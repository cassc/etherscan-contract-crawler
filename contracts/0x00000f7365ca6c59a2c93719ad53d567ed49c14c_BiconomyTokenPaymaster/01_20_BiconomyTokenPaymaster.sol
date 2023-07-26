// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IEntryPoint} from "@account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {UserOperation} from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import {UserOperationLib} from "@account-abstraction/contracts/interfaces/UserOperation.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {BasePaymaster} from "../BasePaymaster.sol";
import {IOracleAggregator} from "./oracles/IOracleAggregator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@account-abstraction/contracts/core/Helpers.sol" as Helpers;
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "../utils/SafeTransferLib.sol";
import {TokenPaymasterErrors} from "./TokenPaymasterErrors.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Biconomy Token Paymaster
/**
 * A token-based paymaster that allows user to pay gas fee in ERC20 tokens. The paymaster owner chooses which tokens to accept.
 * The payment manager (usually the owner) first deposits native gas into the EntryPoint. Then, for each transaction, it takes the gas fee from the user's ERC20 token balance.
 * The manager must convert these collected tokens back to native gas and deposit it into the EntryPoint to keep the system running.
 * It is an extension of VerifyingPaymaster which trusts external signer to authorize the transaction, but also with an ability to withdraw tokens.
 *
 * The validatePaymasterUserOp function does not interact with external contracts but uses an externally provided exchange rate.
 * Based on the exchangeRate and requiredPrefund amount, the validation method checks if the user's account has enough token balance. This is done by only looking at the referenced storage.
 * All Withdrawn tokens are sent to a dynamic fee receiver address.
 *
 * Optionally a safe guard deposit may be used in future versions.
 */
