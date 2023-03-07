// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {NativeClaimer} from "../asset/NativeClaimer.sol";
import {NativeReceiver} from "../asset/NativeReceiver.sol";
import {NativeReturnMods} from "../asset/NativeReturnMods.sol";
import {TokenChecker} from "../asset/TokenChecker.sol";
import {TokenHelper} from "../asset/TokenHelper.sol";
import {DelegateManager} from "../delegate/DelegateManager.sol";
import {AccountCounter} from "../misc/AccountCounter.sol";
import {PermitResolver} from "../permit/PermitResolver.sol";
import {AccountWhitelist} from "../whitelist/AccountWhitelist.sol";
import {Withdraw} from "../withdraw/Withdrawable.sol";
import {Swap, SwapStep, TokenUse, StealthSwap, TokenCheck, IUseProtocol, UseParams} from "./Swap.sol";
import {SwapSignatureValidator} from "./SwapSignatureValidator.sol";

struct Permit {
    address resolver;
    address token;
    uint256 amount;
    uint256 deadline;
    bytes signature;
}

struct Call {
    address target;
    bytes data;
}

struct SwapParams {
    Swap swap;
    bytes swapSignature;
    uint256 stepIndex;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

struct StealthSwapParams {
    StealthSwap swap;
    bytes swapSignature;
    SwapStep step;
    Permit[] permits;
    uint256[] inAmounts;
    Call call;
    bytes[] useArgs;
}

contract Swapper is NativeReceiver, NativeReturnMods {
    using AccountCounter for AccountCounter.State;

    address private immutable _swapSignatureValidator;
    address private immutable _permitResolverWhitelist;
    address private immutable _useProtocolWhitelist;
    address private immutable _delegateManager;
    mapping(address => mapping(uint256 => bool)) private _usedNonces;

    constructor(address swapSignatureValidator_, address permitResolverWhitelist_, address useProtocolWhitelist_, address delegateManager_) {
        _swapSignatureValidator = swapSignatureValidator_;
        _permitResolverWhitelist = permitResolverWhitelist_;
        _useProtocolWhitelist = useProtocolWhitelist_;
        _delegateManager = delegateManager_;
    }

    function swap(SwapParams calldata params_) external payable {
        _checkSwapEnabled();
        require(params_.stepIndex < params_.swap.steps.length, "SW: no step with provided index");
        SwapStep calldata step = params_.swap.steps[params_.stepIndex];
        _validateSwapSignature(params_.swap, params_.swapSignature);
        _performSwapStep(params_.swap.account, step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function swapStealth(StealthSwapParams calldata params_) external payable {
        _checkSwapEnabled();
        _validateStealthSwapSignature(params_.swap, params_.swapSignature, params_.step);
        _performSwapStep(params_.swap.account, params_.step, params_.permits, params_.inAmounts, params_.call, params_.useArgs);
    }

    function _checkSwapEnabled() internal view virtual {} // Nothing is hindering by default

    function _validateSwapSignature(Swap calldata swap_, bytes calldata swapSignature_) private view {
        if (_isSignaturePresented(swapSignature_))
            SwapSignatureValidator(_swapSignatureValidator).validateSwapSignature(swap_, swapSignature_);
        else _validateSwapManualCaller(swap_.account);
    }

    function _validateStealthSwapSignature(StealthSwap calldata stealthSwap_, bytes calldata stealthSwapSignature_, SwapStep calldata step_) private view {
        if (_isSignaturePresented(stealthSwapSignature_))
            SwapSignatureValidator(_swapSignatureValidator).validateStealthSwapStepSignature(step_, stealthSwap_, stealthSwapSignature_);
        else {
            _validateSwapManualCaller(stealthSwap_.account);
            SwapSignatureValidator(_swapSignatureValidator).findStealthSwapStepIndex(step_, stealthSwap_); // Ensure presented
        }
    }

    function _isSignaturePresented(bytes calldata signature_) private pure returns (bool) {
        return signature_.length > 0;
    }

    function _validateSwapManualCaller(address account_) private view {
        require(msg.sender == account_, "SW: caller must be swap account");
    }

    function _performSwapStep(address account_, SwapStep calldata step_, Permit[] calldata permits_, uint256[] calldata inAmounts_, Call calldata call_, bytes[] calldata useArgs_) private {
        require(step_.deadline > block.timestamp, "SW: swap step expired");
        require(step_.chain == block.chainid, "SW: wrong swap step chain");
        require(step_.swapper == address(this), "SW: wrong swap step swapper");
        require(step_.ins.length == inAmounts_.length, "SW: in amounts length mismatch");

        _useNonce(account_, step_.nonce);
        _usePermits(account_, permits_);

        uint256[] memory outAmounts = _performCall(account_, step_.sponsor, step_.ins, inAmounts_, step_.outs, call_);
        _performUses(step_.uses, useArgs_, step_.outs, outAmounts);
    }

    function _useNonce(address account_, uint256 nonce_) private {
        require(!_usedNonces[account_][nonce_], "SW: invalid nonce");
        _usedNonces[account_][nonce_] = true;
    }

    function _usePermits(address account_, Permit[] calldata permits_) private {
        for (uint256 i = 0; i < permits_.length; i++)
            _usePermit(account_, permits_[i]);
    }

    function _usePermit(address account_, Permit calldata permit_) private {
        require(_isWhitelistedResolver(permit_.resolver), "SW: permitter not whitelisted");
        PermitResolver(permit_.resolver).resolvePermit(permit_.token, account_, permit_.amount, permit_.deadline, permit_.signature);
    }

    function _isWhitelistedResolver(address resolver_) private view returns (bool) {
        return AccountWhitelist(_permitResolverWhitelist).isAccountWhitelisted(resolver_);
    }

    function _performCall(address account_, address sponsor_, TokenCheck[] calldata ins_, uint256[] calldata inAmounts_, TokenCheck[] calldata outs_, Call calldata call_) private returns (uint256[] memory outAmounts) {
        NativeClaimer.State memory nativeClaimer;
        return _performCallWithReturn(account_, sponsor_, ins_, inAmounts_, outs_, call_, nativeClaimer);
    }

    function _performCallWithReturn(address account_, address sponsor_, TokenCheck[] calldata ins_, uint256[] calldata inAmounts_, TokenCheck[] calldata outs_, Call calldata call_, NativeClaimer.State memory nativeClaimer_) private returnUnclaimedNative(nativeClaimer_) returns (uint256[] memory outAmounts) {
        for (uint256 i = 0; i < ins_.length; i++)
            TokenChecker.checkMinMax(ins_[i], inAmounts_[i]);

        AccountCounter.State memory inAmountsByToken = AccountCounter.create(ins_.length);
        for (uint256 i = 0; i < ins_.length; i++)
            inAmountsByToken.add(ins_[i].token, inAmounts_[i]);

        address delegate = DelegateManager(_delegateManager).predictDelegateDeploy(account_);
        require(sponsor_ == account_ || sponsor_ == delegate || _isWhitelistedResolver(sponsor_), "SW: sponsor not allowed");
        if (sponsor_ == delegate) _claimDelegateCallIns(account_, inAmountsByToken);
        else _claimSponsorCallIns(sponsor_, inAmountsByToken, nativeClaimer_);

        AccountCounter.State memory outBalances = AccountCounter.create(outs_.length);
        for (uint256 i = 0; i < outs_.length; i++) {
            address token = outs_[i].token;
            uint256 sizeBefore = outBalances.size();
            uint256 tokenIndex = outBalances.indexOf(token);
            if (sizeBefore != outBalances.size())
                outBalances.setAt(tokenIndex, TokenHelper.balanceOfThis(token, nativeClaimer_));
        }
        uint256 totalOutTokens = outBalances.size();

        uint256 sendValue = _approveAssets(inAmountsByToken, call_.target);
        bytes memory result = Address.functionCallWithValue(call_.target, call_.data, sendValue);
        _revokeAssets(inAmountsByToken, call_.target);

        for (uint256 i = 0; i < totalOutTokens; i++) {
            uint256 tokenInIndex = inAmountsByToken.indexOf(outBalances.accountAt(i), false);
            if (!AccountCounter.isNullIndex(tokenInIndex))
                outBalances.subAt(i, inAmountsByToken.getAt(tokenInIndex));
        }

        for (uint256 i = 0; i < totalOutTokens; i++)
            outBalances.setAt(i, TokenHelper.balanceOfThis(outBalances.accountAt(i), nativeClaimer_) - outBalances.getAt(i));

        outAmounts = abi.decode(result, (uint256[]));
        require(outAmounts.length == outs_.length, "SW: out amounts length mismatch");

        for (uint256 i = 0; i < outs_.length; i++) {
            uint256 amount = TokenChecker.checkMin(outs_[i], outAmounts[i]);
            outAmounts[i] = amount;
            uint256 tokenIndex = outBalances.indexOf(outs_[i].token, false);
            require(outBalances.getAt(tokenIndex) >= amount, "SW: insufficient out amount");
            outBalances.subAt(tokenIndex, amount);
        }
    }

    function _claimDelegateCallIns(address account_, AccountCounter.State memory inAmountsByToken_) private {
        Withdraw[] memory withdraws = new Withdraw[](inAmountsByToken_.size());
        for (uint256 i = 0; i < inAmountsByToken_.size(); i++)
            withdraws[i] = Withdraw({token: inAmountsByToken_.accountAt(i), amount: inAmountsByToken_.getAt(i), to: address(this)});

        if (!DelegateManager(_delegateManager).isDelegateDeployed(account_))
            DelegateManager(_delegateManager).deployDelegate(account_);
        DelegateManager(_delegateManager).withdraw(account_, withdraws);
    }

    function _claimSponsorCallIns(address sponsor_, AccountCounter.State memory inAmountsByToken_, NativeClaimer.State memory nativeClaimer_) private {
        for (uint256 i = 0; i < inAmountsByToken_.size(); i++)
            TokenHelper.transferToThis(inAmountsByToken_.accountAt(i), sponsor_, inAmountsByToken_.getAt(i), nativeClaimer_);
    }

    function _approveAssets(AccountCounter.State memory amountsByToken_, address spender_) private returns (uint256 sendValue) {
        for (uint256 i = 0; i < amountsByToken_.size(); i++)
            sendValue += TokenHelper.approveOfThis(amountsByToken_.accountAt(i), spender_, amountsByToken_.getAt(i));
    }

    function _revokeAssets(AccountCounter.State memory amountsByToken_, address spender_) private {
        for (uint256 i = 0; i < amountsByToken_.size(); i++)
            TokenHelper.revokeOfThis(amountsByToken_.accountAt(i), spender_);
    }

    function _performUses(TokenUse[] calldata uses_, bytes[] calldata useArgs_, TokenCheck[] calldata useIns_, uint256[] memory useInAmounts_) private {
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
        if (args_.length != 7) return false;
        return bytes7(args_) == 0x44796E616D6963; // "Dynamic" in ASCII
    }

    function _performUse(TokenUse calldata use_, bytes calldata args_, TokenCheck[] calldata useIns_, uint256[] memory useInAmounts_) private {
        require(AccountWhitelist(_useProtocolWhitelist).isAccountWhitelisted(use_.protocol), "SW: use protocol not whitelisted");

        TokenCheck[] memory ins = new TokenCheck[](use_.inIndices.length);
        uint256[] memory inAmounts = new uint256[](use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++) {
            uint256 inIndex = use_.inIndices[i];
            require(useInAmounts_[inIndex] != type(uint256).max, "SW: input already spent");
            ins[i] = useIns_[inIndex];
            inAmounts[i] = useInAmounts_[inIndex];
            useInAmounts_[inIndex] = type(uint256).max; // Mark as spent
        }

        AccountCounter.State memory useInAmounts = AccountCounter.create(use_.inIndices.length);
        for (uint256 i = 0; i < use_.inIndices.length; i++)
            useInAmounts.add(ins[i].token, inAmounts[i]);

        uint256 sendValue = _approveAssets(useInAmounts, use_.protocol);
        IUseProtocol(use_.protocol).use{value: sendValue}(UseParams({chain: use_.chain, account: use_.account, ins: ins, inAmounts: inAmounts, outs: use_.outs, args: args_, msgSender: msg.sender, msgData: msg.data}));
        _revokeAssets(useInAmounts, use_.protocol);
    }
}