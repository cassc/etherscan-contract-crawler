// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IOwner} from "src/contracts/utils/IOwner.sol";

/**
 * @title MinterTracker
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Abstract utility that allows a Module to track the number of tokens each
 * member has minted *through that Module* and enforce a maximum total number
 * of tokens all members can mint *through that Module*.
 */
abstract contract MinterTracker {
    // token => max
    mapping(address => uint256) public mintMax;
    // token => member => number minted
    mapping(address => mapping(address => uint256)) public numberMinted;

    event MintMaxUpdated(address indexed token, uint256 indexed max);

    function checkMintMax(address token) internal {
        if (mintMax[token] > 0) {
            require(
                mintMax[token] > numberMinted[token][msg.sender],
                "MinterTracker: Address has reached mint max"
            );
            numberMinted[token][msg.sender] =
                numberMinted[token][msg.sender] +
                1;
        }
    }

    function checkMintMax(address token, uint256 amount) internal {
        if (mintMax[token] > 0) {
            require(
                mintMax[token] >= numberMinted[token][msg.sender] + amount,
                "MinterTracker: Address has reached mint max"
            );
            numberMinted[token][msg.sender] =
                numberMinted[token][msg.sender] +
                amount;
        }
    }

    /// Set eth price
    /// @param token Token address
    /// @param _mintMax New merkle root
    /// @notice Only available to token owner
    function updateMintMax(address token, uint256 _mintMax) external {
        require(
            msg.sender == IOwner(token).owner(),
            "MinterTracker: Only owner can set mint max"
        );
        mintMax[token] = _mintMax;
        emit MintMaxUpdated(token, _mintMax);
    }
}