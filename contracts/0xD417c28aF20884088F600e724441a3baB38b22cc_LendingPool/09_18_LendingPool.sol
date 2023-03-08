/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity ^0.8.13;

import { SafeTransferLib } from "../lib/solmate/src/utils/SafeTransferLib.sol";
import { SafeCastLib } from "../lib/solmate/src/utils/SafeCastLib.sol";
import { FixedPointMathLib } from "../lib/solmate/src/utils/FixedPointMathLib.sol";
import { LogExpMath } from "./utils/LogExpMath.sol";
import { ITranche } from "./interfaces/ITranche.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { IVault } from "./interfaces/IVault.sol";
import { ILiquidator } from "./interfaces/ILiquidator.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";
import { TrustedCreditor } from "./TrustedCreditor.sol";
import { ERC20, ERC4626, DebtToken } from "./DebtToken.sol";
import { InterestRateModule } from "./InterestRateModule.sol";
import { Guardian } from "./security/Guardian.sol";

/**
 * @title Arcadia LendingPool.
 * @author Pragma Labs
 * @notice The Lending pool contains the main logic to provide liquidity and take or repay loans for a certain asset
 * and does the accounting of the debtTokens (ERC4626).
 * @dev Implementation not vulnerable to ERC4626 inflation attacks,
 * since totalAssets() cannot be manipulated by the first minter.
 * For more information, see https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706
 */
