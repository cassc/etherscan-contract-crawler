// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAMOMinter.sol";

/// @title BaseAMOStorage
/// @author Angle Core Team
/// @notice Variables, references, parameters, and events needed in each AMO contract
contract BaseAMOStorage is Initializable {
    // =========================== Constant Address ================================

    /// @notice Router used for swaps
    address internal constant _oneInch = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    // ================================= Reference =================================

    /// @notice Reference to the `AmoMinter` contract
    IAMOMinter public amoMinter;

    // ================================= Mappings ==================================

    /// @notice Maps a token supported by an AMO to the last known balance of it: it is needed to track
    /// gains and losses made on a specific token
    mapping(IERC20 => uint256) public lastBalances;
    /// @notice Maps a token to the loss made on it by the AMO
    mapping(IERC20 => uint256) public protocolDebts;
    /// @notice Maps a token to the gain made on it by the AMO
    mapping(IERC20 => uint256) public protocolGains;

    uint256[46] private __gapStorage;

    // =============================== Events ======================================

    event Recovered(address tokenAddress, address to, uint256 amountToRecover);

    // =============================== Errors ======================================

    error IncompatibleLengths();
    error NotAMOMinter();
    error NotApproved();
    error NotGovernor();
    error OneInchSwapFailed();
    error TooSmallAmountOut();
    error ZeroAddress();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}
}