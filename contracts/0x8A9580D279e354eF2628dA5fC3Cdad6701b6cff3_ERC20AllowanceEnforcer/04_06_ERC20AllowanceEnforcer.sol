//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../CaveatEnforcer.sol";
import {BytesLib} from "../libraries/BytesLib.sol";

contract ERC20AllowanceEnforcer is CaveatEnforcer {
    mapping(address => mapping(bytes32 => uint256)) spentMap;

    function enforceCaveat(
        bytes calldata terms,
        Transaction calldata transaction,
        bytes32 delegationHash
    ) public override returns (bool) {
        bytes4 targetSig = bytes4(transaction.data[0:4]);
        bytes4 allowedSig = bytes4(0xa9059cbb);
        require(
            targetSig == allowedSig,
            "ERC20AllowanceEnforcer:invalid-method"
        );
        uint256 limit = BytesLib.toUint256(terms, 0);
        uint256 sending = BytesLib.toUint256(transaction.data, 36);
        spentMap[msg.sender][delegationHash] += sending;
        uint256 spent = spentMap[msg.sender][delegationHash];
        require(spent <= limit, "ERC20AllowanceEnforcer:allowance-exceeded");
        return true;
    }
}