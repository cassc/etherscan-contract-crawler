// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './libraries/Math.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UniswapV2Router02 is IUniswapV2Router02, Initializable {
    using SafeMathUniswap for uint;

    address public override factory;
    address public override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'DVF_AMM_Router: EXPIRED');
        _;
    }

    function initialize(address _factory, address _WETH) initializer external {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    event Sync(address indexed pair, string id, string name, uint256 vaultId);
    event Layer2StateChange(address indexed pair, bool isLayer2, uint balance0, uint balance1, uint totalSupply);

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'DVF_AMM_Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'DVF_AMM_Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = UniswapV2Library.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'DVF_AMM_Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'DVF_AMM_Router: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'DVF_AMM_Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'DVF_AMM_Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'DVF_AMM_Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'DVF_AMM_Router: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'DVF_AMM_Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'DVF_AMM_Router: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'DVF_AMM_Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'DVF_AMM_Router: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'DVF_AMM_Router: INVALID_PATH');
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'DVF_AMM_Router: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20Uniswap(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    /**
    L2 overlay and sync functions
     */
    function syncStarkware(
      StarkwareSyncDtos.SwapArgs memory swapArgs,
      StarkwareSyncDtos.FundingArgs memory fundingArgs,
      uint nonceToUse,
      address exchangeAddress,
      string calldata id
    ) external returns(bool) {
      address pairAddress = UniswapV2Library.pairFor(factory, fundingArgs.tokenA, fundingArgs.tokenB);
      IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

      emit Sync(pairAddress, id, 'syncStarkware', pair.currentVault());

      pair.syncStarkware(
        swapArgs,
        fundingArgs,
        nonceToUse,
        exchangeAddress
      );

      return true;
    }

    function settleStarkWare(address tokenA, address tokenB, string memory id) external returns(bool) {
      address pairAddress = UniswapV2Library.pairFor(factory, tokenA, tokenB);
      IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
      emit Sync(pairAddress, id, 'settleStarkWare', pair.currentVault());
      return pair.settleStarkWare();
    }

    function abortStarkware(address tokenA, address tokenB, string memory id) external returns(uint256 newVaultId) {
      address pairAddress = UniswapV2Library.pairFor(factory, tokenA, tokenB);
      IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
      newVaultId = pair.abortStarkware();
      emit Sync(pairAddress, id, 'abortStarkware', newVaultId);
    }

    function getPairState(address tokenA, address tokenB) public view returns (uint reserveA, uint reserveB, uint totalSupply) {
      IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
      (reserveA, reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
      totalSupply = pair.totalSupply();
    }

    /**
     * @dev Toggle layer2 status of the underlying pair
     */
    function toggleLayer2(address tokenA, address tokenB, bool state) public {
      address pairAddress = UniswapV2Library.pairFor(factory, tokenA, tokenB);
      IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
      pair.toggleLayer2(state);
      (uint balance0, uint balance1, uint totalSupply) = getPairState(tokenA, tokenB);

      emit Layer2StateChange(pairAddress, state, balance0, balance1, totalSupply);
    }

    function setupStarkware(address tokenA, address tokenB, uint assetId, uint tokenAAssetId, uint tokenBAssetId) public {
      IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
      (tokenAAssetId, tokenBAssetId) = UniswapV2Library.sortNumbersForTokens(tokenA, tokenB, tokenAAssetId, tokenBAssetId);
      pair.setupStarkware(assetId, tokenAAssetId, tokenBAssetId);
    }

    /**
     * @dev Sort a pair fo tokens
     */
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1) {
      (token0, token1) = UniswapV2Library.sortTokens(tokenA, tokenB);
    }

    /**
     * @dev get Pair address for a potential pair of tokens, pair does not have to exist
     */
    function pairFor(address tokenA, address tokenB) external view returns (address pair) {
      pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }

    /**
     * @dev Create a pair and setup starkware assetIds
     */
    function createPair(address tokenA, address tokenB, address expectedPairAddress) public returns (address pair) {
      pair = IUniswapV2Factory(factory).createPair(tokenA, tokenB);
      require(pair == expectedPairAddress, 'DVF: EXPECTED_PAIR_ADDRESS_MISMATCH');
    }

    /**
     * @dev Setup starkware variables, deposit funds and switch to L2
     */
    function depositAndActiveL2(address tokenA, address tokenB,
      uint pairAssetId, uint tokenAAssetId, uint tokenBAssetId,
      uint amountA, uint amountB, address to) external {
       setupStarkware(tokenA, tokenB, pairAssetId, tokenAAssetId, tokenBAssetId);
       addLiquidity(tokenA, tokenB, amountA, amountB, 1, 1, to, type(uint).max);
       toggleLayer2(tokenA, tokenB, true);
    }

    /**
     * @dev Setup starkware information and activate layer 2
     */
    function setupAndActivateL2(address tokenA, address tokenB, uint pairAssetId, uint tokenAAssetId,
     uint tokenBAssetId) external {
       setupStarkware(tokenA, tokenB, pairAssetId, tokenAAssetId, tokenBAssetId);
       toggleLayer2(tokenA, tokenB, true);
    }
}