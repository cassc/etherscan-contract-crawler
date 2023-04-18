// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMinter.sol";

interface ILightGauge {
    function depositRewardToken(address rewardToken, uint256 amount) external;

    function claimableTokens(address addr) external returns (uint256);
}

/**
 *  the contract which escrow stHOPE should inherit `AbsExternalLTReward`
 */
abstract contract AbsExternalLTRewardDistributor {
    address private _stHopeGauge;
    address private _minter;
    address private _ltToken;
    address private _gaugeAddress;

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    event RewardsDistributed(uint256 claimableTokens);

    function _init(address stHopeGauge, address minter, address ltToken) internal {
        require(stHopeGauge != address(0), "CE000");
        require(minter != address(0), "CE000");
        require(ltToken != address(0), "CE000");
        require(!_initialized, "Initializable: contract is already initialized");
        _initialized = true;
        _stHopeGauge = stHopeGauge;
        _minter = minter;
        _ltToken = ltToken;
    }

    function refreshGaugeRewards() external {
        require(_gaugeAddress != address(0), "please set gaugeAddress first");

        uint256 claimableTokens = ILightGauge(_stHopeGauge).claimableTokens(address(this));
        require(claimableTokens > 0, "Noting Token to Deposit");

        IMinter(_minter).mint(_stHopeGauge);

        bool success = IERC20(_ltToken).approve(_gaugeAddress, claimableTokens);
        require(success, "APPROVE FAILED");
        ILightGauge(_gaugeAddress).depositRewardToken(_ltToken, claimableTokens);

        emit RewardsDistributed(claimableTokens);
    }

    function _setGaugeAddress(address gaugeAddress) internal {
        _gaugeAddress = gaugeAddress;
    }
}