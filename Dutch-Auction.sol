// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// RemixIDE complier version: 0.8.13

import "../@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../@openzeppelin/contracts/access/Ownable.sol";
import "../@openzeppelin/contracts/utils/Counters.sol";
import "../@openzeppelin/contracts/security/Pausable.sol";

contract MyToken is ERC721, ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public startPrice;
    uint256 public startAt;
    uint256 public floorPrice;
    uint256 public intervalInMinute;
    uint256 public quantity;
    uint256 public totalPausedTime = 0;
    bool public AuctionStarted = false;
    uint256 internal pausedTimerStartsAt;
    uint256 internal currentPriceWhenPaused;

    constructor() ERC721("MyToken", "MTK") {}

    //@dev triggering pauseAuction() will change the state variable currentPriceWhenPaused,reflecting in the price().
    //@dev can only be called by the owner.

    function pauseAuction() public onlyOwner {
        pausedTimerStartsAt = block.timestamp;

        currentPriceWhenPaused = price();

        _pause();
    }

    //@dev when unpause, state variable totalPausedTime is updated and reflected in the price().
    //@dev can only be called by the owner.

    function unpauseAuction() public onlyOwner {
        uint256 unPasuedAt = block.timestamp;

        uint256 pausedTime = unPasuedAt - pausedTimerStartsAt;

        totalPausedTime += pausedTime;

        _unpause();
    }

    // @dev startPrice and floorPrice in wei, conversion of uints should be done in the front-end.
    // @dev function can only be triggered once (i.e. Owner can pause the Auction but not Restart it. )
    // @dev can only be called by the owner.

    function dutchAuctionStart(
        uint256 _quantity,
        uint256 _startPrice,
        uint256 _intervalInMinute,
        uint256 _floorPrice
    ) public onlyOwner {
        require(AuctionStarted == false, "Auction has started");

        quantity = _quantity;
        startPrice = _startPrice;
        intervalInMinute = _intervalInMinute;
        floorPrice = _floorPrice;
        startAt = block.timestamp;
        AuctionStarted = true;
    }

    //@return the current price of the Auction

    function price() public view returns (uint256) {
        if (paused()) {
            return currentPriceWhenPaused;
        } else {
            uint256 minutesElapsed = (block.timestamp -
                startAt -
                totalPausedTime) / 60;

            // @dev Solidity uses integer division, which is equivalent to floored division. i.e DeductionMultiplier will only increase when the time of intervalInMinute has passed.

            uint256 DeductionMultiplier = minutesElapsed / intervalInMinute;

            //@dev CurrentPrice = startPrice *(9/10)^(DeductionMultiplier). 9/10 represents the 10% decrease at the rate of intervalInMinute.

            uint256 currentPrice = (startPrice * (9**DeductionMultiplier)) /
                (10**DeductionMultiplier);

            if (currentPrice >= floorPrice) {
                return currentPrice;
            } else {
                return floorPrice;
            }
        }
    }

    function dutchAuctionMint(uint256 _amount) public payable whenNotPaused {
        require(msg.value >= (_amount * price()), "Not enough ether sent");
        require(quantity >= _amount, "Not enough NFT for minting.");

        quantity -= _amount;

        for (uint256 i = 0; i < _amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _safeMint(msg.sender, tokenId);
            _tokenIdCounter.increment();
        }

        uint256 refund = msg.value - (_amount * price());
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //Hooks from the openzeppelin library.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
