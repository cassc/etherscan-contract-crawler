//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './INFModule.sol';

interface INFModuleMutableURI is INFModule {
    function mutableURI(uint256 tokenId) external view returns (string memory);

    function mutableURI(address registry, uint256 tokenId)
        external
        view
        returns (string memory);
}