pragma solidity 0.5.17;

import "./CErc20Delegate.sol";

/**
 * @title Compound's CErc20Delegate Contract
 * @notice CTokens which wrap Ether and are delegated to
 * @author Compound
 */
contract CErc20DelegateDAIAggregatorFix is CErc20Delegate {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes calldata data) external {
        address DAI_CONTROLLER = 0xaFD2AaDE64E6Ea690173F6DE59Fc09F5C9190d74;
        address MERKLE_REDEEMER = 0xCAe4210e6676727EA4e0fD9BA5dFb95831356a16;

        require(msg.sender == address(this) || hasAdminRights(), "!self");
        require(accrueInterest() == uint(Error.NO_ERROR), "!accrue");

        // Get account #1 supply balance
        uint256 account1SupplyShares = accountTokens[DAI_CONTROLLER];

        // Set account supply shares to 0
        accountTokens[DAI_CONTROLLER] = 0;
        accountTokens[MERKLE_REDEEMER] = account1SupplyShares;

        emit Transfer(DAI_CONTROLLER, MERKLE_REDEEMER, account1SupplyShares);
    }

    /**
     * @notice Function called before all delegator functions
     */
    function _prepare() external payable {}
}