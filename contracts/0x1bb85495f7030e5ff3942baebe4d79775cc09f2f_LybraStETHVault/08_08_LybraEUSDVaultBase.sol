// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "../../interfaces/IEUSD.sol";
import "../../interfaces/Iconfigurator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPriceFeed {
    function fetchPrice() external returns (uint256);
}

abstract contract LybraEUSDVaultBase {
    using SafeERC20 for IERC20;
    IEUSD public immutable EUSD;
    IERC20 public immutable collateralAsset;
    Iconfigurator public immutable configurator;
    uint256 public constant badCollateralRatio = 150 * 1e18;
    IPriceFeed immutable etherOracle;

    uint256 public totalDepositedAsset;
    uint256 public lastReportTime;
    uint256 poolTotalCirculation;

    mapping(address => uint256) public depositedAsset;
    mapping(address => uint256) borrowed;
    uint256 public feeStored;
    mapping(address => uint256) depositedTime;

    event DepositEther(address indexed onBehalfOf, address asset, uint256 etherAmount, uint256 assetAmount, uint256 timestamp);

    event DepositAsset(address indexed onBehalfOf, address asset, uint256 amount, uint256 timestamp);

    event WithdrawAsset(address indexed sponsor, address asset, address indexed onBehalfOf, uint256 amount, uint256 timestamp);
    event Mint(address indexed sponsor, address indexed onBehalfOf, uint256 amount, uint256 timestamp);
    event Burn(address indexed sponsor, address indexed onBehalfOf, uint256 amount, uint256 timestamp);
    event LiquidationRecord(address indexed provider, address indexed keeper, address indexed onBehalfOf, uint256 eusdamount, uint256 liquidateEtherAmount, uint256 keeperReward, bool superLiquidation, uint256 timestamp);
    event LSDValueCaptured(uint256 stETHAdded, uint256 payoutEUSD, uint256 discountRate, uint256 timestamp);
    event RigidRedemption(address indexed caller, address indexed provider, uint256 eusdAmount, uint256 collateralAmount, uint256 timestamp);
    event FeeDistribution(address indexed feeAddress, uint256 feeAmount, uint256 timestamp);

    //etherOracle = 0x4c517D4e2C851CA76d7eC94B805269Df0f2201De
    constructor(address _collateralAsset, address _etherOracle, address _configurator) {
        collateralAsset = IERC20(_collateralAsset);
        configurator = Iconfigurator(_configurator);
        EUSD = IEUSD(configurator.getEUSDAddress());
        etherOracle = IPriceFeed(_etherOracle);
    }

    /**
     * @notice Allowing direct deposits of ETH, the pool may convert it into the corresponding collateral during the implementation.
     * While depositing, it is possible to simultaneously mint eUSD for oneself.
     * Emits a `DepositEther` event.
     *
     * Requirements:
     * - `mintAmount` Send 0 if doesn't mint eUSD
     * - msg.value Must be higher than 0.
     */
    function depositEtherToMint(uint256 mintAmount) external payable virtual;

    /**
     * @notice Deposit collateral and allow minting eUSD for oneself.
     * Emits a `DepositAsset` event.
     *
     * Requirements:
     * - `assetAmount` Must be higher than 1e18.
     * - `mintAmount` Send 0 if doesn't mint eUSD
     */
    function depositAssetToMint(uint256 assetAmount, uint256 mintAmount) external virtual {
        require(assetAmount >= 1 ether, "Deposit should not be less than 1 stETH.");
        collateralAsset.safeTransferFrom(msg.sender, address(this), assetAmount);
        totalDepositedAsset += assetAmount;
        depositedAsset[msg.sender] += assetAmount;
        depositedTime[msg.sender] = block.timestamp;

        if (mintAmount > 0) {
            _mintEUSD(msg.sender, msg.sender, mintAmount, getAssetPrice());
        }
        emit DepositAsset(msg.sender, address(collateralAsset), assetAmount, block.timestamp);
    }

    /**
     * @notice Withdraw collateral assets to an address
     * Emits a `WithdrawEther` event.
     *
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `amount` Must be higher than 0.
     *
     * @dev Withdraw stETH. Check user’s collateral ratio after withdrawal, should be higher than `safeCollateralRatio`
     */
    function withdraw(address onBehalfOf, uint256 amount) external virtual {
        require(onBehalfOf != address(0), "TZA");
        require(amount != 0, "ZERO_WITHDRAW");
        require(depositedAsset[msg.sender] >= amount, "Withdraw amount exceeds deposited amount.");
        totalDepositedAsset -= amount;
        depositedAsset[msg.sender] -= amount;

        uint256 withdrawal = checkWithdrawal(msg.sender, amount);

        collateralAsset.safeTransfer(onBehalfOf, withdrawal);
        if (borrowed[msg.sender] > 0) {
            _checkHealth(msg.sender, getAssetPrice());
        }
        emit WithdrawAsset(msg.sender, address(collateralAsset), onBehalfOf, withdrawal, block.timestamp);
    }

    function checkWithdrawal(address user, uint256 amount) public view returns (uint256 withdrawal) {
        withdrawal = block.timestamp - 3 days >= depositedTime[user] ? amount : (amount * 999) / 1000;
    }

    /**
     * @notice The mint amount number of eUSD is minted to the address
     * Emits a `Mint` event.
     *
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     */
    function mint(address onBehalfOf, uint256 amount) external {
        require(onBehalfOf != address(0), "MINT_TO_THE_ZERO_ADDRESS");
        require(amount != 0, "ZERO_MINT");
        _mintEUSD(msg.sender, onBehalfOf, amount, getAssetPrice());
    }

    /**
     * @notice Burn the amount of eUSD and payback the amount of minted eUSD
     * Emits a `Burn` event.
     * Requirements:
     * - `onBehalfOf` cannot be the zero address.
     * - `amount` Must be higher than 0.
     * @dev Calling the internal`_repay`function.
     */
    function burn(address onBehalfOf, uint256 amount) external {
        require(onBehalfOf != address(0), "BURN_TO_THE_ZERO_ADDRESS");
        _repay(msg.sender, onBehalfOf, amount);
    }

    /**
     * @notice Keeper liquidates borrowers whose collateral ratio is below badCollateralRatio, using eUSD provided by Liquidation Provider.
     *
     * Requirements:
     * - onBehalfOf Collateral Ratio should be below badCollateralRatio
     * - collateralAmount should be less than 50% of collateral
     * - provider should authorize Lybra to utilize eUSD
     * @dev After liquidation, borrower's debt is reduced by collateralAmount * etherPrice, providers and keepers can receive up to an additional 10% liquidation reward. 
     */
    function liquidation(address provider, address onBehalfOf, uint256 assetAmount) external virtual {
        uint256 assetPrice = getAssetPrice();
        uint256 onBehalfOfCollateralRatio = (depositedAsset[onBehalfOf] * assetPrice * 100) / borrowed[onBehalfOf];
        require(onBehalfOfCollateralRatio < badCollateralRatio, "Borrowers collateral ratio should below badCollateralRatio");

        require(assetAmount * 2 <= depositedAsset[onBehalfOf], "a max of 50% collateral can be liquidated");
        require(EUSD.allowance(provider, address(this)) != 0 || msg.sender == provider, "provider should authorize to provide liquidation eUSD");
        uint256 eusdAmount = (assetAmount * assetPrice) / 1e18;

        _repay(provider, onBehalfOf, eusdAmount);
        uint256 reducedAsset = assetAmount;

        if(onBehalfOfCollateralRatio > 1e20 && onBehalfOfCollateralRatio < 11e19) {
            reducedAsset = assetAmount * onBehalfOfCollateralRatio / 1e20;
        }
        if(onBehalfOfCollateralRatio >= 11e19) {
            reducedAsset = assetAmount * 11 / 10;
        }
        totalDepositedAsset -= reducedAsset;
        depositedAsset[onBehalfOf] -= reducedAsset;

        uint256 reward2keeper;
        uint256 keeperRatio = configurator.vaultKeeperRatio(address(this));
        if (msg.sender != provider && onBehalfOfCollateralRatio >= 1e20 + keeperRatio * 1e18) {
            reward2keeper = assetAmount * keeperRatio / 100;
            collateralAsset.safeTransfer(msg.sender, reward2keeper);
        }
        collateralAsset.safeTransfer(provider, reducedAsset - reward2keeper);

        emit LiquidationRecord(provider, msg.sender, onBehalfOf, eusdAmount, reducedAsset, reward2keeper, false, block.timestamp);
    }

    /**
     * @notice When overallCollateralRatio is below badCollateralRatio, borrowers with collateralRatio below 125% could be fully liquidated.
     * Emits a `LiquidationRecord` event.
     *
     * Requirements:
     * - Current overallCollateralRatio should be below badCollateralRatio
     * - `onBehalfOf`collateralRatio should be below 125%
     * @dev After Liquidation, borrower's debt is reduced by collateralAmount * etherPrice, deposit is reduced by collateralAmount * borrower's collateralRatio. Keeper gets a liquidation reward of `keeperRatio / borrower's collateralRatio
     */
    function superLiquidation(address provider, address onBehalfOf, uint256 assetAmount) external virtual {
        uint256 assetPrice = getAssetPrice();
        require((totalDepositedAsset * assetPrice * 100) / poolTotalCirculation < badCollateralRatio, "overallCollateralRatio should below 150%");
        uint256 onBehalfOfCollateralRatio = (depositedAsset[onBehalfOf] * assetPrice * 100) / borrowed[onBehalfOf];
        require(onBehalfOfCollateralRatio < 125 * 1e18, "borrowers collateralRatio should below 125%");
        require(assetAmount <= depositedAsset[onBehalfOf], "total of collateral can be liquidated at most");
        uint256 eusdAmount = (assetAmount * assetPrice) / 1e18;
        if (onBehalfOfCollateralRatio >= 1e20) {
            eusdAmount = (eusdAmount * 1e20) / onBehalfOfCollateralRatio;
        }
        require(EUSD.allowance(provider, address(this)) != 0 || msg.sender == provider, "provider should authorize to provide liquidation eUSD");

        _repay(provider, onBehalfOf, eusdAmount);

        totalDepositedAsset -= assetAmount;
        depositedAsset[onBehalfOf] -= assetAmount;
        uint256 reward2keeper;
        if (msg.sender != provider && onBehalfOfCollateralRatio >= 1e20 + configurator.vaultKeeperRatio(address(this)) * 1e18) {
            reward2keeper = ((assetAmount * configurator.vaultKeeperRatio(address(this))) * 1e18) / onBehalfOfCollateralRatio;
            collateralAsset.safeTransfer(msg.sender, reward2keeper);
        }
        collateralAsset.safeTransfer(provider, assetAmount - reward2keeper);

        emit LiquidationRecord(provider, msg.sender, onBehalfOf, eusdAmount, assetAmount, reward2keeper, true, block.timestamp);
    }

    /**
     * @notice When stETH balance increases through LSD or other reasons, the excess income is sold for eUSD, allocated to eUSD holders through rebase mechanism.
     * Emits a `LSDistribution` event.
     *
     * *Requirements:
     * - stETH balance in the contract cannot be less than totalDepositedAsset after exchange.
     * @dev Income is used to cover accumulated Service Fee first.
     */
    function excessIncomeDistribution(uint256 payAmount) external virtual;

    /**
     * @notice Choose a Redemption Provider, Rigid Redeem `eusdAmount` of eUSD and get 1:1 value of collateral
     * Emits a `RigidRedemption` event.
     *
     * *Requirements:
     * - `provider` must be a Redemption Provider
     * - `provider`debt must equal to or above`eusdAmount`
     * @dev Service Fee for rigidRedemption `redemptionFee` is set to 0.5% by default, can be revised by DAO.
     */
    function rigidRedemption(address provider, uint256 eusdAmount, uint256 minReceiveAmount) external virtual {
        require(provider != msg.sender, "CBS");
        require(configurator.isRedemptionProvider(provider), "provider is not a RedemptionProvider");
        require(borrowed[provider] >= eusdAmount, "eusdAmount cannot surpass providers debt");
        uint256 assetPrice = getAssetPrice();
        uint256 providerCollateralRatio = (depositedAsset[provider] * assetPrice * 100) / borrowed[provider];
        require(providerCollateralRatio >= 100 * 1e18, "The provider's collateral ratio should be not less than 100%.");
        _repay(msg.sender, provider, eusdAmount);
        uint256 collateralAmount = eusdAmount * 1e18 * (10_000 - configurator.redemptionFee()) / assetPrice / 10_000;
        uint256 sendAmount = checkWithdrawal(provider, collateralAmount);
        require(sendAmount >= minReceiveAmount, "EL");
        depositedAsset[provider] -= collateralAmount;
        totalDepositedAsset -= collateralAmount;
        collateralAsset.safeTransfer(msg.sender, sendAmount);
        emit RigidRedemption(msg.sender, provider, eusdAmount, sendAmount, block.timestamp);
    }

    /**
     * @notice Mints eUSD tokens for a user.
     * @param _provider The provider's address.
     * @param _onBehalfOf The user's address.
     * @param _mintAmount The amount of eUSD tokens to be minted.
     * @param _assetPrice The current collateral asset price.
     * @dev Mints eUSD tokens for the specified user, updates the total supply and borrowed balance,
     * refreshes the mint reward for the provider, checks the health of the provider,
     * and emits a Mint event.
     * Requirements:
     * The total supply plus mint amount must not exceed the maximum supply allowed for the vault.
     * The provider must have sufficient borrowing capacity to mint the specified amount.
     */
    function _mintEUSD(address _provider, address _onBehalfOf, uint256 _mintAmount, uint256 _assetPrice) internal virtual {
        require(poolTotalCirculation + _mintAmount <= configurator.mintVaultMaxSupply(address(this)), "ESL");
        configurator.refreshMintReward(_provider);
        borrowed[_provider] += _mintAmount;

        EUSD.mint(_onBehalfOf, _mintAmount);
        _saveReport();
        poolTotalCirculation += _mintAmount;
        _checkHealth(_provider, _assetPrice);
        emit Mint(msg.sender, _onBehalfOf, _mintAmount, block.timestamp);
    }

    /**
     * @notice Burn _provideramount eUSD to payback minted eUSD for _onBehalfOf.
     *
     * @dev Refresh LBR reward before reducing providers debt. Refresh Lybra generated service fee before reducing totalEUSDCirculation.
     */
    function _repay(address _provider, address _onBehalfOf, uint256 _amount) internal virtual {
        uint256 amount = borrowed[_onBehalfOf] >= _amount ? _amount : borrowed[_onBehalfOf];

        EUSD.burn(_provider, amount);
        configurator.refreshMintReward(_onBehalfOf);

        borrowed[_onBehalfOf] -= amount;
        _saveReport();
        poolTotalCirculation -= amount;
        emit Burn(_provider, _onBehalfOf, amount, block.timestamp);
    }

    /**
     * @dev Get USD value of current collateral asset and minted eUSD through price oracle / Collateral asset USD value must higher than safe Collateral Ratio.
     */
    function _checkHealth(address _user, uint256 _assetPrice) internal view {
        if (((depositedAsset[_user] * _assetPrice * 100) / borrowed[_user]) < configurator.getSafeCollateralRatio(address(this))) revert("collateralRatio is Below safeCollateralRatio");
    }

    function _saveReport() internal {
        feeStored += _newFee();
        lastReportTime = block.timestamp;
    }

    function _newFee() internal view returns (uint256) {
        return (poolTotalCirculation * configurator.vaultMintFeeApy(address(this)) * (block.timestamp - lastReportTime)) / (86_400 * 365) / 10_000;
    }

    /**
     * @dev Return USD value of current ETH through Liquity PriceFeed Contract.
     */
    function _etherPrice() internal returns (uint256) {
        return etherOracle.fetchPrice();
    }

    function getBorrowedOf(address user) external view returns (uint256) {
        return borrowed[user];
    }

    function getPoolTotalCirculation() external view returns (uint256) {
        return poolTotalCirculation;
    }

    function getAsset() external view virtual returns (address) {
        return address(collateralAsset);
    }

    function getVaultType() external pure returns (uint8) {
        return 0;
    }

    function getAssetPrice() public virtual returns (uint256);
    function getAsset2EtherExchangeRate() external view virtual returns (uint256);
}