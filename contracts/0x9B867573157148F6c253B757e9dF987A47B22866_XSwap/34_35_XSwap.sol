// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Initializable} from "./core/init/Initializable.sol";

import {Swapper, SwapperConstructorParams} from "./core/swap/Swapper.sol";

import {WhitelistWithdrawable} from "./core/withdraw/WhitelistWithdrawable.sol";

import {XSwapStorage} from "./XSwapStorage.sol";

struct XSwapConstructorParams {
    /**
     * @dev {ISwapSignatureValidator}-compatible contract address
     */
    address swapSignatureValidator;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address permitResolverWhitelist;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address useProtocolWhitelist;
    /**
     * @dev {IDelegateManager}-compatible contract address
     */
    address delegateManager;
    /**
     * @dev {IAccountWhitelist}-compatible contract address
     */
    address withdrawWhitelist;
    /**
     * @dev {ILifeControl}-compatible contract address
     */
    address lifeControl;
}

contract XSwap is Initializable, Swapper, WhitelistWithdrawable, XSwapStorage {
    // prettier-ignore
    constructor(XSwapConstructorParams memory params_)
        Initializable(INITIALIZER_SLOT)
        WhitelistWithdrawable(WITHDRAW_WHITELIST_SLOT, _whitelistWithdrawableParams(params_))
        Swapper(_swapperParams(params_))
    {
        _initialize(params_, false);
    }

    function initialize(XSwapConstructorParams memory params_) external {
        _initialize(params_, true);
    }

    function _initialize(XSwapConstructorParams memory params_, bool initBase_) private init {
        if (initBase_) {
            initializeSwapper(_swapperParams(params_));
            initializeWhitelistWithdrawable(_whitelistWithdrawableParams(params_));
        }

        require(params_.lifeControl != address(0), "XS: zero life control");
        _setLifeControl(params_.lifeControl);
    }

    function _swapperParams(
        XSwapConstructorParams memory params_
    ) private pure returns (SwapperConstructorParams memory) {
        // prettier-ignore
        return SwapperConstructorParams({
            swapSignatureValidator: params_.swapSignatureValidator,
            permitResolverWhitelist: params_.permitResolverWhitelist,
            useProtocolWhitelist: params_.useProtocolWhitelist,
            delegateManager: params_.delegateManager
        });
    }

    function _whitelistWithdrawableParams(XSwapConstructorParams memory params_) private pure returns (address) {
        return params_.withdrawWhitelist;
    }

    function _checkSwapEnabled() internal view override {
        require(!_lifeControl().paused(), "XS: swapping paused");
    }
}