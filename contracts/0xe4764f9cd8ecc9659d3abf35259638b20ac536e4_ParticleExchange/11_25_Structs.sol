// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct Lien {
    address lender; // NFT supplier address
    address borrower; // NFT trade executor address
    address collection; // NFT collection address
    uint256 tokenId; /// NFT ID  (@dev: at borrower bidding, this field is used to store margin)
    uint256 price; // NFT supplier's desired sold price
    uint256 rate; // APR in bips, _BASIS_POINTS defined in MathUtils.sol
    uint256 loanStartTime; // loan start block.timestamp
    uint256 auctionStartTime; // auction start block.timestamp
}