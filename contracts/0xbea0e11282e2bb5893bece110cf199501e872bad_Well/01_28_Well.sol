// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ReentrancyGuardUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {ERC20Upgradeable, ERC20PermitUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {IERC20, SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWell, Call} from "src/interfaces/IWell.sol";
import {IWellErrors} from "src/interfaces/IWellErrors.sol";
import {IPump} from "src/interfaces/pumps/IPump.sol";
import {IWellFunction} from "src/interfaces/IWellFunction.sol";
import {LibBytes} from "src/libraries/LibBytes.sol";
import {ClonePlus} from "src/utils/ClonePlus.sol";

/**
 * @title Well
 * @author Publius, Silo Chad, Brean
 * @dev A Well is a constant function AMM allowing the provisioning of liquidity
 * into a single pooled on-chain liquidity position.
 *
 * Rebasing Tokens:
 * - Positive rebasing tokens are supported by Wells, but any tokens recieved from a
 *   rebase will not be rewarded to LP holders and instead can be extracted by anyone
 *   using `skim`, `sync` or `shift`.
 * - Negative rebasing tokens should not be used in Well as the effect of a negative
 *   rebase will be realized by users interacting with the Well, not LP token holders.
 *
 * Fee on Tranfer (FoT) Tokens:
 * - When transferring fee on transfer tokens to a Well (swapping from or adding liquidity),
 *   use `swapFromFeeOnTrasfer` or `addLiquidityFeeOnTransfer`. `swapTo` does not support
 *   fee on transfer tokens (See {swapTo}).
 * - When recieving fee on transfer tokens from a Well (swapping to and removing liquidity),
 *   INCLUDE the fee that is taken on transfer when calculating amount out values.
 */
