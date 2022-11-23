// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {Address} from "../../lib/Address.sol";
import {Math} from "../../lib/Math.sol";

import {NativeClaimer} from "../asset/NativeClaimer.sol";
import {NativeReceiver} from "../asset/NativeReceiver.sol";
import {NativeReturnMods} from "../asset/NativeReturnMods.sol";
import {TokenChecker} from "../asset/TokenChecker.sol";
import {TokenHelper} from "../asset/TokenHelper.sol";

import {IDelegateManager} from "../delegate/IDelegateManager.sol";

import {AccountCounter} from "../misc/AccountCounter.sol";

import {IPermitResolver} from "../permit/IPermitResolver.sol";

import {IUseProtocol, UseParams} from "../use/IUseProtocol.sol";

import {Withdraw} from "../withdraw/IWithdrawable.sol";

import {ISwapper, SwapParams, StealthSwapParams, Permit, Call} from "./ISwapper.sol";
import {Swap, SwapStep, TokenUse, StealthSwap, TokenCheck} from "./Swap.sol";
import {SwapperStorage} from "./SwapperStorage.sol";

struct SwapperConstructorParams {
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
}

contract Swapper is ISwapper, NativeReceiver, NativeReturnMods, SwapperStorage {
    using AccountCounter for AccountCounter.State;

    constructor(SwapperConstructorParams memory params_) {
        _initialize(params_);
    }

    function initializeSwapper(SwapperConstructorParams memory params_) internal {
        _initialize(params_);
    }

    function _initialize(SwapperConstructorParams memory params_) private {
        require(params_.swapSignatureValidator != address(0), "SW: zero swap sign validator");
        _setSwapSignatureValidator(params_.swapSignatureValidator);

        require(params_.permitResolverWhitelist != address(0), "SW: zero permit resolver list");
        _setPermitResolverWhitelist(params_.permitResolverWhitelist);

        require(params_.useProtocolWhitelist != address(0), "SW: zero use protocol list");
        _setUseProtocolWhitelist(params_.useProtocolWhitelist);

        require(params_.delegateManager != address(0), "SW: zero delegate manager");
        _setDelegateManager(params_.delegateManager);
    }

    function swap(SwapParams calldata params_) external payable {
        _checkSwapEnabled();
        require(params_.stepIndex < params_.swap.steps.length, "SW: no step with provided index");
        SwapStep calldata step = params_.swap.steps[params_.stepIndex];
        _validateSwapSignature(params_.swap, params_.swapSignature, step);
        _performSwapStep(step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function swapStealth(StealthSwapParams calldata params_) external payable {
        _checkSwapEnabled();
        _validateStealthSwapSignature(params_.swap, params_.swapSignature, params_.step);
        _performSwapStep(params_.step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function _checkSwapEnabled() internal view virtual {
        return; // Nothing is hindering by default
    }

    function _validateSwapSignature(
        Swap calldata swap_,
        bytes calldata swapSignature_,
        SwapStep calldata step_
    ) private view {
        if (_isSignaturePresented(swapSignature_)) {
            _swapSignatureValidator().validateSwapSignature(swap_, swapSignature_);
        } else {
            _validateStepManualCaller(step_);
        }
    }

    function _validateStealthSwapSignature(
        StealthSwap calldata stealthSwap_,
        bytes calldata stealthSwapSignature_,
        SwapStep calldata step_
    ) private view {
        if (_isSignaturePresented(stealthSwapSignature_)) {
            _swapSignatureValidator().validateStealthSwapStepSignature(step_, stealthSwap_, stealthSwapSignature_);
        } else {
            _validateStepManualCaller(step_);
            _swapSignatureValidator().findStealthSwapStepIndex(step_, stealthSwap_); // Ensure presented
        }
    }

    function _isSignaturePresented(bytes calldata signature_) private pure returns (bool) {
        return signature_.length > 0;
    }

    function _validateStepManualCaller(SwapStep calldata step_) private view {
        require(msg.sender == step_.account, "SW: caller must be step account");
    }

    function _performSwapStep(
        SwapStep calldata step_,
        Permit[] calldata permits_,
        uint256[] calldata inAmounts_,
        Call calldata call_,
        bytes[] calldata useArgs_
    ) private {
        // solhint-disable-next-line not-rely-on-time
        require(step_.deadline > block.timestamp, "SW: swap step expired");
        require(step_.chain == block.chainid, "SW: wrong swap step chain");
        require(step_.swapper == address(this), "SW: wrong swap step swapper");
        require(step_.ins.length == inAmounts_.length, "SW: in amounts length mismatch");

        _useNonce(step_.account, step_.nonce);
        _usePermits(step_.account, permits_);

        uint256[] memory outAmounts = _performCall(
            step_.account,
            step_.useDelegate,
            step_.ins,
            inAmounts_,
            step_.outs,
            call_
        );
        _performUses(step_.uses, useArgs_, step_.outs, outAmounts);
    }

    function _useNonce(address account_, uint256 nonce_) private {
        require(!_nonceUsed(account_, nonce_), "SW: invalid nonce");
        _setNonceUsed(account_, nonce_, true);
    }

    function _usePermits(address account_, Permit[] calldata permits_) private {
        for (uint256 i = 0; i < permits_.length; i++) {
            _usePermit(account_, permits_[i]);
        }
    }

    function _usePermit(address account_, Permit calldata permit_) private {
        require(_permitResolverWhitelist().isAccountWhitelisted(permit_.resolver), "SW: permitter not whitelisted");
        IPermitResolver(permit_.resolver).resolvePermit(
            permit_.token,
            account_,
            permit_.amount,
            permit_.deadline,
            permit_.signature
        );
    }

    function _performCall(
        address account_,
        bool useDelegate_,
        TokenCheck[] calldata ins_,
        uint256[] calldata inAmounts_,
        TokenCheck[] calldata outs_,
        Call calldata call_
    ) private returns (uint256[] memory outAmounts) {
        NativeClaimer.State memory nativeClaimer;
        // prettier-ignore
        return _performCallWithReturn(
            account_,
            useDelegate_,
            ins_,
            inAmounts_,
            outs_,
            call_,
            nativeClaimer
        );
    }

    function _performCallWithReturn(
        address account_,
        bool useDelegate_,
        TokenCheck[] calldata ins_,
        uint256[] calldata inAmounts_,
        TokenCheck[] calldata outs_,
        Call calldata call_,
        NativeClaimer.State memory nativeClaimer_
    ) private returnUnclaimedNative(nativeClaimer_) returns (uint256[] memory outAmounts) {
        // Ensure input amounts are within the min-max range
        for (uint256 i = 0; i < ins_.length; i++) {
            TokenChecker.checkMinMax(ins_[i], inAmounts_[i]);
        }

        // Calc input amounts to claim (per token)
        AccountCounter.State memory inAmountsByToken = AccountCounter.create(ins_.length);
        for (uint256 i = 0; i < ins_.length; i++) {
            inAmountsByToken.add(ins_[i].token, inAmounts_[i]);
        }

        // Claim inputs
        if (useDelegate_) {
            _claimAccountDelegateCallIns(account_, inAmountsByToken);
        } else {
            _claimAccountCallIns(account_, inAmountsByToken, nativeClaimer_);
        }

        // Snapshot output balances before call
        AccountCounter.State memory outBalances = AccountCounter.create(outs_.length);
        for (uint256 i = 0; i < outs_.length; i++) {
            address token = outs_[i].token;
            uint256 sizeBefore = outBalances.size();
            uint256 tokenIndex = outBalances.indexOf(token);
            if (sizeBefore != outBalances.size()) {
                outBalances.setAt(tokenIndex, TokenHelper.balanceOfThis(token, nativeClaimer_));
            }
        }
        uint256 totalOutTokens = outBalances.size();

        // Approve call assets
        uint256 sendValue = _approveAssets(inAmountsByToken, call_.target);

        // Do the call
        bytes memory result = Address.functionCallWithValue(call_.target, call_.data, sendValue);

        // Revoke call assets
        _revokeAssets(inAmountsByToken, call_.target);

        // Decrease output balances by (presumably) spent inputs
        for (uint256 i = 0; i < totalOutTokens; i++) {
            address token = outBalances.accountAt(i);
            uint256 tokenInIndex = inAmountsByToken.indexOf(token, false);
            if (!AccountCounter.isNullIndex(tokenInIndex)) {
                uint256 inAmount = inAmountsByToken.getAt(tokenInIndex);
                outBalances.subAt(i, inAmount);
            }
        }

        // Replace balances before with remaining balances to "spend" on amount checks
        for (uint256 i = 0; i < totalOutTokens; i++) {
            address token = outBalances.accountAt(i);
            uint256 balanceNow = TokenHelper.balanceOfThis(token, nativeClaimer_);
            outBalances.setAt(i, balanceNow - outBalances.getAt(i));
        }

        // Parse outputs from result
        outAmounts = abi.decode(result, (uint256[]));
        require(outAmounts.length == outs_.length, "SW: out amounts length mismatch");

        // Validate output amounts
        for (uint256 i = 0; i < outs_.length; i++) {
            uint256 amount = TokenChecker.checkMin(outs_[i], outAmounts[i]);
            outAmounts[i] = amount;
            uint256 tokenIndex = outBalances.indexOf(outs_[i].token, false);
            require(outBalances.getAt(tokenIndex) >= amount, "SW: insufficient out amount");
            outBalances.subAt(tokenIndex, amount);
        }
    }

    function _claimAccountDelegateCallIns(address account_, AccountCounter.State memory inAmountsByToken_) private {
        uint256 totalInTokens = inAmountsByToken_.size();
        Withdraw[] memory withdraws = new Withdraw[](totalInTokens);
        for (uint256 i = 0; i < totalInTokens; i++) {
            address token = inAmountsByToken_.accountAt(i);
            uint256 amount = inAmountsByToken_.getAt(i);
            withdraws[i] = Withdraw({token: token, amount: amount, to: address(this)});
        }

        IDelegateManager delegateManager = _delegateManager();
        if (!delegateManager.isDelegateDeployed(account_)) {
            delegateManager.deployDelegate(account_);
        }
        delegateManager.withdraw(account_, withdraws);
    }

    function _claimAccountCallIns(
        address account_,
        AccountCounter.State memory inAmountsByToken_,
        NativeClaimer.State memory nativeClaimer_
    ) private {
        uint256 totalInTokens = inAmountsByToken_.size();
        for (uint256 i = 0; i < totalInTokens; i++) {
            address token = inAmountsByToken_.accountAt(i);
            uint256 amount = inAmountsByToken_.getAt(i);
            TokenHelper.transferToThis(token, account_, amount, nativeClaimer_);
        }
    }

    function _approveAssets(
        AccountCounter.State memory amountsByToken_,
        address spender_
    ) private returns (uint256 sendValue) {
        uint256 totalTokens = amountsByToken_.size();
        for (uint256 i = 0; i < totalTokens; i++) {
            address token = amountsByToken_.accountAt(i);
            uint256 amount = amountsByToken_.getAt(i);
            sendValue += TokenHelper.approveOfThis(token, spender_, amount);
        }
    }

    function _revokeAssets(AccountCounter.State memory amountsByToken_, address spender_) private {
        uint256 totalTokens = amountsByToken_.size();
        for (uint256 i = 0; i < totalTokens; i++) {
            address token = amountsByToken_.accountAt(i);
            TokenHelper.revokeOfThis(token, spender_);
        }
    }

    function _performUses(
        TokenUse[] calldata uses_,
        bytes[] calldata useArgs_,
        TokenCheck[] calldata useIns_,
        uint256[] memory useInAmounts_
    ) private {
        uint256 dynamicArgsCursor = 0;
        for (uint256 i = 0; i < uses_.length; i++) {
            bytes calldata args = uses_[i].args;
            if (_shouldUseDynamicArgs(args)) {
                require(dynamicArgsCursor < useArgs_.length, "SW: not enough dynamic use args");
                args = useArgs_[dynamicArgsCursor];
                dynamicArgsCursor++;
            }
            _performUse(uses_[i], args, useIns_, useInAmounts_);
        }
        require(dynamicArgsCursor == useArgs_.length, "SW: too many dynamic use args");
    }

    function _shouldUseDynamicArgs(bytes calldata args_) private pure returns (bool) {
        if (args_.length != 7) {
            return false;
        }
        return bytes7(args_) == 0x44796E616D6963; // "Dynamic" in ASCII
    }

    function _performUse(
        TokenUse calldata use_,
        bytes calldata args_,
        TokenCheck[] calldata useIns_,
        uint256[] memory useInAmounts_
    ) private {
        require(_useProtocolWhitelist().isAccountWhitelisted(use_.protocol), "SW: use protocol not whitelisted");

        TokenCheck[] memory ins = new TokenCheck[](use_.inIndices.length);
        uint256[] memory inAmounts = new uint256[](use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++) {
            uint256 inIndex = use_.inIndices[i];
            _ensureUseInputUnspent(useInAmounts_, inIndex);
            ins[i] = useIns_[inIndex];
            inAmounts[i] = useInAmounts_[inIndex];
            _spendUseInput(useInAmounts_, inIndex);
        }

        AccountCounter.State memory useInAmounts = AccountCounter.create(use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++) {
            useInAmounts.add(ins[i].token, inAmounts[i]);
        }

        uint256 sendValue = _approveAssets(useInAmounts, use_.protocol);
        IUseProtocol(use_.protocol).use{value: sendValue}(
            UseParams({
                chain: use_.chain,
                account: use_.account,
                ins: ins,
                inAmounts: inAmounts,
                outs: use_.outs,
                args: args_,
                msgSender: msg.sender,
                msgData: msg.data
            })
        );
        _revokeAssets(useInAmounts, use_.protocol);
    }

    uint256 private constant _SPENT_USE_INPUT = type(uint256).max;

    function _spendUseInput(uint256[] memory inAmounts_, uint256 index_) private pure {
        inAmounts_[index_] = _SPENT_USE_INPUT;
    }

    function _ensureUseInputUnspent(uint256[] memory inAmounts_, uint256 index_) private pure {
        require(inAmounts_[index_] != _SPENT_USE_INPUT, "SW: input already spent");
    }
}