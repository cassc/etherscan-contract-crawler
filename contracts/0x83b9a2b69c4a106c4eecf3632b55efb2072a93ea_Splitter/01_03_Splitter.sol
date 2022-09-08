// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "solmate/utils/SafeTransferLib.sol";

/// @notice Contract that splits users funds into different addresses on the PoS and PoW chains after the merge.
contract Splitter {
    using SafeTransferLib for ERC20;

    mapping(bytes32 => bool) public validClaims;

    ///@notice Returns true if merge has happened.
    ///@dev Based on https://eips.ethereum.org/EIPS/eip-4399
    function mergeHappened() public view returns (bool) {
        return block.difficulty > 2 ** 64;
    }

    function deposit(address token, uint256 amount, address recipientPOS, address recipientPOW) external payable {
        if (token == address(0)) {
            validClaims[keccak256(abi.encodePacked(msg.sender, address(0), msg.value, recipientPOS, recipientPOW))] = true;
        } else {
            ERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            validClaims[keccak256(abi.encodePacked(msg.sender, token, amount, recipientPOS, recipientPOW))] = true;
        }
    }

    function withdraw(address token, uint256 amount, address recipientPOS, address recipientPOW) external {
        bytes32 claim = keccak256(abi.encodePacked(msg.sender, token, amount, recipientPOS, recipientPOW));

        require(validClaims[claim], "Invalid request.");

        validClaims[claim] = false;

        address recipient = mergeHappened() ? recipientPOS : recipientPOW;

        if (token == address(0)) {
            SafeTransferLib.safeTransferETH(recipient, amount);
        } else {
            ERC20(token).safeTransfer(recipient, amount);
        }
    }

    function returnToSender(address token, uint256 amount, address recipientPOS, address recipientPOW) external {
        bytes32 claim = keccak256(abi.encodePacked(msg.sender, token, amount, recipientPOS, recipientPOW));

        require(validClaims[claim], "Invalid request.");

        validClaims[claim] = false;

        if (token == address(0)) {
            SafeTransferLib.safeTransferETH(msg.sender, amount);
        } else {
            ERC20(token).safeTransfer(msg.sender, amount);
        }
    }
}