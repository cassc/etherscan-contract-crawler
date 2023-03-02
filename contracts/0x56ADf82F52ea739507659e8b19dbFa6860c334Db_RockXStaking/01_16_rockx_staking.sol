// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "iface.sol";
import "BytesLib.sol";
import "SafeERC20.sol";
import "Initializable.sol";
import "AccessControlUpgradeable.sol";
import "PausableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";


/**
 * @title RockX Ethereum 2.0 Staking Contract
 *
 * Description:
 * 
 * Term:
 *  ExchangeRatio:              Exchange Ratio of xETH to ETH, normally >= 1.0
 *  TotalXETH:                  Total Supply of xETH
 *  TotalStaked:                Total Ethers Staked to Validators
 *  TotalDebts:                 Total unpaid debts(generated from redeemFromValidators), 
 *                              awaiting to be paid by turn off validators to clean debts.
 *  TotalPending:               Pending Ethers(<32 Ethers), awaiting to be staked
 *  RewardDebts:                The amount re-staked into TotalPending
 *
 *  AccountedUserRevenue:       Overall Net revenue which belongs to all xETH holders(excluded re-staked amount)
 *  ReportedValidators:         Latest Reported Validator Count
 *  ReportedValidatorBalance:   Latest Reported Validator Overall Balance
 *  RecentReceived:             The Amount this contract receives recently.
 *  CurrentReserve:             Assets Under Management
 *
 * Lemma 1: (AUM)
 *
 *          CurrentReserve = TotalPending + TotalStaked + AccountedUserRevenue - TotalDebts - RewardDebts
 *
 * Lemma 2: (Exchange Ratio)
 *
 *          ExchangeRatio = CurrentReserve / TotalXETH
 *
 * Rule 1: (function mint) For every mint operation, the ethers pays debt in priority the reset will be put in TotalPending(deprecated),
 *          ethersToMint:               The amount user deposits
 *
 *          (deprecated)
 *          TotalDebts = TotalDebts - Min(ethersToMint, TotalDebts)    
 *          TotalPending = TotalPending + Max(0, ethersToMint - TotalDebts)
 *          TotalXETH = TotalXETH + ethersToMint / ExchangeRatio
 *          
 *          (updated)
 *          TotalPending = TotalPending + ethersToMint
 *          TotalXETH = TotalXETH + ethersToMint / ExchangeRatio
 *
 * Rule 2: (function mint) At any time TotalPending has more than 32 Ethers, It will be staked, TotalPending
 *          moves to TotalStaked and keeps TotalPending less than 32 Ether.
 *
 *          TotalPending = TotalPending - ⌊TotalPending/32ETH⌋ * 32ETH
 *          TotalStaked = TotalStaked + ⌊TotalPending/32ETH⌋ * 32ETH
 *
 * Rule 3: (function validatorStopped) Whenever a validator stopped, all value pays debts in priority, then:
 *          valueStopped:               The value sent-back via receive() funtion
 *          amountUnstaked:             The amount of unstaked node (base 32ethers)
 *          validatorStopped:           The count of validator stopped
 *          
 *          incrRewardDebt := valueStopped - amountUnstaked
 *          RewardDebts = RewardDebt + incrRewardDebt
 *          RecentReceived = RecentReceived + valueStopped
 *          TotalPending = TotalPending + Max(0, amountUnstaked - TotalDebts) + incrRewardDebt
 *          TotalStaked = TotalStaked - validatorStopped * 32 ETH
 *
 * Rule 4.1: (function pushBeacon) Oracle push balance, rebase if new validator is alive:
 *          aliveValidator:             The count of validators alive
 *          
 *          RewardBase = ReportedValidatorBalance + Max(0, aliveValidator - ReportedValidators) * 32 ETH
 *
 * Rule 4.2: (function pushBeacon) Oracle push balance, revenue calculation:
 *          aliveBalance:               The balance of current alive validators
 *
 *          r := aliveBalance + RecentReceived - RewardBase
 *          AccountedUserRevenue = AccountedUserRevenue + r * (1000 - managerFeeShare) / 1000
 *          RecentReceived = 0
 *          ReportedValidators = aliveValidator
 *          ReportedValidatorBalance = aliveBalance
 *
 */
