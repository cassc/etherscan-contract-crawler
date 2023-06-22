// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./NarwhalRouter.sol";
import "./BMath.sol";
import "./interfaces/IIndexPool.sol";
import "./interfaces/IERC20.sol";
import "./libraries/TransferHelper.sol";


contract IndexedNarwhalRouter is NarwhalRouter, BMath {
  using TokenInfo for bytes32;
  using TokenInfo for address;
  using TransferHelper for address;
  using SafeMath for uint256;

  constructor(
    address _uniswapFactory,
    address _sushiswapFactory,
    address _weth
  ) NarwhalRouter(_uniswapFactory, _sushiswapFactory, _weth) {}

/** ========== Mint Single: Exact In ========== */

  /**
   * @dev Swaps ether for each token in `path` using their Uniswap pairs,
   * then mints at least `minPoolAmountOut` pool tokens from `indexPool`.
   *
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param minPoolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapExactETHForTokensAndMint(
    bytes32[] calldata path,
    address indexPool,
    uint minPoolAmountOut
  ) external payable returns (uint poolAmountOut) {
    require(path[0].readToken() == address(weth), "NRouter: INVALID_PATH");
    uint256[] memory amounts = getAmountsOut(path, msg.value);

    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, address(this));

    uint amountOut =  amounts[amounts.length - 1];
    return _mintExactIn(
      path[path.length - 1].readToken(),
      amountOut,
      indexPool,
      minPoolAmountOut
    );
  }

  /**
   * @dev Swaps a token for each other token in `path` using their Uniswap pairs,
   * then mints at least `minPoolAmountOut` pool tokens from `indexPool`.
   *
   * @param amountIn Amount of the first token in `path` to swap.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param minPoolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapExactTokensForTokensAndMint(
    uint amountIn,
    bytes32[] calldata path,
    address indexPool,
    uint minPoolAmountOut
  ) external returns (uint poolAmountOut) {
    uint256[] memory amounts = getAmountsOut(path, amountIn);
    path[0].readToken().safeTransferFrom(
      msg.sender, pairFor(path[0], path[1]), amounts[0]
    );
    _swap(amounts, path, address(this));
    uint amountOut = amounts[amounts.length - 1];

    return _mintExactIn(
      path[path.length - 1].readToken(),
      amountOut,
      indexPool,
      minPoolAmountOut
    );
  }

  function _mintExactIn(
    address tokenIn,
    uint amountIn,
    address indexPool,
    uint minPoolAmountOut
  ) internal returns (uint poolAmountOut) {
    TransferHelper.safeApprove(tokenIn, indexPool, amountIn);
    poolAmountOut = IIndexPool(indexPool).joinswapExternAmountIn(
      tokenIn,
      amountIn,
      minPoolAmountOut
    );
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
  }

/** ========== Burn Single: Exact In ========== */


  /**
   * @dev Redeems `poolAmountIn` pool tokens for the first token in `path`
   * and swaps it to at least `minAmountOut` of the last token in `path`.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountIn Amount of pool tokens to burn.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param minAmountOut Amount of last token in `path` that must be received to not revert.
   * @return amountOut Amount of output tokens received.
   */
  function burnExactAndSwapForTokens(
    address indexPool,
    uint poolAmountIn,
    bytes32[] calldata path,
    uint minAmountOut
  ) external returns (uint amountOut) {
    amountOut = _burnExactAndSwap(
      indexPool,
      poolAmountIn,
      path,
      minAmountOut,
      msg.sender
    );
  }

  /**
   * @dev Redeems `poolAmountIn` pool tokens for the first token in `path`
   * and swaps it to at least `minAmountOut` ether.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountIn Amount of pool tokens to burn.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param minAmountOut Amount of ether that must be received to not revert.
   * @return amountOut Amount of ether received.
   */
  function burnExactAndSwapForETH(
    address indexPool,
    uint poolAmountIn,
    bytes32[] calldata path,
    uint minAmountOut
  ) external returns (uint amountOut) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
    amountOut = _burnExactAndSwap(
      indexPool,
      poolAmountIn,
      path,
      minAmountOut,
      address(this)
    );
    IWETH(weth).withdraw(amountOut);
    TransferHelper.safeTransferETH(msg.sender, amountOut);
  }

  function _burnExactAndSwap(
    address indexPool,
    uint poolAmountIn,
    bytes32[] memory path,
    uint minAmountOut,
    address recipient
  ) internal returns (uint amountOut) {
    // Transfer the pool tokens to the router.
    TransferHelper.safeTransferFrom(
      indexPool,
      msg.sender,
      address(this),
      poolAmountIn
    );
    // Burn the pool tokens for the first token in `path`.
    uint redeemedAmountOut = IIndexPool(indexPool).exitswapPoolAmountIn(
      path[0].readToken(),
      poolAmountIn,
      0
    );
    // Calculate the swap amounts for the redeemed amount of the first token in `path`.
    uint[] memory amounts = getAmountsOut(path, redeemedAmountOut);
    amountOut = amounts[amounts.length - 1];
    require(amountOut >= minAmountOut, "NRouter: MIN_OUT");
    // Transfer the redeemed tokens to the first Uniswap pair.
    TransferHelper.safeTransfer(
      path[0].readToken(),
      pairFor(path[0], path[1]),
      amounts[0]
    );
    // Execute the routed swaps and send the output tokens to `recipient`.
    _swap(amounts, path, recipient);
  }

