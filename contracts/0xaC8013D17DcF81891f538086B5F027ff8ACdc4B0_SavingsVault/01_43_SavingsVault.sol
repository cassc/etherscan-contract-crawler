// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "lib/openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/IERC20Upgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/utils/math/MathUpgradeable.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

import { NotionalViews, MarketParameters } from "./external/notional/interfaces/INotional.sol";
import "./external/notional/lib/DateTime.sol";
import "./external/notional/interfaces/IWrappedfCashFactory.sol";
import { IWrappedfCashComplete } from "./external/notional/interfaces/IWrappedfCash.sol";
import "./external/notional/lib/Constants.sol";
import "./interfaces/ISavingsVault.sol";
import "./interfaces/ISavingsVaultHarvester.sol";
import "./interfaces/ISavingsVaultViewer.sol";
import "./libraries/AUMCalculationLibrary.sol";
import "./libraries/TypeConversionLibrary.sol";

/// @title Savings vault
/// @notice Contains logic for integration with Notional protocol
contract SavingsVault is
    ISavingsVault,
    ISavingsVaultHarvester,
    ISavingsVaultViewer,
    ERC4626Upgradeable,
    ERC20PermitUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUpgradeable for uint256;

    /// @notice Responsible for all vault related permissions
    bytes32 internal constant VAULT_ADMIN_ROLE = keccak256("VAULT_ADMIN_ROLE");
    /// @notice Role for vault management
    bytes32 internal constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");

    /// @inheritdoc ISavingsVaultViewer
    uint8 public constant SUPPORTED_MATURITIES = 2;
    /// @inheritdoc ISavingsVaultViewer
    uint16 public constant BP = 10_000;
    /// @inheritdoc ISavingsVaultViewer
    uint public constant AUM_SCALED_PER_SECONDS_RATE = 1000000000158946658547141217;
    /// @inheritdoc ISavingsVaultViewer
    uint public constant MINTING_FEE_IN_BP = 0;
    /// @inheritdoc ISavingsVaultViewer
    uint public constant BURNING_FEE_IN_BP = 0;

    /// @inheritdoc ISavingsVaultViewer
    uint16 public currencyId;
    /// @inheritdoc ISavingsVaultViewer
    uint16 public maxLoss;
    /// @inheritdoc ISavingsVaultViewer
    address public notionalRouter;
    /// @inheritdoc ISavingsVaultViewer
    IWrappedfCashFactory public wrappedfCashFactory;
    /// @notice 3 and 6 months maturities
    address[2] internal fCashPositions;
    /// @notice Timestamp of last AUM fee charge
    uint96 internal lastTransferTime;
    /// @notice Address of the feeRecipient
    address internal feeRecipient;

    /// @notice Checks if max loss is within an acceptable range
    modifier isValidMaxLoss(uint16 _maxLoss) {
        require(_maxLoss <= BP, "SavingsVault: INVALID");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc ISavingsVault
    function initialize(
        string memory _name,
        string memory _symbol,
        address _asset,
        uint16 _currencyId,
        IWrappedfCashFactory _wrappedfCashFactory,
        address _notionalRouter,
        uint16 _maxLoss,
        address _feeRecipient
    ) external initializer isValidMaxLoss(_maxLoss) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(VAULT_MANAGER_ROLE, VAULT_ADMIN_ROLE);

        __ERC4626_init(IERC20MetadataUpgradeable(_asset));
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        currencyId = _currencyId;
        wrappedfCashFactory = _wrappedfCashFactory;
        notionalRouter = _notionalRouter;
        maxLoss = _maxLoss;
        feeRecipient = _feeRecipient;
        lastTransferTime = uint96(block.timestamp);

        (NotionalMarket memory lowestYieldMarket, NotionalMarket memory highestYieldMarket) = sortMarketsByOracleRate();

        address lowestYieldFCash = _wrappedfCashFactory.deployWrapper(_currencyId, uint40(lowestYieldMarket.maturity));
        address highestYieldFCash = _wrappedfCashFactory.deployWrapper(
            _currencyId,
            uint40(highestYieldMarket.maturity)
        );

        fCashPositions[0] = lowestYieldFCash;
        fCashPositions[1] = highestYieldFCash;
    }

    /// @inheritdoc ISavingsVaultHarvester
    function harvest(uint _maxDepositedAmount) external nonReentrant {
        _redeemAssetsIfMarketMatured();

        address _asset = asset();
        uint assetBalance = IERC20Upgradeable(_asset).balanceOf(address(this));
        if (assetBalance == 0 || _maxDepositedAmount == 0) {
            return;
        }
        uint deposited = assetBalance < _maxDepositedAmount ? assetBalance : _maxDepositedAmount;

        (NotionalMarket memory lowestYieldMarket, NotionalMarket memory highestYieldMarket) = sortMarketsByOracleRate();

        IWrappedfCashFactory _wrappedfCashFactory = wrappedfCashFactory;
        uint16 _currencyId = currencyId;
        address lowestYieldfCash = _wrappedfCashFactory.deployWrapper(_currencyId, uint40(lowestYieldMarket.maturity));
        address highestYieldfCash = _wrappedfCashFactory.deployWrapper(
            _currencyId,
            uint40(highestYieldMarket.maturity)
        );
        // Storing latest active fCash positions in the cache so during the withdrawal/totalAssets we know which positions the vault has.
        _sortfCashPositions(lowestYieldfCash, highestYieldfCash);

        uint fCashAmount = IWrappedfCashComplete(highestYieldfCash).previewDeposit(deposited);

        IERC20Upgradeable(_asset).safeApprove(highestYieldfCash, deposited);
        IWrappedfCashComplete(highestYieldfCash).mintViaUnderlying(
            deposited,
            TypeConversionLibrary._safeUint88(fCashAmount),
            address(this),
            TypeConversionLibrary._safeUint32((highestYieldMarket.oracleRate * maxLoss) / BP)
        );
        IERC20Upgradeable(_asset).safeApprove(highestYieldfCash, 0);
        emit FCashMinted(IWrappedfCashComplete(highestYieldfCash), deposited, fCashAmount);
    }

    /// @inheritdoc ISavingsVault
    function setMaxLoss(uint16 _maxLoss) external onlyRole(VAULT_MANAGER_ROLE) isValidMaxLoss(_maxLoss) {
        maxLoss = _maxLoss;
    }

    /// @inheritdoc ISavingsVault
    function setFeeRecipient(address _feeRecipient) external onlyRole(VAULT_MANAGER_ROLE) {
        feeRecipient = _feeRecipient;
    }

    /// @inheritdoc ISavingsVaultViewer
    function getfCashPositions() external view returns (address[2] memory) {
        return fCashPositions;
    }

    /// @inheritdoc IERC4626Upgradeable
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) public override returns (uint256) {
        require(_assets <= maxWithdraw(_owner), "SavingsVault: MAX");
        // determine the amount of shares for the assets without the fees
        uint shares = _convertToShares(_assets, MathUpgradeable.Rounding.Up);
        // determine the burning fee on top of the estimated shares for withdrawing the exact asset output
        // cannot use the previewWithdraw since it already accounts for the burning fee
        uint fee = (shares * BURNING_FEE_IN_BP) / BP;
        if (fee != 0) {
            // AUM charged inside _transfer
            // Transfer the shares which account for the fee to the feeRecipient
            _transfer(_owner, feeRecipient, fee);
        } else {
            _chargeAUMFee();
        }
        // shares accounting for the fees are not burned since they are transferred to the feeRecipient
        uint assetsWithdrawn = _beforeWithdraw(_assets);
        _withdraw(msg.sender, _receiver, _owner, assetsWithdrawn, shares);
        // returns the shares plus fee
        return shares + fee;
    }

    /// @inheritdoc IERC4626Upgradeable
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) public override returns (uint256) {
        return redeemWithMinOutputAmount(_shares, _receiver, _owner, 0);
    }

    /// @inheritdoc ISavingsVault
    function redeemWithMinOutputAmount(
        uint256 _shares,
        address _receiver,
        address _owner,
        uint _minOutputAmount
    ) public returns (uint256) {
        require(_shares <= maxRedeem(_owner), "SavingsVault: MAX");
        // input shares equal to _shares = sharesToBurn + sharesToBurn * burning_fee.
        // By solving the equation for sharesToBurn we can calculate the fee by subtracting sharesToBurn from the input _shares
        uint sharesToBurn = (_shares * BP) / (BP + BURNING_FEE_IN_BP);
        uint fee = _shares - sharesToBurn;
        // converts sharesToBurn to assets which are transferred to the user
        uint assets = convertToAssets(sharesToBurn);
        if (fee != 0) {
            // AUM charged inside _transfer
            // Transfer the shares which account for the fee to the feeRecipient
            _transfer(_owner, feeRecipient, fee);
        } else {
            _chargeAUMFee();
        }
        uint assetsWithdrawn = _beforeWithdraw(assets);
        require(assetsWithdrawn >= _minOutputAmount, "SavingsVault: MIN_OUTPUT");
        _withdraw(msg.sender, _receiver, _owner, assetsWithdrawn, sharesToBurn);

        return assetsWithdrawn;
    }

    /// @inheritdoc ERC4626Upgradeable
    function mint(uint256 _shares, address receiver) public override returns (uint256) {
        require(_shares <= maxMint(receiver), "SavingsVault: MAX");

        uint256 assets = _convertToAssets(_shares, MathUpgradeable.Rounding.Up);

        uint fee = (_shares * MINTING_FEE_IN_BP) / BP;
        uint feeInAssets = convertToAssets(fee);
        _chargeAUMFee();
        if (fee != 0) {
            _mint(feeRecipient, fee);
        }
        // we need to mint exact number of shares
        _deposit(msg.sender, receiver, assets + feeInAssets, _shares);

        return assets + feeInAssets;
    }

    /// @inheritdoc ERC4626Upgradeable
    function deposit(uint256 _assets, address _receiver) public override returns (uint256) {
        require(_assets <= maxDeposit(_receiver), "SavingsVault: MAX");
        // calculate the shares to mint
        uint shares = convertToShares(_assets);
        uint fee = (shares * MINTING_FEE_IN_BP) / (BP + MINTING_FEE_IN_BP);
        // charge the actual fees
        _chargeAUMFee();
        if (fee != 0) {
            _mint(feeRecipient, fee);
        }
        _deposit(msg.sender, _receiver, _assets, shares - fee);
        return shares - fee;
    }

    /// @inheritdoc ISavingsVault
    function depositWithPermit(
        uint _assets,
        address _receiver,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public override returns (uint) {
        ERC20PermitUpgradeable(asset()).permit(msg.sender, address(this), _assets, _deadline, _v, _r, _s);
        return deposit(_assets, _receiver);
    }

    /// @inheritdoc IERC4626Upgradeable
    function previewWithdraw(uint256 _assets) public view override returns (uint256) {
        uint shares = super.previewWithdraw(_assets);
        uint burningFee = (shares * BURNING_FEE_IN_BP) / BP;
        // To withdraw asset amount on top of needed shares burning fee is added
        return shares + burningFee;
    }

    /// @inheritdoc IERC4626Upgradeable
    function previewRedeem(uint256 _shares) public view override returns (uint256) {
        // amount of assets received is reduced by the fee amount
        uint assets = convertToAssets((_shares * BP) / (BP + BURNING_FEE_IN_BP));
        return _previewRedeemFromMaturities(assets);
    }

    /// @inheritdoc ERC4626Upgradeable
    function previewMint(uint256 _shares) public view override returns (uint256) {
        // While minting exact amount of shares user needs to transfer asset plus fees on top of those assets
        return super.previewMint(_shares + (_shares * MINTING_FEE_IN_BP) / BP);
    }

    /// @inheritdoc ERC4626Upgradeable
    function previewDeposit(uint256 _assets) public view override returns (uint256) {
        uint shares = super.previewDeposit(_assets);
        uint fee = (shares * MINTING_FEE_IN_BP) / (BP + MINTING_FEE_IN_BP);
        // While depositing exact amount of assets user receives shares minus fee payed on that amount
        return shares - fee;
    }

    /// @inheritdoc IERC4626Upgradeable
    function maxWithdraw(address _owner) public view virtual override returns (uint256) {
        // max withdraw asset amount is equal to shares / 1 + burning_fee
        return convertToAssets((balanceOf(_owner) * BP) / (BP + BURNING_FEE_IN_BP));
    }

    /// @inheritdoc IERC4626Upgradeable
    function totalAssets() public view override returns (uint) {
        uint assetBalance = IERC20Upgradeable(asset()).balanceOf(address(this));
        for (uint i = 0; i < SUPPORTED_MATURITIES; i++) {
            IWrappedfCashComplete fCashPosition = IWrappedfCashComplete(fCashPositions[i]);
            uint fCashBalance = fCashPosition.balanceOf(address(this));
            if (fCashBalance != 0) {
                assetBalance += fCashPosition.convertToAssets(fCashBalance);
            }
        }
        return assetBalance;
    }

    /// @inheritdoc ISavingsVaultHarvester
    function sortMarketsByOracleRate()
        public
        view
        returns (NotionalMarket memory lowestYieldMarket, NotionalMarket memory highestYieldMarket)
    {
        NotionalMarket[] memory notionalMarkets = _getThreeAndSixMonthMarkets();
        uint market0OracleRate = notionalMarkets[0].oracleRate;
        uint market1OracleRate = notionalMarkets[1].oracleRate;
        if (market0OracleRate < market1OracleRate) {
            lowestYieldMarket = notionalMarkets[0];
            highestYieldMarket = notionalMarkets[1];
        } else {
            lowestYieldMarket = notionalMarkets[1];
            highestYieldMarket = notionalMarkets[0];
        }
    }

    /// @dev Overrides _transfer to include AUM fee logic
    /// @inheritdoc ERC20Upgradeable
    function _transfer(
        address _from,
        address _to,
        uint _amount
    ) internal override {
        _chargeAUMFee();
        super._transfer(_from, _to, _amount);
    }

    /// @notice Loops through fCash positions and redeems into asset if position has matured
    function _redeemAssetsIfMarketMatured() internal {
        for (uint i = 0; i < SUPPORTED_MATURITIES; i++) {
            IWrappedfCashComplete fCashPosition = IWrappedfCashComplete(fCashPositions[i]);
            if (fCashPosition.hasMatured()) {
                uint fCashAmount = fCashPosition.balanceOf(address(this));
                if (fCashAmount != 0) {
                    fCashPosition.redeemToUnderlying(fCashAmount, address(this), type(uint32).max);
                }
            }
        }
    }

    /// @notice Sorts fCash positions in case there was a change with respect to the previous state
    function _sortfCashPositions(address _lowestYieldfCash, address _highestYieldfCash) internal {
        if (
            keccak256(abi.encodePacked(fCashPositions[0], fCashPositions[1])) !=
            keccak256(abi.encodePacked(_lowestYieldfCash, _highestYieldfCash))
        ) {
            fCashPositions[0] = _lowestYieldfCash;
            fCashPositions[1] = _highestYieldfCash;
        }
    }

    /// @notice Calculates and mints AUM fee to feeRecipient
    function _chargeAUMFee() internal {
        uint timePassed = uint96(block.timestamp) - lastTransferTime;
        if (timePassed != 0) {
            address _feeRecipient = feeRecipient;
            uint fee = ((totalSupply() - balanceOf(_feeRecipient)) *
                (AUMCalculationLibrary.rpow(
                    AUM_SCALED_PER_SECONDS_RATE,
                    timePassed,
                    AUMCalculationLibrary.RATE_SCALE_BASE
                ) - AUMCalculationLibrary.RATE_SCALE_BASE)) / AUMCalculationLibrary.RATE_SCALE_BASE;
            if (fee != 0) {
                _mint(_feeRecipient, fee);
                lastTransferTime = uint96(block.timestamp);
            }
        }
    }

    /// @notice Withdraws asset from maturities
    /// @param _assets Amount of assets for withdrawal
    function _beforeWithdraw(uint _assets) internal nonReentrant returns (uint) {
        IERC20MetadataUpgradeable _asset = IERC20MetadataUpgradeable(asset());
        uint assetBalance = _asset.balanceOf(address(this));
        // There is enough assets in the vault, no need to withdraw from fCash positions
        if (assetBalance >= _assets) {
            return _assets;
        }
        // Otherwise the amount of assets to withdraw is the difference between the amount of assets in the vault and the amount of assets to withdraw from maturities
        uint totalWithdrawn = assetBalance;
        FCashProperties[2] memory sortedfCashPositions = _sortStoredfCashPositions();
        for (uint i; i < sortedfCashPositions.length; ++i) {
            uint cashToWithdraw = _assets - totalWithdrawn;
            if (cashToWithdraw == 0) {
                break;
            }
            FCashProperties memory fCashPosition = sortedfCashPositions[i];
            IWrappedfCashComplete fCash = IWrappedfCashComplete(fCashPosition.wrappedfCash);
            uint totalfCashAmount = fCash.balanceOf(address(this));
            if (totalfCashAmount == 0) {
                continue;
            }
            uint totalCashAmount = fCash.convertToAssets(totalfCashAmount);
            if (totalCashAmount == 0) {
                continue;
            }
            uint cashAmount = Math.min(totalCashAmount, cashToWithdraw);
            uint fCashAmount = (cashAmount * totalfCashAmount) / totalCashAmount;
            if (fCashAmount > 0) {
                fCash.redeemToUnderlying(fCashAmount, address(this), type(uint32).max);
            }
            totalWithdrawn += cashAmount;
        }
        return _asset.balanceOf(address(this));
    }

    /// @notice Preview withdrawal of assets from maturities
    /// @param _assets Amount of assets for withdrawal
    function _previewRedeemFromMaturities(uint _assets) internal view returns (uint) {
        IERC20MetadataUpgradeable _asset = IERC20MetadataUpgradeable(asset());
        uint assetBalance = _asset.balanceOf(address(this));
        // There is enough assets in the vault, no need to withdraw from fCash positions
        if (assetBalance >= _assets) {
            return _assets;
        }
        // Otherwise the amount of assets to withdraw is the difference between the amount of assets in the vault and the amount of assets to withdraw from maturities.
        // We track the actual amount received with previewRedeem to account for price impact/slippage
        uint totalWithdrawn = assetBalance;
        uint totalRedeemed = assetBalance;
        FCashProperties[2] memory sortedfCashPositions = _sortStoredfCashPositions();
        for (uint i; i < sortedfCashPositions.length; ++i) {
            uint cashToWithdraw = _assets - totalWithdrawn;
            if (cashToWithdraw == 0) {
                break;
            }
            FCashProperties memory fCashPosition = sortedfCashPositions[i];
            IWrappedfCashComplete fCash = IWrappedfCashComplete(fCashPosition.wrappedfCash);
            uint totalfCashAmount = fCash.balanceOf(address(this));
            if (totalfCashAmount == 0) {
                continue;
            }
            uint totalCashAmount = fCash.convertToAssets(totalfCashAmount);
            if (totalCashAmount == 0) {
                continue;
            }
            uint cashAmount = Math.min(totalCashAmount, cashToWithdraw);
            uint fCashAmount = (cashAmount * totalfCashAmount) / totalCashAmount;
            if (fCashAmount > 0) {
                totalRedeemed += fCash.previewRedeem(fCashAmount);
            }
            totalWithdrawn += cashAmount;
        }
        return totalRedeemed;
    }

    /// @notice Sorts stored fCash positions in order: matured, lowestYield, highestYield
    function _sortStoredfCashPositions() internal view returns (FCashProperties[2] memory sorted) {
        address _firstfCashPosition = fCashPositions[0];
        address _secondfCashPosition = fCashPositions[1];
        // If one of the fCash positions has matured in between harvesting/withdrawal it means that the other one has rolled and became a 3 month maturity.
        // We can set max value for oracleRate for the matured fCash since it doesn't matter during redemption.
        // first position is matured redeem from it first.
        if (IWrappedfCashComplete(_firstfCashPosition).hasMatured()) {
            sorted[0] = FCashProperties({ wrappedfCash: _firstfCashPosition, oracleRate: type(uint32).max });
            MarketParameters memory threeMonthfCash = _getNotionalMarketParameters(_secondfCashPosition);
            sorted[1] = FCashProperties({
                wrappedfCash: _secondfCashPosition,
                oracleRate: TypeConversionLibrary._safeUint32(threeMonthfCash.oracleRate)
            });
            // second position is matured redeem from it first
        } else if (IWrappedfCashComplete(_secondfCashPosition).hasMatured()) {
            sorted[0] = FCashProperties({ wrappedfCash: _secondfCashPosition, oracleRate: type(uint32).max });
            MarketParameters memory threeMonthfCash = _getNotionalMarketParameters(_firstfCashPosition);
            sorted[1] = FCashProperties({
                wrappedfCash: _firstfCashPosition,
                oracleRate: TypeConversionLibrary._safeUint32(threeMonthfCash.oracleRate)
            });
            // both positions are still active, we need to fetch the oracle rates and compare it again
        } else {
            (
                NotionalMarket memory lowestYieldMarket,
                NotionalMarket memory highestYieldMarket
            ) = sortMarketsByOracleRate();
            uint16 _currencyId = currencyId;
            IWrappedfCashFactory _wrappedfCashFactory = wrappedfCashFactory;
            address lowestYieldfCash = _wrappedfCashFactory.computeAddress(
                _currencyId,
                uint40(lowestYieldMarket.maturity)
            );
            address highestYieldfCash = _wrappedfCashFactory.computeAddress(
                _currencyId,
                uint40(highestYieldMarket.maturity)
            );
            sorted[0] = FCashProperties({
                wrappedfCash: lowestYieldfCash,
                oracleRate: TypeConversionLibrary._safeUint32(lowestYieldMarket.oracleRate)
            });
            sorted[1] = FCashProperties({
                wrappedfCash: highestYieldfCash,
                oracleRate: TypeConversionLibrary._safeUint32(highestYieldMarket.oracleRate)
            });
        }
        return sorted;
    }

    /// @notice Fetches market parameters from Notional
    /// @param _fCash to fetch market parameters
    function _getNotionalMarketParameters(address _fCash)
        internal
        view
        returns (MarketParameters memory marketParameters)
    {
        uint256 settlementDate = DateTime.getReferenceTime(block.timestamp) + Constants.QUARTER;
        marketParameters = NotionalViews(notionalRouter).getMarket(
            currencyId,
            IWrappedfCashComplete(_fCash).getMaturity(),
            settlementDate
        );
    }

    /// @notice Gets the three and six months markets from Notional
    function _getThreeAndSixMonthMarkets() internal view returns (NotionalMarket[] memory) {
        NotionalMarket[] memory markets = new NotionalMarket[](SUPPORTED_MATURITIES);
        MarketParameters[] memory marketParameters = NotionalViews(notionalRouter).getActiveMarkets(currencyId);
        uint marketCount;
        for (uint i = 0; i < marketParameters.length; i++) {
            MarketParameters memory parameters = marketParameters[i];
            if (parameters.maturity >= block.timestamp + 2 * Constants.QUARTER) {
                // it's not 3 or 6 months maturity check the next one
                continue;
            }
            markets[marketCount] = (
                NotionalMarket({ maturity: parameters.maturity, oracleRate: parameters.oracleRate })
            );
            marketCount++;
        }
        require(marketCount == SUPPORTED_MATURITIES, "SavingsVault: NOTIONAL_MARKETS");
        return markets;
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address _newImpl) internal view virtual override onlyRole(VAULT_MANAGER_ROLE) {}

    uint256[45] private __gap;
}