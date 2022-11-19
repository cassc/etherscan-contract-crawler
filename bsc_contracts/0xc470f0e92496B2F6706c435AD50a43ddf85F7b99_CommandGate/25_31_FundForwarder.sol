// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Transferable.sol";

import "./interfaces/IFundForwarder.sol";

abstract contract FundForwarder is Transferable, IFundForwarder {
    bytes32 private _treasury;

    constructor(ITreasury treasury_) payable {
        _updateTreasury(treasury_);
    }

    receive() external payable virtual {
        address treasury_;
        assembly {
            treasury_ := sload(_treasury.slot)
        }
        _safeNativeTransfer(treasury_, msg.value);
    }

    function updateTreasury(ITreasury) external virtual override;

    function treasury() public view returns (ITreasury treasury_) {
        assembly {
            treasury_ := sload(_treasury.slot)
        }
    }

    function _updateTreasury(ITreasury treasury_) internal {
        assembly {
            sstore(_treasury.slot, treasury_)
        }
    }

    function recoverERC20(IERC20 token_) external {
        _safeERC20Transfer(
            token_,
            address(treasury()),
            token_.balanceOf(address(this))
        );
    }

    function recoverNative() external {
        _safeNativeTransfer(address(treasury()), address(this).balance);
    }
}