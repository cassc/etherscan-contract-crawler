pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20.sol";
import "../openzeppelin/Ownable.sol";
import "../interfaces/IDSProxy.sol";
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
}

interface IDesynOwnable {
    function adminList(address adr) external view returns (bool);
    function getController() external view returns (address);
    function getOwners() external view returns (address[] memory);
    function getOwnerPercentage() external view returns (uint[] memory);
    function allOwnerPercentage() external view returns (uint);
}

interface IUserVault {
    function depositToken(
        address pool,
        uint types,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external;
}

interface ICRPFactory {
    function isCrp(address addr) external view returns (bool);
}

/**
 * @author Desyn Labs
 * @title Vault managerFee
 */
contract Vault is Ownable, Logs {
    using SafeMath for uint;
    using Address for address;
    using SafeERC20 for IERC20;

    ICRPFactory crpFactory;
    address public userVault;

    event ManagersClaim(address indexed caller,address indexed pool, address token, uint amount, uint time);
    event ManagerClaim(address indexed caller, address indexed pool, address indexed manager, address token, uint amount, uint time);

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
    }
    
    struct ClaimTokens {
        address[] tokens;
        uint[] amounts;
    }

    // pool tokens
    mapping(address => PoolTokens) poolsTokens;
    mapping(address => PoolStatus) public poolsStatus;

    mapping (address => ClaimTokens) manageHasClaimed;

    // default ratio config
    uint public TOTAL_RATIO = 1000;
    uint public management_portion = 800;
    uint public issuance_portion = 800;
    uint public redemption_portion = 800;
    uint public performance_portion = 800;

    receive() external payable {}