contract LendingPool is Guardian, TrustedCreditor, DebtToken, InterestRateModule, ILendingPool {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Seconds per year, leap years ignored.
    uint256 public constant YEARLY_SECONDS = 31_536_000;
    // Contract address of the Arcadia Vault Factory.
    address public immutable vaultFactory;
    // Contract address of the Liquidator contract.
    address public immutable liquidator;

    // Last timestamp that interests were realized.
    uint32 public lastSyncedTimestamp;
    // Origination fee, 4 decimals precision (10 equals 0.001 or 0.1%), capped at 255 (2.55%).
    uint8 public originationFee;
    // Sum of all the interest weights of the tranches + treasury.
    uint24 public totalInterestWeight;
    // Fraction (interestWeightTreasury / totalInterestWeight) of the interest fees that go to the treasury.
    uint16 public interestWeightTreasury;
    // Sum of the liquidation weights of the tranches + treasury.
    uint24 public totalLiquidationWeight;
    // Fraction (liquidationWeightTreasury / totalLiquidationWeight) of the liquidation fees that goes to the treasury.
    uint16 public liquidationWeightTreasury;

    // Total amount of `underlying asset` that is claimable by the LPs. Does not take into account pending interests.
    uint128 public totalRealisedLiquidity;
    // Maximum amount of `underlying asset` that can be supplied to the pool.
    uint128 public supplyCap;
    // Conservative estimate of the maximal gas cost to liquidate a position (fixed cost, independent of openDebt).
    uint96 public fixedLiquidationCost;
    // Maximum amount of `underlying asset` that is paid as fee to the initiator of a liquidation.
    uint80 public maxInitiatorFee;
    // Number of auctions that are currently in progress.
    uint16 public auctionsInProgress;
    // Address of the protocol treasury.
    address public treasury;

    // Array of the interest weights of each Tranche.
    // Fraction (interestWeightTranches[i] / totalInterestWeight) of the interest fees that go to Tranche i.
    uint16[] public interestWeightTranches;
    // Array of the liquidation weights of each Tranche.
    // Fraction (liquidationWeightTranches[i] / totalLiquidationWeight) of the liquidation fees that go to Tranche i.
    uint16[] public liquidationWeightTranches;
    // Array of the contract addresses of the Tranches.
    address[] public tranches;

    // Map tranche => status.
    mapping(address => bool) public isTranche;
    // Map tranche => interestWeight.
    // Fraction (interestWeightTranches[i] / totalInterestWeight) of the interest fees that go to Tranche i.
    mapping(address => uint256) public interestWeight;
    // Map tranche => realisedLiquidity.
    // Amount of `underlying asset` that is claimable by the Tranche. Does not take into account pending interests.
    mapping(address => uint256) public realisedLiquidityOf;
    // Map vault => initiator.
    // Stores the address of the initiator of an auction, used to pay out the initiation fee after auction is ended.
    mapping(address => address) public liquidationInitiator;
    // Map vault => owner => beneficiary => amount.
    // Stores the credit allowances for a beneficiary per Vault and per Owner.
    mapping(address => mapping(address => mapping(address => uint256))) public creditAllowance;

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event TrancheAdded(address indexed tranche, uint8 indexed index, uint16 interestWeight, uint16 liquidationWeight);
    event InterestWeightSet(uint256 indexed index, uint16 weight);
    event LiquidationWeightSet(uint256 indexed index, uint16 weight);
    event MaxInitiatorFeeSet(uint80 maxInitiatorFee);
    event TranchePopped(address tranche);
    event TreasuryInterestWeightSet(uint16 weight);
    event TreasuryLiquidationWeightSet(uint16 weight);
    event OriginationFeeSet(uint8 originationFee);
    event BorrowCapSet(uint128 borrowCap);
    event SupplyCapSet(uint128 supplyCap);
    event CreditApproval(address indexed vault, address indexed owner, address indexed beneficiary, uint256 amount);
    event Borrow(
        address indexed vault, address indexed by, address to, uint256 amount, uint256 fee, bytes3 indexed referrer
    );
    event Repay(address indexed vault, address indexed from, uint256 amount);
    event FixedLiquidationCostSet(uint96 fixedLiquidationCost);
    event VaultVersionSet(uint256 indexed vaultVersion, bool valid);

    error supplyCapExceeded();

    /* //////////////////////////////////////////////////////////////
                                MODIFIERS
    ////////////////////////////////////////////////////////////// */

    modifier onlyLiquidator() {
        require(liquidator == msg.sender, "LP: Only liquidator");
        _;
    }

    modifier onlyTranche() {
        require(isTranche[msg.sender], "LP: Only tranche");
        _;
    }

    modifier processInterests() {
        _syncInterests();
        _;
        //_updateInterestRate() modifies the state (effect), but can safely be called after interactions.
        //Cannot be exploited by re-entrancy attack.
        _updateInterestRate(realisedDebt, totalRealisedLiquidity);
    }

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice The constructor for a lending pool.
     * @param asset_ The underlying ERC-20 token of the Lending Pool.
     * @param treasury_ The address of the protocol treasury.
     * @param vaultFactory_ The address of the Vault Factory.
     * @param liquidator_ The address of the Liquidator.
     * @dev The name and symbol of the DebtToken are automatically generated, based on the name and symbol of the underlying token.
     */
    constructor(ERC20 asset_, address treasury_, address vaultFactory_, address liquidator_)
        Guardian()
        TrustedCreditor()
        DebtToken(asset_)
    {
        treasury = treasury_;
        vaultFactory = vaultFactory_;
        liquidator = liquidator_;
    }

    /* //////////////////////////////////////////////////////////////
                            TRANCHES LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Adds a tranche to the Lending Pool.
     * @param tranche The address of the Tranche.
     * @param interestWeight_ The interestWeight of the specific Tranche.
     * @param liquidationWeight The liquidationWeight of the specific Tranche.
     * @dev The order of the tranches is important, the most senior tranche is added first at index 0, the most junior at the last index.
     * @dev Each Tranche is an ERC-4626 contract.
     * @dev The interestWeight of each Tranche determines the relative share of the yield (interest payments) that goes to its Liquidity providers.
     * @dev The liquidationWeight of each Tranche determines the relative share of the liquidation fee that goes to its Liquidity providers.
     */
    function addTranche(address tranche, uint16 interestWeight_, uint16 liquidationWeight) external onlyOwner {
        require(!isTranche[tranche], "TR_AD: Already exists");
        totalInterestWeight += interestWeight_;
        interestWeightTranches.push(interestWeight_);
        interestWeight[tranche] = interestWeight_;

        totalLiquidationWeight += liquidationWeight;
        liquidationWeightTranches.push(liquidationWeight);

        tranches.push(tranche);
        isTranche[tranche] = true;

        emit TrancheAdded(tranche, uint8(tranches.length - 1), interestWeight_, liquidationWeight);
    }

    /**
     * @notice Changes the interestWeight of a specific Tranche.
     * @param index The index of the Tranche for which a new interestWeight is being set.
     * @param weight The new interestWeight of the Tranche at the index.
     * @dev The interestWeight of each Tranche determines the relative share yield (interest payments) that goes to its Liquidity providers.
     */
    function setInterestWeight(uint256 index, uint16 weight) external onlyOwner {
        require(index < tranches.length, "TR_SIW: Non Existing Tranche");
        totalInterestWeight = totalInterestWeight - interestWeightTranches[index] + weight;
        interestWeightTranches[index] = weight;
        interestWeight[tranches[index]] = weight;

        emit InterestWeightSet(index, weight);
    }

    /**
     * @notice Changes the liquidationWeight of a specific tranche.
     * @param index The index of the Tranche for which a new liquidationWeight is being set.
     * @param weight The new liquidationWeight of the Tranche at the index.
     * @dev The liquidationWeight determines the relative share of the liquidation fee that goes to its Liquidity providers.
     */
    function setLiquidationWeight(uint256 index, uint16 weight) external onlyOwner {
        require(index < tranches.length, "TR_SLW: Non Existing Tranche");
        totalLiquidationWeight = totalLiquidationWeight - liquidationWeightTranches[index] + weight;
        liquidationWeightTranches[index] = weight;

        emit LiquidationWeightSet(index, weight);
    }

    /**
     * @notice Removes the Tranche at the last index (most junior).
     * @param index The index of the last Tranche.
     * @param tranche The address of the last Tranche.
     * @dev This function can only be called by the function _processDefault(uint256 assets),
     * when there is a default as big as (or bigger than) the complete principal of the most junior tranche.
     * @dev Passing the input parameters to the function saves gas compared to reading the address and index of the last tranche from memory.
     * No need to check if index and Tranche are indeed of the last tranche since function is only called by _processDefault.
     */
    function _popTranche(uint256 index, address tranche) internal {
        totalInterestWeight -= interestWeightTranches[index];
        totalLiquidationWeight -= liquidationWeightTranches[index];
        isTranche[tranche] = false;
        interestWeightTranches.pop();
        liquidationWeightTranches.pop();
        tranches.pop();

        emit TranchePopped(tranche);
    }

    /* ///////////////////////////////////////////////////////////////
                    TREASURY FEE CONFIGURATION
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Changes the fraction of the interest payments that go to the treasury.
     * @param interestWeightTreasury_ The new interestWeight of the treasury.
     * @dev The interestWeight determines the relative share of the yield (interest payments) that goes to the protocol treasury.
     * @dev Setting interestWeightTreasury to a very high value will cause the treasury to collect all interest fees from that moment on.
     * Although this will affect the future profits of liquidity providers, no funds nor realized interest are at risk for LPs.
     */
    function setTreasuryInterestWeight(uint16 interestWeightTreasury_) external onlyOwner {
        totalInterestWeight = totalInterestWeight - interestWeightTreasury + interestWeightTreasury_;
        interestWeightTreasury = interestWeightTreasury_;

        emit TreasuryInterestWeightSet(interestWeightTreasury_);
    }

    /**
     * @notice Changes the fraction of the liquidation fees that go to the treasury.
     * @param liquidationWeightTreasury_ The new liquidationWeight of the liquidation fee fee.
     * @dev The liquidationWeight determines the relative share of the liquidation fee that goes to the protocol treasury.
     * @dev Setting liquidationWeightTreasury to a very high value will cause the treasury to collect all liquidation fees from that moment on.
     * Although this will affect the future profits of liquidity providers in the Jr tranche, no funds nor realized interest are at risk for LPs.
     */
    function setTreasuryLiquidationWeight(uint16 liquidationWeightTreasury_) external onlyOwner {
        totalLiquidationWeight = totalLiquidationWeight - liquidationWeightTreasury + liquidationWeightTreasury_;
        liquidationWeightTreasury = liquidationWeightTreasury_;

        emit TreasuryLiquidationWeightSet(liquidationWeightTreasury_);
    }

    /**
     * @notice Sets new treasury address.
     * @param treasury_ The new address of the treasury.
     */
    function setTreasury(address treasury_) external onlyOwner {
        treasury = treasury_;
    }

    /**
     * @notice Sets the new origination fee.
     * @param originationFee_ The new origination fee.
     * @dev originationFee is limited by being a uint8 -> max value is 2.55%
     * 4 decimal precision (10 = 0.1%).
     */
    function setOriginationFee(uint8 originationFee_) external onlyOwner {
        originationFee = originationFee_;

        emit OriginationFeeSet(originationFee_);
    }

    /* //////////////////////////////////////////////////////////////
                         PROTOCOL CAP LOGIC
    ////////////////////////////////////////////////////////////// */
    /**
     * @notice Sets the maximum amount of assets that can be borrowed per Vault.
     * @param borrowCap_ The new maximum amount that can be borrowed.
     * @dev The borrowCap is the maximum amount of assets that can be borrowed per Vault.
     * @dev If it is set to 0, there is no borrow cap.
     */
    function setBorrowCap(uint128 borrowCap_) external onlyOwner {
        borrowCap = borrowCap_;

        emit BorrowCapSet(borrowCap_);
    }

    /**
     * @notice Sets the maximum amount of assets that can be deposited in the pool.
     * @param supplyCap_ The new maximum amount of assets that can be deposited.
     * @dev The supplyCap is the maximum amount of assets that can be deposited in the pool at any given time.
     * @dev If it is set to 0, there is no supply cap.
     */
    function setSupplyCap(uint128 supplyCap_) external onlyOwner {
        supplyCap = supplyCap_;

        emit SupplyCapSet(supplyCap_);
    }

    /* //////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Deposit assets in the Lending Pool.
     * @param assets The amount of assets of the underlying ERC-20 tokens being deposited.
     * @param from The address of the Liquidity Provider who deposits the underlying ERC-20 token via a Tranche.
     * @dev This function can only be called by Tranches.
     */

    function depositInLendingPool(uint256 assets, address from)
        external
        whenDepositNotPaused
        onlyTranche
        processInterests
    {
        if (supplyCap > 0) {
            if (totalRealisedLiquidity + assets > supplyCap) revert supplyCapExceeded();
        }
        // Need to transfer before minting or ERC777s could reenter.
        // Address(this) is trusted -> no risk on re-entrancy attack after transfer.
        asset.safeTransferFrom(from, address(this), assets);

        unchecked {
            realisedLiquidityOf[msg.sender] += assets;
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(assets);
        }

        //Event emitted by Tranche.
    }

    /**
     * @notice Donate assets to the Lending Pool.
     * @param trancheIndex The index of the tranche to donate to.
     * @param assets The amount of assets of the underlying ERC-20 tokens being deposited.
     * @dev Can be used by anyone to donate assets to the Lending Pool.
     * It is supposed to serve as a way to compensate the jrTranche after an
     * auction didn't get sold and was manually Liquidated by the Protocol.
     * @dev First minter of a tranche could abuse this function by mining only 1 share,
     * frontrun next minter by calling this function and inflate the share price.
     * This is mitigated by checking that there are at least 10 ** decimals shares outstanding.
     */
    function donateToTranche(uint256 trancheIndex, uint256 assets) external whenDepositNotPaused processInterests {
        require(assets > 0, "LP_DTT: Amount is 0");

        if (supplyCap > 0) {
            if (totalRealisedLiquidity + assets > supplyCap) revert supplyCapExceeded();
        }

        address tranche = tranches[trancheIndex];
        //Mitigate share manipulation, where first Liquidity Provider mints just 1 share.
        //See https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3706 for more information.
        require(ERC4626(tranche).totalSupply() >= 10 ** decimals, "LP_DTT: Insufficient shares");

        asset.safeTransferFrom(msg.sender, address(this), assets);

        unchecked {
            realisedLiquidityOf[tranche] += assets; //[̲̅$̲̅(̲̅ ͡° ͜ʖ ͡°̲̅)̲̅$̲̅]
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(assets);
        }
    }

    /**
     * @notice Withdraw assets from the Lending Pool.
     * @param assets The amount of assets of the underlying ERC-20 tokens being withdrawn.
     * @param receiver The address of the receiver of the underlying ERC-20 tokens.
     * @dev This function can be called by anyone with an open balance (realisedLiquidityOf[address] bigger than 0),
     * which can be both Tranches as other address (treasury, Liquidation Initiators, Liquidated Vault Owner...).
     */
    function withdrawFromLendingPool(uint256 assets, address receiver)
        external
        whenWithdrawNotPaused
        processInterests
    {
        require(realisedLiquidityOf[msg.sender] >= assets, "LP_WFLP: Amount exceeds balance");

        unchecked {
            realisedLiquidityOf[msg.sender] -= assets;
        }
        totalRealisedLiquidity -= SafeCastLib.safeCastTo128(assets);

        asset.safeTransfer(receiver, assets);

        //Event emitted by Tranche.
    }

    /* //////////////////////////////////////////////////////////////
                            LENDING LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Approve a beneficiary to take out a loan against an Arcadia Vault.
     * @param beneficiary The address of the beneficiary who can take out a loan backed by an Arcadia Vault.
     * @param amount The amount of underlying ERC-20 tokens to be lent out.
     * @param vault The address of the Arcadia Vault backing the loan.
     */
    function approveBeneficiary(address beneficiary, uint256 amount, address vault) external {
        //If vault is not an actual address of a vault, ownerOfVault(address) will return the zero address.
        require(IFactory(vaultFactory).ownerOfVault(vault) == msg.sender, "LP_AB: UNAUTHORIZED");

        creditAllowance[vault][msg.sender][beneficiary] = amount;

        emit CreditApproval(vault, msg.sender, beneficiary, amount);
    }

    /**
     * @notice Takes out a loan backed by collateral in an Arcadia Vault.
     * @param amount The amount of underlying ERC-20 tokens to be lent out.
     * @param vault The address of the Arcadia Vault backing the loan.
     * @param to The address who receives the lent out underlying tokens.
     * @param referrer A unique identifier of the referrer, who will receive part of the fees generated by this transaction.
     * @dev The sender might be different than the owner if they have the proper allowances.
     */
    function borrow(uint256 amount, address vault, address to, bytes3 referrer)
        external
        whenBorrowNotPaused
        processInterests
    {
        //If vault is not an actual address of a vault, ownerOfVault(address) will return the zero address.
        address vaultOwner = IFactory(vaultFactory).ownerOfVault(vault);
        require(vaultOwner != address(0), "LP_B: Not a vault");

        uint256 amountWithFee = amount + (amount * originationFee) / 10_000;

        //Check allowances to take debt.
        if (vaultOwner != msg.sender) {
            uint256 allowed = creditAllowance[vault][vaultOwner][msg.sender];
            if (allowed != type(uint256).max) {
                creditAllowance[vault][vaultOwner][msg.sender] = allowed - amountWithFee;
            }
        }

        //Mint debt tokens to the vault.
        _deposit(amountWithFee, vault);

        //Add origination fee to the treasury.
        unchecked {
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(amountWithFee - amount);
            realisedLiquidityOf[treasury] += amountWithFee - amount;
        }

        //Call vault to check if it is still healthy after the debt is increased with amountWithFee.
        (bool isHealthy, address trustedCreditor, uint256 vaultVersion) =
            IVault(vault).isVaultHealthy(0, maxWithdraw(vault));
        require(isHealthy && trustedCreditor == address(this) && isValidVersion[vaultVersion], "LP_B: Reverted");

        //Transfer fails if there is insufficient liquidity in the pool.
        asset.safeTransfer(to, amount);

        emit Borrow(vault, msg.sender, to, amount, amountWithFee - amount, referrer);
    }

    /**
     * @notice Repays a loan.
     * @param amount The amount of underlying ERC-20 tokens to be repaid.
     * @param vault The address of the Arcadia Vault backing the loan.
     * @dev if Vault is not an actual address of a Vault, maxWithdraw(vault) will always return 0.
     * Function will not revert, but transferAmount is always 0.
     * @dev Anyone (EOAs and contracts) can repay debt in the name of a vault.
     */
    function repay(uint256 amount, address vault) external whenRepayNotPaused processInterests {
        uint256 vaultDebt = maxWithdraw(vault);
        uint256 transferAmount = vaultDebt > amount ? amount : vaultDebt;

        // Need to transfer before burning debt or ERC777s could reenter.
        // Address(this) is trusted -> no risk on re-entrancy attack after transfer.
        asset.safeTransferFrom(msg.sender, address(this), transferAmount);

        _withdraw(transferAmount, vault, vault);

        emit Repay(vault, msg.sender, transferAmount);
    }

    /* //////////////////////////////////////////////////////////////
                        LEVERAGED ACTIONS LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Execute and interact with external logic on leverage.
     * @param amountBorrowed The amount of underlying ERC-20 tokens to be lent out.
     * @param vault The address of the Arcadia Vault backing the loan.
     * @param actionHandler the address of the action handler to call.
     * @param actionData a bytes object containing two actionAssetData structs, an address array and a bytes array.
     * @param referrer A unique identifier of the referrer, who will receive part of the fees generated by this transaction.
     * @dev The sender might be different than the owner if they have the proper allowances.
     * @dev vaultManagementAction() works similar to flash loans, this function optimistically calls external logic and checks for the vault state at the very end.
     */
    function doActionWithLeverage(
        uint256 amountBorrowed,
        address vault,
        address actionHandler,
        bytes calldata actionData,
        bytes3 referrer
    ) external whenBorrowNotPaused processInterests {
        //If vault is not an actual address of a vault, ownerOfVault(address) will return the zero address.
        address vaultOwner = IFactory(vaultFactory).ownerOfVault(vault);
        require(vaultOwner != address(0), "LP_DAWL: Not a vault");

        uint256 amountBorrowedWithFee = amountBorrowed + (amountBorrowed * originationFee) / 10_000;

        //Check allowances to take debt.
        if (vaultOwner != msg.sender) {
            //Since calling vaultManagementAction() gives the sender full control over all assets in the vault,
            //Only Beneficiaries with maximum allowance can call the doActionWithLeverage function.
            require(creditAllowance[vault][vaultOwner][msg.sender] == type(uint256).max, "LP_DAWL: UNAUTHORIZED");
        }

        //Mint debt tokens to the vault, debt must be minted Before the actions in the vault are performed.
        _deposit(amountBorrowedWithFee, vault);

        //Add origination fee to the treasury.
        unchecked {
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(amountBorrowedWithFee - amountBorrowed);
            realisedLiquidityOf[treasury] += amountBorrowedWithFee - amountBorrowed;
        }

        //Send Borrowed funds to the actionHandler.
        asset.safeTransfer(actionHandler, amountBorrowed);

        //The actionHandler will use the borrowed funds (optionally with additional assets withdrawn from the Vault)
        //to execute one or more actions (swap, deposit, mint...).
        //Next the actionHandler will deposit any of the remaining funds or any of the recipient token
        //resulting from the actions back into the vault.
        //As last step, after all assets are deposited back into the vault a final health check is done:
        //The Collateral Value of all assets in the vault is bigger than the total liabilities against the vault (including the margin taken during this function).
        (address trustedCreditor, uint256 vaultVersion) = IVault(vault).vaultManagementAction(actionHandler, actionData);
        require(trustedCreditor == address(this) && isValidVersion[vaultVersion], "LP_DAWL: Reverted");

        emit Borrow(vault, msg.sender, actionHandler, amountBorrowed, amountBorrowedWithFee - amountBorrowed, referrer);
    }

    /* //////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Returns the total amount of outstanding debt in the underlying asset.
     * @return totalDebt The total debt in underlying assets.
     */
    function totalAssets() public view override returns (uint256 totalDebt) {
        // Avoid a second calculation of unrealised debt (expensive)
        // if interests are already synced this block.
        if (lastSyncedTimestamp != uint32(block.timestamp)) {
            totalDebt = realisedDebt + calcUnrealisedDebt();
        } else {
            totalDebt = realisedDebt;
        }
    }

    /**
     * @notice Returns the redeemable amount of liquidity in the underlying asset of an address.
     * @param owner_ The address of the liquidity provider.
     * @return assets The redeemable amount of liquidity in the underlying asset.
     * @dev This function syncs the interests to prevent calculating UnrealisedDebt twice when depositing/withdrawing through the Tranches.
     * @dev After calling this function, the interest rate will not be updated until the next processInterests() call.
     */
    function liquidityOfAndSync(address owner_) external returns (uint256 assets) {
        _syncInterests();
        assets = realisedLiquidityOf[owner_];
    }

    /**
     * @notice Returns the redeemable amount of liquidity in the underlying asset of an address.
     * @param owner_ The address of the liquidity provider.
     * @return assets The redeemable amount of liquidity in the underlying asset.
     */
    function liquidityOf(address owner_) external view returns (uint256 assets) {
        // Avoid a second calculation of unrealised debt (expensive).
        // if interests are already synced this block.
        if (lastSyncedTimestamp != uint32(block.timestamp)) {
            // The total liquidity of a tranche equals the sum of the realised liquidity
            // of the tranche, and its pending interests.
            uint256 interest = calcUnrealisedDebt().mulDivUp(interestWeight[owner_], totalInterestWeight);
            unchecked {
                assets = realisedLiquidityOf[owner_] + interest;
            }
        } else {
            assets = realisedLiquidityOf[owner_];
        }
    }

    /**
     * @notice Skims any surplus funds in the LendingPool to the treasury.
     * @dev In normal conditions (when there are no ongoing auctions), the total Claimable Liquidity should be equal
     * to the sum of the available funds (the balanceOf() the underlying asset) in the pool and the total open debt.
     * In practice the actual sum of available funds and total open debt will always be bigger than the total Claimable Liquidity.
     * This because of the rounding errors of the ERC4626 calculations (conversions between assets and shares),
     * or because someone accidentally sent funds directly to the pool instead of depositing via a Tranche.
     * This functions makes the surplus available to the Treasury (otherwise they would be lost forever).
     * @dev In case you accidentally sent funds to the pool, contact the current treasury manager.
     */
    function skim() external processInterests {
        //During auctions, debt tokens are burned at start of the auction, while auctions proceeds are only returned
        //at the end of the auction -> skim function must be blocked during auctions.
        require(auctionsInProgress == 0, "LP_S: Auctions Ongoing");

        //Pending interests are synced via the processInterests modifier.
        uint256 delta = asset.balanceOf(address(this)) + realisedDebt - totalRealisedLiquidity;

        //Add difference to the treasury.
        unchecked {
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(delta);
            realisedLiquidityOf[treasury] += delta;
        }
    }

    /* //////////////////////////////////////////////////////////////
                            INTERESTS LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Syncs all unrealised debt (= interest for LP and treasury).
     * @dev Calculates the unrealised debt since last sync, and realises it by minting an equal amount of
     * debt tokens to all debt holders and interests to LPs and the treasury.
     */
    function _syncInterests() internal {
        // Only Sync interests once per block.
        if (lastSyncedTimestamp != uint32(block.timestamp)) {
            uint256 unrealisedDebt = calcUnrealisedDebt();
            lastSyncedTimestamp = uint32(block.timestamp);

            //Sync interests for borrowers.
            unchecked {
                realisedDebt += unrealisedDebt;
            }

            //Sync interests for LPs and Protocol Treasury.
            _syncInterestsToLiquidityProviders(unrealisedDebt);
        }
    }

    /**
     * @notice Calculates the unrealised debt (interests).
     * @return unrealisedDebt The unrealised debt.
     * @dev To Find the unrealised debt over an amount of time, you need to calculate D[(1+r)^x-1].
     * The base of the exponential: 1 + r, is a 18 decimals fixed point number
     * with r the yearly interest rate.
     * The exponent of the exponential: x, is a 18 decimals fixed point number.
     * The exponent x is calculated as: the amount of seconds passed since last sync timestamp divided by the average of
     * seconds per year. _yearlyInterestRate = 1 + r expressed as 18 decimals fixed point number.
     */
    function calcUnrealisedDebt() public view returns (uint256 unrealisedDebt) {
        uint256 base;
        uint256 exponent;

        unchecked {
            //gas: Can't overflow for reasonable interest rates.
            base = 1e18 + interestRate;

            //gas: Only overflows when (block.timestamp - lastSyncedBlockTimestamp) > 1e59
            //in practice: exponent in LogExpMath lib is limited to 130e18,
            //Corresponding to a delta of timestamps of 4099680000 (or 130 years),
            //much bigger than any realistic time difference between two syncs.
            exponent = ((block.timestamp - lastSyncedTimestamp) * 1e18) / YEARLY_SECONDS;

            //gas: Taking an imaginary worst-case scenario with max interest of 1000%
            //over a period of 5 years.
            //This won't overflow as long as openDebt < 3402823669209384912995114146594816
            //which is 3.4 million billion *10**18 decimals.
            unrealisedDebt = (realisedDebt * (LogExpMath.pow(base, exponent) - 1e18)) / 1e18;
        }

        return SafeCastLib.safeCastTo128(unrealisedDebt);
    }

    /**
     * @notice Syncs interest payments to the Lending providers and the treasury.
     * @param assets The total amount of underlying assets to be paid out as interests.
     * @dev The interestWeight of each Tranche determines the relative share yield (interest payments) that goes to its Liquidity providers.
     */
    function _syncInterestsToLiquidityProviders(uint256 assets) internal {
        uint256 remainingAssets = assets;

        uint256 trancheShare;
        for (uint256 i; i < tranches.length;) {
            trancheShare = assets.mulDivDown(interestWeightTranches[i], totalInterestWeight);
            unchecked {
                realisedLiquidityOf[tranches[i]] += trancheShare;
                remainingAssets -= trancheShare;
                ++i;
            }
        }
        unchecked {
            totalRealisedLiquidity += SafeCastLib.safeCastTo128(assets);

            // Add the remainingAssets to the treasury balance.
            realisedLiquidityOf[treasury] += remainingAssets;
        }
    }

    /* //////////////////////////////////////////////////////////////
                        INTEREST RATE LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Set's the configuration parameters of InterestRateConfiguration struct.
     * @param newConfig New set of configuration parameters.
     */
    function setInterestConfig(InterestRateConfiguration calldata newConfig) external onlyOwner {
        _setInterestConfig(newConfig);
    }

    /**
     * @notice Updates the interest rate.
     * @dev Any address can call this, it will sync unrealised interests and update the interest rate.
     */
    function updateInterestRate() external processInterests { }

    /* //////////////////////////////////////////////////////////////
                        LIQUIDATION LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Sets the maxInitiatorFee.
     * @param maxInitiatorFee_ The maximum fee that is paid to the initiator of a liquidation.
     * @dev The liquidator sets the % of the debt that is paid to the initiator of a liquidation.
     * This fee is capped by the maxInitiatorFee.
     */
    function setMaxInitiatorFee(uint80 maxInitiatorFee_) external onlyOwner {
        maxInitiatorFee = maxInitiatorFee_;

        emit MaxInitiatorFeeSet(maxInitiatorFee_);
    }

    /**
     * @notice Sets the estimated max gas cost to liquidate a position, denominated in baseCurrency.
     * @param fixedLiquidationCost_ The new fixedLiquidationCost.
     * @dev Conservative estimate of the maximal gas cost to liquidate a position (fixed cost, independent of openDebt).
     * The fixedLiquidationCost prevents dusting attacks, and ensures that upon Liquidations positions are big enough to cover.
     * gas costs of the Liquidator without resulting in badDebt.
     */
    function setFixedLiquidationCost(uint96 fixedLiquidationCost_) external onlyOwner {
        fixedLiquidationCost = fixedLiquidationCost_;

        emit FixedLiquidationCostSet(fixedLiquidationCost_);
    }

    /**
     * @notice Starts liquidation of a Vault.
     * @param vault The vault address.
     * @dev At the start of the liquidation the debt tokens are burned,
     * as such interests are not accrued during the liquidation.
     */

    function liquidateVault(address vault) external whenLiquidationNotPaused processInterests {
        //Only Vaults can have debt, and debtTokens are non-transferrable.
        //Hence by checking that the balance of the address passed as vault is not 0, we know the address
        //passed as vault is indeed a vault and has debt.
        uint256 openDebt = maxWithdraw(vault);
        require(openDebt != 0, "LP_LV: Not a Vault with debt");

        //Store liquidation initiator to pay out initiator reward when auction is finished.
        liquidationInitiator[vault] = msg.sender;

        //Start the auction of the collateralised assets to repay debt.
        ILiquidator(liquidator).startAuction(vault, openDebt, maxInitiatorFee);

        //Hook to the most junior Tranche, to inform that auctions are ongoing,
        //already done if there are other auctions in progress (auctionsInProgress > O).
        if (auctionsInProgress == 0) {
            ITranche(tranches[tranches.length - 1]).setAuctionInProgress(true);
        }
        unchecked {
            ++auctionsInProgress;
        }

        //Remove debt from Vault (burn DebtTokens).
        _withdraw(openDebt, vault, vault);

        //Event emitted by Liquidator.
    }

    /**
     * @notice Settles the liquidation after the auction is finished and pays out Creditor, Original owner and Service providers.
     * @param vault The contract address of the vault.
     * @param originalOwner The original owner of the vault before the auction.
     * @param badDebt The amount of liabilities that was not recouped by the auction.
     * @param liquidationInitiatorReward The Reward for the Liquidation Initiator.
     * @param liquidationFee The additional fee the `originalOwner` has to pay to the protocol.
     * @param remainder Any funds remaining after the auction are returned back to the `originalOwner`.
     * @dev This function is called by the Liquidator after a liquidation is finished.
     * @dev The liquidator will transfer the auction proceeds (the underlying asset)
     * back to the liquidity pool after liquidation, before calling this function.
     */

    function settleLiquidation(
        address vault,
        address originalOwner,
        uint256 badDebt,
        uint256 liquidationInitiatorReward,
        uint256 liquidationFee,
        uint256 remainder
    ) external onlyLiquidator processInterests {
        //Make Initiator rewards claimable for liquidationInitiator[vault].
        realisedLiquidityOf[liquidationInitiator[vault]] += liquidationInitiatorReward;

        if (badDebt > 0) {
            //Collateral was auctioned for less than the liabilities (openDebt + Liquidation Initiator Reward)
            //-> Default event, deduct badDebt from LPs, starting with most Junior Tranche.
            totalRealisedLiquidity =
                SafeCastLib.safeCastTo128(uint256(totalRealisedLiquidity) + liquidationInitiatorReward - badDebt);
            _processDefault(badDebt);
        } else {
            //Collateral was auctioned for more than the liabilities
            //-> Pay out the Liquidation Fee to treasury and Tranches.
            _syncLiquidationFeeToLiquidityProviders(liquidationFee);
            totalRealisedLiquidity = SafeCastLib.safeCastTo128(
                uint256(totalRealisedLiquidity) + liquidationInitiatorReward + liquidationFee + remainder
            );

            //Any remaining assets after paying off liabilities and the fee go back to the original Vault Owner.
            if (remainder > 0) {
                //Make remainder claimable by originalOwner.
                realisedLiquidityOf[originalOwner] += remainder;
            }
        }

        unchecked {
            --auctionsInProgress;
        }
        //Hook to the most junior Tranche to inform that there are no ongoing auctions.
        if (auctionsInProgress == 0 && tranches.length > 0) {
            ITranche(tranches[tranches.length - 1]).setAuctionInProgress(false);
        }

        //Event emitted by Liquidator.
    }

    /**
     * @notice Handles the bookkeeping in case of bad debt (Vault became undercollateralised).
     * @param badDebt The total amount of underlying assets that need to be written off as bad debt.
     * @dev The order of the Tranches is important, the most senior tranche is at index 0, the most junior at the last index.
     * @dev The most junior tranche will lose its underlying assets first. If all liquidity of a certain Tranche is written off,
     * the complete tranche is locked and removed. If there is still remaining bad debt, the next Tranche starts losing capital.
     */
    function _processDefault(uint256 badDebt) internal {
        address tranche;
        uint256 maxBurnable;
        for (uint256 i = tranches.length; i > 0;) {
            unchecked {
                --i;
            }
            tranche = tranches[i];
            maxBurnable = realisedLiquidityOf[tranche];
            if (badDebt < maxBurnable) {
                //Deduct badDebt from the balance of the most junior Tranche.
                unchecked {
                    realisedLiquidityOf[tranche] -= badDebt;
                }
                break;
            } else {
                //Unhappy flow, should never occur in practice!
                //badDebt is bigger than balance most junior Tranche -> tranche is completely wiped out
                //and temporarily locked (no new deposits or withdraws possible).
                //DAO or insurance might refund (Part of) the losses, and add Tranche back.
                realisedLiquidityOf[tranche] = 0;
                _popTranche(i, tranche);
                unchecked {
                    badDebt -= maxBurnable;
                }
                ITranche(tranche).lock();
                //Hook to the new most junior Tranche to inform that auctions are ongoing.
                if (i != 0) ITranche(tranches[i - 1]).setAuctionInProgress(true);
            }
        }
    }

    /**
     * @notice Syncs liquidation penalties to the Lending providers and the treasury.
     * @param assets The total amount of underlying assets to be paid out as liquidation fee.
     * @dev The liquidationWeight of each Tranche determines the relative share yield (interest payments) that goes to its Liquidity providers.
     */
    function _syncLiquidationFeeToLiquidityProviders(uint256 assets) internal {
        uint256 remainingAssets = assets;

        uint256 trancheShare;
        uint256 weightOfTranche;
        for (uint256 i; i < tranches.length;) {
            weightOfTranche = liquidationWeightTranches[i];

            if (weightOfTranche != 0) {
                //skip if weight is zero, which is the case for Sr tranche.
                trancheShare = assets.mulDivDown(weightOfTranche, totalLiquidationWeight);
                unchecked {
                    realisedLiquidityOf[tranches[i]] += trancheShare;
                    remainingAssets -= trancheShare;
                }
            }

            unchecked {
                ++i;
            }
        }

        unchecked {
            // Add the remainingAssets to the treasury balance.
            realisedLiquidityOf[treasury] += remainingAssets;
        }
    }

    /* //////////////////////////////////////////////////////////////
                            VAULT LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Enables or disables a certain Vault version to be used as margin account.
     * @param vaultVersion The Vault version to be enabled/disabled.
     * @param valid The validity of the respective vaultVersion.
     */
    function setVaultVersion(uint256 vaultVersion, bool valid) external onlyOwner {
        _setVaultVersion(vaultVersion, valid);

        emit VaultVersionSet(vaultVersion, valid);
    }

    /**
     * @inheritdoc TrustedCreditor
     */
    function openMarginAccount(uint256 vaultVersion)
        external
        view
        override
        returns (bool success, address baseCurrency, address liquidator_, uint256 fixedLiquidationCost_)
    {
        if (isValidVersion[vaultVersion]) {
            success = true;
            baseCurrency = address(asset);
            liquidator_ = liquidator;
            fixedLiquidationCost_ = fixedLiquidationCost;
        }
    }

    /**
     * @inheritdoc TrustedCreditor
     */
    function getOpenPosition(address vault) external view override returns (uint256 openPosition) {
        openPosition = maxWithdraw(vault);
    }
}