/** ========== Mint Single: Exact Out ========== */

  /**
   * @dev Swaps ether for each token in `path` through Uniswap,
   * then mints `poolAmountOut` pool tokens from `indexPool`.
   *
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param poolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapETHForTokensAndMintExact(
    bytes32[] calldata path,
    address indexPool,
    uint poolAmountOut
  ) external payable {
    address swapTokenOut = path[path.length - 1].readToken();
    uint amountOut = _tokenInGivenPoolOut(indexPool, swapTokenOut, poolAmountOut);
    require(path[0].readToken() == address(weth), "INVALID_PATH");

    uint[] memory amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= msg.value, "NRouter: MAX_IN");

    weth.deposit{value: amounts[0]}();
    address(weth).safeTransfer(pairFor(path[0], path[1]), amounts[0]);
    _swap(amounts, path, address(this));

    // refund dust eth, if any
    if (msg.value > amounts[0]) {
      TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    return _mintExactOut(
      swapTokenOut,
      amountOut,
      indexPool,
      poolAmountOut
    );
  }

  /**
   * @dev Swaps a token for each other token in `path` through Uniswap,
   * then mints at least `poolAmountOut` pool tokens from `indexPool`.
   *
   * @param amountInMax Maximum amount of the first token in `path` to give.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param indexPool Address of the index pool to mint tokens from.
   * @param poolAmountOut Amount of pool tokens that must be received to not revert.
   */
  function swapTokensForTokensAndMintExact(
    uint amountInMax,
    bytes32[] calldata path,
    address indexPool,
    uint poolAmountOut
  ) external {
    address swapTokenOut = path[path.length - 1].readToken();
    uint amountOut = _tokenInGivenPoolOut(indexPool, swapTokenOut, poolAmountOut);
    uint[] memory amounts = getAmountsIn(path, amountOut);
    require(amounts[0] <= amountInMax, "NRouter: MAX_IN");
    path[0].readToken().safeTransferFrom(
      msg.sender, pairFor(path[0], path[1]), amounts[0]
    );
    _swap(amounts, path, address(this));
    _mintExactOut(
      swapTokenOut,
      amountOut,
      indexPool,
      poolAmountOut
    );
  }

  function _mintExactOut(
    address tokenIn,
    uint amountIn,
    address indexPool,
    uint poolAmountOut
  ) internal {
    TransferHelper.safeApprove(tokenIn, indexPool, amountIn);
    IIndexPool(indexPool).joinswapPoolAmountOut(
      tokenIn,
      poolAmountOut,
      amountIn
    );
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
  }

  function _tokenInGivenPoolOut(
    address indexPool,
    address tokenIn,
    uint256 poolAmountOut
  ) internal view returns (uint256 amountIn) {
    IIndexPool.Record memory record = IIndexPool(indexPool).getTokenRecord(tokenIn);
    if (!record.ready) {
      uint256 minimumBalance = IIndexPool(indexPool).getMinimumBalance(tokenIn);
      uint256 realToMinRatio = bdiv(
        bsub(minimumBalance, record.balance),
        minimumBalance
      );
      uint256 weightPremium = bmul(MIN_WEIGHT / 10, realToMinRatio);
      record.balance = minimumBalance;
      record.denorm = uint96(badd(MIN_WEIGHT, weightPremium));
    }

    uint256 totalSupply = IERC20(indexPool).totalSupply();
    uint256 totalWeight = IIndexPool(indexPool).getTotalDenormalizedWeight();
    uint256 swapFee = IIndexPool(indexPool).getSwapFee();

    return calcSingleInGivenPoolOut(
      record.balance,
      record.denorm,
      totalSupply,
      totalWeight,
      poolAmountOut,
      swapFee
    );
  }

