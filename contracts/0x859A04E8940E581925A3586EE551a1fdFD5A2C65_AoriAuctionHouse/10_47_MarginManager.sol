// SPDX-License-Identifier: UNLICENSED
/**                           
        /@#(@@@@@              
       @@      @@@             
        @@                      
        [email protected]@@#                  
        ##@@@@@@,              
      @@@      /@@@&            
    [email protected]@@  @   @  @@@@           
    @@@@  @@@@@  @@@@           
    @@@@  @   @  @@@/           
     @@@@       @@@             
       (@@@@#@@@      
    THE AORI PROTOCOL                           
 */
pragma solidity 0.8.19;

import "../OpenZeppelin/Ownable.sol";
import "../Chainlink/AggregatorV3Interface.sol";
import "./PositionRouter.sol";
import "../OpenZeppelin/Ownable.sol";
import "../OpenZeppelin/ReentrancyGuard.sol";
import "./Vault.sol";

contract MarginManager is Ownable, ReentrancyGuard {
    
    // Storage variables
    PositionRouter public positionRouter;
    uint256 public immutable BPS_DIVISOR = 10000;
    uint256 public collateralRatio; //12000 by default, or 120%
    uint256 immutable expScale = 1e18;
    uint256 immutable USDCScale = 10**6;
    
    //Necessary mappings to store user data and open position/option data
    mapping(ERC20 => bool) public whitelistedAssets;
    mapping(ERC20 => Vault) public lpTokens;
    mapping(ERC20 => AggregatorV3Interface) public oracles;
    mapping(bytes32 => Position) public positions;
    //add address => position mapping for frontend

    struct Position {
        address account;
        bool isCall;
        address token;
        address option;
        uint256 strikeInUSDC;
        uint256 optionSize;
        uint256 collateral;
        uint256 entryMarginRate;
        uint256 lastAccrueTime;
        address orderbook;
        uint256 endingTime;
    }

    constructor(
        PositionRouter _positionRouter
    ){
        positionRouter = _positionRouter;
    }

    event PositionCreated(bytes32 key_, address _account, uint256 _optionSize, address _orderbook, bool _isCall);
    event PositionUpdated(bytes32 key_, address _account, uint256 _optionSize, address _orderbook, bool _isCall);

    /**
        Good
     */
    function openShortPosition(
        address account_,
        uint256 collateral,
        address orderbook,
        bool isCall,
        uint256 amountOfUnderlying,
        uint256 seatId
    ) public nonReentrant returns (bytes32){
        require(msg.sender == address(positionRouter));
        bytes32 key;
        Structs.Vars memory localVars;
        address option = address(Orderbook(orderbook).OPTION());
        ERC20 token;
        if(isCall) {
            token = ERC20(address(AoriCall(option).UNDERLYING()));
            //mint options
            localVars.optionsMinted = lpTokens[token].mintOptions(amountOfUnderlying, option, seatId, account_, true);
            //store position data
            key = getPositionKey(account_, localVars.optionsMinted, orderbook, true);
            Position storage position = positions[key];
            position.account = account_;
            position.isCall = true;
            position.option = option;
            position.strikeInUSDC = AoriCall(option).strikeInUSDC();
            position.optionSize = localVars.optionsMinted;
            position.collateral = collateral;
            position.entryMarginRate = positionRouter.getBorrowRate(token); //1e8 per block, 
            position.lastAccrueTime = block.timestamp;
            position.orderbook = orderbook;
            position.endingTime = AoriCall(option).endingTime();
            emit PositionCreated(key, account_, position.optionSize, position.orderbook, true);
        } else if(!isCall) {
            token = ERC20(address(AoriPut(option).USDC()));

            //mint options
            localVars.optionsMinted = lpTokens[token].mintOptions(amountOfUnderlying, option, seatId, account_, false);
            //store position data
            key = getPositionKey(account_, localVars.optionsMinted, orderbook, true);
            Position storage position = positions[key];
            position.account = account_;
            position.isCall = false;
            position.option = option;
            position.strikeInUSDC = AoriPut(option).strikeInUSDC();
            position.optionSize = localVars.optionsMinted;
            position.collateral = collateral;
            position.entryMarginRate = positionRouter.getBorrowRate(token);
            position.lastAccrueTime = block.timestamp;
            position.orderbook = orderbook;
            position.endingTime = AoriPut(option).endingTime();
            emit PositionCreated(key, account_, position.optionSize, position.orderbook, false);
        }
        return key;
    }

    /**
        Good
     */
    function settlePosition(address account, bytes32 key) public nonReentrant {
        Position memory position = positions[key];
        uint256 collateralMinusLoss;
        ERC20 underlying;
        if(position.isCall) {
            AoriCall(position.option).endingTime();
            require(block.timestamp >= AoriCall(position.option).endingTime(), "Option has not reached expiry");
            underlying = ERC20(address(AoriCall(position.option).UNDERLYING()));
            if(AoriCall(position.option).getITM() > 0) {
                lpTokens[underlying].settleITMOption(position.option, true);
                collateralMinusLoss = position.collateral - positionRouter.mulDiv(AoriCall(position.option).settlementPrice() - position.strikeInUSDC, position.optionSize, USDCScale); 
                underlying.approve(account, collateralMinusLoss);
                underlying.transfer(account, collateralMinusLoss);
                underlying.decreaseAllowance(account, underlying.allowance(address(this), account));
                delete positions[key];
                emit PositionUpdated(key, account, position.optionSize, position.orderbook, position.isCall);
            } else {
                lpTokens[underlying].settleOTMOption(position.option, true);
                underlying.approve(account, position.collateral);
                underlying.transfer(account, position.collateral);
                underlying.decreaseAllowance(account, underlying.allowance(address(this), account));
                delete positions[key];
                emit PositionUpdated(key, account, position.optionSize, position.orderbook, position.isCall);
            }
        } else {
            require(block.timestamp >= AoriCall(position.option).endingTime(), "Option has not reached expiry");
            underlying = ERC20(address(AoriPut(position.option).USDC()));
            if(AoriPut(position.option).getITM() > 0) {
                lpTokens[underlying].settleITMOption(position.option, false);
                collateralMinusLoss = position.collateral - positionRouter.mulDiv(position.strikeInUSDC - AoriPut(position.option).settlementPrice(), position.optionSize, expScale);
                doTransferOut(underlying, account, collateralMinusLoss);
                delete positions[key];
                emit PositionUpdated(key, account, position.optionSize, position.orderbook, position.isCall);
            } else {
                lpTokens[underlying].settleOTMOption(position.option, false);
                doTransferOut(underlying, account, collateralMinusLoss);
                delete positions[key];
                emit PositionUpdated(key, account, position.optionSize, position.orderbook, position.isCall);
            }
        }
    }
    /**
        Good
     */
    function addCollateral(bytes32 key, uint256 collateralToAdd) public nonReentrant returns (uint256) {
        Position memory position = positions[key];
        ERC20 underlying;        
        if(position.isCall) {
            underlying = ERC20(address(AoriCall(position.option).UNDERLYING()));
            underlying.transferFrom(msg.sender, address(this), collateralToAdd);
            position.collateral += collateralToAdd;
            emit PositionUpdated(key, position.account, position.optionSize, position.orderbook, true);
        } else {
            underlying = ERC20(address(AoriPut(position.option).UNDERLYING()));
            underlying.transferFrom(msg.sender, address(this), collateralToAdd);
            position.collateral += collateralToAdd;
            emit PositionUpdated(key, position.account, position.optionSize, position.orderbook, true);
        }
        return position.collateral;
    }
    /**
        Good
     */
    function liquidatePosition(bytes32 key, uint256 fairValueOfOption, address liquidator) public returns (uint256) {
        require(positionRouter.isLiquidator(msg.sender));
        Position memory position = positions[key];
        accruePositionInterest(key);
        Structs.Vars memory localVars;
        ERC20 underlying;
        if(position.isCall) {
            underlying = ERC20(address(AoriCall(position.option).UNDERLYING()));
            require(whitelistedAssets[underlying], "Asset it not whitelisted");
            (localVars.collateralVal, localVars.portfolioVal, localVars.isLiquidatable) = positionRouter.isLiquidatable(underlying, fairValueOfOption, position.optionSize, position.collateral, true);
            require(localVars.isLiquidatable, "Portfolio is not liquidatable");

            localVars.profit = localVars.collateralVal - localVars.portfolioVal;
            localVars.profitInUnderlying = positionRouter.mulDiv(localVars.profit, 10**underlying.decimals(), positionRouter.getPrice(oracles[underlying]));
            uint256 fairValueInUnderlying = positionRouter.mulDiv(fairValueOfOption, position.optionSize, positionRouter.getPrice(oracles[underlying]));
            localVars.collateralToLiquidator = fairValueInUnderlying + positionRouter.mulDiv(localVars.profitInUnderlying, positionRouter.liquidatorFee(), BPS_DIVISOR);
            //Liquidator sells us options
            doTransferOut(ERC20(position.option), address(lpTokens[underlying]), position.optionSize);
            lpTokens[underlying].closeHedgedPosition(position.option, true, position.optionSize);
            //transfer the profit to the liquidator
            doTransferOut(underlying, liquidator, localVars.collateralToLiquidator);
            //and profit to the vault
            doTransferOut(underlying, address(lpTokens[underlying]), position.collateral - localVars.collateralToLiquidator);
            //storage
            delete positions[key];
            emit PositionUpdated(key, position.account, position.optionSize, position.orderbook, true);
        } else {
            underlying = ERC20(address(AoriPut(position.option).USDC()));
            require(whitelistedAssets[underlying], "Asset it not whitelisted");
            (localVars.collateralVal, localVars.portfolioVal, localVars.isLiquidatable) = positionRouter.isLiquidatable(underlying, fairValueOfOption, position.optionSize, position.collateral, false);
            require(localVars.isLiquidatable, "Portfolio is not liquidatable");
            //Calculate the fees
            localVars.profit = localVars.collateralVal - localVars.portfolioVal;
            localVars.profitInUnderlying = positionRouter.mulDiv(localVars.profit, 10**USDCScale, positionRouter.getPrice(oracles[underlying]));
            localVars.collateralToLiquidator = fairValueOfOption + positionRouter.mulDiv(localVars.profitInUnderlying, positionRouter.liquidatorFee(), BPS_DIVISOR);
            //Liquidator sells the vault the options
            doTransferOut(AoriPut(position.option), address(lpTokens[underlying]), position.optionSize);
            lpTokens[underlying].closeHedgedPosition(position.option, true, position.optionSize);
            //transfer the profit to the liquidator
            doTransferOut(underlying, liquidator, localVars.collateralToLiquidator);
            //and profit to the vault
            doTransferOut(underlying, address(lpTokens[underlying]), position.collateral - localVars.collateralToLiquidator);
            
            AoriPut(position.option).liquidationSettlement(position.optionSize);
            //storage
            delete positions[key];
            emit PositionUpdated(key, position.account, position.optionSize, position.orderbook, false);
        }
    }
    /**
        Good
     */
    function accruePositionInterest(bytes32 key) public returns (bool) {
        Position memory position = positions[key];
        ERC20 underlying;
        //irm calc
        AoriCall call;
        AoriPut put;
        uint256 interestOwed;
        require(block.timestamp - position.lastAccrueTime > 0, "cannot accrue position interest at the moment of deployment");
        
        if(position.isCall) {
            call = AoriCall(position.option);
            underlying = ERC20(address(call.UNDERLYING()));
            uint256 interestFactor = ((positionRouter.getBorrowRate(underlying) + position.entryMarginRate) / 2) * (block.timestamp - position.lastAccrueTime);
            interestOwed = positionRouter.mulDiv(interestFactor, position.optionSize, expScale);
            doTransferOut(underlying, address(lpTokens[underlying]), interestOwed);
        } else {
            put = AoriPut(position.option);
            underlying = ERC20(address(put.UNDERLYING()));
            uint256 interestFactor = ((positionRouter.getBorrowRate(underlying) + position.entryMarginRate) / 2) * (block.timestamp - position.lastAccrueTime);
            uint256 USDCUnderlying = positionRouter.mulDiv(position.optionSize, position.strikeInUSDC, expScale);
            interestOwed = positionRouter.mulDiv(interestFactor, USDCUnderlying, expScale);
            doTransferOut(underlying, address(lpTokens[underlying]), interestOwed);
        }
        if(position.collateral > interestOwed) {
            position.collateral -= interestOwed;
            position.lastAccrueTime = block.timestamp;
            lpTokens[underlying].repaid(interestOwed);
            return true;
        } else {
            return false;
        }
    }
    /**
        Good
     */
    function whitelistAsset(ERC20 token, AggregatorV3Interface oracle) public onlyOwner nonReentrant returns(ERC20) {
        whitelistedAssets[token] = true;
        Vault lpToken = new Vault(token, string.concat("Aori Vault for",string(token.name())), string.concat("a",string(token.name())), MarginManager(address(this)));
        lpTokens[token] = lpToken;
        oracles[token] = oracle;
        return token;
    }

    function getPosition(address _account, uint256 _optionSize, address _orderbook, bool _isCall) public view returns (address, bool, address, uint256, uint256, uint256, uint256, uint256, address, uint256) {
        bytes32 key = getPositionKey(_account, _optionSize, _orderbook, _isCall);
        Position memory position = positions[key];
        return (
            position.account,
            position.isCall,
            position.option,
            position.strikeInUSDC,
            position.optionSize,
            position.collateral,
            position.entryMarginRate,
            position.lastAccrueTime,
            position.orderbook,
            position.endingTime
        );
    }

    function getPositionWithKey(bytes32 key) public view returns (address, bool, address, uint256, uint256, uint256, uint256, uint256, address, uint256) {
        Position memory position = positions[key];
        return (
            position.account,
            position.isCall,
            position.option,
            position.strikeInUSDC,
            position.optionSize,
            position.collateral,
            position.entryMarginRate,
            position.lastAccrueTime,
            position.orderbook,
            position.endingTime
        );
    }

    function getPositionKey(address _account, uint256 _optionSize, address _orderbook, bool _isCall) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _account,
            _optionSize,
            _orderbook,
            _isCall
        ));
    }

    function vaultAdd(ERC20 token) public view returns (address) {
        require(whitelistedAssets[token], "Unsupported market");
        return address(lpTokens[token]);
    }

    function doTransferOut(ERC20 token, address receiver, uint256 amount) internal returns (bool) {
        token.approve(receiver, amount);
        token.transfer(receiver, amount);
        token.decreaseAllowance(receiver, token.allowance(address(this), receiver));
    }
}