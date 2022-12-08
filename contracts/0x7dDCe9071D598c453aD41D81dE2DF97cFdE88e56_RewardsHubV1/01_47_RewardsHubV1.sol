// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./interfaces/IBDSystem.sol";
import "./interfaces/IEmissionBooster.sol";
import "./interfaces/IMnt.sol";
import "./interfaces/IMToken.sol";
import "./libraries/ErrorCodes.sol";
import "./libraries/PauseControl.sol";
import "./InterconnectorLeaf.sol";

contract RewardsHubV1 is Initializable, ReentrancyGuard, AccessControl, PauseControl, InterconnectorLeaf {
    using SafeCast for uint256;
    using SafeERC20Upgradeable for IMnt;

    event DistributedSupplierMnt(
        IMToken indexed mToken,
        address indexed supplier,
        uint256 mntDelta,
        uint256 mntSupplyIndex
    );
    event DistributedBorrowerMnt(
        IMToken indexed mToken,
        address indexed borrower,
        uint256 mntDelta,
        uint256 mntBorrowIndex
    );
    event EmissionRewardAccrued(address indexed account, uint256 amount);
    event RepresentativeRewardAccrued(address indexed account, address provider, uint256 amount);
    event BuybackRewardAccrued(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event MntGranted(address recipient, uint256 amount);
    event MntSupplyEmissionRateUpdated(IMToken indexed mToken, uint256 newSupplyEmissionRate);
    event MntBorrowEmissionRateUpdated(IMToken indexed mToken, uint256 newBorrowEmissionRate);

    struct IndexState {
        uint224 index;
        uint32 block; // block number of the last index update
    }

    /// @dev The right part is the keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    uint256 internal constant EXP_SCALE = 1e18;
    uint256 internal constant DOUBLE_SCALE = 1e36;

    /// @notice The initial MNT index for a market
    uint224 internal constant MNT_INITIAL_INDEX = 1e36;

    IMnt public mnt;
    IEmissionBooster public emissionBooster;
    IBDSystem public bdSystem;

    /// @dev Contains amounts of regular rewards for individual accounts.
    mapping(address => uint256) public balances;

    // // // // // // MNT emissions

    /// @dev The rate at which MNT is distributed to the corresponding supply market (per block)
    mapping(IMToken => uint256) public mntSupplyEmissionRate;
    /// @dev The rate at which MNT is distributed to the corresponding borrow market (per block)
    mapping(IMToken => uint256) public mntBorrowEmissionRate;
    /// @dev The MNT market supply state for each market
    mapping(IMToken => IndexState) public mntSupplyState;
    /// @dev The MNT market borrow state for each market
    mapping(IMToken => IndexState) public mntBorrowState;
    /// @dev The MNT supply index and block number for each market
    /// for each supplier as of the last time they accrued MNT
    mapping(IMToken => mapping(address => IndexState)) public mntSupplierState;
    /// @dev The MNT borrow index and block number for each market
    /// for each supplier as of the last time they accrued MNT
    mapping(IMToken => mapping(address => IndexState)) public mntBorrowerState;

    /**
     * @notice Initialise RewardsHub contract
     * @param admin_ admin address
     * @param mnt_ Mnt contract address
     * @param emissionBooster_ EmissionBooster contract address
     * @param bdSystem_ BDSystem contract address
     */
    function initialize(
        address admin_,
        IMnt mnt_,
        IEmissionBooster emissionBooster_,
        IBDSystem bdSystem_
    ) public initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(TIMELOCK, admin_);

        mnt = mnt_;
        emissionBooster = emissionBooster_;
        bdSystem = bdSystem_;
    }

    // // // // Getters

    /**
     * @notice Gets summary amount of available and delayed balances of an account.
     */
    function totalBalanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @notice Gets amount of MNT that can be withdrawn from an account at this block.
     */
    function availableBalanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    // // // // MNT emissions

    /**
     * @notice Initializes market in RewardsHub. Should be called once from Supervisor.supportMarket
     * @dev RESTRICTION: Supervisor only
     */
    function initMarket(IMToken mToken) external {
        require(msg.sender == address(supervisor()), ErrorCodes.UNAUTHORIZED);
        require(
            mntSupplyState[mToken].index == 0 && mntBorrowState[mToken].index == 0,
            ErrorCodes.MARKET_ALREADY_LISTED
        );

        // Initialize MNT emission indexes of the market
        uint32 currentBlock = getBlockNumber();
        mntSupplyState[mToken] = IndexState({index: MNT_INITIAL_INDEX, block: currentBlock});
        mntBorrowState[mToken] = IndexState({index: MNT_INITIAL_INDEX, block: currentBlock});
    }

    /**
     * @dev Calculates the new state of the market.
     * @param state The block number the index was last updated at and the market's last updated mntBorrowIndex
     * or mntSupplyIndex in this block
     * @param emissionRate MNT rate that each market currently receives (supply or borrow)
     * @param totalBalance Total market balance (totalSupply or totalBorrow)
     * Note: this method doesn't return anything, it only mutates memory variable `state`.
     */
    function calculateUpdatedMarketState(
        IndexState memory state,
        uint256 emissionRate,
        uint256 totalBalance
    ) internal view {
        uint256 blockNumber = getBlockNumber();

        if (emissionRate > 0) {
            uint256 deltaBlocks = blockNumber - state.block;
            uint256 mntAccrued_ = deltaBlocks * emissionRate;
            uint256 ratio = totalBalance > 0 ? (mntAccrued_ * DOUBLE_SCALE) / totalBalance : 0;
            // index = lastUpdatedIndex + deltaBlocks * emissionRate / amount
            state.index += ratio.toUint224();
        }

        state.block = uint32(blockNumber);
    }

    /**
     * @dev Gets current market state (the block number and MNT supply index)
     * @param mToken The market whose MNT supply index to get
     */
    function getUpdatedMntSupplyIndex(IMToken mToken) internal view returns (IndexState memory supplyState) {
        supplyState = mntSupplyState[mToken];
        require(supplyState.index >= MNT_INITIAL_INDEX, ErrorCodes.MARKET_NOT_LISTED);
        calculateUpdatedMarketState(supplyState, mntSupplyEmissionRate[mToken], mToken.totalSupply());
        return supplyState;
    }

    /**
     * @dev Gets current market state (the block number and MNT supply index)
     * @param mToken The market whose MNT supply index to get
     */
    function getUpdatedMntBorrowIndex(IMToken mToken, uint224 marketBorrowIndex)
        internal
        view
        returns (IndexState memory borrowState)
    {
        borrowState = mntBorrowState[mToken];
        require(borrowState.index >= MNT_INITIAL_INDEX, ErrorCodes.MARKET_NOT_LISTED);
        uint256 borrowAmount = (mToken.totalBorrows() * EXP_SCALE) / marketBorrowIndex;
        calculateUpdatedMarketState(borrowState, mntBorrowEmissionRate[mToken], borrowAmount);
        return borrowState;
    }

    /**
     * @dev Accrue MNT to the market by updating the MNT supply index.
     * Index is a cumulative sum of the MNT per mToken accrued.
     * @param mToken The market whose MNT supply index to update
     */
    function updateMntSupplyIndex(IMToken mToken) internal {
        uint32 lastUpdatedBlock = mntSupplyState[mToken].block;
        if (lastUpdatedBlock == getBlockNumber()) return;

        if (emissionBooster.isEmissionBoostingEnabled()) {
            uint224 lastUpdatedIndex = mntSupplyState[mToken].index;
            IndexState memory currentState = getUpdatedMntSupplyIndex(mToken);
            mntSupplyState[mToken] = currentState;
            // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
            emissionBooster.updateSupplyIndexesHistory(mToken, lastUpdatedBlock, lastUpdatedIndex, currentState.index);
        } else {
            mntSupplyState[mToken] = getUpdatedMntSupplyIndex(mToken);
        }
    }

    /**
     * @dev Accrue MNT to the market by updating the MNT borrow index.
     * Index is a cumulative sum of the MNT per mToken accrued.
     * @param mToken The market whose MNT borrow index to update
     * @param marketBorrowIndex The market's last updated BorrowIndex
     */
    function updateMntBorrowIndex(IMToken mToken, uint224 marketBorrowIndex) internal {
        uint32 lastUpdatedBlock = mntBorrowState[mToken].block;
        if (lastUpdatedBlock == getBlockNumber()) return;

        if (emissionBooster.isEmissionBoostingEnabled()) {
            uint224 lastUpdatedIndex = mntBorrowState[mToken].index;
            IndexState memory currentState = getUpdatedMntBorrowIndex(mToken, marketBorrowIndex);
            mntBorrowState[mToken] = currentState;
            // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
            emissionBooster.updateBorrowIndexesHistory(mToken, lastUpdatedBlock, lastUpdatedIndex, currentState.index);
        } else {
            mntBorrowState[mToken] = getUpdatedMntBorrowIndex(mToken, marketBorrowIndex);
        }
    }

    /**
     * @notice Accrues MNT to the market by updating the borrow and supply indexes
     * @dev This method doesn't update MNT index history in Minterest NFT.
     * @param market The market whose supply and borrow index to update
     * @return (MNT supply index, MNT borrow index)
     */
    function updateAndGetMntIndexes(IMToken market) external returns (uint224, uint224) {
        IndexState memory supplyState = getUpdatedMntSupplyIndex(market);
        mntSupplyState[market] = supplyState;

        uint224 borrowIndex = market.borrowIndex().toUint224();
        IndexState memory borrowState = getUpdatedMntBorrowIndex(market, borrowIndex);
        mntBorrowState[market] = borrowState;

        return (supplyState.index, borrowState.index);
    }

    struct EmissionsDistributionVars {
        address account;
        address representative;
        uint256 representativeBonus;
        uint256 liquidityProviderBoost;
        uint256 accruedMnt;
    }

    /// @dev Basically EmissionsDistributionVars constructor
    function createDistributionState(address account)
        internal
        view
        checkPaused(DISTRIBUTION_OP)
        returns (EmissionsDistributionVars memory vars)
    {
        vars.account = account;

        (
            vars.liquidityProviderBoost,
            vars.representativeBonus,
            ,
            // ^^^ skips endBlock
            vars.representative
        ) = bdSystem.providerToAgreement(account);
    }

    /// @dev Accrues MNT emissions of account per market and saves result to EmissionsDistributionVars
    function updateDistributionState(
        EmissionsDistributionVars memory vars,
        IMToken mToken,
        uint256 accountBalance,
        uint224 currentMntIndex,
        IndexState storage accountIndex,
        bool isSupply
    ) internal {
        uint32 currentBlock = getBlockNumber();
        uint224 lastAccountIndex = accountIndex.index;
        uint32 lastUpdateBlock = accountIndex.block;

        if (lastAccountIndex == 0 && currentMntIndex >= MNT_INITIAL_INDEX) {
            // Covers the case where users interacted with market before its state index was set.
            // Rewards the user with MNT accrued from the start of when account rewards were first
            // set for the market.
            lastAccountIndex = MNT_INITIAL_INDEX;
            lastUpdateBlock = currentBlock;
        }

        // Update supplier's index and block to the current index and block since we are distributing accrued MNT
        accountIndex.index = currentMntIndex;
        accountIndex.block = currentBlock;

        if (currentMntIndex == lastAccountIndex) return;

        uint256 deltaIndex = currentMntIndex - lastAccountIndex;

        if (vars.representative != address(0)) {
            // Calc change in the cumulative sum of the MNT per mToken accrued (with considering BD system boosts)
            deltaIndex += (deltaIndex * vars.liquidityProviderBoost) / EXP_SCALE;
        } else {
            // Calc change in the cumulative sum of the MNT per mToken accrued (with considering NFT emission boost).
            // NFT emission boost doesn't work with liquidity provider emission boost at the same time.
            deltaIndex += emissionBooster.calculateEmissionBoost(
                mToken,
                vars.account,
                lastAccountIndex,
                lastUpdateBlock,
                currentMntIndex,
                isSupply
            );
        }

        uint256 accruedMnt = (accountBalance * deltaIndex) / DOUBLE_SCALE;
        vars.accruedMnt += accruedMnt;

        if (isSupply) emit DistributedSupplierMnt(mToken, vars.account, accruedMnt, currentMntIndex);
        else emit DistributedBorrowerMnt(mToken, vars.account, accruedMnt, currentMntIndex);
    }

    /// @dev Accumulate accrued MNT to user balance and its BDR representative if they have any.
    /// Also updates buyback and voting weights for user
    function payoutDistributionState(EmissionsDistributionVars memory vars) internal {
        if (vars.accruedMnt == 0) return;

        balances[vars.account] += vars.accruedMnt;
        emit EmissionRewardAccrued(vars.account, vars.accruedMnt);

        if (vars.representative != address(0)) {
            uint256 repReward = (vars.accruedMnt * vars.representativeBonus) / EXP_SCALE;
            balances[vars.representative] += repReward;
            emit RepresentativeRewardAccrued(vars.representative, vars.account, repReward);
        }

        // Use relaxed update so it could skip if buyback update is paused
        buyback().updateBuybackAndVotingWeightsRelaxed(vars.account);
    }

    /**
     * @notice Shorthand function to distribute MNT emissions from supplies of one market.
     */
    function distributeSupplierMnt(IMToken mToken, address account) external {
        updateMntSupplyIndex(mToken);

        EmissionsDistributionVars memory vars = createDistributionState(account);
        uint256 supplyAmount = mToken.balanceOf(account);
        updateDistributionState(
            vars,
            mToken,
            supplyAmount,
            mntSupplyState[mToken].index,
            mntSupplierState[mToken][account],
            true
        );
        payoutDistributionState(vars);
    }

    /**
     * @notice Shorthand function to distribute MNT emissions from borrows of one market.
     */
    function distributeBorrowerMnt(IMToken mToken, address account) external {
        uint224 borrowIndex = mToken.borrowIndex().toUint224();
        updateMntBorrowIndex(mToken, borrowIndex);

        EmissionsDistributionVars memory vars = createDistributionState(account);
        uint256 borrowAmount = (mToken.borrowBalanceStored(account) * EXP_SCALE) / borrowIndex;
        updateDistributionState(
            vars,
            mToken,
            borrowAmount,
            mntBorrowState[mToken].index,
            mntBorrowerState[mToken][account],
            false
        );
        payoutDistributionState(vars);
    }

    /**
     * @notice Updates market indices and distributes tokens (if any) for holder
     * @dev Updates indices and distributes only for those markets where the holder have a
     * non-zero supply or borrow balance.
     * @param account The address to distribute MNT for
     */
    function distributeAllMnt(address account) external nonReentrant {
        return distributeAccountMnt(account, supervisor().getAllMarkets(), true, true);
    }

    /**
     * @notice Distribute all MNT accrued by the accounts
     * @param accounts The addresses to distribute MNT for
     * @param mTokens The list of markets to distribute MNT in
     * @param borrowers Whether or not to distribute MNT earned by borrowing
     * @param suppliers Whether or not to distribute MNT earned by supplying
     */
    function distributeMnt(
        address[] calldata accounts,
        IMToken[] calldata mTokens,
        bool borrowers,
        bool suppliers
    ) external nonReentrant {
        ISupervisor cachedSupervisor = supervisor();
        for (uint256 i = 0; i < mTokens.length; i++) {
            require(cachedSupervisor.isMarketListed(mTokens[i]), ErrorCodes.MARKET_NOT_LISTED);
        }
        for (uint256 i = 0; i < accounts.length; i++) {
            distributeAccountMnt(accounts[i], mTokens, borrowers, suppliers);
        }
    }

    function distributeAccountMnt(
        address account,
        IMToken[] memory mTokens,
        bool borrowers,
        bool suppliers
    ) internal {
        EmissionsDistributionVars memory vars = createDistributionState(account);

        for (uint256 i = 0; i < mTokens.length; i++) {
            IMToken mToken = mTokens[i];
            if (borrowers) {
                uint256 accountBorrowUnderlying = mToken.borrowBalanceStored(account);
                if (accountBorrowUnderlying > 0) {
                    uint224 borrowIndex = mToken.borrowIndex().toUint224();
                    updateMntBorrowIndex(mToken, borrowIndex);
                    updateDistributionState(
                        vars,
                        mToken,
                        (accountBorrowUnderlying * EXP_SCALE) / borrowIndex,
                        mntBorrowState[mToken].index,
                        mntBorrowerState[mToken][account],
                        false
                    );
                }
            }
            if (suppliers) {
                uint256 accountSupplyWrap = mToken.balanceOf(account);
                if (accountSupplyWrap > 0) {
                    updateMntSupplyIndex(mToken);
                    updateDistributionState(
                        vars,
                        mToken,
                        accountSupplyWrap,
                        mntSupplyState[mToken].index,
                        mntSupplierState[mToken][account],
                        true
                    );
                }
            }
        }

        payoutDistributionState(vars);
    }

    // // // // Rewards accrual

    /**
     * @notice Accrues buyback reward
     * @dev RESTRICTION: Buyback only
     */
    function accrueBuybackReward(address account, uint256 amount) external {
        require(msg.sender == address(buyback()), ErrorCodes.UNAUTHORIZED);
        accrueReward(account, amount);
        emit BuybackRewardAccrued(account, amount);
    }

    function accrueReward(address account, uint256 amount) internal {
        revert("unimplemented"); // TODO: Implement delay buckets

        balances[account] += amount;
    }

    // // // // Withdrawal

    /**
     * @notice Transfers available part of MNT rewards to the sender.
     * This will decrease accounts buyback and voting weights.
     */
    function withdraw(uint256 amount) external checkPaused(WITHDRAW_OP) {
        revert("unimplemented"); // TODO: Claim rewards unlocked from delay here

        uint256 balance = balances[msg.sender];
        if (amount == type(uint256).max) amount = balance;

        require(amount <= balance, ErrorCodes.INCORRECT_AMOUNT);
        balances[msg.sender] = balance - amount;

        emit Withdraw(msg.sender, amount);

        buyback().updateBuybackAndVotingWeights(msg.sender);
        mnt.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Transfers
     * @dev RESTRICTION: Admin only
     */
    function grant(address recipient, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount > 0, ErrorCodes.INCORRECT_AMOUNT);

        uint256 balance = mnt.balanceOf(address(this));
        require(balance >= amount, ErrorCodes.INSUFFICIENT_MNT_FOR_GRANT);

        emit MntGranted(recipient, amount);

        mnt.safeTransfer(recipient, amount);
    }

    // // // // Admin zone

    /**
     * @notice Set MNT borrow and supply emission rates for a single market
     * @param mToken The market whose MNT emission rate to update
     * @param newMntSupplyEmissionRate New supply MNT emission rate for market
     * @param newMntBorrowEmissionRate New borrow MNT emission rate for market
     * @dev RESTRICTION Timelock only
     */
    function setMntEmissionRates(
        IMToken mToken,
        uint256 newMntSupplyEmissionRate,
        uint256 newMntBorrowEmissionRate
    ) external onlyRole(TIMELOCK) {
        require(supervisor().isMarketListed(mToken), ErrorCodes.MARKET_NOT_LISTED);

        if (mntSupplyEmissionRate[mToken] != newMntSupplyEmissionRate) {
            // Supply emission rate updated so let's update supply state to ensure that
            //  1. MNT accrued properly for the old emission rate.
            //  2. MNT accrued at the new speed starts after this block.
            updateMntSupplyIndex(mToken);

            // Update emission rate and emit event
            mntSupplyEmissionRate[mToken] = newMntSupplyEmissionRate;
            emit MntSupplyEmissionRateUpdated(mToken, newMntSupplyEmissionRate);
        }

        if (mntBorrowEmissionRate[mToken] != newMntBorrowEmissionRate) {
            // Borrow emission rate updated so let's update borrow state to ensure that
            //  1. MNT accrued properly for the old emission rate.
            //  2. MNT accrued at the new speed starts after this block.
            uint224 borrowIndex = mToken.borrowIndex().toUint224();
            updateMntBorrowIndex(mToken, borrowIndex);

            // Update emission rate and emit event
            mntBorrowEmissionRate[mToken] = newMntBorrowEmissionRate;
            emit MntBorrowEmissionRateUpdated(mToken, newMntBorrowEmissionRate);
        }
    }

    // // // // Pause control

    bytes32 internal constant DISTRIBUTION_OP = "MntDistribution";
    bytes32 internal constant WITHDRAW_OP = "Withdraw";

    function validatePause(address) internal view override {
        require(hasRole(GATEKEEPER, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    function validateUnpause(address) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), ErrorCodes.UNAUTHORIZED);
    }

    // // // // Utils

    function getTimestamp() internal view virtual returns (uint32) {
        return block.timestamp.toUint32();
    }

    function getBlockNumber() internal view virtual returns (uint32) {
        return uint32(block.number);
    }

    function supervisor() internal view returns (ISupervisor) {
        return getInterconnector().supervisor();
    }

    function buyback() internal view returns (IBuyback) {
        return getInterconnector().buyback();
    }
}