/** ========== Burn Single: Exact Out ========== */

  /**
   * @dev Redeems up to `poolAmountInMax` pool tokens for the first token in `path`
   * and swaps it to exactly `tokenAmountOut` of the last token in `path`.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountInMax Maximum amount of pool tokens to burn.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param tokenAmountOut Amount of last token in `path` to receive.
   * @return poolAmountIn Amount of pool tokens burned.
   */
  function burnAndSwapForExactTokens(
    address indexPool,
    uint poolAmountInMax,
    bytes32[] calldata path,
    uint tokenAmountOut
  ) external returns (uint poolAmountIn) {
    poolAmountIn = _burnAndSwapForExact(
      indexPool,
      poolAmountInMax,
      path,
      tokenAmountOut,
      msg.sender
    );
  }

  /**
   * @dev Redeems up to `poolAmountInMax` pool tokens for the first token in `path`
   * and swaps it to exactly `ethAmountOut` ether.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param poolAmountInMax Maximum amount of pool tokens to burn.
   * @param path Array of encoded tokens to swap using the Narwhal router.
   * @param ethAmountOut Amount of eth to receive.
   * @return poolAmountIn Amount of pool tokens burned.
   */
  function burnAndSwapForExactETH(
    address indexPool,
    uint poolAmountInMax,
    bytes32[] calldata path,
    uint ethAmountOut
  ) external returns (uint poolAmountIn) {
    require(path[path.length - 1].readToken() == address(weth), "NRouter: INVALID_PATH");
    poolAmountIn = _burnAndSwapForExact(
      indexPool,
      poolAmountInMax,
      path,
      ethAmountOut,
      address(this)
    );
    IWETH(weth).withdraw(ethAmountOut);
    TransferHelper.safeTransferETH(msg.sender, ethAmountOut);
  }

  function _burnAndSwapForExact(
    address indexPool,
    uint poolAmountInMax,
    bytes32[] memory path,
    uint tokenAmountOut,
    address recipient
  ) internal returns (uint poolAmountIn) {
    // Transfer the maximum pool tokens to the router.
    indexPool.safeTransferFrom(
      msg.sender,
      address(this),
      poolAmountInMax
    );
    // Calculate the swap amounts for `tokenAmountOut` of the last token in `path`.
    uint[] memory amounts = getAmountsIn(path, tokenAmountOut);
    // Burn the pool tokens for the exact amount of the first token in `path`.
    poolAmountIn = IIndexPool(indexPool).exitswapExternAmountOut(
      path[0].readToken(),
      amounts[0],
      poolAmountInMax
    );
    // Transfer the redeemed tokens to the first Uniswap pair.
    TransferHelper.safeTransfer(
      path[0].readToken(),
      pairFor(path[0], path[1]),
      amounts[0]
    );
    // Execute the routed swaps and send the output tokens to `recipient`.
    _swap(amounts, path, recipient);
    // Return any unburned pool tokens to the caller.
    indexPool.safeTransfer(
      msg.sender,
      poolAmountInMax.sub(poolAmountIn)
    );
  }