contract BiconomyTokenPaymaster is
    BasePaymaster,
    ReentrancyGuard,
    TokenPaymasterErrors
{
    using ECDSA for bytes32;
    using Address for address;
    using UserOperationLib for UserOperation;

    /**
     * price source can be off-chain calculation or oracles
     * for oracle based it can be based on chainlink feeds or TWAP oracles
     * for ORACLE_BASED oracle aggregator address has to be passed in paymasterAndData
     */
    enum ExchangeRateSource {
        EXTERNAL_EXCHANGE_RATE,
        ORACLE_BASED
    }

    // 1. use mode and based on mode treat uint256 fee sent either as priceMarkup or flatFee
    // 2. (no mode required) add extra value in paymasterandData so uint32 markup and uint224 flatFee both can be parsed
    // 3. (no mode required) without extra value treat uint256 as packed uint32uint224 and use values accordingly
    /*enum FeePremiumMode {
        PERCENTAGE,
        FLAT
    }*/

    /// @notice All 'price' variable coming from outside are expected to be multiple of 1e6, and in actual calculation,
    /// final value is divided by PRICE_DENOMINATOR to avoid rounding up.
    uint32 private constant PRICE_DENOMINATOR = 1e6;

    // Gas used in EntryPoint._handlePostOp() method (including this#postOp() call)
    uint256 public UNACCOUNTED_COST = 45000; // TBD

    // Always rely on verifyingSigner..
    address public verifyingSigner;

    // receiver of withdrawn fee tokens
    address public feeReceiver;

    // paymasterAndData: concat of [paymasterAddress(address), priceSource(enum 1 byte), abi.encode(validUntil, validAfter, feeToken, oracleAggregator, exchangeRate, priceMarkup): makes up 32*6 bytes, signature]
    // PND offset is used to indicate offsets to decode, used along with Signature offset
    uint256 private constant VALID_PND_OFFSET = 21;

    uint256 private constant SIGNATURE_OFFSET = 213;

    address private constant NATIVE_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * Designed to enable the community to track change in storage variable UNACCOUNTED_COST which is used
     * to maintain gas execution cost which can't be calculated within contract*/
    event EPGasOverheadChanged(
        uint256 indexed _oldOverheadCost,
        uint256 indexed _newOverheadCost,
        address indexed _actor
    );

    /**
     * Designed to enable the community to track change in storage variable verifyingSigner which is used
     * to authorize any operation for this paymaster (validation stage) and provides signature*/
    event VerifyingSignerChanged(
        address indexed _oldSigner,
        address indexed _newSigner,
        address indexed _actor
    );

    /**
     * Designed to enable the community to track change in storage variable feeReceiver which is an address (self or other SCW/EOA)
     * responsible for collecting all the tokens being withdrawn as fees*/
    event FeeReceiverChanged(
        address indexed _oldfeeReceiver,
        address indexed _newfeeReceiver,
        address indexed _actor
    );

    /**
     * Designed to enable tracking how much fees were charged from the sender and in which ERC20 token
     * More information can be emitted like exchangeRate used, what was the source of exchangeRate etc*/
    // priceMarkup = Multiplier value to calculate markup, 1e6 means 1x multiplier = No markup
    event TokenPaymasterOperation(
        address indexed sender,
        address indexed token,
        uint256 indexed totalCharge,
        address oracleAggregator,
        uint32 priceMarkup,
        bytes32 userOpHash,
        uint256 exchangeRate,
        ExchangeRateSource priceSource
    );

    /**
     * Notify in case paymaster failed to withdraw tokens from sender
     */
    event TokenPaymentDue(
        address indexed token,
        address indexed account,
        uint256 indexed charge
    );

    event Received(address indexed sender, uint256 value);

    constructor(
        address _owner,
        IEntryPoint _entryPoint,
        address _verifyingSigner
    ) payable BasePaymaster(_owner, _entryPoint) {
        if (_owner == address(0)) revert OwnerCannotBeZero();
        if (address(_entryPoint) == address(0)) revert EntryPointCannotBeZero();
        if (_verifyingSigner == address(0))
            revert VerifyingSignerCannotBeZero();
        assembly ("memory-safe") {
            sstore(verifyingSigner.slot, _verifyingSigner)
            sstore(feeReceiver.slot, address()) // initialize with self (could also be _owner)
        }
    }

    /**
     * @dev Set a new verifying signer address.
     * Can only be called by the owner of the contract.
     * @param _newVerifyingSigner The new address to be set as the verifying signer.
     * @notice If _newVerifyingSigner is set to zero address, it will revert with an error.
     * After setting the new signer address, it will emit an event VerifyingSignerChanged.
     */
    function setVerifyingSigner(
        address _newVerifyingSigner
    ) external payable onlyOwner {
        if (_newVerifyingSigner == address(0))
            revert VerifyingSignerCannotBeZero();
        address oldSigner = verifyingSigner;
        assembly ("memory-safe") {
            sstore(verifyingSigner.slot, _newVerifyingSigner)
        }
        emit VerifyingSignerChanged(oldSigner, _newVerifyingSigner, msg.sender);
    }

    // marked for removal
    /**
     * @dev Set a new fee receiver.
     * Can only be called by the owner of the contract.
     * @param _newFeeReceiver The new address to be set as the address of new fee receiver.
     * @notice If _newFeeReceiver is set to zero address, it will revert with an error.
     * After setting the new address, it will emit an event FeeReceiverChanged.
     */
    function setFeeReceiver(
        address _newFeeReceiver
    ) external payable onlyOwner {
        if (_newFeeReceiver == address(0)) revert FeeReceiverCannotBeZero();
        address oldFeeReceiver = feeReceiver;
        assembly ("memory-safe") {
            sstore(feeReceiver.slot, _newFeeReceiver)
        }
        emit FeeReceiverChanged(oldFeeReceiver, _newFeeReceiver, msg.sender);
    }

    /**
     * @dev Set a new overhead for unaccounted cost
     * Can only be called by the owner of the contract.
     * @param _newOverheadCost The new value to be set as the gas cost overhead.
     * @notice If _newOverheadCost is set to very high value, it will revert with an error.
     * After setting the new value, it will emit an event EPGasOverheadChanged.
     */
    function setUnaccountedEPGasOverhead(
        uint256 _newOverheadCost
    ) external payable onlyOwner {
        // review if this could be high value in case of arbitrum
        if (_newOverheadCost > 200000) revert CannotBeUnrealisticValue();
        uint256 oldValue = UNACCOUNTED_COST;
        assembly ("memory-safe") {
            sstore(UNACCOUNTED_COST.slot, _newOverheadCost)
        }
        emit EPGasOverheadChanged(oldValue, _newOverheadCost, msg.sender);
    }

    /**
     * Add a deposit in native currency for this paymaster, used for paying for transaction fees.
     * This is ideally done by the entity who is managing the received ERC20 gas tokens.
     */
    function deposit() public payable virtual override nonReentrant {
        IEntryPoint(entryPoint).depositTo{value: msg.value}(address(this));
    }

    /**
     * @dev Withdraws the specified amount of gas tokens from the paymaster's balance and transfers them to the specified address.
     * @param withdrawAddress The address to which the gas tokens should be transferred.
     * @param amount The amount of gas tokens to withdraw.
     */
    function withdrawTo(
        address payable withdrawAddress,
        uint256 amount
    ) public override onlyOwner nonReentrant {
        if (withdrawAddress == address(0)) revert CanNotWithdrawToZeroAddress();
        entryPoint.withdrawTo(withdrawAddress, amount);
    }

    /**
     * @dev Returns the exchange price of the token in wei.
     * @param _token ERC20 token address
     * @param _oracleAggregator oracle aggregator address
     */
    function exchangePrice(
        address _token,
        address _oracleAggregator
    ) internal view virtual returns (uint256) {
        try
            IOracleAggregator(_oracleAggregator).getTokenValueOfOneNativeToken(
                _token
            )
        returns (uint256 exchangeRate) {
            return exchangeRate;
        } catch {
            return 0;
        }
    }

    /**
     * @dev pull tokens out of paymaster in case they were sent to the paymaster at any point.
     * @param token the token deposit to withdraw
     * @param target address to send to
     * @param amount amount to withdraw
     */
    function withdrawERC20(
        IERC20 token,
        address target,
        uint256 amount
    ) public payable onlyOwner nonReentrant {
        _withdrawERC20(token, target, amount);
    }

    /**
     * @dev pull tokens out of paymaster in case they were sent to the paymaster at any point.
     * @param token the token deposit to withdraw
     * @param target address to send to
     */
    function withdrawERC20Full(
        IERC20 token,
        address target
    ) public payable onlyOwner nonReentrant {
        uint256 amount = token.balanceOf(address(this));
        _withdrawERC20(token, target, amount);
    }

    /**
     * @dev pull multiple tokens out of paymaster in case they were sent to the paymaster at any point.
     * @param token the tokens deposit to withdraw
     * @param target address to send to
     * @param amount amounts to withdraw
     */
    function withdrawMultipleERC20(
        IERC20[] calldata token,
        address target,
        uint256[] calldata amount
    ) public payable onlyOwner nonReentrant {
        if (token.length != amount.length)
            revert TokensAndAmountsLengthMismatch();
        unchecked {
            for (uint256 i; i < token.length; ) {
                _withdrawERC20(token[i], target, amount[i]);
                ++i;
            }
        }
    }

    /**
     * @dev pull multiple tokens out of paymaster in case they were sent to the paymaster at any point.
     * @param token the tokens deposit to withdraw
     * @param target address to send to
     */
    function withdrawMultipleERC20Full(
        IERC20[] calldata token,
        address target
    ) public payable onlyOwner nonReentrant {
        unchecked {
            for (uint256 i; i < token.length; ) {
                uint256 amount = token[i].balanceOf(address(this));
                _withdrawERC20(token[i], target, amount);
                ++i;
            }
        }
    }

    /**
     * @dev pull native tokens out of paymaster in case they were sent to the paymaster at any point
     * @param dest address to send to
     */
    function withdrawAllNative(
        address dest
    ) public payable onlyOwner nonReentrant {
        uint256 _balance = address(this).balance;
        if (_balance == 0) revert NativeTokenBalanceZero();
        if (dest == address(0)) revert CanNotWithdrawToZeroAddress();
        bool success;
        assembly ("memory-safe") {
            success := call(gas(), dest, _balance, 0, 0, 0, 0)
        }
        if (!success) revert NativeTokensWithdrawalFailed();
    }

    /**
     * @dev This method is called by the off-chain service, to sign the request.
     * It is called on-chain from the validatePaymasterUserOp, to validate the signature.
     * @notice That this signature covers all fields of the UserOperation, except the "paymasterAndData",
     * which will carry the signature itself.
     * @return hash we're going to sign off-chain (and validate on-chain)
     */
    function getHash(
        UserOperation calldata userOp,
        ExchangeRateSource priceSource,
        uint48 validUntil,
        uint48 validAfter,
        address feeToken,
        address oracleAggregator,
        uint256 exchangeRate,
        uint32 priceMarkup
    ) public view returns (bytes32) {
        //can't use userOp.hash(), since it contains also the paymasterAndData itself.
        return
            keccak256(
                abi.encode(
                    userOp.getSender(),
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.callGasLimit,
                    userOp.verificationGasLimit,
                    userOp.preVerificationGas,
                    userOp.maxFeePerGas,
                    userOp.maxPriorityFeePerGas,
                    block.chainid,
                    address(this),
                    priceSource,
                    validUntil,
                    validAfter,
                    feeToken,
                    oracleAggregator,
                    exchangeRate,
                    priceMarkup
                )
            );
    }

    function parsePaymasterAndData(
        bytes calldata paymasterAndData
    )
        public
        pure
        returns (
            ExchangeRateSource priceSource,
            uint48 validUntil,
            uint48 validAfter,
            address feeToken,
            address oracleAggregator,
            uint256 exchangeRate,
            uint32 priceMarkup,
            bytes calldata signature
        )
    {
        // paymasterAndData.length should be at least SIGNATURE_OFFSET + 65 (checked separate)
        require(
            paymasterAndData.length >= SIGNATURE_OFFSET,
            "BTPM: Invalid length for paymasterAndData"
        );
        priceSource = ExchangeRateSource(
            uint8(
                bytes1(paymasterAndData[VALID_PND_OFFSET - 1:VALID_PND_OFFSET])
            )
        );
        (
            validUntil,
            validAfter,
            feeToken,
            oracleAggregator,
            exchangeRate,
            priceMarkup
        ) = abi.decode(
            paymasterAndData[VALID_PND_OFFSET:SIGNATURE_OFFSET],
            (uint48, uint48, address, address, uint256, uint32)
        );
        signature = paymasterAndData[SIGNATURE_OFFSET:];
    }

    function _getRequiredPrefund(
        UserOperation calldata userOp
    ) internal view returns (uint256 requiredPrefund) {
        unchecked {
            uint256 requiredGas = userOp.callGasLimit +
                userOp.verificationGasLimit +
                userOp.preVerificationGas +
                UNACCOUNTED_COST;

            requiredPrefund = requiredGas * userOp.maxFeePerGas;
        }
    }

    /**
     * @dev Verify that an external signer signed the paymaster data of a user operation.
     * The paymaster data is expected to be the paymaster address, request data and a signature over the entire request parameters.
     * paymasterAndData: hexConcat([paymasterAddress, priceSource, abi.encode(validUntil, validAfter, feeToken, oracleAggregator, exchangeRate, priceMarkup), signature])
     * @param userOp The UserOperation struct that represents the current user operation.
     * userOpHash The hash of the UserOperation struct.
     * @param requiredPreFund The required amount of pre-funding for the paymaster.
     * @return context A context string returned by the entry point after successful validation.
     * @return validationData An integer returned by the entry point after successful validation.
     */
    function _validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 requiredPreFund
    )
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        (requiredPreFund);
        // verificationGasLimit is dual-purposed, as gas limit for postOp. make sure it is high enough
        // make sure that verificationGasLimit is high enough to handle postOp
        require(
            userOp.verificationGasLimit > UNACCOUNTED_COST,
            "BTPM: gas too low for postOp"
        );

        // review: in this method try to resolve stack too deep (though via-ir is good enough)
        (
            ExchangeRateSource priceSource,
            uint48 validUntil,
            uint48 validAfter,
            address feeToken,
            address oracleAggregator,
            uint256 exchangeRate,
            uint32 priceMarkup,
            bytes calldata signature
        ) = parsePaymasterAndData(userOp.paymasterAndData);

        // we only "require" it here so that the revert reason on invalid signature will be of "VerifyingPaymaster", and not "ECDSA"
        require(
            signature.length == 65,
            "BTPM: invalid signature length in paymasterAndData"
        );

        bytes32 _hash = getHash(
            userOp,
            priceSource,
            validUntil,
            validAfter,
            feeToken,
            oracleAggregator,
            exchangeRate,
            priceMarkup
        ).toEthSignedMessageHash();

        context = "";

        //don't revert on signature failure: return SIG_VALIDATION_FAILED
        if (verifyingSigner != _hash.recover(signature)) {
            // empty context and sigFailed true
            return (
                context,
                Helpers._packValidationData(true, validUntil, validAfter)
            );
        }

        address account = userOp.getSender();

        // This model assumes irrespective of priceSource exchangeRate is always sent from outside
        // for below checks you would either need maxCost or some exchangeRate

        uint256 btpmRequiredPrefund = _getRequiredPrefund(userOp);

        uint256 tokenRequiredPreFund = (btpmRequiredPrefund * exchangeRate) /
            10 ** 18;
        require(
            tokenRequiredPreFund != 0,
            "BTPM: calculated token charge invalid"
        );
        require(priceMarkup <= 2e6, "BTPM: price markup percentage too high");
        require(priceMarkup >= 1e6, "BTPM: price markup percentage too low");
        require(
            IERC20(feeToken).balanceOf(account) >=
                ((tokenRequiredPreFund * priceMarkup) / PRICE_DENOMINATOR),
            "BTPM: account does not have enough token balance"
        );

        context = abi.encode(
            account,
            feeToken,
            oracleAggregator,
            priceSource,
            exchangeRate,
            priceMarkup,
            userOpHash
        );

        return (
            context,
            Helpers._packValidationData(false, validUntil, validAfter)
        );
    }

    /**
     * @dev Executes the paymaster's payment conditions
     * @param mode tells whether the op succeeded, reverted, or if the op succeeded but cause the postOp to revert
     * @param context payment conditions signed by the paymaster in `validatePaymasterUserOp`
     * @param actualGasCost amount to be paid to the entry point in wei
     */
    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal virtual override {
        (
            address account,
            IERC20 feeToken,
            address oracleAggregator,
            ExchangeRateSource priceSource,
            uint256 exchangeRate,
            uint32 priceMarkup,
            bytes32 userOpHash
        ) = abi.decode(
                context,
                (
                    address,
                    IERC20,
                    address,
                    ExchangeRateSource,
                    uint256,
                    uint32,
                    bytes32
                )
            );

        uint256 effectiveExchangeRate = exchangeRate;

        if (
            priceSource == ExchangeRateSource.ORACLE_BASED &&
            oracleAggregator != address(NATIVE_ADDRESS) &&
            oracleAggregator != address(0)
        ) {
            uint256 result = exchangePrice(address(feeToken), oracleAggregator);
            if (result != 0) effectiveExchangeRate = result;
        }

        // We could either touch the state for BASEFEE and calculate based on maxPriorityFee passed (to be added in context along with maxFeePerGas) or just use tx.gasprice
        uint256 charge; // Final amount to be charged from user account
        {
            uint256 actualTokenCost = ((actualGasCost +
                (UNACCOUNTED_COST * tx.gasprice)) * effectiveExchangeRate) /
                1e18;
            charge = ((actualTokenCost * priceMarkup) / PRICE_DENOMINATOR);
        }

        if (mode != PostOpMode.postOpReverted) {
            SafeTransferLib.safeTransferFrom(
                address(feeToken),
                account,
                feeReceiver,
                charge
            );
            emit TokenPaymasterOperation(
                account,
                address(feeToken),
                charge,
                oracleAggregator,
                priceMarkup,
                userOpHash,
                effectiveExchangeRate,
                priceSource
            );
        } else {
            // In case transferFrom failed in first handlePostOp call, attempt to charge the tokens again
            bytes memory _data = abi.encodeWithSelector(
                feeToken.transferFrom.selector,
                account,
                feeReceiver,
                charge
            );
            (bool success, bytes memory returndata) = address(feeToken).call(
                _data
            );
            if (!success) {
                // In case above transferFrom failed, pay with deposit / notify at least
                // Sender could be banned indefinitely or for certain period
                emit TokenPaymentDue(address(feeToken), account, charge);
                // Do nothing else here to not revert the whole bundle and harm reputation
            }
        }
    }

    function _withdrawERC20(
        IERC20 token,
        address target,
        uint256 amount
    ) private {
        if (target == address(0)) revert CanNotWithdrawToZeroAddress();
        SafeTransferLib.safeTransfer(address(token), target, amount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}