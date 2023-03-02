// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "Ownable.sol";

import "IController.sol";
import "ICNCToken.sol";
import "IMinter.sol";

/// @notice this contract will be added as a minter to the CNC token
/// and will only be allow to add new minters for the first three months
/// to be able to recover in case of an issue in the protocol
/// Adding a minter will always be a governance decision and will have a
/// timelock of 7 days (enforced by the governance proxy)
/// to allow the community to review the decision
/// should there ever be a need to add a new minter
/// This will only be used in case of an emergency and should not actually
/// be used should the protocol operate as intended
contract EmergencyMinter is Ownable {
    event LpTokenStakerSwitched(address previousTokenStaker, address newTokenStaker);
    event RebalancingRewardsHandlerSwitched(address previousHandler, address newHandler);
    event Shutdown();

    uint256 public constant ACTIVE_TIME = 90 days;

    ICNCToken public immutable cnc;
    IController public immutable controller;
    uint256 public immutable deployedAt;

    constructor(ICNCToken _cnc, IController _controller) {
        cnc = _cnc;
        controller = _controller;
        deployedAt = block.timestamp;
    }

    /// @notice this switches the rebalancing reward handler in charge of minting CNC as reward
    /// it replaces the reward handler for all the pools that have the previous handler
    /// this should typicall be all the Omnipools, since at launch, they will all have
    /// the same reward handler
    function switchRebalancingRewardsHandler(address previousHandler, address newHandler)
        external
        onlyOwner
    {
        address[] memory pools = controller.listPools();
        IInflationManager inflationManager = controller.inflationManager();
        for (uint256 i; i < pools.length; i++) {
            address pool = pools[i];
            if (inflationManager.hasPoolRebalancingRewardHandlers(pool, previousHandler)) {
                inflationManager.removePoolRebalancingRewardHandler(pool, previousHandler);
                inflationManager.addPoolRebalancingRewardHandler(pool, newHandler);
            }
        }
        _switchMinter(IMinter(previousHandler), IMinter(newHandler));
        emit RebalancingRewardsHandlerSwitched(previousHandler, newHandler);
    }

    // NOTE: If a new LpTokenStaker is created, the previous one should be shut down first.
    // Otherwise there is a risk of double counting inflation.
    // Also to rescue rewards, one should call `claimPoolEarningsAndSellRewardTokens` for the reward managers
    function switchLpTokenStaker(address previousTokenStaker, address newTokenStaker)
        external
        onlyOwner
    {
        require(
            address(controller.lpTokenStaker()) == previousTokenStaker,
            "EmergencyMinter: invalid staker"
        );
        ILpTokenStaker(previousTokenStaker).shutdown();
        controller.setLpTokenStaker(newTokenStaker);
        _switchMinter(IMinter(previousTokenStaker), IMinter(newTokenStaker));
        emit LpTokenStakerSwitched(previousTokenStaker, newTokenStaker);
    }

    /// @notice renounces minting rights for `currentMinter` and adds them to `replacementMinter`
    /// This is a critical operation that should only be executed in case an issue arises and will have a 7 days timelock
    /// This function will only be callable for the first 90 days after deployment
    function _switchMinter(IMinter currentMinter, IMinter replacementMinter) internal {
        require(block.timestamp < deployedAt + ACTIVE_TIME, "EmergencyMinter: no longer active");
        require(
            address(currentMinter) != address(replacementMinter),
            "EmergencyMinter: same minter"
        );
        require(
            _isMinter(address(currentMinter)),
            "EmergencyMinter: currentMinter is not a minter"
        );
        require(
            replacementMinter.supportsInterface(IMinter.renounceMinterRights.selector),
            "EmergencyMinter: invalid minter"
        );

        currentMinter.renounceMinterRights();
        cnc.addMinter(address(replacementMinter));
    }

    /// @notice after the 90 days period, the contract cannot add new minters anymore
    /// and this can be called to remove it from the list of minters,
    /// although this will in practice not make a difference
    function shutdown() external {
        require(block.timestamp >= deployedAt + ACTIVE_TIME, "EmergencyMinter: still active");
        cnc.renounceMinterRights();
        emit Shutdown();
    }

    /// @dev we do not have a constant-time way to check if an address is a minter
    /// so we need to iterate through all the minters
    /// there should only ever be three minters when this function is called, so this is not an issue
    function _isMinter(address minter) internal view returns (bool) {
        address[] memory minters = cnc.listMinters();
        for (uint256 i; i < minters.length; i++) {
            if (minters[i] == address(minter)) {
                return true;
            }
        }
        return false;
    }
}