# ERC721 Smart Contract Dutch Auction

Create an NFT Dutch Auction method with on/off switch (Dutch Auction: the mint price will begins at x ETH, and lower every y minutes, with a floor price at z ETH, until the dutch auction qty all sold), please well consider the security aspect of the method, you should create based on following dependences:

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

You should have at least the following 2 methods:

dutchAuctionStart(qty, x, y, z) onlyOwner

dutchAuctionMint(qty) payable
