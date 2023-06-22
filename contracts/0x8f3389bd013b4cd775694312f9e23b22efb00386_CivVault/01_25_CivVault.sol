// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import "./interfaces/ICivFund.sol";
import './libraries/FixedPoint.sol';
import './libraries/UniswapV2OracleLibrary.sol';

/// @title  Civ Vault
/// @author Ren


contract CivVault is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ICivFundRT;
    using FixedPoint for *;

    /// @notice Guarantee Fee Amount
    uint256 public guarantee_fee = 1000; //10% of $ value equivalent, expressed in bps
    /// @notice Fee Base Amount(Fee calculated like this guarantee_fee / feeBase)
    uint256 public constant feeBase = 10000;
    /// @notice Dead Address
    address public constant NULL_ADDRESS = 0x0000000000000000000000000000000000000000;

    struct UserInfo {
        uint256 startingEpoch;         // Starting Epoch of guarantee lock time
    }

    struct AddPoolParam {
        IERC20 _lpToken;
        ICivFundRT _fundRepresentToken;
        IERC20 _guaranteeToken;
        uint256 _maxDeposit;
        uint256 _maxUser;
        address[] _withdrawAddresses; // Withdraw Address
        uint256 _fee;
        uint256 _feeDuration;
        uint256 _depositDuration;
        uint256 _withdrawDuration;   
        uint256 _lockPeriod; 
        bool _paused;
    }

    struct DepositParams {
        uint256 depositInfo;
        uint256 withdrawInfo;
        uint256 depositQuantity;
    }

    /// @notice vault getter contract
    ICivVaultGetter public vaultGetter;
    /// @notice structure with info on each pool
    PoolInfo[] public poolInfo;
    /// @notice structure with info on each pool
    VaultInfo[] public vaultInfo;
    /// @notice Info of each user that enters the fund
    mapping(uint256 => mapping(address => UserInfo)) public userInfo; 
    /// @notice Info if represent token is already added to the pool
    mapping(address=> bool) public bFundRepresentTokenAdded;
    /// @notice Each Pools deposit informations
    mapping(uint256 => mapping( address=> mapping(uint256 => DepositParams))) public depositParams;
    /// @notice Each Pools deposit time values
    mapping(uint256 => mapping(uint256 => uint256)) public depositTime;

    /// @notice Event emitted when user deposit fund to our vault or vault deposit fund to strategy
    event Deposit(address indexed user, address receiver, uint256 indexed pid, uint256 amount);
    /// @notice Event emitted when user request withdraw fund from our vault or vault withdraw fund to user
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    /// @notice Event emitted when owner sets new fee
    event SetFee(uint256 pid, uint256 oldFee, uint256 newFee);
    /// @notice Event emitted when owner sets new guarantee fee
    event SetGuaranteeFee(uint256 oldFee, uint256 newFee);
    /// @notice Event emitted when owner sets new fee duration
    event SetFeeDuration(uint256 pid, uint256 oldDuration, uint256 newDuration);
    /// @notice Event emitted when owner sets new deposit duration
    event SetDepositDuration(uint256 pid, uint256 oldDuration, uint256 newDuration);
    /// @notice Event emitted when owner sets new guarantee token lock time
    event SetPoolLockTime(uint256 pid, uint256 oldLocktime, uint256 newLockTime);
    /// @notice Event emitted when owner sets new withdraw duration
    event SetWithdrawDuration(uint256 pid, uint256 oldDuration, uint256 newDuration);
    /// @notice Event emitted when owner sets new treasury addresses
    event SetWithdrawAddress(uint256 pid, address[] oldAddress, address[] newAddress);
    /// @notice Event emitted when send fee to our treasury
    event SendFeeWithOwner(uint256 pid, address treasuryAddress,uint256 feeAmount);
    /// @notice Event emitted when owner update new NAV
    event UpdateNAV(uint256 pid, uint256 NAV, uint256 watermark, uint256 unpaidFee);
    /// @notice Event emitted when owner paused deposit
    event SetPaused(uint256 pid, bool paused);
    /// @notice Event emitted when owner set new Max Deposit Amount
    event SetMaxDeposit(uint256 pid, uint256 oldMaxAmount, uint256 newMaxAmount);
    /// @notice Event emitted when owner set new Max User Count for Deposit/Withdraw
    event SetMaxUser(uint256 _pid, uint256 oldMaxUser, uint256 newMaxUser);
    /// @notice Event emitted when user withdraw pending amount from vault
    event WithdrawPending(address user,uint256 pid, uint256 amount);
    /// @notice Event emitted when Uniswap Token Price Updated
    event Update(uint256 _pid, uint256 index);
    /// @notice Event emitted when user claim guarantee token
    event ClaimGuarantee(uint256 pid, address user, uint256 rewardAmount);
    /// @notice Event emitted when user claim LP token for each epoch
    event ClaimWithdrawedToken(uint256 pid, address user, uint256 epoch, uint256 lpAmount);
    /// @notice Event emitted when user claim LP token
    event GetWithdrawedToken(uint256 pid, address user, uint256 lpAmount);
    /// @notice Event emitted when owner adds new pool
    event AddPool(
        uint256 indexed pid,
        uint256 indexed fee,
        uint256 maxDeposit,
        bool paused,
        address[] withdrawAddress,
        address lpToken,
        address guaranteeToken,
        uint256 lockPeriod
    );

    modifier whenDepositPaused(uint256 _pid) {
        require(vaultInfo.length > _pid, "Pool does not exist");
        require(vaultInfo[_pid].paused == true, "Deposit is not paused");
        _;
    }
    modifier whenDepositNotPaused(uint256 _pid) {
        require(vaultInfo.length > _pid, "Pool does not exist");
        require(vaultInfo[_pid].paused == false, "deposit paused");
        _;
    }

    constructor(
    ) {}

    /// @notice Add new pool to our vault
    /// @dev Only Owner can call this function
    /// @param addPoolParam Parameters for new pool
    function addPool(
        AddPoolParam memory addPoolParam
    ) public virtual onlyOwner {
        require(addPoolParam._withdrawAddresses.length == 2,"Treasury Address Length must be 2");
        require(address(addPoolParam._fundRepresentToken) != NULL_ADDRESS,"Fund Represent Token address cannot be null address");
        require(address(addPoolParam._guaranteeToken) != NULL_ADDRESS,"Guarantee Token address cannot be null address");
        require(addPoolParam._withdrawAddresses[0] != NULL_ADDRESS,"first Treasury address cannot be null address");
        require(addPoolParam._withdrawAddresses[1] != NULL_ADDRESS,"second Treasury address cannot be null address");
        require(!bFundRepresentTokenAdded[address(addPoolParam._fundRepresentToken)], "represent token already added");
        poolInfo.push(
            PoolInfo({
                lpToken: addPoolParam._lpToken, // Rewardable contract: token for staking, LP for Funding, or NFT for NFT staking
                fundRepresentToken: addPoolParam._fundRepresentToken,
                guaranteeToken: addPoolParam._guaranteeToken,
                NAV: 0, //init = always 0
                totalShares: 0, //init = always 0
                fee: addPoolParam._fee,
                withdrawAddress: addPoolParam._withdrawAddresses,
                unpaidFee: 0,
                watermark: 0,
                burnShareAmount: 0,
                currentDepositEpoch: 0,
                currentWithdrawEpoch: 0,
                valuePerShare: 0 //init = always 0
            })
        );  
        vaultInfo.push(
            VaultInfo({
                maxDeposit: addPoolParam._maxDeposit,
                maxUser: addPoolParam._maxUser,
                paused: addPoolParam._paused,
                currentDeposit: 0,
                currentWithdraw: 0,
                collectFeeDuration: addPoolParam._feeDuration,
                lastCollectFee: block.timestamp,
                depositDuration: addPoolParam._depositDuration,
                withdrawDuration: addPoolParam._withdrawDuration,
                lockPeriod: addPoolParam._lockPeriod,
                lastDeposit: block.timestamp,
                lastWithdraw: block.timestamp,
                curDepositUser: 0,
                curWithdrawUser: 0
            })
        );
        uint256 pid = poolInfo.length - 1;
        vaultGetter.addUniPair(pid, address(addPoolParam._lpToken), address(addPoolParam._guaranteeToken));
        bFundRepresentTokenAdded[address(addPoolParam._fundRepresentToken)] = true;
        emit AddPool(
            pid,
            addPoolParam._fee,
            addPoolParam._maxDeposit,
            addPoolParam._paused,
            addPoolParam._withdrawAddresses,
            address(addPoolParam._lpToken),
            address(addPoolParam._guaranteeToken),
            addPoolParam._lockPeriod
        );     
    }

    /// @notice Sets new fee
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newFee New Fee Percent
    function setFee(uint256 _pid,uint256 _newFee) external onlyOwner {
        require(poolInfo.length > _pid, "Pool does not exist");
        emit SetFee(_pid, poolInfo[_pid].fee, _newFee);
        poolInfo[_pid].fee = _newFee;
    }

    /// @notice Sets new collecting fee duration
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newDuration New Collecting Fee Duration
    function setFeeDuration(uint256 _pid, uint256 _newDuration) external onlyOwner {
        require(vaultInfo.length > _pid, "Pool does not exist");
        emit SetFeeDuration(_pid, vaultInfo[_pid].collectFeeDuration, _newDuration);
        vaultInfo[_pid].collectFeeDuration = _newDuration;
    }

    /// @notice Sets new Pool guarantee token lock time
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _lockTime New Guarantee token lock time
    function setPoolLockTime(uint256 _pid, uint256 _lockTime)
        external
        onlyOwner
    {
        require(vaultInfo.length > _pid, "Pool does not exist");
        uint256 previousLockTime = vaultInfo[_pid].lockPeriod;
        emit SetPoolLockTime(_pid, previousLockTime, _lockTime);
        vaultInfo[_pid].lockPeriod = _lockTime;
    }

    /// @notice Sets new deposit fund from vault to strategy duration
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newDuration New Duration for Deposit fund from vault to strategy
    function setDepositDuration(uint256 _pid, uint256 _newDuration) external onlyOwner {
        require(vaultInfo.length > _pid, "Pool does not exist");
        emit SetDepositDuration(_pid, vaultInfo[_pid].depositDuration, _newDuration);
        vaultInfo[_pid].depositDuration = _newDuration;
    }

    /// @notice Sets new withdraw fund from strategy to users duration
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newDuration New Duration for Withdraw fund from strategy to users
    function setWithdrawDuration(uint256 _pid, uint256 _newDuration) external onlyOwner {
        require(vaultInfo.length > _pid, "Pool does not exist");
        emit SetWithdrawDuration(_pid, vaultInfo[_pid].withdrawDuration, _newDuration);
        vaultInfo[_pid].withdrawDuration = _newDuration;
    }

    /// @notice Sets new treasury addresses to keep fee
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newAddress Address list to keep fee
    function setWithdrawAddress(uint256 _pid, address[] memory _newAddress) external onlyOwner {
        require(_newAddress.length == 2, "Withdraw Addresses length must be 2");
        require(_newAddress[0] != NULL_ADDRESS,"first Treasury address cannot be null address");
        require(_newAddress[1] != NULL_ADDRESS,"second Treasury address cannot be null address");
        require(poolInfo.length > _pid, "Pool does not exist");
        emit SetWithdrawAddress(_pid, poolInfo[_pid].withdrawAddress, _newAddress);
        poolInfo[_pid].withdrawAddress = _newAddress;
    }

    /// @notice Set Pause of Unpause for deposit to vault
    /// @dev Only Owner can change this status
    /// @param _pid Pool Id
    /// @param _paused paused or unpaused for deposit
    function setPaused(uint256 _pid,bool _paused) external onlyOwner {
        require(vaultInfo.length > _pid, "Pool does not exist");
        emit SetPaused(_pid, _paused);
        vaultInfo[_pid].paused = _paused;
    }

    /// @notice Set Max Deposit Amount in the vault on a given pool
    /// @dev Only Owner can change this status
    /// @param _pid Pool Id
    /// @param _newMaxDeposit New Max Deposit Amount
    function setMaxDeposit(uint256 _pid,uint256 _newMaxDeposit) external onlyOwner {
        require(vaultInfo.length > _pid, "Pool does not exist");
        emit SetMaxDeposit(_pid, vaultInfo[_pid].maxDeposit, _newMaxDeposit);
        vaultInfo[_pid].maxDeposit = _newMaxDeposit;
    }

    /// @notice Set Max Deposit/Withdraw User Count in the vault on a given pool
    /// @dev Only Owner can change this status
    /// @param _pid Pool Id
    /// @param _newMaxUser New Max User Count
    function setMaxUser(uint256 _pid,uint256 _newMaxUser) external onlyOwner {
        require(vaultInfo.length > _pid, "Pool does not exist");
        emit SetMaxUser(_pid, vaultInfo[_pid].maxUser, _newMaxUser);
        vaultInfo[_pid].maxUser = _newMaxUser;
    }

    /// @notice Sets new guarantee fee
    /// @dev Only Owner can call this function
    /// @param _newFee new guarantee fee amount
    function setGuaranteeFee(uint256 _newFee) external onlyOwner {
        emit SetGuaranteeFee(guarantee_fee, _newFee);
        guarantee_fee = _newFee;
    }

    /// @notice Sets vault getter function
    /// @dev Only Owner can call this function
    /// @param _vaultGetter vaultGetter function address
    function setVaultGetter(ICivVaultGetter _vaultGetter) external onlyOwner {
        vaultGetter = _vaultGetter;
    }

    /// @notice Sets new NAV of the pool.
    /** 
     * @dev Only Owner can call this function. 
     *      Owner must transfer fund to our vault before calling this function
    */ 
    /// @param _pid Pool Id
    /// @param _newNAV New NAV value
    function updateNAV(uint256 _pid, uint256 _newNAV) external onlyOwner whenDepositPaused(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        pool.NAV = _newNAV;
        if( pool.watermark < _newNAV) {
            uint256 actualFee = (_newNAV - pool.watermark) * pool.fee / feeBase;
            if( actualFee > 0 ) {
                pool.watermark = _newNAV - actualFee;
                pool.unpaidFee += actualFee;
            }
        }
        emit UpdateNAV(_pid, _newNAV, pool.watermark, pool.unpaidFee);
    }

    function getPoolInfo(uint256 _pid) external view returns(PoolInfo memory pool, VaultInfo memory vault) {
        pool = poolInfo[_pid];
        vault = vaultInfo[_pid];
    }

    /// @dev Number of pools
    /// @return length Current Pool Length in a smart contract
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /// @dev Get Guarantee amount for deposit to the vault
    /// @param _pid Pool Id
    /// @param amount Amount to deposit in the vault
    /// @return amount Guarantee Token Amount needs for deposit in a given pool
    function getDepositGuarantee(uint256 _pid,uint256 amount) external view returns(uint) {
        return vaultGetter.getPrice(_pid, amount) * guarantee_fee / feeBase;
    }

    /// @dev Get Current Epoch deposit info on a given pool
    /// @param _pid Pool Id
    /// @param _user userAddress
    /// @return _curEpoch epoch value
    function getDepositParams(uint256 _pid,address _user, uint256 _curEpoch) external view returns(DepositParams memory) {
        return depositParams[_pid][_user][_curEpoch];
    }

    /// @dev Get Guarantee Token symbol and decimal
    /// @param _pid Pool Id
    /// @return symbol Guarantee Token Symbol in a given pool
    /// @return decimals Guarantee Token Decimal in a given pool
    function getGuaranteeTokenInfo(uint256 _pid) external view returns(string memory symbol, uint decimals) {
        IERC20Extended guarantee = IERC20Extended(address(poolInfo[_pid].guaranteeToken));
        symbol = guarantee.symbol();
        decimals = guarantee.decimals();
    }

    /// @dev Get available deposit amount based of user's guarantee amount
    /// @param _pid Pool Id
    /// @return amount Current Available Deposit amount regarding users's current guarantee token balance in a given pool
    function getAvailableDeposit(uint256 _pid) external view returns(uint) {
        IERC20Extended guarantee = IERC20Extended(address(poolInfo[_pid].guaranteeToken));
        uint256 balance = guarantee.balanceOf(_msgSender());
        return vaultGetter.getReversePrice(_pid, balance) * feeBase / guarantee_fee;
    }

    /// @dev Get claimable guarantee token amount
    /// @param _pid Pool Id
    /// @param _user userAddress
    /// @return amount Current claimable guarantee token amount
    function getClaimableGuaranteeToken(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        VaultInfo memory vault = vaultInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 curEpoch = poolInfo[_pid].currentDepositEpoch;
        uint256 unLocked;
        for( uint256 i = user.startingEpoch; i < curEpoch; i++ ) {
            if (
                block.timestamp >= depositTime[_pid][i] + vault.lockPeriod
            ) {
                unLocked += depositParams[_pid][_user][i].depositQuantity;
            }
        }

        return unLocked;
    }

    /// @notice Get withdraw tokens from vault
    /**
     * @dev Withdraw my fund from vault
     */
    /// @param _pid Pool Id
    function getWithdrawedToken(uint256 _pid, uint256[] memory epochs) external nonReentrant whenDepositNotPaused(_pid) {
        require(poolInfo.length > _pid, "Pool does not exist");
        PoolInfo memory pool = poolInfo[_pid];
        uint256 unclaimedAmount = 0;
       
        for(uint i = 0; i < epochs.length;i++) {
            if( epochs[i] < pool.currentWithdrawEpoch) {
                DepositParams storage dp = depositParams[_pid][_msgSender()][epochs[i]];
                unclaimedAmount += dp.withdrawInfo;
                emit ClaimWithdrawedToken(_pid, _msgSender(), epochs[i], dp.withdrawInfo);
                dp.withdrawInfo = 0;
            }
        }
        pool.lpToken.safeTransfer(_msgSender(), unclaimedAmount);
        emit GetWithdrawedToken(_pid, _msgSender(), unclaimedAmount);
    }

    /// @notice get unclaimed withdrawed token epochs
    /// @param _pid Pool Id
    /// @return _epochs array of unclaimed epochs
    function getUnclaimedTokenEpochs(uint256 _pid, address user) external view returns(uint256[] memory _epochs, uint256 _epochLength) {
        require(poolInfo.length > _pid, "Pool does not exist");
        PoolInfo memory pool = poolInfo[_pid];
        uint256 epochLen = 0;
        uint256 curWithdrawEpoch = pool.currentWithdrawEpoch;
        uint256[] memory tempEpochs = new uint256[](curWithdrawEpoch);
        for(uint i = 0; i < curWithdrawEpoch; i++) {
            if( depositParams[_pid][user][i].withdrawInfo > 0 ) {
                tempEpochs[epochLen++] = i;
            }
        }
        _epochLength = epochLen;
        _epochs = new uint256[](_epochLength);
        for(uint i = 0; i < _epochLength; i++) {
            _epochs[i] = tempEpochs[i];
        }
    }

    /// @notice Claim withdrawed token epochs
    /// @param _pid Pool Id
    /// @param _maxEpoch max epoch count to claim  
    function claimGuaranteeToken(uint256 _pid, uint256 _maxEpoch) external {
        require(poolInfo.length > _pid, "Pool does not exist");
        VaultInfo memory vault = vaultInfo[_pid];
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        uint256 curEpoch =  pool.currentDepositEpoch;
        uint256 endEpoch = Math.min(_maxEpoch, curEpoch);
        uint256 _startingEpoch = user.startingEpoch;
        uint256 _startingEpochFinal = _startingEpoch;
        uint256 actualReward;
        for( uint256 i = user.startingEpoch; i < endEpoch; i++ ) {
            if (block.timestamp < depositTime[_pid][i] + vault.lockPeriod) {
                break;
            }
            actualReward += depositParams[_pid][_msgSender()][i].depositQuantity;
            _startingEpochFinal = i + 1;
        }
        require(actualReward > 0, "no reward");
        user.startingEpoch = _startingEpochFinal;
        pool.guaranteeToken.safeTransfer(_msgSender(), actualReward);
        emit ClaimGuarantee(_pid, _msgSender(), actualReward);
    }

    /// @notice Users Deposit tokens to our vault
    /**
     * @dev Anyone can call this function if pool is not paused.
     *      Users must approve deposit token before calling this function
     *      We mint represent token to users so that we can calculate each users deposit amount outside
     */ 
    /// @param _pid Pool Id
    /// @param _amount Token Amount to deposit
    function deposit(uint256 _pid, uint256 _amount)
        external
        nonReentrant
        whenDepositNotPaused(_pid)
    {
        require(poolInfo.length > _pid, "Pool does not exist");
        require(vaultInfo[_pid].paused==false,"deposit paused");
        PoolInfo storage pool = poolInfo[_pid];
        VaultInfo storage vault = vaultInfo[_pid];
        uint256 curEpoch = pool.currentDepositEpoch;
        DepositParams storage dp = depositParams[_pid][_msgSender()][curEpoch];
        require( vault.currentDeposit+_amount <= vault.maxDeposit, "exceeds limit");
        if(dp.depositInfo == 0) {
            require(vault.curDepositUser < vault.maxUser, "Can't deposit any more");
            vault.curDepositUser++;
        }
        if (_amount > 0) { 
            if( pool.unpaidFee > 0 ) {
                sendFee(_pid, pool.unpaidFee);
            }
            // transfer guarantee token to the vault
            vaultGetter.updateAll(_pid);
            
            uint256 guaranteeAmount = vaultGetter.getPrice(_pid,_amount) * guarantee_fee / feeBase;
            require(guaranteeAmount>0, "not supported");
            pool.guaranteeToken.safeTransferFrom(_msgSender(), address(this), guaranteeAmount);
            dp.depositQuantity += guaranteeAmount;
            
            if( pool.totalShares == 0 ) {
                pool.valuePerShare = _amount;
            } else {
                pool.valuePerShare = pool.NAV * 10 **18 / pool.totalShares;
            }
            pool.NAV += _amount;
            uint256 addShare = _amount * 10 ** 18 / pool.valuePerShare;
            pool.totalShares += addShare;
            pool.watermark += _amount;
            pool.lpToken.safeTransferFrom(_msgSender(), address(this), _amount);
           
            if (addShare > 0) {
                pool.fundRepresentToken.mint(_msgSender(), addShare); // decimals of rewardable and represent tokens should be the same
            }
            dp.depositInfo += _amount;
            vault.currentDeposit += _amount;
        }
        emit Deposit(_msgSender(), address(this), _pid, _amount);
    }

    /// @notice Deposit vault fund to strategy address
    /**
     * @dev Only Owner can call this function if deposit duration is passed.
     *      Owner must setPaused(false)
     */
    /// @param _pid Pool Id
    /// @param invest strategy address
    function depositToFund(uint256 _pid, address invest)
        external
        nonReentrant
        whenDepositPaused(_pid)
        onlyOwner
    {
        PoolInfo storage pool = poolInfo[_pid];
        VaultInfo storage vault = vaultInfo[_pid];
        uint256 currentDeposit = vault.currentDeposit;
        require(invest != NULL_ADDRESS, "strategy address cannot be null address");
        require(currentDeposit > 0, "no token for deposit to fund");
        require(vault.lastDeposit + vault.depositDuration <= block.timestamp, "not ready for deposit");
        require(pool.lpToken.balanceOf(address(this)) >= currentDeposit);
        if( pool.unpaidFee > 0 ) {
            sendFee(_pid, pool.unpaidFee);
        }
        pool.valuePerShare = pool.NAV * 10 **18 / pool.totalShares;
        pool.lpToken.safeTransfer(invest, currentDeposit);
        depositTime[_pid][pool.currentDepositEpoch] = block.timestamp;
        pool.currentDepositEpoch++;
        vault.curDepositUser = 0;
        vault.currentDeposit = 0;
        vault.lastDeposit = block.timestamp;
        emit Deposit(address(this), invest, _pid, currentDeposit);
    }

    /// @notice Sends Withdraw Request to vault
    /**
     * @dev Withdraw all users fund from vault
     */
    /// @param _pid Pool Id
    function withdrawAll(uint256 _pid) external nonReentrant whenDepositNotPaused(_pid) {
        require(poolInfo.length > _pid, "Pool does not exist");
        VaultInfo storage vault = vaultInfo[_pid];
        PoolInfo storage pool = poolInfo[_pid];
        if( pool.unpaidFee > 0 ) {
            sendFee(_pid, pool.unpaidFee);
        }
        (uint256 currentBalance,uint256 shareAmount) = vaultGetter.getBalanceOfUser(_pid,_msgSender());
        pool.valuePerShare = pool.NAV * 10 **18 / pool.totalShares;
        uint256 valuePerShare = pool.valuePerShare;


        uint256 curDepositEpoch = pool.currentDepositEpoch;
        DepositParams storage depositParam = depositParams[_pid][_msgSender()][curDepositEpoch];
        require(currentBalance > 0, "Current balance must be bigger than 0");
        require( currentBalance > depositParam.depositInfo, "rt balance is less than deposit amount");
        currentBalance -= depositParam.depositInfo;
        uint256 curWithdrawEpoch = pool.currentWithdrawEpoch;
        DepositParams storage dp = depositParams[_pid][_msgSender()][curWithdrawEpoch];
        if(dp.withdrawInfo == 0) {
            require(vault.curWithdrawUser < vault.maxUser, "Can't withdraw any more");
            vault.curWithdrawUser++;
        }
        uint256 shareTransferAmount = currentBalance * 10 ** 18 / valuePerShare;
        require(shareAmount >= shareTransferAmount, "rt balance is less than burn amount");
        
        vault.currentWithdraw += currentBalance;
        dp.withdrawInfo += currentBalance;
        pool.fundRepresentToken.safeTransferFrom(_msgSender(),address(this), shareTransferAmount);
        pool.burnShareAmount += shareTransferAmount;
        emit Withdraw(_msgSender(), _pid, currentBalance);
    }

    /// @notice Immediately withdraw current pending deposit amount
    /// @param _pid Pool Id
    function withdrawPending(uint256 _pid) external nonReentrant whenDepositNotPaused(_pid) {
        require(poolInfo.length > _pid, "Pool does not exist");
        PoolInfo storage pool = poolInfo[_pid];
        VaultInfo storage vault = vaultInfo[_pid];
        uint256 curEpoch = pool.currentDepositEpoch;
        DepositParams storage dp = depositParams[_pid][_msgSender()][curEpoch];
        uint256 amount = dp.depositInfo;
        require( amount > 0, "no amount to withdraw pending token");
        if( pool.unpaidFee > 0 ) {
            sendFee(_pid, pool.unpaidFee);
        }
        pool.valuePerShare = pool.NAV * 10 **18 / pool.totalShares;
        uint256 valuePerShare = pool.valuePerShare;
        uint256 shareAmount = amount * 10 ** 18 / valuePerShare;
        pool.fundRepresentToken.burnFrom(_msgSender(),shareAmount);
        pool.NAV -= amount;
        pool.totalShares -= shareAmount;
        pool.watermark -= amount;
        pool.lpToken.safeTransfer(_msgSender(), amount);
        uint256 guaranteeAmount = dp.depositQuantity;
        dp.depositQuantity = 0;
        pool.guaranteeToken.safeTransfer(_msgSender(), guaranteeAmount);
        dp.depositInfo -= amount;
        vault.currentDeposit -= amount;
        vault.curDepositUser--;
        emit WithdrawPending(_msgSender(), _pid, amount);
    }

    /// @notice Sends tokens to users that request withdraw
    /**
     * @dev Owner must deposit token before calling this function
            Only Owner can call this function
            We burn fund represent token based withdraw request amount
            We send fee to the treasury address
     */
    /// @param _pid Pool Id
    function withdrawFromVault(uint256 _pid)
        external
        nonReentrant
        whenDepositPaused(_pid)
        onlyOwner
    {
        require(poolInfo.length > _pid, "Pool does not exist");
        PoolInfo storage pool = poolInfo[_pid];
        VaultInfo storage vault = vaultInfo[_pid];
        uint256 currentWithdraw = vault.currentWithdraw;
        uint256 burnShareAmount = pool.burnShareAmount;
        require( vault.curWithdrawUser > 0, "no user for withdraw");
        require(pool.totalShares > 0, "nothing to withdraw");
        require(vault.lastWithdraw + vault.withdrawDuration <= block.timestamp, "not ready for withdraw");
        require(pool.lpToken.balanceOf(address(this)) >= currentWithdraw + pool.unpaidFee, "not enough amount to withdraw");
        if( pool.unpaidFee > 0 ) {
            sendFee(_pid, pool.unpaidFee);
        }
        pool.NAV -= currentWithdraw;
        pool.watermark -= currentWithdraw;
        pool.totalShares -= burnShareAmount;
        vault.currentWithdraw = 0;
        vault.lastWithdraw = block.timestamp;
        vault.curWithdrawUser = 0;
        pool.fundRepresentToken.burn(burnShareAmount);
        pool.burnShareAmount = 0;
        pool.currentWithdrawEpoch++;
        emit Withdraw(address(this), _pid, currentWithdraw);
    }

    /// @notice Sends fee to the treasury address
    /**
     * @dev Internal function
     */
    /// @param _pid Pool Id
    /// @param feeAmount feeAmount
    function sendFee(uint256 _pid, uint256 feeAmount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        pool.NAV -= feeAmount;
        address addr0 = pool.withdrawAddress[0];
        address addr1 = pool.withdrawAddress[1];
        emit SendFeeWithOwner(_pid,addr0, feeAmount / 2);
        emit SendFeeWithOwner(_pid,addr1, feeAmount / 2);
        pool.unpaidFee = 0;
        pool.lpToken.safeTransfer(addr0, feeAmount / 2);
        pool.lpToken.safeTransfer(addr1, feeAmount / 2);
    }

    /// @notice Collects protocol fee
    /**
     * @dev Only Owner can call this function
     */
    /// @param _pid Pool Id
    function collectFee(uint256 _pid) external onlyOwner {
        require(poolInfo.length > _pid, "Pool does not exist");
        PoolInfo memory pool = poolInfo[_pid];
        VaultInfo storage vault = vaultInfo[_pid];
        require(pool.unpaidFee > 0, "no fee to collect");
        require(vault.lastCollectFee + vault.collectFeeDuration <= block.timestamp,"not ready yet!");
        vault.lastCollectFee = block.timestamp;
        sendFee(_pid, poolInfo[_pid].unpaidFee);
    }

    /* Just in case anyone sends tokens by accident to this contract */

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "CivFund");
    }

    /// @notice Withdraw ETH to the owner
    /**
     * @dev Only Owner can call this function
     */
    function withdrawETH() external payable onlyOwner {
        safeTransferETH(_msgSender(), address(this).balance);
    }

    /// @notice Withdraw ERC-20 Token to the owner
    /**
     * @dev Only Owner can call this function
     */
    /// @param _tokenContract ERC-20 Token address
    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        for( uint256 i = 0; i < poolInfo.length; i++) {
            require(poolInfo[i].guaranteeToken != _tokenContract, "Withdraw Token cannot be deposit token");
            require(poolInfo[i].lpToken != _tokenContract, "Withdraw Token cannot be deposit token");
        }
        _tokenContract.safeTransfer(
            _msgSender(),
            _tokenContract.balanceOf(address(this))
        );
    }

    /**
     * @dev allow the contract to receive ETH
     * without payable fallback and receive, it would fail
     */
    fallback() external payable {}

    receive() external payable {}
}