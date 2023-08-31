// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedAsset is IERC20 /* IERC20WithOptional */ {

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PositionMoved(address indexed userFrom, address indexed userTo, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 amount);
    event TokenWithdraw(address indexed user, address token, uint256 amount);

    event FeeChanged(uint256 newFeePercent);
    event FeeReceiverChanged(address newFeeReceiver);
    event AllowedBoneLockerSelectorAdded(address boneLocker, bytes4 selector);
    event AllowedBoneLockerSelectorRemoved(address boneLocker, bytes4 selector);

    /**
     * @notice Get underlying token
     */
    function getUnderlyingToken() external view returns (IERC20);

    /**
     * @notice deposit underlying token and send wrapped token to user
     * @dev Important! Only user or trusted contracts must be able to call this method
     */
    function deposit(address _userAddr, uint256 _amount) external;

    /**
     * @notice get wrapped token and return underlying
     * @dev Important! Only user or trusted contracts must be able to call this method
     */
    function withdraw(address _userAddr, uint256 _amount) external;

    /**
     * @notice get pending reward amount for user if reward is supported
     */
    function pendingReward(address _userAddr) external view returns (uint256);

    /**
     * @notice claim pending reward for user if reward is supported
     */
    function claimReward(address _userAddr) external;

    /**
     * @notice Manually move position (or its part) to another user (for example in case of liquidation)
     * @dev Important! Only trusted contracts must be able to call this method
     */
    function movePosition(address _userAddrFrom, address _userAddrTo, uint256 _amount) external;

    /**
     * @dev function for checks that asset is unitprotocol wrapped asset.
     * @dev For wrapped assets must return keccak256("UnitProtocolWrappedAsset")
     */
    function isUnitProtocolWrappedAsset() external view returns (bytes32);
}