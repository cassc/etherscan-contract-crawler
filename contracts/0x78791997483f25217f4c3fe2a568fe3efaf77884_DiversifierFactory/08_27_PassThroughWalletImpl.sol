// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {PausableImpl} from "splits-utils/PausableImpl.sol";
import {TokenUtils} from "splits-utils/TokenUtils.sol";
import {WalletImpl} from "splits-utils/WalletImpl.sol";

/// @title Pass-Through Wallet Implementation
/// @author 0xSplits
/// @notice A clone-implementation of a pass-through wallet.
/// Please be aware, owner has _FULL CONTROL_ of the deployment.
/// @dev This contract uses token = address(0) to refer to ETH.
contract PassThroughWalletImpl is WalletImpl, PausableImpl {
    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using TokenUtils for address;

    /// -----------------------------------------------------------------------
    /// structs
    /// -----------------------------------------------------------------------

    struct InitParams {
        address owner;
        bool paused;
        address passThrough;
    }

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    event SetPassThrough(address passThrough);
    event PassThrough(address indexed passThrough, address[] tokens, uint256[] amounts);

    // emitted in clone bytecode
    event ReceiveETH(uint256 amount);

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// storage - constants & immutables
    /// -----------------------------------------------------------------------

    address public immutable passThroughWalletFactory;

    /// -----------------------------------------------------------------------
    /// storage - mutables
    /// -----------------------------------------------------------------------

    /// slot 0 - 11 bytes free

    /// OwnableImpl storage
    /// address internal $owner;
    /// 20 bytes

    /// PausableImpl storage
    /// bool internal $paused;
    /// 1 byte

    /// slot 1 - 12 bytes free

    /// address to pass-through funds to
    address internal $passThrough;
    /// 20 bytes

    /// -----------------------------------------------------------------------
    /// constructor & initializer
    /// -----------------------------------------------------------------------

    constructor() {
        passThroughWalletFactory = msg.sender;
    }

    function initializer(InitParams calldata params_) external {
        // only passThroughWalletFactory may call `initializer`
        if (msg.sender != passThroughWalletFactory) revert Unauthorized();

        // don't need to init wallet separately
        __initPausable({owner_: params_.owner, paused_: params_.paused});
        $passThrough = params_.passThrough;
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external - onlyOwner
    /// -----------------------------------------------------------------------

    /// set passThrough
    function setPassThrough(address passThrough_) external onlyOwner {
        $passThrough = passThrough_;
        emit SetPassThrough(passThrough_);
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - view
    /// -----------------------------------------------------------------------

    function passThrough() external view returns (address) {
        return $passThrough;
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - permissionless
    /// -----------------------------------------------------------------------

    /// emit event when receiving ETH
    /// @dev implemented w/i clone bytecode
    /* receive() external payable { */
    /*     emit ReceiveETH(msg.value); */
    /* } */

    /// send `tokens_` to `$passThrough`
    function passThroughTokens(address[] calldata tokens_) external pausable returns (uint256[] memory amounts) {
        address _passThrough = $passThrough;
        uint256 length = tokens_.length;
        amounts = new uint256[](length);
        for (uint256 i; i < length;) {
            address token = tokens_[i];
            uint256 amount = token._balanceOf(address(this));
            amounts[i] = amount;
            token._safeTransfer(_passThrough, amount);

            unchecked {
                ++i;
            }
        }

        emit PassThrough(_passThrough, tokens_, amounts);
    }
}