contract Well is ERC20PermitUpgradeable, IWell, IWellErrors, ReentrancyGuardUpgradeable, ClonePlus {
    using SafeERC20 for IERC20;

    uint256 private constant PACKED_ADDRESS = 20;
    uint256 private constant ONE_WORD_PLUS_PACKED_ADDRESS = 52; // For gas efficiency purposes
    bytes32 private constant RESERVES_STORAGE_SLOT = 0x4bba01c388049b5ebd30398b65e8ad45b632802c5faf4964e58085ea8ab03715; // bytes32(uint256(keccak256("reserves.storage.slot")) - 1);

    constructor() {
        // Disable Initializers to prevent the init function from being callable on the implementation contract
        _disableInitializers();
    }

    function init(string memory _name, string memory _symbol) external initializer {
        __ERC20Permit_init(_name);
        __ERC20_init(_name, _symbol);
        __ReentrancyGuard_init();

        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        for (uint256 i; i < tokensLength - 1; ++i) {
            for (uint256 j = i + 1; j < tokensLength; ++j) {
                if (_tokens[i] == _tokens[j]) {
                    revert DuplicateTokens(_tokens[i]);
                }
            }
        }
    }

    function isInitialized() external view returns (bool) {
        return _getInitializedVersion() > 0;
    }

    //////////////////// WELL DEFINITION ////////////////////

    /// This Well uses a dynamic immutable storage layout. Immutable storage is
    /// used for gas-efficient reads during Well operation. The Well must be
    /// created by cloning with a pre-encoded byte string containing immutable
    /// data.
    ///
    /// Let n = number of tokens
    ///     m = length of well function data (bytes)
    ///
    /// TYPE        NAME                       LOCATION (CONSTANT)
    /// ==============================================================
    /// address     aquifer()                  0        (LOC_AQUIFER_ADDR)
    /// uint256     numberOfTokens()           20       (LOC_TOKENS_COUNT)
    /// address     wellFunctionAddress()      52       (LOC_WELL_FUNCTION_ADDR)
    /// uint256     wellFunctionDataLength()   72       (LOC_WELL_FUNCTION_DATA_LENGTH)
    /// uint256     numberOfPumps()            104      (LOC_PUMPS_COUNT)
    /// --------------------------------------------------------------
    /// address     token0                     136      (LOC_VARIABLE)
    /// ...
    /// address     tokenN                     136 + (n-1) * 32
    /// --------------------------------------------------------------
    /// byte        wellFunctionData0          136 + n * 32
    /// ...
    /// byte        wellFunctionDataM          136 + n * 32 + m
    /// --------------------------------------------------------------
    /// address     pump1Address               136 + n * 32 + m
    /// uint256     pump1DataLength            136 + n * 32 + m + 20
    /// byte        pump1Data                  136 + n * 32 + m + 52
    /// ...
    /// ==============================================================

    uint256 private constant LOC_AQUIFER_ADDR = 0;
    uint256 private constant LOC_TOKENS_COUNT = 20; // LOC_AQUIFER_ADDR + PACKED_ADDRESS
    uint256 private constant LOC_WELL_FUNCTION_ADDR = 52; // LOC_TOKENS_COUNT + ONE_WORD
    uint256 private constant LOC_WELL_FUNCTION_DATA_LENGTH = 72; // LOC_WELL_FUNCTION_ADDR + PACKED_ADDRESS;
    uint256 private constant LOC_PUMPS_COUNT = 104; // LOC_WELL_FUNCTION_DATA_LENGTH + ONE_WORD;
    uint256 private constant LOC_VARIABLE = 136; // LOC_PUMPS_COUNT + ONE_WORD;

    function tokens() public pure returns (IERC20[] memory _tokens) {
        _tokens = _getArgIERC20Array(LOC_VARIABLE, numberOfTokens());
    }

    function wellFunction() public pure returns (Call memory _wellFunction) {
        _wellFunction.target = wellFunctionAddress();
        _wellFunction.data = _getArgBytes(LOC_VARIABLE + numberOfTokens() * ONE_WORD, wellFunctionDataLength());
    }

    function pumps() public pure returns (Call[] memory _pumps) {
        uint256 _numberOfPumps = numberOfPumps();
        if (_numberOfPumps == 0) return _pumps;

        _pumps = new Call[](_numberOfPumps);
        uint256 dataLoc = LOC_VARIABLE + numberOfTokens() * ONE_WORD + wellFunctionDataLength();

        uint256 pumpDataLength;
        for (uint256 i; i < _pumps.length; ++i) {
            _pumps[i].target = _getArgAddress(dataLoc);
            dataLoc += PACKED_ADDRESS;
            pumpDataLength = _getArgUint256(dataLoc);
            dataLoc += ONE_WORD;
            _pumps[i].data = _getArgBytes(dataLoc, pumpDataLength);
            dataLoc += pumpDataLength;
        }
    }

    /**
     * @dev {wellData} is unused in this implementation.
     */
    function wellData() public pure returns (bytes memory) {}

    function aquifer() public pure override returns (address) {
        return _getArgAddress(LOC_AQUIFER_ADDR);
    }

    function well()
        external
        pure
        returns (
            IERC20[] memory _tokens,
            Call memory _wellFunction,
            Call[] memory _pumps,
            bytes memory _wellData,
            address _aquifer
        )
    {
        _tokens = tokens();
        _wellFunction = wellFunction();
        _pumps = pumps();
        _wellData = wellData();
        _aquifer = aquifer();
    }

    //////////////////// WELL DEFINITION: HELPERS ////////////////////

    /**
     * @notice Returns the number of tokens that are tradable in this Well.
     * @dev Length of the `tokens()` array.
     */
    function numberOfTokens() public pure returns (uint256) {
        return _getArgUint256(LOC_TOKENS_COUNT);
    }

    /**
     * @notice Returns the address of the Well Function.
     */
    function wellFunctionAddress() public pure returns (address) {
        return _getArgAddress(LOC_WELL_FUNCTION_ADDR);
    }

    /**
     * @notice Returns the length of the configurable `data` parameter passed during calls to the Well Function.
     */
    function wellFunctionDataLength() public pure returns (uint256) {
        return _getArgUint256(LOC_WELL_FUNCTION_DATA_LENGTH);
    }

    /**
     * @notice Returns the number of Pumps which this Well was initialized with.
     */
    function numberOfPumps() public pure returns (uint256) {
        return _getArgUint256(LOC_PUMPS_COUNT);
    }

    /**
     * @notice Returns address & data used to call the first Pump.
     * @dev Provided as an optimization in the case where {numberOfPumps} returns 1.
     */
    function firstPump() public pure returns (Call memory _pump) {
        uint256 dataLoc = LOC_VARIABLE + numberOfTokens() * ONE_WORD + wellFunctionDataLength();
        _pump.target = _getArgAddress(dataLoc);
        _pump.data = _getArgBytes(dataLoc + ONE_WORD_PLUS_PACKED_ADDRESS, _getArgUint256(dataLoc + PACKED_ADDRESS));
    }

    //////////////////// SWAP: FROM ////////////////////

    /**
     * @dev MUST revert if a fee on transfer token is used. The requisite check
     * is performed in {_setReserves}.
     */
    function swapFrom(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        uint256 deadline
    ) external nonReentrant expire(deadline) returns (uint256 amountOut) {
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        amountOut = _swapFrom(fromToken, toToken, amountIn, minAmountOut, recipient);
    }

    /**
     * @dev Note that `amountOut` is the amount *transferred* by the Well; if a fee
     * is charged on transfers of `toToken`, the amount received by `recipient`
     * will be less than `amountOut`.
     */
    function swapFromFeeOnTransfer(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        uint256 deadline
    ) external nonReentrant expire(deadline) returns (uint256 amountOut) {
        amountIn = _safeTransferFromFeeOnTransfer(fromToken, msg.sender, amountIn);
        amountOut = _swapFrom(fromToken, toToken, amountIn, minAmountOut, recipient);
    }

    function _swapFrom(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) internal returns (uint256 amountOut) {
        IERC20[] memory _tokens = tokens();
        (uint256 i, uint256 j) = _getIJ(_tokens, fromToken, toToken);
        uint256[] memory reserves = _updatePumps(_tokens.length);

        reserves[i] += amountIn;
        uint256 reserveJBefore = reserves[j];
        reserves[j] = _calcReserve(wellFunction(), reserves, j, totalSupply());

        // Note: The rounding approach of the Well function determines whether
        // slippage from imprecision goes to the Well or to the User.
        amountOut = reserveJBefore - reserves[j];
        if (amountOut < minAmountOut) {
            revert SlippageOut(amountOut, minAmountOut);
        }

        toToken.safeTransfer(recipient, amountOut);
        emit Swap(fromToken, toToken, amountIn, amountOut, recipient);
        _setReserves(_tokens, reserves);
    }

    /**
     * @dev Assumes both tokens incur no fee on transfer.
     */
    function getSwapOut(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn
    ) external view readOnlyNonReentrant returns (uint256 amountOut) {
        IERC20[] memory _tokens = tokens();
        (uint256 i, uint256 j) = _getIJ(_tokens, fromToken, toToken);
        uint256[] memory reserves = _getReserves(_tokens.length);

        reserves[i] += amountIn;

        // underflow is desired; Well Function SHOULD NOT increase reserves of both `i` and `j`
        amountOut = reserves[j] - _calcReserve(wellFunction(), reserves, j, totalSupply());
    }

    //////////////////// SWAP: TO ////////////////////

    /**
     * @dev {swapTo} does not support fee on transfer tokens, and no corresponding
     * "swapToFeeOnTransfer" function is provided as this would require either:
     * (a) inclusion of the fee as a parameter with verification; or
     * (b) iterative transfers which attempts to back-calculate the fee.
     */
    function swapTo(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 maxAmountIn,
        uint256 amountOut,
        address recipient,
        uint256 deadline
    ) external nonReentrant expire(deadline) returns (uint256 amountIn) {
        IERC20[] memory _tokens = tokens();
        (uint256 i, uint256 j) = _getIJ(_tokens, fromToken, toToken);
        uint256[] memory reserves = _updatePumps(_tokens.length);

        reserves[j] -= amountOut;
        uint256 reserveIBefore = reserves[i];
        reserves[i] = _calcReserve(wellFunction(), reserves, i, totalSupply());

        // Note: The rounding approach of the Well function determines whether
        // slippage from imprecision goes to the Well or to the User.
        amountIn = reserves[i] - reserveIBefore;

        if (amountIn > maxAmountIn) {
            revert SlippageIn(amountIn, maxAmountIn);
        }

        _swapTo(fromToken, toToken, amountIn, amountOut, recipient);
        _setReserves(_tokens, reserves);
    }

    /**
     * @dev Executes token transfers and emits Swap event. Used by {swapTo} to
     * avoid stack too deep errors.
     */
    function _swapTo(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountIn,
        uint256 amountOut,
        address recipient
    ) internal {
        fromToken.safeTransferFrom(msg.sender, address(this), amountIn);
        toToken.safeTransfer(recipient, amountOut);
        emit Swap(fromToken, toToken, amountIn, amountOut, recipient);
    }

    /**
     * @dev Assumes both tokens incur no fee on transfer.
     */
    function getSwapIn(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 amountOut
    ) external view readOnlyNonReentrant returns (uint256 amountIn) {
        IERC20[] memory _tokens = tokens();
        (uint256 i, uint256 j) = _getIJ(_tokens, fromToken, toToken);
        uint256[] memory reserves = _getReserves(_tokens.length);

        reserves[j] -= amountOut;

        amountIn = _calcReserve(wellFunction(), reserves, i, totalSupply()) - reserves[i];
    }

    //////////////////// SHIFT ////////////////////

    /**
     * @dev When using Wells for a multi-hop swap in 1 single transaction using a
     * multicall contract like Pipeline, costs can be reduced by "shifting" tokens
     * from one Well to another rather than returning them to the multicall router.
     *
     * Example multi-hop swap: WETH -> DAI -> USDC
     *
     * 1. Using a router without {shift}:
     *  WETH.transfer(sender=0xUSER, recipient=0xROUTER)                     [1]
     *  Call the router, which performs:
     *      Well1.swapFrom(fromToken=WETH, toToken=DAI, recipient=0xROUTER)
     *          WETH.transfer(sender=0xROUTER, recipient=Well1)              [2]
     *          DAI.transfer(sender=Well1, recipient=0xROUTER)               [3]
     *      Well2.swapFrom(fromToken=DAI, toToken=USDC, recipient=0xROUTER)
     *          DAI.transfer(sender=0xROUTER, recipient=Well2)               [4]
     *          USDC.transfer(sender=Well2, recipient=0xROUTER)              [5]
     *  USDC.transfer(sender=0xROUTER, recipient=0xUSER)                     [6]
     *
     *  Note: this could be optimized by configuring the router to deliver
     *  tokens from the last swap directly to the user.
     *
     * 2. Using a router with {shift}:
     *  WETH.transfer(sender=0xUSER, recipient=Well1)                        [1]
     *  Call the router, which performs:
     *      Well1.shift(tokenOut=DAI, recipient=Well2)
     *          DAI.transfer(sender=Well1, recipient=Well2)                  [2]
     *      Well2.shift(tokenOut=USDC, recipient=0xUSER)
     *          USDC.transfer(sender=Well2, recipient=0xUSER)                [3]
     */
    function shift(
        IERC20 tokenOut,
        uint256 minAmountOut,
        address recipient
    ) external nonReentrant returns (uint256 amountOut) {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        _updatePumps(tokensLength);

        uint256[] memory reserves = new uint256[](tokensLength);

        // Use the balances of the pool instead of the stored reserves.
        // If there is a change in token balances relative to the currently
        // stored reserves, the extra tokens can be shifted into `tokenOut`.
        for (uint256 i; i < tokensLength; ++i) {
            reserves[i] = _tokens[i].balanceOf(address(this));
        }
        uint256 j = _getJ(_tokens, tokenOut);
        amountOut = reserves[j] - _calcReserve(wellFunction(), reserves, j, totalSupply());

        if (amountOut >= minAmountOut) {
            tokenOut.safeTransfer(recipient, amountOut);
            reserves[j] -= amountOut;
            _setReserves(_tokens, reserves);
            emit Shift(reserves, tokenOut, amountOut, recipient);
        } else {
            revert SlippageOut(amountOut, minAmountOut);
        }
    }

    function getShiftOut(IERC20 tokenOut) external view readOnlyNonReentrant returns (uint256 amountOut) {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        uint256[] memory reserves = new uint256[](tokensLength);
        for (uint256 i; i < tokensLength; ++i) {
            reserves[i] = _tokens[i].balanceOf(address(this));
        }

        uint256 j = _getJ(_tokens, tokenOut);
        amountOut = reserves[j] - _calcReserve(wellFunction(), reserves, j, totalSupply());
    }

    //////////////////// ADD LIQUIDITY ////////////////////

    function addLiquidity(
        uint256[] memory tokenAmountsIn,
        uint256 minLpAmountOut,
        address recipient,
        uint256 deadline
    ) external nonReentrant expire(deadline) returns (uint256 lpAmountOut) {
        lpAmountOut = _addLiquidity(tokenAmountsIn, minLpAmountOut, recipient, false);
    }

    function addLiquidityFeeOnTransfer(
        uint256[] memory tokenAmountsIn,
        uint256 minLpAmountOut,
        address recipient,
        uint256 deadline
    ) external nonReentrant expire(deadline) returns (uint256 lpAmountOut) {
        lpAmountOut = _addLiquidity(tokenAmountsIn, minLpAmountOut, recipient, true);
    }

    /**
     * @dev Gas optimization: {IWell.AddLiquidity} is emitted even if `lpAmountOut` is 0.
     */
    function _addLiquidity(
        uint256[] memory tokenAmountsIn,
        uint256 minLpAmountOut,
        address recipient,
        bool feeOnTransfer
    ) internal returns (uint256 lpAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        uint256[] memory reserves = _updatePumps(tokensLength);

        uint256 _tokenAmountIn;
        if (feeOnTransfer) {
            for (uint256 i; i < tokensLength; ++i) {
                _tokenAmountIn = tokenAmountsIn[i];
                if (_tokenAmountIn == 0) continue;
                _tokenAmountIn = _safeTransferFromFeeOnTransfer(_tokens[i], msg.sender, _tokenAmountIn);
                reserves[i] += _tokenAmountIn;
                tokenAmountsIn[i] = _tokenAmountIn;
            }
        } else {
            for (uint256 i; i < tokensLength; ++i) {
                _tokenAmountIn = tokenAmountsIn[i];
                if (_tokenAmountIn == 0) continue;
                _tokens[i].safeTransferFrom(msg.sender, address(this), _tokenAmountIn);
                reserves[i] += _tokenAmountIn;
            }
        }

        lpAmountOut = _calcLpTokenSupply(wellFunction(), reserves) - totalSupply();
        if (lpAmountOut < minLpAmountOut) {
            revert SlippageOut(lpAmountOut, minLpAmountOut);
        }

        _mint(recipient, lpAmountOut);
        _setReserves(_tokens, reserves);
        emit AddLiquidity(tokenAmountsIn, lpAmountOut, recipient);
    }

    /**
     * @dev Assumes that no tokens involved incur a fee on transfer.
     */
    function getAddLiquidityOut(uint256[] memory tokenAmountsIn)
        external
        view
        readOnlyNonReentrant
        returns (uint256 lpAmountOut)
    {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        uint256[] memory reserves = _getReserves(tokensLength);
        for (uint256 i; i < tokensLength; ++i) {
            reserves[i] += tokenAmountsIn[i];
        }
        lpAmountOut = _calcLpTokenSupply(wellFunction(), reserves) - totalSupply();
    }

    //////////////////// REMOVE LIQUIDITY: BALANCED ////////////////////

    function removeLiquidity(
        uint256 lpAmountIn,
        uint256[] calldata minTokenAmountsOut,
        address recipient,
        uint256 deadline
    ) external nonReentrant expire(deadline) returns (uint256[] memory tokenAmountsOut) {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        uint256[] memory reserves = _updatePumps(tokensLength);

        tokenAmountsOut = _calcLPTokenUnderlying(wellFunction(), lpAmountIn, reserves, totalSupply());
        _burn(msg.sender, lpAmountIn);
        uint256 _tokenAmountOut;
        for (uint256 i; i < tokensLength; ++i) {
            _tokenAmountOut = tokenAmountsOut[i];
            if (_tokenAmountOut < minTokenAmountsOut[i]) {
                revert SlippageOut(_tokenAmountOut, minTokenAmountsOut[i]);
            }
            _tokens[i].safeTransfer(recipient, _tokenAmountOut);
            reserves[i] -= _tokenAmountOut;
        }

        _setReserves(_tokens, reserves);
        emit RemoveLiquidity(lpAmountIn, tokenAmountsOut, recipient);
    }

    function getRemoveLiquidityOut(uint256 lpAmountIn)
        external
        view
        readOnlyNonReentrant
        returns (uint256[] memory tokenAmountsOut)
    {
        IERC20[] memory _tokens = tokens();
        uint256[] memory reserves = _getReserves(_tokens.length);
        uint256 lpTokenSupply = totalSupply();

        tokenAmountsOut = _calcLPTokenUnderlying(wellFunction(), lpAmountIn, reserves, lpTokenSupply);
    }

    //////////////////// REMOVE LIQUIDITY: ONE TOKEN ////////////////////

    function removeLiquidityOneToken(
        uint256 lpAmountIn,
        IERC20 tokenOut,
        uint256 minTokenAmountOut,
        address recipient,
        uint256 deadline
    ) external nonReentrant expire(deadline) returns (uint256 tokenAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint256[] memory reserves = _updatePumps(_tokens.length);
        uint256 j = _getJ(_tokens, tokenOut);

        tokenAmountOut = _getRemoveLiquidityOneTokenOut(lpAmountIn, j, reserves);
        if (tokenAmountOut < minTokenAmountOut) {
            revert SlippageOut(tokenAmountOut, minTokenAmountOut);
        }

        _burn(msg.sender, lpAmountIn);
        tokenOut.safeTransfer(recipient, tokenAmountOut);

        reserves[j] -= tokenAmountOut;
        _setReserves(_tokens, reserves);
        emit RemoveLiquidityOneToken(lpAmountIn, tokenOut, tokenAmountOut, recipient);
    }

    function getRemoveLiquidityOneTokenOut(
        uint256 lpAmountIn,
        IERC20 tokenOut
    ) external view readOnlyNonReentrant returns (uint256 tokenAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint256[] memory reserves = _getReserves(_tokens.length);
        tokenAmountOut = _getRemoveLiquidityOneTokenOut(lpAmountIn, _getJ(_tokens, tokenOut), reserves);
    }

    /**
     * @dev Shared logic for removing a single token from liquidity.
     * Calculates change in reserve `j` given a change in LP token supply.
     *
     * Note: `lpAmountIn` is the amount of LP the user is burning in exchange
     * for some amount of token `j`.
     */
    function _getRemoveLiquidityOneTokenOut(
        uint256 lpAmountIn,
        uint256 j,
        uint256[] memory reserves
    ) private view returns (uint256 tokenAmountOut) {
        uint256 newReserveJ = _calcReserve(wellFunction(), reserves, j, totalSupply() - lpAmountIn);
        tokenAmountOut = reserves[j] - newReserveJ;
    }

    //////////// REMOVE LIQUIDITY: IMBALANCED ////////////

    function removeLiquidityImbalanced(
        uint256 maxLpAmountIn,
        uint256[] calldata tokenAmountsOut,
        address recipient,
        uint256 deadline
    ) external nonReentrant expire(deadline) returns (uint256 lpAmountIn) {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        uint256[] memory reserves = _updatePumps(tokensLength);

        uint256 _tokenAmountOut;
        for (uint256 i; i < tokensLength; ++i) {
            _tokenAmountOut = tokenAmountsOut[i];
            _tokens[i].safeTransfer(recipient, _tokenAmountOut);
            reserves[i] -= _tokenAmountOut;
        }

        lpAmountIn = totalSupply() - _calcLpTokenSupply(wellFunction(), reserves);
        if (lpAmountIn > maxLpAmountIn) {
            revert SlippageIn(lpAmountIn, maxLpAmountIn);
        }
        _burn(msg.sender, lpAmountIn);

        _setReserves(_tokens, reserves);
        emit RemoveLiquidity(lpAmountIn, tokenAmountsOut, recipient);
    }

    function getRemoveLiquidityImbalancedIn(uint256[] calldata tokenAmountsOut)
        external
        view
        readOnlyNonReentrant
        returns (uint256 lpAmountIn)
    {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        uint256[] memory reserves = _getReserves(tokensLength);
        for (uint256 i; i < tokensLength; ++i) {
            reserves[i] -= tokenAmountsOut[i];
        }
        lpAmountIn = totalSupply() - _calcLpTokenSupply(wellFunction(), reserves);
    }

    //////////////////// RESERVES ////////////////////

    /**
     * @dev Can be used in a multicall to add liquidity similar to how `shift` can be used to swap.
     * See {shift} for examples of how to use in a multicall.
     */
    function sync(address recipient, uint256 minLpAmountOut) external nonReentrant returns (uint256 lpAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        _updatePumps(tokensLength);
        uint256[] memory reserves = new uint256[](tokensLength);
        for (uint256 i; i < tokensLength; ++i) {
            reserves[i] = _tokens[i].balanceOf(address(this));
        }
        uint256 newTokenSupply = _calcLpTokenSupply(wellFunction(), reserves);
        uint256 oldTokenSupply = totalSupply();
        if (newTokenSupply > oldTokenSupply) {
            lpAmountOut = newTokenSupply - oldTokenSupply;
            _mint(recipient, lpAmountOut);
        }

        if (lpAmountOut < minLpAmountOut) {
            revert SlippageOut(lpAmountOut, minLpAmountOut);
        }

        _setReserves(_tokens, reserves);
        emit Sync(reserves, lpAmountOut, recipient);
    }

    function getSyncOut() external view readOnlyNonReentrant returns (uint256 lpAmountOut) {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;

        uint256[] memory reserves = new uint256[](tokensLength);
        for (uint256 i; i < tokensLength; ++i) {
            reserves[i] = _tokens[i].balanceOf(address(this));
        }

        uint256 newTokenSupply = _calcLpTokenSupply(wellFunction(), reserves);
        uint256 oldTokenSupply = totalSupply();
        if (newTokenSupply > oldTokenSupply) {
            lpAmountOut = newTokenSupply - oldTokenSupply;
        }
    }

    /**
     * @dev Transfer excess tokens held by the Well to `recipient`.
     */
    function skim(address recipient) external nonReentrant returns (uint256[] memory skimAmounts) {
        IERC20[] memory _tokens = tokens();
        uint256 tokensLength = _tokens.length;
        uint256[] memory reserves = _getReserves(tokensLength);
        skimAmounts = new uint256[](tokensLength);
        for (uint256 i; i < tokensLength; ++i) {
            skimAmounts[i] = _tokens[i].balanceOf(address(this)) - reserves[i];
            if (skimAmounts[i] > 0) {
                _tokens[i].safeTransfer(recipient, skimAmounts[i]);
            }
        }
    }

    function getReserves() external view readOnlyNonReentrant returns (uint256[] memory reserves) {
        reserves = _getReserves(numberOfTokens());
    }

    /**
     * @dev Gets the Well's token reserves by reading from byte storage.
     */
    function _getReserves(uint256 _numberOfTokens) internal view returns (uint256[] memory reserves) {
        reserves = LibBytes.readUint128(RESERVES_STORAGE_SLOT, _numberOfTokens);
    }

    /**
     * @dev Checks that the balance of each ERC-20 token is >= the reserves and
     * sets the Well's reserves of each token by writing to byte storage.
     */
    function _setReserves(IERC20[] memory _tokens, uint256[] memory reserves) internal {
        for (uint256 i; i < reserves.length; ++i) {
            if (reserves[i] > _tokens[i].balanceOf(address(this))) revert InvalidReserves();
        }
        LibBytes.storeUint128(RESERVES_STORAGE_SLOT, reserves);
    }

    //////////////////// INTERNAL: UPDATE PUMPS ////////////////////

    /**
     * @dev Fetches the current token reserves of the Well and updates the Pumps.
     * Typically called before an operation that modifies the Well's reserves.
     */
    function _updatePumps(uint256 _numberOfTokens) internal returns (uint256[] memory reserves) {
        reserves = _getReserves(_numberOfTokens);

        uint256 _numberOfPumps = numberOfPumps();
        if (_numberOfPumps == 0) {
            return reserves;
        }

        // gas optimization: avoid looping if there is only one pump
        if (_numberOfPumps == 1) {
            Call memory _pump = firstPump();
            // Don't revert if the update call fails.
            try IPump(_pump.target).update(reserves, _pump.data) {}
            catch {
                // ignore reversion. If an external shutoff mechanism is added to a Pump, it could be called here.
            }
        } else {
            Call[] memory _pumps = pumps();
            for (uint256 i; i < _pumps.length; ++i) {
                // Don't revert if the update call fails.
                try IPump(_pumps[i].target).update(reserves, _pumps[i].data) {}
                catch {
                    // ignore reversion. If an external shutoff mechanism is added to a Pump, it could be called here.
                }
            }
        }
    }

    //////////////////// INTERNAL: WELL FUNCTION INTERACTION ////////////////////

    /**
     * @dev Calculates the LP token supply given a list of `reserves` using the
     * provided `_wellFunction`. Wraps {IWellFunction.calcLpTokenSupply}.
     *
     * The Well function is passed as a parameter to minimize gas in instances
     * where it is called multiple times in one transaction.
     */
    function _calcLpTokenSupply(
        Call memory _wellFunction,
        uint256[] memory reserves
    ) internal view returns (uint256 lpTokenSupply) {
        lpTokenSupply = IWellFunction(_wellFunction.target).calcLpTokenSupply(reserves, _wellFunction.data);
    }

    /**
     * @dev Calculates the `j`th reserve given a list of `reserves` and `lpTokenSupply`
     * using the provided `_wellFunction`. Wraps {IWellFunction.calcReserve}.
     *
     * The Well function is passed as a parameter to minimize gas in instances
     * where it is called multiple times in one transaction.
     */
    function _calcReserve(
        Call memory _wellFunction,
        uint256[] memory reserves,
        uint256 j,
        uint256 lpTokenSupply
    ) internal view returns (uint256 reserve) {
        reserve = IWellFunction(_wellFunction.target).calcReserve(reserves, j, lpTokenSupply, _wellFunction.data);
    }

    /**
     * @dev Calculates the amount of tokens that underly a given amount of LP tokens
     * Wraps {IWellFunction.calcLPTokenAmount}.
     *
     * Used to determine the how many tokens to send to a user when they remove LP.
     *
     * The Well function is passed as a parameter to minimize gas in instances
     * where it is called multiple times in one transaction.
     */
    function _calcLPTokenUnderlying(
        Call memory _wellFunction,
        uint256 lpTokenAmount,
        uint256[] memory reserves,
        uint256 lpTokenSupply
    ) internal view returns (uint256[] memory tokenAmounts) {
        tokenAmounts = IWellFunction(_wellFunction.target).calcLPTokenUnderlying(
            lpTokenAmount, reserves, lpTokenSupply, _wellFunction.data
        );
    }

    //////////////////// INTERNAL: WELL TOKEN INDEXING ////////////////////

    /**
     * @dev Returns the indices of `iToken` and `jToken` in `_tokens`.
     * Reverts if either token is not in `_tokens`.
     * Reverts if `iToken` and `jToken` are the same.
     */
    function _getIJ(
        IERC20[] memory _tokens,
        IERC20 iToken,
        IERC20 jToken
    ) internal pure returns (uint256 i, uint256 j) {
        bool foundOne;
        for (uint256 k; k < _tokens.length; ++k) {
            if (iToken == _tokens[k]) {
                i = k;
                if (foundOne) return (i, j);
                foundOne = true;
            } else if (jToken == _tokens[k]) {
                j = k;
                if (foundOne) return (i, j);
                foundOne = true;
            }
        }
        revert InvalidTokens();
    }

    /**
     * @dev Returns the index of `jToken` in `_tokens`. Reverts if `jToken` is
     * not in `_tokens`.
     *
     * If `_tokens` contains multiple instances of `jToken`, this will return
     * the first one. A {Well} with duplicate tokens has been misconfigured.
     */
    function _getJ(IERC20[] memory _tokens, IERC20 jToken) internal pure returns (uint256 j) {
        for (j; j < _tokens.length; ++j) {
            if (jToken == _tokens[j]) {
                return j;
            }
        }
        revert InvalidTokens();
    }

    //////////////////// INTERNAL: TRANSFER HELPERS ////////////////////

    /**
     * @dev Calculates the change in token balance of the Well across a transfer.
     * Used when a fee might be incurred during safeTransferFrom.
     */
    function _safeTransferFromFeeOnTransfer(
        IERC20 token,
        address from,
        uint256 amount
    ) internal returns (uint256 amountTransferred) {
        uint256 balanceBefore = token.balanceOf(address(this));
        token.safeTransferFrom(from, address(this), amount);
        amountTransferred = token.balanceOf(address(this)) - balanceBefore;
    }

    //////////////////// INTERNAL: EXPIRY ////////////////////

    /**
     * @dev Reverts if the deadline has passed.
     */
    modifier expire(uint256 deadline) {
        if (block.timestamp > deadline) {
            revert Expired();
        }
        _;
    }

    //////////////////// INTERNAL: Read Only Reentrancy ////////////////////

    /**
     * @dev Reverts if the reentrncy guard has been entered.
     */
    modifier readOnlyNonReentrant() {
        // Use the same error as `ReentrancyGuardUpgradeable` instead of using a custom error for consistency.
        require(!_reentrancyGuardEntered(), "ReentrancyGuard: reentrant call");
        _;
    }
}