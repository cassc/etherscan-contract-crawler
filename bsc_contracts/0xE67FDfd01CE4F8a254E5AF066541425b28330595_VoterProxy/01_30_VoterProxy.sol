// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
// General imports
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./GovernableImplementation.sol";
import "./ProxyImplementation.sol";

// Interfaces
import "./interfaces/IGauge.sol";
import "./interfaces/IUnCone.sol";
import "./interfaces/IUnkwnPool.sol";
import "./interfaces/IUnkwnPoolFactory.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IController.sol";
import "./interfaces/ICone.sol";
import "./interfaces/IConeBribe.sol";
import "./interfaces/IConeGauge.sol";
import "./interfaces/IConePool.sol";
import "./interfaces/IConeLens.sol";
import "./interfaces/ITokensAllowlist.sol";
import "./interfaces/IVe.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVoterProxy.sol";
import "./interfaces/IVoterProxyAssets.sol";
import "./interfaces/IVeDist.sol";

/**************************************************
 *                   Voter Proxy
 **************************************************/

contract VoterProxy is
    IERC721Receiver,
    GovernableImplementation,
    ProxyImplementation
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Public addresses
    address public unkwnPoolFactoryAddress;
    address public unConeAddress;
    uint256 public primaryTokenId;
    address public rewardsDistributorAddress;
    address public coneAddress;
    address public veAddress;
    address public veDistAddress;
    address public votingSnapshotAddress;

    // Public vars
    uint256 public coneInflationSinceInception;

    // Internal addresses
    address internal voterProxyAddress;

    // Internal interfaces
    IVoter internal voter;
    IController internal controller;
    IVe internal ve;
    IVeDist internal veDist;
    ITokensAllowlist internal tokensAllowlist;

    mapping(address => bool) internal claimDisabledByUnkwnPoolAddress;
    address whitelistCaller;
    bool whitelistNotRestricted;

    // Records cone stored in voterProxy for an unkwnPool
    mapping(address => uint256) public coneStoredForUnkwnPool;

    // Migration
    address public voterProxyAssetsAddress;
    IVoterProxyAssets internal voterProxyAssets;
    address public voterProxyTargetAddress;
    mapping(address => bool) public conePoolMigrated;

    // Operator for maximizing bribes and fees via votes
    mapping(address => bool) public operator;

    /**************************************************
     *                    Events
     **************************************************/
    event OperatorStatus(address indexed candidate, bool status);

    /**
     * @notice Initialize proxy storage
     */
    function initializeProxyStorage(
        address _veAddress,
        address _veDistAddress,
        address _tokensAllowlistAddress
    ) public checkProxyInitialized {
        // Set addresses
        veAddress = _veAddress;
        veDistAddress = _veDistAddress;

        // Set inflation
        coneInflationSinceInception = 1e18;

        // Set interfaces
        ve = IVe(veAddress);
        veDist = IVeDist(veDistAddress);
        controller = IController(ve.controller());
        voter = IVoter(controller.voter());
        tokensAllowlist = ITokensAllowlist(_tokensAllowlistAddress);
    }

    /**************************************************
     *                    Modifiers
     **************************************************/
    modifier onlyUnCone() {
        require(msg.sender == unConeAddress, "Only unCone can deposit NFTs");
        _;
    }

    modifier onlyUnkwnPool() {
        bool _isUnkwnPool = IUnkwnPoolFactory(unkwnPoolFactoryAddress)
            .isUnkwnPool(msg.sender);
        require(_isUnkwnPool, "Only unkwn pools can stake");
        _;
    }

    modifier onlyUnkwnPoolOrLegacyUnkwnPool() {
        require(
            IUnkwnPoolFactory(unkwnPoolFactoryAddress)
                .isUnkwnPoolOrLegacyUnkwnPool(msg.sender),
            "Only unkwn pools can stake"
        );
        _;
    }

    modifier onlyGovernanceOrVotingSnapshotOrOperator() {
        require(
            msg.sender == governanceAddress() ||
                operator[msg.sender] ||
                msg.sender == votingSnapshotAddress,
            "Only governance, voting snapshot, or operator"
        );
        _;
    }

    modifier voterProxyAssetsSet() {
        require(
            voterProxyAssetsAddress != address(0),
            "voterProxyAssetsAddress not set"
        );
        _;
    }

    /**
     * @notice Initialization
     * @param _unkwnPoolFactoryAddress unkwnPool factory address
     * @param _unConeAddress unCone address
     * @dev Can only be initialized once
     */
    function initialize(
        address _unkwnPoolFactoryAddress,
        address _unConeAddress,
        address _votingSnapshotAddress
    ) public {
        bool notInitialized = unkwnPoolFactoryAddress == address(0);
        require(notInitialized, "Already initialized");

        // Set addresses and interfaces
        unkwnPoolFactoryAddress = _unkwnPoolFactoryAddress;
        unConeAddress = _unConeAddress;
        coneAddress = IVe(veAddress).token();
        voterProxyAddress = address(this);
        rewardsDistributorAddress = IUnkwnPoolFactory(_unkwnPoolFactoryAddress)
            .rewardsDistributorAddress();
        votingSnapshotAddress = _votingSnapshotAddress;
    }

    /**************************************************
     *                  Gauge interactions
     **************************************************/

    /**
     * @notice Deposit CONE LP into a gauge
     * @param conePoolAddress Address of LP to deposit
     * @param amount Amount of LP to deposit
     */
    function depositInGauge(address conePoolAddress, uint256 amount)
        public
        onlyUnkwnPool
        voterProxyAssetsSet
    {
        // Cannot deposit nothing
        require(amount > 0, "Nothing to deposit");

        // unkwnPool has transferred LP to VoterProxy...

        // Find gauge address
        address gaugeAddress = voter.gauges(conePoolAddress);
        IConePool conePool = IConePool(conePoolAddress);
        conePool.transfer(voterProxyAssetsAddress, amount);

        // Claim cone on every interaction if possible
        bool coneClaimed = claimCone(msg.sender);

        // Deposit all LP if cone is claimed, withdraw all if not
        if (coneClaimed) {
            // Deposit CONE LP into gauge
            voterProxyAssets.depositInGauge(conePoolAddress, gaugeAddress);
        } else {
            uint256 gaugeBalance = IConeGauge(gaugeAddress).balanceOf(
                voterProxyAssetsAddress
            );
            if (gaugeBalance > 0) {
                voterProxyAssets.withdrawFromGauge(
                    conePoolAddress,
                    gaugeAddress,
                    IConeGauge(gaugeAddress).balanceOf(voterProxyAssetsAddress)
                );
            }
        }
    }

    /**
     * @notice Withdraw CONE LP from a gauge
     * @param conePoolAddress Address of LP to withdraw
     * @param amount Amount of LP to withdraw
     */
    function withdrawFromGauge(address conePoolAddress, uint256 amount)
        public
        onlyUnkwnPoolOrLegacyUnkwnPool
        voterProxyAssetsSet
    {
        require(amount > 0, "Nothing to withdraw");

        // Fetch gauge address
        address gaugeAddress = voter.gauges(conePoolAddress);
        IConePool conePool = IConePool(conePoolAddress);

        /**
         * Claim cone on every interaction if possible
         * In some cases it's not possible to claim due to an unbounded for loop in Coney gauge.getReward
         */
        bool coneClaimed = claimCone(msg.sender, false);

        if (!conePoolMigrated[conePoolAddress]) {
            migrateLp(conePoolAddress);
        }

        // Only withdraw from gauge if coneClaimed, otherwise enter caching mode
        if (coneClaimed) {
            // If there's LP in voterProxyAssets, it means we just got back from caching mode
            // deposit all except the withdrawal amount

            if (conePool.balanceOf(voterProxyAssetsAddress) > 0) {
                conePool.transferFrom(
                    voterProxyAssetsAddress,
                    msg.sender,
                    amount
                );
                voterProxyAssets.depositInGauge(conePoolAddress, gaugeAddress);
            } else {
                voterProxyAssets.withdrawFromGauge(
                    conePoolAddress,
                    gaugeAddress,
                    amount
                );
                conePool.transferFrom(
                    voterProxyAssetsAddress,
                    msg.sender,
                    amount
                );
            }
        } else {
            uint256 gaugeBalance = IConeGauge(gaugeAddress).balanceOf(
                voterProxyAssetsAddress
            );
            if (gaugeBalance > 0) {
                voterProxyAssets.withdrawFromGauge(
                    conePoolAddress,
                    gaugeAddress,
                    gaugeBalance
                );
            }
            conePool.transferFrom(voterProxyAssetsAddress, msg.sender, amount);
        }
    }

    /**
     * @notice Pokes LP into gauge if gauge is sync'd
     * @param unkwnPoolAddress Address of unkwnPool to poke
     * @param batchAmount Amount of checkpoints to sync
     */
    function pokeGauge(address unkwnPoolAddress, uint256 batchAmount)
        external
        voterProxyAssetsSet
    {
        // Find addresses
        address conePoolAddress = IUnkwnPool(unkwnPoolAddress)
            .conePoolAddress();
        address gaugeAddress = voter.gauges(conePoolAddress);

        // Determine lag
        uint256 lag = bribeSupplyLag(gaugeAddress, coneAddress);
        // If batchAmount is 0, default to max batch if lag > bribeSyncLagLimit
        // Adjust batchAmount to max batch if lag > bribeSyncLagLimit
        if (
            (batchAmount == 0 || batchAmount >= lag) &&
            lag > tokensAllowlist.bribeSyncLagLimit()
        ) {
            batchAmount = lag.sub(1);
        }
        // Batch checkpoints
        batchCheckPointOrGetReward(gaugeAddress, coneAddress, batchAmount);

        // Claim cone on every interaction if possible
        bool coneClaimed = claimCone(unkwnPoolAddress);

        // Deposit all LP if cone is claimed
        if (coneClaimed) {
            // Deposit CONE LP into gauge
            voterProxyAssets.depositInGauge(conePoolAddress, gaugeAddress);
        }
        notifyConeRewards(unkwnPoolAddress);
    }

    /**************************************************
     *                      Rewards
     **************************************************/

    /**
     * @notice Get fees from bribe
     * @param unkwnPoolAddress Address of unkwnPool
     */
    function getFeeTokensFromBribe(address unkwnPoolAddress)
        public
        returns (bool allClaimed)
    {
        // auth to prevent legacy pools from claiming but without reverting
        if (
            !IUnkwnPoolFactory(unkwnPoolFactoryAddress).isUnkwnPool(
                unkwnPoolAddress
            )
        ) {
            return true;
        }
        IUnkwnPool unkwnPool = IUnkwnPool(unkwnPoolAddress);
        IConeLens.Pool memory conePoolInfo = unkwnPool.conePoolInfo();
        address gaugeAddress = conePoolInfo.gaugeAddress;

        address[] memory feeTokenAddresses = new address[](2);
        feeTokenAddresses[0] = conePoolInfo.token0Address;
        feeTokenAddresses[1] = conePoolInfo.token1Address;
        (allClaimed, ) = getRewardFromBribe(
            unkwnPoolAddress,
            feeTokenAddresses
        );
        if (allClaimed) {
            // low-level call, so rest will still run even if revert
            // doing this because tax-on-transfer tokens brick cone's fee contracts
            gaugeAddress.call(abi.encodeWithSignature("claimFees()"));
        }
    }

    /**
     * @notice Claims LP CONE emissions and calls rewardsDistributor,
     * with a check if notifyConeThreshold should be respected or not.
     * @param unkwnPoolAddress the unkwnPool to claim for
     * @param isRespectingThreshold is it respecting the notifyConeThreshold
     * or not?
     */
    function claimCone(address unkwnPoolAddress, bool isRespectingThreshold)
        public
        returns (bool _claimCone)
    {
        // auth to prevent legacy pools from claiming but without reverting
        if (
            !IUnkwnPoolFactory(unkwnPoolFactoryAddress).isUnkwnPool(
                unkwnPoolAddress
            )
        ) {
            return false;
        }
        IUnkwnPool unkwnPool = IUnkwnPool(unkwnPoolAddress);
        IConeLens.Pool memory conePoolInfo = unkwnPool.conePoolInfo();
        address gaugeAddress = conePoolInfo.gaugeAddress;

        // low-level call, so rest will still run even if revert
        // doing this because tax-on-transfer tokens brick cone's fee contracts
        (bool distributed, ) = address(voter).call(
            abi.encodeWithSignature("distribute(address)", gaugeAddress)
        );

        _claimCone = (distributed &&
            _batchCheckPointOrGetReward(gaugeAddress, coneAddress));

        if (_claimCone) {
            // Claim CONE via voterProxyAssets
            uint256 amountClaimed = voterProxyAssets.claimCone(gaugeAddress);
            // Record CONE claimed
            coneStoredForUnkwnPool[unkwnPoolAddress] = coneStoredForUnkwnPool[
                unkwnPoolAddress
            ].add(amountClaimed);

            bool isStoredConeExceedingThreshold = coneStoredForUnkwnPool[
                unkwnPoolAddress
            ] > tokensAllowlist.notifyConeThreshold();
            if (isRespectingThreshold ? isStoredConeExceedingThreshold : true) {
                notifyConeRewards(unkwnPoolAddress);
            }
        }
    }

    function claimConeMultiple(
        address[] memory unkwnPoolAddresses,
        bool isRespectingThreshold
    ) public {
        for (uint256 i = 0; i < unkwnPoolAddresses.length; i++) {
            address unkwnPoolAddress = unkwnPoolAddresses[i];
            bool _claimCone;
            // auth to prevent legacy pools from claiming but without reverting
            if (
                !IUnkwnPoolFactory(unkwnPoolFactoryAddress).isUnkwnPool(
                    unkwnPoolAddress
                )
            ) {
                continue;
            }
            IUnkwnPool unkwnPool = IUnkwnPool(unkwnPoolAddress);
            IConeLens.Pool memory conePoolInfo = unkwnPool.conePoolInfo();
            address gaugeAddress = conePoolInfo.gaugeAddress;
            // low-level call, so rest will still run even if revert
            // doing this because tax-on-transfer tokens brick cone's fee contracts
            (bool distributed, ) = address(voter).call(
                abi.encodeWithSignature("distribute(address)", gaugeAddress)
            );
            _claimCone = (distributed &&
                _batchCheckPointOrGetReward(gaugeAddress, coneAddress));
            if (_claimCone) {
                // Claim CONE via voterProxyAssets
                uint256 amountClaimed = voterProxyAssets.claimCone(
                    gaugeAddress
                );
                // Record CONE claimed
                coneStoredForUnkwnPool[
                    unkwnPoolAddress
                ] = coneStoredForUnkwnPool[unkwnPoolAddress].add(amountClaimed);
                bool isStoredConeExceedingThreshold = coneStoredForUnkwnPool[
                    unkwnPoolAddress
                ] > tokensAllowlist.notifyConeThreshold();
                if (
                    isRespectingThreshold
                        ? isStoredConeExceedingThreshold
                        : true
                ) {
                    notifyConeRewards(unkwnPoolAddress);
                }
            }
        }
    }

    /**
     * @notice Claims LP CONE emissions and calls rewardsDistributor
     * @param unkwnPoolAddress the unkwnPool to claim for
     */
    function claimCone(address unkwnPoolAddress)
        public
        returns (bool _claimCone)
    {
        // auth to prevent legacy pools from claiming but without reverting
        if (
            !IUnkwnPoolFactory(unkwnPoolFactoryAddress).isUnkwnPool(
                unkwnPoolAddress
            )
        ) {
            return false;
        }
        IUnkwnPool unkwnPool = IUnkwnPool(unkwnPoolAddress);
        IConeLens.Pool memory conePoolInfo = unkwnPool.conePoolInfo();
        address gaugeAddress = conePoolInfo.gaugeAddress;

        // low-level call, so rest will still run even if revert
        // doing this because tax-on-transfer tokens brick cone's fee contracts
        (bool distributed, ) = address(voter).call(
            abi.encodeWithSignature("distribute(address)", gaugeAddress)
        );

        _claimCone = (distributed &&
            _batchCheckPointOrGetReward(gaugeAddress, coneAddress));

        if (_claimCone) {
            // Claim CONE via voterProxyAssets
            uint256 amountClaimed = voterProxyAssets.claimCone(gaugeAddress);
            // Record CONE claimed
            coneStoredForUnkwnPool[unkwnPoolAddress] = coneStoredForUnkwnPool[
                unkwnPoolAddress
            ].add(amountClaimed);

            if (
                coneStoredForUnkwnPool[unkwnPoolAddress] >
                tokensAllowlist.notifyConeThreshold()
            ) {
                notifyConeRewards(unkwnPoolAddress);
            }
        }
    }

    /**
     * @notice Notify cone rewards for an unkwnPool
     * @param unkwnPoolAddress the unkwnPool to nottify rewards for
     */
    function notifyConeRewards(address unkwnPoolAddress) public {
        // auth to prevent legacy pools from claiming but without reverting
        require(
            IUnkwnPoolFactory(unkwnPoolFactoryAddress).isUnkwnPool(
                unkwnPoolAddress
            ),
            "Not an unkwnPool"
        );

        IUnkwnPool unkwnPool = IUnkwnPool(unkwnPoolAddress);
        address stakingAddress = unkwnPool.stakingAddress();

        uint256 _coneEarned = coneStoredForUnkwnPool[unkwnPoolAddress];

        coneStoredForUnkwnPool[unkwnPoolAddress] = 0;

        IERC20(coneAddress).safeTransferFrom(
            voterProxyAssetsAddress,
            rewardsDistributorAddress,
            _coneEarned
        );
        IRewardsDistributor(rewardsDistributorAddress).notifyRewardAmount(
            stakingAddress,
            coneAddress,
            _coneEarned
        );
    }

    /**
     * @notice Notify cone rewards for an array of unkwnPools
     * @param unkwnPoolAddresses the unkwnPools to nottify rewards for
     */
    function notifyConeRewards(address[] memory unkwnPoolAddresses) public {
        for (uint256 i = 0; i < unkwnPoolAddresses.length; i++) {
            address unkwnPoolAddress = unkwnPoolAddresses[i];
            // auth to prevent legacy pools from claiming but without reverting
            require(
                IUnkwnPoolFactory(unkwnPoolFactoryAddress).isUnkwnPool(
                    unkwnPoolAddress
                ),
                "Not an unkwnPool"
            );
            IUnkwnPool unkwnPool = IUnkwnPool(unkwnPoolAddress);
            address stakingAddress = unkwnPool.stakingAddress();
            uint256 _coneEarned = coneStoredForUnkwnPool[unkwnPoolAddress];
            coneStoredForUnkwnPool[unkwnPoolAddress] = 0;
            IERC20(coneAddress).safeTransferFrom(
                voterProxyAssetsAddress,
                rewardsDistributorAddress,
                _coneEarned
            );
            IRewardsDistributor(rewardsDistributorAddress).notifyRewardAmount(
                stakingAddress,
                coneAddress,
                _coneEarned
            );
        }
    }

    /**
     * @notice Claim bribes and notify rewards contract of new balances
     * @param unkwnPoolAddress unkwnPool address
     * @param _tokensAddresses Bribe tokens addresses
     */
    function getRewardFromBribe(
        address unkwnPoolAddress,
        address[] memory _tokensAddresses
    ) public returns (bool allClaimed, bool[] memory claimed) {
        (allClaimed, claimed) = _getRewardFromCone(
            unkwnPoolAddress,
            _tokensAddresses,
            true
        );
    }

    /**
     * @notice Fetch reward from unkwnPool given token addresses
     * @param unkwnPoolAddress Address of the unkwnPool
     * @param tokensAddresses Tokens to fetch rewards for
     */
    function getRewardFromUnkwnPool(
        address unkwnPoolAddress,
        address[] memory tokensAddresses
    ) public {
        getRewardFromGauge(unkwnPoolAddress, tokensAddresses);
    }

    /**
     * @notice Fetch reward from gauge
     * @param unkwnPoolAddress Address of unkwnPool contract
     * @param _tokensAddresses Tokens to fetch rewards for
     */
    function getRewardFromGauge(
        address unkwnPoolAddress,
        address[] memory _tokensAddresses
    ) public returns (bool allClaimed, bool[] memory claimed) {
        (allClaimed, claimed) = _getRewardFromCone(
            unkwnPoolAddress,
            _tokensAddresses,
            false
        );
    }

    /**
     * @notice Fetch reward from CONE bribe or gauge
     * @param unkwnPoolAddress Address of unkwnPool contract
     * @param _tokensAddresses Tokens to fetch rewards for
     * @param fromBribe getting from bribe rather than gauge
     */
    function _getRewardFromCone(
        address unkwnPoolAddress,
        address[] memory _tokensAddresses,
        bool fromBribe
    )
        internal
        voterProxyAssetsSet
        returns (bool allClaimed, bool[] memory claimed)
    {
        // auth to prevent legacy pools from claiming but without reverting
        if (
            !IUnkwnPoolFactory(unkwnPoolFactoryAddress).isUnkwnPool(
                unkwnPoolAddress
            )
        ) {
            claimed = new bool[](_tokensAddresses.length);
            for (uint256 i; i < _tokensAddresses.length; i++) {
                claimed[i] = false;
            }
            return (false, claimed);
        }

        // Establish addresses
        IUnkwnPool unkwnPool = IUnkwnPool(unkwnPoolAddress);
        address _stakingAddress = unkwnPool.stakingAddress();
        address _gaugeOrBribeAddress;
        if (fromBribe) {
            IConeLens.Pool memory conePoolInfo = unkwnPool.conePoolInfo();
            _gaugeOrBribeAddress = conePoolInfo.bribeAddress;
        } else {
            _gaugeOrBribeAddress = unkwnPool.gaugeAddress();
        }

        // New array to record whether a token's claimed
        claimed = new bool[](_tokensAddresses.length);

        // Preflight - check whether to batch checkpoints or to claim said token
        address[] memory _claimableAddresses;
        _claimableAddresses = new address[](_tokensAddresses.length);
        uint256 j;

        // Populate a new array with addresses that are ready to be claimed
        for (uint256 i; i < _tokensAddresses.length; i++) {
            if (
                _batchCheckPointOrGetReward(
                    _gaugeOrBribeAddress,
                    _tokensAddresses[i]
                )
            ) {
                _claimableAddresses[j] = _tokensAddresses[i];
                claimed[j] = true;
                j++;
            }
        }
        // Clean up _claimableAddresses array, so we don't pass a bunch of address(0)s to IConeBribe
        address[] memory claimableAddresses = new address[](j);
        for (uint256 k; k < j; k++) {
            claimableAddresses[k] = _claimableAddresses[k];
        }

        // Actually claim rewards that are deemed claimable
        if (claimableAddresses.length != 0) {
            if (fromBribe) {
                voterProxyAssets.getRewardFromBribe(
                    _stakingAddress,
                    _gaugeOrBribeAddress,
                    claimableAddresses
                );
            } else {
                voterProxyAssets.getRewardFromGauge(
                    _stakingAddress,
                    _gaugeOrBribeAddress,
                    claimableAddresses
                );
            }
            // If everything was claimable, flag return to true
            if (claimableAddresses.length == _tokensAddresses.length) {
                if (
                    claimableAddresses[claimableAddresses.length - 1] !=
                    address(0)
                ) {
                    allClaimed = true;
                }
            }
        }
    }

    /**
     * @notice Batch fetch reward
     * @param bribeAddress Address of bribe
     * @param tokenAddress Reward token address
     * @param lagLimit Number of indexes per batch
     * @dev This method is important because if we don't do this CONE claiming can be bricked due to gas costs
     */
    function batchCheckPointOrGetReward(
        address bribeAddress,
        address tokenAddress,
        uint256 lagLimit
    ) public returns (bool _getReward) {
        if (tokenAddress == address(0)) {
            return _getReward; //returns false if address(0)
        }
        IConeBribe bribe = IConeBribe(bribeAddress);
        uint256 lastUpdateTime = bribe.lastUpdateTime(tokenAddress);
        uint256 priorSupplyIndex = bribe.getPriorSupplyIndex(lastUpdateTime);
        uint256 supplyNumCheckpoints = bribe.supplyNumCheckpoints();
        uint256 lag;
        if (supplyNumCheckpoints > priorSupplyIndex) {
            lag = supplyNumCheckpoints.sub(priorSupplyIndex);
        }
        if (lag > lagLimit) {
            bribe.batchUpdateRewardPerToken(
                tokenAddress,
                priorSupplyIndex.add(lagLimit)
            ); // costs about 250k gas, around 3% of an ftm block. Don't want to do too many since we need to chain these sometimes. Hardcoded to save some gas (probably don't need changing anyway)
        } else {
            _getReward = true;
        }
    }

    /**
     * @notice Internal reward batching
     * @param bribeAddress Address of bribe
     * @param tokenAddress Reward token address
     */
    function _batchCheckPointOrGetReward(
        address bribeAddress,
        address tokenAddress
    ) internal returns (bool _getReward) {
        uint256 lagLimit = tokensAllowlist.bribeSyncLagLimit();
        _getReward = batchCheckPointOrGetReward(
            bribeAddress,
            tokenAddress,
            lagLimit
        );
    }

    /**
     * @notice returns bribe contract supply checkpoint lag
     * @param bribeAddress Address of bribe
     * @param tokenAddress Reward token address
     * @dev This method is important because if we don't do this CONE claiming can be bricked due to gas costs
     */
    function bribeSupplyLag(address bribeAddress, address tokenAddress)
        public
        view
        returns (uint256 lag)
    {
        if (tokenAddress == address(0)) {
            return lag; //returns 0
        }
        IConeBribe bribe = IConeBribe(bribeAddress);
        uint256 lastUpdateTime = bribe.lastUpdateTime(tokenAddress);
        uint256 priorSupplyIndex = bribe.getPriorSupplyIndex(lastUpdateTime);
        uint256 supplyNumCheckpoints = bribe.supplyNumCheckpoints();
        if (supplyNumCheckpoints > priorSupplyIndex) {
            lag = supplyNumCheckpoints.sub(priorSupplyIndex);
        }
    }

    /**
     * @notice returns bribe contract supply checkpoint lag is out of sync or not
     * @param bribeAddress Address of bribe
     * @param tokenAddress Reward token address
     * @dev This method is important because if we don't do this CONE claiming can be bricked due to gas costs
     */
    function bribeSupplyOutOfSync(address bribeAddress, address tokenAddress)
        public
        view
        returns (bool outOfSync)
    {
        if (tokenAddress == address(0)) {
            return false; //returns false
        }
        IConeBribe bribe = IConeBribe(bribeAddress);
        uint256 lastUpdateTime = bribe.lastUpdateTime(tokenAddress);
        uint256 priorSupplyIndex = bribe.getPriorSupplyIndex(lastUpdateTime);
        uint256 supplyNumCheckpoints = bribe.supplyNumCheckpoints();
        uint256 lag;
        if (supplyNumCheckpoints > priorSupplyIndex) {
            lag = supplyNumCheckpoints.sub(priorSupplyIndex);
        }
        if (lag > tokensAllowlist.bribeSyncLagLimit()) {
            outOfSync = true;
        }
    }

    /**
     * @notice checks whether claiming cone can be done within block gas limit, returns false if it will run out-of-gas
     * @param gaugeAddress Address of gauge
     * @param tokenAddress Reward token address
     */
    function gaugeWithinOogSyncLimit(address gaugeAddress, address tokenAddress)
        public
        view
        returns (bool canClaim)
    {
        if (tokenAddress == address(0)) {
            return canClaim; //returns false if address(0)
        }
        uint256 lag = gaugeAccountLag(gaugeAddress, tokenAddress);

        uint256 oogLimit = tokensAllowlist.oogLoopLimit();
        if (oogLimit > lag) {
            canClaim = true;
        }
    }

    /**
     * @notice returns gauge account checkpoint lag
     * @param gaugeAddress Address of gauge
     * @param tokenAddress Reward token address
     */
    function gaugeAccountLag(address gaugeAddress, address tokenAddress)
        public
        view
        returns (uint256 lag)
    {
        if (tokenAddress == address(0)) {
            return lag; //returns 0
        }
        IConeGauge gauge = IConeGauge(gaugeAddress);
        uint256 lastUpdateTime = Math.max(
            gauge.lastEarn(tokenAddress, voterProxyAssetsAddress),
            gauge.rewardPerTokenCheckpoints(tokenAddress, 0).timestamp
        );

        uint256 priorBalanceIndex = gauge.getPriorBalanceIndex(
            voterProxyAssetsAddress,
            lastUpdateTime
        );
        uint256 numCheckpoints = gauge.numCheckpoints(voterProxyAssetsAddress);

        if (numCheckpoints > priorBalanceIndex.add(1)) {
            lag = numCheckpoints.sub(priorBalanceIndex).sub(1);
        }
    }

    /**************************************************
     *             Voting and Whitelisting
     **************************************************/

    /**
     * @notice Submit vote to CONE
     * @param poolVote Addresses of pools to vote on
     * @param weights Weights of pools to vote on
     * @dev For first round only governnce can vote, after that voting snapshot can vote
     */
    function vote(address[] memory poolVote, int256[] memory weights)
        external
        onlyGovernanceOrVotingSnapshotOrOperator
    {
        voterProxyAssets.vote(poolVote, weights);
    }

    function reset() external onlyGovernanceOrVotingSnapshotOrOperator {
        voterProxyAssets.reset();
    }

    /**
     * @notice Whitelist a token on CONE
     * @param tokenAddress Address to whitelist
     * @param tokenId Token ID to use for whitelist
     */
    function whitelist(address tokenAddress, uint256 tokenId)
        external
        onlyGovernanceOrVotingSnapshotOrOperator
    {
        voterProxyAssets.whitelist(tokenAddress, tokenId);
    }

    function whitelist(address tokenAddress) external {
        require(
            IUnCone(unConeAddress).balanceOf(msg.sender) > whitelistingFee(),
            "Insufficient unConelance"
        );
        require(
            msg.sender == whitelistCaller || whitelistNotRestricted,
            "Restricted function"
        );
        voterProxyAssets.whitelist(tokenAddress, primaryTokenId);
    }

    /**
     * @notice Sets operator that can vote and whitelist to maximize bribes
     * @param candidate Address of candidate
     * @param status candidate operator status
     */
    function setOperator(address candidate, bool status)
        external
        onlyGovernance
    {
        operator[candidate] = status;
        emit OperatorStatus(candidate, status);
    }

    /**************************************************
     *                   Migration
     **************************************************/

    function detachNFT(uint256 startingIndex, uint256 range)
        external
        onlyGovernance
    {
        IUnkwnPoolFactory unkwnPoolFactory = IUnkwnPoolFactory(
            unkwnPoolFactoryAddress
        );

        // calc endIndex, compare to existing unkwnPoolsLength
        uint256 endIndex = startingIndex.add(range);
        uint256 unkwnPoolsLength = unkwnPoolFactory.unkwnPoolsLength();
        if (endIndex > unkwnPoolsLength) {
            endIndex = unkwnPoolsLength;
        }

        // operation for each unkwnPool
        for (uint256 i = startingIndex; i < endIndex; i++) {
            // get gauge via unkwnPool
            IConeGauge gauge = IConeGauge(
                IUnkwnPool(unkwnPoolFactory.unkwnPools(i)).gaugeAddress()
            );

            // check if detached, detach if not
            if (gauge.tokenIds(address(this)) > 0) {
                gauge.withdrawToken(0, primaryTokenId);
            }
        }

        // if all done, transfer NFT and activate it in voterProxyAssets
        if (endIndex == unkwnPoolsLength) {
            // clear votes
            voter.reset(primaryTokenId);

            // transfer NFT
            ve.safeTransferFrom(
                address(this),
                voterProxyAssetsAddress,
                primaryTokenId
            );

            // setup NFT in voterProxyAssets
            voterProxyAssets.setPrimaryTokenId();
        }
    }

    function setVoterProxyAssetsAddress(address _voterProxyAssetsAddress)
        external
        onlyGovernance
    {
        require(
            _voterProxyAssetsAddress != address(0),
            "Invalid _voterProxyAssetsAddress"
        );
        IERC20 cone = IERC20(coneAddress);
        voterProxyAssetsAddress = _voterProxyAssetsAddress;
        voterProxyAssets = IVoterProxyAssets(_voterProxyAssetsAddress);
        cone.transfer(_voterProxyAssetsAddress, cone.balanceOf(address(this)));
    }

    function migrateLp(address conePoolAddress) public voterProxyAssetsSet {
        // this can replace auth, silently fail so it doesn't revert batch txs
        if (conePoolMigrated[conePoolAddress]) {
            return;
        }

        // Fetch gauge
        address gaugeAddress = voter.gauges(conePoolAddress);

        // Determine voter proxy addresses
        address _voterProxyAddress = address(this);

        // Find gauge balance of voter proxy
        uint256 gaugeBalance = IConeGauge(gaugeAddress).balanceOf(
            _voterProxyAddress
        );

        // Withdraw LP from voter proxy
        IConeGauge(gaugeAddress).withdraw(gaugeBalance);

        // TODO: make sure balance increased

        // Find total LP amount in voter proxy
        IConePool conePool = IConePool(conePoolAddress);
        uint256 totalBalance = conePool.balanceOf(address(this));

        // Transfer LP tokens to voterProxyAssets
        conePool.transfer(voterProxyAssetsAddress, totalBalance);
        bool gaugeSynced = _batchCheckPointOrGetReward(
            gaugeAddress,
            coneAddress
        );
        if (gaugeSynced) {
            voterProxyAssets.depositInGauge(conePoolAddress, gaugeAddress);
        } else {
            voterProxyAssets.withdrawFromGauge(
                conePoolAddress,
                gaugeAddress,
                0
            );
        }

        /**
         * Keep track of whether or not a migration is complete
         * This will be used during deposit and withdraw logic
         */
        conePoolMigrated[conePoolAddress] = true;
    }

    /**************************************************
     *               Ve Dillution mechanism
     **************************************************/

    /**
     * @notice Claims CONE inflation for veNFT, logs inflation record, mints corresponding UnCONE, and distributes UnCONE
     */
    function claim() external {
        uint256 lockedAmount = ve.locked(primaryTokenId);
        uint256 inflationAmount = voterProxyAssets.claim();
        coneInflationSinceInception = coneInflationSinceInception
            .mul(
                (inflationAmount.add(lockedAmount)).mul(1e18).div(lockedAmount)
            )
            .div(1e18);
        IUnCone(unConeAddress).mint(voterProxyAddress, inflationAmount);
        IERC20(unConeAddress).safeTransfer(
            rewardsDistributorAddress,
            inflationAmount
        );
        IRewardsDistributor(rewardsDistributorAddress).notifyRewardAmount(
            voterProxyAddress,
            unConeAddress,
            inflationAmount
        );
    }

    /**************************************************
     *                    Claims
     **************************************************/

    function setClaimDisabledUnkwnByPoolAddress(
        address poolAddress,
        bool disabled
    ) public onlyGovernance {
        claimDisabledByUnkwnPoolAddress[poolAddress] = disabled;
    }

    /**************************************************
     *                 NFT Interactions
     **************************************************/

    /**
     * @notice Deposit and merge NFT
     * @param tokenId The token ID to deposit
     * @dev Note: Depositing is a one way/nonreversible action
     */
    function depositNft(uint256 tokenId) public onlyUnCone {
        // Set primary token ID if it hasn't been set yet
        bool primaryTokenIdSet = primaryTokenId > 0;
        if (!primaryTokenIdSet) {
            primaryTokenId = tokenId;
        }

        // Transfer NFT from msg.sender to voterProxyAssets
        ve.safeTransferFrom(msg.sender, voterProxyAssetsAddress, tokenId);

        // If primary token ID is set, merge the NFT
        if (primaryTokenIdSet) {
            voterProxyAssets.depositNft(tokenId);
        }
    }

    /**
     * @notice Convert CONE to veNFT and deposit for UnCONE
     * @param amount The amount of CONE to lock
     */
    function lockCone(uint256 amount) external {
        ICone cone = ICone(coneAddress);
        cone.transferFrom(msg.sender, voterProxyAssetsAddress, amount);
        voterProxyAssets.lockCone(amount);
        IUnCone(unConeAddress).mint(msg.sender, amount);
    }

    /**
     * @notice Don't do anything with direct NFT transfers
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // function voterAddress() public view returns (address) {
    //     return ve.voter();
    // }

    /**************************************************
     *                   View methods
     **************************************************/

    /**
     * @notice Calculate amount of CONE currently claimable by VoterProxy
     * @param gaugeAddress The address of the gauge VoterProxy has earned on
     */
    function coneEarned(address gaugeAddress) public view returns (uint256) {
        return
            IGauge(gaugeAddress).earned(coneAddress, voterProxyAssetsAddress);
    }

    function whitelistingFee() public view returns (uint256) {
        return voter.listingFee();
    }

    /**************************************************
     *                   Setters
     **************************************************/

    function setWhitelistCaller(address _whitelistCaller)
        public
        onlyGovernance
    {
        whitelistCaller = _whitelistCaller;
    }

    function setWhitelistNotRestricted(bool _whitelistNotRestricted)
        public
        onlyGovernance
    {
        whitelistNotRestricted = _whitelistNotRestricted;
    }
}