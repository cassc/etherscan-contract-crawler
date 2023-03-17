// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {SafeERC20, IERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {IUniswapRouter02} from "../interfaces/IUniswapRouter02.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";

contract AuctionTreasury is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    uint256 public constant RATIO_PRECISION = 1000;

    IERC20 public LVL;
    IERC20 public LGO;

    address public LVLAuctionFactory;
    address public LGOAuctionFactory;
    address public admin;

    address public cashTreasury;
    IERC20 public USDT;
    uint256 usdtToReserveRatio;
    IUniswapRouter02 public pancakeRouter;
    IUniswapV2Pair lvlUsdtPair;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _lvl, address _lgo) external initializer {
        __Ownable_init();
        require(_lvl != address(0), "Invalid address");
        require(_lgo != address(0), "Invalid address");
        LVL = IERC20(_lvl);
        LGO = IERC20(_lgo);
    }

    function reinitV2(address _cashTreasury, address _usdt, address _pcsRouter, address _lvlUsdtPair)
        external
        reinitializer(2)
    {
        require(_cashTreasury != address(0), "Invalid address");
        require(_usdt != address(0), "Invalid address");
        require(_pcsRouter != address(0), "Invalid address");
        require(_lvlUsdtPair != address(0), "Invalid address");
        cashTreasury = _cashTreasury;
        USDT = IERC20(_usdt);
        pancakeRouter = IUniswapRouter02(_pcsRouter);
        lvlUsdtPair = IUniswapV2Pair(_lvlUsdtPair);
    }

    function reinitV3() external reinitializer(3) {
        usdtToReserveRatio = 750;
    }

    function transferLVL(address _for, uint256 _amount) external {
        require(msg.sender == LVLAuctionFactory, "only LVLAuctionFactory");
        LVL.safeTransfer(_for, _amount);
        emit LVLGranted(_for, _amount);
    }

    function transferLGO(address _for, uint256 _amount) external {
        require(msg.sender == LGOAuctionFactory, "only LGOAuctionFactory");
        LGO.safeTransfer(_for, _amount);
        emit LGOGranted(_for, _amount);
    }

    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Invalid address");
        admin = _admin;
        emit AdminSet(_admin);
    }

    function setLVLAuctionFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "Invalid address");
        LVLAuctionFactory = _factory;
        emit LVLAuctionFactorySet(_factory);
    }

    function setLGOAuctionFactory(address _factory) external onlyOwner {
        require(_factory != address(0), "Invalid address");
        LGOAuctionFactory = _factory;
        emit LGOAuctionFactorySet(_factory);
    }

    function distribute() external {
        require(msg.sender == admin || msg.sender == owner(), "Only Owner or Admin can operate");
        uint256 _usdtBalance = USDT.balanceOf(address(this));
        uint256 _amountToTreasury = _usdtBalance * usdtToReserveRatio / RATIO_PRECISION;
        uint256 _amountToLP = _usdtBalance - _amountToTreasury;

        // 1. split to Treasury
        if (_amountToTreasury > 0) {
            require(cashTreasury != address(0), "Invalid address");
            USDT.safeTransfer(cashTreasury, _amountToTreasury);
        }

        // 2. convert to LP
        if (_amountToLP > 0) {
            uint256 _amountOfLvl = getLVLAddLiquidityAmount(_amountToLP);
            LVL.safeIncreaseAllowance(address(pancakeRouter), _amountOfLvl);
            USDT.safeIncreaseAllowance(address(pancakeRouter), _amountToLP);
            pancakeRouter.addLiquidity(
                address(LVL), address(USDT), _amountOfLvl, _amountToLP, 0, 0, cashTreasury, block.timestamp + 300
            );
        }
    }

    function recoverFund(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit FundRecovered(_token, _to, _amount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function getLVLAddLiquidityAmount(uint256 _usdtAmount) internal view returns (uint256) {
        address token0 = lvlUsdtPair.token0();
        (uint256 reserve0, uint256 reserve1,) = lvlUsdtPair.getReserves();

        if (address(USDT) == token0) {
            return _usdtAmount * reserve1 / reserve0;
        } else {
            return _usdtAmount * reserve0 / reserve1;
        }
    }

    /* ========== EVENTS ========== */

    event AdminSet(address _admin);
    event LVLGranted(address _for, uint256 _amount);
    event LGOGranted(address _for, uint256 _amount);
    event LVLAuctionFactorySet(address _factory);
    event LGOAuctionFactorySet(address _factory);
    event FundRecovered(address indexed _token, address _to, uint256 _amount);
    event FundWithdrawn(address indexed _token, address _to, uint256 _amount);
}