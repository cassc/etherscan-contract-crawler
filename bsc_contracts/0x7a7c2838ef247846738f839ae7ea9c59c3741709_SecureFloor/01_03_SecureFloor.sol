// Copyright (c) [2023], [Qwantum Finance Labs]
// All rights reserved.
// SPDX-License-Identifier: No License (None)
pragma solidity 0.8.18;

import "./IERC3475.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    /*
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    */

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);    
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    // Derex functions
    // Create pair with options 
    function createPair(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB,
        address to,
        uint32[8] memory vars, 
        bool isPrivate, // is private pool
        address protectedToken, // which token should be protected by secure floor, if address(0) then without secure floor        
        uint32[2] memory voteVars // [0] - voting delay, [1] - minimal level for proposal in percentage with 2 decimals i.e. 100 = 1%
    ) external returns (uint liquidity);

    function createPairETH(
        address token,
        uint amountToken,
        address to,
        uint32[8] memory vars, 
        bool isPrivate, // is private pool
        address protectedToken, // which token should be protected by secure floor, if address(0) then without secure floor        
        uint32[2] memory voteVars // [0] - voting delay, [1] - minimal level for proposal in percentage with 2 decimals i.e. 100 = 1%
    ) external payable returns (uint liquidity);    
}

interface IDexFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDexPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IDumperShield {
    // Deposit tokens to user's address into Dumper Shield. Should be called approve() before deposit.
    function deposit(
        address token,
        uint256 amount,
        address user
    ) external returns (bool);

    function dumperShieldTokens(address token) external returns(address);

    // Create Dumper Shield for new token
    function createDumperShield(
        address token,  // token contract address
        address router, // Uniswap compatible AMM router address where exist Token <> WETH pair
        uint256 unlockDate, // Epoch time (in second) when tokens will be unlocked
        address dao         // Address of token's voting contract if exist. Otherwise = address(0).
    ) external;
}

interface IPDOCreator {
    // tokens should be approved before calling this function
    // additional info can be received from IBO.parameters(uint256 classId, uint256 nonceId) external returns (Parameters)
    function createPDO(address token, uint256 amount, uint256 classId, uint256 nonceId) external;
}