/** ========== Mint All: Exact Out ========== */

  /**
   * @dev Swaps an input token for every underlying token in an index pool,
   * then mints `poolAmountOut` pool tokens from the pool.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   *
   * `intermediaries` is an encoded Narwhal path with a one-byte prefix indicating
   * whether the first swap should use sushiswap.
   *
   * @param indexPool Address of the index pool to mint tokens with.
   * @param intermediaries Encoded Narwhal tokens array with a one-byte prefix
   * indicating whether the swap to the underlying token should use sushiswap.
   * @param poolAmountOut Amount of index pool tokens to mint.
   * @param tokenIn Token to buy the underlying tokens with.
   * @param amountInMax Maximumm amount of `tokenIn` to spend.
   * @return Amount of `tokenIn` spent.
   */
  function swapTokensForAllTokensAndMintExact(
    address indexPool,
    bytes32[] calldata intermediaries,
    uint256 poolAmountOut,
    address tokenIn,
    uint256 amountInMax
  ) external returns (uint256) {
    uint256 remainder = amountInMax;
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      tokens.length == intermediaries.length,
      "NRouter: ARR_LEN"
    );
    tokenIn.safeTransferFrom(msg.sender, address(this), amountInMax);
    uint256[] memory amountsToPool = new uint256[](tokens.length);

    uint256 ratio = bdiv(poolAmountOut, IERC20(indexPool).totalSupply());

    // Reserve 3 slots in memory for the addresses
    bytes32[] memory path = new bytes32[](3);
    path[0] = tokenIn.pack(false);
    for (uint256 i = 0; i < tokens.length; i++) {
      (amountsToPool[i], remainder) = _handleMintInput(
        indexPool,
        intermediaries[i],
        tokens[i],
        path,
        ratio,
        remainder
      );
    }
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);
    if (remainder > 0) {
      tokenIn.safeTransfer(msg.sender, remainder);
    }
    return amountInMax.sub(remainder);
  }

  /**
   * @dev Swaps ether for every underlying token in an index pool,
   * then mints `poolAmountOut` pool tokens from the pool.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   *
   * `intermediaries` is an encoded Narwhal path with a one-byte prefix indicating
   * whether the first swap should use sushiswap.
   *
   * @param indexPool Address of the index pool to mint tokens with.
   * @param intermediaries Encoded Narwhal tokens array with a one-byte prefix
   * indicating whether the swap to the underlying token should use sushiswap.
   * @param poolAmountOut Amount of index pool tokens to mint.
   * @return Amount of ether spent.
   */
  function swapETHForAllTokensAndMintExact(
    address indexPool,
    bytes32[] calldata intermediaries,
    uint256 poolAmountOut
  ) external payable returns (uint) {
    uint256 remainder = msg.value;
    IWETH(weth).deposit{value: msg.value}();
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(tokens.length == intermediaries.length, "NRouter: ARR_LEN");
    uint256[] memory amountsToPool = new uint256[](tokens.length);

    uint256 ratio = bdiv(poolAmountOut, IERC20(indexPool).totalSupply());

    // Reserve 3 slots in memory for the addresses
    bytes32[] memory path = new bytes32[](3);
    path[0] = address(weth).pack(false);

    for (uint256 i = 0; i < tokens.length; i++) {
      (amountsToPool[i], remainder) = _handleMintInput(
        indexPool,
        intermediaries[i],
        tokens[i],
        path,
        ratio,
        remainder
      );
    }
    IIndexPool(indexPool).joinPool(poolAmountOut, amountsToPool);
    TransferHelper.safeTransfer(indexPool, msg.sender, poolAmountOut);

    if (remainder > 0) {
      IWETH(weth).withdraw(remainder);
      TransferHelper.safeTransferETH(msg.sender, remainder);
    }
    return msg.value.sub(remainder);
  }

  function _handleMintInput(
    address indexPool,
    bytes32 intermediate,
    address poolToken,
    bytes32[] memory path,
    uint256 poolRatio,
    uint256 amountInMax
  ) internal returns (uint256 amountToPool, uint256 remainder) {
    address tokenIn = path[0].readToken();
    uint256 usedBalance = IIndexPool(indexPool).getUsedBalance(poolToken);
    amountToPool = bmul(poolRatio, usedBalance);
    if (tokenIn == poolToken) {
      remainder = amountInMax.sub(amountToPool, "NRouter: MAX_IN");
    } else {
      bool sushiFirst;
      assembly {
        sushiFirst := shr(168,  intermediate)
        intermediate := and(
          0x0000000000000000000000ffffffffffffffffffffffffffffffffffffffffff,
          intermediate
        )
      }
      path[0] = tokenIn.pack(sushiFirst);
      if (intermediate == bytes32(0)) {
        // If no intermediate token is given, set path length to 2 so the other
        // functions will not use the 3rd address.
        assembly { mstore(path, 2) }
        // It doesn't matter whether a token is set to use sushi or not
        // if it is the last token in the list.
        path[1] = poolToken.pack(false);
      } else {
        // If an intermediary is given, set path length to 3 so the other
        // functions will use all addresses.
        assembly { mstore(path, 3) }
        path[1] = intermediate;
        path[2] = poolToken.pack(false);
      }
      uint[] memory amounts = getAmountsIn(path, amountToPool);
      remainder = amountInMax.sub(amounts[0], "NRouter: MAX_IN");
      tokenIn.safeTransfer(pairFor(path[0], path[1]), amounts[0]);
      _swap(amounts, path, address(this));
    }
    poolToken.safeApprove(indexPool, amountToPool);
  }

