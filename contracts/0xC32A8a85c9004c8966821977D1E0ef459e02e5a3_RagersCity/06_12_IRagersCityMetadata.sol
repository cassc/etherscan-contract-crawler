// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// @title:  Ragers City
// @desc:   Ragers City is a next-gen decentralized Manga owned by the community, featuring a collection of 5000 NFTs.
// @team:   https://twitter.com/RagersCity
// @author: https://linkedin.com/in/antoine-andrieux
// @url:    https://ragerscity.com

abstract contract IRagersCityMetadata {
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory);

    function lock() public virtual;
}