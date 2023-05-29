pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20.sol";
import "../interfaces/IDSProxy.sol";
import "../openzeppelin/Ownable.sol";
import  "../libraries/SmartPoolManager.sol";
import "../libraries/EnumerableSet.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";
import "../libraries/SafeERC20.sol";
import "../base/Logs.sol";

interface ICRPPool {
    function getController() external view returns (address);

    enum Etypes {
        OPENED,
        CLOSED
    }

    function etype() external view returns (Etypes);

    function isCompletedCollect() external view returns (bool);
}

interface ICRPFactory {
    function isCrp(address addr) external view returns (bool);
}

interface IDesynOwnable {
    function adminList(address adr) external view returns (bool);
    function getController() external view returns (address);
    function getOwners() external view returns (address[] memory);
    function getOwnerPercentage() external view returns (uint[] memory);
    function allOwnerPercentage() external view returns (uint);
}

/**
 * @author Desyn Labs
 * @title Vault managerFee
 */
contract UserVault is Ownable, Logs {
    using SafeMath for uint;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    event ManagersClaim(address indexed caller,address indexed pool, address token, uint amount, uint time);
    event ManagerClaim(address indexed caller,address indexed pool, address indexed manager, address token, uint amount, uint time);
    event KolClaim(address indexed caller,address indexed kol, address token, uint amount, uint time);

    event TypeAmountIn(address indexed pool, uint types, address caller, address token, uint balance);

    ICRPFactory crpFactory;
    address vaultAddress;

    // pool of tokens
    struct PoolTokens {
        address[] tokenList;
        uint[] managerAmount;
        uint[] issueAmount;
        uint[] redeemAmount;
        uint[] perfermanceAmount;
    }

    struct PoolStatus {
        bool couldManagerClaim;
        bool isBlackList;
        bool isSetParams;
        SmartPoolManager.KolPoolParams kolPoolConfig;
    }

    // kol list
    struct KolUserInfo {
        address userAdr;
        uint[] userAmount;
    }

    struct UserKolInfo {
        address kol;
        uint index;
    }

    struct ClaimTokens {
        address[] tokens;
        uint[] amounts;
    }

    // pool => kol => KolUserInfo[]
    mapping(address => mapping(address => KolUserInfo[])) kolUserInfo;

    // pool tokens
    mapping(address => PoolTokens) poolsTokens;
    mapping(address => PoolStatus) poolsStatus;

    //pool => initTotalAmount[]
    mapping(address => uint) public poolInviteTotal;

    //pool => kol[]
    mapping(address => EnumerableSet.AddressSet) kolsList;

    //pool => kol => totalAmount[]
    mapping(address => mapping(address => uint[])) public kolTotalAmountList;

    // pool => user => kol
    mapping(address => mapping(address => UserKolInfo)) public userKolList;
    
    // pool=>kol=>tokens
    mapping(address => mapping(address => ClaimTokens)) kolHasClaimed;

    // pool=>manage=>tokens
    mapping (address => ClaimTokens) manageHasClaimed;

    receive() external payable {}

    uint constant RATIO_BASE = 100;

    function getManagerClaimBool(address pool) external view returns(bool){
        return poolsStatus[pool].couldManagerClaim;
    }

    // one type call and receiver token
    function depositToken(
        address pool,
        uint types,
        address[] calldata tokensIn,
        uint[] calldata amountsIn
    ) external onlyVault {
        require(tokensIn.length == amountsIn.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        _updatePool(pool, types, tokensIn, amountsIn);
        poolsStatus[pool].couldManagerClaim = true;
    }

    // total tokens in pool
    function getPoolReward(address pool) external view returns (address[] memory tokenList, uint[] memory balances) {
        PoolTokens memory tokens = poolsTokens[pool];
        uint len = tokens.tokenList.length;

        balances = new uint[](len);    
        tokenList = tokens.tokenList;

        for(uint i; i<len ;i++){
            balances[i] = tokens.managerAmount[i]
                            .add(tokens.issueAmount[i])
                            .add(tokens.redeemAmount[i])
                            .add(tokens.perfermanceAmount[i]);
        }
    }

    struct RewardVars {
        address pool;
        uint t0Ratio;
        uint t1Ratio;
        uint t2Ratio;
        uint t3Ratio;
        uint[] managementAmounts;
        uint[] issueAmounts;
        uint[] redemptionAmounts;
        uint[] performanceAmounts;
    }

    // one kol total reward 
    function getKolReward(
        address pool,
        address kol
    ) external view returns (address[] memory tokenList, uint[] memory balances) {
        uint contributionByCurKol = kolTotalAmountList[pool][kol].length > 0 ? kolTotalAmountList[pool][kol][0] : 0;
        uint allContributionByKol = poolInviteTotal[pool];

        SmartPoolManager.KolPoolParams memory params = poolsStatus[pool].kolPoolConfig;

        PoolTokens memory tokens = poolsTokens[pool];
        balances = new uint[](tokens.tokenList.length);
        tokenList = tokens.tokenList;

        RewardVars memory vars = RewardVars(
            pool,
            _levelJudge(contributionByCurKol, params.managerFee),
            _levelJudge(contributionByCurKol, params.issueFee),
            _levelJudge(contributionByCurKol, params.redeemFee),
            _levelJudge(contributionByCurKol, params.perfermanceFee),
            tokens.managerAmount,
            tokens.issueAmount,
            tokens.redeemAmount,
            tokens.perfermanceAmount
        );

        for(uint i; i < tokenList.length; i++){
             balances[i] = vars.managementAmounts[i].mul(vars.t0Ratio).div(RATIO_BASE)
                                .add(vars.issueAmounts[i].mul(vars.t1Ratio).div(RATIO_BASE))
                                .add(vars.redemptionAmounts[i].mul(vars.t2Ratio).div(RATIO_BASE))
                                .add(vars.performanceAmounts[i].mul(vars.t3Ratio).div(RATIO_BASE))
                                .mul(contributionByCurKol)
                                .div(allContributionByKol);
        }
    }

    function kolClaim(address pool) external {
        if (_isClosePool(pool)) {
            require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
            require(ICRPPool(pool).isCompletedCollect(), "ERR_NOT_COMPLETED_COLLECT");
            (address[] memory tokens, uint[] memory amounts) = this.getKolReward(pool, msg.sender);

            ClaimTokens storage kolClaimedInfo = kolHasClaimed[pool][msg.sender];

            // update length
            kolClaimedInfo.tokens = tokens;
            uint amountsLen = kolClaimedInfo.amounts.length;
            uint tokensLen = tokens.length;

            if(amountsLen != tokensLen){
                uint delta = tokensLen - amountsLen;
                for(uint i; i < delta; i++){
                    kolClaimedInfo.amounts.push(0);
                }
            }
            
            address receiver = address(msg.sender).isContract()? IDSProxy(msg.sender).owner(): msg.sender;
            for(uint i; i< tokens.length; i++) {
                uint b = amounts[i] - kolClaimedInfo.amounts[i];
                if(b != 0){
                    IERC20(tokens[i]).safeTransfer(receiver, b);
                    kolClaimedInfo.amounts[i] = kolClaimedInfo.amounts[i].add(b);
                    emit KolClaim(msg.sender,receiver,tokens[i],b,block.timestamp);
                }
            }
        }
    }

    // manager claim
    function managerClaim(address pool) external {
        // try  {} catch {}
        if (_isClosePool(pool) && poolsStatus[pool].couldManagerClaim) {
            bool isManager = IDesynOwnable(pool).adminList(msg.sender) || IDesynOwnable(pool).getController() == msg.sender;
            bool isCollectSuccee = ICRPPool(pool).isCompletedCollect();
            require(isCollectSuccee, "ERR_NOT_COMPLETED_COLLECT");
            require(isManager, "ERR_NOT_MANAGER");
            (address[] memory tokens, uint[] memory amounts) = this.getUnManagerReward(pool);
            poolsStatus[pool].couldManagerClaim = false;

            ClaimTokens storage manageHasClimed = manageHasClaimed[pool];

            // update length
            manageHasClimed.tokens = tokens;
            uint amountsLen = manageHasClimed.amounts.length;
            uint tokensLen = tokens.length;

            if(amountsLen != tokensLen){
                uint delta = tokensLen - amountsLen;
                for(uint i; i < delta; i++){
                    manageHasClimed.amounts.push(0);
                }
            }
            // update tokens
            for(uint i; i< tokens.length; i++){
                address t = tokens[i];
                if(amounts[i]!=0){
                    _transferHandle(pool, t, amounts[i]);
                    manageHasClimed.amounts[i] = manageHasClimed.amounts[i].add(amounts[i]);
                }
            }
        }
    }

    function getManagerReward(address pool) external view returns (address[] memory, uint[] memory) {
        (address[] memory totalTokens, uint[] memory totalFee) = this.getPoolReward(pool);
        (, uint[] memory kolFee) = this.getKolsReward(pool);

        uint len = totalTokens.length;
        uint[] memory balances = new uint[](len);

        for(uint i; i<len; i++){
            balances[i] = totalFee[i] - kolFee[i];
        }

        return (totalTokens, balances);
    }
    // for all manager
    function getUnManagerReward(address pool) external returns (address[] memory, uint[] memory) {
        (address[] memory totalTokens, uint[] memory totalAmounts) = this.getManagerReward(pool);
        ClaimTokens storage manageHasClimed = manageHasClaimed[pool];

        // update length
        manageHasClimed.tokens = totalTokens;
        uint amountsLen = manageHasClimed.amounts.length;
        uint tokensLen = totalTokens.length;
        if(amountsLen != tokensLen){
            uint delta = tokensLen - amountsLen;
            for(uint i; i < delta; i++){
                manageHasClimed.amounts.push(0);
            }
        }

        uint len = totalTokens.length;
        uint[] memory balances = new uint[](len);
        for(uint i; i < totalTokens.length; i++){
            balances[i] = totalAmounts[i] - manageHasClimed.amounts[i];
        }        

        return (totalTokens,balances);
    }

    function getPoolFeeTypes(address pool) external view returns(PoolTokens memory result){      
        return poolsTokens[pool];
    }
    
    function getManagerFeeTypes(address pool) external view returns(PoolTokens memory result){     
        result = this.getPoolFeeTypes(pool);
        PoolTokens memory allKolFee = _getKolsFeeTypes(pool); 

        uint len = result.tokenList.length;
        for(uint i; i< len; i++){
            result.managerAmount[i] = result.managerAmount[i].sub(allKolFee.managerAmount[i]);
            result.issueAmount[i] = result.issueAmount[i].sub(allKolFee.issueAmount[i]);
            result.redeemAmount[i] = result.redeemAmount[i].sub(allKolFee.redeemAmount[i]);
            result.perfermanceAmount[i] = result.perfermanceAmount[i].sub(allKolFee.perfermanceAmount[i]);
        }
    }
  
    function _getKolsFeeTypes(address pool) internal view returns(PoolTokens memory result) {
        PoolTokens memory poolInfo = poolsTokens[pool];
        uint len = poolInfo.tokenList.length;
        result.tokenList = poolInfo.tokenList;
        
        EnumerableSet.AddressSet storage list = kolsList[pool];
        uint kolLen = list.length();
        // init result
        result.managerAmount = new uint[](len);
        result.issueAmount = new uint[](len);
        result.redeemAmount = new uint[](len);
        result.perfermanceAmount = new uint[](len);

        for(uint types; types<4; types++){
            for(uint i; i<len; i++){ 
                for (uint j; j < kolLen; j++) {
                    if(types == 0) result.managerAmount[i] = result.managerAmount[i].add(_computeKolTotalReward(pool, list.at(j), 0, i));
                    else if(types == 1) result.issueAmount[i] = result.issueAmount[i].add(_computeKolTotalReward(pool, list.at(j), 1, i));
                    else if(types == 2) result.redeemAmount[i] = result.redeemAmount[i].add(_computeKolTotalReward(pool, list.at(j), 2, i));
                    else if(types == 3) result.perfermanceAmount[i] = result.perfermanceAmount[i].add(_computeKolTotalReward(pool, list.at(j), 3, i));
                }    
            }      
        }
    }

    function getKolFeeType(address pool, address kol) external view returns(PoolTokens memory result) {
        PoolTokens memory poolInfo = poolsTokens[pool];
        result.tokenList = poolInfo.tokenList;
        
        uint len = poolInfo.tokenList.length;
        // init result
        result.managerAmount = new uint[](len);
        result.issueAmount = new uint[](len);
        result.redeemAmount = new uint[](len);
        result.perfermanceAmount = new uint[](len);
        // more for to save gas
        for(uint i; i<len; i++){ 
            result.managerAmount[i] = result.managerAmount[i].add(_computeKolTotalReward(pool, kol, 0, i));
            result.issueAmount[i] = result.issueAmount[i].add(_computeKolTotalReward(pool, kol, 1, i));
            result.redeemAmount[i] = result.redeemAmount[i].add(_computeKolTotalReward(pool, kol, 2, i));
            result.perfermanceAmount[i] = result.perfermanceAmount[i].add(_computeKolTotalReward(pool, kol, 3, i));
        }      
    }

    function getKolsReward(address pool) external view returns (address[] memory, uint[] memory) {
        EnumerableSet.AddressSet storage list = kolsList[pool];
        uint len = list.length();
        address[] memory tokens = poolsTokens[pool].tokenList;
        uint[] memory balances = new uint[](tokens.length);
        for (uint i = 0; i < len; i++) {
            (, uint[] memory singleReward) = this.getKolReward(pool, list.at(i));
            for(uint k; k < singleReward.length; k++){
                balances[k] = balances[k] + singleReward[k];
            }
        }

        return (tokens,balances);
    }

    function getUnKolReward(address pool, address kol) external returns (address[] memory,uint[] memory) {
        (address[] memory totalTokens, uint[] memory totalReward) = this.getKolReward(pool, kol);

        ClaimTokens storage singleKolHasReward = kolHasClaimed[pool][kol];
        // update length
        singleKolHasReward.tokens = totalTokens;
        uint amountsLen = singleKolHasReward.amounts.length;
        uint tokensLen = totalTokens.length;
        if(amountsLen != tokensLen){
            uint delta = tokensLen - amountsLen;
            for(uint i; i < delta; i++){
                singleKolHasReward.amounts.push(0);
            }
        }

        uint len = totalTokens.length;
        uint[] memory balances = new uint[](len);
        for(uint i; i<len; i++){
            balances[i] = totalReward[i] - singleKolHasReward.amounts[i];
        }

        return (totalTokens, balances);
    }

    function recordTokenInfo(
        address kol,
        address user,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external {
        address pool = msg.sender;
        uint len = poolTokens.length;
        require(len == tokensAmount.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        UserKolInfo storage userKolBind = userKolList[pool][user];
        
        if (userKolBind.kol == address(0)) {
            userKolBind.kol = kol;
            if (!kolsList[pool].contains(kol)) kolsList[pool].addValue(kol);
        }
        address newKol = userKolBind.kol;
        require(newKol != address(0), "ERR_INVALID_KOL_ADDRESS");
        //total amount record
        poolInviteTotal[pool] = poolInviteTotal[pool].add(tokensAmount[0]);
        uint[] memory totalAmounts = new uint[](len);
        for (uint i; i < len; i++) {
            bool kolHasInvitations = kolTotalAmountList[pool][newKol].length == 0;
            kolHasInvitations
                ? totalAmounts[i] = tokensAmount[i]
                : totalAmounts[i] = tokensAmount[i].add(kolTotalAmountList[pool][newKol][i]);
        }
        kolTotalAmountList[pool][newKol] = totalAmounts;
        //kol user info record
        KolUserInfo[] storage userInfoArray = kolUserInfo[pool][newKol];
        uint index = userKolBind.index;
        if (index == 0) {
            KolUserInfo memory userInfo;
            userInfo.userAdr = user;
            userInfo.userAmount = tokensAmount;
            userInfoArray.push(userInfo);
            userKolBind.index = userInfoArray.length;
        } else {
            KolUserInfo storage userInfo = kolUserInfo[pool][newKol][index - 1];
            for (uint a; a < userInfo.userAmount.length; a++) {
                userInfo.userAmount[a] = userInfo.userAmount[a].add(tokensAmount[a]);
            }
        }
    }

    function setPoolParams(address pool, SmartPoolManager.KolPoolParams memory _poolParams) external onlyCrpFactory {
        PoolStatus storage status = poolsStatus[pool];
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(!status.isSetParams, "ERR_HAS_SETED");

        status.isSetParams = true;
        status.kolPoolConfig = _poolParams;
    }

    // function _getRatioTotal(address pool, uint types) internal view returns(uint){
    //     SmartPoolManager.KolPoolParams memory params = poolsStatus[pool].kolPoolConfig;
    //     if(types == 0) return params.managerFee.firstLevel.ratio.add(params.managerFee.secondLevel.ratio).add(params.managerFee.thirdLevel.ratio).add(params.managerFee.fourLevel.ratio);
    //     else if(types == 1) return params.issueFee.firstLevel.ratio.add(params.issueFee.secondLevel.ratio).add(params.issueFee.thirdLevel.ratio).add(params.issueFee.fourLevel.ratio);
    //     else if(types == 2) return params.redeemFee.firstLevel.ratio.add(params.redeemFee.secondLevel.ratio).add(params.redeemFee.thirdLevel.ratio).add(params.redeemFee.fourLevel.ratio);
    //     else if(types == 3) return params.perfermanceFee.firstLevel.ratio.add(params.perfermanceFee.secondLevel.ratio).add(params.perfermanceFee.thirdLevel.ratio).add(params.perfermanceFee.fourLevel.ratio);
    // }

    function getKolsAdr(address pool) external view returns (address[] memory) {
        return kolsList[pool].values();
    }

    function getPoolConfig(address pool) external view returns (SmartPoolManager.KolPoolParams memory) {
        return poolsStatus[pool].kolPoolConfig;
    }

    function setBlackList(address pool, bool bools) external onlyOwner _logs_ {
        poolsStatus[pool].isBlackList = bools;
    }

    function setCrpFactory(address adr) external onlyOwner _logs_ {
        crpFactory = ICRPFactory(adr);
    }

    function claimToken(
        address token,
        address user,
        uint amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(user, amount);
    }

    function claimEther() external payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setVaultAdr(address adr) external onlyOwner _logs_ {
        vaultAddress = adr;
    }

    function getKolHasClaimed(address pool,address kol) external view returns(ClaimTokens memory) {
        return kolHasClaimed[pool][kol];
    }
        
    function getManageHasClaimed(address pool) external view returns(ClaimTokens memory) {
        return manageHasClaimed[pool];
    }

    function getKolUserInfo(address pool, address kol) external view  returns (KolUserInfo[] memory) {
        return kolUserInfo[pool][kol];
    }

    function getUserKolInfo(address pool, address user) external view  returns (UserKolInfo memory) {
        return userKolList[pool][user];
    }

    function _updatePool(
        address pool,
        uint types,
        address[] memory tokenIn,
        uint[] memory amountIn
    ) internal {
        PoolTokens storage tokens = poolsTokens[pool];

        for(uint i; i < tokenIn.length; i++){
            address t = tokenIn[i];
            uint b = amountIn[i];

            (bool isExit,uint index) = _arrIncludeAddr(tokens.tokenList, t);

            // update token and init value
            if(!isExit){
                tokens.tokenList.push(t);
                tokens.managerAmount.push(0);
                tokens.issueAmount.push(0);
                tokens.redeemAmount.push(0);
                tokens.perfermanceAmount.push(0);
                index = tokens.tokenList.length -1;
            }

            // update valut
            if(b != 0){
                if(types == 0) tokens.managerAmount[index] = tokens.managerAmount[index].add(b);
                else if(types == 1) tokens.issueAmount[index] = tokens.issueAmount[index].add(b);
                else if(types == 2) tokens.redeemAmount[index] = tokens.redeemAmount[index].add(b);
                else if(types == 3) tokens.perfermanceAmount[index] = tokens.perfermanceAmount[index].add(b);
                emit TypeAmountIn(pool, types, msg.sender, t, b);
            }
        }
    }

    function _arrIncludeAddr(address[] memory tokens, address target) internal pure returns(bool isInclude, uint index){
        for(uint i; i<tokens.length; i++){
            if(tokens[i] == target){ 
                isInclude = true;
                index = i;
                break;
            }
        }
    }

    function _transferHandle(
        address pool,
        address t,
        uint balance
    ) internal {
        require(balance != 0, "ERR_ILLEGAL_BALANCE");
        address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
        uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
        uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();

        for (uint k = 0; k < managerAddressList.length; k++) {
            address reciver = address(managerAddressList[k]).isContract()? IDSProxy(managerAddressList[k]).owner(): managerAddressList[k];
            uint b = balance.mul(ownerPercentage[k]).div(allOwnerPercentage);
            IERC20(t).safeTransfer(reciver, b);
            emit ManagerClaim(msg.sender, pool, reciver,t,b,block.timestamp);
        }
        emit ManagersClaim(msg.sender,pool,t,balance,block.timestamp);
    }

    function _levelJudge(uint amount, SmartPoolManager.feeParams memory _feeParams) internal pure returns (uint) {
        if (_feeParams.firstLevel.level <= amount && amount < _feeParams.secondLevel.level) return _feeParams.firstLevel.ratio;
        else if (_feeParams.secondLevel.level <= amount && amount < _feeParams.thirdLevel.level) return _feeParams.secondLevel.ratio;
        else if (_feeParams.thirdLevel.level <= amount && amount < _feeParams.fourLevel.level) return _feeParams.thirdLevel.ratio;
        else if (_feeParams.fourLevel.level <= amount) return _feeParams.fourLevel.ratio;
        return 0;
    }

    function _isClosePool(address pool) internal view returns (bool) {
        return ICRPPool(pool).etype() == ICRPPool.Etypes.CLOSED;
    }

    function _computeKolTotalReward(
        address pool,
        address kol,
        uint types,
        uint tokenIndex
    ) internal view returns (uint totalFee) {
        uint kolTotalAmount = kolTotalAmountList[pool][kol].length > 0 ? kolTotalAmountList[pool][kol][0] : 0;
        SmartPoolManager.KolPoolParams memory params = poolsStatus[pool].kolPoolConfig;

        PoolTokens memory tokens = poolsTokens[pool];

        if(kolTotalAmount == 0 || tokens.tokenList.length == 0) return 0;

        uint allKolTotalAmount = poolInviteTotal[pool];
        if (types == 0) totalFee = tokens.managerAmount[tokenIndex].mul(_levelJudge(kolTotalAmount, params.managerFee)).div(RATIO_BASE);
        else if (types == 1) totalFee = tokens.issueAmount[tokenIndex].mul(_levelJudge(kolTotalAmount, params.issueFee)).div(RATIO_BASE);
        else if (types == 2) totalFee = tokens.redeemAmount[tokenIndex].mul(_levelJudge(kolTotalAmount, params.redeemFee)).div(RATIO_BASE);
        else if (types == 3) totalFee = tokens.perfermanceAmount[tokenIndex].mul(_levelJudge(kolTotalAmount, params.perfermanceFee)).div(RATIO_BASE);
        
        return totalFee.mul(kolTotalAmount).div(allKolTotalAmount);
    }

    modifier onlyCrpFactory() {
        require(address(crpFactory) == msg.sender, "ERR_NOT_CRP_FACTORY");
        _;
    }

    modifier onlyVault() {
        require(vaultAddress == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }
}