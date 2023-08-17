// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol"; 
import "./interface/IQWA.sol";
import "./interface/ITreasury.sol";

/// @title   Distributor
/// @notice  QWA Staking Distributor
contract Distributor is Ownable {
    /// VARIABLES ///

    /// @notice QWA address
    IERC20 public immutable QWA;
    /// @notice Treasury address
    ITreasury public immutable treasury;
    /// @notice Staking address
    address public immutable staking;

    /// @notice In ten-thousandths ( 5000 = 0.5% )
    uint256 public rate;

    uint256 public constant rateDenominator = 1_000_000;

    /// CONSTRUCTOR ///

    /// @param _treasury  Address of treasury contract
    /// @param _QWA      Address of QWA
    /// @param _staking   Address of staking contract
    constructor(address _treasury, address _QWA, address _staking) {
        require(_treasury != address(0), "Zero address: Treasury");
        treasury = ITreasury(_treasury);
        require(_QWA != address(0), "Zero address: QWA");
        QWA = IQWA(_QWA);
        require(_staking != address(0), "Zero address: Staking");
        staking = _staking;
    }

    /// STAKING FUNCTION ///

    /// @notice Send epoch reward to staking contract
    function distribute() external {
        require(msg.sender == staking, "Only staking");
        treasury.mintQWA(staking, nextReward()); // mint and send tokens
    }

    /// VIEW FUNCTIONS ///

    /// @notice          Returns next reward at given rate
    /// @param _rate     Rate
    /// @return _reward  Next reward
    function nextRewardAt(uint256 _rate) public view returns (uint256 _reward) {
        return (QWA.totalSupply() * _rate) / rateDenominator;
    }

    /// @notice          Returns next reward of staking contract
    /// @return _reward  Next reward for staking contract
    function nextReward() public view returns (uint256 _reward) {
        uint256 excessReserves = treasury.excessReserves();
        _reward = nextRewardAt(rate);
        if (excessReserves < _reward) _reward = excessReserves;
    }

    /// POLICY FUNCTIONS ///

    /// @notice             Set reward rate for rebase
    /// @param _rewardRate  New rate
    function setRate(uint256 _rewardRate) external onlyOwner {
        require(
            _rewardRate <= 50000,
            "Rate cannot exceed 5.0%"
        );

        rate = _rewardRate;
    }
}