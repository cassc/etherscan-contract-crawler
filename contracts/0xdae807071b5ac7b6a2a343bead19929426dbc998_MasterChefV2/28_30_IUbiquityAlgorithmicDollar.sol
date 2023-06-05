// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "./IERC20Ubiquity.sol";

/// @title UAD stablecoin interface
/// @author Ubiquity Algorithmic Dollar
interface IUbiquityAlgorithmicDollar is IERC20Ubiquity {
    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    function setIncentiveContract(address account, address incentive) external;

    function incentiveContract(address account) external view returns (address);
}