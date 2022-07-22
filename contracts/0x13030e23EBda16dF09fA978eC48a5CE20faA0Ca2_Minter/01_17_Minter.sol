// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {ExtendSafeERC20} from "./ExtendSafeERC20.sol";
import {IController} from "./interfaces/IController.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {ILock} from "./interfaces/ILock.sol";
import {Ownable} from "./Ownable.sol";

contract Minter is Ownable, ReentrancyGuard {
    using ExtendSafeERC20 for IERC20;
    using SafeERC20 for IERC20;
    

    address public controllerAddress;
    address public lockAddress;

    // mapping token address to target priceAPIConsumer
    mapping(address => uint256) public targetPrices;

    mapping(bytes =>  uint256) public borrowBalances;          // id -> uAsset ballance
    mapping(bytes =>  uint256) public collateralBalances;      // id -> collateral ballance
    
    mapping(bytes => address) public accounts;                  // id -> account
    mapping(bytes => uint256) public userBalances;              // id -> user balance locked
    mapping(bytes => uint256) public updatedLockTime;           // id -> updated time
    mapping(bytes => uint8) public typeBorrow;                  // id -> 1: borrow, 2: short
    mapping(bytes => uint256) public totalClaimedById;          // id -> total amount claimed
    mapping(bytes => address) public uAssetAddressById;         // id -> uAssetAddress

    event BorrowAsset(
        address indexed userAddress,
        bytes id,
        uint256 uAssetAmount,
        uint256 collateralAmount,
        uint256 timestamp
    );

    event Close(
        address indexed userAddress,
        bytes id,
        uint8 typeId,
        uint256 uAssetAmount,
        uint256 collateralAmount,
        uint256 timestamp
    );

    event Short(
        address indexed userAddress,
        bytes id,
        uint256 uAssetAmount,
        uint256 collateralAmount,
        uint256 timestamp
    );

    event EditShort(
        address indexed userAddress,
        bytes id,
        uint8 isLocked,
        uint256 uAssetAmount,
        uint256 collateralAmount,
        uint256 timestamp
    );

    event Liquidation (
        address indexed buyer,
        address indexed account,
        bytes id,
        uint256 uAssetAmount,
        uint256 collateralAmount,
        uint256 timestamp,
        uint256 discountRate
    );

    event ClaimToken(
        address indexed claimer,
        bytes id,
        uint256 amount, 
        uint256 timestamp
    );

    event ClaimAll(
        address indexed claimer,
        bytes[] ids
    );

    constructor() {
    }

    modifier onlyAdmin() {
        require(IController(controllerAddress).admins(msg.sender) || msg.sender == owner(), "Only admin");
        _;
    }

    function setControllerAddress(address _controllerAddress) external onlyOwner {
        controllerAddress = _controllerAddress;
    }

    function addMoreCollateralAmount(address uAssetAddress, uint256 collateralAmount, bytes memory id) external onlyAdmin {
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        IERC20(collateralAddress).safeTransferFrom(msg.sender, address(this), collateralAmount);
        collateralBalances[id] += collateralAmount;
    }
    
    function lock(bytes memory id, uint256 tokenAmount) internal {
        userBalances[id] += tokenAmount;
        updatedLockTime[id] = block.timestamp;
    } 
    
    function isClaimable(bytes memory id) external view returns (bool){
        uint256 lockTime = IController(controllerAddress).lockTime();
        if(updatedLockTime[id] == 0) return false;
        return (block.timestamp - updatedLockTime[id] > lockTime);
    }

    function claimById(bytes memory id) public nonReentrant {
        require(msg.sender == accounts[id], "Cannot call claim the same id with different account");
        uint256 lockTime = IController(controllerAddress).lockTime();
        require((block.timestamp - updatedLockTime[id]) > lockTime, "Still locking");
        require(userBalances[id] > 0, "Nothing to be claimed");
        uint256 tokenAmount = userBalances[id];
        address uAssetAddress = uAssetAddressById[id];
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        IERC20(collateralAddress).safeTransfer(msg.sender, tokenAmount);
        totalClaimedById[id] += tokenAmount;
        delete userBalances[id];
        delete updatedLockTime[id];
        emit ClaimToken(msg.sender, id, tokenAmount, block.timestamp);
    }
    
    function claimAll(bytes[] memory ids) external {
        uint256 lockTime = IController(controllerAddress).lockTime();
        for(uint256 i = 0; i < ids.length; i++) {
            if(block.timestamp - updatedLockTime[ids[i]] > lockTime && userBalances[ids[i]] > 0) {
                claimById(ids[i]);
            }
        }
        emit ClaimAll(msg.sender, ids);
    }

    function borrow(address uAssetAddress, uint256 uAssetAmount, uint256 collateralAmount, bytes memory id) external nonReentrant {
        if(accounts[id] == address(0)) accounts[id] = msg.sender;
        if(typeBorrow[id] == 0) typeBorrow[id] = 1;
        {
            require(msg.sender == accounts[id], "Cannot call borrow the same id with different account");
            require(collateralBalances[id] == 0, "Cannot call borrow with existed id");
            require(typeBorrow[id] == 1, "Cannot call borrow with different type id");
        }
        {
            uAssetAddressById[id] = uAssetAddress;
        }
        uint256 ttl = IController(controllerAddress).ttl();
        uint16 minCollateralRatio = IController(controllerAddress).minCollateralRatio();
        // uint16 maxCollateralRatio = IController(controllerAddress).maxCollateralRatio();
        uint16 calculationDecimal = IController(controllerAddress).calculationDecimal();

        address oracleAddress = IController(controllerAddress).oracles(uAssetAddress);
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);

        (uint256 targetPrice, uint256 updatedTime) = IOracle(oracleAddress).getTargetValue();
        require(block.timestamp - updatedTime <= ttl, "Target price is not updated");
        
        uint256 realCollateralAmount = (targetPrice * uAssetAmount) / (10 ** ERC20(uAssetAddress).decimals());
        require(realCollateralAmount * minCollateralRatio <= collateralAmount * (10**calculationDecimal), "less than min collateral ratio");
        // require(realCollateralAmount * maxCollateralRatio >= collateralAmount * (10**calculationDecimal), "greater than max collateral ratio");
        IERC20(collateralAddress).safeTransferFrom(msg.sender, address(this), collateralAmount);
        IERC20(uAssetAddress).safeMint(msg.sender, uAssetAmount);
        borrowBalances[id] = uAssetAmount;
        collateralBalances[id] = collateralAmount;
        emit BorrowAsset(msg.sender, id, uAssetAmount, collateralAmount, block.timestamp);
    }

    function editBorrow(address uAssetAddress, uint256 uAssetAmount, uint256 collateralAmount, bytes memory id) public nonReentrant {
        require(msg.sender == accounts[id], "Cannot call edit borrow the same id with different account");
        require(collateralBalances[id] > 0, "Cannot call edit borrow with unexisted id");
        require(typeBorrow[id] == 1, "Cannot call edit borrow with different type id");
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        // require(collateralAddress != address(0), "Collateral address is 0");
        address oracleAddress = IController(controllerAddress).oracles(uAssetAddress);
        // require(oracleAddress != address(0), "Oracle address is 0");
        (uint256 targetPrice, uint256 updatedTime) = IOracle(oracleAddress).getTargetValue();
        
        {
            uint256 ttl = IController(controllerAddress).ttl();
            
            
            if(block.timestamp - updatedTime > ttl) {
                require(uAssetAmount == borrowBalances[id], "Outside of market hour");
            } else {
                if(uAssetAmount < borrowBalances[id]) {
                    uint256 diff = borrowBalances[id] - uAssetAmount;
                    IERC20(uAssetAddress).safeTransferFrom(msg.sender, address(this), diff);
                    IERC20(uAssetAddress).safeBurn(diff);
                } else if (uAssetAmount > borrowBalances[id]) {
                    uint256 diff = uAssetAmount - borrowBalances[id];
                    IERC20(uAssetAddress).safeMint(msg.sender, diff);
                }
            }
        }
        {
            uint16 minCollateralRatio = IController(controllerAddress).minCollateralRatio();
            // uint16 maxCollateralRatio = IController(controllerAddress).maxCollateralRatio();
            uint16 calculationDecimal = IController(controllerAddress).calculationDecimal();
            
            uint256 realCollateralAmount = (targetPrice * uAssetAmount) / (10 ** ERC20(uAssetAddress).decimals());
            require(realCollateralAmount * minCollateralRatio <= collateralAmount * (10**calculationDecimal), "less than min collateral ratio");
            // require(realCollateralAmount * maxCollateralRatio >= collateralAmount * (10**calculationDecimal), "greater than max collateral ratio");
        }
        
        if(collateralAmount < collateralBalances[id]) {
            uint256 diff = collateralBalances[id] - collateralAmount;
            IERC20(collateralAddress).safeTransfer(msg.sender, diff);
        } else if(collateralAmount > collateralBalances[id]){
            uint256 diff = collateralAmount - collateralBalances[id];
            IERC20(collateralAddress).safeTransferFrom(msg.sender, address(this), diff);
        }
        
        borrowBalances[id] = uAssetAmount;
        collateralBalances[id] = collateralAmount;
        emit BorrowAsset(msg.sender, id, uAssetAmount, collateralAmount, block.timestamp);
    }

    function close(address uAssetAddress, bytes memory id) external nonReentrant {
        require(msg.sender == accounts[id], "Cannot call close the same id with different account");
        require(collateralBalances[id] > 0, "Cannot call close with unexisted id");
        uint256 uAssetAmount = borrowBalances[id];
        uint256 collateralAmount = collateralBalances[id];
        if (uAssetAmount > 0) {
            IERC20(uAssetAddress).safeTransferFrom(msg.sender, address(this), uAssetAmount);
            IERC20(uAssetAddress).safeBurn(uAssetAmount);
        }
        
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        require(collateralAddress != address(0), "Collateral address is 0");
        address oracleAddress = IController(controllerAddress).oracles(uAssetAddress);
        (uint256 targetPrice, ) = IOracle(oracleAddress).getTargetValue();
        uint256 fee = targetPrice * uAssetAmount * 15 / (10 ** ERC20(uAssetAddress).decimals() * 1000);
        if(fee < collateralBalances[id]) {
            collateralAmount -= fee;
            IERC20(collateralAddress).safeTransfer(msg.sender, collateralAmount);
            IERC20(collateralAddress).safeTransfer(owner(), fee);
        }
        
        borrowBalances[id] = 0;
        collateralBalances[id] = 0;
        
        emit Close(msg.sender, id, typeBorrow[id], uAssetAmount, collateralAmount, block.timestamp);
    }

    function short(address uAssetAddress, uint256 uAssetAmount, uint256 collateralAmount,uint256 deadline, uint16 slippage, bytes memory id) external nonReentrant {
        if(accounts[id] == address(0)) accounts[id] = msg.sender;
        if(typeBorrow[id] == 0) typeBorrow[id] = 2;
        {
            require(msg.sender == accounts[id], "Cannot call short the same id with different account"); 
            require(collateralBalances[id] == 0, "Cannot call short with existed id");
            require(typeBorrow[id] == 2, "Cannot call short with different type id");
        }
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        {
            uAssetAddressById[id] = uAssetAddress;
        }
        {
            uint256 ttl = IController(controllerAddress).ttl();
            address oracleAddress = IController(controllerAddress).oracles(uAssetAddress);
            (uint256 targetPrice, uint256 updatedTime) = IOracle(oracleAddress).getTargetValue();
            _checkShort(uAssetAddress, updatedTime, ttl, targetPrice, uAssetAmount, collateralAmount);
        }
        {
            IERC20(collateralAddress).safeTransferFrom(msg.sender, address(this), collateralAmount);
            IERC20(uAssetAddress).safeMint(address(this), uAssetAmount);
            borrowBalances[id] = uAssetAmount;
            collateralBalances[id] = collateralAmount;
        }
        {
            IERC20(uAssetAddress).safeApprove(IController(controllerAddress).router(), uAssetAmount);
        }
        {
            address[] memory path = new address[](2);
            uint[] memory reserve = new uint[](2);
            {
                address poolAddress = IController(controllerAddress).pools(uAssetAddress);
                address token0 = IUniswapV2Pair(poolAddress).token0();
                address token1 = IUniswapV2Pair(poolAddress).token1();
                (uint reserve0, uint reserve1,) = IUniswapV2Pair(poolAddress).getReserves();
                
                path[0] = uAssetAddress;
                path[1] = token1;
                reserve[0] = reserve0;
                reserve[1] = reserve1;
                if (token1 == uAssetAddress) {
                    path[1] = token0;
                    reserve[0] = reserve1;
                    reserve[1] = reserve0;
                }
            }
            bytes memory id_ = id;
            uint256 amountOutMin = IUniswapV2Router02(IController(controllerAddress).router()).getAmountOut(uAssetAmount, reserve[0], reserve[1]) * (10000 - slippage) / 10000;
            uint256 balanceBefore = IERC20(path[1]).balanceOf(address(this));
            IUniswapV2Router02(IController(controllerAddress).router()).swapExactTokensForTokensSupportingFeeOnTransferTokens(uAssetAmount, amountOutMin, path, address(this), deadline);
            uint256 amountOut = IERC20(path[1]).balanceOf(address(this)) - balanceBefore;
            lock(id_, amountOut);
            emit Short(msg.sender, id_, uAssetAmount, collateralAmount, block.timestamp);
        }
    }
    
    function editShort(address uAssetAddress, uint256 uAssetAmount, uint256 collateralAmount, uint256 deadline, uint16 slippage, bytes memory id) external nonReentrant {
        {
            require(msg.sender == accounts[id], "Cannot call edit short the same id with different account"); 
            require(collateralBalances[id] > 0, "Cannot call edit short with unexisted id");
            require(typeBorrow[id] == 2, "Cannot call edit short with different type id");
        }
        uint8 isLocked = 0;
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        uint256 ttl = IController(controllerAddress).ttl();
        address oracleAddress = IController(controllerAddress).oracles(uAssetAddress);
        (uint256 targetPrice, uint256 updatedTime) = IOracle(oracleAddress).getTargetValue();
        {
            _checkShort(uAssetAddress, updatedTime, ttl, targetPrice, uAssetAmount, collateralAmount);
        }

        if(collateralAmount < collateralBalances[id]) {
            uint256 diff = collateralBalances[id] - collateralAmount;
            IERC20(collateralAddress).safeTransfer(msg.sender, diff);
        } else if(collateralAmount > collateralBalances[id]){
            uint256 diff = collateralAmount - collateralBalances[id];
            IERC20(collateralAddress).safeTransferFrom(msg.sender, address(this), diff);
        }
        
        if(block.timestamp - updatedTime > ttl) {
            require(uAssetAmount == borrowBalances[id], "Outside of market hour");
        } else {
            if(uAssetAmount < borrowBalances[id]) {
                uint256 diff = borrowBalances[id] - uAssetAmount;
                address addr = uAssetAddress;
                IERC20(addr).safeTransferFrom(msg.sender, address(this), diff);
                IERC20(addr).safeBurn(diff);
            } else if (uAssetAmount > borrowBalances[id]) {
                uint256 diff = uAssetAmount - borrowBalances[id];
                address addr = uAssetAddress;
                uint256 deadline_ = deadline;
                {
                    IERC20(addr).safeMint(address(this), diff);
                }
                address[] memory path = new address[](2);
                uint[] memory reserve = new uint[](2);
                {
                    (uint reserve0, uint reserve1,) = IUniswapV2Pair(IController(controllerAddress).pools(addr)).getReserves();
                    path[0] = addr;
                    path[1] = IUniswapV2Pair(IController(controllerAddress).pools(addr)).token1();
                    reserve[0] = reserve0;
                    reserve[1] = reserve1;
                    if (IUniswapV2Pair(IController(controllerAddress).pools(addr)).token1() == addr) {
                        path[1] = IUniswapV2Pair(IController(controllerAddress).pools(addr)).token0();
                        reserve[0] = reserve1;
                        reserve[1] = reserve0;
                    }
                }
                {
                    IERC20(addr).safeApprove(IController(controllerAddress).router(), diff);
                }
                {
                    uint256 amountOutMin = IUniswapV2Router02(IController(controllerAddress).router()).getAmountOut(diff, reserve[0], reserve[1]) * (10000 - slippage) / 10000;
                    uint256 balanceBefore = IERC20(path[1]).balanceOf(address(this));
                    IUniswapV2Router02(IController(controllerAddress).router()).swapExactTokensForTokensSupportingFeeOnTransferTokens(diff, amountOutMin, path, address(this), deadline_);
                    uint256 amountOut = IERC20(path[1]).balanceOf(address(this)) - balanceBefore;
                    lock(id, amountOut);
                }
                isLocked = 1;
            }
        }
        
        borrowBalances[id] = uAssetAmount;
        collateralBalances[id] = collateralAmount;
        emit EditShort(msg.sender, id, isLocked, uAssetAmount, collateralAmount, block.timestamp);
    }

    function liquidation(address userAddress, address uAssetAddress, uint256 uAssetAmount, bytes memory id) external nonReentrant {
        require(userAddress == accounts[id], "Wrong account to be liquidated");
        require(borrowBalances[id] >= uAssetAmount, "Over liquidation");
        
        uint16 calculationDecimal = IController(controllerAddress).calculationDecimal();
        uint16 discountRate = IController(controllerAddress).discountRates(uAssetAddress);
        (uint256 targetPrice, uint256 updatedTime) = IOracle(IController(controllerAddress).oracles(uAssetAddress)).getTargetValue();
        
        {
            _checkLiquidation(uAssetAddress, targetPrice, updatedTime, borrowBalances[id], collateralBalances[id], calculationDecimal, discountRate);
        }
        
        uint256 discountedCollateralValue = 
            (uAssetAmount * targetPrice * 985 / 1000) / (10 ** ERC20(uAssetAddress).decimals())
            * (10**calculationDecimal)
            / (10**calculationDecimal - discountRate);
            
        address collateralAddress = IController(controllerAddress).collateralForToken(uAssetAddress);
        if (discountedCollateralValue <= collateralBalances[id]) {
            IERC20(uAssetAddress).safeTransferFrom(msg.sender, address(this), uAssetAmount);
            IERC20(uAssetAddress).safeBurn(uAssetAmount);
            IERC20(collateralAddress).safeTransfer(msg.sender, discountedCollateralValue);
            borrowBalances[id] -= uAssetAmount;
            collateralBalances[id] -= discountedCollateralValue;
            if(borrowBalances[id] == 0) {
                IERC20(collateralAddress).safeTransfer(userAddress, collateralBalances[id]);
                collateralBalances[id] = 0;
            }
            emit Liquidation(msg.sender, userAddress, id, uAssetAmount, discountedCollateralValue, block.timestamp, discountRate);
        } else {
            uint256 collateralBalance = collateralBalances[id];
            uint256 uAssetNeeded =  collateralBalance * ((10**calculationDecimal) - discountRate) * (10 ** ERC20(uAssetAddress).decimals()) / ((10**calculationDecimal) * targetPrice * 985 / 1000);
            // uint256 remainedAmount = uAssetAmount - refundUAssetAmount;
            {
                IERC20(uAssetAddress).safeTransferFrom(msg.sender, address(this), uAssetNeeded);
                IERC20(uAssetAddress).safeBurn(uAssetNeeded);
                IERC20(collateralAddress).safeTransfer(msg.sender, collateralBalance);
            }
            {
                borrowBalances[id] -= uAssetNeeded;
                collateralBalances[id] = 0;
            }
            emit Liquidation(msg.sender, userAddress, id, uAssetNeeded, collateralBalance, block.timestamp, discountRate);
        }
    }
    
    function _checkShort(address uAssetAddress, uint256 updatedTime, uint256 ttl, uint256 targetPrice, uint256 uAssetAmount, uint256 collateralAmount) internal view {
        uint16 minCollateralRatio = IController(controllerAddress).minCollateralRatio();
        uint16 maxCollateralRatio = IController(controllerAddress).maxCollateralRatio();
        uint16 calculationDecimal = IController(controllerAddress).calculationDecimal();
        
        require(block.timestamp - updatedTime <= ttl, "Target price is not updated");
        uint256 realCollateralAmount = targetPrice * uAssetAmount / (10 ** ERC20(uAssetAddress).decimals());
        require(realCollateralAmount * minCollateralRatio <= collateralAmount * (10**calculationDecimal), "less than min collateral ratio");
        require(realCollateralAmount * maxCollateralRatio >= collateralAmount * (10**calculationDecimal), "greater than max collateral ratio");
    }
    
    function _checkLiquidation(address uAssetAddress, uint256 targetPrice, uint256 updatedTime, uint256 borrowBalance, uint256 collateralBalance, uint16 calculationDecimal, uint16 discountRate) internal view {
        uint16 minCollateralRatio = IController(controllerAddress).minCollateralRatio();
        uint256 realCollateralAmount = targetPrice * borrowBalance / (10 ** ERC20(uAssetAddress).decimals());
        require(realCollateralAmount * minCollateralRatio > collateralBalance * (10**calculationDecimal), "More than min");
        uint16 configDiscountRate = IController(controllerAddress).discountRates(uAssetAddress);
        if (configDiscountRate < discountRate) {
            discountRate = configDiscountRate;
        }
        uint256 ttl = IController(controllerAddress).ttl();
        require(block.timestamp - updatedTime <= ttl, "Not updated");
    }

}