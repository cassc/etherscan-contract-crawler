// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IOpenSkySettings.sol';
import '../interfaces/IACLManager.sol';
import '../libraries/types/DataTypes.sol';
import '../libraries/helpers/Errors.sol';

contract OpenSkySettings is IOpenSkySettings, Ownable {
    uint256 public constant MAX_RESERVE_FACTOR = 3000;

    address public immutable ACLManagerAddress;

    // nftAddress=>data
    mapping(uint256 => mapping(address => DataTypes.WhitelistInfo)) internal _whitelist;

    // liquidator contract whitelist
    mapping(address => bool) internal _liquidators;

    // one-time initialization factors
    address public override poolAddress;
    address public override loanAddress;
    address public override vaultFactoryAddress;
    address public override incentiveControllerAddress;
    address public override wethGatewayAddress;
    address public override punkGatewayAddress;
    address public override daoVaultAddress;

    // governance factors
    address public override moneyMarketAddress;
    address public override treasuryAddress;
    address public override loanDescriptorAddress;
    address public override nftPriceOracleAddress;
    address public override interestRateStrategyAddress;

    uint256 public override reserveFactor = 2000;
    uint256 public override prepaymentFeeFactor = 0;
    uint256 public override overdueLoanFeeFactor = 100;

    constructor(address _ACLManagerAddress) Ownable() {
        ACLManagerAddress = _ACLManagerAddress;
    }

    modifier onlyGovernance() {
        IACLManager ACLManager = IACLManager(ACLManagerAddress);
        require(ACLManager.isGovernance(_msgSender()), Errors.ACL_ONLY_GOVERNANCE_CAN_CALL);
        _;
    }

    modifier onlyWhenNotInitialized(address address_) {
        require(address_ == address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        _;
    }

    function initPoolAddress(address address_) external onlyOwner onlyWhenNotInitialized(poolAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        poolAddress = address_;
        emit InitPoolAddress(msg.sender, address_);
    }

    function initLoanAddress(address address_) external onlyOwner onlyWhenNotInitialized(loanAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        loanAddress = address_;
        emit InitLoanAddress(msg.sender, address_);
    }

    function initVaultFactoryAddress(address address_) external onlyOwner onlyWhenNotInitialized(vaultFactoryAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        vaultFactoryAddress = address_;
        emit InitVaultFactoryAddress(msg.sender, address_);
    }

    function initIncentiveControllerAddress(address address_)
        external
        onlyOwner
        onlyWhenNotInitialized(incentiveControllerAddress)
    {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        incentiveControllerAddress = address_;
        emit InitIncentiveControllerAddress(msg.sender, address_);
    }

    function initWETHGatewayAddress(address address_) external onlyOwner onlyWhenNotInitialized(wethGatewayAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        wethGatewayAddress = address_;
        emit InitWETHGatewayAddress(msg.sender, address_);
    }

    function initPunkGatewayAddress(address address_) external onlyOwner onlyWhenNotInitialized(punkGatewayAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        punkGatewayAddress = address_;
        emit InitPunkGatewayAddress(msg.sender, address_);
    }

    function initDaoVaultAddress(address address_) external onlyOwner onlyWhenNotInitialized(daoVaultAddress) {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        daoVaultAddress = address_;
        emit InitDaoVaultAddress(msg.sender, address_);
    }

    // Only take effect when creating new reserve
    function setMoneyMarketAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        moneyMarketAddress = address_;
        emit SetMoneyMarketAddress(msg.sender, address_);
    }

    function setTreasuryAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        treasuryAddress = address_;
        emit SetTreasuryAddress(msg.sender, address_);
    }

    function setLoanDescriptorAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        loanDescriptorAddress = address_;
        emit SetLoanDescriptorAddress(msg.sender, address_);
    }

    function setNftPriceOracleAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        nftPriceOracleAddress = address_;
        emit SetNftPriceOracleAddress(msg.sender, address_);
    }

    function setInterestRateStrategyAddress(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        interestRateStrategyAddress = address_;
        emit SetInterestRateStrategyAddress(msg.sender, address_);
    }

    function setReserveFactor(uint256 factor) external onlyGovernance {
        require(factor <= MAX_RESERVE_FACTOR, Errors.SETTING_RESERVE_FACTOR_NOT_ALLOWED);
        reserveFactor = factor;
        emit SetReserveFactor(msg.sender, factor);
    }

    function setPrepaymentFeeFactor(uint256 factor) external onlyGovernance {
        prepaymentFeeFactor = factor;
        emit SetPrepaymentFeeFactor(msg.sender, factor);
    }

    function setOverdueLoanFeeFactor(uint256 factor) external onlyGovernance {
        overdueLoanFeeFactor = factor;
        emit SetOverdueLoanFeeFactor(msg.sender, factor);
    }

    function addToWhitelist(
        uint256 reserveId,
        address nft,
        string memory name,
        string memory symbol,
        uint256 LTV,
        uint256 minBorrowDuration,
        uint256 maxBorrowDuration,
        uint256 extendableDuration,
        uint256 overdueDuration
    ) external onlyGovernance {
        require(reserveId > 0, Errors.SETTING_WHITELIST_INVALID_RESERVE_ID);
        require(nft != address(0), Errors.SETTING_WHITELIST_NFT_ADDRESS_IS_ZERO);
        require(minBorrowDuration <= maxBorrowDuration, Errors.SETTING_WHITELIST_NFT_DURATION_OUT_OF_ORDER);
        require(bytes(name).length != 0, Errors.SETTING_WHITELIST_NFT_NAME_EMPTY);
        require(bytes(symbol).length != 0, Errors.SETTING_WHITELIST_NFT_SYMBOL_EMPTY);
        require(LTV > 0 && LTV <= 10000, Errors.SETTING_WHITELIST_NFT_LTV_NOT_ALLOWED);

        _whitelist[reserveId][nft] = DataTypes.WhitelistInfo({
            enabled: true,
            name: name,
            symbol: symbol,
            LTV: LTV,
            minBorrowDuration: minBorrowDuration,
            maxBorrowDuration: maxBorrowDuration,
            extendableDuration: extendableDuration,
            overdueDuration: overdueDuration
        });
        emit AddToWhitelist(msg.sender, reserveId, nft);
    }

    function removeFromWhitelist(uint256 reserveId, address nft) external onlyGovernance {
        if (_whitelist[reserveId][nft].enabled) {
            _whitelist[reserveId][nft].enabled = false;
            emit RemoveFromWhitelist(msg.sender, reserveId, nft);
        }
    }

    function inWhitelist(uint256 reserveId, address nft) external view override returns (bool) {
        return _whitelist[reserveId][nft].enabled;
    }

    function getWhitelistDetail(uint256 reserveId, address nft)
        external
        view
        override
        returns (DataTypes.WhitelistInfo memory)
    {
        return _whitelist[reserveId][nft];
    }

    // liquidator
    function addLiquidator(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        if (!_liquidators[address_]) {
            _liquidators[address_] = true;
            emit AddLiquidator(msg.sender, address_);
        }
    }

    function removeLiquidator(address address_) external onlyGovernance {
        require(address_ != address(0), Errors.SETTING_ZERO_ADDRESS_NOT_ALLOWED);
        if (_liquidators[address_]) {
            _liquidators[address_] = false;
            emit RemoveLiquidator(msg.sender, address_);
        }
    }

    function isLiquidator(address address_) external view override returns (bool) {
        return _liquidators[address_];
    }
}