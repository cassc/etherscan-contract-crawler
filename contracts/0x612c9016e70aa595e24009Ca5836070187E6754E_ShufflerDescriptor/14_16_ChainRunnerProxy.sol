// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;


abstract contract ChainRunnerProxy {
    address public renderingContractAddress;
}

abstract contract ChainRunnerRenderProxy {
    function onChainTokenURI(uint256 tokenId) virtual external view returns (string memory);
}