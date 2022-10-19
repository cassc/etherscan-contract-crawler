// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/**
 * @dev Factory for Slip minimal proxy contracts
 */
interface ISlipFactory {
    event SlipCreated(address newSlipAddress);

    /**
     * @dev Deploys a minimal proxy instance for a new slip ERC20 token with the given parameters.
     */
    function createSlip(
        string memory name,
        string memory symbol,
        address _collateralToken
    ) external returns (address);
}