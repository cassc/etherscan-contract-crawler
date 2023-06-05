// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./interfaces/ICerosRouterLs.sol";

import "./interfaces/IVault.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IPolygonPool.sol";
import "./interfaces/ICertToken.sol";
import "./interfaces/IPriceGetter.sol";

contract CerosRouterLs is ICerosRouterLs, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    
    // --- Wrapper ---
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // --- Vars ---
    IVault public s_ceVault;
    ISwapRouter public s_dex;
    IPolygonPool public s_pool;
    ICertToken public s_aMATICc;
    IERC20Upgradeable public s_maticToken;
    address public s_strategy;
    IPriceGetter public s_priceGetter;

    uint24 public s_pairFee;

    mapping(address => uint256) public s_profits;

    // --- Mods ---
    modifier onlyOwnerOrStrategy() {

        require(msg.sender == owner() || msg.sender == s_strategy, "CerosRouter/not-owner-or-strategy");
        _;
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    // --- Constructor ---
    constructor() { _disableInitializers(); }

    // --- Init ---
    function initialize(address _aMATICc, address _maticToken, address _bondToken, address _ceVault, address _dex, uint24 _pairFee, address _pool, address _priceGetter) external initializer {

        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        s_aMATICc = ICertToken(_aMATICc);
        s_maticToken = IERC20Upgradeable(_maticToken);
        s_ceVault = IVault(_ceVault);
        s_dex = ISwapRouter(_dex);
        s_pairFee = _pairFee;
        s_pool = IPolygonPool(_pool);
        s_priceGetter = IPriceGetter(_priceGetter);

        IERC20Upgradeable(s_maticToken).approve(_dex, type(uint256).max);
        IERC20Upgradeable(s_maticToken).approve(_pool, type(uint256).max);
        IERC20(s_aMATICc).approve(_dex, type(uint256).max);
        IERC20(s_aMATICc).approve(_bondToken, type(uint256).max);
        IERC20(s_aMATICc).approve(_pool, type(uint256).max);
        IERC20(s_aMATICc).approve(_ceVault, type(uint256).max);
    }

    // --- Users ---
    function deposit(uint256 _amount) external override nonReentrant whenNotPaused returns (uint256 value) {   

        {
            require(_amount > 0, "CerosRouter/invalid-amount");
            uint256 balanceBefore = s_maticToken.balanceOf(address(this));
            s_maticToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 balanceAfter = s_maticToken.balanceOf(address(this));
            require(balanceAfter >= balanceBefore + _amount, "CerosRouter/invalid-transfer");
        }

        // Minimum acceptable amount
        uint256 ratio = s_aMATICc.ratio();
        uint256 minAmount = safeCeilMultiplyAndDivide(_amount, ratio, 1e18);

        // From PolygonPool
        uint256 poolAmount = _amount >= s_pool.getMinimumStake() ? minAmount : 0;

        // From Dex
        uint256 dexAmount = getAmountOut(address(s_maticToken), address(s_aMATICc), _amount);

        // Compare both
        uint256 realAmount;
        if (poolAmount >= dexAmount) {
            realAmount = poolAmount;
            s_pool.stakeAndClaimCerts(_amount);
        } else {
            realAmount = swapV3(address(s_maticToken), address(s_aMATICc), _amount, minAmount, address(this));
        }

        require(realAmount >= minAmount, "CerosRouter/price-low");
        require(s_aMATICc.balanceOf(address(this)) >= realAmount, "CerosRouter/wrong-certToken-amount-in-CerosRouter");
        
        // Profits
        uint256 profit = realAmount - minAmount;
        s_profits[msg.sender] += profit;
        value = s_ceVault.depositFor(msg.sender, realAmount - profit);
        emit Deposit(msg.sender, address(s_maticToken), realAmount - profit, profit);
        return value;
    }
    function swapV3(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOutMin, address recipient) private returns (uint256 amountOut) {

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            _tokenIn,               // tokenIn
            _tokenOut,              // tokenOut
            s_pairFee,              // fee
            recipient,              // recipient
            block.timestamp + 300,  // deadline
            _amountIn,              // amountIn
            _amountOutMin,          // amountOutMinimum
            0                       // sqrtPriceLimitX96
        );
        amountOut = s_dex.exactInputSingle(params);
    }

    function withdrawAMATICc(address _recipient, uint256 _amount) external override nonReentrant whenNotPaused returns (uint256 realAmount) {

        realAmount = s_ceVault.withdrawFor(msg.sender, _recipient, _amount);

        emit Withdrawal(msg.sender, _recipient, address(s_aMATICc), realAmount);
        return realAmount;
    }

    function claim(address _recipient) external override nonReentrant whenNotPaused returns (uint256 yields) {

        yields = s_ceVault.claimYieldsFor(msg.sender, _recipient);  // aMATICc

        emit Claim(_recipient, address(s_aMATICc), yields);
        return yields;
    }
    function claimProfit(address _recipient) external nonReentrant {

        uint256 profit = s_profits[msg.sender];
        require(profit > 0, "CerosRouter/no-profits");
        require(s_aMATICc.balanceOf(address(this)) >= profit, "CerosRouter/insufficient-amount");

        s_aMATICc.transfer(_recipient, profit);  // aMATICc
        s_profits[msg.sender] -= profit;

        emit Claim(_recipient, address(s_aMATICc), profit);
    }

    // --- Strategy ---
    function withdrawFor(address _recipient, uint256 _amount) external override nonReentrant whenNotPaused onlyOwnerOrStrategy returns (uint256 realAmount) {

        realAmount = s_ceVault.withdrawFor(msg.sender, address(this), _amount);
        bytes memory bytesData;
        s_pool.unstakeCertsFor{value: 0}(_recipient, realAmount, 0, 0, bytesData); // aMATICc -> MATIC

        emit Withdrawal(msg.sender, _recipient, address(s_maticToken), realAmount);
        return realAmount;
    }

    // --- Internal ---
    function safeCeilMultiplyAndDivide(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {

        // Ceil (a * b / c)
        uint256 remainder = a.mod(c);
        uint256 result = a.div(c);
        bool safe;
        (safe, result) = result.tryMul(b);
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        (safe, result) = result.tryAdd(remainder.mul(b).add(c.sub(1)).div(c));
        if (!safe) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return result;
    }

    // --- Admin ---
    function pause() external onlyOwner {

        _pause();
    }
    function unpause() external onlyOwner {

        _unpause();
    }
    function changePriceGetter(address _priceGetter) external onlyOwner {

        require(_priceGetter != address(0));
        s_priceGetter = IPriceGetter(_priceGetter);
    }
    function changePairFee(uint24 _fee) external onlyOwner {

        s_pairFee = _fee;
        emit ChangePairFee(_fee);
    }
    function changeStrategy(address _strategy) external onlyOwner {

        s_strategy = _strategy;
        emit ChangeStrategy(_strategy);
    }
    function changePool(address _pool) external onlyOwner {

        s_aMATICc.approve(address(s_pool), 0);
        s_pool = IPolygonPool(_pool);
        s_aMATICc.approve(address(_pool), type(uint256).max);
        emit ChangePool(_pool);
    }
    function changeDex(address _dex) external onlyOwner {

        IERC20Upgradeable(s_maticToken).approve(address(s_dex), 0);
        s_aMATICc.approve(address(s_dex), 0);
        s_dex = ISwapRouter(_dex);
        IERC20Upgradeable(s_maticToken).approve(address(_dex), type(uint256).max);
        s_aMATICc.approve(address(_dex), type(uint256).max);
        emit ChangeDex(_dex);
    }
    function changeCeVault(address _ceVault) external onlyOwner {

        s_aMATICc.approve(address(s_ceVault), 0);
        s_ceVault = IVault(_ceVault);
        s_aMATICc.approve(address(_ceVault), type(uint256).max);
        emit ChangeCeVault(_ceVault);
    }

    // --- Views ---
    function getAmountOut(address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256 amountOut) {

        if(address(s_priceGetter) == address(0)) return 0;
        else {
            amountOut = IPriceGetter(s_priceGetter).getPrice(
                _tokenIn,
                _tokenOut,
                _amountIn,
                0,
                s_pairFee
            );
        }
    }
    function getPendingWithdrawalOf(address _account) external view returns (uint256) {

        return s_pool.pendingUnstakesOf(_account);
    }
    function getYieldFor(address _account) external view returns(uint256) {

        return s_ceVault.getYieldFor(_account);
    } 
}