contract RockXStaking is Initializable, PausableUpgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using Address for address;

    // stored credentials
    struct ValidatorCredential {
        bytes pubkey;
        bytes signature;
        bool stopped;
    }
    
    // track ether debts to return to async caller
    struct Debt {
        address account;
        uint256 amount;
    }

    /**
        Incorrect storage preservation:

        |Implementation_v0   |Implementation_v1        |
        |--------------------|-------------------------|
        |address _owner      |address _lastContributor | <=== Storage collision!
        |mapping _balances   |address _owner           |
        |uint256 _supply     |mapping _balances        |
        |...                 |uint256 _supply          |
        |                    |...                      |
        Correct storage preservation:

        |Implementation_v0   |Implementation_v1        |
        |--------------------|-------------------------|
        |address _owner      |address _owner           |
        |mapping _balances   |mapping _balances        |
        |uint256 _supply     |uint256 _supply          |
        |...                 |address _lastContributor | <=== Storage extension.
        |                    |...                      |
    */

    // Always extend storage instead of modifying it
    // Variables in implementation v0 
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant REGISTRY_ROLE = keccak256("REGISTRY_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    uint256 public constant DEPOSIT_SIZE = 32 ether;

    uint256 private constant MULTIPLIER = 1e18; 
    uint256 private constant DEPOSIT_AMOUNT_UNIT = 1000000000 wei;
    uint256 private constant SIGNATURE_LENGTH = 96;
    uint256 private constant PUBKEY_LENGTH = 48;
    
    address public ethDepositContract;      // ETH 2.0 Deposit contract
    address public xETHAddress;             // xETH token address
    address public redeemContract;          // redeeming contract for user to pull ethers

    uint256 public managerFeeShare;         // manager's fee in 1/1000
    bytes32 public withdrawalCredentials;   // WithdrawCredential for all validator
    
    // credentials, pushed by owner
    ValidatorCredential [] private validatorRegistry;
    mapping(bytes32 => uint256) private pubkeyIndices; // indices of validatorRegistry by pubkey hash, starts from 1

    // next validator id
    uint256 private nextValidatorId;

    // exchange ratio related variables
    // track user deposits & redeem (xETH mint & burn)
    uint256 private totalPending;           // track pending ethers awaiting to be staked to validators
    uint256 private totalStaked;            // track current staked ethers for validators, rounded to 32 ethers
    uint256 private totalDebts;             // track current unpaid debts

    // FIFO of debts from redeemFromValidators
    mapping(uint256=>Debt) private etherDebts;
    uint256 private firstDebt;
    uint256 private lastDebt;
    mapping(address=>uint256) private userDebts;    // debts from user's perspective

    // track revenue from validators to form exchange ratio
    uint256 private accountedUserRevenue;           // accounted shared user revenue
    uint256 private accountedManagerRevenue;        // accounted manager's revenue
    uint256 private rewardDebts;                    // check validatorStopped function

    // revenue related variables
    // track beacon validator & balance
    uint256 private reportedValidators;
    uint256 private reportedValidatorBalance;

    // balance tracking
    int256 private accountedBalance;                // tracked balance change in functions,
                                                    // NOTE(x): balance might be negative for not accounting validators's redeeming

    uint256 private recentSlashed;                  // track recently slashed value
    uint256 private recentReceived;                 // track recently received (un-accounted) value into this contract
    bytes32 private vectorClock;                    // a vector clock for detecting receive() & pushBeacon() causality violations
    uint256 private vectorClockTicks;               // record current vector clock step;

    // track stopped validators
    uint256 stoppedValidators;                      // track stopped validators count

    // phase switch from 0 to 1
    uint256 private phase;

    // gas refunds
    uint256 [] private refunds;

    // PATCH VARIABLES(UPGRADES)
    uint256 recentStopped;                          // track recent stopped validators(update: 20220927)

    /**
     * @dev empty reserved space for future adding of variables
     */
    uint256[31] private __gap;

    // KYC control
    mapping(address=>uint256) quotaUsed;
    mapping(address=>bool) whiteList;

    // auto-compounding
    bool private autoCompoundEnabled;

    /** 
     * ======================================================================================
     * 
     * SYSTEM SETTINGS, OPERATED VIA OWNER(DAO/TIMELOCK)
     * 
     * ======================================================================================
     */
    receive() external payable { }

    /**
     * @dev only phase
     */
    modifier onlyPhase(uint256 requiredPhase) {
        require(phase >= requiredPhase, "SYS001");
        _;
    }

    /**
     * @dev pause the contract
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev unpause the contract
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev initialization address
     */
    function initialize() initializer public {
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, msg.sender);
        _grantRole(REGISTRY_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MANAGER_ROLE, msg.sender);

        // init default values
        managerFeeShare = 5;
        firstDebt = 1;
        lastDebt = 0;
        phase = 0;
        _vectorClockTick();

        // initiate default withdrawal credential to the contract itself
        // uint8('0x1') + 11 bytes(0) + this.address
        bytes memory cred = abi.encodePacked(bytes1(0x01), new bytes(11), address(this));
        withdrawalCredentials = BytesLib.toBytes32(cred, 0);
    }

    /**
     * @dev phase switch
     */
    function switchPhase(uint256 newPhase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require (newPhase >= phase, "SYS002");
        phase = newPhase;
    }

    /**
     * @dev register a validator
     */
    function registerValidator(bytes calldata pubkey, bytes calldata signature) external onlyRole(REGISTRY_ROLE) {
        require(signature.length == SIGNATURE_LENGTH, "SYS003");
        require(pubkey.length == PUBKEY_LENGTH, "SYS004");

        bytes32 pubkeyHash = keccak256(pubkey);
        require(pubkeyIndices[pubkeyHash] == 0, "SYS005");
        validatorRegistry.push(ValidatorCredential({pubkey:pubkey, signature:signature, stopped:false}));
        pubkeyIndices[pubkeyHash] = validatorRegistry.length;
    }

    /**
     * @dev replace a validator in case of msitakes
     */
    function replaceValidator(bytes calldata oldpubkey, bytes calldata pubkey, bytes calldata signature) external onlyRole(REGISTRY_ROLE) {
        require(pubkey.length == PUBKEY_LENGTH, "SYS004");
        require(signature.length == SIGNATURE_LENGTH, "SYS003");

        // mark old pub key to false
        bytes32 oldPubKeyHash = keccak256(oldpubkey);
        require(pubkeyIndices[oldPubKeyHash] > 0, "SYS006");
        uint256 index = pubkeyIndices[oldPubKeyHash] - 1;
        delete pubkeyIndices[oldPubKeyHash];

        // set new pubkey
        bytes32 pubkeyHash = keccak256(pubkey);
        validatorRegistry[index] = ValidatorCredential({pubkey:pubkey, signature:signature, stopped:false});
        pubkeyIndices[pubkeyHash] = index+1;
    }

    /**
     * @dev register a batch of validators
     */
    function registerValidators(bytes [] calldata pubkeys, bytes [] calldata signatures) external onlyRole(REGISTRY_ROLE) {
        require(pubkeys.length == signatures.length, "SYS007");
        uint256 n = pubkeys.length;
        for(uint256 i=0;i<n;i++) {
            require(pubkeys[i].length == PUBKEY_LENGTH, "SYS004");
            require(signatures[i].length == SIGNATURE_LENGTH, "SYS003");

            bytes32 pubkeyHash = keccak256(pubkeys[i]);
            require(pubkeyIndices[pubkeyHash] == 0, "SYS005");
            validatorRegistry.push(ValidatorCredential({pubkey:pubkeys[i], signature:signatures[i], stopped:false}));
            pubkeyIndices[pubkeyHash] = validatorRegistry.length;
        }
    }

    /**
     * @dev toggleWhiteList
     */
    function toggleWhiteList(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whiteList[account] = !whiteList[account];

        emit WhiteListToggle(account, whiteList[account]);
    }
    
    /**
     * @dev toggle autocompound
     */
    function toggleAutoCompound() external onlyRole(DEFAULT_ADMIN_ROLE) {
        autoCompoundEnabled = !autoCompoundEnabled;

        emit AutoCompoundToggle(autoCompoundEnabled);
    }
    
    /**
     * @dev set manager's fee in 1/1000
     */
    function setManagerFeeShare(uint256 milli) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        require(milli >=0 && milli <=1000, "SYS008");
        managerFeeShare = milli;

        emit ManagerFeeSet(milli);
    }

    /**
     * @dev set xETH token contract address
     */
    function setXETHContractAddress(address _xETHContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        xETHAddress = _xETHContract;

        emit XETHContractSet(_xETHContract);
    }

    /**
     * @dev set eth deposit contract address
     */
    function setETHDepositContract(address _ethDepositContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ethDepositContract = _ethDepositContract;

        emit DepositContractSet(_ethDepositContract);
    }

    /**
     * @dev set redeem contract
     */
    function setRedeemContract(address _redeemContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        redeemContract = _redeemContract;

        emit RedeemContractSet(_redeemContract);
    }

    /**
     @dev set withdraw credential to receive revenue, usually this should be the contract itself.
     */
    function setWithdrawCredential(bytes32 withdrawalCredentials_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        withdrawalCredentials = withdrawalCredentials_;
        emit WithdrawCredentialSet(withdrawalCredentials);
    } 

    /**
     * @dev stake into eth2 staking contract by calling this function
     */
    function stake() external onlyRole(REGISTRY_ROLE) {
        // spin up n nodes
        uint256 numValidators = totalPending / DEPOSIT_SIZE;
        require(nextValidatorId + numValidators <= validatorRegistry.length, "SYS009");
        for (uint256 i = 0;i<numValidators;i++) {
            _spinup();
        }

        emit ValidatorActivated(nextValidatorId);
    }

    /**
     * @dev manager withdraw fees as uniETH
     */
    function withdrawManagerFee(uint256 amount, address to) external nonReentrant onlyRole(MANAGER_ROLE)  {
        _syncBalance();
        
        require(amount <= accountedManagerRevenue, "SYS010");
        // debts + userRevenue + managersRevenue + pending ethers
        require(address(this).balance >= amount + totalPending + totalDebts, "SYS011");

        // mint uniETH while keeping the exchange ratio invariant
        uint256 totalXETH = IERC20(xETHAddress).totalSupply();
        uint256 totalEthers = currentReserve();
        uint256 toMint = 1 * amount;  // default exchange ratio 1:1

        if (totalEthers > 0) { // avert division overflow
            toMint = totalXETH * amount / totalEthers;
        }

        // NOTE: the following procdure must keep exchangeRatio invariant:
        // mint equivalent `uniETH` to `amount`
        IMintableContract(xETHAddress).mint(to, toMint);

        // track balance change:
        // shift manager's revenue from accountedManagerRevenue to totalPending
        totalPending += amount;
        accountedManagerRevenue -= amount;

        emit ManagerFeeWithdrawed(amount, to);
    }

    /**
     * @dev balance sync, also moves the vector clock if it has different value
     */
    function syncBalance() external onlyRole(ORACLE_ROLE) { _syncBalance(); }
    
    /**
     * @dev balance sync, also moves the vector clock if it has different value
     */
    function _syncBalance() internal {
        assert(int256(address(this).balance) >= accountedBalance);
        uint256 diff = uint256(int256(address(this).balance) - accountedBalance);
        if (diff > 0) {
            accountedBalance = int256(address(this).balance);
            recentReceived += diff;
            _vectorClockTick();
            emit BalanceSynced(diff);
        }
    }
    
    /**
     * @dev operator reports current alive validators count and overall balance
     * with default appreciation limit
     */
    function pushBeacon(uint256 _aliveValidators, uint256 _aliveBalance, bytes32 clock) external onlyRole(ORACLE_ROLE) {
        _pushBeacon(_aliveValidators, _aliveBalance, clock, 5);
    }

    /**
     * @dev operator reports current alive validators count and overall balance
     * with custom appreciation limit
     */
    function pushBeacon(uint256 _aliveValidators, uint256 _aliveBalance, bytes32 clock, uint256 limit) external onlyRole(ORACLE_ROLE) {
        _pushBeacon(_aliveValidators, _aliveBalance, clock, limit);
    }


    function _pushBeacon(uint256 _aliveValidators, uint256 _aliveBalance, bytes32 clock, uint256 limit) internal {
        require(vectorClock == clock, "SYS012");
        require(_aliveValidators + stoppedValidators <= nextValidatorId, "SYS013");
        require(_aliveBalance >= _aliveValidators * DEPOSIT_SIZE, "SYS014");

        // step 0. collect new revenue if there is any.
        _syncBalance();

        // step 1. check if new validator increased
        // and adjust rewardBase to include the new validators' value
        uint256 rewardBase = reportedValidatorBalance;
        if (_aliveValidators + recentStopped > reportedValidators) {
            // newly launched validators
            uint256 newValidators = _aliveValidators + recentStopped - reportedValidators;
            rewardBase += newValidators * DEPOSIT_SIZE;
        }

        // step 2. calc rewards, this also considers recentReceived ethers from 
        // either stopped validators or withdrawed ethers as rewards.
        //
        // During two consecutive pushBeacon operation, the ethers will ONLY: 
        //  1. staked to new validators
        //  2. move from active validators to this contract
        //  3. slashed and stopped then the remaining ethers returned to this contract
        // 
        // so, at any time, revenue generated if:
        //
        //  current active validator balance 
        //      + recent received from validators(since last pushBeacon) 
        //      + recent slashed(since last pushBeacon)
        //  >（GREATER THAN) reward base(last active validator balance + new nodes balance)
        //
        // NOTE(x): recentSlashed is accounted here, then we can adjust the basepoint to current alive validator balance.
        //   eg:
        //          _aliveBalance = 0 （slashed)
        //          recentReceived = 16 ETH (the ethers left)
        //          recentSlashed = 16 ETH (assumed slashed ethers)
        // 

        require(_aliveBalance + recentReceived + recentSlashed >= rewardBase, "SYS015");
        uint256 rewards = _aliveBalance + recentReceived + recentSlashed - rewardBase;
        if (totalDebts > 0) {
            // as we cannot differentiate the ethers from full withdrawal & partial withdrawal,
            // to make sure we only take partial withdrawal(revenue) into reward calculation
            require(rewards * 1000 / currentReserve() < limit, "SYS016");
        }

        _distributeRewards(rewards);
        _autocompound();

        // step 3. update reportedValidators & reportedValidatorBalance
        // reset the recentReceived to 0
        reportedValidatorBalance = _aliveBalance; 
        reportedValidators = _aliveValidators;
        recentReceived = 0;
        recentSlashed = 0;
        recentStopped = 0;
    }

    /**
     * @dev notify some validators stopped, and pay the debts
     */
    function validatorStopped(bytes [] calldata _stoppedPubKeys, bytes32 clock) external nonReentrant onlyRole(ORACLE_ROLE) {
        require(vectorClock == clock, "SYS012");
        uint256 amountUnstaked = _stoppedPubKeys.length * DEPOSIT_SIZE;
        require(_stoppedPubKeys.length > 0, "SYS017");
        require(_stoppedPubKeys.length + stoppedValidators <= nextValidatorId, "SYS018");
        require(address(this).balance >= amountUnstaked + totalPending + accountedManagerRevenue, "SYS019");

        // track stopped validators
        for (uint i=0;i<_stoppedPubKeys.length;i++) {
            bytes32 pubkeyHash = keccak256(_stoppedPubKeys[i]);
            require(pubkeyIndices[pubkeyHash] > 0, "SYS006");
            uint256 index = pubkeyIndices[pubkeyHash] - 1;
            require(!validatorRegistry[index].stopped, "SYS020");
            validatorRegistry[index].stopped = true;
        }
        stoppedValidators += _stoppedPubKeys.length;
        recentStopped += _stoppedPubKeys.length;

        // NOTE(x) The following procedure MUST keep currentReserve unchanged:
        // ASSUMING: paid == amountUnstaked
        // 
        // totalPending + (totalStaked - amountUnstaked) + accountedUserRevenue - rewardDebt - (totalDebts - paid)
        //  ==
        //  totalPending + totalStaked + accountedUserRevenue - totalDebts - rewardDebt
        //

        // pay debts
        uint256 paid = _payDebts(amountUnstaked);
        require(paid == amountUnstaked, "SYS021");
        // track total staked ethers
        totalStaked -= amountUnstaked;
        
        // log
        emit ValidatorStopped(_stoppedPubKeys.length);

        // vector clock moves
        _vectorClockTick();
    }

    /**
     * @dev notify some validators has been slashed, turn off those stopped validator
     */
    function validatorSlashedStop(bytes [] calldata _stoppedPubKeys, bytes32 clock) external nonReentrant onlyRole(ORACLE_ROLE) {
        require(vectorClock == clock, "SYS012");
        uint256 amountUnstaked = _stoppedPubKeys.length * DEPOSIT_SIZE;
        require(_stoppedPubKeys.length > 0, "SYS017");
        require(address(this).balance >= _stoppedPubKeys.length * 16 ether + totalPending + accountedManagerRevenue, "SYS019");

        // record slashed validators.
        for (uint i=0;i<_stoppedPubKeys.length;i++) {
            bytes32 pubkeyHash = keccak256(_stoppedPubKeys[i]);
            require(pubkeyIndices[pubkeyHash] > 0, "SYS006");
            uint256 index = pubkeyIndices[pubkeyHash] - 1;
            require(!validatorRegistry[index].stopped, "SYS020");
            validatorRegistry[index].stopped = true;
        }
        stoppedValidators += _stoppedPubKeys.length;
        recentStopped += _stoppedPubKeys.length;

        // currentReserve changed to:
        // (totalPending + 16 ETH) + (totalStaked - amountUnstaked) + accountedUserRevenue - rewardDebt - totalDebts
        //  the remaining part(revenue) will be taken as the accruing rewards of existing holders.
        totalStaked -= amountUnstaked;
        totalPending += _stoppedPubKeys.length * 16 ether;
        // track recent slashed
        recentSlashed += _stoppedPubKeys.length * 16 ether;

        // log
        emit ValidatorSlashedStopped(_stoppedPubKeys.length);
        
        // vector clock moves
        _vectorClockTick();
    }

    /**
     * ======================================================================================
     * 
     * VIEW FUNCTIONS
     * 
     * ======================================================================================
     */

    /**
     * @dev returns current reserve of ethers
     */
    function currentReserve() public view returns(uint256) {
        return totalPending + totalStaked + accountedUserRevenue - totalDebts - rewardDebts;
    }

    /*
     * @dev returns current vector clock
     */
    function getVectorClock() external view returns(bytes32) { return vectorClock; }

    /*
     * @dev returns current accounted balance
     */
    function getAccountedBalance() external view returns(int256) { return accountedBalance; }

    /**
     * @dev return total staked ethers
     */
    function getTotalStaked() external view returns (uint256) { return totalStaked; }

    /**
     * @dev return pending ethers
     */
    function getPendingEthers() external view returns (uint256) { return totalPending; }

    /**
     * @dev return reward debts
     */
    function getRewardDebts() external view returns (uint256) { return rewardDebts; }

    /**
     * @dev return current debts
     */
    function getCurrentDebts() external view returns (uint256) { return totalDebts; }

    /**
     * @dev returns the accounted user revenue
     */
    function getAccountedUserRevenue() external view returns (uint256) { return accountedUserRevenue; }

    /**
     * @dev returns the accounted manager's revenue
     */
    function getAccountedManagerRevenue() external view returns (uint256) { return accountedManagerRevenue; }

    /*
     * @dev returns accumulated beacon validators
     */
    function getReportedValidators() external view returns (uint256) { return reportedValidators; }

    /*
     * @dev returns reported validator balance snapshot
     */
    function getReportedValidatorBalance() external view returns (uint256) { return reportedValidatorBalance; }

    /*
     * @dev returns recent slashed value
     */
    function getRecentSlashed() external view returns (uint256) { return recentSlashed; }
    /*
     * @dev returns recent received value
     */
    function getRecentReceived() external view returns (uint256) { return recentReceived; }

    /**
     * @dev return debt for an account
     */
    function debtOf(address account) external view returns (uint256) {
        return userDebts[account];
    }

    /**
     * @dev return number of registered validator
     */
    function getRegisteredValidatorsCount() external view returns (uint256) {
        return validatorRegistry.length;
    }
    
    /**
     * @dev return a batch of validators credential
     */
    function getRegisteredValidators(uint256 idx_from, uint256 idx_to) external view returns (bytes [] memory pubkeys, bytes [] memory signatures, bool[] memory stopped) {
        pubkeys = new bytes[](idx_to - idx_from);
        signatures = new bytes[](idx_to - idx_from);
        stopped = new bool[](idx_to - idx_from);


        uint counter = 0;
        for (uint i = idx_from; i < idx_to;i++) {
            pubkeys[counter] = validatorRegistry[i].pubkey;
            signatures[counter] = validatorRegistry[i].signature;
            stopped[counter] = validatorRegistry[i].stopped;
            counter++;
        }
    }

    /**
     * @dev return next validator id
     */
    function getNextValidatorId() external view returns (uint256) { return nextValidatorId; }

    /**
     * @dev return exchange ratio of , multiplied by 1e18
     */
    function exchangeRatio() external view returns (uint256) {
        uint256 xETHAmount = IERC20(xETHAddress).totalSupply();
        if (xETHAmount == 0) {
            return 1 * MULTIPLIER;
        }

        uint256 ratio = currentReserve() * MULTIPLIER / xETHAmount;
        return ratio;
    }

    /**
     * @dev return debt of index
     */
    function checkDebt(uint256 index) external view returns (address account, uint256 amount) {
        Debt memory debt = etherDebts[index];
        return (debt.account, debt.amount);
    }
    /**
     * @dev return debt queue index
     */
    function getDebtQueue() external view returns (uint256 first, uint256 last) {
        return (firstDebt, lastDebt);
    }

    /**
     * @dev get stopped validators count
     */
    function getStoppedValidatorsCount() external view returns (uint256) { return stoppedValidators; }

    /**
     * @dev get used quota
     */
    function getQuota(address account) external view returns (uint256) { return quotaUsed[account]; }

    /**
     * @dev check whitelist enabled
     */
    function isWhiteListed(address account) external view returns (bool) { return whiteList[account]; }


    /**
     * ======================================================================================
     * 
     * EXTERNAL FUNCTIONS
     * 
     * ======================================================================================
     */
    /**
     * @dev mint xETH with ETH
     */
    function mint(uint256 minToMint, uint256 deadline) external payable nonReentrant whenNotPaused returns(uint256 minted){
        require(block.timestamp < deadline, "USR001");
        require(msg.value > 0, "USR002");

        // for non KYC users, check the quota
        if (!whiteList[msg.sender]) {
            require(quotaUsed[msg.sender] + msg.value <= DEPOSIT_SIZE, "USR003");
            quotaUsed[msg.sender] += msg.value;
        }
        
        // track balance
        _balanceIncrease(msg.value);

        // mint xETH while keeping the exchange ratio invariant
        uint256 totalXETH = IERC20(xETHAddress).totalSupply();
        uint256 totalEthers = currentReserve();
        uint256 toMint = 1 * msg.value;  // default exchange ratio 1:1

        if (totalEthers > 0) { // avert division overflow
            toMint = totalXETH * msg.value / totalEthers;
        }

        // mint xETH
        require(toMint >= minToMint, "USR004");
        IMintableContract(xETHAddress).mint(msg.sender, toMint);
        totalPending += msg.value;

        return toMint;
    }

    /**
     * @dev redeem N * 32Ethers, which will turn off validadators,
     * note this function is asynchronous, the caller will only receive his ethers
     * after the validator has turned off.
     *
     * this function is dedicated for institutional operations.
     * 
     * redeem keeps the ratio invariant
     */
    function redeemFromValidators(uint256 ethersToRedeem, uint256 maxToBurn, uint256 deadline) external nonReentrant onlyPhase(1) returns(uint256 burned) {
        require(block.timestamp < deadline, "USR001");
        require(ethersToRedeem % DEPOSIT_SIZE == 0, "USR005");

        uint256 totalXETH = IERC20(xETHAddress).totalSupply();
        uint256 xETHToBurn = totalXETH * ethersToRedeem / currentReserve();
        require(xETHToBurn <= maxToBurn, "USR004");

        // NOTE: the following procdure must keep exchangeRatio invariant:
        // transfer xETH from sender & burn
        IERC20(xETHAddress).safeTransferFrom(msg.sender, address(this), xETHToBurn);
        IMintableContract(xETHAddress).burn(xETHToBurn);

        // queue ether debts
        _enqueueDebt(msg.sender, ethersToRedeem);

        // return burned 
        return xETHToBurn;
    }

    /** 
     * ======================================================================================
     * 
     * INTERNAL FUNCTIONS
     * 
     * ======================================================================================
     */

    function _balanceIncrease(uint256 amount) internal { accountedBalance += int256(amount); }
    function _balanceDecrease(uint256 amount) internal { accountedBalance -= int256(amount); }

    function _vectorClockTick() internal {
        vectorClockTicks++;
        vectorClock = keccak256(abi.encodePacked(vectorClock, block.timestamp, vectorClockTicks));
    }

    function _enqueueDebt(address account, uint256 amount) internal {
        // debt is paid in FIFO queue
        lastDebt += 1;
        etherDebts[lastDebt] = Debt({account:account, amount:amount});

        // track user debts
        userDebts[account] += amount;
        // track total debts
        totalDebts += amount;

        // log
        emit DebtQueued(account, amount);
    }

    function _dequeueDebt() internal returns (Debt memory debt) {
        require(lastDebt >= firstDebt, "SYS022");  // non-empty queue
        debt = etherDebts[firstDebt];
        delete etherDebts[firstDebt];
        firstDebt += 1;
    }

    /**
     * @dev pay debts for a given amount
     */
    function _payDebts(uint256 total) internal returns(uint256 amountPaid) {
        require(address(redeemContract) != address(0x0), "SYS023");

        // ethers to pay
        for (uint i=firstDebt;i<=lastDebt;i++) {
            if (total == 0) {
                break;
            }

            Debt storage debt = etherDebts[i];

            // clean debts
            uint256 toPay = debt.amount <= total? debt.amount:total;
            debt.amount -= toPay;
            total -= toPay;
            userDebts[debt.account] -= toPay;
            amountPaid += toPay;

            // transfer money to debt contract
            IRockXRedeem(redeemContract).pay{value:toPay}(debt.account);

            // dequeue if cleared 
            if (debt.amount == 0) {
                _dequeueDebt();
            }
        }
        
        totalDebts -= amountPaid;
        
        // track balance
        _balanceDecrease(amountPaid);
    }

    /**
     * @dev distribute revenue
     */
    function _distributeRewards(uint256 rewards) internal {
        // rewards distribution
        uint256 fee = rewards * managerFeeShare / 1000;
        accountedManagerRevenue += fee;
        accountedUserRevenue += rewards - fee;

        emit RevenueAccounted(rewards);
    }

    /**
     * @dev auto compounding, after shanghai merge, called in pushBeacon
     */
    function _autocompound() internal {
        if (autoCompoundEnabled) {
            // contract balance consists of maximum:
            // validator assets to clear debts, rewards after shanghai merge(compound), user's pending ethers to mint and manager's revenue.
            // autocompound & payDebts will race to use the incoming ethers, but eventually both will succeed.
            if (address(this).balance > accountedManagerRevenue + totalPending) {
                uint256 maxCompound = accountedUserRevenue - rewardDebts;
                uint256 maxUsable = address(this).balance - accountedManagerRevenue - totalPending;
                uint256 effectiveEthers = maxCompound < maxUsable? maxCompound:maxUsable;
                totalPending += effectiveEthers;
                rewardDebts += effectiveEthers;
            }
        }
    }

    /**
     * @dev spin up the node
     */
    function _spinup() internal {
         // load credential
        ValidatorCredential memory cred = validatorRegistry[nextValidatorId];
        _stake(cred.pubkey, cred.signature);
        nextValidatorId++;        

        // track total staked & total pending ethers
        totalStaked += DEPOSIT_SIZE;
        totalPending -= DEPOSIT_SIZE;
    }

    /**
     * @dev Invokes a deposit call to the official Deposit contract
     */
    function _stake(bytes memory pubkey, bytes memory signature) internal {
        require(withdrawalCredentials != bytes32(0x0), "SYS024");
        uint256 value = DEPOSIT_SIZE;
        uint256 depositAmount = DEPOSIT_SIZE / DEPOSIT_AMOUNT_UNIT;
        assert(depositAmount * DEPOSIT_AMOUNT_UNIT == value);    // properly rounded

        // Compute deposit data root (`DepositData` hash tree root)
        // https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa#code
        bytes32 pubkey_root = sha256(abi.encodePacked(pubkey, bytes16(0)));
        bytes32 signature_root = sha256(abi.encodePacked(
            sha256(BytesLib.slice(signature, 0, 64)),
            sha256(abi.encodePacked(BytesLib.slice(signature, 64, SIGNATURE_LENGTH - 64), bytes32(0)))
        ));
        
        bytes memory amount = to_little_endian_64(uint64(depositAmount));

        bytes32 depositDataRoot = sha256(abi.encodePacked(
            sha256(abi.encodePacked(pubkey_root, withdrawalCredentials)),
            sha256(abi.encodePacked(amount, bytes24(0), signature_root))
        ));

        IDepositContract(ethDepositContract).deposit{value:DEPOSIT_SIZE} (
            pubkey, abi.encodePacked(withdrawalCredentials), signature, depositDataRoot);

        // track balance
        _balanceDecrease(DEPOSIT_SIZE);
    }

    /**
     * @dev to little endian
     * https://etherscan.io/address/0x00000000219ab540356cbb839cbe05303d7705fa#code
     */
    function to_little_endian_64(uint64 value) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }

    /**
     * ======================================================================================
     * 
     * ROCKX SYSTEM EVENTS
     *
     * ======================================================================================
     */
    event ValidatorActivated(uint256 nextValidatorId);
    event ValidatorStopped(uint256 stoppedCount);
    event RevenueAccounted(uint256 amount);
    event ValidatorSlashedStopped(uint256 stoppedCount);
    event ManagerAccountSet(address account);
    event ManagerFeeSet(uint256 milli);
    event ManagerFeeWithdrawed(uint256 amount, address);
    event WithdrawCredentialSet(bytes32 withdrawCredential);
    event DebtQueued(address creditor, uint256 amountEther);
    event XETHContractSet(address addr);
    event DepositContractSet(address addr);
    event RedeemContractSet(address addr);
    event BalanceSynced(uint256 diff);
    event WhiteListToggle(address account, bool enabled);
    event AutoCompoundToggle(bool enabled);
}