/** ========== Burn All: Exact In ========== */

  /**
   * @dev Burns `poolAmountOut` for all the underlying tokens in a pool, then
   * swaps each of them on Uniswap for at least `minAmountOut` of `tokenOut`.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param minAmountsOut Minimum amount of each underlying token that must be
   * received from the pool to not revert.
   * @param intermediaries Encoded Narwhal tokens array with a one-byte prefix
   * indicating whether the swap to the underlying token should use sushiswap.
   * @param poolAmountIn Amount of index pool tokens to burn.
   * @param tokenOut Address of the token to buy.
   * @param minAmountOut Minimum amount of `tokenOut` that must be received to
   * not revert.
   * @return amountOutTotal Amount of `tokenOut` received.
   */
  function burnForAllTokensAndSwapForTokens(
    address indexPool,
    uint256[] calldata minAmountsOut,
    bytes32[] calldata intermediaries,
    uint256 poolAmountIn,
    address tokenOut,
    uint256 minAmountOut
  ) external returns (uint256 amountOutTotal) {
    amountOutTotal = _burnForAllTokensAndSwap(
      indexPool,
      tokenOut,
      minAmountsOut,
      intermediaries,
      poolAmountIn,
      minAmountOut,
      msg.sender
    );
  }

  /**
   * @dev Burns `poolAmountOut` for all the underlying tokens in a pool, then
   * swaps each of them on Uniswap for at least `minAmountOut` ether.
   *
   * Up to one intermediary token may be provided in `intermediaries` for each
   * underlying token in the index pool.
   *
   * If a null address is provided as an intermediary, the input token will be
   * swapped directly for the output token.
   *
   * @param indexPool Address of the index pool to burn tokens from.
   * @param minAmountsOut Minimum amount of each underlying token that must be
   * received from the pool to not revert.
   * @param intermediaries Encoded Narwhal tokens array with a one-byte prefix
   * indicating whether the swap to the underlying token should use sushiswap.
   * @param poolAmountIn Amount of index pool tokens to burn.
   * @param minAmountOut Minimum amount of ether that must be received to
   * not revert.
   * @return amountOutTotal Amount of ether received.
   */
  function burnForAllTokensAndSwapForETH(
    address indexPool,
    uint256[] calldata minAmountsOut,
    bytes32[] calldata intermediaries,
    uint256 poolAmountIn,
    uint256 minAmountOut
  ) external returns (uint amountOutTotal) {
    amountOutTotal = _burnForAllTokensAndSwap(
      indexPool,
      address(weth),
      minAmountsOut,
      intermediaries,
      poolAmountIn,
      minAmountOut,
      address(this)
    );
    IWETH(weth).withdraw(amountOutTotal);
    TransferHelper.safeTransferETH(msg.sender, amountOutTotal);
  }

  function _burnForAllTokensAndSwap(
    address indexPool,
    address tokenOut,
    uint256[] calldata minAmountsOut,
    bytes32[] calldata intermediaries,
    uint256 poolAmountIn,
    uint256 minAmountOut,
    address recipient
  ) internal returns (uint amountOutTotal) {
    // Transfer the pool tokens from the caller.
    TransferHelper.safeTransferFrom(indexPool, msg.sender, address(this), poolAmountIn);
    address[] memory tokens = IIndexPool(indexPool).getCurrentTokens();
    require(
      intermediaries.length == tokens.length && minAmountsOut.length == tokens.length,
      "IndexedUniswapRouterBurner: BAD_ARRAY_LENGTH"
    );
    IIndexPool(indexPool).exitPool(poolAmountIn, minAmountsOut);
    // Reserve 3 slots in memory for the addresses
    bytes32[] memory path = new bytes32[](3);

    for (uint256 i = 0; i < tokens.length; i++) {
      uint amountOut = _handleBurnOutput(
        tokens[i],
        intermediaries[i],
        tokenOut,
        path,
        recipient
      );
      amountOutTotal = amountOutTotal.add(amountOut);
    }
    require(amountOutTotal >= minAmountOut, "NRouter: MIN_OUT");
  }

  function _handleBurnOutput(
    address tokenIn,
    bytes32 intermediate,
    address tokenOut,
    bytes32[] memory path,
    address recipient
  ) internal returns (uint amountOut) {
    uint256 _balance = IERC20(tokenIn).balanceOf(address(this));
    if (tokenIn == tokenOut) {
      amountOut = _balance;
      if (recipient != address(this)) {
        tokenIn.safeTransfer(recipient, _balance);
      }
    } else {
      bool sushiFirst;
      assembly {
        sushiFirst := shr(168,  intermediate)
        intermediate := and(
          0x0000000000000000000000ffffffffffffffffffffffffffffffffffffffffff,
          intermediate
        )
      }
      path[0] = tokenIn.pack(sushiFirst);
      if (intermediate == bytes32(0)) {
        // If no intermediate token is given, set path length to 2 so the other
        // functions will not use the 3rd address.
        assembly { mstore(path, 2) }
        // It doesn't matter whether a token is set to use sushi or not
        // if it is the last token in the list.
        path[1] = tokenOut.pack(false);
      } else {
        // If an intermediary is given, set path length to 3 so the other
        // functions will use all addresses.
        assembly { mstore(path, 3) }
        path[1] = intermediate;
        path[2] = tokenOut.pack(false);
      }
      uint[] memory amounts = getAmountsOut(path, _balance);
      tokenIn.safeTransfer(pairFor(path[0], path[1]), amounts[0]);
      _swap(amounts, path, recipient);
      amountOut = amounts[amounts.length - 1];
    }
  }
}