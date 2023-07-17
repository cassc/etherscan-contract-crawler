pragma solidity ^0.8.3;

/**
 * @dev Factory for Tranche minimal proxy contracts
 */
interface ITrancheFactory {
    event TrancheCreated(address newTrancheAddress);

    /**
     * @dev Deploys a minimal proxy instance for a new tranche ERC20 token with the given parameters.
     */
    function createTranche(
        string memory name,
        string memory symbol,
        address _collateralToken
    ) external returns (address);
}