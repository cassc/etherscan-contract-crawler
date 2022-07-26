// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/MultistageAllowlistCloneable.sol";

abstract contract $INFT is INFT {
    constructor() {}
}

contract $MultiStageAllowlistCloneable is MultiStageAllowlistCloneable {
    constructor() {}

    function $ownableInitialized() external view returns (bool) {
        return ownableInitialized;
    }

    function $_isTokenIdAllowed(uint8 stage,uint256 tokenId) external view returns (bool) {
        return super._isTokenIdAllowed(stage,tokenId);
    }

    function $_getTokenElementPositions(uint256 tokenId) external pure returns (uint256, uint256) {
        return super._getTokenElementPositions(tokenId);
    }

    function $_setBit(uint256 bitField,uint256 position) external pure returns (uint256) {
        return super._setBit(bitField,position);
    }

    function $_clearBit(uint256 bitField,uint256 position) external pure returns (uint256) {
        return super._clearBit(bitField,position);
    }

    function $_setOwner(address newOwner) external {
        return super._setOwner(newOwner);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}