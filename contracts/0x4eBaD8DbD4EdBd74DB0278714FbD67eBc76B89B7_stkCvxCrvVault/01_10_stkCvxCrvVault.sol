// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "GenericVault.sol";

interface stkCvxCrvStrategy {
    function harvest(
        address _caller,
        uint256 _minAmountOut,
        bool _forceLock
    ) external returns (uint256 harvested);

    function setRewardWeight(uint256 _weight) external;
}

contract stkCvxCrvVault is GenericUnionVault {
    bool public isHarvestPermissioned = false;
    uint256 public weight;
    mapping(address => bool) public authorizedHarvesters;
    uint256 public constant WEIGHT_PRECISION = 10000;

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
        authorizedHarvesters[_harvester] = _authorized;
    }

    /// @notice set the strategy's reward weight
    /// @dev Always only available to owner or authorized harvesters
    /// @param _weight the desired weight: 0 = full group 0, 10k = full group 1
    function setRewardWeight(uint256 _weight) public {
        require(_weight <= WEIGHT_PRECISION, "invalid weight");
        require(
            authorizedHarvesters[msg.sender] || msg.sender == owner(),
            "authorized only"
        );
        stkCvxCrvStrategy(strategy).setRewardWeight(_weight);
    }

    /// @notice Updates the strategy's reward weight before harvesting
    /// @dev Always only available to owner or authorized harvesters
    /// @param _minAmountOut - min amount of cvxCrv to receive for harvest
    /// @param _lock - whether to lock or swap lp tokens for cvxCrv
    /// @param _weight the desired weight: 0 = full group 0, 10k = full group 1
    function harvestAndSetRewardWeight(
        uint256 _minAmountOut,
        bool _lock,
        uint256 _weight
    ) public {
        setRewardWeight(_weight);
        harvest(_minAmountOut, _lock);
    }

    /// @notice Claim rewards and swaps them to cvxCrv for restaking
    /// @param _minAmountOut - min amount of cvxCrv to receive for harvest
    /// @param _forceLock - force locking even if there's a discount for swapping
    /// @dev Can be called by whitelisted account or anyone against an ETH incentive
    /// @dev Harvest logic in the strategy contract
    /// @dev Harvest can be called even if permissioned when last staker is
    ///      withdrawing from the vault.
    function harvest(uint256 _minAmountOut, bool _forceLock) public {
        require(
            !isHarvestPermissioned ||
                authorizedHarvesters[msg.sender] ||
                totalSupply() == 0,
            "permissioned harvest"
        );
        uint256 _harvested = stkCvxCrvStrategy(strategy).harvest(
            msg.sender,
            _minAmountOut,
            _forceLock
        );
        emit Harvest(msg.sender, _harvested);
    }

    /// @notice Claim rewards and swaps them to cvxCRV for restaking
    /// @param _minAmountOut - min amount of cvxCRV to receive for harvest
    /// @dev swapping for cvxCRV by default
    function harvest(uint256 _minAmountOut) public {
        harvest(_minAmountOut, false);
    }

    /// @notice Claim rewards and swaps them to cvxCRV for restaking
    /// @dev No slippage protection, swapping for cvxCRV
    function harvest() public override {
        harvest(0);
    }
}