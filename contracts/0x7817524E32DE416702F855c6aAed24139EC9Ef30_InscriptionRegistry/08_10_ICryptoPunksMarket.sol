// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ICryptoPunksMarket {
    function punkIndexToAddress(uint256 _tokenId)
        external
        view
        returns (address);

    function balanceOf(address _address) external view returns (uint256);
}