contract SecureFloor is Ownable {
    using TransferHelper for address;

    address constant public BURN_ADDRESS = address(0xdEad000000000000000000000000000000000000);

    // default vars for Derex poo creation
    uint32[8] private _vars; // timeFrame, maxDump0, maxDump1, maxTxDump0, maxTxDump1, coefficient, minimalFee, periodMA
    //timeFrame = 1 days;  // during this time frame rate of reserve1/reserve0 should be in range [baseLinePrice0*(1-maxDump0), baseLinePrice0*(1+maxDump1)]
    //maxDump0 = 10000;   // maximum allowed dump (in percentage with 2 decimals) of reserve1/reserve0 rate during time frame relatively the baseline
    //maxDump1 = 10000;   // maximum allowed dump (in percentage with 2 decimals) of reserve0/reserve1 rate during time frame relatively the baseline
    //maxTxDump0 = 10000; // maximum allowed dump (in percentage with 2 decimals) of token0 price per transaction
    //maxTxDump1 = 10000; // maximum allowed dump (in percentage with 2 decimals) of token1 price per transaction
    //coefficient = 10000; // coefficient (in percentage with 2 decimals) to transform price growing into fee. ie
    //minimalFee = 5;   // Minimal fee percentage (with 2 decimals) applied to transaction. I.e. 5 = 0.05%
    //periodMA = 45 minutes;  // MA period in seconds
    uint32[2] private _voteVars;

    address public derexRouter;
    address public bondContract;

    mapping(uint256 => uint256) feeByType;  // feeType => fee % with 2 decimals (i.e. 500 = 5%)

    struct FeeParams {
        uint8 feeType;  // 0 - free, 1 - 5% to DumperShield, 2 - 10% into PDO
        // DumperShield params
        address router; // dex router where exist pool "token-WETH" (token to native coin)
        uint64 dsReleaseTime;   // Epoch time (in seconds) when tokens will be unlocked in dumper shield. 0 if no DS needed
        // PDO params
        uint64 stakingPeriod; // number of days (0 means no staking)
        uint64 stakingAPY; // the percentage of APY with 4 decimals
        address licensee; //    Licensee address who bring the client (0 if no licensee)
    }

    struct VestingParams {
        // vesting principal
        uint64 cliffDate;   // epoch timestamp of cliff date (in seconds), if there isn't cliff then 0
        // vesting profits
        uint64 cliffProfitDate;   // epoch timestamp of cliff date (in seconds), if there isn't cliff then 0
        uint32 prepaymentPenalty;   // percentage of initial penalty. During the time penalty will decrease
    }

    struct Parameters {
        // step 1
        address token;  //  project token
        address pairToken;  // token that should be paid by users to add pool liquidity. Address(1) if native coin (BNB)
        //address dexRouter;  // address of DEX router where is pool "token-pairToken". If 0, then create new pool with secure floor
        uint64  startDate;  // Epoch time (in seconds) when IBO will be started.
        uint64  endDate;    // Epoch time (in seconds) when IBO will be closed.
        bool leftoverBurn;  // if true - burn leftover, false - return to project
        // step 2
        VestingParams vestingParams;
        // step 3
        uint256 supplyAmount;  // amount of tokens that project supply
        uint256 targetAmount;  // amount of pairTokens, used to calculate ratio for addLiquidity (supplyAmount:targetAmount)
        FeeParams feeParams;
        // limits
        uint256 minInvestment; // min investment in "pairToken"
        uint256 maxInvestment; // max investment in "pairToken"
    }

    struct PoolParams {
        address poolAddress;
        address projectWallet;
        uint256 spentTokens;
        uint256 totalRaisedPairTokens;  // amount of pair tokens received during IBO
        uint256 fee;    //  reserved amount of fee
        address bondContract;   // bond contract that was used on creation.
        bool isClosed;  // true is IBO is closed
        bool isCoin;    // true if pairToken is native coin (BNB, ETH, etc)
    }

    mapping(uint256 => mapping(uint256 => Parameters)) public parameters; // classId => nonceId => Parameters
    mapping(uint256 => mapping(uint256 => PoolParams)) public poolParams; // classId => nonceId => poolParams

    //farming
    uint256 maxFarms;
    IDumperShield public dumperShield;    // Dumper Shield contract
    IPDOCreator public PDOCreator;  // contract which create PDO

    struct Rewarads {
        uint256 classId;
        uint256 farmId;
        address rewardToken;    // address of reward token
        uint256 amount;         // amount of reward token available for harvesting
    }

    struct Farm {
        address rewardToken;    // address of reward token
        bool toDumperShield;    // if true, rewards will be send to the DumperShield
        uint256 baseRewardPerToken; // base value of rewardPerToken on moment of farm creation
        uint256 rewardPerSecond;    // value of reward's token to split per second
        uint256 endDate;    // end date (timestamp) of farming
        uint256 endRewardPerToken; // value of rewardPerToken on the moment of end farming
        address owner;  // address of farm creator
    }

    mapping(uint256 => Farm[]) public farms; // classID (token) => Farming
    mapping(uint256 => mapping(uint256 => mapping(address => uint256))) public userFarmBalance; // classId => farmId => user address => userFarmBalance

    event AddFarm(
        uint256 classId, // bond class id (project token address) which participate in farming
        uint256 farmId, // farm Id for this class Id
        address token,  // reward token
        uint256 amount, // amount of tokens for reward
        uint256 period, // time period (in second) while rewards will be split
        bool toDumperShield // transfer rewards to the Dumper Shield
    );

    event DecreaseFarmPeriod(
        uint256 classId, // bond class id (project token address) which participate in farming
        uint256 farmId, // farm Id for this class Id
        uint256 decreaseTime, 
        address owner,  // address of farm creator
        address token,  // reward token
        uint256 change  // amount of tokens return to owner
    );

    event CreateOffer(address creator, Parameters p, PoolParams pp, uint256 classId, uint256 nonceId);
    event CloseOffer(uint256 classId, uint256 nonceId, uint256 leftover);
    event BuyBond(address buyer, uint256 classId, uint256 nonceId, uint256 bondAmounts, PoolParams pp);
    event WithdrawProjectTokens(uint256 classId, uint256 nonceId, uint256 amount);
    event AddProjectTokens(uint256 classId, uint256 nonceId, uint256 amount);
    event Deposit(address user, uint256 amount);


    function initialize(address _derexRouter, address _bondContract, address _dumperShield) public {
        require(_owner == address(0));
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        _vars = [1 days, 10000, 10000, 0, 0, 10000, 5, 45 minutes]; // disable swapping
        _voteVars = [uint32(1 days), 100]; // 1% to create ballot
        feeByType[1] = 500;  // 1 - 5% to DumperShield
        feeByType[2] = 1000; // 2 - 10% into PDO
        dumperShield = IDumperShield(_dumperShield);
        bondContract = _bondContract;
        derexRouter = _derexRouter;
        
        IERC3475(_bondContract).initDerex(_derexRouter);
        //super.initialize();
    }

    function createOffer(Parameters calldata p) external payable returns(uint256 classId, uint256 nonceId) {
        require(block.timestamp < p.startDate && p.startDate < p.endDate, "date error");
        uint256 liquidity;
        uint256 price;
        // create pool with secure floor
        {
        IERC3475.BondParameters memory params;
        uint256 oneToken = 10**(IERC20(p.token).decimals()); // one token with decimals
        {
        p.token.safeTransferFrom(msg.sender, address(this), p.supplyAmount);
        require(oneToken * 2 <= p.supplyAmount, "Not enough tokens"); // minimum 2 tokens required
        p.token.safeApprove(derexRouter, type(uint256).max);    // approve maximum amount at once
        price = p.targetAmount * oneToken / p.supplyAmount;
        if (p.pairToken == address(1)) {
            require(msg.value == price, "wrong msg.value");
            // create private pool
            liquidity = IRouter(derexRouter).createPairETH{value: price}(p.token, oneToken, address(this), _vars, true, p.token, _voteVars);
            params.pairToken = IRouter(derexRouter).WETH();
        } else {
            params.pairToken = p.pairToken;
            p.pairToken.safeTransferFrom(msg.sender, address(this), price);
            p.pairToken.safeApprove(derexRouter, price);
            {
            // create private pool
            liquidity = IRouter(derexRouter).createPair(p.token, p.pairToken, oneToken, price, address(this), _vars, true, p.token, _voteVars);
            }
        }
        }
        params.LPToken = IDexFactory(IRouter(derexRouter).factory()).getPair(p.token, params.pairToken);
        if (!p.leftoverBurn) params.projectWallet = msg.sender;
        params.issuanceDate = p.endDate;
        params.prepaymentPenalty = p.vestingParams.prepaymentPenalty;
        params.maturityDate = p.vestingParams.cliffDate;
        params.maturityProfitDate = p.vestingParams.cliffProfitDate;
        // get classId and nonceId
        (classId, nonceId) = IERC3475(bondContract).createBond(p.token, params);
        poolParams[classId][nonceId].spentTokens = oneToken;
        poolParams[classId][nonceId].poolAddress = params.LPToken;
        poolParams[classId][nonceId].projectWallet = msg.sender;
        poolParams[classId][nonceId].bondContract = bondContract;
        uint256 fee = p.supplyAmount * feeByType[uint256(p.feeParams.feeType)] / 10000;
        poolParams[classId][nonceId].fee = fee;
        parameters[classId][nonceId] = p;
        if (p.pairToken == address(1)) {
            parameters[classId][nonceId].pairToken = params.pairToken;
            poolParams[classId][nonceId].isCoin = true;
        }
        if (fee != 0) parameters[classId][nonceId].supplyAmount -=  fee;    // reduce supply by fee
        // issue bond to creator
        liquidity--;   // left 1 wei of token to be able addLiquidity to private pool
        params.LPToken.safeTransfer(bondContract, liquidity);
        }
        {
        // create DumperShield
        if (p.feeParams.feeType == 1) createDumperShield(p.token, p.feeParams.router, p.feeParams.dsReleaseTime);
        //IERC3475.Transaction[] memory _transaction = IERC3475.Transaction(classId, nonceId, liquidity);
        IERC3475(bondContract).issue(msg.sender, price, IERC3475.Transaction(classId, nonceId, liquidity));
        }
        emit CreateOffer(msg.sender, p, poolParams[classId][nonceId], classId, nonceId);
    }
    
    // Close IBO and open pool for trading. Should be called when IBO is over
    function closeOffer(uint256 classId, uint256 nonceId) external {
        Parameters storage p = parameters[classId][nonceId];
        PoolParams storage pp = poolParams[classId][nonceId];
        require(block.timestamp > p.endDate, "IBO opened");
        require(!pp.isClosed, "Already closed");
        uint256 leftover = p.supplyAmount - pp.spentTokens;
        address projectToken = p.token;
        if (leftover != 0) {
            if (p.leftoverBurn)
                projectToken.safeTransfer(BURN_ADDRESS, leftover);   // burn
            else
                projectToken.safeTransfer(pp.projectWallet, leftover); // return to project
        }
        if (p.feeParams.feeType == 1) { // transfer fee to the DumperShield to the owner address
            projectToken.safeApprove(address(dumperShield), pp.fee);
            dumperShield.deposit(projectToken, pp.fee, owner());
        } else if (p.feeParams.feeType == 2) {  // transfer fee to the PDO
            projectToken.safeApprove(address(PDOCreator), pp.fee);
            PDOCreator.createPDO(projectToken, pp.fee, classId, nonceId);
        }
        IERC3475(pp.bondContract).unlockPool(classId, nonceId);
        pp.isClosed = true;
        emit CloseOffer(classId, nonceId, leftover);
    }

    // Get max amount of available tokens and max amount that user can pay
    function getMaxAmount(uint256 classId, uint256 nonceId) external view returns (uint256 maxPayAmount, uint256 maxTokenAmount) {
        Parameters storage p = parameters[classId][nonceId];
        PoolParams storage pp = poolParams[classId][nonceId];
        address pairToken = p.pairToken;
        (uint256 money, uint256 tokens) = getReserves(pairToken, p.token, pp.poolAddress);
        maxTokenAmount = p.supplyAmount - pp.spentTokens;
        maxPayAmount = quote(maxTokenAmount, tokens, money);
        if (block.timestamp < p.startDate && block.timestamp > p.endDate) maxPayAmount = 0; // if offer closed then maxPayAmount = 0
        if (p.maxInvestment != 0 && p.maxInvestment < maxPayAmount) maxPayAmount = p.maxInvestment; // maxPayAmount <= maxInvestment
    }
   
    // Buy bond
    function buyBond(uint256 classId, uint256 nonceId, uint256 payAmount) external payable {
        Parameters storage p = parameters[classId][nonceId];
        PoolParams storage pp = poolParams[classId][nonceId];
        require(block.timestamp >= p.startDate && block.timestamp <= p.endDate, "IBO is not opened");
        require(p.minInvestment <= payAmount && (p.maxInvestment == 0 || p.maxInvestment >= payAmount), "investment out of range");
        address pairToken = p.pairToken;

        (uint256 money, uint256 tokens) = getReserves(pairToken, p.token, pp.poolAddress);
        uint256 tokenAmount = quote(payAmount, money, tokens);
        if(pp.spentTokens + tokenAmount > p.supplyAmount) { // not enough supply
            tokenAmount = p.supplyAmount - pp.spentTokens;
            if (tokenAmount != 0)
                payAmount = quote(tokenAmount, tokens, money);
        }
        pp.spentTokens += tokenAmount;
        //p.token.safeApprove(derexRouter, tokenAmount); // tokens already approved in function createOffer
        uint256 bondAmounts;
        if (pp.isCoin) {
            emit Deposit(msg.sender, msg.value);
            require(msg.value >= payAmount, "wrong msg.value");
            if (msg.value > payAmount) {
                msg.sender.safeTransferETH(msg.value - payAmount);  // return the rest
            }
            (,,bondAmounts) = IRouter(derexRouter).addLiquidityETH{value: payAmount}(p.token, tokenAmount, 0, 0, bondContract, block.timestamp);
        } else {
            pairToken.safeTransferFrom(msg.sender, address(this), payAmount);
            pairToken.safeApprove(derexRouter, payAmount);
            (,,bondAmounts) = IRouter(derexRouter).addLiquidity(p.token, pairToken, tokenAmount, payAmount, 0, 0, bondContract, block.timestamp);
        }
        pp.totalRaisedPairTokens += payAmount;
        // issue bond to buyer
        {
        //IERC3475.Transaction memory _transaction = IERC3475.Transaction(classId, nonceId, bondAmounts);
        IERC3475(pp.bondContract).issue(msg.sender, payAmount, IERC3475.Transaction(classId, nonceId, bondAmounts));
        }
        emit BuyBond(msg.sender, classId, nonceId, bondAmounts, pp);
    }

    // update farming data for user
    function updateFarming(
        uint256 classId,
        address user,
        uint256 userBalance, 
        uint256 userRewardPerTokenPaid, 
        uint256 rewardPerTokenStored, 
        uint256 totalBonds
    ) external {
        require(msg.sender == bondContract, "Only bond contract");
        Farm[] storage f = farms[classId];
        uint len = f.length;
        for (uint i = 0; i < len; i++){
            uint256 userRewardPerToken = userRewardPerTokenPaid < f[i].baseRewardPerToken ? f[i].baseRewardPerToken : userRewardPerTokenPaid;
            if(block.timestamp > f[i].endDate) {    // farming is over
                uint256 endRewardPerToken = f[i].endRewardPerToken; // value of rewardPerToken on the moment of end farming
                if (endRewardPerToken == 0) {
                    uint256 timePassed = block.timestamp - f[i].endDate;
                    endRewardPerToken = rewardPerTokenStored - (timePassed * 1e36 / totalBonds);
                    f[i].endRewardPerToken = endRewardPerToken;
                }
                if (userRewardPerToken >= endRewardPerToken) continue;   // no rewards in this farming
                userRewardPerToken = endRewardPerToken - userRewardPerToken;
            } else {
                userRewardPerToken = rewardPerTokenStored - userRewardPerToken;
            }
            uint256 reward = userRewardPerToken * userBalance * f[i].rewardPerSecond / 1e36;
            userFarmBalance[classId][i][user] += reward;
        }
    }

    // harvest all rewards from farms of specific classIds
    function harvest(
        uint256[] memory classIds   // classes to harvest rewards from
    ) external {
        for (uint i = 0; i < classIds.length; i++) {
            IERC3475(bondContract).updateFarming(classIds[i], msg.sender);
            Farm[] storage f = farms[classIds[i]];
            uint len = f.length;
            for (uint j = 0; j < len; j++) {
                uint256 reward = userFarmBalance[classIds[i]][j][msg.sender];
                if(reward != 0) {
                    userFarmBalance[classIds[i]][j][msg.sender] = 0;
                    if (f[j].toDumperShield)
                        dumperShield.deposit(f[j].rewardToken, reward, msg.sender);
                    else 
                        f[j].rewardToken.safeTransfer(msg.sender, reward);
                }
            }
        }
    }

    // harvest rewards from specific farms of specific classId
    function harvestFarms(
        uint256 classId,    // class to harvest rewards from
        uint256[] memory farmIds   // IDs of farm to harvest from
    ) external {
        IERC3475(bondContract).updateFarming(classId, msg.sender);
        Farm[] storage f = farms[classId];
        uint256 len = f.length;
        for (uint i = 0; i < farmIds.length; i++) {
            uint j = farmIds[i];
            if (j < len) {
                uint256 reward = userFarmBalance[classId][j][msg.sender];
                if(reward != 0) {
                    userFarmBalance[classId][j][msg.sender] = 0;
                    if (f[j].toDumperShield)
                        dumperShield.deposit(f[j].rewardToken, reward, msg.sender);
                    else 
                        f[j].rewardToken.safeTransfer(msg.sender, reward);
                }
            }
        }
    }

    // Get all info about all farms by classId
    function getFarms(uint256 classId) external view returns(Farm[] memory _farms) {
        return farms[classId];
    }

    // Get rewards for user of specific bond classId
    function getRewards(uint256[] memory classIds, address user) external view returns(Rewarads[] memory rewards) {
        uint256 k;
        for (uint i = 0; i < classIds.length; i++) {
            k += farms[classIds[i]].length;
        }
        rewards = new Rewarads[](k);
        k = 0;
  
        for (uint i = 0; i < classIds.length; i++) {
            (uint256 userBalance, uint256 userRewardPerTokenPaid, uint256 rewardPerTokenStored, uint256 totalBonds) =
                IERC3475(bondContract).getFarmingData(classIds[i], user);
            Farm[] storage f = farms[classIds[i]];
            uint len = f.length;
            for (uint j = 0; j < len; j++) {

                uint256 userRewardPerToken = userRewardPerTokenPaid < f[j].baseRewardPerToken ? f[j].baseRewardPerToken : userRewardPerTokenPaid;
                if(block.timestamp > f[j].endDate) {
                    uint256 endRewardPerToken = f[j].endRewardPerToken;
                    if (endRewardPerToken == 0) {
                        uint256 timePassed = block.timestamp - f[j].endDate;
                        endRewardPerToken = rewardPerTokenStored - (timePassed * 1e36 / totalBonds);
                    }
                    if (userRewardPerToken >= endRewardPerToken) continue;   // no rewards in this farming
                    userRewardPerToken = endRewardPerToken - userRewardPerToken;
                } else {
                    userRewardPerToken = rewardPerTokenStored - userRewardPerToken;
                }
                uint256 reward = userRewardPerToken * userBalance * f[j].rewardPerSecond / 1e36;
                reward += userFarmBalance[classIds[i]][j][user];
                rewards[k] = Rewarads(classIds[i], j, f[j].rewardToken, reward);
                k++;
            }
        }
    }

/*
    function testFarms() external {
        uint256 classId = 1;

        Farm[] storage f = farms[classId];
        uint len = f.length;

        for (uint i=len; i<len+10; i++) {
            f.push();
            f[i].endDate = block.timestamp + 100000;
            f[i].rewardPerSecond = (i+1) * (100 ether) / 10 days;
        }

        // issue bond to buyer
        IERC3475.BondParameters memory params;
        params.pairToken = address(2);
        params.LPToken = address(3);
        params.offerId = 100;
        //params.isCoin = p.isCoin;
        params.issuanceDate = block.timestamp;
        params.prepaymentPenalty = 0;
        params.maturityDate = 10 days + block.timestamp;
        params.insurance = 5 ether;
        IERC3475(bondContract).createBond(address(1), msg.sender, 10 ether, params);
    }
*/
    // add farm to class Id
    function addFarm(
        uint256 classId, // bond class id (project token address) which participate in farming
        address token,  // reward token
        uint256 amount, // amount of tokens for reward
        uint256 period, // time period (in second) while rewards will be split
        bool toDumperShield // transfer rewards to the Dumper Shield
    ) 
    external 
    {
        Farm[] storage f = farms[classId];
        uint len = f.length;
        require(len < maxFarms, "max Farms added");
        token.safeTransferFrom(msg.sender, address(this), amount);
        if (toDumperShield) {
            require(
                address(dumperShield) != address(0) &&
                dumperShield.dumperShieldTokens(token) != address(0),
                "dumperShield error"
            );
            token.safeApprove(address(dumperShield), amount);
        }
        (,,uint256 rewardPerTokenStored, uint256 totalBonds) = IERC3475(bondContract).getFarmingData(classId, address(0));
        require(totalBonds != 0, "No bonds");
        f.push();
        f[len].toDumperShield = toDumperShield;
        f[len].endDate = block.timestamp + period;
        f[len].rewardToken = token;
        f[len].rewardPerSecond = amount / period;
        f[len].owner = msg.sender;
        require(f[len].rewardPerSecond != 0, "too small amount");
        f[len].baseRewardPerToken = rewardPerTokenStored;
        emit AddFarm(classId, len, token, amount, period, toDumperShield);
    }

    // Allow farm's owner to decrease farming period, the change of tokens returns to farm's owner
    function decreaseFarmPeriod(
        uint256 classId, // bond class id (project token address) which participate in farming
        uint256 farmId,  // farm Id
        uint256 decreaseTime // time period (in second) to decrease farming by
    ) 
    external 
    {
        Farm[] storage f = farms[classId];
        require(f.length > farmId, "wrong farmId");
        require(f[farmId].owner == msg.sender, "only farm owner");
        uint256 endDate = f[farmId].endDate - decreaseTime;
        require(endDate > block.timestamp, "endDate should be in future");
        f[farmId].endDate = endDate; // set new endDate
        uint256 change = decreaseTime * f[farmId].rewardPerSecond;
        address token = f[farmId].rewardToken;
        token.safeTransfer(msg.sender, change);
        emit DecreaseFarmPeriod(classId, farmId, decreaseTime, msg.sender, token, change);
    }

    receive() external payable {
        require(msg.sender == derexRouter); // only rest from DEREX router is acceptable
    }

    // Allow project wallet withdraw unspent tokens
    function withdrawProjectTokens(uint256 classId, uint256 nonceId, uint256 amount) external {
        Parameters storage p = parameters[classId][nonceId];
        PoolParams storage pp = poolParams[classId][nonceId];
        require(msg.sender == pp.projectWallet, "Only bond creator can withdraw");
        require(amount <= p.supplyAmount - pp.spentTokens, "Not enough supply");
        p.token.safeTransfer(msg.sender, amount);
        p.supplyAmount -= amount;
        emit WithdrawProjectTokens(classId, nonceId, amount);
    }

    // Allow project wallet to add more tokens to supply
    function addProjectTokens(uint256 classId, uint256 nonceId, uint256 amount) external {
        Parameters storage p = parameters[classId][nonceId];
        PoolParams storage pp = poolParams[classId][nonceId];
        p.token.safeTransferFrom(msg.sender, address(this), amount);
        uint256 fee = amount * feeByType[uint256(p.feeParams.feeType)] / 10000;
        pp.fee += fee;
        p.supplyAmount += (amount - fee);
        emit AddProjectTokens(classId, nonceId, amount);
    }

    function setDumperShield(address _dumperShield) external onlyOwner {
        dumperShield = IDumperShield(_dumperShield);
    }

    function setPDOCreator(address _PDOCreator) external onlyOwner {
        PDOCreator = IPDOCreator(_PDOCreator);
    }

    function setDerex(address _derexRouter) external onlyOwner {
        derexRouter = _derexRouter;
        IERC3475(bondContract).initDerex(_derexRouter);
    }

    function setDerexVars(uint32[8] calldata _derexVars) external onlyOwner {
        _vars = _derexVars;
    }

    function getDerexVars() external view returns(uint32[8] memory) {
        return _vars;
    }

    function setDerexVoteVars(uint32[2] calldata _derexVoteVars) external onlyOwner {
        _voteVars = _derexVoteVars;
    }

    function getDerexVoteVars() external view returns(uint32[2] memory) {
        return _voteVars;
    }

    function setBondContract(address _bondContract) external onlyOwner {
        require(_bondContract != address(0));
        bondContract = _bondContract;
    }
    
    // set fee in % (with 2 decimals) of specific IBO type. For example, fee 100 = 1%
    function setFeeByType(uint256 _type, uint256 _fee) external onlyOwner {
        require(_type <= 2 && _fee < 10000);
        feeByType[_type] = _fee;
    }


    function createDumperShield(address token, address router, uint256 unlockDate) internal {
        require(address(dumperShield) != address(0), "No dumperShield");
        if (dumperShield.dumperShieldTokens(token) == address(0)) 
            dumperShield.createDumperShield(token, router, unlockDate, address(0));
    }

    // =================== Router Library ===================
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }


    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, address pair) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IDexPair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }
}
