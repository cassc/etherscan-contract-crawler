// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import { SafeMath } from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import { Math } from "openzeppelin-solidity/contracts/math/Math.sol";
import { IERC20 } from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath32 } from "../../libs/SafeMath32.sol";
import { SafeMath96 } from "../../libs/SafeMath96.sol";
import { MathHelpers } from "../../libs/MathHelpers.sol";
import { InsuranceFundDefs } from "../../libs/defs/InsuranceFundDefs.sol";
import { LibDiamondStorageDerivaDEX } from "../../storage/LibDiamondStorageDerivaDEX.sol";
import { LibDiamondStorageInsuranceFund } from "../../storage/LibDiamondStorageInsuranceFund.sol";
import { LibDiamondStorageTrader } from "../../storage/LibDiamondStorageTrader.sol";
import { LibDiamondStoragePause } from "../../storage/LibDiamondStoragePause.sol";
import { IDDX } from "../../tokens/interfaces/IDDX.sol";
import { LibTraderInternal } from "../trader/LibTraderInternal.sol";
import { IAToken } from "../interfaces/IAToken.sol";
import { IComptroller } from "../interfaces/IComptroller.sol";
import { ICToken } from "../interfaces/ICToken.sol";
import { IDIFundToken } from "../../tokens/interfaces/IDIFundToken.sol";
import { IDIFundTokenFactory } from "../../tokens/interfaces/IDIFundTokenFactory.sol";

interface IERCCustom {
    function decimals() external view returns (uint8);
}

/**
 * @title InsuranceFund
 * @author DerivaDEX
 * @notice This is a facet to the DerivaDEX proxy contract that handles
 *         the logic pertaining to insurance mining - staking directly
 *         into the insurance fund and receiving a DDX issuance to be
 *         used in governance/operations.
 * @dev This facet at the moment only handles insurance mining. It can
 *      and will grow to handle the remaining functions of the insurance
 *      fund, such as receiving quote-denominated fees and liquidation
 *      spreads, among others. The Diamond storage will only be
 *      affected when facet functions are called via the proxy
 *      contract, no checks are necessary.
 */
