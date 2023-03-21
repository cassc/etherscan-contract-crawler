pragma solidity ^0.8.18;

// SPDX-License-Identifier: BUSL-1.1

import { GiantLP } from "./GiantLP.sol";
import { StakingFundsVault } from "./StakingFundsVault.sol";
import { LPToken } from "./LPToken.sol";
import { GiantPoolBase } from "./GiantPoolBase.sol";
import { SyndicateRewardsProcessor } from "./SyndicateRewardsProcessor.sol";
import { LSDNFactory } from "./LSDNFactory.sol";
import { LPToken } from "./LPToken.sol";
import { GiantLPDeployer } from "./GiantLPDeployer.sol";
import { Errors } from "./Errors.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { MainnetConstants, GoerliConstants } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";
import { IAccountManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IAccountManager.sol";

/// @notice A giant pool that can provide liquidity to any liquid staking network's staking funds vault
contract GiantMevAndFeesPool is
    GiantPoolBase,
    SyndicateRewardsProcessor,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;

    error ContractPaused();
    error ReentrancyCall();

    /// @notice Emitted when a user withdraws their LSD LP token by burning their giant LP
    event LPWithdrawn(address indexed lp, address indexed user);

    /// @notice Emitted when pause or unpause is triggered
    event Paused(bool activated);

    /// @notice Total amount of LP allocated to receive pro-rata MEV and fees rewards
    uint256 public totalLPAssociatedWithDerivativesMinted;

    /// @notice Snapshotting pro-rata share of tokens for last claim by address
    mapping(address => uint256) public lastAccumulatedLPAtLastLiquiditySize;

    /// @notice Whether the contract is paused
    bool public paused;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(LSDNFactory _factory, address _lpDeployer, address _upgradeManager) external virtual initializer {
        lpTokenETH = GiantLP(GiantLPDeployer(_lpDeployer).deployToken(address(this), address(this), "GiantETHLP", "gMevETH"));
        liquidStakingDerivativeFactory = _factory;
        batchSize = 4 ether;
        _transferOwnership(_upgradeManager);
        __ReentrancyGuard_init();
    }

    /// @dev Owner based upgrades
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @notice Allow the contract owner to trigger pausing of core features
    function togglePause(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /// @notice Stake ETH against multiple BLS keys within multiple LSDNs and specify the amount of ETH being supplied for each key
    /// @dev Uses contract balance for funding and get Staking Funds Vault LP in exchange for ETH
    /// @param _stakingFundsVault List of mev and fees vaults being interacted with
    /// @param _ETHTransactionAmounts ETH being attached to each savETH vault in the list
    /// @param _blsPublicKeyOfKnots For every staking funds vault, the list of BLS keys of LSDN validators receiving funding
    /// @param _amounts List of amounts of ETH being staked per BLS public key
    function batchDepositETHForStaking(
        address[] calldata _stakingFundsVault,
        uint256[] calldata _ETHTransactionAmounts,
        bytes[][] calldata _blsPublicKeyOfKnots,
        uint256[][] calldata _amounts
    ) external whenContractNotPaused nonReentrant {
        uint256 numOfVaults = _stakingFundsVault.length;
        if (numOfVaults == 0) revert Errors.EmptyArray();
        if (numOfVaults != _ETHTransactionAmounts.length) revert Errors.InconsistentArrayLength();
        if (numOfVaults != _blsPublicKeyOfKnots.length) revert Errors.InconsistentArrayLength();
        if (numOfVaults != _amounts.length) revert Errors.InconsistentArrayLength();

        updateAccumulatedETHPerLP();

        for (uint256 i; i < numOfVaults; ++i) {
            // As ETH is being deployed to a staking funds vault, it is no longer idle
            idleETH -= _ETHTransactionAmounts[i];

            if (!liquidStakingDerivativeFactory.isStakingFundsVault(_stakingFundsVault[i])) revert Errors.InvalidStakingFundsVault();

            StakingFundsVault(payable(_stakingFundsVault[i])).batchDepositETHForStaking{ value: _ETHTransactionAmounts[i] }(
                _blsPublicKeyOfKnots[i],
                _amounts[i]
            );

            uint256 numOfPublicKeys = _blsPublicKeyOfKnots[i].length;
            for (uint256 j; j < numOfPublicKeys; ++j) {
                // because of withdrawal batch allocation, partial funding amounts would add too much complexity for later allocation
                if (_amounts[i][j] != 4 ether) revert Errors.InvalidAmount();
                _onStake(_blsPublicKeyOfKnots[i][j]);
                isBLSPubKeyFundedByGiantPool[_blsPublicKeyOfKnots[i][j]] = true;
            }
        }
    }

    /// @notice Allow a giant LP to claim a % of the revenue received by the MEV and Fees Pool
    function claimRewards(
        address _recipient,
        address[] calldata _stakingFundsVaults,
        bytes[][] calldata _blsPublicKeysForKnots
    ) external whenContractNotPaused {
        if (totalLPAssociatedWithDerivativesMinted == 0) revert Errors.NoDerivativesMinted();

        _fetchGiantPoolRewards(_stakingFundsVaults, _blsPublicKeysForKnots);

        claimExistingRewards(_recipient);
    }

    /// @notice Fetch ETH rewards from staking funds vaults funded from the giant pool without sending to giant LPs
    function fetchGiantPoolRewards(
        address[] calldata _stakingFundsVaults,
        bytes[][] calldata _blsPublicKeysForKnots
    ) public whenContractNotPaused nonReentrant {
        _fetchGiantPoolRewards(_stakingFundsVaults, _blsPublicKeysForKnots);
        updateAccumulatedETHPerLP();
    }

    /// @notice Allow a user to claim their reward balance without fetching upstream ETH rewards (that are in syndicates)
    function claimExistingRewards(address _recipient) public whenContractNotPaused nonReentrant {
        updateAccumulatedETHPerLP();
        _transferETH(
            _recipient,
            _distributeETHRewardsToUserForToken(
                msg.sender,
                address(lpTokenETH),
                _getTotalLiquidityInActiveRangeForUser(msg.sender),
                _recipient
            )
        );
    }

    /// @notice Any ETH that has not been utilized by a Staking Funds vault can be brought back into the giant pool
    /// @param _stakingFundsVaults List of staking funds vaults this contract will contact
    /// @param _lpTokens List of LP tokens that the giant pool holds which represents ETH in a staking funds vault
    /// @param _amounts Amounts of LP within the giant pool being burnt
    function bringUnusedETHBackIntoGiantPool(
        address[] calldata _stakingFundsVaults,
        LPToken[][] calldata _lpTokens,
        uint256[][] calldata _amounts
    ) external whenContractNotPaused nonReentrant {
        uint256 numOfVaults = _stakingFundsVaults.length;
        if (numOfVaults == 0) revert Errors.EmptyArray();
        if (numOfVaults != _lpTokens.length) revert Errors.InconsistentArrayLength();
        if (numOfVaults != _amounts.length) revert Errors.InconsistentArrayLength();

        updateAccumulatedETHPerLP();

        for (uint256 i; i < numOfVaults; ++i) {
            StakingFundsVault vault = StakingFundsVault(payable(_stakingFundsVaults[i]));
            if (!liquidStakingDerivativeFactory.isStakingFundsVault(address(vault))) revert Errors.InvalidStakingFundsVault();

            vault.burnLPTokensForETH(_lpTokens[i], _amounts[i]);

            uint256 numOfTokens = _lpTokens[i].length;
            for (uint256 j; j < numOfTokens; ++j) {
                // Increase the amount of ETH that's idle
                idleETH += _amounts[i][j];

                bytes memory blsPubKey = vault.KnotAssociatedWithLPToken(_lpTokens[i][j]);
                _onBringBackETHToGiantPool(blsPubKey);
                isBLSPubKeyFundedByGiantPool[blsPubKey] = false;
            }
        }
    }

    /// @notice Allow giant pool LP holders to withdraw LP tokens from LSD networks that they funded
    /// @param _lpToken Address of the LP token that the user is withdrawing from the giant pool
    /// @param _amount Of LP tokens user is withdrawing and also amount of giant tokens being burnt
    function withdrawLP(
        LPToken _lpToken,
        uint256 _amount
    ) external whenContractNotPaused nonReentrant {
        // Check the token that the giant pool should own was deployed by an authenticated staking funds vault
        address stakingFundsVault = _lpToken.deployer();
        if (!liquidStakingDerivativeFactory.isStakingFundsVault(stakingFundsVault)) revert Errors.InvalidStakingFundsVault();
        if (_lpToken.balanceOf(address(this)) < _amount) revert Errors.InvalidBalance();
        if (lpTokenETH.balanceOf(msg.sender) < _amount) revert Errors.InvalidBalance();
        if (_amount < MIN_STAKING_AMOUNT) revert Errors.InvalidAmount();

        bytes memory blsPublicKey = StakingFundsVault(payable(stakingFundsVault)).KnotAssociatedWithLPToken(_lpToken);
        if (!_isDerivativesMinted(blsPublicKey)) revert Errors.NoDerivativesMinted();

        _lpToken.transfer(msg.sender, _amount);
        lpTokenETH.burn(msg.sender, _amount);

        uint256 batchId = allocatedWithdrawalBatchForBlsPubKey[blsPublicKey];
        _reduceUserAmountFundedInBatch(batchId, msg.sender, _amount);

        emit LPWithdrawn(address(_lpToken), msg.sender);
    }

    /// @notice Distribute any new ETH received to LP holders
    function updateAccumulatedETHPerLP() public whenContractNotPaused {
        _updateAccumulatedETHPerLP(totalLPAssociatedWithDerivativesMinted);
    }

    /// @notice Allow giant LP token to notify pool about transfers so the claimed amounts can be processed
    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external whenContractNotPaused {
        if (msg.sender != address(lpTokenETH)) revert Errors.InvalidCaller();

        updateAccumulatedETHPerLP();

        // Make sure that `_from` gets total accrued before transfer as post transferred anything owed will be wiped
        if (_from != address(0)) {
            (uint256 activeLiquidityFrom, uint256 lpBalanceFromBefore) = _distributePendingETHRewards(_from);
            if (lpTokenETH.balanceOf(_from) != lpBalanceFromBefore) revert ReentrancyCall();

            lastAccumulatedLPAtLastLiquiditySize[_from] = accumulatedETHPerLPShare;
            claimed[_from][msg.sender] = activeLiquidityFrom == 0 ?
                0 : (accumulatedETHPerLPShare * (activeLiquidityFrom - _amount)) / PRECISION;
        }

        // Make sure that `_to` gets total accrued before transfer as post transferred anything owed will be wiped
        if (_to != address(0)) {
            (uint256 activeLiquidityTo, uint256 lpBalanceToBefore) = _distributePendingETHRewards(_to);
            if (lpTokenETH.balanceOf(_to) != lpBalanceToBefore) revert ReentrancyCall();
            if (lpBalanceToBefore > 0) {
                claimed[_to][msg.sender] = (accumulatedETHPerLPShare * (activeLiquidityTo + _amount)) / PRECISION;
            } else {
                claimed[_to][msg.sender] = (accumulatedETHPerLPShare * _amount) / PRECISION;
            }

            lastAccumulatedLPAtLastLiquiditySize[_to] = accumulatedETHPerLPShare;
        }
    }

    /// @notice Total rewards received by this contract from the syndicate excluding idle ETH from LP depositors
    function totalRewardsReceived() public view override returns (uint256) {
        return address(this).balance + totalClaimed - idleETH;
    }

    /// @notice Preview total ETH accrued by an address from Syndicate rewards
    function previewAccumulatedETH(
        address _user,
        address[] calldata _stakingFundsVaults,
        LPToken[][] calldata _lpTokens
    ) external view returns (uint256) {
        uint256 numOfVaults = _stakingFundsVaults.length;
        if (numOfVaults != _lpTokens.length) revert Errors.InconsistentArrayLength();

        uint256 accumulated;
        for (uint256 i; i < numOfVaults; ++i) {
            accumulated += StakingFundsVault(payable(_stakingFundsVaults[i])).batchPreviewAccumulatedETH(
                address(this),
                _lpTokens[i]
            );
        }

        return _previewAccumulatedETH(
            _user,
            address(lpTokenETH),
            _getTotalLiquidityInActiveRangeForUser(_user),
            totalLPAssociatedWithDerivativesMinted,
            accumulated
        );
    }

    /// @notice Get total liquidity that is in active reward range for user
    function getTotalLiquidityInActiveRangeForUser(address _user) external view returns (uint256) {
        return _getTotalLiquidityInActiveRangeForUser(_user);
    }

    /// @dev Re-usable function for distributing rewards based on having an LP balance and active liquidity from minting derivatives
    function _distributePendingETHRewards(address _receiver) internal returns (
        uint256 activeLiquidityReceivingRewards,
        uint256 lpTokenETHBalance
    ) {
        lpTokenETHBalance = lpTokenETH.balanceOf(_receiver);
        if (lpTokenETHBalance > 0) {
            activeLiquidityReceivingRewards = _getTotalLiquidityInActiveRangeForUser(_receiver);
            if (activeLiquidityReceivingRewards > 0) {
                _transferETH(
                    _receiver,
                    _distributeETHRewardsToUserForToken(
                        _receiver,
                        address(lpTokenETH),
                        activeLiquidityReceivingRewards,
                        _receiver
                    )
                );
            }
        }
    }

    /// @notice Allow liquid staking managers to notify the giant pool about derivatives minted for a key
    function _onMintDerivatives(bytes calldata _blsPublicKey) internal override {
        // use this to update active liquidity range for distributing rewards
        if (isBLSPubKeyFundedByGiantPool[_blsPublicKey]) {
            // Capture accumulated LP at time of minting derivatives
            accumulatedETHPerLPAtTimeOfMintingDerivatives[_blsPublicKey] = accumulatedETHPerLPShare;

            totalLPAssociatedWithDerivativesMinted += 4 ether;
        }
    }

    /// @dev Total claimed for a user and LP token needs to be based on when derivatives were minted so that pro-rated share is not earned too early causing phantom balances
    function _getTotalClaimedForUserAndToken(
        address _user,
        address _token,
        uint256 _currentBalance
    ) internal override view returns (uint256) {
        uint256 claimedSoFar = claimed[_user][_token];

        // Handle the case where all LP is withdrawn or some derivatives are not minted
        if (_currentBalance == 0) revert Errors.InvalidAmount();

        if (claimedSoFar > 0) {
            claimedSoFar = (lastAccumulatedLPAtLastLiquiditySize[_user] * _currentBalance) / PRECISION;
        } else {
            uint256 batchId = setOfAssociatedDepositBatches[_user].at(0);
            bytes memory blsPublicKey = allocatedBlsPubKeyForWithdrawalBatch[batchId];
            claimedSoFar = (_currentBalance * accumulatedETHPerLPAtTimeOfMintingDerivatives[blsPublicKey]) / PRECISION;
        }

        // Either user has a claimed amount or their claimed amount needs to be based on accumulated ETH at time of minting derivatives
        return claimedSoFar;
    }

    /// @dev Use _getTotalClaimedForUserAndToken to correctly track and save total claimed by a user for a token
    function _increaseClaimedForUserAndToken(
        address _user,
        address _token,
        uint256 _increase,
        uint256 _balance
    ) internal override {
        // _getTotalClaimedForUserAndToken will factor in accumulated ETH at time of minting derivatives
        lastAccumulatedLPAtLastLiquiditySize[_user] = accumulatedETHPerLPShare;
        claimed[_user][_token] = _getTotalClaimedForUserAndToken(_user, _token, _balance) + _increase;
    }

    /// @dev Utility for fetching total ETH that is eligble to receive rewards for a user
    function _getTotalLiquidityInActiveRangeForUser(address _user) internal view returns (uint256) {
        uint256 totalLiquidityInActiveRangeForUser;
        uint256 totalNumOfBatches = setOfAssociatedDepositBatches[_user].length();

        for (uint256 i; i < totalNumOfBatches; ++i) {
            uint256 batchId = setOfAssociatedDepositBatches[_user].at(i);

            if (!_isDerivativesMinted(allocatedBlsPubKeyForWithdrawalBatch[batchId])) {
                // Derivatives are not minted for this batch so continue as elements in enumerable set are not guaranteed any order
                continue;
            }

            totalLiquidityInActiveRangeForUser += totalETHFundedPerBatch[_user][batchId];
        }

        return totalLiquidityInActiveRangeForUser;
    }

    /// @dev Given a BLS pub key, whether derivatives are minted
    function _isDerivativesMinted(bytes memory _blsPubKey) internal view returns (bool) {
        return getAccountManager().blsPublicKeyToLifecycleStatus(_blsPubKey) == IDataStructures.LifecycleStatus.TOKENS_MINTED;
    }

    /// @dev Internal business logic for fetching fees and mev rewards from specified LSD networks
    function _fetchGiantPoolRewards(
        address[] calldata _stakingFundsVaults,
        bytes[][] calldata _blsPublicKeysForKnots
    ) internal {
        uint256 numOfVaults = _stakingFundsVaults.length;
        if (numOfVaults == 0) revert Errors.EmptyArray();
        if (numOfVaults != _blsPublicKeysForKnots.length) revert Errors.InconsistentArrayLength();
        for (uint256 i; i < numOfVaults; ++i) {
            StakingFundsVault vault = StakingFundsVault(payable(_stakingFundsVaults[i]));
            if (!liquidStakingDerivativeFactory.isStakingFundsVault(address(vault))) revert Errors.InvalidStakingFundsVault();
            vault.claimRewards(
                address(this),
                _blsPublicKeysForKnots[i]
            );
        }
    }

    // @dev Get the interface connected to the AccountManager smart contract
    function getAccountManager() internal view virtual returns (IAccountManager accountManager) {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        if(chainId == MainnetConstants.CHAIN_ID) {
            accountManager = IAccountManager(MainnetConstants.AccountManager);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            accountManager = IAccountManager(GoerliConstants.AccountManager);
        }

        else {
            revert('CHAIN');
        }
    }

    function _assertContractNotPaused() internal override {
        if (paused) revert ContractPaused();
    }
}