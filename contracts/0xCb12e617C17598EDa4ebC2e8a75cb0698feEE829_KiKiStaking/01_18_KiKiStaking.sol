// SPDX-License-Identifier: MIT

pragma solidity 0.4.24;

import "@aragon/os/contracts/common/Initializable.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";
import "@aragon/os/contracts/lib/math/SafeMath64.sol";
import "@aragon/os/contracts/common/IsContract.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "solidity-bytes-utils/contracts/BytesLib.sol";

import "./interfaces/IKiKiStaking.sol";
import "./interfaces/INodeOperatorsRegistry.sol";
import "./interfaces/IDepositContract.sol";
import "./KiKiStakingToken.sol";
import "./lib/StakeLimitUtils.sol";

/**
* @title Liquid staking pool implementation
*
* KiKiStaking is an Ethereum 2.0 liquid staking protocol solving the problem of frozen staked Ethers
* until transfers become available in Ethereum 2.0.
*
* NOTE: the code below assumes moderate amount of node operators, e.g. up to 50.
*
* Since balances of all token holders change when the amount of total pooled Ether
* changes, this token cannot fully implement ERC20 standard: it only emits `Transfer`
* events upon explicit transfer between holders. In contrast, when KiKiStaking oracle reports
* rewards, no Transfer events are generated: doing so would require emitting an event
* for each token holder and thus running an unbounded loop.
*/
contract KiKiStaking is IKiKiStaking, KiKiStakingToken, IsContract, Ownable, Initializable
{
    using SafeMath for uint256;
    using SafeMath64 for uint64;
    using StakeLimitUnstructuredStorage for bytes32;
    using StakeLimitUtils for StakeLimitState.Data;

    /// ACL
    bytes32 constant public PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 constant public RESUME_ROLE = keccak256("RESUME_ROLE");
    bytes32 constant public STAKING_PAUSE_ROLE = keccak256("STAKING_PAUSE_ROLE");
    bytes32 constant public STAKING_CONTROL_ROLE = keccak256("STAKING_CONTROL_ROLE");
    bytes32 constant public MANAGE_FEE = keccak256("MANAGE_FEE");
    bytes32 constant public MANAGE_WITHDRAWAL_KEY = keccak256("MANAGE_WITHDRAWAL_KEY");
    bytes32 constant public BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 constant public DEPOSIT_ROLE = keccak256("DEPOSIT_ROLE");
    bytes32 constant public LIQUIDITY_POOL_ROLE = keccak256("LIQUIDITY_POOL_ROLE");
    bytes32 constant public MANAGE_PROTOCOL_CONTRACTS_ROLE = keccak256("MANAGE_PROTOCOL_CONTRACTS_ROLE");

    

    uint256 constant public PUBKEY_LENGTH = 48;
    uint256 constant public WITHDRAWAL_CREDENTIALS_LENGTH = 32;
    uint256 constant public SIGNATURE_LENGTH = 96;

    uint256 constant public DEPOSIT_SIZE = 32 ether;

    uint256 internal constant DEPOSIT_AMOUNT_UNIT = 1000000000 wei;

    /// @dev default value for maximum number of Ethereum 2.0 validators registered in a single depositBufferedEther call
    uint256 internal constant DEFAULT_MAX_DEPOSITS_PER_CALL = 150;

    bytes32 internal constant FEE_POSITION = keccak256("kiki.kiki.fee");

    bytes32 internal constant DEPOSIT_CONTRACT_POSITION = keccak256("kiki.kiki.depositContract");
    bytes32 internal constant ORACLE_POSITION = keccak256("kiki.kiki.oracle");
    bytes32 internal constant NODE_OPERATORS_REGISTRY_POSITION = keccak256("kiki.kiki.nodeOperatorsRegistry");
    bytes32 internal constant MASTER_CHEF_POSITION = keccak256("kiki.kiki.masterChef");
    bytes32 internal constant TREASURY_POSITION = keccak256("kiki.kiki.treasury");

    /// @dev storage slot position of the staking rate limit structure
    bytes32 internal constant STAKING_STATE_POSITION = keccak256("kiki.kiki.stakeLimit");
    /// @dev amount of Ether (on the current Ethereum side) buffered on this smart contract balance
    bytes32 internal constant BUFFERED_ETHER_POSITION = keccak256("kiki.kiki.bufferedEther");
    /// @dev amount of Ether (on the current Ethereum side) in liquidity pool pool on this smart contract balance
    bytes32 internal constant LIQUIDITY_POOLED_POSITION = keccak256("kiki.kiki.liquidityPooledEther");
    /// @dev number of deposited validators (incrementing counter of deposit operations).
    bytes32 internal constant DEPOSITED_VALIDATORS_POSITION = keccak256("kiki.kiki.depositedValidators");
    /// @dev total amount of Beacon-side Ether (sum of all the balances of KiKiStaking validators)
    bytes32 internal constant BEACON_BALANCE_POSITION = keccak256("kiki.kiki.beaconBalance");
    /// @dev number of KiKi's validators available in the Beacon state
    bytes32 internal constant BEACON_VALIDATORS_POSITION = keccak256("kiki.kiki.beaconValidators");
    /// @dev Credentials which allows the DAO to withdraw Ether on the 2.0 side
    bytes32 internal constant WITHDRAWAL_CREDENTIALS_POSITION = keccak256("kiki.kiki.withdrawalCredentials");    
    /// @dev liquidity pool percent, based on 10000 point
    bytes32 internal constant LIQUIDITY_POOL_CAP_PERCENT_POSITION = keccak256("kiki.kiki.liquidityPoolCapPercent");
    /// @dev liquidity pool min fee, based on 10000 point
    bytes32 internal constant LIQUIDITY_POOL_MIN_FEE_POSITION = keccak256("kiki.kiki.liquidityPoolMinFee");
    /// @dev liquidity pool max fee, based on 10000 point
    bytes32 internal constant LIQUIDITY_POOL_MAX_FEE_POSITION = keccak256("kiki.kiki.liquidityPoolMaxFee");
    
    /**
    * @dev KiKiStaking contract must be initialized with following variables:
    * @param _depositContract official ETH2 Deposit contract
    * @param _oracle oracle contract
    * @param _operators instance of Node Operators Registry
    * @param _treasury treasury contract
    * @param _masterChef masterChef contract
    */
    function initialize(
        IDepositContract _depositContract,
        address _oracle,
        INodeOperatorsRegistry _operators,
        address _treasury,
        IMasterChef _masterChef
    )
        public 
        onlyInit
        onlyOwner
    {
        _setDepositContract(_depositContract);
        _setOperators(_operators);
        _setProtocolContracts(_oracle, _treasury, _masterChef);

        initialized();
    }

    /**
    * @notice Stops accepting new Ether to the protocol
    *
    * @dev While accepting new Ether is stopped, calls to the `submit` function,
    * as well as to the default payable function, will revert.
    *
    * Emits `StakingPaused` event.
    */
    function pauseStaking() external onlyOwner {

        _pauseStaking();
    }

     /**
    * @notice Resumes accepting new Ether to the protocol (if `pauseStaking` was called previously)
    * NB: Staking could be rate-limited by imposing a limit on the stake amount
    * at each moment in time, see `setStakingLimit()` and `removeStakingLimit()`
    *
    * @dev Preserves staking limit if it was set previously
    *
    * Emits `StakingResumed` event
    */
    function resumeStaking() external onlyOwner {
        _resumeStaking();
    }

     /**
      * @notice Set liquidity pool percent to `points`, need manager role
      * @param points Percent points, base on 10000
      */
    function setLiquidityPoolPercent(uint16 points) external onlyOwner {        
        if (_readBPValue(LIQUIDITY_POOL_CAP_PERCENT_POSITION) != points) {
            uint256 total = _getTotalStakedEther();
            uint256 newLiquidityPoolCap = total.mul(points).div(10000);
            uint256 oldLiquidityPooled = _getLiquidityPooledEther();
            uint256 oldBuffered = _getBufferedEther();
            uint256 newLiquidityPooled;
            uint256 newBuffered;
            if (oldLiquidityPooled.add(oldBuffered) <= newLiquidityPoolCap) {
                newLiquidityPooled = oldLiquidityPooled.add(oldBuffered);
                newBuffered = 0;
            } else {
                newLiquidityPooled = newLiquidityPoolCap;
                newBuffered = oldBuffered.add(oldLiquidityPooled).sub(newLiquidityPoolCap);
            }
            _setBPValue(LIQUIDITY_POOL_CAP_PERCENT_POSITION, points);
            BUFFERED_ETHER_POSITION.setStorageUint256(newBuffered);
            LIQUIDITY_POOLED_POSITION.setStorageUint256(newLiquidityPooled);
        }
    }

    /**
      * @notice Set liquidity pool fee percent 
      * @param minPoints Min percent points, base on 10000
      * @param maxPoints Max percent points, base on 10000
      */
    function setLiquidityPoolFeePercent(uint16 minPoints, uint16 maxPoints) external onlyOwner {
        require(minPoints <= maxPoints, "minPoints can not greater than maxPoints");
        _setBPValue(LIQUIDITY_POOL_MIN_FEE_POSITION, minPoints);
        _setBPValue(LIQUIDITY_POOL_MAX_FEE_POSITION, maxPoints);
    }

    /**
    * @notice Sets the staking rate limit
    *
    * ▲ Stake limit
    * │.....  .....   ........ ...            ....     ... Stake limit = max
    * │      .       .        .   .   .      .    . . .
    * │     .       .              . .  . . .      . .
    * │            .                .  . . .
    * │──────────────────────────────────────────────────> Time
    * │     ^      ^          ^   ^^^  ^ ^ ^     ^^^ ^     Stake events
    *
    * @dev Reverts if:
    * - `_maxStakeLimit` == 0
    * - `_maxStakeLimit` >= 2^96
    * - `_maxStakeLimit` < `_stakeLimitIncreasePerBlock`
    * - `_maxStakeLimit` / `_stakeLimitIncreasePerBlock` >= 2^32 (only if `_stakeLimitIncreasePerBlock` != 0)
    *
    * Emits `StakingLimitSet` event
    *
    * @param _maxStakeLimit max stake limit value
    * @param _stakeLimitIncreasePerBlock stake limit increase per single block
    */
    function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external onlyOwner {
        STAKING_STATE_POSITION.setStorageStakeLimitStruct(
            STAKING_STATE_POSITION.getStorageStakeLimitStruct().setStakingLimit(
                _maxStakeLimit,
                _stakeLimitIncreasePerBlock
            )
        );

        emit StakingLimitSet(_maxStakeLimit, _stakeLimitIncreasePerBlock);
    }

   /**
    * @notice Removes the staking rate limit
    *
    * Emits `StakingLimitRemoved` event
    */
    function removeStakingLimit() external onlyOwner {
        STAKING_STATE_POSITION.setStorageStakeLimitStruct(
            STAKING_STATE_POSITION.getStorageStakeLimitStruct().removeStakingLimit()
        );

        emit StakingLimitRemoved();
    }

    /**
    * @notice Check staking state: whether it's paused or not
    */
    function isStakingPaused() external view returns (bool) {
        return STAKING_STATE_POSITION.getStorageStakeLimitStruct().isStakingPaused();
    }

    /**
    * @notice Returns how much Ether can be staked in the current block
    * @dev Special return values:
    * - 2^256 - 1 if staking is unlimited;
    * - 0 if staking is paused or if limit is exhausted.
    */
    function getCurrentStakeLimit() public view returns (uint256) {
        return _getCurrentStakeLimit(STAKING_STATE_POSITION.getStorageStakeLimitStruct());
    }



    /**
    * @notice Returns the liquidity pool percent point, based on 10000
    */
    function getLiquidityPoolCapPercent() public view returns (uint16) {
        return _readBPValue(LIQUIDITY_POOL_CAP_PERCENT_POSITION);
    }

    /**
    * @notice Returns the min and max liquidity pool fee percent point, based on 10000
    */
    function getLiquidityPoolFeePercent() public view returns (uint16, uint16) {
        return (_readBPValue(LIQUIDITY_POOL_MIN_FEE_POSITION), _readBPValue(LIQUIDITY_POOL_MAX_FEE_POSITION));
    }

    /**
    * @notice Returns the liquidity pool fee by ether amount `etherAmount`
    * @param etherAmount eth amount
    * @return liquidity pool fee
    */
    function getLiquidityPoolFeeByEtherAmount(uint256 etherAmount) public view returns (uint256) {
        return etherAmount.mul(getLiquidityPoolFeePointsByEtherAmount(etherAmount)).div(10000);
    }

    /**
    * @notice Returns the liquidity pool fee percent points by ether amount `etherAmount`, based on 10000
    * @param etherAmount eth amount
    * @return liquidity pool fee points
    */
    function getLiquidityPoolFeePointsByEtherAmount(uint256 etherAmount) public view returns (uint16) {
        uint256 liquidityPoolCap = _getLiquidityPoolCap();
        require(liquidityPoolCap != 0, "LiquidityPoolCap is zero");
        uint256 liquidityPooled  = _getLiquidityPooledEther();
        uint256 outEth = liquidityPooled  > etherAmount ? etherAmount : liquidityPooled;
        uint256 newLiquidityPoolCap = (_getTotalStakedEther()).sub(outEth).mul(getLiquidityPoolCapPercent()).div(10000);
        require(newLiquidityPoolCap != 0, "newLiquidityPoolCap is zero");
        (uint16 minFee, uint16 maxFee) = getLiquidityPoolFeePercent();
        if (maxFee == minFee) {
            return minFee;
        } else {   
            // k = (maxFee - minFee) / liquidityPoolCap;
            // feePoints = (liquidityPoolCap - liquidityPooled + outEth) * k + minFee;
            uint256 feePoints = newLiquidityPoolCap.sub(liquidityPooled).add(outEth).mul(uint256(maxFee).sub(minFee)).div(newLiquidityPoolCap).add(minFee);
            assert(feePoints <= 10000);
            return uint16(feePoints);
        }
    }


    /**
    * @notice calculate the new liquidityPooled ether and new buffred ether when new submit happened
    * @param _value new dopsited eth amount
    * @return new liquidityPooled ether and new buffred ether
    */
    function getLiquidityPoolNewStatus(uint256 _value) internal view returns (uint256 newLiquidityPooled, uint256 newBuffered) {
        uint256 total = _value.add(_getTotalStakedEther());
        uint16 liquidityPoolCapPercentPoints = _readBPValue(LIQUIDITY_POOL_CAP_PERCENT_POSITION);
        uint256 newLiquidityPoolCap = total.mul(liquidityPoolCapPercentPoints).div(10000);
        uint256 oldLiquidityPooled = _getLiquidityPooledEther();
        uint256 oldBuffered = _getBufferedEther();
        if (oldLiquidityPooled.add(_value) <= newLiquidityPoolCap) {
            newLiquidityPooled = oldLiquidityPooled.add(_value);
            newBuffered = oldBuffered;
        } else {
            newLiquidityPooled = newLiquidityPoolCap;
            newBuffered = oldBuffered.add(_value).add(oldLiquidityPooled).sub(newLiquidityPoolCap);
        }
    }



    /**
    * @notice Send funds to the pool
    * @dev Users are able to submit their funds by transacting to the fallback function.
    * Unlike vanilla Eth2.0 Deposit contract, accepting only 32-Ether transactions, KiKiStaking
    * accepts payments of any size. Submitted Ethers are stored in Buffer until someone calls
    * depositBufferedEther() and pushes them to the ETH2 Deposit contract.
    */
    function() external payable {
        // protection against accidental submissions by calling non-existent function
        require(msg.data.length == 0, "NON_EMPTY_DATA");
        _submit(0);
    }

    /**
    * @notice Send funds to the pool with optional _referral parameter
    * @dev This function is alternative way to submit funds. Supports optional referral address.
    * @return Amount of StETH shares generated
    */
    function submit(address _referral) external payable returns (uint256) {
        return _submit(_referral);
    }

    /**
    * @notice Deposits buffered ethers to the official DepositContract.
    * @dev This function is separated from submit() to reduce the cost of sending funds.
    */
    function depositBufferedEther() external onlyOwner {
        return _depositBufferedEther(DEFAULT_MAX_DEPOSITS_PER_CALL);
    }

    /**
      * @notice Deposits buffered ethers to the official DepositContract, making no more than `_maxDeposits` deposit calls.
      * @dev This function is separated from submit() to reduce the cost of sending funds.
      */
    function depositBufferedEther(uint256 _maxDeposits) external onlyOwner {
        return _depositBufferedEther(_maxDeposits);
    }

    function burnShares(address _account, uint256 _sharesAmount)
        external
        onlyOwner
        returns (uint256 newTotalShares)
    {
        return _burnShares(_account, _sharesAmount);
    }

    /**
    * @notice Stop pool routine operations
    */
    function stop() external onlyOwner {
        _stop();
        _pauseStaking();
    }

    /**
    * @notice Resume pool routine operations
    * @dev Staking should be resumed manually after this call using the desired limits
    */
    function resume() external onlyOwner {
        _resume();
        _resumeStaking();
    }

    /**
      * @notice Set fee rate to `_feeBasisPoints` basis points. The fees are accrued when oracles report staking results
      * @param _feeBasisPoints Fee rate, in basis points
      */
    function setFee(uint16 _feeBasisPoints) external onlyOwner {        
        _setBPValue(FEE_POSITION, _feeBasisPoints);
        emit FeeSet(_feeBasisPoints);
    }



     /**
    * @notice Set KiKiStaking protocol contracts (oracle, treasury, masterChef).
    *
    * @dev Oracle contract specified here is allowed to make
    * periodical updates of beacon stats
    * by calling pushBeacon. Treasury contract specified here is used
    * to accumulate the protocol treasury fee. MasterChef contract
    * specified here is used to mint kiki to participant.
    *
    * @param _oracle oracle contract
    * @param _treasury treasury contract
    * @param _masterChef masterChef contract
    */
    function setProtocolContracts(
        address _oracle,
        address _treasury,
        address _masterChef
    ) external onlyOwner {
        _setProtocolContracts(_oracle, _treasury, _masterChef);
    }


    /**
    * @dev Internal function to set authorized oracle address
    * @param _oracle oracle contract
    */
    function _setProtocolContracts(address _oracle, address _treasury, address _masterChef) internal {
        require(_oracle != address(0), "ORACLE_ZERO_ADDRESS");
        require(_treasury != address(0), "TREASURY_ZERO_ADDRESS");
        require(_masterChef != address(0), "MASTER_CHEF_ZERO_ADDRESS");

        ORACLE_POSITION.setStorageAddress(_oracle);
        TREASURY_POSITION.setStorageAddress(_treasury);
        MASTER_CHEF_POSITION.setStorageAddress(_masterChef);

        emit ProtocolContractsSet(_oracle, _treasury, _masterChef);
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "ORACLE_ZERO_ADDRESS");
        ORACLE_POSITION.setStorageAddress(_oracle);
    }

    /**
      * @notice Set credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched to `_withdrawalCredentials`
      * @dev Note that setWithdrawalCredentials discards all unused signing keys as the signatures are invalidated.
      * @param _withdrawalCredentials hash of withdrawal multisignature key as accepted by
      *        the deposit_contract.deposit function
      */
    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external onlyOwner {
        WITHDRAWAL_CREDENTIALS_POSITION.setStorageBytes32(_withdrawalCredentials);
        getOperators().trimUnusedKeys();

        emit WithdrawalCredentialsSet(_withdrawalCredentials);
    }


    /**
    * @notice Updates the number of KiKiStaking-controlled keys in the beacon validators set and their total balance.
    * @dev periodically called by the Oracle contract
    * @param _beaconValidators number of KiKiStaking's keys in the beacon state
    * @param _beaconBalance summarized balance of KiKiStaking-controlled keys in wei
    */
    function handleOracleReport(uint256 _beaconValidators, uint256 _beaconBalance) external whenNotStopped {
        require(msg.sender == getOracle(), "APP_AUTH_FAILED");

        uint256 depositedValidators = DEPOSITED_VALIDATORS_POSITION.getStorageUint256();
        require(_beaconValidators <= depositedValidators, "REPORTED_MORE_DEPOSITED");

        uint256 beaconValidators = BEACON_VALIDATORS_POSITION.getStorageUint256();
        // Since the calculation of funds in the ingress queue is based on the number of validators
        // that are in a transient state (deposited but not seen on beacon yet), we can't decrease the previously
        // reported number (we'll be unable to figure out who is in the queue and count them).
        require(_beaconValidators >= beaconValidators, "REPORTED_LESS_VALIDATORS");
        uint256 appearedValidators = _beaconValidators.sub(beaconValidators);

        // RewardBase is the amount of money that is not included in the reward calculation
        // Just appeared validators * 32 added to the previously reported beacon balance
        uint256 rewardBase = (appearedValidators.mul(DEPOSIT_SIZE)).add(BEACON_BALANCE_POSITION.getStorageUint256());

        // Save the current beacon balance and validators to
        // calcuate rewards on the next push
        BEACON_BALANCE_POSITION.setStorageUint256(_beaconBalance);
        BEACON_VALIDATORS_POSITION.setStorageUint256(_beaconValidators);

        if (_beaconBalance > rewardBase) {
            uint256 rewards = _beaconBalance.sub(rewardBase);
            distributeFee(rewards);
        }
    }



    /**
      * @notice Returns staking rewards fee rate
      */
    function getFee() external view returns (uint16 feeBasisPoints) {
        return _getFee();
    }

    /**
      * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
      */
    function getWithdrawalCredentials() public view returns (bytes32) {
        return WITHDRAWAL_CREDENTIALS_POSITION.getStorageBytes32();
    }

    /**
    * @notice Get the amount of Ether temporary buffered on this contract balance
    * @dev Buffered balance is kept on the contract from the moment the funds are received from user
    * until the moment they are actually sent to the official Deposit contract.
    * @return uint256 of buffered funds in wei
    */
    function getBufferedEther() external view returns (uint256) {
        return _getBufferedEther();
    }


    /**
      * @notice Issues swap `_amount` kETH to ETH from liquidity pool, transfer to `to`.
      * @param _amount Amount of kETH to burn
      * @param to Recipient
      * @return ETH actual withdraw ethers
      */
    function withdraw(uint256 _amount, address to) external {
        require(_amount <= _sharesOf(msg.sender), "Not enough balance");
        require(address(0) != to, "Transfer to zero address");
        uint256 ethAmount = getPooledEthByShares(_amount);
        uint256 liquidityPooled  = _getLiquidityPooledEther();
        require(liquidityPooled != 0, "liquidityPooled ethers is zero");
        uint256 outEth = liquidityPooled  > ethAmount ? ethAmount : liquidityPooled ;
        _withdraw(msg.sender, to, outEth);
    }



    /**
      * @notice Gets deposit contract handle
      */
    function getDepositContract() public view returns (IDepositContract) {
        return IDepositContract(DEPOSIT_CONTRACT_POSITION.getStorageAddress());
    }

    /**
    * @notice Gets authorized oracle address
    * @return address of oracle contract
    */
    function getOracle() public view returns (address) {
        return ORACLE_POSITION.getStorageAddress();
    }

    /**
      * @notice Gets node operators registry interface handle
      */
    function getOperators() public view returns (INodeOperatorsRegistry) {
        return INodeOperatorsRegistry(NODE_OPERATORS_REGISTRY_POSITION.getStorageAddress());
    }


    /**
      * @notice Gets masterChef interface handle
      */
    function getMasterChef() public view returns (IMasterChef) {
        return IMasterChef(MASTER_CHEF_POSITION.getStorageAddress());
    }

    /**
      * @notice Returns the Treasury address
      */
    function getTreasury() public view returns (address) {
        return TREASURY_POSITION.getStorageAddress();
    }

    /**
    * @notice Returns the key values related to Beacon-side
    * @return depositedValidators - number of deposited validators
    * @return beaconValidators - number of KiKiStaking's validators visible in the Beacon state, reported by oracles
    * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of KiKiStaking validators)
    */
    function getBeaconStat() public view returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance) {
        depositedValidators = DEPOSITED_VALIDATORS_POSITION.getStorageUint256();
        beaconValidators = BEACON_VALIDATORS_POSITION.getStorageUint256();
        beaconBalance = BEACON_BALANCE_POSITION.getStorageUint256();
    }


    function getLiquidityPooledEther() public view returns (uint256) {
        return _getLiquidityPooledEther();
    }

    /**
      * @notice Gets the liquidity pool Cap
      */
    function getLiquidityPoolCap() public view returns (uint256) {
        return _getLiquidityPoolCap();
    }


    /**
    * @dev Sets the address of Deposit contract
    * @param _contract the address of Deposit contract
    */
    function _setDepositContract(IDepositContract _contract) internal {
        require(isContract(address(_contract)), "D_NOT_A_CONTRACT");
        DEPOSIT_CONTRACT_POSITION.setStorageAddress(address(_contract));
    }


    /**
    * @dev Internal function to set node operator registry address
    * @param _r registry of node operators
    */
    function _setOperators(INodeOperatorsRegistry _r) internal {
        require(isContract(_r), "NOT_A_CONTRACT");
        NODE_OPERATORS_REGISTRY_POSITION.setStorageAddress(_r);
    }


    /**
    * @dev Process user deposit, mints liquid tokens and increase the pool buffer
    * @param _referral address of referral.
    * @return amount of StETH shares generated
    */
    function _submit(address _referral) internal returns (uint256) {
        address sender = msg.sender;
        uint256 deposit = msg.value;
        require(deposit != 0, "ZERO_DEPOSIT");
        StakeLimitState.Data memory stakeLimitData = STAKING_STATE_POSITION.getStorageStakeLimitStruct();

        require(!stakeLimitData.isStakingPaused(), "STAKING_PAUSED");

        if (stakeLimitData.isStakingLimitSet()) {
            uint256 currentStakeLimit = stakeLimitData.calculateCurrentStakeLimit();

            require(msg.value <= currentStakeLimit, "STAKE_LIMIT");

            STAKING_STATE_POSITION.setStorageStakeLimitStruct(
                stakeLimitData.updatePrevStakeLimit(currentStakeLimit - msg.value)
            );
        }

        uint256 sharesAmount = getSharesByPooledEth(deposit);
        if (sharesAmount == 0) {
            // totalControlledEther is 0: either the first-ever deposit or complete slashing
            // assume that shares correspond to Ether 1-to-1
            sharesAmount = deposit;
        }

        _mintShares(sender, sharesAmount);
        _submitted(sender, deposit, _referral);
        return sharesAmount;
    }


    /**
    * @dev Deposits buffered eth to the DepositContract and assigns chunked deposits to node operators
    */
    function _depositBufferedEther(uint256 _maxDeposits) internal whenNotStopped {
        uint256 buffered = _getBufferedEther();
        if (buffered >= DEPOSIT_SIZE) {
            uint256 unaccounted = _getUnaccountedEther();
            uint256 numDeposits = buffered.div(DEPOSIT_SIZE);
            _markAsUnbuffered(_ETH2Deposit(numDeposits < _maxDeposits ? numDeposits : _maxDeposits));
            assert(_getUnaccountedEther() == unaccounted);
        }
    }

    /**
    * @dev Performs deposits to the ETH 2.0 side
    * @param _numDeposits Number of deposits to perform
    * @return actually deposited Ether amount
    */
    function _ETH2Deposit(uint256 _numDeposits) internal returns (uint256) {
        (bytes memory pubkeys, bytes memory signatures) = getOperators().assignNextSigningKeys(_numDeposits);
        if (pubkeys.length == 0) {
            return 0;
        }

        require(pubkeys.length.mod(PUBKEY_LENGTH) == 0, "REGISTRY_INCONSISTENT_PUBKEYS_LEN");
        require(signatures.length.mod(SIGNATURE_LENGTH) == 0, "REGISTRY_INCONSISTENT_SIG_LEN");

        uint256 numKeys = pubkeys.length.div(PUBKEY_LENGTH);
        require(numKeys == signatures.length.div(SIGNATURE_LENGTH), "REGISTRY_INCONSISTENT_SIG_COUNT");

        for (uint256 i = 0; i < numKeys; ++i) {
            bytes memory pubkey = BytesLib.slice(pubkeys, i * PUBKEY_LENGTH, PUBKEY_LENGTH);
            bytes memory signature = BytesLib.slice(signatures, i * SIGNATURE_LENGTH, SIGNATURE_LENGTH);
            _stake(pubkey, signature);
        }

        DEPOSITED_VALIDATORS_POSITION.setStorageUint256(
            DEPOSITED_VALIDATORS_POSITION.getStorageUint256().add(numKeys)
        );

        return numKeys.mul(DEPOSIT_SIZE);
    }

    /**
    * @dev Invokes a deposit call to the official Deposit contract
    * @param _pubkey Validator to stake for
    * @param _signature Signature of the deposit call
    */
    function _stake(bytes memory _pubkey, bytes memory _signature) internal {
        bytes32 withdrawalCredentials = getWithdrawalCredentials();
        require(withdrawalCredentials != 0, "EMPTY_WITHDRAWAL_CREDENTIALS");

        uint256 value = DEPOSIT_SIZE;

        // The following computations and Merkle tree-ization will make official Deposit contract happy
        uint256 depositAmount = value.div(DEPOSIT_AMOUNT_UNIT);
        assert(depositAmount.mul(DEPOSIT_AMOUNT_UNIT) == value);    // properly rounded

        // Compute deposit data root (`DepositData` hash tree root) according to deposit_contract.sol
        bytes32 pubkeyRoot = sha256(_pad64(_pubkey));
        bytes32 signatureRoot = sha256(
            abi.encodePacked(
                sha256(BytesLib.slice(_signature, 0, 64)),
                sha256(_pad64(BytesLib.slice(_signature, 64, SIGNATURE_LENGTH.sub(64))))
            )
        );

        bytes32 depositDataRoot = sha256(
            abi.encodePacked(
                sha256(abi.encodePacked(pubkeyRoot, withdrawalCredentials)),
                sha256(abi.encodePacked(_toLittleEndian64(depositAmount), signatureRoot))
            )
        );

        uint256 targetBalance = address(this).balance.sub(value);

        getDepositContract().deposit.value(value)(
            _pubkey, abi.encodePacked(withdrawalCredentials), _signature, depositDataRoot);
        emit Stake(_pubkey);
        require(address(this).balance == targetBalance, "EXPECTING_DEPOSIT_TO_HAPPEN");
    }

    /**
    * @dev Distributes fee portion of the rewards by minting and distributing corresponding amount of liquid tokens.
    * @param _totalRewards Total rewards accrued on the Ethereum 2.0 side in wei
    */
    function distributeFee(uint256 _totalRewards) internal {
        // We need to take a defined percentage of the reported reward as a fee, and we do
        // this by minting new token shares and assigning them to the fee recipients (see
        // StETH docs for the explanation of the shares mechanics). The staking rewards fee
        // is defined in basis points (1 basis point is equal to 0.01%, 10000 is 100%).
        //
        // Since we've increased totalPooledEther by _totalRewards (which is already
        // performed by the time this function is called), the combined cost of all holders'
        // shares has became _totalRewards StETH tokens more, effectively splitting the reward
        // between each token holder proportionally to their token share.
        //
        // Now we want to mint new shares to the fee recipient, so that the total cost of the
        // newly-minted shares exactly corresponds to the fee taken:
        //
        // shares2mint * newShareCost = (_totalRewards * feeBasis) / 10000
        // newShareCost = newTotalPooledEther / (prevTotalShares + shares2mint)
        //
        // which follows to:
        //
        //                        _totalRewards * feeBasis * prevTotalShares
        // shares2mint = --------------------------------------------------------------
        //                 (newTotalPooledEther * 10000) - (feeBasis * _totalRewards)
        //
        // The effect is that the given percentage of the reward goes to the fee recipient, and
        // the rest of the reward is distributed between token holders proportionally to their
        // token shares.
        uint256 feeBasis = _getFee();
        uint256 totalPooledEther = _getTotalPooledEther();
        uint256 shares2mint = (
            _totalRewards.mul(feeBasis).mul(_getTotalShares())
            .div(
                totalPooledEther.mul(10000)
                .sub(feeBasis.mul(_totalRewards))
            )
        );

        // Mint the calculated amount of shares to fee address
        _mintShares(getTreasury(), shares2mint);
    }

    /**
    * @dev Records a deposit made by a user with optional referral
    * @param _sender sender's address
    * @param _value Deposit value in wei
    * @param _referral address of the referral
    */
    function _submitted(address _sender, uint256 _value, address _referral) internal {
        _updateLiquidityPool(_value);
        emit Submitted(_sender, _value, _referral);
    }

    /**
      * @dev Records a deposit to the deposit_contract.deposit function.
      * @param _amount Total amount deposited to the ETH 2.0 side
      */
    function _markAsUnbuffered(uint256 _amount) internal {
        BUFFERED_ETHER_POSITION.setStorageUint256(
            BUFFERED_ETHER_POSITION.getStorageUint256().sub(_amount));

        emit Unbuffered(_amount);
    }

    /**
      * @dev Write a value nominated in basis points
      */
    function _setBPValue(bytes32 _slot, uint16 _value) internal {
        require(_value <= 10000, "VALUE_OVER_100_PERCENT");
        _slot.setStorageUint256(uint256(_value));
    }

    /**
      * @dev Returns staking rewards fee rate
      */
    function _getFee() internal view returns (uint16) {
        return _readBPValue(FEE_POSITION);
    }

    /**
      * @dev Read a value nominated in basis points
      */
    function _readBPValue(bytes32 _slot) internal view returns (uint16) {
        uint256 v = _slot.getStorageUint256();
        assert(v <= 10000);
        return uint16(v);
    }

    /**
      * @dev Gets the amount of Ether temporary buffered on this contract balance
      */
    function _getBufferedEther() internal view returns (uint256) {
        uint256 buffered = BUFFERED_ETHER_POSITION.getStorageUint256();

        return buffered;
    }

    /**
      * @dev Gets the amount of Ether temporary in liquidity pool on this contract balance
      */
    function _getLiquidityPooledEther() internal view returns (uint256) {
        uint256 buffered = LIQUIDITY_POOLED_POSITION.getStorageUint256();
        return buffered;
    }

    /**
      * @dev Gets the amount of Ether temporary in liquidity pool and buffered on this contract balance
      */
    function _getBufferedAndLiquidityPooled() internal view returns (uint256) {
        uint256 buffered = BUFFERED_ETHER_POSITION.getStorageUint256();
        buffered = buffered.add(LIQUIDITY_POOLED_POSITION.getStorageUint256());
        return buffered;
    }

    /**
      * @dev Gets unaccounted (excess) Ether on this contract balance
      */
    function _getUnaccountedEther() internal view returns (uint256) {
        return address(this).balance.sub(_getBufferedAndLiquidityPooled());
    }

    /**
    * @dev Calculates and returns the total base balance (multiple of 32) of validators in transient state,
    *      i.e. submitted to the official Deposit contract but not yet visible in the beacon state.
    * @return transient balance in wei (1e-18 Ether)
    */
    function _getTransientBalance() internal view returns (uint256) {
        uint256 depositedValidators = DEPOSITED_VALIDATORS_POSITION.getStorageUint256();
        uint256 beaconValidators = BEACON_VALIDATORS_POSITION.getStorageUint256();
        // beaconValidators can never be less than deposited ones.
        assert(depositedValidators >= beaconValidators);
        uint256 transientValidators = depositedValidators.sub(beaconValidators);
        return transientValidators.mul(DEPOSIT_SIZE);
    }

    /**
    * @dev Gets the total amount of Ether controlled by the system
    * @return total balance in wei
    */
    function _getTotalPooledEther() internal view returns (uint256) {
        uint256 bufferedBalance = _getBufferedAndLiquidityPooled();
        uint256 beaconBalance = BEACON_BALANCE_POSITION.getStorageUint256();
        uint256 transientBalance = _getTransientBalance();
        return bufferedBalance.add(beaconBalance).add(transientBalance);
    }

     function _getTotalStakedEther() internal view returns (uint256) {
        return _getBufferedEther().add(_getLiquidityPooledEther()).add(DEPOSITED_VALIDATORS_POSITION.getStorageUint256().mul(DEPOSIT_SIZE));
    }

    function _getLiquidityPoolCap() internal view returns (uint256) {
        uint16 liquidityPoolCapPercentPoints = getLiquidityPoolCapPercent();
        uint256 total = _getTotalStakedEther();
        return total.mul(liquidityPoolCapPercentPoints).div(10000);
    }

    function _updateLiquidityPool(uint256 _value) internal {
        (uint256 newLiquidityPooled, uint256 newBuffered) = getLiquidityPoolNewStatus(_value);
        if (_getBufferedEther() != newBuffered) {
            BUFFERED_ETHER_POSITION.setStorageUint256(newBuffered);
        }
        LIQUIDITY_POOLED_POSITION.setStorageUint256(newLiquidityPooled);
    }

     function _pauseStaking() internal {
        STAKING_STATE_POSITION.setStorageStakeLimitStruct(
            STAKING_STATE_POSITION.getStorageStakeLimitStruct().setStakeLimitPauseState(true)
        );

        emit StakingPaused();
    }

    function _resumeStaking() internal {
        STAKING_STATE_POSITION.setStorageStakeLimitStruct(
            STAKING_STATE_POSITION.getStorageStakeLimitStruct().setStakeLimitPauseState(false)
        );

        emit StakingResumed();
    }

    function _getCurrentStakeLimit(StakeLimitState.Data memory _stakeLimitData) internal view returns(uint256) {
        if (_stakeLimitData.isStakingPaused()) {
            return 0;
        }
        if (!_stakeLimitData.isStakingLimitSet()) {
            return uint256(-1);
        }

        return _stakeLimitData.calculateCurrentStakeLimit();
    }

    /**
      * @dev Padding memory array with zeroes up to 64 bytes on the right
      * @param _b Memory array of size 32 .. 64
      */
    function _pad64(bytes memory _b) internal pure returns (bytes memory) {
        assert(_b.length >= 32 && _b.length <= 64);
        if (64 == _b.length)
            return _b;

        bytes memory zero32 = new bytes(32);
        assembly { mstore(add(zero32, 0x20), 0) }

        if (32 == _b.length)
            return BytesLib.concat(_b, zero32);
        else
            return BytesLib.concat(_b, BytesLib.slice(zero32, 0, uint256(64).sub(_b.length)));
    }

    /**
      * @dev Converting value to little endian bytes and padding up to 32 bytes on the right
      * @param _value Number less than `2**64` for compatibility reasons
      */
    function _toLittleEndian64(uint256 _value) internal pure returns (uint256 result) {
        result = 0;
        uint256 temp_value = _value;
        for (uint256 i = 0; i < 8; ++i) {
            result = (result << 8) | (temp_value & 0xFF);
            temp_value >>= 8;
        }

        assert(0 == temp_value);    // fully converted
        result <<= (24 * 8);
    }

    function to64(uint256 v) internal pure returns (uint64) {
        assert(v <= uint256(uint64(-1)));
        return uint64(v);
    }
    
    
    function _withdraw(address from, address recipient, uint256 ethAmount) internal whenNotStopped {
        uint256 fee = getLiquidityPoolFeeByEtherAmount(ethAmount);
        uint256 outEth = ethAmount.sub(fee);
        uint256 kETHAmount = getSharesByPooledEth(outEth);
        _burnShares(from, kETHAmount);
        LIQUIDITY_POOLED_POSITION.setStorageUint256(_getLiquidityPooledEther().sub(ethAmount));
        safeTransferETH(getTreasury(), fee);
        emit Withdraw(from, recipient, outEth, kETHAmount);
        safeTransferETH(recipient, outEth);
    }

    function safeTransferETH(address to, uint256 value) internal whenNotStopped {
        (bool success, )  = to.call.value(value)("");
        require(
            success,
            "KiKiStaking::safeTransferETH: ETH transfer failed"
        );
    }

    
}