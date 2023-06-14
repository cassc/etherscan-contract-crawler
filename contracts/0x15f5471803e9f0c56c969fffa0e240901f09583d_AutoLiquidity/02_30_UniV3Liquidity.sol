// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../base/GovIdentity.sol";
import "../interfaces/uniswap-v3/Path.sol";
import "../libraries/EnumerableSetExtends.sol";
import "../libraries/ERC20Extends.sol";
import "../libraries/UniV3SwapExtends.sol";
import "../libraries/UniV3PMExtends.sol";

pragma abicoder v2;
/// @title Position Management
/// @notice Provide asset operation functions, allow authorized identities to perform asset operations, and achieve the purpose of increasing the net value of the fund
contract UniV3Liquidity is GovIdentity {

    using SafeMath for uint256;
    using Path for bytes;
    using EnumerableSetExtends for EnumerableSetExtends.UintSet;
    using UniV3SwapExtends for mapping(address => mapping(address => bytes));

    //Swap route
    mapping(address => mapping(address => bytes)) public swapRoute;
    //Position list
    mapping(bytes32 => uint256) public history;
    //position mapping owner
    mapping(uint256 => address) public positionOwners;
    //available token limit
    mapping(address => mapping(address => uint256)) public tokenLimit;
    //Working positions
    EnumerableSetExtends.UintSet internal works;

    //Swap
    event Swap(address sender, address fromToken, address toToken, uint256 amountIn, uint256 amountOut);
    //Create positoin
    event Mint(address sender, uint256 tokenId, uint128 liquidity);
    //Increase liquidity
    event IncreaseLiquidity(address sender, uint256 tokenId, uint128 liquidity);
    //Decrease liquidity
    event DecreaseLiquidity(address sender, uint256 tokenId, uint128 liquidity);
    //Collect asset
    event Collect(address sender, uint256 tokenId, uint256 amount0, uint256 amount1);

    //Only allow governance, strategy, ext authorize
    modifier onlyAssetsManager() {
        require(
            msg.sender == getGovernance()
            || isAdmin(msg.sender)
            || isStrategist(msg.sender)
            || extAuthorize(), "!AM");
        _;
    }

    //Only position owner
    modifier onlyPositionManager(uint256 tokenId) {
        require(
            msg.sender == getGovernance()
            || isAdmin(msg.sender)
            || positionOwners[tokenId] == msg.sender
            || extAuthorize(), "!PM");
        _;
    }



    /// @notice extend authorize
    function extAuthorize() internal virtual view returns (bool){
        return false;
    }


    /// @notice swap after handle
    function swapAfter(
        address,
        uint256) internal virtual {

    }

    /// @notice collect after handle
    function collectAfter(
        address,
        address,
        uint256,
        uint256) internal virtual {

    }

    /// @notice Check current position
    /// @dev Check the current UniV3 position by pool token ID.
    /// @param pool liquidity pool
    /// @param tickLower Tick lower bound
    /// @param tickUpper Tick upper bound
    /// @return atWork Position status
    /// @return has Check if the position ID exist
    /// @return tokenId Position ID
    function checkPos(
        address pool,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (bool atWork, bool has, uint256 tokenId){
        bytes32 pk = UniV3PMExtends.positionKey(pool, tickLower, tickUpper);
        tokenId = history[pk];
        atWork = works.contains(tokenId);
        has = tokenId > 0 ? true : false;
    }

    /// @notice Update strategist's available token limit
    /// @param strategist strategist's
    /// @param token token address
    /// @param amount limit amount
    function setTokenLimit(address strategist, address token, int256 amount) public onlyAdminOrGovernance {
        if (amount > 0) {
            tokenLimit[strategist][token] += uint256(amount);
        } else {
            tokenLimit[strategist][token] -= uint256(amount);
        }
    }

    /// @notice Authorize UniV3 contract to move vault asset
    /// @dev Only allow governance and admin identities to execute authorized functions to reduce miner fee consumption
    /// @param token Authorized target token
    function safeApproveAll(address token) public virtual onlyAdminOrGovernance {
        ERC20Extends.safeApprove(token, address(UniV3PMExtends.PM), type(uint256).max);
        ERC20Extends.safeApprove(token, address(UniV3SwapExtends.SRT), type(uint256).max);
    }

    /// @notice Multiple functions of the contract can be executed at the same time
    /// @dev Only the assets manager identities are allowed to execute multiple function calls,
    /// and the execution of multiple functions can ensure the consistency of the execution results
    /// @param data Encode data of multiple execution functions
    /// @return results Execution result
    function multicall(bytes[] calldata data) external onlyAssetsManager returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            if (!success) {
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
    }


    /// @notice Set asset swap route
    /// @dev Only the governance and admin identity is allowed to set the asset swap path, and the firstToken and lastToken contained in the path will be used as the underlying asset token address by default
    /// @param path Swap path byte code
    function settingSwapRoute(bytes memory path) external onlyAdminOrGovernance {
        require(path.valid(), 'path is not valid');
        address fromToken = path.getFirstAddress();
        address toToken = path.getLastAddress();
        swapRoute[fromToken][toToken] = path;
    }

    /// @notice Estimated to obtain the target token amount
    /// @dev Only allow the asset transaction path that has been set to be estimated
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountIn Source token amount
    /// @return amountOut Target token amount
    function estimateAmountOut(
        address from,
        address to,
        uint256 amountIn
    ) public view returns (uint256 amountOut){
        return swapRoute.estimateAmountOut(from, to, amountIn);
    }

    /// @notice Estimate the amount of source tokens that need to be provided
    /// @dev Only allow the governance identity to set the underlying asset token address
    /// @param from Source token address
    /// @param to Target token address
    /// @param amountOut Expect to get the target token amount
    /// @return amountIn Source token amount
    function estimateAmountIn(
        address from,
        address to,
        uint256 amountOut
    ) public view returns (uint256 amountIn){
        return swapRoute.estimateAmountIn(from, to, amountOut);
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Initiate a transaction with a known input amount and return the output amount
    /// @param tokenIn Token in address
    /// @param tokenOut Token out address
    /// @param amountIn Token in amount
    /// @param amountOutMinimum Expected to get minimum token out amount
    /// @return amountOut Token out amount
    function exactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public onlyAssetsManager returns (uint256 amountOut) {
        bool _isStrategist = isStrategist(msg.sender);
        if (_isStrategist) {
            require(tokenLimit[msg.sender][tokenIn] >= amountIn, '!check limit');
        }
        amountOut = swapRoute.exactInput(tokenIn, tokenOut, amountIn, address(this), amountOutMinimum);
        if (_isStrategist) {
            tokenLimit[msg.sender][tokenIn] -= amountIn;
            tokenLimit[msg.sender][tokenOut] += amountOut;
        }
        swapAfter(tokenOut, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @dev Initiate a transaction with a known output amount and return the input amount
    /// @param tokenIn Token in address
    /// @param tokenOut Token out address
    /// @param amountOut Token out amount
    /// @param amountInMaximum Expect to input the maximum amount of tokens
    /// @return amountIn Token in amount
    function exactOutput(
        address tokenIn,
        address tokenOut,
        uint256 amountOut,
        uint256 amountInMaximum
    ) public onlyAssetsManager returns (uint256 amountIn) {
        amountIn = swapRoute.exactOutput(tokenIn, tokenOut, address(this), amountOut, amountInMaximum);
        if (isStrategist(msg.sender)) {
            require(tokenLimit[msg.sender][tokenIn] >= amountIn, '!check limit');
            tokenLimit[msg.sender][tokenIn] -= amountIn;
            tokenLimit[msg.sender][tokenOut] += amountOut;
        }
        swapAfter(tokenOut, amountOut);
        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Create position
    /// @dev Repeated creation of the same position will cause an error, you need to change tickLower Or tickUpper
    /// @param token0 Liquidity pool token 0 contract address
    /// @param token1 Liquidity pool token 1 contract address
    /// @param fee Target liquidity pool rate
    /// @param tickLower Expect to place the lower price boundary of the target liquidity pool
    /// @param tickUpper Expect to place the upper price boundary of the target liquidity pool
    /// @param amount0Desired Desired token 0 amount
    /// @param amount1Desired Desired token 1 amount
    function mint(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) public onlyAssetsManager
    {
        bool _isStrategist = isStrategist(msg.sender);
        if (_isStrategist) {
            require(tokenLimit[msg.sender][token0] >= amount0Desired, '!check limit');
            require(tokenLimit[msg.sender][token1] >= amount1Desired, '!check limit');
        }
        (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
        ) = UniV3PMExtends.PM.mint(INonfungiblePositionManager.MintParams({
        token0 : token0,
        token1 : token1,
        fee : fee,
        tickLower : tickLower,
        tickUpper : tickUpper,
        amount0Desired : amount0Desired,
        amount1Desired : amount1Desired,
        amount0Min : 0,
        amount1Min : 0,
        recipient : address(this),
        deadline : block.timestamp
        }));
        if (_isStrategist) {
            tokenLimit[msg.sender][token0] -= amount0;
            tokenLimit[msg.sender][token1] -= amount1;
        }
        address pool = UniV3PMExtends.getPool(tokenId);
        bytes32 pk = UniV3PMExtends.positionKey(pool, tickLower, tickUpper);
        history[pk] = tokenId;
        positionOwners[tokenId] = msg.sender;
        works.add(tokenId);
        emit Mint(msg.sender, tokenId, liquidity);
    }

    /// @notice Increase liquidity
    /// @dev Use checkPos to check the position ID
    /// @param tokenId Position ID
    /// @param amount0 Desired Desired token 0 amount
    /// @param amount1 Desired Desired token 1 amount
    /// @param amount0Min Minimum token 0 amount
    /// @param amount1Min Minimum token 1 amount
    /// @return liquidity The amount of liquidity
    /// @return amount0 Actual token 0 amount being added
    /// @return amount1 Actual token 1 amount being added
    function increaseLiquidity(
        uint256 tokenId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    ) public onlyPositionManager(tokenId) returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ){
        (
        ,
        ,
        address token0,
        address token1,
        ,
        ,
        ,
        ,
        ,
        ,
        ,

        ) = UniV3PMExtends.PM.positions(tokenId);
        address po = positionOwners[tokenId];
        if (isStrategist(po)) {
            require(tokenLimit[po][token0] >= amount0Desired, '!check limit');
            require(tokenLimit[po][token1] >= amount1Desired, '!check limit');
        }
        (liquidity, amount0, amount1) = UniV3PMExtends.PM.increaseLiquidity(INonfungiblePositionManager.IncreaseLiquidityParams({
        tokenId : tokenId,
        amount0Desired : amount0Desired,
        amount1Desired : amount1Desired,
        amount0Min : amount0Min,
        amount1Min : amount1Min,
        deadline : block.timestamp
        }));
        if (isStrategist(po)) {
            tokenLimit[po][token0] -= amount0;
            tokenLimit[po][token1] -= amount1;
        }
        if (!works.contains(tokenId)) {
            works.add(tokenId);
        }
        emit IncreaseLiquidity(msg.sender, tokenId, liquidity);
    }

    /// @notice Decrease liquidity
    /// @dev Use checkPos to query the position ID
    /// @param tokenId Position ID
    /// @param liquidity Expected reduction amount of liquidity
    /// @param amount0Min Minimum amount of token 0 to be reduced
    /// @param amount1Min Minimum amount of token 1 to be reduced
    /// @return amount0 Actual amount of token 0 being reduced
    /// @return amount1 Actual amount of token 1 being reduced
    function decreaseLiquidity(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min
    ) public onlyPositionManager(tokenId) returns (uint256 amount0, uint256 amount1){
        (amount0, amount1) = UniV3PMExtends.PM.decreaseLiquidity(INonfungiblePositionManager.DecreaseLiquidityParams({
        tokenId : tokenId,
        liquidity : liquidity,
        amount0Min : amount0Min,
        amount1Min : amount1Min,
        deadline : block.timestamp
        }));
        emit DecreaseLiquidity(msg.sender, tokenId, liquidity);
    }

    /// @notice Collect position asset
    /// @dev Use checkPos to check the position ID
    /// @param tokenId Position ID
    /// @param amount0Max Maximum amount of token 0 to be collected
    /// @param amount1Max Maximum amount of token 1 to be collected
    /// @return amount0 Actual amount of token 0 being collected
    /// @return amount1 Actual amount of token 1 being collected
    function collect(
        uint256 tokenId,
        uint128 amount0Max,
        uint128 amount1Max
    ) public onlyPositionManager(tokenId) returns (uint256 amount0, uint256 amount1){
        (amount0, amount1) = UniV3PMExtends.PM.collect(INonfungiblePositionManager.CollectParams({
        tokenId : tokenId,
        recipient : address(this),
        amount0Max : amount0Max,
        amount1Max : amount1Max
        }));
        (
        ,
        ,
        address token0,
        address token1,
        ,
        ,
        ,
        uint128 liquidity,
        ,
        ,
        ,
        ) = UniV3PMExtends.PM.positions(tokenId);
        address po = positionOwners[tokenId];
        if (isStrategist(po)) {
            tokenLimit[po][token0] += amount0;
            tokenLimit[po][token1] += amount1;
        }
        if (liquidity == 0) {
            works.remove(tokenId);
        }
        collectAfter(token0, token1, amount0, amount1);
        emit Collect(msg.sender, tokenId, amount0, amount1);
    }

    /// @notice calc tokenId asset
    /// @dev This function calc tokenId asset
    /// @return tokenId asset
    function calcLiquidityAssets(uint256 tokenId, address toToken) internal view returns (uint256) {
        (
        ,
        ,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        ,
        ,
        ,
        ) = UniV3PMExtends.PM.positions(tokenId);
        (uint256 amount0, uint256 amount1) = UniV3PMExtends.getAmountsForLiquidity(
            token0, token1, fee, tickLower, tickUpper, liquidity);
        (uint256 fee0, uint256 fee1) = UniV3PMExtends.getFeesForLiquidity(tokenId);
        (amount0, amount1) = (amount0.add(fee0), amount1.add(fee1));
        uint256 total;
        if (token0 == toToken) {
            total = amount0;
        } else {
            uint256 _estimateAmountOut = swapRoute.estimateAmountOut(token0, toToken, amount0);
            total = _estimateAmountOut;
        }
        if (token1 == toToken) {
            total = total.add(amount1);
        } else {
            uint256 _estimateAmountOut = swapRoute.estimateAmountOut(token1, toToken, amount1);
            total = total.add(_estimateAmountOut);
        }
        return total;
    }


}