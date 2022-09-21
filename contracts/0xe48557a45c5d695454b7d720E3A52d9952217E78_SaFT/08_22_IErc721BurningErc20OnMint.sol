//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IErc721BurningErc20OnMint {
    function setErc20TokenAddress(address erc20TokenAddress_) external;

    // Input: address to mint ERC721 to, and returns the token ID minted
    function mint() external returns (uint256);
}