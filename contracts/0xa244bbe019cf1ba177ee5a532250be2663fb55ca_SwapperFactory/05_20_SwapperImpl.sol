// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IOracle} from "splits-oracle/interfaces/IOracle.sol";
import {PausableImpl} from "splits-utils/PausableImpl.sol";
import {QuotePair, QuoteParams, SortedQuotePair} from "splits-utils/LibQuotes.sol";
import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {TokenUtils} from "splits-utils/TokenUtils.sol";
import {WalletImpl} from "splits-utils/WalletImpl.sol";

import {ISwapperFlashCallback} from "./interfaces/ISwapperFlashCallback.sol";
import {PairScaledOfferFactors} from "./libraries/PairScaledOfferFactors.sol";

/// @title Swapper Implementation
/// @author 0xSplits
/// @notice A contract to trustlessly & automatically convert multi-token
/// onchain revenue into a particular output token.
/// Please be aware, owner has _FULL CONTROL_ of the deployment.
/// @dev This contract uses a modular oracle. Be very careful to use a secure
/// oracle with sensible settings for the desired behavior. Insecure oracles
/// will  result in catastrophic loss of funds.
/// This contract uses token = address(0) to refer to ETH.
contract SwapperImpl is WalletImpl, PausableImpl {
    /// -----------------------------------------------------------------------
    /// libraries
    /// -----------------------------------------------------------------------

    using SafeTransferLib for address;
    using SafeCastLib for uint256;
    using TokenUtils for address;
    using PairScaledOfferFactors for mapping(address => mapping(address => uint32));

    /// -----------------------------------------------------------------------
    /// errors
    /// -----------------------------------------------------------------------

    error Invalid_AmountsToBeneficiary();
    error Invalid_QuoteToken();
    error InsufficientFunds_InContract();
    error InsufficientFunds_FromTrader();

    /// -----------------------------------------------------------------------
    /// structs
    /// -----------------------------------------------------------------------

    struct InitParams {
        address owner;
        bool paused;
        address beneficiary;
        address tokenToBeneficiary;
        IOracle oracle;
        uint32 defaultScaledOfferFactor;
        SetPairScaledOfferFactorParams[] pairScaledOfferFactors;
    }

    struct SetPairScaledOfferFactorParams {
        QuotePair quotePair;
        uint32 scaledOfferFactor;
    }

    /// -----------------------------------------------------------------------
    /// events
    /// -----------------------------------------------------------------------

    event SetBeneficiary(address beneficiary);
    event SetTokenToBeneficiary(address tokenToBeneficiary);
    event SetOracle(IOracle oracle);
    event SetDefaultScaledOfferFactor(uint32 defaultScaledOfferFactor);
    event SetPairScaledOfferFactors(SetPairScaledOfferFactorParams[] params);

    event ReceiveETH(uint256 amount);
    event Payback(address indexed payer, uint256 amount);
    event Flash(
        address indexed beneficiary,
        address indexed trader,
        QuoteParams[] quoteParams,
        address tokenToBeneficiary,
        uint256[] amountsToBeneficiary,
        uint256 excessToBeneficiary
    );

    /// -----------------------------------------------------------------------
    /// storage
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// storage - constants & immutables
    /// -----------------------------------------------------------------------

    address public immutable swapperFactory;

    /// @dev percentages measured in hundredths of basis points
    uint32 internal constant PERCENTAGE_SCALE = 100_00_00; // = 100%

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

    /// slot 1 - 0 bytes free

    /// address to receive post-swap tokens
    address internal $beneficiary;
    /// 20 bytes

    /// used to track ETH payback in flash
    uint96 internal $_payback;
    /// 12 bytes

    /// slot 2 - 8 bytes free

    /// token type to send beneficiary
    /// @dev 0x0 used for ETH
    address internal $tokenToBeneficiary;
    /// 20 bytes

    /// default oracle price scaling factor
    /// @dev PERCENTAGE_SCALE = 1e6 = 100_00_00 = 100% = no discount or premium
    /// 99_00_00 = 99% = 1% discount to oracle; 101_00_00 = 101% = 1% premium to oracle
    /// 4 bytes
    uint32 internal $defaultScaledOfferFactor;

    /// slot 3 - 12 bytes free

    /// price oracle for `#flash`
    IOracle internal $oracle;
    /// 20 bytes

    /// slot 4 - 0 bytes free

    /// scaledOfferFactors for specific quote pairs
    /// 32 bytes
    mapping(address => mapping(address => uint32)) internal $_pairScaledOfferFactors;

    /// -----------------------------------------------------------------------
    /// constructor & initializer
    /// -----------------------------------------------------------------------

    constructor() {
        swapperFactory = msg.sender;
    }

    function initializer(InitParams calldata params_) external {
        // only swapperFactory may call `initializer`
        if (msg.sender != swapperFactory) revert Unauthorized();

        // don't need to init wallet separately
        __initPausable({owner_: params_.owner, paused_: params_.paused});

        $beneficiary = params_.beneficiary;
        $tokenToBeneficiary = params_.tokenToBeneficiary;
        $oracle = params_.oracle;
        $defaultScaledOfferFactor = params_.defaultScaledOfferFactor;

        $_pairScaledOfferFactors._set(params_.pairScaledOfferFactors);
    }

    /// -----------------------------------------------------------------------
    /// functions
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// functions - public & external - onlyOwner
    /// -----------------------------------------------------------------------

    /// set beneficiary
    function setBeneficiary(address beneficiary_) external onlyOwner {
        $beneficiary = beneficiary_;
        emit SetBeneficiary(beneficiary_);
    }

    /// set tokenToBeneficiary
    function setTokenToBeneficiary(address tokenToBeneficiary_) external onlyOwner {
        $tokenToBeneficiary = tokenToBeneficiary_;
        emit SetTokenToBeneficiary(tokenToBeneficiary_);
    }

    /// set oracle
    function setOracle(IOracle oracle_) external onlyOwner {
        $oracle = oracle_;
        emit SetOracle(oracle_);
    }

    /// set defaultScaledOfferFactor
    function setDefaultScaledOfferFactor(uint32 defaultScaledOfferFactor_) external onlyOwner {
        $defaultScaledOfferFactor = defaultScaledOfferFactor_;
        emit SetDefaultScaledOfferFactor(defaultScaledOfferFactor_);
    }

    /// set pair scaled offer factors
    function setPairScaledOfferFactors(SetPairScaledOfferFactorParams[] calldata params_) external onlyOwner {
        $_pairScaledOfferFactors._set(params_);
        emit SetPairScaledOfferFactors(params_);
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - view
    /// -----------------------------------------------------------------------

    function beneficiary() external view returns (address) {
        return $beneficiary;
    }

    function tokenToBeneficiary() external view returns (address) {
        return $tokenToBeneficiary;
    }

    function oracle() external view returns (IOracle) {
        return $oracle;
    }

    function defaultScaledOfferFactor() external view returns (uint32) {
        return $defaultScaledOfferFactor;
    }

    /// get pair scaled offer factors for an array of quote pairs
    function getPairScaledOfferFactors(QuotePair[] calldata quotePairs_)
        external
        view
        returns (uint32[] memory pairScaledOfferFactors)
    {
        uint256 length = quotePairs_.length;
        pairScaledOfferFactors = new uint32[](length);
        for (uint256 i; i < length;) {
            pairScaledOfferFactors[i] = $_pairScaledOfferFactors._get(quotePairs_[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// functions - public & external - permissionless
    /// -----------------------------------------------------------------------

    /// emit event when receiving ETH
    /// @dev implemented w/i clone bytecode
    /* receive() external payable { */
    /*     emit ReceiveETH(msg.value); */
    /* } */

    /// allows `#flash` to track ETH payback to `beneficiary`
    /// @dev if used outside `#swapperFlashCallback`, msg.sender may lose funds.
    /// Accumulates until next flash call
    function payback() external payable {
        $_payback += msg.value.toUint96();
        emit Payback(msg.sender, msg.value);
    }

    /// allow third parties to withdraw tokens in return for sending `tokenToBeneficiary` to `beneficiary`
    function flash(QuoteParams[] calldata quoteParams_, bytes calldata callbackData_)
        external
        pausable
        returns (uint256)
    {
        address _tokenToBeneficiary = $tokenToBeneficiary;
        (uint256 amountToBeneficiary, uint256[] memory amountsToBeneficiary) =
            _transferToTrader(_tokenToBeneficiary, quoteParams_);

        ISwapperFlashCallback(msg.sender).swapperFlashCallback({
            tokenToBeneficiary: _tokenToBeneficiary,
            amountToBeneficiary: amountToBeneficiary,
            data: callbackData_
        });

        address _beneficiary = $beneficiary;
        uint256 excessToBeneficiary = _transferToBeneficiary(_beneficiary, _tokenToBeneficiary, amountToBeneficiary);

        emit Flash(
            _beneficiary, msg.sender, quoteParams_, _tokenToBeneficiary, amountsToBeneficiary, excessToBeneficiary
        );

        return amountToBeneficiary + excessToBeneficiary;
    }

    /// -----------------------------------------------------------------------
    /// functions - private & internal
    /// -----------------------------------------------------------------------

    function _transferToTrader(address tokenToBeneficiary_, QuoteParams[] calldata quoteParams_)
        internal
        returns (uint256 amountToBeneficiary, uint256[] memory amountsToBeneficiary)
    {
        uint256[] memory unscaledAmountsToBeneficiary = $oracle.getQuoteAmounts(quoteParams_);
        uint256 length = quoteParams_.length;
        if (unscaledAmountsToBeneficiary.length != length) revert Invalid_AmountsToBeneficiary();

        amountsToBeneficiary = new uint256[](length);
        uint256 scaledAmountToBeneficiary;
        uint128 amountToTrader;
        address tokenToTrader;
        for (uint256 i; i < length;) {
            QuoteParams calldata qp = quoteParams_[i];

            if (tokenToBeneficiary_ != qp.quotePair.quote) revert Invalid_QuoteToken();
            tokenToTrader = qp.quotePair.base;
            amountToTrader = qp.baseAmount;

            if (amountToTrader > tokenToTrader._balanceOf(address(this))) {
                revert InsufficientFunds_InContract();
            }

            uint32 scaledOfferFactor = $_pairScaledOfferFactors._get(qp.quotePair._sort());
            if (scaledOfferFactor == 0) {
                scaledOfferFactor = $defaultScaledOfferFactor;
            }

            scaledAmountToBeneficiary = unscaledAmountsToBeneficiary[i] * scaledOfferFactor / PERCENTAGE_SCALE;
            amountsToBeneficiary[i] = scaledAmountToBeneficiary;
            amountToBeneficiary += scaledAmountToBeneficiary;
            tokenToTrader._safeTransfer(msg.sender, amountToTrader);

            unchecked {
                ++i;
            }
        }
    }

    function _transferToBeneficiary(address beneficiary_, address tokenToBeneficiary_, uint256 amountToBeneficiary_)
        internal
        returns (uint256 excessToBeneficiary)
    {
        if (tokenToBeneficiary_._isETH()) {
            if ($_payback < amountToBeneficiary_) {
                revert InsufficientFunds_FromTrader();
            }
            $_payback = 0;

            // send ETH to `beneficiary`
            uint256 ethBalance = address(this).balance;
            excessToBeneficiary = ethBalance - amountToBeneficiary_;
            beneficiary_.safeTransferETH(ethBalance);
        } else {
            tokenToBeneficiary_.safeTransferFrom(msg.sender, beneficiary_, amountToBeneficiary_);

            // flush excess `tokenToBeneficiary` to `beneficiary`
            excessToBeneficiary = ERC20(tokenToBeneficiary_).balanceOf(address(this));
            if (excessToBeneficiary > 0) {
                tokenToBeneficiary_.safeTransfer(beneficiary_, excessToBeneficiary);
            }
        }
    }
}