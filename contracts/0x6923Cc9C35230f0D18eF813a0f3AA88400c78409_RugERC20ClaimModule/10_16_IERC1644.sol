// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title IERC1644 Controller Token Operation (part of the ERC1400 Security Token Standards)
/// @dev See https://github.com/ethereum/EIPs/issues/1644
/// @notice data and operatorData parameters were removed from `controllerTransfer`
/// and `controllerRedeem`
interface IERC1644 {
    // Controller Operation
    function isControllable() external view returns (bool);

    function controllerTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function controllerRedeem(address account, uint256 amount) external;

    // Controller Events
    event ControllerTransfer(
        address controller,
        address indexed sender,
        address indexed recipient,
        uint256 amount
    );

    event ControllerRedemption(
        address controller,
        address indexed account,
        uint256 amount
    );
}