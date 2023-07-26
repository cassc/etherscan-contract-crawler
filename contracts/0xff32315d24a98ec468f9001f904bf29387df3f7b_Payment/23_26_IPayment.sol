// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IFeeDistributor } from "./IFeeDistributor.sol";

interface IPayment {
    function pay(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        IFeeDistributor.Fee[] calldata fees,
        bytes calldata signature
    ) external payable;

    function payHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        IFeeDistributor.Fee[] calldata fees,
        address sender
    ) external pure returns (bytes32);
}