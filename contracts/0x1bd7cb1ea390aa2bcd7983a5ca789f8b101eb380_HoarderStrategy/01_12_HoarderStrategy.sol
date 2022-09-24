// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IHoarderStrategy.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IHoarderRewards.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IClearpoolPool.sol";
import "./interfaces/IUSDT.sol";
import "./interfaces/IUSDH.sol";
import "./interfaces/IRouter.sol";
import "v3-periphery/interfaces/external/IWETH9.sol";

contract HoarderStrategy is IHoarderStrategy, ReentrancyGuard {
    uint256 private constant max = type(uint256).max;

    address private constant _tokenDeposit = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;// USDC
    address private constant _token = 0xCb288b6d30738db7E3998159d192615769794B5b;// cpWIN-USDC
    uint24 private constant _feeTier = 100;
    string private constant _name = "Clearpool cpWIN-USDC";

    address public immutable hoarder;
    IHoarderRewards public immutable hoarderRewards;

    IUSDT public constant TokenDeposit = IUSDT(_tokenDeposit);
    IUSDT public constant Token = IUSDT(_token);

    address private constant _tokenRewards = 0x66761Fa41377003622aEE3c7675Fc7b5c1C2FaC5;
    IUSDT private constant TokenRewards = IUSDT(_tokenRewards);

    ISwapRouter private constant router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    IRouter private constant routerV2 = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IClearpoolPool private clearpoolPool = IClearpoolPool(_token);

    IUSDH public immutable usdh;
    IUSDT public immutable Usdh;
    address private constant hrd = 0x461B71cff4d4334BbA09489acE4b5Dc1A1813445;

    address public collateral = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;// MIM
    IUSDT public Collateral = IUSDT(collateral);

    uint256 public deposits;

    address private constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IWETH9 private constant Weth = IWETH9(weth);

    address public strategist;

    modifier onlyHoarder {
        require(msg.sender == hoarder);
        _;
    }

    modifier onlyStrategist {
        require(msg.sender == strategist);
        _;
    }

    constructor (address _hoarder, address _hoarderRewards, address _usdh, address _strategist) {
        hoarder = _hoarder;
        hoarderRewards = IHoarderRewards(_hoarderRewards);
        usdh = IUSDH(_usdh);
        Usdh = IUSDT(_usdh);
        strategist = _strategist;
    }

    function _swap(uint256 _amountIn, address _tokenIn, address _tokenOut, uint24 _fee) private {
        try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: _fee, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
            try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: 100, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: 500, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                    try router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: 3000, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0})) {} catch {
                        router.exactInputSingle(ISwapRouter.ExactInputSingleParams({tokenIn: _tokenIn, tokenOut: _tokenOut, fee: 10000, recipient: address(this), amountIn: _amountIn, amountOutMinimum: 0, sqrtPriceLimitX96: 0}));
                    }
                }
            }
        }
    }

    function _pool(uint256 _amount) private {
        deposits = deposits + _amount;
        clearpoolPool.provide(_amount);
    }

    function _supplyDeficitFund() private {
        uint256 yield = Collateral.balanceOf(address(this));
        usdh.mint(collateral, yield * 7000 / 10000, false);
        try Usdh.transfer(0x000000000000000000000000000000000000dEaD, yield * 500 / 10000) {} catch { Usdh.transfer(0x000000000000000000000000000000000000dEaD, Usdh.balanceOf(address(this)) * 500 / 10000); }
    }

    function _buyback() private {
        _swap(Collateral.balanceOf(address(this)), collateral, weth, 10000);
        Weth.withdraw(Weth.balanceOf(address(this)));
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = 0x461B71cff4d4334BbA09489acE4b5Dc1A1813445;
        routerV2.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}(0, path, 0x000000000000000000000000000000000000dEaD, block.timestamp);
    }

    function _depositRewards() private {
        hoarderRewards.deposit(Usdh.balanceOf(address(this)));
    }

    function _unpool() private {
        clearpoolPool.redeem(max);
        uint256 balance = TokenDeposit.balanceOf(address(this));
        if ((balance > deposits) && (deposits > 0)) {
            _swap((balance - deposits), _tokenDeposit, collateral, 500);
            _supplyDeficitFund();
            _buyback();
            _depositRewards();
            deposits = 0;
        }
        uint256 rewards = TokenRewards.balanceOf(address(this));
        if (rewards > 0) {
            balance = TokenDeposit.balanceOf(address(this));
            _swap(rewards, _tokenRewards, _tokenDeposit, 10000);
            uint256 toSwap = TokenDeposit.balanceOf(address(this)) - balance;
            if (toSwap > 0) {
                _swap(toSwap, _tokenDeposit, collateral, 500);
                _supplyDeficitFund();
                _buyback();
                _depositRewards();
            }
        }
    }

    function _deposit(uint256 amount) private {
        _pool(amount);
    }

    function _withdraw(uint256 amount) private returns (uint256) {
        _unpool();
        if ((TokenDeposit.balanceOf(address(this)) > 0) && (amount > 0)) _swap(amount > TokenDeposit.balanceOf(address(this)) ? TokenDeposit.balanceOf(address(this)) : amount, _tokenDeposit, collateral, 500);
        uint256 withdrawn;
        if (Collateral.balanceOf(address(this)) > 0) {
            uint256 balance = Usdh.balanceOf(address(this));
            usdh.mint(collateral, Collateral.balanceOf(address(this)), false);
            withdrawn = Usdh.balanceOf(address(this)) - balance;
            Usdh.transfer(msg.sender, withdrawn);
        }
        _pool(TokenDeposit.balanceOf(address(this)));
        return withdrawn;
    }

    function init(address tokenDepositOld, uint256 amount) external override nonReentrant onlyHoarder {
        TokenDeposit.approve(address(router), max);
        Token.approve(address(router), max);
        TokenDeposit.approve(_token, max);
        Usdh.approve(address(hoarderRewards), max);
        Collateral.approve(address(usdh), max);
        Collateral.approve(address(router), max);
        TokenRewards.approve(address(router), max);
        if (amount > 0) {
            IUSDT TokenDepositOld = IUSDT(tokenDepositOld);
            require(TokenDepositOld.balanceOf(msg.sender) >= amount);
            require(TokenDepositOld.allowance(msg.sender, address(this)) >= amount);
            uint256 snapshot = TokenDepositOld.balanceOf(address(this));
            TokenDepositOld.transferFrom(msg.sender, address(this), amount);
            require(TokenDepositOld.balanceOf(address(this)) == snapshot + amount);
            if (tokenDepositOld != tokenDeposit()) {
                TokenDepositOld.approve(address(router), max);
                _swap(TokenDepositOld.balanceOf(address(this)), tokenDepositOld, tokenDeposit(), 100);
            }
            _deposit(TokenDeposit.balanceOf(address(this)));
        }
    }

    function deposit(uint256 amount) external override nonReentrant onlyHoarder {
        require(TokenDeposit.balanceOf(msg.sender) >= amount);
        require(TokenDeposit.allowance(msg.sender, address(this)) >= amount);
        uint256 snapshot = TokenDeposit.balanceOf(address(this));
        TokenDeposit.transferFrom(msg.sender, address(this), amount);
        require(TokenDeposit.balanceOf(address(this)) == snapshot + amount);
        _deposit(amount);
    }

    function withdraw(uint256 amount) external override nonReentrant onlyHoarder returns (uint256) {
        return _withdraw(amount / (10 ** 12));
    }

    function end() external override nonReentrant onlyHoarder {
        _unpool();
        TokenDeposit.transfer(hoarder, TokenDeposit.balanceOf(address(this)));
    }

    function setStrategist(address _strategist) external nonReentrant onlyStrategist {
        strategist = _strategist;
    }

    function getStrategist() external view override returns (address) {
        return strategist;
    }

    function tokenDeposit() public pure override returns (address) {
        return _tokenDeposit;
    }

    function token() external pure override returns (address) {
        return _token;
    }

    function feeTier() external pure override returns (uint24) {
        return _feeTier;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    receive() external payable {}
}