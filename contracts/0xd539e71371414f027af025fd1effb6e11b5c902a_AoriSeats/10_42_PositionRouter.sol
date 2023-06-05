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
import "./MarginManager.sol";
import "../OpenZeppelin/ERC20.sol";
import "./Vault.sol";
import "./Structs.sol";
import "../AoriCall.sol";
import "../AoriPut.sol";
import "../Orderbook.sol";
import "../CallFactory.sol";
import "../PutFactory.sol";

contract PositionRouter is Ownable {

    address public callFactory;
    address public putFactory;
    MarginManager public manager;
    uint256 immutable tolerance = 2 hours;
    uint256 public immutable BPS_DIVISOR = 10000;
    uint256 immutable expScale = 1e18;
    uint256 immutable USDCScale = 1e6;
    mapping(address => bool) public isLiquidator;
    mapping(address => bool) public keeper;
    uint256 public liquidatorFee; //In BPS, 2500
    uint256 public liquidationRatio; //in bps over 10000, default 20000
    uint256 public initialMarginRatio; //20% of underlying, so 2000 base.
    uint256 public liquidatorSeatId; //seat held by this address
    mapping(ERC20 => IRM) public interestRateModels;

    mapping(bytes32 => Structs.OpenPositionRequest) public openPositionRequests;
    bytes32[] public openPositionRequestKeys;
    uint256 indexPosition;

    struct IRM { //All in 1e4 scale
        uint256 baseRate;
        uint256 kinkUtil;
        uint256 rateBeforeUtil;
        uint256 rateAfterUtil;
    }

    event RequestCreated(bytes32 key, address account, uint256 index);
    event OrderApproved(bytes32 key, address account, uint256 index);
    event OrderDenied(uint256 index);

    function initialize(
            address callFactory_, 
            address putFactory_, 
            MarginManager manager_, 
            uint256 liquidatorFee_, 
            uint256 liquidationRatio_, 
            uint256 initialMarginRatio_, 
            uint256 liquidatorSeatId_,
            address keeper_
        ) public onlyOwner {
        callFactory = callFactory_;
        putFactory = putFactory_;
        manager = manager_;
        liquidatorFee = liquidatorFee_;
        liquidationRatio = liquidationRatio_;
        initialMarginRatio = initialMarginRatio_;
        setLiquidatorSeatId(liquidatorSeatId_);
        setKeeper(keeper_);
    }
    

    function setLiquidator(address liquidator) public onlyOwner {
        isLiquidator[liquidator] = true;
    }
    function setKeeper(address _keeper) public onlyOwner {
        keeper[_keeper] = true;
    }
    function setLiquidatorFee(uint256 newFee) public onlyOwner returns(uint256) {
        liquidatorFee = newFee;
        return newFee;
    }
    function setLiquidatorSeatId(uint256 newLiquidatorSeatId) public onlyOwner returns(uint256) {
        liquidatorSeatId = newLiquidatorSeatId;
        return liquidatorSeatId;
    }
    function setLiquidatonThreshold(uint256 newThreshold) public onlyOwner returns(uint256) {
        liquidationRatio = newThreshold;
        return newThreshold;
    }
    function setInitialMarginRatio(uint256 newInitialMarginRatio) public onlyOwner returns(uint256) {
        initialMarginRatio = newInitialMarginRatio;
        return initialMarginRatio;
    }

    function openShortPositionRequest(
            address _account,
            address option,
            uint256 collateral,
            address orderbook,
            bool isCall,
            uint256 amountOfUnderlying,
            uint256 seatId
            ) 
        public returns (uint256) {
        require(amountOfUnderlying > 0, "Must request some borrow");
        address token;
        bytes32 requestKey;
        uint256 optionsToMint;
        uint256 currentIndex;
        if(isCall) {
            token = address(AoriCall(option).UNDERLYING());
            require(CallFactory(callFactory).checkIsListed(option), "Not a valid call market");
            require(AoriCall(option).endingTime() != 0, "Invalid maturity");

            optionsToMint = mulDiv(amountOfUnderlying, USDCScale, AoriCall(option).strikeInUSDC());
            ERC20(token).transferFrom(msg.sender, address(this), collateral);
            
            currentIndex = indexPosition;
            requestKey = getRequestKey(_account, indexPosition);
            indexPosition++;

            Structs.OpenPositionRequest storage positionRequest = openPositionRequests[requestKey];
            positionRequest.account = _account;
            positionRequest.collateral = collateral;
            positionRequest.seatId = seatId;
            positionRequest.orderbook = orderbook;
            positionRequest.isCall = true;
            positionRequest.amountOfUnderlying = amountOfUnderlying;
            positionRequest.endingTime = AoriCall(option).endingTime();

            openPositionRequestKeys.push(requestKey);
            emit RequestCreated(requestKey, _account, currentIndex);
            return currentIndex;
        } else {
            token = address(AoriPut(option).USDC());
            require(PutFactory(putFactory).checkIsListed(option), "Not a valid put market");
            require(AoriPut(option).endingTime() != 0, "Invalid maturity");

            optionsToMint = 10**(12) * mulDiv(amountOfUnderlying, USDCScale, AoriPut(option).strikeInUSDC());            
            ERC20(token).transferFrom(msg.sender, address(this), collateral);

            currentIndex = indexPosition;
            requestKey = getRequestKey(_account, currentIndex);
            indexPosition++;

            Structs.OpenPositionRequest storage positionRequest = openPositionRequests[requestKey];
            positionRequest.account = _account;
            positionRequest.collateral = collateral;
            positionRequest.seatId = seatId;
            positionRequest.orderbook = orderbook;
            positionRequest.isCall = false;
            positionRequest.amountOfUnderlying = amountOfUnderlying;
            positionRequest.endingTime = AoriPut(option).endingTime();
        
            openPositionRequestKeys.push(requestKey);
            emit RequestCreated(requestKey, _account, currentIndex);
            return currentIndex;
        }
        
    }

    function executeOpenPosition(uint256 indexToExecute) public returns (bytes32) {
        require(keeper[msg.sender]);
        bytes32 key = openPositionRequestKeys[indexToExecute];
        Structs.OpenPositionRequest memory positionRequest = openPositionRequests[key];
        ERC20 underlying;
        if(positionRequest.isCall) {
            underlying = AoriCall(address(Orderbook(positionRequest.orderbook).UNDERLYING(true)));
            underlying.approve(address(manager), positionRequest.collateral);
        } else if (!positionRequest.isCall){
            underlying = ERC20(address(Orderbook(positionRequest.orderbook).USDC()));
            underlying.approve(address(manager), positionRequest.collateral);
        }
        underlying.transfer(address(manager), positionRequest.collateral);
        bytes32 keyToEmit = manager.openShortPosition(
            positionRequest.account, 
            positionRequest.collateral, 
            positionRequest.orderbook, 
            positionRequest.isCall, 
            positionRequest.amountOfUnderlying, 
            positionRequest.seatId
        );

        emit OrderApproved(keyToEmit, positionRequest.account, indexToExecute);
        delete openPositionRequestKeys[indexToExecute];
        return keyToEmit;
    }

    function rejectIncreasePosition(uint256 indexToReject) public {
        require(keeper[msg.sender]);
        emit OrderDenied(indexToReject);
        delete openPositionRequestKeys[indexToReject];
    }

    /**
        Get the interest rate based on an inputted util
        @notice util is inputted in BPS
     */
    function getBorrowRate(ERC20 token) public view returns (uint256) {
        require(manager.whitelistedAssets(token),  "Unsupported vault");
        Vault vault = manager.lpTokens(token);
        uint256 util = mulDiv(vault.totalBorrows(), expScale, token.balanceOf(address(vault)) + vault.totalBorrows()); //1e18
        IRM memory irm = interestRateModels[token];
        if (util <= irm.kinkUtil) {
            return irm.baseRate + mulDiv(util, irm.rateBeforeUtil, expScale); //1e18 + 1e18 * 1e18 / 1e18
        } else {
            //1e18 * 1e18 / 1e18 + (1e18 - 1e18) * 1e18 / 1e18
            uint256 prePlusPost = mulDiv(irm.kinkUtil, irm.rateBeforeUtil, expScale) + mulDiv((util - irm.kinkUtil), irm.rateAfterUtil, expScale);
            return (prePlusPost + irm.baseRate);
        }
    }

    function isLiquidatable(ERC20 token, uint256 fairValueOfOption, uint256 optionSize, uint256 collateral, bool isCall) public view returns(uint256, uint256, bool) {
        uint256 collateralVal;
        uint256 positionVal;
        uint256 liquidationThreshold;
        if(isCall) {
            collateralVal = mulDiv(getPrice(manager.oracles(token)), collateral, 10**token.decimals());
            positionVal = mulDiv(fairValueOfOption, optionSize, expScale);
            liquidationThreshold = mulDiv(positionVal, liquidationRatio, BPS_DIVISOR);
            if(liquidationThreshold >= collateralVal) {
                return (collateralVal, positionVal, true);
            } else {
                return (collateralVal, positionVal, false);
            }
        } else {
            collateralVal = mulDiv(getPrice(manager.oracles(token)), optionSize, expScale);
            positionVal = mulDiv(fairValueOfOption, optionSize, expScale);
            liquidationThreshold = mulDiv(positionVal, liquidationRatio, BPS_DIVISOR);
            if(liquidationThreshold >= collateralVal) {
                return (collateralVal, positionVal, true);
            } else {
                return (collateralVal, positionVal, false);
            }
        }
    }

    function getInitialMargin(ERC20 token, uint256 fairValueInUSDCScale, uint256 optionSize, bool isCall) public view returns(uint256) {
        uint256 positionVal;
        if(isCall) {
            positionVal = mulDiv(fairValueInUSDCScale, optionSize, expScale); //1e6 * 1e18 / 1e18
            return mulDiv(positionVal, expScale, getPrice(manager.oracles(token))) + mulDiv(optionSize, initialMarginRatio, BPS_DIVISOR); 
        } else {
            // .2 underlying plus fair val
            positionVal = fairValueInUSDCScale + mulDiv(getPrice(manager.oracles(token)), initialMarginRatio, BPS_DIVISOR);
            return mulDiv(positionVal, optionSize, expScale);
        }
    }
 

    function updateIRM(ERC20 token, uint256 _baseRate, uint256 _kinkUtil, uint256 _rateBeforeUtil, uint256 _rateAfterUtil) public onlyOwner returns (IRM memory) {
        IRM memory irm;
        irm.baseRate = _baseRate;
        irm.kinkUtil = _kinkUtil;
        irm.rateBeforeUtil = _rateBeforeUtil;
        irm.rateAfterUtil = _rateAfterUtil;
        interestRateModels[token] = irm;
        return interestRateModels[token];
    }

    /** 
        Get the price converted from Chainlink format to USDC
    */
    function getPrice(AggregatorV3Interface oracle) public view returns (uint256) {
        (, int256 price,  ,uint256 updatedAt,  ) = oracle.latestRoundData();
        require(price >= 0, "Negative Prices are not allowed");
        require(block.timestamp <= updatedAt + tolerance, "Price is too stale to be trustworthy"); // also works if updatedAt is 0
        if (price == 0) {
            return 0;
        } else {
            //8 is the decimals() of chainlink oracles, return USDC scale
            return (uint256(price) / (10**2));
        }
    }

    function getPosition(address _account, uint256 _index) public view returns (address, uint256, uint256, address, bool, uint256, uint256) {
        bytes32 key = getRequestKey(_account, _index);
        Structs.OpenPositionRequest memory positionRequest = openPositionRequests[key];
        return (
            positionRequest.account,
            positionRequest.collateral,
            positionRequest.seatId,
            positionRequest.orderbook,
            positionRequest.isCall,
            positionRequest.amountOfUnderlying,
            positionRequest.endingTime
        );
    }

    function getRequestKey(address _account, uint256 _index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _index));
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return (x * y) / z;
    }
}