    function depositManagerToken(address[] calldata tokensIn, uint[] calldata amountsIn) external {
        address pool = msg.sender;
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(tokensIn.length == amountsIn.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        _depositTokenIM(0, pool, tokensIn, amountsIn);

        poolsStatus[pool].couldManagerClaim = true;
        
        if (_isClosePool(pool)) managerClaim(pool);
    }

    function depositIssueRedeemPToken(
        address[] calldata tokensIn,
        uint[] calldata amountsIn,
        uint[] calldata tokensAmountIR,
        bool isPerfermance
    ) external {
        address pool = msg.sender;
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(tokensIn.length == amountsIn.length, "ERR_TOKEN_LENGTH_NOT_MATCH");

        isPerfermance
                // I-issuce； M-mamager； R-redeem；p-performance
                ? _depositTokenRP(pool, tokensIn, amountsIn, tokensAmountIR)
                : _depositTokenIM(1, pool, tokensIn, amountsIn);

        poolsStatus[pool].couldManagerClaim = true;

        if (_isClosePool(pool)) managerClaim(pool);   
    }

    function getManagerClaimBool(address pool) external view returns (bool) {
        return poolsStatus[pool].couldManagerClaim;
    }

    function setBlackList(address pool, bool bools) external onlyOwner _logs_ {
        poolsStatus[pool].isBlackList = bools;
    }

    function setUserVaultAdr(address adr) external onlyOwner _logs_ {
        require(adr != address(0), "ERR_INVALID_USERVAULT_ADDRESS");
        userVault = adr;
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

    function setManagerRatio(uint amount) external onlyOwner _logs_ {
        require(amount <= TOTAL_RATIO, "Maximum limit exceeded");
        management_portion = amount;
    }

    function setIssueRatio(uint amount) external onlyOwner _logs_ {
        require(amount <= TOTAL_RATIO, "Maximum limit exceeded");
        issuance_portion = amount;
    }

    function setRedeemRatio(uint amount) external onlyOwner _logs_ {
        require(amount <= TOTAL_RATIO, "Maximum limit exceeded");
        redemption_portion = amount;
    }

    function setPerfermanceRatio(uint amount) external onlyOwner _logs_{
        performance_portion = amount;
    }

    function managerClaim(address pool) public {
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        address managerAddr = ICRPPool(pool).getController();

        PoolTokens memory tokens = poolsTokens[pool];
        PoolStatus storage status = poolsStatus[pool];
        bool isCloseETF = _isClosePool(pool);

        address[] memory poolManageTokens = tokens.tokenList;
        uint len = poolManageTokens.length;
        require(!status.isBlackList, "ERR_POOL_IS_BLACKLIST");
        require(len > 0, "ERR_NOT_MANGER_FEE");
        require(status.couldManagerClaim, "ERR_MANAGER_COULD_NOT_CLAIM");
        status.couldManagerClaim = false;

        uint[] memory managerTokenAmount = new uint[](len);
        uint[] memory issueTokenAmount = new uint[](len);
        uint[] memory redeemTokenAmount = new uint[](len);
        uint[] memory perfermanceTokenAmount = new uint[](len);

        for (uint i; i < len; i++) {
            address t = poolManageTokens[i];
            uint b;
            (b, managerTokenAmount[i], issueTokenAmount[i], redeemTokenAmount[i], perfermanceTokenAmount[i]) = _computeBalance(i, pool);
            if(!isCloseETF) b = b.sub(_getManagerHasClaimed(pool,t));
            if(b != 0) _transferHandle(pool, managerAddr, t, b);
        }
        
        if (isCloseETF) {
            _recordUserVault(pool, poolManageTokens, managerTokenAmount, issueTokenAmount, redeemTokenAmount, perfermanceTokenAmount);
            _clearPool(pool);
        }   
    }

    function getManagerFeeTypes(address pool) external view returns(PoolTokens memory result){     
        PoolTokens memory tokens = poolsTokens[pool];
        address[] memory poolManageTokens = tokens.tokenList;
        uint len = poolManageTokens.length;

        result.tokenList = tokens.tokenList;
        result.managerAmount = new uint[](len);
        result.issueAmount = new uint[](len);
        result.redeemAmount = new uint[](len);
        result.perfermanceAmount = new uint[](len);

        for(uint i; i< len; i++){
            (,result.managerAmount[i],result.issueAmount[i],result.redeemAmount[i],result.perfermanceAmount[i]) = _computeBalance(i,pool);
        }
    }

    function getUnManagerReward(address pool) external view returns (address[] memory tokensList, uint[] memory amounts) {
        PoolTokens memory tokens = poolsTokens[pool];
        address[] memory poolManageTokens = tokens.tokenList;
        uint len = poolManageTokens.length;

        tokensList = new address[](len);
        amounts = new uint[](len);

        for (uint i; i < len; i++) {
            address t = poolManageTokens[i];
            tokensList[i] = t;
            (amounts[i],,,,) = _computeBalance(i,pool);
            amounts[i] = amounts[i].sub(_getManagerHasClaimed(pool, t));
        }
    }

    function _addTokenInPool(address pool, address tokenAddr) internal {
        PoolTokens storage tokens = poolsTokens[pool];

        tokens.tokenList.push(tokenAddr);
        tokens.managerAmount.push(0);
        tokens.issueAmount.push(0);
        tokens.redeemAmount.push(0);
        tokens.perfermanceAmount.push(0);
    }
    // for old token
    function _updateTokenAmountInPool(uint types, address pool, uint tokenIndex, uint amount) internal {
        PoolTokens storage tokens = poolsTokens[pool];

        if(types == 0) tokens.managerAmount[tokenIndex] = tokens.managerAmount[tokenIndex].add(amount);
        else if(types == 1) tokens.issueAmount[tokenIndex] = tokens.issueAmount[tokenIndex].add(amount);
        else if(types == 2) tokens.redeemAmount[tokenIndex] = tokens.redeemAmount[tokenIndex].add(amount);
        else if(types == 3) tokens.perfermanceAmount[tokenIndex] = tokens.perfermanceAmount[tokenIndex].add(amount);
    }
    // for new token
    function _updateTokenAmountInPool(uint types, address pool, uint amount) internal {
        PoolTokens storage tokens = poolsTokens[pool];
        uint tokenIndex = tokens.tokenList.length - 1;

        if(types == 0) tokens.managerAmount[tokenIndex] = amount;
        else if(types == 1) tokens.issueAmount[tokenIndex] = amount;
        else if(types == 2) tokens.redeemAmount[tokenIndex] = amount;
        else if(types == 3) tokens.perfermanceAmount[tokenIndex] = amount;
    }

    function _depositTokenIM(
        uint types,
        address pool,
        address[] memory tokensIn,
        uint[] memory amountsIn
    ) internal {
        PoolTokens memory tokens = poolsTokens[pool];

        uint len = tokensIn.length;
        for (uint i; i < len; i++) {
            address t = tokensIn[i];
            uint b = amountsIn[i];

            IERC20(t).safeTransferFrom(msg.sender, address(this), b);
            (bool isExit, uint index) = _arrIncludeAddr(tokens.tokenList,t);
            if (isExit) {
                _updateTokenAmountInPool(types,pool,index,b);
            } else { 
                _addTokenInPool(pool,t); 
                _updateTokenAmountInPool(types,pool,b);    
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

    function _depositTokenRP(
        address pool,
        address[] calldata tokenIns,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountIR
    ) internal {
        address[] memory tokenList = poolsTokens[pool].tokenList;

        uint len = tokensAmount.length;
        for (uint i; i < len; i++) {
            address t = tokenIns[i];
            uint b = tokensAmount[i];
            // uint bIR = tokensAmountIR[i];
            IERC20(t).safeTransferFrom(msg.sender, address(this), b);

            (bool isExit,uint index) = _arrIncludeAddr(tokenList, t);
            if(isExit){
                _updateTokenAmountInPool(2, pool, index, tokensAmountIR[i]);
                _updateTokenAmountInPool(3, pool, index, b.sub(tokensAmountIR[i]));
            } else {
                _addTokenInPool(pool, t);
                _updateTokenAmountInPool(2,pool, tokensAmountIR[i]);
                _updateTokenAmountInPool(3, pool,b.sub(tokensAmountIR[i]));        
            }
        }
    }

    function _isClosePool(address pool) internal view returns (bool) {
        return ICRPPool(pool).etype() == ICRPPool.Etypes.CLOSED;
    }

    function _computeBalance(uint i, address pool)
        internal
        view
        returns (
            uint balance,
            uint bManagerAmount,
            uint bIssueAmount,
            uint bRedeemAmount,
            uint bPerfermanceAmount
        )
    {
        PoolTokens memory tokens = poolsTokens[pool];

        if (tokens.tokenList.length != 0) {
            bManagerAmount = tokens.managerAmount[i].mul(management_portion).div(TOTAL_RATIO);
            bIssueAmount = tokens.issueAmount[i].mul(issuance_portion).div(TOTAL_RATIO);
            bRedeemAmount = tokens.redeemAmount[i].mul(redemption_portion).div(TOTAL_RATIO);
            bPerfermanceAmount = tokens.perfermanceAmount[i].mul(performance_portion).div(TOTAL_RATIO);

            balance = bManagerAmount.add(bIssueAmount).add(bRedeemAmount).add(bPerfermanceAmount);
        }
    }

    function _clearPool(address pool) internal {
        delete poolsTokens[pool];
    }

    function _recordUserVault(
        address pool,
        address[] memory tokenList,
        uint[] memory managerTokenAmount,
        uint[] memory issueTokenAmount,
        uint[] memory redeemTokenAmount,
        uint[] memory perfermanceTokenAmount
    ) internal {
        if (tokenList.length != 0) {
            IUserVault(userVault).depositToken(pool, 0, tokenList, managerTokenAmount);
            IUserVault(userVault).depositToken(pool, 1, tokenList, issueTokenAmount);
            IUserVault(userVault).depositToken(pool, 2, tokenList, redeemTokenAmount);
            IUserVault(userVault).depositToken(pool, 3, tokenList, perfermanceTokenAmount);
        }

    }

    function _transferHandle(
        address pool,
        address managerAddr,
        address t,
        uint balance
    ) internal {
        require(balance != 0, "ERR_ILLEGAL_BALANCE");
        bool isCloseETF = _isClosePool(pool);
        bool isOpenETF = !isCloseETF;

        if(isCloseETF){
            IERC20(t).safeTransfer(userVault, balance);
        }

        // if(isOpenETF && isContractManager){
        if(isOpenETF) {
            address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
            uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
            uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();

            for (uint k; k < managerAddressList.length; k++) {
                address reciver = address(managerAddressList[k]).isContract()? IDSProxy(managerAddressList[k]).owner(): managerAddressList[k];
                uint b = balance.mul(ownerPercentage[k]).div(allOwnerPercentage);
                IERC20(t).safeTransfer(reciver, b);
                emit ManagerClaim(msg.sender, pool, reciver,t,b,block.timestamp);
            }
            _updateManageHasClaimed(pool,t,balance);
            emit ManagersClaim(msg.sender, pool, t, balance, block.timestamp);
        }
    }

    function _updateManageHasClaimed(address pool, address token, uint amount) internal {
        ClaimTokens storage claimInfo = manageHasClaimed[pool];
        (bool isExit, uint index) = _arrIncludeAddr(claimInfo.tokens, token);

        if(isExit){
            claimInfo.amounts[index] = claimInfo.amounts[index].add(amount);
        } else{
            claimInfo.tokens.push(token);
            claimInfo.amounts.push(amount);
        }
    }

    function _getManagerHasClaimed(address pool, address token) internal view returns(uint){
        require(!_isClosePool(pool),"ERR_NOT_OPEN_POOL");

        ClaimTokens memory claimInfo = manageHasClaimed[pool];
        (bool isExit,uint index) = _arrIncludeAddr(claimInfo.tokens, token);

        if(isExit) return claimInfo.amounts[index];
        if(!isExit) return 0;
    }
}