// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IOwner} from "src/contracts/utils/IOwner.sol";

/// Use an eth price to mint token tokens as airdrop
abstract contract MinterTracker {
    mapping(address => uint256) public mintMax;
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