// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';

import '../interfaces/IACLManager.sol';
import './interfaces/IOpenSkyBespokeSettings.sol';
import './libraries/BespokeTypes.sol';

contract OpenSkyBespokeSettings is Ownable, IOpenSkyBespokeSettings {
    uint256 public constant MAX_RESERVE_FACTOR = 3000;

    address public immutable ACLManagerAddress;

    // nft whitelist
    bool public override isWhitelistOn = false;
    // nftAddress=>data
    mapping(address => BespokeTypes.WhitelistInfo) internal _whitelist;

    // currency whitelist
    mapping(address => bool) public _currencyWhitelist;

    // one-time initialization
    address public override marketAddress;
    address public override borrowLoanAddress;
    address public override lendLoanAddress;

    // governance factors
    uint256 public override reserveFactor = 2000;
    uint256 public override overdueLoanFeeFactor = 100;

    uint256 public override minBorrowDuration = 30 minutes;
    uint256 public override maxBorrowDuration = 60 days;
    uint256 public override overdueDuration = 2 days;

    modifier onlyGovernance() {
        IACLManager ACLManager = IACLManager(ACLManagerAddress);
        require(ACLManager.isGovernance(_msgSender()), 'BM_ACL_ONLY_GOVERNANCE_CAN_CALL');
        _;
    }
    modifier onlyWhenNotInitialized(address address_) {
        require(address_ == address(0));
        _;
    }

    constructor(address _ACLManagerAddress) Ownable() {
        ACLManagerAddress = _ACLManagerAddress;
    }

    // OpenSkyBespokeMarket address
    function initMarketAddress(address address_) external onlyOwner onlyWhenNotInitialized(marketAddress) {
        require(address_ != address(0));
        marketAddress = address_;
        emit InitMarketAddress(msg.sender, address_);
    }

    function initLoanAddress(address borrowLoanAddress_, address lendLoanAddress_)
        external
        onlyOwner
        onlyWhenNotInitialized(borrowLoanAddress)
        onlyWhenNotInitialized(lendLoanAddress)
    {
        require(borrowLoanAddress_ != address(0) && lendLoanAddress_ != address(0));
        borrowLoanAddress = borrowLoanAddress_;
        lendLoanAddress = lendLoanAddress_;
        emit InitLoanAddress(msg.sender, borrowLoanAddress_, lendLoanAddress_);
    }
    
    function setMinBorrowDuration(uint256 factor) external onlyGovernance {
        require(minBorrowDuration > 0);
        minBorrowDuration = factor;
        emit SetMinBorrowDuration(msg.sender, factor);
    }

    function setMaxBorrowDuration(uint256 factor) external onlyGovernance {
        require(maxBorrowDuration > 0);
        maxBorrowDuration = factor;
        emit SetMaxBorrowDuration(msg.sender, factor);
    }

    function setOverdueDuration(uint256 factor) external onlyGovernance {
        overdueDuration = factor;
        emit SetOverdueDuration(msg.sender, factor);
    }

    function setReserveFactor(uint256 factor) external onlyGovernance {
        require(factor <= MAX_RESERVE_FACTOR);
        reserveFactor = factor;
        emit SetReserveFactor(msg.sender, factor);
    }

    function setOverdueLoanFeeFactor(uint256 factor) external onlyGovernance {
        overdueLoanFeeFactor = factor;
        emit SetOverdueLoanFeeFactor(msg.sender, factor);
    }

    function openWhitelist() external onlyGovernance {
        isWhitelistOn = true;
        emit OpenWhitelist(msg.sender);
    }

    function closeWhitelist() external onlyGovernance {
        isWhitelistOn = false;
        emit CloseWhitelist(msg.sender);
    }

    function addToWhitelist(
        address nft,
        uint256 minBorrowDuration,
        uint256 maxBorrowDuration,
        uint256 overdueDuration
    ) external onlyGovernance {
        require(nft != address(0));
        require(minBorrowDuration <= maxBorrowDuration);
        _whitelist[nft] = BespokeTypes.WhitelistInfo({
            enabled: true,
            minBorrowDuration: minBorrowDuration,
            maxBorrowDuration: maxBorrowDuration,
            overdueDuration: overdueDuration
        });
        emit AddToWhitelist(msg.sender, nft);
    }

    function removeFromWhitelist(address nft) external onlyGovernance {
        if (_whitelist[nft].enabled) {
            _whitelist[nft].enabled = false;
            emit RemoveFromWhitelist(msg.sender, nft);
        }
    }

    function inWhitelist(address nft) public view override returns (bool) {
        require(nft != address(0));
        return !isWhitelistOn || _whitelist[nft].enabled;
    }

    function getWhitelistDetail(address nft) public view override returns (BespokeTypes.WhitelistInfo memory) {
        return _whitelist[nft];
    }

    function getBorrowDurationConfig(address nftAddress)
        public
        view
        override
        returns (
            uint256 minBorrowDuration_,
            uint256 maxBorrowDuration_,
            uint256 overdueDuration_
        )
    {
        if (isWhitelistOn && inWhitelist(nftAddress)) {
            BespokeTypes.WhitelistInfo memory info = getWhitelistDetail(nftAddress);
            minBorrowDuration_ = info.minBorrowDuration;
            maxBorrowDuration_ = info.maxBorrowDuration;
            overdueDuration_ = info.overdueDuration;
        } else {
            minBorrowDuration_ = minBorrowDuration;
            maxBorrowDuration_ = maxBorrowDuration;
            overdueDuration_ = overdueDuration;
        }
    }

    // currency whitelist
    function addCurrency(address currency) external onlyGovernance {
        require(currency != address(0));
        if (_currencyWhitelist[currency] != true) {
            _currencyWhitelist[currency] = true;
        }
        emit AddCurrency(msg.sender, currency);
    }

    function removeCurrency(address currency) external onlyGovernance {
        require(currency != address(0));
        delete _currencyWhitelist[currency];
        emit RemoveCurrency(msg.sender, currency);
    }

    function isCurrencyWhitelisted(address currency) external view override returns (bool) {
        return _currencyWhitelist[currency];
    }
}