// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "v3-periphery/interfaces/INonfungiblePositionManager.sol";
import "v3-periphery/interfaces/external/IWETH9.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/// @title v3Utils - Utility functions for Uniswap V3 positions
/// @notice This is a completely ownerless/stateless contract - does not hold any ERC20 or NFTs.
/// @dev It can be simply redeployed when new / better functionality is implemented
contract V3Utils is IERC721Receiver {

    /// @notice Wrapped native token address
    IWETH9 immutable public weth;

    /// @notice Uniswap v3 position manager
    INonfungiblePositionManager immutable public nonfungiblePositionManager;

    // error types
    error Unauthorized();
    error WrongContract();
    error WrongChain();
    error NotSupportedWhatToDo();
    error SameToken();
    error SwapFailed();
    error AmountError();
    error SlippageError();
    error CollectError();
    error TransferError();
    error EtherSendFailed();
    error TooMuchEtherSent();
    error NoEtherToken();
    error NotWETH();

    // events
    event CompoundFees(uint indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event ChangeRange(uint indexed tokenId, uint newTokenId);
    event WithdrawAndCollectAndSwap(uint indexed tokenId, address token, uint256 amount);
    event Swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
    event SwapAndMint(uint indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event SwapAndIncreaseLiquidity(uint indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Constructor
    /// @param _nonfungiblePositionManager Uniswap v3 position manager
    constructor(INonfungiblePositionManager _nonfungiblePositionManager) {
        weth = IWETH9(_nonfungiblePositionManager.WETH9());
        nonfungiblePositionManager = _nonfungiblePositionManager;
    }

    /// @notice Action which should be executed on provided NFT
    enum WhatToDo {
        CHANGE_RANGE,
        WITHDRAW_AND_COLLECT_AND_SWAP,
        COMPOUND_FEES
    }

    /// @notice Complete description of what should be executed on provided NFT - different fields are used depending on specified WhatToDo 
    struct Instructions {
        // what action to perform on provided Uniswap v3 position
        WhatToDo whatToDo;

        // target token for swaps (if this is address(0) no swaps are executed)
        address targetToken;

        // amountIn0 is used for swap and also as minAmount0 for decreaseLiquidity (when WITHDRAW_AND_COLLECT_AND_SWAP amountIn0 + available fees0 will be swapped)
        uint amountIn0;
        // if token0 needs to be swapped to targetToken - set values
        uint amountOut0Min;
        bytes swapData0; // encoded data from 0x api call (address,address,bytes) - to,allowanceTarget,data

        // amountIn1 is used for swap and also as minAmount1 for decreaseLiquidity (when WITHDRAW_AND_COLLECT_AND_SWAP amountIn1 + available fees1 will be swapped)
        uint amountIn1;
        // if token1 needs to be swapped to targetToken - set values
        uint amountOut1Min;
        bytes swapData1; // encoded data from 0x api call (address,address,bytes) - to,allowanceTarget,data

        // collect fee amount for COMPOUND_FEES / CHANGE_RANGE / WITHDRAW_AND_COLLECT_AND_SWAP (if uint(128).max - ALL)
        uint128 feeAmount0;
        uint128 feeAmount1;

        // for creating new positions with CHANGE_RANGE
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        
        // remove liquidity amount for COMPOUND_FEES (in this case should be probably 0) / CHANGE_RANGE / WITHDRAW_AND_COLLECT_AND_SWAP
        uint128 liquidity;

        // for adding liquidity slippage
        uint amountAddMin0;
        uint amountAddMin1;

        // for all uniswap deadlineable functions
        uint deadline;

        // left over tokens will be sent to this address (the sent / newly created NFT will ALWAYS be returned to from)
        address recipient;

        // if tokenIn or tokenOut is WETH - unwrap
        bool unwrap;

        // data sent with returned token to IERC721Receiver (optional) 
        bytes returnData;

        // data sent with minted token to IERC721Receiver (optional)
        bytes swapAndMintReturnData;
    }

    /// @notice struct used to store local variables during function execution
    struct ERC721ReceivedState {
        address token0;
        address token1;
        uint128 liquidity;
        uint amount0;
        uint amount1;
        uint newTokenId;
    }

    /// @notice Execute instruction by pulling approved NFT instead of direct safeTransferFrom call from owner
    /// @param tokenId Token to process
    /// @param instructions Instructions to execute
    function execute(uint256 tokenId, Instructions memory instructions) external
    {
        // must be approved beforehand
        nonfungiblePositionManager.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            abi.encode(instructions)
        );
    }

    /// @notice ERC721 callback function. Called on safeTransferFrom and does manipulation as configured in encoded Instructions parameter. 
    /// At the end the NFT (and any newly minted NFT) is returned to sender. The leftover tokens are sent to instructions.recipient.
    function onERC721Received(address , address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {

        // only Uniswap v3 NFTs allowed
        if (msg.sender != address(nonfungiblePositionManager)) {
            revert WrongContract();
        }

        Instructions memory instructions = abi.decode(data, (Instructions));
        ERC721ReceivedState memory state;

        (,,state.token0,state.token1,,,,state.liquidity,,,,) = nonfungiblePositionManager.positions(tokenId);

        if (instructions.liquidity > 0) {
            (state.amount0, state.amount1) = _decreaseLiquidity(tokenId, instructions.liquidity, instructions.deadline, instructions.amountIn0, instructions.amountIn1);
        }
        (state.amount0, state.amount1) = _collectFees(tokenId, IERC20(state.token0), IERC20(state.token1), instructions.feeAmount0 == type(uint128).max ? type(uint128).max : _toUint128(state.amount0 + instructions.feeAmount0), instructions.feeAmount1 == type(uint128).max ? type(uint128).max : _toUint128(state.amount1 + instructions.feeAmount1));

        if (instructions.whatToDo == WhatToDo.COMPOUND_FEES) {
            if (instructions.targetToken == state.token0) {
                if (state.amount1 < instructions.amountIn1) {
                    revert AmountError();
                }
                (state.liquidity, state.amount0, state.amount1) = _swapAndIncrease(SwapAndIncreaseLiquidityParams(tokenId, state.amount0, state.amount1, instructions.recipient, instructions.deadline, IERC20(state.token1), instructions.amountIn1, instructions.amountOut1Min, instructions.swapData1, 0, 0, "", 0, 0), IERC20(state.token0), IERC20(state.token1), instructions.unwrap);
            } else if (instructions.targetToken == state.token1) {
                if (state.amount0 < instructions.amountIn0) {
                    revert AmountError();
                }
                (state.liquidity, state.amount0, state.amount1) = _swapAndIncrease(SwapAndIncreaseLiquidityParams(tokenId, state.amount0, state.amount1, instructions.recipient, instructions.deadline, IERC20(state.token0), 0, 0, "", instructions.amountIn0, instructions.amountOut0Min, instructions.swapData0, 0, 0), IERC20(state.token0), IERC20(state.token1), instructions.unwrap);
            } else {
                // no swap is done here
                (state.liquidity,state.amount0, state.amount1) = _swapAndIncrease(SwapAndIncreaseLiquidityParams(tokenId, state.amount0, state.amount1, instructions.recipient, instructions.deadline, IERC20(address(0)), 0, 0, "", 0, 0, "", 0, 0), IERC20(state.token0), IERC20(state.token1), instructions.unwrap);
            }
            emit CompoundFees(tokenId, state.liquidity, state.amount0, state.amount1);            
        } else if (instructions.whatToDo == WhatToDo.CHANGE_RANGE) {
            if (instructions.targetToken == state.token0) {
                if (state.amount1 < instructions.amountIn1) {
                    revert AmountError();
                }
                (state.newTokenId,,,) = _swapAndMint(SwapAndMintParams(IERC20(state.token0), IERC20(state.token1), instructions.fee, instructions.tickLower, instructions.tickUpper, state.amount0, state.amount1, instructions.recipient, from, instructions.deadline, IERC20(state.token1), instructions.amountIn1, instructions.amountOut1Min, instructions.swapData1, 0, 0, "", 0, 0, instructions.swapAndMintReturnData), instructions.unwrap);
            } else if (instructions.targetToken == state.token1) {
                if (state.amount0 < instructions.amountIn0) {
                    revert AmountError();
                }
                (state.newTokenId,,,) = _swapAndMint(SwapAndMintParams(IERC20(state.token0), IERC20(state.token1), instructions.fee, instructions.tickLower, instructions.tickUpper, state.amount0, state.amount1, instructions.recipient, from, instructions.deadline, IERC20(state.token0), 0, 0, "", instructions.amountIn0, instructions.amountOut0Min, instructions.swapData0, 0, 0, instructions.swapAndMintReturnData), instructions.unwrap);
            } else {
                // no swap is done here
                (state.newTokenId,,,) = _swapAndMint(SwapAndMintParams(IERC20(state.token0), IERC20(state.token1), instructions.fee, instructions.tickLower, instructions.tickUpper, state.amount0, state.amount1, instructions.recipient, from, instructions.deadline, IERC20(state.token0), 0, 0, "", 0, 0, "", 0, 0, instructions.swapAndMintReturnData), instructions.unwrap);
            }

            emit ChangeRange(tokenId, state.newTokenId);
        } else if (instructions.whatToDo == WhatToDo.WITHDRAW_AND_COLLECT_AND_SWAP) {
            uint targetAmount;
            if (state.token0 != instructions.targetToken) {
                (uint amountInDelta, uint256 amountOutDelta) = _swap(IERC20(state.token0), IERC20(instructions.targetToken), state.amount0, instructions.amountOut0Min, instructions.swapData0);
                if (amountInDelta < state.amount0) {
                    _transferToken(instructions.recipient, IERC20(state.token0), state.amount0 - amountInDelta, instructions.unwrap);
                }
                targetAmount += amountOutDelta;
            } else {
                targetAmount += state.amount0; 
            }
            if (state.token1 != instructions.targetToken) {
                (uint amountInDelta, uint256 amountOutDelta) = _swap(IERC20(state.token1), IERC20(instructions.targetToken), state.amount1, instructions.amountOut1Min, instructions.swapData1);
                if (amountInDelta < state.amount1) {
                    _transferToken(instructions.recipient, IERC20(state.token1), state.amount1 - amountInDelta, instructions.unwrap);
                }
                targetAmount += amountOutDelta;
            } else {
                targetAmount += state.amount1; 
            }

            // send complete target amount
            if (targetAmount > 0 && instructions.targetToken != address(0)) {
                _transferToken(instructions.recipient, IERC20(instructions.targetToken), targetAmount, instructions.unwrap);
            }

            emit WithdrawAndCollectAndSwap(tokenId, instructions.targetToken, targetAmount);
        } else {
            revert NotSupportedWhatToDo();
        }
        
        // return token to owner (this line guarantees that token is returned to originating owner)
        nonfungiblePositionManager.safeTransferFrom(address(this), from, tokenId, instructions.returnData);

        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Params for swap() function
    struct SwapParams {
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        address recipient; // recipient of tokenOut and leftover tokenIn (if any leftover)
        bytes swapData;
        bool unwrap; // if tokenIn or tokenOut is WETH - unwrap
    }

    /// @notice Swaps amountIn of tokenIn for tokenOut - returning at least minAmountOut
    /// @param params Swap configuration
    /// If tokenIn is wrapped native token - both the token or the wrapped token can be sent (the sum of both must be equal to amountIn)
    /// Optionally unwraps any wrapped native token and returns native token instead
    function swap(SwapParams calldata params) external payable returns (uint256 amountOut) {

        _prepareAdd(params.tokenIn, IERC20(address(0)), IERC20(address(0)), params.amountIn, 0, 0);

        uint amountInDelta;
        (amountInDelta, amountOut) = _swap(params.tokenIn, params.tokenOut, params.amountIn, params.minAmountOut, params.swapData);

        // send swapped amount of tokenOut
        if (amountOut > 0) {
            _transferToken(params.recipient, params.tokenOut, amountOut, params.unwrap);
        }

        // if not all was swapped - return leftovers of tokenIn
        uint leftOver = params.amountIn - amountInDelta;
        if (leftOver > 0) {
            _transferToken(params.recipient, params.tokenIn, leftOver, params.unwrap);
        }
    }

    /// @notice Params for swapAndMint() function
    struct SwapAndMintParams {
        IERC20 token0;
        IERC20 token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;

        // how much is provided of token0 and token1
        uint256 amount0;
        uint256 amount1;
        address recipient; // recipient of leftover tokens
        address recipientNFT; // recipient of nft
        uint256 deadline;

        // source token for swaps (maybe either address(0), token0, token1 or another token)
        // if swapSourceToken is another token than token0 or token1 -> amountIn0 + amountIn1 of swapSourceToken are expected to be available
        IERC20 swapSourceToken;

        // if swapSourceToken needs to be swapped to token0 - set values
        uint amountIn0;
        uint amountOut0Min;
        bytes swapData0;

        // if swapSourceToken needs to be swapped to token1 - set values
        uint amountIn1;
        uint amountOut1Min;
        bytes swapData1;

        // min amount to be added after swap
        uint amountAddMin0;
        uint amountAddMin1;

        // data to be sent along newly created NFT when transfered to recipient (sent to IERC721Receiver callback)
        bytes returnData;
    }

    /// @notice Does 1 or 2 swaps from swapSourceToken to token0 and token1 and adds as much as possible liquidity to a newly minted position.
    /// @param params Swap and mint configuration
    /// Newly minted NFT and leftover tokens are returned to recipient
    function swapAndMint(SwapAndMintParams calldata params) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
        if (params.token0 == params.token1) {
            revert SameToken();
        }
        _prepareAdd(params.token0, params.token1, params.swapSourceToken, params.amount0, params.amount1, params.amountIn0 + params.amountIn1);
        (tokenId, liquidity, amount0, amount1) = _swapAndMint(params, msg.value > 0);
    }

    /// @notice Params for swapAndIncreaseLiquidity() function
    struct SwapAndIncreaseLiquidityParams {
        uint256 tokenId;

        // how much is provided of token0 and token1
        uint256 amount0;
        uint256 amount1;
        address recipient; // recipient of leftover tokens
        uint256 deadline;
        
        // source token for swaps (maybe either address(0), token0, token1 or another token)
        // if swapSourceToken is another token than token0 or token1 -> amountIn0 + amountIn1 of swapSourceToken are expected to be available
        IERC20 swapSourceToken;

        // if swapSourceToken needs to be swapped to token0 - set values
        uint amountIn0;
        uint amountOut0Min;
        bytes swapData0;

        // if swapSourceToken needs to be swapped to token1 - set values
        uint amountIn1;
        uint amountOut1Min;
        bytes swapData1;

        // min amount to be added after swap
        uint amountAddMin0;
        uint amountAddMin1;
    }

    /// @notice Does 1 or 2 swaps from swapSourceToken to token0 and token1 and adds as much as possible liquidity to any existing position (no need to be position owner).
    /// @param params Swap and increase liquidity configuration
    // Sends any leftover tokens to recipient.
    function swapAndIncreaseLiquidity(SwapAndIncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
        (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(params.tokenId);
        _prepareAdd(IERC20(token0), IERC20(token1), params.swapSourceToken, params.amount0, params.amount1, params.amountIn0 + params.amountIn1);
        (liquidity, amount0, amount1) = _swapAndIncrease(params, IERC20(token0), IERC20(token1), msg.value > 0);
    }

    // checks if required amounts are provided and are exact - wraps any provided ETH as WETH
    // if less or more provided reverts
    function _prepareAdd(IERC20 token0, IERC20 token1, IERC20 otherToken, uint amount0, uint amount1, uint amountOther) internal
    {
        uint amountAdded0;
        uint amountAdded1;
        uint amountAddedOther;

        // wrap ether sent
        if (msg.value > 0) {
            weth.deposit{ value: msg.value }();

            if (address(weth) == address(token0)) {
                amountAdded0 = msg.value;
                if (amountAdded0 > amount0) {
                    revert TooMuchEtherSent();
                }
            } else if (address(weth) == address(token1)) {
                amountAdded1 = msg.value;
                if (amountAdded1 > amount1) {
                    revert TooMuchEtherSent();
                }
            } else if (address(weth) == address(otherToken)) {
                amountAddedOther = msg.value;
                if (amountAddedOther > amountOther) {
                    revert TooMuchEtherSent();
                }
            } else {
                revert NoEtherToken();
            }
        }

        // get missing tokens (fails if not enough provided)
        if (amount0 > amountAdded0) {
            uint balanceBefore = token0.balanceOf(address(this));
            SafeERC20.safeTransferFrom(token0, msg.sender, address(this), amount0 - amountAdded0);
            uint balanceAfter = token0.balanceOf(address(this));
            if (balanceAfter - balanceBefore != amount0 - amountAdded0) {
                revert TransferError(); // reverts for fee-on-transfer tokens
            }
        }
        if (amount1 > amountAdded1) {
            uint balanceBefore = token1.balanceOf(address(this));
            SafeERC20.safeTransferFrom(token1, msg.sender, address(this), amount1 - amountAdded1);
            uint balanceAfter = token1.balanceOf(address(this));
            if (balanceAfter - balanceBefore != amount1 - amountAdded1) {
                revert TransferError(); // reverts for fee-on-transfer tokens
            }
        }
        if (address(otherToken) != address(0) && token0 != otherToken && token1 != otherToken && amountOther > amountAddedOther) {
            uint balanceBefore = otherToken.balanceOf(address(this));
            SafeERC20.safeTransferFrom(otherToken, msg.sender, address(this), amountOther - amountAddedOther);
            uint balanceAfter = otherToken.balanceOf(address(this));
            if (balanceAfter - balanceBefore != amountOther - amountAddedOther) {
                revert TransferError(); // reverts for fee-on-transfer tokens
            }
        }
    }

    // swap and mint logic
    function _swapAndMint(SwapAndMintParams memory params, bool unwrap) internal returns (uint tokenId, uint128 liquidity, uint added0, uint added1) {

        (uint total0, uint total1) = _swapAndPrepareAmounts(params, unwrap);

        INonfungiblePositionManager.MintParams memory mintParams = 
            INonfungiblePositionManager.MintParams(
                address(params.token0), 
                address(params.token1), 
                params.fee, 
                params.tickLower, 
                params.tickUpper,
                total0,
                total1, 
                params.amountAddMin0,
                params.amountAddMin1,
                address(this), // is sent to real recipient aftwards
                params.deadline
            );

        // mint is done to address(this) because it is not a safemint and safeTransferFrom needs to be done manually afterwards
        (tokenId,liquidity,added0,added1) = nonfungiblePositionManager.mint(mintParams);

        // IMPORTANT to be able to pass msg.sender to receiving contract - this is added to return data - this breaks money lego style data :(
        // other contracts recieving NFTs with data from V3Utils must implement this special behaviour
        nonfungiblePositionManager.safeTransferFrom(address(this), params.recipientNFT, tokenId, abi.encode(msg.sender, params.returnData));

        emit SwapAndMint(tokenId, liquidity, added0, added1);

        _returnLeftoverTokens(params.recipient, params.token0, params.token1, total0, total1, added0, added1, unwrap);
    }

    // swap and increase logic
    function _swapAndIncrease(SwapAndIncreaseLiquidityParams memory params, IERC20 token0, IERC20 token1, bool unwrap) internal returns (uint128 liquidity, uint added0, uint added1) {

        (uint total0, uint total1) = _swapAndPrepareAmounts(
            SwapAndMintParams(token0, token1, 0, 0, 0, params.amount0, params.amount1, params.recipient, params.recipient, params.deadline, params.swapSourceToken, params.amountIn0, params.amountOut0Min, params.swapData0, params.amountIn1, params.amountOut1Min, params.swapData1, params.amountAddMin0, params.amountAddMin1, ""), unwrap);

        INonfungiblePositionManager.IncreaseLiquidityParams memory increaseLiquidityParams = 
            INonfungiblePositionManager.IncreaseLiquidityParams(
                params.tokenId, 
                total0, 
                total1, 
                params.amountAddMin0,
                params.amountAddMin1, 
                params.deadline
            );

        (liquidity, added0, added1) = nonfungiblePositionManager.increaseLiquidity(increaseLiquidityParams);

        emit SwapAndIncreaseLiquidity(params.tokenId, liquidity, added0, added1);

        _returnLeftoverTokens(params.recipient, token0, token1, total0, total1, added0, added1, unwrap);
    }

    // swaps available tokens and prepares max amounts to be added to nonfungiblePositionManager
    function _swapAndPrepareAmounts(SwapAndMintParams memory params, bool unwrap) internal returns (uint total0, uint total1) {
        if (params.swapSourceToken == params.token0) { 
            if (params.amount0 < params.amountIn1) {
                revert AmountError();
            }
            (uint amountInDelta, uint256 amountOutDelta) = _swap(params.token0, params.token1, params.amountIn1, params.amountOut1Min, params.swapData1);
            total0 = params.amount0 - amountInDelta;
            total1 = params.amount1 + amountOutDelta;
        } else if (params.swapSourceToken == params.token1) { 
            if (params.amount1 < params.amountIn0) {
                revert AmountError();
            }
            (uint amountInDelta, uint256 amountOutDelta) = _swap(params.token1, params.token0, params.amountIn0, params.amountOut0Min, params.swapData0);
            total1 = params.amount1 - amountInDelta;
            total0 = params.amount0 + amountOutDelta;
        } else if (address(params.swapSourceToken) != address(0)) {

            (uint amountInDelta0, uint256 amountOutDelta0) = _swap(params.swapSourceToken, params.token0, params.amountIn0, params.amountOut0Min, params.swapData0);
            (uint amountInDelta1, uint256 amountOutDelta1) = _swap(params.swapSourceToken, params.token1, params.amountIn1, params.amountOut1Min, params.swapData1);
            total0 = params.amount0 + amountOutDelta0;
            total1 = params.amount1 + amountOutDelta1;

            // return third token leftover if any
            uint leftOver = params.amountIn0 + params.amountIn1 - amountInDelta0 - amountInDelta1;

            if (leftOver > 0) {
                _transferToken(params.recipient, params.swapSourceToken, leftOver, unwrap);
            }
        } else {
            total0 = params.amount0;
            total1 = params.amount1;
        }

        if (total0 > 0) {
            params.token0.approve(address(nonfungiblePositionManager), total0);
        }
        if (total1 > 0) {
            params.token1.approve(address(nonfungiblePositionManager), total1);
        }
    }

    // returns leftover token balances
    function _returnLeftoverTokens(address to, IERC20 token0, IERC20 token1, uint total0, uint total1, uint added0, uint added1, bool unwrap) internal {

        uint left0 = total0 - added0;
        uint left1 = total1 - added1;

        // return leftovers
        if (left0 > 0) {
            _transferToken(to, token0, left0, unwrap);
        }
        if (left1 > 0) {
            _transferToken(to, token1, left1, unwrap);
        }
    }

    // transfers token (or unwraps WETH and sends ETH)
    function _transferToken(address to, IERC20 token, uint amount, bool unwrap) internal {
        if (address(weth) == address(token) && unwrap) {
            weth.withdraw(amount);
            (bool sent, ) = to.call{value: amount}("");
            if (!sent) {
                revert EtherSendFailed();
            }
        } else {
            SafeERC20.safeTransfer(token, to, amount);
        }
    }

    // general swap function which uses external router with off-chain calculated swap instructions
    // does slippage check with amountOutMin param
    // returns token amounts deltas after swap
    function _swap(IERC20 tokenIn, IERC20 tokenOut, uint amountIn, uint amountOutMin, bytes memory swapData) internal returns (uint amountInDelta, uint256 amountOutDelta) {
        if (amountIn > 0 && swapData.length > 0 && address(tokenOut) != address(0)) {
            uint balanceInBefore = tokenIn.balanceOf(address(this));
            uint balanceOutBefore = tokenOut.balanceOf(address(this));

            // get router specific swap data
            (address swapRouter, address allowanceTarget, bytes memory data) = abi.decode(swapData, (address, address, bytes));

            // approve needed amount
            tokenIn.approve(allowanceTarget, amountIn);

            // execute swap
            (bool success,) = swapRouter.call(data);
            if (!success) {
                revert SwapFailed();
            }

            // remove any remaining allowance
            tokenIn.approve(allowanceTarget, 0);

            uint balanceInAfter = tokenIn.balanceOf(address(this));
            uint balanceOutAfter = tokenOut.balanceOf(address(this));

            amountInDelta = balanceInBefore - balanceInAfter;
            amountOutDelta = balanceOutAfter - balanceOutBefore;

            // amountMin slippage check
            if (amountOutDelta < amountOutMin) {
                revert SlippageError();
            }

            // event for any swap with exact swapped value
            emit Swap(address(tokenIn), address(tokenOut), amountInDelta, amountOutDelta);
        }
    }

    // decreases liquidity from uniswap v3 position
    function _decreaseLiquidity(uint tokenId, uint128 liquidity, uint deadline, uint token0Min, uint token1Min) internal returns (uint256 amount0, uint256 amount1) {
        if (liquidity > 0) {
            (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
                INonfungiblePositionManager.DecreaseLiquidityParams(
                    tokenId, 
                    liquidity, 
                    token0Min, 
                    token1Min,
                    deadline
                )
            );
        }
    }

    // collects specified amount of fees from uniswap v3 position
    function _collectFees(uint tokenId, IERC20 token0, IERC20 token1, uint128 collectAmount0, uint128 collectAmount1) internal returns (uint256 amount0, uint256 amount1) {
        uint balanceBefore0 = token0.balanceOf(address(this));
        uint balanceBefore1 = token1.balanceOf(address(this));
        (amount0, amount1) = nonfungiblePositionManager.collect(
            INonfungiblePositionManager.CollectParams(tokenId, address(this), collectAmount0, collectAmount1)
        );
        uint balanceAfter0 = token0.balanceOf(address(this));
        uint balanceAfter1 = token1.balanceOf(address(this));

        // reverts for fee-on-transfer tokens
        if (balanceAfter0 - balanceBefore0 != amount0) {
            revert CollectError();
        }
        if (balanceAfter1 - balanceBefore1 != amount1) {
            revert CollectError();
        }
    }

    // utility function to do safe downcast
    function _toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    // needed for WETH unwrapping
    receive() external payable {
        if (msg.sender != address(weth)) {
            revert NotWETH();
        }
    }
}