contract InsuranceFund {
    using SafeMath32 for uint32;
    using SafeMath96 for uint96;
    using SafeMath for uint96;
    using SafeMath for uint256;
    using MathHelpers for uint32;
    using MathHelpers for uint96;
    using MathHelpers for uint224;
    using MathHelpers for uint256;
    using SafeERC20 for IERC20;

    // Compound-related constant variables
    // kovan: 0x5eAe89DC1C671724A672ff0630122ee834098657
    IComptroller public constant COMPTROLLER = IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    // kovan: 0x61460874a7196d6a22D1eE4922473664b3E95270
    IERC20 public constant COMP_TOKEN = IERC20(0xc00e94Cb662C3520282E6f5717214004A7f26888);

    event InsuranceFundInitialized(
        uint32 interval,
        uint32 withdrawalFactor,
        uint96 mineRatePerBlock,
        uint96 advanceIntervalReward,
        uint256 miningFinalBlockNumber
    );

    event InsuranceFundCollateralAdded(
        bytes32 collateralName,
        address underlyingToken,
        address collateralToken,
        InsuranceFundDefs.Flavor flavor
    );

    event StakedToInsuranceFund(address staker, uint96 amount, bytes32 collateralName);

    event WithdrawnFromInsuranceFund(address withdrawer, uint96 amount, bytes32 collateralName);

    event AdvancedOtherRewards(address intervalAdvancer, uint96 advanceReward);

    event InsuranceMineRewardsClaimed(address claimant, uint96 minedAmount);

    event MineRatePerBlockSet(uint96 mineRatePerBlock);

    event AdvanceIntervalRewardSet(uint96 advanceIntervalReward);

    event WithdrawalFactorSet(uint32 withdrawalFactor);

    event InsuranceMiningExtended(uint256 miningFinalBlockNumber);

    /**
     * @notice Limits functions to only be called via governance.
     */
    modifier onlyAdmin {
        LibDiamondStorageDerivaDEX.DiamondStorageDerivaDEX storage dsDerivaDEX =
            LibDiamondStorageDerivaDEX.diamondStorageDerivaDEX();
        require(msg.sender == dsDerivaDEX.admin, "IFund: must be called by Gov.");
        _;
    }

    /**
     * @notice Limits functions to only be called while insurance
     *         mining is ongoing.
     */
    modifier insuranceMiningOngoing {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        require(block.number < dsInsuranceFund.miningFinalBlockNumber, "IFund: mining ended.");
        _;
    }

    /**
     * @notice Limits functions to only be called while other
     *         rewards checkpointing is ongoing.
     */
    modifier otherRewardsOngoing {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        require(
            dsInsuranceFund.otherRewardsCheckpointBlock < dsInsuranceFund.miningFinalBlockNumber,
            "IFund: other rewards checkpointing ended."
        );
        _;
    }

    /**
     * @notice Limits functions to only be called via governance.
     */
    modifier isNotPaused {
        LibDiamondStoragePause.DiamondStoragePause storage dsPause = LibDiamondStoragePause.diamondStoragePause();
        require(!dsPause.isPaused, "IFund: paused.");
        _;
    }

    /**
     * @notice This function initializes the state with some critical
     *         information. This can only be called via governance.
     * @dev This function is best called as a parameter to the
     *      diamond cut function. This is removed prior to the selectors
     *      being added to the diamond, meaning it cannot be called
     *      again.
     * @param _interval The interval length (blocks) for other rewards
     *        claiming checkpoints (i.e. COMP and extra aTokens).
     * @param _withdrawalFactor Specifies the withdrawal fee if users
     *        redeem their insurance tokens.
     * @param _mineRatePerBlock The DDX tokens to be mined each interval
     *        for insurance mining.
     * @param _advanceIntervalReward DDX reward for participant who
     *        advances the insurance mining interval.
     * @param _insuranceMiningLength Insurance mining length (blocks).
     */
    function initialize(
        uint32 _interval,
        uint32 _withdrawalFactor,
        uint96 _mineRatePerBlock,
        uint96 _advanceIntervalReward,
        uint256 _insuranceMiningLength,
        IDIFundTokenFactory _diFundTokenFactory
    ) external onlyAdmin {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // Set the interval for other rewards claiming checkpoints
        // (i.e. COMP and aTokens that accrue to the contract)
        // (e.g. 40320 ~ 1 week = 7 * 24 * 60 * 60 / 15 blocks)
        dsInsuranceFund.interval = _interval;

        // Keep track of the block number for other rewards checkpoint,
        // which is initialized to the block number the insurance fund
        // facet is added to the diamond
        dsInsuranceFund.otherRewardsCheckpointBlock = block.number;

        // Set the withdrawal factor, capped at 1000, implying 0% fee
        require(_withdrawalFactor <= 1000, "IFund: withdrawal fee too high.");
        // Set withdrawal ratio, which will be used with a 1e3 scaling
        // factor, meaning a value of 995 implies a withdrawal fee of
        // 0.5% since 995/1e3 => 0.995
        dsInsuranceFund.withdrawalFactor = _withdrawalFactor;

        // Set the insurance mine rate per block.
        // (e.g. 1.189e18 ~ 5% liquidity mine (50mm tokens))
        dsInsuranceFund.mineRatePerBlock = _mineRatePerBlock;

        // Incentive to advance the other rewards interval
        // (e.g. 100e18 = 100 DDX)
        dsInsuranceFund.advanceIntervalReward = _advanceIntervalReward;

        // Set the final block number for insurance mining
        dsInsuranceFund.miningFinalBlockNumber = block.number.add(_insuranceMiningLength);

        // DIFundToken factory to deploy DerivaDEX Insurance Fund token
        // contracts pertaining to each supported collateral
        dsInsuranceFund.diFundTokenFactory = _diFundTokenFactory;

        // Initialize the DDX market state index and block. These values
        // are critical for computing the DDX continuously issued per
        // block
        dsInsuranceFund.ddxMarketState.index = 1e36;
        dsInsuranceFund.ddxMarketState.block = block.number.safe32("IFund: exceeds 32 bits");

        emit InsuranceFundInitialized(
            _interval,
            _withdrawalFactor,
            _mineRatePerBlock,
            _advanceIntervalReward,
            dsInsuranceFund.miningFinalBlockNumber
        );
    }

    /**
     * @notice This function sets the DDX mine rate per block.
     * @param _mineRatePerBlock The DDX tokens mine rate per block.
     */
    function setMineRatePerBlock(uint96 _mineRatePerBlock) external onlyAdmin insuranceMiningOngoing isNotPaused {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // NOTE(jalextowle): We must update the DDX Market State prior to
        // changing the mine rate per block in order to lock in earned rewards
        // for insurance mining participants.
        updateDDXMarketState(dsInsuranceFund);

        require(_mineRatePerBlock != dsInsuranceFund.mineRatePerBlock, "IFund: same as current value.");
        // Set the insurance mine rate per block.
        // (e.g. 1.189e18 ~ 5% liquidity mine (50mm tokens))
        dsInsuranceFund.mineRatePerBlock = _mineRatePerBlock;

        emit MineRatePerBlockSet(_mineRatePerBlock);
    }

    /**
     * @notice This function sets the advance interval reward.
     * @param _advanceIntervalReward DDX reward for advancing interval.
     */
    function setAdvanceIntervalReward(uint96 _advanceIntervalReward)
        external
        onlyAdmin
        insuranceMiningOngoing
        isNotPaused
    {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        require(_advanceIntervalReward != dsInsuranceFund.advanceIntervalReward, "IFund: same as current value.");
        // Set the advance interval reward
        dsInsuranceFund.advanceIntervalReward = _advanceIntervalReward;

        emit AdvanceIntervalRewardSet(_advanceIntervalReward);
    }

    /**
     * @notice This function sets the withdrawal factor.
     * @param _withdrawalFactor Withdrawal factor.
     */
    function setWithdrawalFactor(uint32 _withdrawalFactor) external onlyAdmin insuranceMiningOngoing isNotPaused {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        require(_withdrawalFactor != dsInsuranceFund.withdrawalFactor, "IFund: same as current value.");
        // Set the withdrawal factor, capped at 1000, implying 0% fee
        require(dsInsuranceFund.withdrawalFactor <= 1000, "IFund: withdrawal fee too high.");
        dsInsuranceFund.withdrawalFactor = _withdrawalFactor;

        emit WithdrawalFactorSet(_withdrawalFactor);
    }

    /**
     * @notice This function extends insurance mining.
     * @param _insuranceMiningExtension Insurance mining extension
     *         (blocks).
     */
    function extendInsuranceMining(uint256 _insuranceMiningExtension)
        external
        onlyAdmin
        insuranceMiningOngoing
        isNotPaused
    {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        require(_insuranceMiningExtension != 0, "IFund: invalid extension.");
        // Extend the mining final block number
        dsInsuranceFund.miningFinalBlockNumber = dsInsuranceFund.miningFinalBlockNumber.add(_insuranceMiningExtension);

        emit InsuranceMiningExtended(dsInsuranceFund.miningFinalBlockNumber);
    }

    /**
     * @notice This function adds a new supported collateral type that
     *         can be staked to the insurance fund. It can only
     *         be called via governance.
     * @dev For vanilla contracts (e.g. USDT, USDC, etc.), the
     *      underlying token equals address(0).
     * @param _collateralName Name of collateral.
     * @param _collateralSymbol Symbol of collateral.
     * @param _underlyingToken Deployed address of underlying token.
     * @param _collateralToken Deployed address of collateral token.
     * @param _flavor Collateral flavor (Vanilla, Compound, Aave, etc.).
     */
    function addInsuranceFundCollateral(
        string memory _collateralName,
        string memory _collateralSymbol,
        address _underlyingToken,
        address _collateralToken,
        InsuranceFundDefs.Flavor _flavor
    ) external onlyAdmin insuranceMiningOngoing isNotPaused {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // Obtain bytes32 representation of collateral name
        bytes32 result;
        assembly {
            result := mload(add(_collateralName, 32))
        }

        // Ensure collateral has not already been added
        require(
            dsInsuranceFund.stakeCollaterals[result].collateralToken == address(0),
            "IFund: collateral already added."
        );

        require(_collateralToken != address(0), "IFund: collateral address must be non-zero.");
        require(!isCollateralTokenPresent(_collateralToken), "IFund: collateral token already present.");
        require(_underlyingToken != _collateralToken, "IFund: token addresses are same.");
        if (_flavor == InsuranceFundDefs.Flavor.Vanilla) {
            // If collateral is of vanilla flavor, there should only be
            // a value for collateral token, and underlying token should
            // be empty
            require(_underlyingToken == address(0), "IFund: underlying address non-zero for Vanilla.");
        }

        // Add collateral type to storage, including its underlying
        // token and collateral token addresses, and its flavor
        dsInsuranceFund.stakeCollaterals[result].underlyingToken = _underlyingToken;
        dsInsuranceFund.stakeCollaterals[result].collateralToken = _collateralToken;
        dsInsuranceFund.stakeCollaterals[result].flavor = _flavor;

        // Create a DerivaDEX Insurance Fund token contract associated
        // with this supported collateral
        dsInsuranceFund.stakeCollaterals[result].diFundToken = IDIFundToken(
            dsInsuranceFund.diFundTokenFactory.createNewDIFundToken(
                _collateralName,
                _collateralSymbol,
                IERCCustom(_collateralToken).decimals()
            )
        );
        dsInsuranceFund.collateralNames.push(result);

        emit InsuranceFundCollateralAdded(result, _underlyingToken, _collateralToken, _flavor);
    }

    /**
     * @notice This function allows participants to stake a supported
     *         collateral type to the insurance fund.
     * @param _collateralName Name of collateral.
     * @param _amount Amount to stake.
     */
    function stakeToInsuranceFund(bytes32 _collateralName, uint96 _amount) external insuranceMiningOngoing isNotPaused {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // Obtain the collateral struct for the collateral type
        // participant is staking
        InsuranceFundDefs.StakeCollateral storage stakeCollateral = dsInsuranceFund.stakeCollaterals[_collateralName];

        // Ensure this is a supported collateral type and that the user
        // has approved the proxy contract for transfer
        require(stakeCollateral.collateralToken != address(0), "IFund: invalid collateral.");

        // Ensure non-zero stake amount
        require(_amount > 0, "IFund: non-zero amount.");

        // Claim DDX for staking user. We do this prior to the stake
        // taking effect, thereby preventing someone from being rewarded
        // instantly for the stake.
        claimDDXFromInsuranceMining(msg.sender);

        // Increment the underlying capitalization
        stakeCollateral.cap = stakeCollateral.cap.add96(_amount);

        // Transfer collateral amount from user to proxy contract
        IERC20(stakeCollateral.collateralToken).safeTransferFrom(msg.sender, address(this), _amount);

        // Mint DIFund tokens to user
        stakeCollateral.diFundToken.mint(msg.sender, _amount);

        emit StakedToInsuranceFund(msg.sender, _amount, _collateralName);
    }

    /**
     * @notice This function allows participants to withdraw a supported
     *         collateral type from the insurance fund.
     * @param _collateralName Name of collateral.
     * @param _amount Amount to stake.
     */
    function withdrawFromInsuranceFund(bytes32 _collateralName, uint96 _amount) external isNotPaused {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // Obtain the collateral struct for the collateral type
        // participant is staking
        InsuranceFundDefs.StakeCollateral storage stakeCollateral = dsInsuranceFund.stakeCollaterals[_collateralName];

        // Ensure this is a supported collateral type and that the user
        // has approved the proxy contract for transfer
        require(stakeCollateral.collateralToken != address(0), "IFund: invalid collateral.");

        // Ensure non-zero withdraw amount
        require(_amount > 0, "IFund: non-zero amount.");

        // Claim DDX for withdrawing user. We do this prior to the
        // redeem taking effect.
        claimDDXFromInsuranceMining(msg.sender);

        // Determine underlying to transfer based on how much underlying
        // can be redeemed given the current underlying capitalization
        // and how many DIFund tokens are globally available. This
        // theoretically fails in the scenario where globally there are
        // 0 insurance fund tokens, however that would mean the user
        // also has 0 tokens in their possession, and thus would have
        // nothing to be redeemed anyways.
        uint96 underlyingToTransferNoFee =
            _amount.proportion96(stakeCollateral.cap, stakeCollateral.diFundToken.totalSupply());
        uint96 underlyingToTransfer = underlyingToTransferNoFee.proportion96(dsInsuranceFund.withdrawalFactor, 1e3);

        // Decrement the capitalization
        stakeCollateral.cap = stakeCollateral.cap.sub96(underlyingToTransferNoFee);

        // Increment the withdrawal fee cap
        stakeCollateral.withdrawalFeeCap = stakeCollateral.withdrawalFeeCap.add96(
            underlyingToTransferNoFee.sub96(underlyingToTransfer)
        );

        // Transfer collateral amount from proxy contract to user
        IERC20(stakeCollateral.collateralToken).safeTransfer(msg.sender, underlyingToTransfer);

        // Burn DIFund tokens being redeemed from user
        stakeCollateral.diFundToken.burnFrom(msg.sender, _amount);

        emit WithdrawnFromInsuranceFund(msg.sender, _amount, _collateralName);
    }

    /**
     * @notice Advance other rewards interval
     */
    function advanceOtherRewardsInterval() external otherRewardsOngoing isNotPaused {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // Check if the current block has exceeded the interval bounds,
        // allowing for a new other rewards interval to be checkpointed
        require(
            block.number >= dsInsuranceFund.otherRewardsCheckpointBlock.add(dsInsuranceFund.interval),
            "IFund: advance too soon."
        );

        // Maintain the USD-denominated sum of all Compound-flavor
        // assets. This needs to be stored separately than the rest
        // due to the way COMP tokens are rewarded to the contract in
        // order to properly disseminate to the user.
        uint96 normalizedCapCheckpointSumCompound;

        // Loop through each of the supported collateral types
        for (uint256 i = 0; i < dsInsuranceFund.collateralNames.length; i++) {
            // Obtain collateral struct under consideration
            InsuranceFundDefs.StakeCollateral storage stakeCollateral =
                dsInsuranceFund.stakeCollaterals[dsInsuranceFund.collateralNames[i]];
            if (stakeCollateral.flavor == InsuranceFundDefs.Flavor.Compound) {
                // If collateral is of type Compound, set the exchange
                // rate at this point in time. We do this so later on,
                // when claiming rewards, we know the exchange rate
                // checkpointed balances should be converted to
                // determine the USD-denominated value of holdings
                // needed to compute fair share of DDX rewards.
                stakeCollateral.exchangeRate = ICToken(stakeCollateral.collateralToken).exchangeRateStored().safe96(
                    "IFund: amount exceeds 96 bits"
                );

                // Set checkpoint cap for this Compound flavor
                // collateral to handle COMP distribution lookbacks
                stakeCollateral.checkpointCap = stakeCollateral.cap;

                // Increment the normalized Compound checkpoint cap
                // with the USD-denominated value
                normalizedCapCheckpointSumCompound = normalizedCapCheckpointSumCompound.add96(
                    getUnderlyingTokenAmountForCompound(stakeCollateral.cap, stakeCollateral.exchangeRate)
                );
            } else if (stakeCollateral.flavor == InsuranceFundDefs.Flavor.Aave) {
                // If collateral is of type Aave, we need to do some
                // custom Aave aToken reward distribution. We first
                // determine the contract's aToken balance for this
                // collateral type and subtract the underlying
                // aToken capitalization that are due to users. This
                // leaves us with the excess that has been rewarded
                // to the contract due to Aave's mechanisms, but
                // belong to the users.
                uint96 myATokenBalance =
                    uint96(IAToken(stakeCollateral.collateralToken).balanceOf(address(this)).sub(stakeCollateral.cap));

                // Store the aToken yield information
                dsInsuranceFund.aTokenYields[dsInsuranceFund.collateralNames[i]] = InsuranceFundDefs
                    .ExternalYieldCheckpoint({ accrued: myATokenBalance, totalNormalizedCap: 0 });
            }
        }

        // Ensure that the normalized cap sum is non-zero
        if (normalizedCapCheckpointSumCompound > 0) {
            // If there's Compound-type asset capitalization in the
            // system, claim COMP accrued to this contract. This COMP is
            // a result of holding all the cToken deposits from users.
            // We claim COMP via Compound's Comptroller contract.
            COMPTROLLER.claimComp(address(this));

            // Obtain contract's balance of COMP
            uint96 myCompBalance = COMP_TOKEN.balanceOf(address(this)).safe96("IFund: amount exceeds 96 bits.");

            // Store the updated value as the checkpointed COMP yield owed
            // for this interval
            dsInsuranceFund.compYields = InsuranceFundDefs.ExternalYieldCheckpoint({
                accrued: myCompBalance,
                totalNormalizedCap: normalizedCapCheckpointSumCompound
            });
        }

        // Set other rewards checkpoint block to current block
        dsInsuranceFund.otherRewardsCheckpointBlock = block.number;

        // Issue DDX reward to trader's on-chain DDX wallet as an
        // incentive to users calling this function
        LibTraderInternal.issueDDXReward(dsInsuranceFund.advanceIntervalReward, msg.sender);

        emit AdvancedOtherRewards(msg.sender, dsInsuranceFund.advanceIntervalReward);
    }

    /**
     * @notice This function gets some high level insurance mining
     *         details.
     * @return The interval length (blocks) for other rewards
     *         claiming checkpoints (i.e. COMP and extra aTokens).
     * @return Current insurance mine withdrawal factor.
     * @return DDX reward for advancing interval.
     * @return Total global insurance mined amount in DDX.
     * @return Current insurance mine rate per block.
     * @return Insurance mining final block number.
     * @return DDX market state used for continuous DDX payouts.
     * @return Supported collateral names supported.
     */
    function getInsuranceMineInfo()
        external
        view
        returns (
            uint32,
            uint32,
            uint96,
            uint96,
            uint96,
            uint256,
            InsuranceFundDefs.DDXMarketState memory,
            bytes32[] memory
        )
    {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        return (
            dsInsuranceFund.interval,
            dsInsuranceFund.withdrawalFactor,
            dsInsuranceFund.advanceIntervalReward,
            dsInsuranceFund.minedAmount,
            dsInsuranceFund.mineRatePerBlock,
            dsInsuranceFund.miningFinalBlockNumber,
            dsInsuranceFund.ddxMarketState,
            dsInsuranceFund.collateralNames
        );
    }

    /**
     * @notice This function gets the current claimant state for a user.
     * @param _claimant Claimant address.
     * @return Claimant state.
     */
    function getDDXClaimantState(address _claimant) external view returns (InsuranceFundDefs.DDXClaimantState memory) {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        return dsInsuranceFund.ddxClaimantState[_claimant];
    }

    /**
     * @notice This function gets a supported collateral type's data,
     *         including collateral's token addresses, collateral
     *         flavor/type, current cap and withdrawal amounts, the
     *         latest checkpointed cap, and exchange rate (for cTokens).
     *         An interface for the DerivaDEX Insurance Fund token
     *         corresponding to this collateral is also maintained.
     * @param _collateralName Name of collateral.
     * @return Stake collateral.
     */
    function getStakeCollateralByCollateralName(bytes32 _collateralName)
        external
        view
        returns (InsuranceFundDefs.StakeCollateral memory)
    {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        return dsInsuranceFund.stakeCollaterals[_collateralName];
    }

    /**
     * @notice This function gets unclaimed DDX rewards for a claimant.
     * @param _claimant Claimant address.
     * @return Unclaimed DDX rewards.
     */
    function getUnclaimedDDXRewards(address _claimant) external view returns (uint96) {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // Number of blocks that have elapsed from the last protocol
        // interaction resulting in DDX accrual. If insurance mining
        // has ended, we use this as the reference point, so deltaBlocks
        // will be 0 from the second time onwards.
        uint256 deltaBlocks =
            Math.min(block.number, dsInsuranceFund.miningFinalBlockNumber).sub(dsInsuranceFund.ddxMarketState.block);

        // Save off last index value
        uint256 index = dsInsuranceFund.ddxMarketState.index;

        // If number of blocks elapsed and mine rate per block are
        // non-zero
        if (deltaBlocks > 0 && dsInsuranceFund.mineRatePerBlock > 0) {
            // Maintain a running total of USDT-normalized claim tokens
            // (i.e. 1e6 multiplier)
            uint256 claimTokens;

            // Loop through each of the supported collateral types
            for (uint256 i = 0; i < dsInsuranceFund.collateralNames.length; i++) {
                // Obtain the collateral struct for the collateral type
                // participant is staking
                InsuranceFundDefs.StakeCollateral storage stakeCollateral =
                    dsInsuranceFund.stakeCollaterals[dsInsuranceFund.collateralNames[i]];

                // Increment the USDT-normalized claim tokens count with
                // the current total supply
                claimTokens = claimTokens.add(
                    getNormalizedCollateralValue(
                        dsInsuranceFund.collateralNames[i],
                        stakeCollateral.diFundToken.totalSupply().safe96("IFund: exceeds 96 bits")
                    )
                );
            }

            // Compute DDX accrued during the time elapsed and the
            // number of tokens accrued per claim token outstanding
            uint256 ddxAccrued = deltaBlocks.mul(dsInsuranceFund.mineRatePerBlock);
            uint256 ratio = claimTokens > 0 ? ddxAccrued.mul(1e36).div(claimTokens) : 0;

            // Increment the index
            index = index.add(ratio);
        }

        // Obtain the most recent claimant index
        uint256 ddxClaimantIndex = dsInsuranceFund.ddxClaimantState[_claimant].index;

        // If the claimant index is 0, i.e. it's the user's first time
        // interacting with the protocol, initialize it to this starting
        // value
        if ((ddxClaimantIndex == 0) && (index > 0)) {
            ddxClaimantIndex = 1e36;
        }

        // Maintain a running total of USDT-normalized claimant tokens
        // (i.e. 1e6 multiplier)
        uint256 claimantTokens;

        // Loop through each of the supported collateral types
        for (uint256 i = 0; i < dsInsuranceFund.collateralNames.length; i++) {
            // Obtain the collateral struct for the collateral type
            // participant is staking
            InsuranceFundDefs.StakeCollateral storage stakeCollateral =
                dsInsuranceFund.stakeCollaterals[dsInsuranceFund.collateralNames[i]];

            // Increment the USDT-normalized claimant tokens count with
            // the current balance
            claimantTokens = claimantTokens.add(
                getNormalizedCollateralValue(
                    dsInsuranceFund.collateralNames[i],
                    stakeCollateral.diFundToken.balanceOf(_claimant).safe96("IFund: exceeds 96 bits")
                )
            );
        }

        // Compute the unclaimed DDX based on the number of claimant
        // tokens and the difference between the user's index and the
        // claimant index computed above
        return claimantTokens.mul(index.sub(ddxClaimantIndex)).div(1e36).safe96("IFund: exceeds 96 bits");
    }

    /**
     * @notice Calculate DDX accrued by a claimant and possibly transfer
     *         it to them.
     * @param _claimant The address of the claimant.
     */
    function claimDDXFromInsuranceMining(address _claimant) public {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // Update the DDX Market State in order to determine the amount of
        // rewards that should be paid to the claimant.
        updateDDXMarketState(dsInsuranceFund);

        // Obtain the most recent claimant index
        uint256 ddxClaimantIndex = dsInsuranceFund.ddxClaimantState[_claimant].index;
        dsInsuranceFund.ddxClaimantState[_claimant].index = dsInsuranceFund.ddxMarketState.index;

        // If the claimant index is 0, i.e. it's the user's first time
        // interacting with the protocol, initialize it to this starting
        // value
        if ((ddxClaimantIndex == 0) && (dsInsuranceFund.ddxMarketState.index > 0)) {
            ddxClaimantIndex = 1e36;
        }

        // Compute the difference between the latest DDX market state
        // index and the claimant's index
        uint256 deltaIndex = uint256(dsInsuranceFund.ddxMarketState.index).sub(ddxClaimantIndex);

        // Maintain a running total of USDT-normalized claimant tokens
        // (i.e. 1e6 multiplier)
        uint256 claimantTokens;

        // Loop through each of the supported collateral types
        for (uint256 i = 0; i < dsInsuranceFund.collateralNames.length; i++) {
            // Obtain the collateral struct for the collateral type
            // participant is staking
            InsuranceFundDefs.StakeCollateral storage stakeCollateral =
                dsInsuranceFund.stakeCollaterals[dsInsuranceFund.collateralNames[i]];

            // Increment the USDT-normalized claimant tokens count with
            // the current balance
            claimantTokens = claimantTokens.add(
                getNormalizedCollateralValue(
                    dsInsuranceFund.collateralNames[i],
                    stakeCollateral.diFundToken.balanceOf(_claimant).safe96("IFund: exceeds 96 bits")
                )
            );
        }

        // Compute the claimed DDX based on the number of claimant
        // tokens and the difference between the user's index and the
        // claimant index computed above
        uint96 claimantDelta = claimantTokens.mul(deltaIndex).div(1e36).safe96("IFund: exceeds 96 bits");

        if (claimantDelta != 0) {
            // Adjust insurance mined amount
            dsInsuranceFund.minedAmount = dsInsuranceFund.minedAmount.add96(claimantDelta);

            // Increment the insurance mined claimed DDX for claimant
            dsInsuranceFund.ddxClaimantState[_claimant].claimedDDX = dsInsuranceFund.ddxClaimantState[_claimant]
                .claimedDDX
                .add96(claimantDelta);

            // Mint the DDX governance/operational token claimed reward
            // from the proxy contract to the participant
            LibTraderInternal.issueDDXReward(claimantDelta, _claimant);
        }

        // Check if COMP or aTokens have not already been claimed
        if (dsInsuranceFund.stakerToOtherRewardsClaims[_claimant] < dsInsuranceFund.otherRewardsCheckpointBlock) {
            // Record the current block number preventing a user from
            // reclaiming the COMP reward unfairly
            dsInsuranceFund.stakerToOtherRewardsClaims[_claimant] = block.number;

            // Claim COMP and extra aTokens
            claimOtherRewardsFromInsuranceMining(_claimant);
        }

        emit InsuranceMineRewardsClaimed(_claimant, claimantDelta);
    }

    /**
     * @notice Get USDT-normalized collateral token amount.
     * @param _collateralName The collateral name.
     * @param _value The number of tokens.
     */
    function getNormalizedCollateralValue(bytes32 _collateralName, uint96 _value) public view returns (uint96) {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        InsuranceFundDefs.StakeCollateral storage stakeCollateral = dsInsuranceFund.stakeCollaterals[_collateralName];

        return
            (stakeCollateral.flavor != InsuranceFundDefs.Flavor.Compound)
                ? getUnderlyingTokenAmountForVanilla(_value, stakeCollateral.collateralToken)
                : getUnderlyingTokenAmountForCompound(
                    _value,
                    ICToken(stakeCollateral.collateralToken).exchangeRateStored()
                );
    }

    /**
     * @notice This function gets a participant's current
     *         USD-normalized/denominated stake and global
     *         USD-normalized/denominated stake across all supported
     *         collateral types.
     * @param _staker Participant's address.
     * @return Current USD redemption value of DIFund tokens staked.
     * @return Current USD global cap.
     */
    function getCurrentTotalStakes(address _staker) public view returns (uint96, uint96) {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // Maintain running totals
        uint96 normalizedStakerStakeSum;
        uint96 normalizedGlobalCapSum;

        // Loop through each supported collateral
        for (uint256 i = 0; i < dsInsuranceFund.collateralNames.length; i++) {
            (, , uint96 normalizedStakerStake, uint96 normalizedGlobalCap) =
                getCurrentStakeByCollateralNameAndStaker(dsInsuranceFund.collateralNames[i], _staker);
            normalizedStakerStakeSum = normalizedStakerStakeSum.add96(normalizedStakerStake);
            normalizedGlobalCapSum = normalizedGlobalCapSum.add96(normalizedGlobalCap);
        }

        return (normalizedStakerStakeSum, normalizedGlobalCapSum);
    }

    /**
     * @notice This function gets a participant's current DIFund token
     *         holdings and global DIFund token holdings for a
     *         collateral type and staker, in addition to the
     *         USD-normalized collateral in the system and the
     *         redemption value for the staker.
     * @param _collateralName Name of collateral.
     * @param _staker Participant's address.
     * @return DIFund tokens for staker.
     * @return DIFund tokens globally.
     * @return Redemption value for staker (USD-denominated).
     * @return Underlying collateral (USD-denominated) in staking system.
     */
    function getCurrentStakeByCollateralNameAndStaker(bytes32 _collateralName, address _staker)
        public
        view
        returns (
            uint96,
            uint96,
            uint96,
            uint96
        )
    {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        InsuranceFundDefs.StakeCollateral storage stakeCollateral = dsInsuranceFund.stakeCollaterals[_collateralName];

        // Get DIFund tokens for staker
        uint96 stakerStake = stakeCollateral.diFundToken.balanceOf(_staker).safe96("IFund: exceeds 96 bits.");

        // Get DIFund tokens globally
        uint96 globalCap = stakeCollateral.diFundToken.totalSupply().safe96("IFund: exceeds 96 bits.");

        // Compute global USD-denominated stake capitalization. This is
        // is straightforward for non-Compound assets, but requires
        // exchange rate conversion for Compound assets.
        uint96 normalizedGlobalCap =
            (stakeCollateral.flavor != InsuranceFundDefs.Flavor.Compound)
                ? getUnderlyingTokenAmountForVanilla(stakeCollateral.cap, stakeCollateral.collateralToken)
                : getUnderlyingTokenAmountForCompound(
                    stakeCollateral.cap,
                    ICToken(stakeCollateral.collateralToken).exchangeRateStored()
                );

        // Compute the redemption value (USD-normalized) for staker
        // given DIFund token holdings
        uint96 normalizedStakerStake = globalCap > 0 ? normalizedGlobalCap.proportion96(stakerStake, globalCap) : 0;
        return (stakerStake, globalCap, normalizedStakerStake, normalizedGlobalCap);
    }

    /**
     * @notice This function gets a participant's DIFund token
     *         holdings and global DIFund token holdings for Compound
     *         and Aave tokens for a collateral type and staker as of
     *         the checkpointed block, in addition to the
     *         USD-normalized collateral in the system and the
     *         redemption value for the staker.
     * @param _collateralName Name of collateral.
     * @param _staker Participant's address.
     * @return DIFund tokens for staker.
     * @return DIFund tokens globally.
     * @return Redemption value for staker (USD-denominated).
     * @return Underlying collateral (USD-denominated) in staking system.
     */
    function getOtherRewardsStakeByCollateralNameAndStaker(bytes32 _collateralName, address _staker)
        public
        view
        returns (
            uint96,
            uint96,
            uint96,
            uint96
        )
    {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        InsuranceFundDefs.StakeCollateral storage stakeCollateral = dsInsuranceFund.stakeCollaterals[_collateralName];

        // Get DIFund tokens for staker as of the checkpointed block
        uint96 stakerStake =
            stakeCollateral.diFundToken.getPriorValues(_staker, dsInsuranceFund.otherRewardsCheckpointBlock.sub(1));

        // Get DIFund tokens globally as of the checkpointed block
        uint96 globalCap =
            stakeCollateral.diFundToken.getTotalPriorValues(dsInsuranceFund.otherRewardsCheckpointBlock.sub(1));

        // If Aave, don't worry about the normalized values since 1-1
        if (stakeCollateral.flavor == InsuranceFundDefs.Flavor.Aave) {
            return (stakerStake, globalCap, 0, 0);
        }

        // Compute global USD-denominated stake capitalization. This is
        // is straightforward for non-Compound assets, but requires
        // exchange rate conversion for Compound assets.
        uint96 normalizedGlobalCap =
            getUnderlyingTokenAmountForCompound(stakeCollateral.checkpointCap, stakeCollateral.exchangeRate);

        // Compute the redemption value (USD-normalized) for staker
        // given DIFund token holdings
        uint96 normalizedStakerStake = globalCap > 0 ? normalizedGlobalCap.proportion96(stakerStake, globalCap) : 0;
        return (stakerStake, globalCap, normalizedStakerStake, normalizedGlobalCap);
    }

    /**
     * @notice Claim other rewards (COMP and aTokens) for a claimant.
     * @param _claimant The address for the claimant.
     */
    function claimOtherRewardsFromInsuranceMining(address _claimant) internal {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();

        // Maintain a running total of COMP to be claimed from
        // insurance mining contract as a by product of cToken deposits
        uint96 compClaimedAmountSum;

        // Loop through collateral names that are supported
        for (uint256 i = 0; i < dsInsuranceFund.collateralNames.length; i++) {
            // Obtain collateral struct under consideration
            InsuranceFundDefs.StakeCollateral storage stakeCollateral =
                dsInsuranceFund.stakeCollaterals[dsInsuranceFund.collateralNames[i]];

            if (stakeCollateral.flavor == InsuranceFundDefs.Flavor.Vanilla) {
                // If collateral is of Vanilla flavor, we just
                // continue...
                continue;
            }

            // Compute the DIFund token holdings and the normalized,
            // USDT-normalized collateral value for the user
            (uint96 collateralStaker, uint96 collateralTotal, uint96 normalizedCollateralStaker, ) =
                getOtherRewardsStakeByCollateralNameAndStaker(dsInsuranceFund.collateralNames[i], _claimant);

            if ((collateralTotal == 0) || (collateralStaker == 0)) {
                // If there are no DIFund tokens, there is no reason to
                // claim rewards, so we continue...
                continue;
            }

            if (stakeCollateral.flavor == InsuranceFundDefs.Flavor.Aave) {
                // Aave has a special circumstance, where every
                // aToken results in additional aTokens accruing
                // to the holder's wallet. In this case, this is
                // the DerivaDEX contract. Therefore, we must
                // appropriately distribute the extra aTokens to
                // users claiming DDX for their aToken deposits.
                transferTokensAave(_claimant, dsInsuranceFund.collateralNames[i], collateralStaker, collateralTotal);
            } else if (stakeCollateral.flavor == InsuranceFundDefs.Flavor.Compound) {
                // If collateral is of type Compound, determine the
                // COMP claimant is entitled to based on the COMP
                // yield for this interval, the claimant's
                // DIFundToken share, and the USD-denominated
                // share for this market.
                uint96 compClaimedAmount =
                    dsInsuranceFund.compYields.accrued.proportion96(
                        normalizedCollateralStaker,
                        dsInsuranceFund.compYields.totalNormalizedCap
                    );

                // Increment the COMP claimed sum to be paid out
                // later
                compClaimedAmountSum = compClaimedAmountSum.add96(compClaimedAmount);
            }
        }

        // Distribute any COMP to be shared with the user
        if (compClaimedAmountSum > 0) {
            transferTokensCompound(_claimant, compClaimedAmountSum);
        }
    }

    /**
     * @notice This function transfers extra Aave aTokens to claimant.
     */
    function transferTokensAave(
        address _claimant,
        bytes32 _collateralName,
        uint96 _aaveStaker,
        uint96 _aaveTotal
    ) internal {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        // Obtain collateral struct under consideration
        InsuranceFundDefs.StakeCollateral storage stakeCollateral = dsInsuranceFund.stakeCollaterals[_collateralName];

        uint96 aTokenClaimedAmount =
            dsInsuranceFund.aTokenYields[_collateralName].accrued.proportion96(_aaveStaker, _aaveTotal);

        // Continues in scenarios token transfer fails (such as
        // transferring 0 tokens)
        try IAToken(stakeCollateral.collateralToken).transfer(_claimant, aTokenClaimedAmount) {} catch {}
    }

    /**
     * @notice This function transfers COMP tokens from the contract to
     *         a recipient.
     * @param _amount Amount of COMP to receive.
     */
    function transferTokensCompound(address _claimant, uint96 _amount) internal {
        // Continues in scenarios token transfer fails (such as
        // transferring 0 tokens)
        try COMP_TOKEN.transfer(_claimant, _amount) {} catch {}
    }

    /**
     * @notice Updates the DDX market state to ensure that claimants can receive
     *         their earned DDX rewards.
     */
    function updateDDXMarketState(LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund)
        internal
    {
        // Number of blocks that have elapsed from the last protocol
        // interaction resulting in DDX accrual. If insurance mining
        // has ended, we use this as the reference point, so deltaBlocks
        // will be 0 from the second time onwards.
        uint256 endBlock = Math.min(block.number, dsInsuranceFund.miningFinalBlockNumber);
        uint256 deltaBlocks = endBlock.sub(dsInsuranceFund.ddxMarketState.block);

        // If number of blocks elapsed and mine rate per block are
        // non-zero
        if (deltaBlocks > 0 && dsInsuranceFund.mineRatePerBlock > 0) {
            // Maintain a running total of USDT-normalized claim tokens
            // (i.e. 1e6 multiplier)
            uint256 claimTokens;

            // Loop through each of the supported collateral types
            for (uint256 i = 0; i < dsInsuranceFund.collateralNames.length; i++) {
                // Obtain the collateral struct for the collateral type
                // participant is staking
                InsuranceFundDefs.StakeCollateral storage stakeCollateral =
                    dsInsuranceFund.stakeCollaterals[dsInsuranceFund.collateralNames[i]];

                // Increment the USDT-normalized claim tokens count with
                // the current total supply
                claimTokens = claimTokens.add(
                    getNormalizedCollateralValue(
                        dsInsuranceFund.collateralNames[i],
                        stakeCollateral.diFundToken.totalSupply().safe96("IFund: exceeds 96 bits")
                    )
                );
            }

            // Compute DDX accrued during the time elapsed and the
            // number of tokens accrued per claim token outstanding
            uint256 ddxAccrued = deltaBlocks.mul(dsInsuranceFund.mineRatePerBlock);
            uint256 ratio = claimTokens > 0 ? ddxAccrued.mul(1e36).div(claimTokens) : 0;

            // Increment the index
            uint256 index = uint256(dsInsuranceFund.ddxMarketState.index).add(ratio);

            // Update the claim ddx market state with the new index
            // and block
            dsInsuranceFund.ddxMarketState.index = index.safe224("IFund: exceeds 224 bits");
            dsInsuranceFund.ddxMarketState.block = endBlock.safe32("IFund: exceeds 32 bits");
        } else if (deltaBlocks > 0) {
            dsInsuranceFund.ddxMarketState.block = endBlock.safe32("IFund: exceeds 32 bits");
        }
    }

    /**
     * @notice This function checks if a collateral token is present.
     * @param _collateralToken Collateral token address.
     * @return Whether collateral token is present or not.
     */
    function isCollateralTokenPresent(address _collateralToken) internal view returns (bool) {
        LibDiamondStorageInsuranceFund.DiamondStorageInsuranceFund storage dsInsuranceFund =
            LibDiamondStorageInsuranceFund.diamondStorageInsuranceFund();
        for (uint256 i = 0; i < dsInsuranceFund.collateralNames.length; i++) {
            // Return true if collateral token has been added
            if (
                dsInsuranceFund.stakeCollaterals[dsInsuranceFund.collateralNames[i]].collateralToken == _collateralToken
            ) {
                return true;
            }
        }

        // Collateral token has not been added, return false
        return false;
    }

    /**
     * @notice This function computes the underlying token amount for a
     *         vanilla token.
     * @param _vanillaAmount Number of vanilla tokens.
     * @param _collateral Address of vanilla collateral.
     * @return Underlying token amount.
     */
    function getUnderlyingTokenAmountForVanilla(uint96 _vanillaAmount, address _collateral)
        internal
        view
        returns (uint96)
    {
        uint256 vanillaDecimals = uint256(IERCCustom(_collateral).decimals());
        if (vanillaDecimals >= 6) {
            return uint256(_vanillaAmount).div(10**(vanillaDecimals.sub(6))).safe96("IFund: amount exceeds 96 bits");
        }
        return
            uint256(_vanillaAmount).mul(10**(uint256(6).sub(vanillaDecimals))).safe96("IFund: amount exceeds 96 bits");
    }

    /**
     * @notice This function computes the underlying token amount for a
     *         cToken amount by computing the current exchange rate.
     * @param _cTokenAmount Number of cTokens.
     * @param _exchangeRate Exchange rate derived from Compound.
     * @return Underlying token amount.
     */
    function getUnderlyingTokenAmountForCompound(uint96 _cTokenAmount, uint256 _exchangeRate)
        internal
        pure
        returns (uint96)
    {
        return _exchangeRate.mul(_cTokenAmount).div(1e18).safe96("IFund: amount exceeds 96 bits.");
    }
}