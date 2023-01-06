//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IIDOExtra {
    function extras(address) external view returns(address factory);
}

interface IIDO {
    enum PoolStatus {
        Inprogress,
        Listed,
        Cancelled,
        Unlocked
    }
    enum PoolTier {
        Nothing,
        Gold,
        Platinum,
        Diamond,
        Alpha
    }
    struct PoolModel {
        uint256 hardCap; // how much project wants to raise
        uint256 softCap; // how much of the raise will be accepted as successful IDO
        uint256 presaleRate;
        uint256 dexCapPercent;
        uint256 dexRate;
        address projectTokenAddress; //the address of the token that project is offering in return
        PoolStatus status; //: by default “Upcoming”,
        PoolTier tier;
        bool kyc;
    }
    function isHiddenPool(address) external view returns (bool);
    function fundRaiseToken(address) external view returns (address);
    function fairLaunch(address) external view returns (bool);
    function fairPresaleAmount(address) external view returns (uint256);
    function _weiRaised(address) external view returns (uint256);
    function isStealth(address) external view returns (bool);
    function totalSupply(address) external view returns (uint256);

    function poolInformation(address) external view returns (PoolModel memory);
    function poolDetails(address) external view returns (
        uint256 startDateTime,
        uint256 endDateTime,
        uint256 listDateTime,
        uint256 minAllocationPerUser,
        uint256 maxAllocationPerUser,
        uint256 dexLockup,
        string memory extraData,
        bool whitelistable,
        bool audit,
        string memory auditLink);
    function poolAddresses(uint256) external view returns (address);
    function poolOwners(address) external view returns (address);
    function getPoolAddresses() external view returns (address[] memory);
}

interface ILock {
    struct TokenList {
        uint256 amount;
        uint256 startDateTime;
        uint256 endDateTime;
        address owner;
        address creator;
    }

    function liquidities(uint256) external view returns (address);

    function tokens(uint256) external view returns (address);

    function getTokenDetails(address) external view returns (TokenList[] memory);

    function getLiquidityDetails(address) external view returns (TokenList[] memory);
}

