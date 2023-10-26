// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "./interfaces/IPoolFactory.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IPoolCallback.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IDebt.sol";
import "./interfaces/IWETH.sol";

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-periphery/contracts/base/Multicall.sol";

contract Router is IRouter, IPoolCallback, Multicall {
    fallback() external {}
    receive() payable external {}

    using SafeERC20 for IERC20;

    address public _factory;
    address public _wETH;
    address private _uniV3Factory;
    address private _uniV2Factory;
    address private _sushiFactory;
    uint32 private _tokenId = 0;

    struct tokenDate {
        address user;
        address poolAddress;
        uint32 positionId;
    }

    mapping(uint32 => tokenDate) public _tokenData;

    constructor(address factory, address uniV3Factory, address uniV2Factory, address sushiFactory, address wETH) {
        _factory = factory;
        _uniV3Factory = uniV3Factory;
        _uniV2Factory = uniV2Factory;
        _sushiFactory = sushiFactory;
        _wETH = wETH;
    }

    function poolV2Callback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external override payable {
        IPoolFactory qilin = IPoolFactory(_factory);
        require(
            qilin.pools(poolToken, oraclePool, reverse) == msg.sender,
            "poolV2Callback caller is not the pool contract"
        );

        if (poolToken == _wETH && address(this).balance >= amount) {
            IWETH wETH = IWETH(_wETH);
            wETH.deposit{value: amount}();
            wETH.transfer(msg.sender, amount);
        } else {
            IERC20(poolToken).safeTransferFrom(payer, msg.sender, amount);
        }
    }

    function poolV2RemoveCallback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external override {
        IPoolFactory qilin = IPoolFactory(_factory);
        require(
            qilin.pools(poolToken, oraclePool, reverse) == msg.sender,
            "poolV2Callback caller is not the pool contract"
        );

        IERC20(msg.sender).safeTransferFrom(payer, msg.sender, amount);
    }

    function poolV2BondsCallback(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external override {
        address pool = IPoolFactory(_factory).pools(poolToken, oraclePool, reverse);
        require(
             pool == msg.sender,
            "poolV2BondsCallback caller is not the pool contract"
        );

        address debt = IPool(pool).debtToken();

        IERC20(debt).safeTransferFrom(payer, debt, amount);
    }

    function poolV2BondsCallbackFromDebt(
        uint256 amount,
        address poolToken,
        address oraclePool,
        address payer,
        bool reverse
    ) external override {
        address pool = IPoolFactory(_factory).pools(poolToken, oraclePool, reverse);
        address debt = IPool(pool).debtToken();
        require(
            debt == msg.sender,
            "poolV2BondsCallbackFromDebt caller is not the debt contract"
        );

        IERC20(debt).safeTransferFrom(payer, debt, amount);
    }

    function getPoolFromUni(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) public view returns (address) {
        address oraclePool;

        if (fee == 0) {
            oraclePool = IUniswapV2Factory(_uniV2Factory).getPair(tradeToken, poolToken);
        } else {
            oraclePool = IUniswapV3Factory(_uniV3Factory).getPool(tradeToken, poolToken, fee);
        }

        return IPoolFactory(_factory).pools(poolToken, oraclePool, reverse);
    }

    function getPoolFromSushi(
        address tradeToken,
        address poolToken,
        bool reverse
    ) public view returns (address) {
        address oraclePool = IUniswapV2Factory(_sushiFactory).getPair(tradeToken, poolToken);
        return IPoolFactory(_factory).pools(poolToken, oraclePool, reverse);
    }

    function createPoolFromUni(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) external override {
        IPoolFactory(_factory).createPoolFromUni(tradeToken, poolToken, fee, reverse);
    }

    function createPoolFromSushi(
        address tradeToken,
        address poolToken,
        bool reverse
    ) external override {
        IPoolFactory(_factory).createPoolFromSushi(tradeToken, poolToken, reverse);
    }

    function getLsBalance(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        address user
    ) external override view returns (uint256) {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        return IERC20(pool).balanceOf(user);
    }

    function getLsBalance2(
        address tradeToken,
        address poolToken,
        bool reverse,
        address user
    ) external override view returns (uint256) {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        return IERC20(pool).balanceOf(user);
    }

    function getLsPrice(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse
    ) external override view returns (uint256) {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        return IPool(pool).lsTokenPrice();
    }

    function getLsPrice2(
        address tradeToken,
        address poolToken,
        bool reverse
    ) external override view returns (uint256) {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        return IPool(pool).lsTokenPrice();
    }

    function addLiquidity(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 amount
    ) external override payable {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        IPool(pool).addLiquidity(msg.sender, amount);
    }

    function addLiquidity2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 amount
    ) external override payable {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        IPool(pool).addLiquidity(msg.sender, amount);
    }

    function removeLiquidity(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 lsAmount,
        uint256 bondsAmount,
        address receipt
    ) external override {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        IPool(pool).removeLiquidity(msg.sender, lsAmount, bondsAmount, receipt);
    }

    function removeLiquidity2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 lsAmount,
        uint256 bondsAmount,
        address receipt
    ) external override {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        IPool(pool).removeLiquidity(msg.sender, lsAmount, bondsAmount, receipt);
    }

    function openPosition(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external override payable {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        _tokenId++;
        uint32 positionId = IPool(pool).openPosition(
            msg.sender,
            direction,
            leverage,
            position
        );
        tokenDate memory tempTokenDate = tokenDate(
            msg.sender,
            pool,
            positionId
        );
        _tokenData[_tokenId] = tempTokenDate;
        emit TokenCreate(_tokenId, address(pool), msg.sender, positionId);
    }

    function openPosition2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint8 direction,
        uint16 leverage,
        uint256 position
    ) external override payable {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        _tokenId++;
        uint32 positionId = IPool(pool).openPosition(
            msg.sender,
            direction,
            leverage,
            position
        );
        tokenDate memory tempTokenDate = tokenDate(
            msg.sender,
            pool,
            positionId
        );
        _tokenData[_tokenId] = tempTokenDate;
        emit TokenCreate(_tokenId, address(pool), msg.sender, positionId);
    }

    function addMargin(uint32 tokenId, uint256 margin) external override payable {
        tokenDate memory tempTokenDate = _tokenData[tokenId];
        require(
            tempTokenDate.user == msg.sender,
            "token owner not match msg.sender"
        );
        IPool(tempTokenDate.poolAddress).addMargin(
            msg.sender,
            tempTokenDate.positionId,
            margin
        );
    }

    function closePosition(uint32 tokenId, address receipt) external override {
        tokenDate memory tempTokenDate = _tokenData[tokenId];
        require(
            tempTokenDate.user == msg.sender,
            "token owner not match msg.sender"
        );
        IPool(tempTokenDate.poolAddress).closePosition(
            receipt,
            tempTokenDate.positionId
        );
    }

    function liquidate(uint32 tokenId, address receipt) external override {
        tokenDate memory tempTokenDate = _tokenData[tokenId];
        require(tempTokenDate.user != address(0), "tokenId does not exist");
        IPool(tempTokenDate.poolAddress).liquidate(
            msg.sender,
            tempTokenDate.positionId,
            receipt
        );
    }

    function liquidateByPool(address poolAddress, uint32 positionId, address receipt) external override {
        IPool(poolAddress).liquidate(msg.sender, positionId, receipt);
    }

    function withdrawERC20(address poolToken) external override {
        IERC20 erc20 = IERC20(poolToken);
        uint256 balance = erc20.balanceOf(address(this));
        require(balance > 0, "balance of router must > 0");
        erc20.safeTransfer(msg.sender, balance);
    }

    function withdrawETH() external override {
        uint256 balance = IERC20(_wETH).balanceOf(address(this));
        require(balance > 0, "balance of router must > 0");
        IWETH(_wETH).withdraw(balance);
        (bool success, ) = msg.sender.call{value: balance}(new bytes(0));
        require(success, "ETH transfer failed");
    }

    function repayLoan(
        address tradeToken,
        address poolToken,
        uint24 fee,
        bool reverse,
        uint256 amount,
        address receipt
    ) external override payable {
        address pool = getPoolFromUni(tradeToken, poolToken, fee, reverse);
        require(pool != address(0), "non-exist pool");
        address debtToken = IPool(pool).debtToken();
        IDebt(debtToken).repayLoan(msg.sender, receipt, amount);
    }

    function repayLoan2(
        address tradeToken,
        address poolToken,
        bool reverse,
        uint256 amount,
        address receipt
    ) external override payable {
        address pool = getPoolFromSushi(tradeToken, poolToken, reverse);
        require(pool != address(0), "non-exist pool");
        address debtToken = IPool(pool).debtToken();
        IDebt(debtToken).repayLoan(msg.sender, receipt, amount);
    }

    function exit(uint32 tokenId, address receipt) external override {
        tokenDate memory tempTokenDate = _tokenData[tokenId];
        require(
            tempTokenDate.user == msg.sender,
            "token owner not match msg.sender"
        );
        IPool(tempTokenDate.poolAddress).exit(
            receipt,
            tempTokenDate.positionId
        );
    }
}