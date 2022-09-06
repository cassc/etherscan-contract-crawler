// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JupiterNFT.sol';

/**
 * @dev Whenever we need to enforce a single address a cap on the mint of tokens.
 * Max value is set at constructor but can be changed by an operator.
 */
abstract contract AddressMintCap is JupiterNFT {
    // the max cap we will allow per address
    uint256 private _mintCap;
    // Mapping for how much each address has minted. This value is increased on each mint.
    mapping(address => uint256) public _addressCap;

    constructor () {
        _mintCap = 10;
    }
    
    /**
     * @dev jupiter operator only, allows to change the mint cap.
     * if new cap is lower that previous, it will not allow those capped address to mint again.
     */
    function setMintCap(uint256 cap) external {
        require(operators[msg.sender], "only operators");
        _mintCap = cap;
    }

    function getMintCap() external view returns (uint256) {
        return _mintCap;
    }
    
}