contract Multicall is Initializable, OwnableUpgradeable {
    // enum PoolStatus {
    //     Inprogress,
    //     Listed,
    //     Cancelled,
    //     Unlocked
    // }
    // struct PoolModel {
    //     uint256 hardCap; // how much project wants to raise
    //     uint256 softCap; // how much of the raise will be accepted as successful IDO
    //     uint256 presaleRate;
    //     uint256 dexCapPercent;
    //     uint256 dexRate;
    //     address projectTokenAddress; //the address of the token that project is offering in return
    //     PoolStatus status; //: by default “Upcoming”,
    //     PoolTier tier;
    //     bool kyc;
    // }
    // struct TokenList {
    //     uint256 amount;
    //     uint256 startDateTime;
    //     uint256 endDateTime;
    //     address owner;
    //     address creator;
    // }
    struct CardView {
        string name;
        bool isStealth;
        uint256 softCap;
        uint256 hardCap;
        uint8 tier;
        bool kyc;
        bool audit;
        uint256 startDateTime;
        uint256 endDateTime;
        uint8 poolStatus;
        uint256 weiRaised;
        string extraData;
        bool fairLaunch;
        uint256 fairPresaleAmount;
        string fundRaiseToken;
        uint256 marketCap;
    }
    struct Call {
        address target;
        bytes callData;
    }
    struct LiquidityLockList {
        address liquidity;
        uint256 amount;
        string token0Name;
        string token1Name;
        string token0Symbol;
        string token1Symbol;
        address owner;
    }
    struct TokenLockList {
        address token;
        uint256 amount;
        string name;
        uint8 decimals;
        string symbol;
        address owner;
    }
    struct PresaleLockList {
        address pool;
        address liquidity;
        uint256 amount;
        string token0Name;
        string token1Name;
        string token0Symbol;
        string token1Symbol;
        address owner;
    }
    struct PresaleLockDetail{
        string poolName;
        uint256 value;
        uint256 listedTime;
        uint256 dexLockup;
        address owner;
    }
    address public constant WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address[] tokensForPrice;
    address public baseToken;
    IPancakeFactory public factory;
    IIDOExtra public constant iIDOExtra=IIDOExtra(0x78373309C67987679e8eF794Bc70e5c619534827);
    address public constant IDOAddress =
        address(0x476F879CAC05c2976e0DCC7789406292B2f14E96);
    address public constant LockAddress =
        address(0x1aEd86440B5065D523302d9fE1Dd24B9044482E3);
    address[] public factoryList;

    function initialize() public initializer {
        __Ownable_init();
    }

    function tokensForPriceList() external view returns (address[] memory) {
        return tokensForPrice;
    }

    function updateTokensForPriceList(
        address[] memory _tokens,
        address _baseToken
    ) external onlyOwner {
        tokensForPrice = _tokens;
        baseToken = _baseToken;
    }

    function updateFactoryList(address[] memory _factoryList) external onlyOwner {
        factoryList=_factoryList;
    }

    function getFactoryList() external view returns (address[] memory) {
        return factoryList;
    }
    function updateFactory(address _factory) external onlyOwner {
        factory = IPancakeFactory(_factory);
    }

    function _getRatio(address target, address base, address _factory)
        internal
        view
        returns (uint256)
    {
        address pair = IPancakeFactory(_factory).getPair(target, base);
        uint8 decimals = IERC20Metadata(target).decimals();
        if (pair != address(0x0) && IERC20Metadata(base).balanceOf(pair)>0) {
            IPancakePair pairContract = IPancakePair(pair);
            bool isToken0 = pairContract.token0() == target;
            (uint256 reserve0, uint256 reserve1, ) = pairContract.getReserves();
            if (isToken0) {
                
                return (reserve1 * (10**decimals)) / reserve0;
            } else {
                return (reserve0 * (10**decimals)) / reserve1;
            }
        } else return 0;
    }

    function getPrice(address token, address _factory) public view returns (uint256) {
        uint256 ratio = _getRatio(token, baseToken, _factory);
        if (ratio > 0) {
            return ratio;
        } else {
            for (uint8 i = 0; i < tokensForPrice.length; i++) {
                ratio = _getRatio(token, tokensForPrice[i], _factory);
                if (ratio > 0) {
                    uint256 ratio1 = _getRatio(tokensForPrice[i], baseToken, address(factory));
                    return
                        (ratio * ratio1) /
                        (10**IERC20Metadata(tokensForPrice[i]).decimals());
                }
            }
            return 0;
        }
    }  

    function getTokenLockList(
        address[] memory tokenAddresses,
        address search
    ) public view returns (TokenLockList[] memory) {
        ILock lock = ILock(LockAddress);
        uint256 n = 0;
        if (search == address(0x0)) {
            TokenLockList[] memory tokens = new TokenLockList[](
                tokenAddresses.length
            );
            
            for (uint256 i = tokenAddresses.length; i > 0; i--) {
                ILock.TokenList[] memory tokenList = lock.getTokenDetails(tokenAddresses[i-1]);             
                tokens[n] = _getTokenLock(tokenAddresses[i-1], tokenList[0].owner);
                n++;                
            }
            return tokens;
        } else {
            TokenLockList[] memory token=new TokenLockList[](1);
            ILock.TokenList[] memory tokenList = lock.getTokenDetails(search);
            
            token[0]=_getTokenLock(search, tokenList[0].owner);
            return token;
        }
    }

    function _getTokenLock(address token, address owner)
        internal
        view
        returns (TokenLockList memory)
    {
        TokenLockList memory tokenLock;
        tokenLock.token = token;
        tokenLock.name = IERC20Metadata(token).name();
        tokenLock.symbol = IERC20Metadata(token).symbol();
        tokenLock.decimals = IERC20Metadata(token).decimals();
        tokenLock.amount = IERC20Metadata(token).balanceOf(LockAddress);
        tokenLock.owner=owner;
        return tokenLock;
    }


    function getOtherLiqList(
        address[] memory liqAddresses,
        address search
    ) public view returns (LiquidityLockList[] memory) {
        ILock lock = ILock(LockAddress);
        uint256 n = 0;
        if (search == address(0x0)) {
            LiquidityLockList[] memory liqs = new LiquidityLockList[](
                liqAddresses.length
            );
            for (uint256 i = liqAddresses.length; i > 0; i--) {
                ILock.TokenList[] memory liqList = lock.getLiquidityDetails(liqAddresses[i-1]);
                liqs[n] = _getLiqLock(liqAddresses[i-1], liqList[0].owner);
                n++;
            }
            return liqs;
        } else {
            LiquidityLockList[] memory liq = new LiquidityLockList[](1);
            ILock.TokenList[] memory liqList = lock.getLiquidityDetails(search);
            liq[0] = _getLiqLock(search, liqList[0].owner);
            return liq;
        }
    }
    function _getLiqLock(address liquidity, address owner)
        internal
        view
        returns (LiquidityLockList memory)
    {
        LiquidityLockList memory liq;
        liq.owner=owner;
        liq.liquidity = liquidity;
        address token0 = IPancakePair(liquidity).token0();
        liq.token0Name = IERC20Metadata(token0).name();
        liq.token0Symbol = IERC20Metadata(token0).symbol();
        address token1 = IPancakePair(liquidity).token1();
        liq.token1Name = IERC20Metadata(token1).name();
        liq.token1Symbol = IERC20Metadata(token1).symbol();
        liq.amount = IPancakePair(liquidity).balanceOf(LockAddress);
        return liq;
    }

    function _getPresaleLock(address pool, IIDO ido)
        internal
        view
        returns (PresaleLockList memory)
    {
        IPancakeFactory _factory= iIDOExtra.extras(pool)==address(0) ? factory : IPancakeFactory(iIDOExtra.extras(pool));
        PresaleLockList memory liq;
        liq.pool = pool;
        address token0 = ido.fundRaiseToken(pool) == address(0x0)
            ? WETH
            : ido.fundRaiseToken(pool);
        address token1 = ido.poolInformation(pool).projectTokenAddress;
        address pair = _factory.getPair(token0, token1);
        liq.owner=ido.poolOwners(pool);
        liq.amount = IPancakePair(pair).balanceOf(pool);
        liq.liquidity = pair;
        liq.token0Name = IERC20Metadata(token0).name();
        liq.token1Name = IERC20Metadata(token1).name();
        liq.token0Symbol = IERC20Metadata(token0).symbol();
        liq.token1Symbol = IERC20Metadata(token1).symbol();
        return liq;
    }

    function getPresaleLiqList(
        address[] memory pools,
        address search
    ) public view returns (PresaleLockList[] memory) {
        IIDO ido = IIDO(IDOAddress);        
        if(search==address(0x0)){
            uint256 n = 0;
            PresaleLockList[] memory liqs = new PresaleLockList[](
                pools.length
            );
            for (uint256 i = pools.length; i > 0; i--) {
                if(ido.isHiddenPool(pools[i-1])) continue;
                if (ido.poolInformation(pools[i-1]).status != IIDO.PoolStatus.Listed) continue;
                liqs[n] = _getPresaleLock(pools[i-1], ido);
                n++;           
            }
            return liqs;
        }else{
            PresaleLockList[] memory liqs = new PresaleLockList[](1);
            for (uint256 i = pools.length; i > 0; i--) {
                if(ido.isHiddenPool(pools[i-1])) continue;
                if (ido.poolInformation(pools[i-1]).status != IIDO.PoolStatus.Listed) continue;
                PresaleLockList memory liq = _getPresaleLock(pools[i-1], ido);
                if(liq.liquidity==search){
                    liqs[0]=liq;
                    break;
                }
            }
            return liqs;
        }  
    }

    function getPresaleLockDetail(address pool, address liquidity) external view returns(PresaleLockDetail memory){
        PresaleLockDetail memory lockDetail;
        IIDO ido = IIDO(IDOAddress);      
        lockDetail.poolName=IERC20Metadata(ido.poolInformation(pool).projectTokenAddress).name();
        address token0=ido.fundRaiseToken(pool);
        token0= token0==address(0x0) ? WETH : token0;
        lockDetail.value=(IPancakePair(liquidity).balanceOf(pool)*getPrice(token0, address(factory))/IPancakePair(liquidity).totalSupply())*
            IERC20Metadata(token0).balanceOf(liquidity)/(10**IERC20Metadata(token0).decimals());
        (,,lockDetail.listedTime,,,lockDetail.dexLockup,,,,)=ido.poolDetails(pool);
        lockDetail.owner=ido.poolOwners(pool);
        return lockDetail;
    }

    function getOtherLockDetail(address liquidity) external view returns(uint256 value, address owner, ILock.TokenList[] memory liqList){
        ILock lock = ILock(LockAddress);
        address token0=IPancakePair(liquidity).token0();
        uint256 price=getPrice(token0, address(factory));
        if(price==0){
            for(uint256 i=0;i<factoryList.length;i++){
                price=getPrice(token0, factoryList[i]);
                if(price>0)
                    break;
            }
        }
        value=(IPancakePair(liquidity).balanceOf(LockAddress)*price/IPancakePair(liquidity).totalSupply())*
            IERC20Metadata(token0).balanceOf(liquidity)/(10**IERC20Metadata(token0).decimals());
        liqList= lock.getLiquidityDetails(liquidity);
        owner=liqList[0].owner;
    }

    // function getUpcomingAndLiveIDOPools() external view returns(address[] memory){
    //     IIDO ido = IIDO(IDOAddress);
    //     address[] memory pools=ido.getPoolAddresses();
    //     address[] memory poolsUL=new address[](pools.length);
    //     uint256 n=0;
    //     for(uint256 i=0;i<pools.length;i++){
    //         if(ido.isHiddenPool(pools[i]))
    //             continue;
    //         if(uint(ido.poolInformation(pools[i]).status) != 0)
    //             continue;
    //         poolsUL[n]=pools[i];
    //         n++;            
    //     }
    //     return poolsUL;
    // }
    // function getIDOCardViewDirect() external view returns(CardView[] memory){        
    //     IIDO ido = IIDO(IDOAddress);
    //     address[] memory pools=ido.getPoolAddresses();
    //     CardView[] memory cardviews=new CardView[](pools.length);
    //     uint256 n=0;
    //     for(uint256 i=0;i<50;i++){
    //         if(!ido.isHiddenPool(pools[i]) && IIDO.PoolStatus.Inprogress==ido.poolInformation(pools[i]).status){
    //             if(!ido.isStealth(pools[i])){                    
    //                 cardviews[n].name=IERC20Metadata(ido.poolInformation(pools[i]).projectTokenAddress).name();
    //                 cardviews[n].isStealth=false;
    //             }else
    //                 cardviews[n].isStealth=true;
    //             cardviews[n].softCap=ido.poolInformation(pools[i]).softCap;
    //             cardviews[n].hardCap=ido.poolInformation(pools[i]).hardCap;
    //             cardviews[n].tier=uint8(ido.poolInformation(pools[i]).tier);
    //             cardviews[n].kyc=ido.poolInformation(pools[i]).kyc;
    //             (cardviews[n].startDateTime,
    //             cardviews[n].endDateTime,
    //             ,
    //             ,
    //             ,
    //             ,
    //             cardviews[n].extraData,
    //             ,
    //             cardviews[n].audit,)=ido.poolDetails(pools[i]);
 
    //             cardviews[n].fairLaunch=ido.fairLaunch(pools[i]);
    //             cardviews[n].fairPresaleAmount=ido.fairPresaleAmount(pools[i]);
    //             uint256 price;
    //             if(ido.fundRaiseToken(pools[i])!=address(0x0)){
    //                 cardviews[n].fundRaiseToken=IERC20Metadata(ido.fundRaiseToken(pools[i])).name();
    //                 price=getPrice(ido.fundRaiseToken(pools[i]), address(factory));
    //             }else{
    //                 cardviews[n].fundRaiseToken=IERC20Metadata(ido.fundRaiseToken(pools[i])).name();
    //                 price=getPrice(WETH, address(factory));
    //             }
                
    //             uint256 totalSupply;
    //             if(!ido.isStealth(pools[i])){
    //                 totalSupply=IERC20Metadata(ido.poolInformation(pools[i]).projectTokenAddress).totalSupply();
    //             }else{
    //                 totalSupply=ido.totalSupply(pools[i]);
    //             }
    //             if(!cardviews[n].fairLaunch)
    //                 cardviews[n].marketCap=totalSupply/ido.poolInformation(pools[i]).dexRate*price;
    //             else
    //                 cardviews[n].marketCap=totalSupply/cardviews[n].fairPresaleAmount*cardviews[n].softCap*price;
    //             n++;     
    //         }
    //     }
    //     return cardviews;
    // }

    function getIDOCardView(address[] memory pools) external view returns(CardView[] memory){        
        CardView[] memory cardviews=new CardView[](pools.length);
        IIDO ido = IIDO(IDOAddress);
        uint256 n=0;
        for(uint256 i=0;i<pools.length;i++){
            if(!ido.isStealth(pools[i])){                    
                cardviews[n].name=IERC20Metadata(ido.poolInformation(pools[i]).projectTokenAddress).name();
                cardviews[n].isStealth=false;
            }else
                cardviews[n].isStealth=true;
            cardviews[n].softCap=ido.poolInformation(pools[i]).softCap;
            cardviews[n].hardCap=ido.poolInformation(pools[i]).hardCap;
            cardviews[n].tier=uint8(ido.poolInformation(pools[i]).tier);
            cardviews[n].poolStatus=uint8(ido.poolInformation(pools[i]).status);
            cardviews[n].weiRaised=ido._weiRaised(pools[i]);
            cardviews[n].kyc=ido.poolInformation(pools[i]).kyc;
            (cardviews[n].startDateTime,
                cardviews[n].endDateTime,
                ,
                ,
                ,
                ,
                cardviews[n].extraData,
                ,
                cardviews[n].audit,)=ido.poolDetails(pools[i]);
            cardviews[n].fairLaunch=ido.fairLaunch(pools[i]);
            cardviews[n].fairPresaleAmount=ido.fairPresaleAmount(pools[i]);
            uint256 price;
            if(ido.fundRaiseToken(pools[i])!=address(0x0)){
                cardviews[n].fundRaiseToken=IERC20Metadata(ido.fundRaiseToken(pools[i])).name();
                price=getPrice(ido.fundRaiseToken(pools[i]), address(factory));
            }else{
                cardviews[n].fundRaiseToken=IERC20Metadata(WETH).name();
                price=getPrice(WETH, address(factory));
            }
            
            uint256 totalSupply;
            if(!ido.isStealth(pools[i])){
                totalSupply=IERC20Metadata(ido.poolInformation(pools[i]).projectTokenAddress).totalSupply();
            }else{
                totalSupply=ido.totalSupply(pools[i]);
            }
            if(!cardviews[n].fairLaunch)
                cardviews[n].marketCap=totalSupply/ido.poolInformation(pools[i]).dexRate*price;
            else
                cardviews[n].marketCap=totalSupply/cardviews[n].fairPresaleAmount*cardviews[n].softCap*price;
            n++;     
        }
        return cardviews;
    }


    function aggregate(Call[] memory calls)
        public
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(
                calls[i].callData
            );
            require(success);
            returnData[i] = ret;
        }
    }

    function multiCall(Call[] memory calls)
        external
        view
        returns (uint256 blockNumber, bytes[] memory results)
    {
        blockNumber = block.number;
        results = new bytes[](calls.length);

        for (uint256 i; i < calls.length; i++) {
            (bool success, bytes memory result) = calls[i].target.staticcall(
                calls[i].callData
            );
            require(success, "call failed");
            results[i] = result;
        }
    }

    // function getIDO(uint256 number, address IDOAddress)
    //     external
    //     view
    //     returns (uint256 blockNumber, bytes[] memory results)
    // {
    //     blockNumber = block.number;
    //     results = new bytes[](number>20 ? 20 : number);
    //     uint256 end=number-(number>20 ? 20 : number);
    //     IDO ido=new IDO(IDOAddress);
    //     for (uint i=number-1; i >=end; i--) {
    //         (bool success, bytes memory result) = calls[i].target.staticcall(calls[i].callData);
    //         require(success, "call failed");
    //         results[i] = result;
    //     }
    // }

    function getDate(Call[] memory calls)
        public
        returns (uint256 blockNumber, bytes[] memory returnData)
    {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(
                calls[i].callData
            );
            require(success);
            returnData[i] = ret;
        }
    }

    // Helper functions
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    function getBlockHash(uint256 blockNumber)
        public
        view
        returns (bytes32 blockHash)
    {
        blockHash = blockhash(blockNumber);
    }

    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function getCurrentBlockTimestamp()
        public
        view
        returns (uint256 timestamp)
    {
        timestamp = block.timestamp;
    }

    function getCurrentBlockDifficulty()
        public
        view
        returns (uint256 difficulty)
    {
        difficulty = block.difficulty;
    }

    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}