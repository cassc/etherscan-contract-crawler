// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "GenericVault.sol";

error ZeroAddress();

interface IstkCvxFxsStrategy {
    function harvest(address _caller, uint256 _minAmountOut)
        external
        returns (uint256 harvested);
}

interface ICvxFxsStaking {
    function claimableRewards(address _account)
        external
        view
        returns (EarnedData[] memory userRewards);

    struct EarnedData {
        address token;
        uint256 amount;
    }
}

contract stkCvxFxsVault is GenericUnionVault {
    bool public isHarvestPermissioned;
    mapping(address => bool) public authorizedHarvesters;
    ICvxFxsStaking constant cvxFxsStaking =
        ICvxFxsStaking(0x49b4d1dF40442f0C31b1BbAEA3EDE7c38e37E31a);

    constructor(address _token) GenericUnionVault(_token) {}

    /// @notice Sets whether only whitelisted addresses can harvest
    /// @param _status Whether or not harvests are permissioned
    function setHarvestPermissions(bool _status) external onlyOwner {
        isHarvestPermissioned = _status;
    }

    /// @notice Adds or remove an address from the harvesters' whitelist
    /// @param _harvester address of the authorized harvester
    /// @param _authorized Whether to add or remove harvester
    function updateAuthorizedHarvesters(address _harvester, bool _authorized)
        external
        onlyOwner
    {
        if (_harvester == address(0)) revert ZeroAddress();
        authorizedHarvesters[_harvester] = _authorized;
    }

    /// @notice Claim rewards and swaps them to cvxFxs for restaking
    /// @param _minAmountOut - min amount of cvxFxs to receive for harvest
    /// @dev Can be called by whitelisted account or anyone against a cvxFxs incentive
    /// @dev Harvest logic in the strategy/harvester contract
    /// @dev Harvest can be called even if permissioned when last staker is
    ///      withdrawing from the vault.
    function harvest(uint256 _minAmountOut) public {
        require(
            !isHarvestPermissioned ||
                authorizedHarvesters[msg.sender] ||
                totalSupply() == 0,
            "permissioned harvest"
        );
        uint256 _harvested = IstkCvxFxsStrategy(strategy).harvest(
            msg.sender,
            _minAmountOut
        );
        emit Harvest(msg.sender, _harvested);
    }

    /// @notice View function to get pending staking rewards
    function claimableRewards()
        external
        view
        returns (ICvxFxsStaking.EarnedData[] memory)
    {
        return cvxFxsStaking.claimableRewards(strategy);
    }

    /// @notice Claim rewards and swaps them to cvxFXS for restaking
    /// @dev No slippage protection (harvester will use oracles), swapping for cvxCRV
    function harvest() public override {
        harvest(0);
    }
}