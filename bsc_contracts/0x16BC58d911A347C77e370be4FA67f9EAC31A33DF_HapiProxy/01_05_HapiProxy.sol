// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract HapiProxy is OwnableUpgradeable {
    enum Category {
        None,
        // Wallet service - custodial or mixed wallets
        WalletService,
        // Merchant service
        MerchantService,
        // Mining pool
        MiningPool,
        // Exchange with high KYC standards
        Exchange,
        // DeFi application
        DeFi,
        // OTC Broker
        OTCBroker,
        // Cryptocurrency ATM
        ATM,
        // Gambling
        Gambling,
        // Illicit organization
        IllicitOrganization,
        // Mixer
        Mixer,
        // Darknet market or service
        DarknetService,
        // Scam
        Scam,
        // Ransomware
        Ransomware,
        // Theft - stolen funds
        Theft,
        // Counterfeit - fake assets
        Counterfeit,
        // Terrorist financing
        TerroristFinancing,
        // Sanctions
        Sanctions,
        // Child abuse and porn materials
        ChildAbuse
    }

    struct AddressInfo {
        Category category;
        uint8 risk;
    }

    uint8 private constant _MAX_RISK = 10;

    mapping(address => uint8) private _reporters;
    mapping(address => AddressInfo) private _addresses;

    event CreateReporter(address reporterAddress_, uint8 permissionLevel_);
    event UpdateReporter(address reporterAddress_, uint8 permissionLevel_);
    event CreateAddress(address address_, Category category_, uint8 risk_);
    event UpdateAddress(address address_, Category category_, uint8 risk_);

    function initialize() public initializer {
        __Ownable_init();
    }

    modifier minReporterLevel1() {
        require(_reporters[msg.sender] >= 1, 'HapiProxy: Reporter permission level is less than 1');
        _;
    }

    modifier minReporterLevel2() {
        require(_reporters[msg.sender] >= 2, 'HapiProxy: Reporter permission level is less than 2');
        _;
    }

    function createReporter(address reporterAddress_, uint8 permissionLevel_)
        external
        onlyOwner
        returns (bool success)
    {
        require(reporterAddress_ != address(0), 'HapiProxy: Invalid address');
        require(permissionLevel_ > 0 && permissionLevel_ <= 2, 'HapiProxy: Invalid permission level');
        require(_reporters[reporterAddress_] == 0, 'HapiProxy: Reporter already exists');

        _reporters[reporterAddress_] = permissionLevel_;

        emit CreateReporter(reporterAddress_, permissionLevel_);
        return true;
    }

    function updateReporter(address reporterAddress_, uint8 permissionLevel_)
        external
        onlyOwner
        returns (bool success)
    {
        require(reporterAddress_ != address(0), 'HapiProxy: Invalid address');
        require(permissionLevel_ > 0 && permissionLevel_ <= 2, 'HapiProxy: Invalid permission level');
        require(_reporters[reporterAddress_] != 0, 'HapiProxy: Reporter does not exist');
        require(_reporters[reporterAddress_] != permissionLevel_, 'HapiProxy: Invalid params');

        _reporters[reporterAddress_] = permissionLevel_;

        emit UpdateReporter(reporterAddress_, permissionLevel_);
        return true;
    }

    function createAddress(
        address address_,
        Category category_,
        uint8 risk_
    ) external minReporterLevel1 returns (bool success) {
        require(address_ != address(0), 'HapiProxy: Invalid address');
        require(risk_ <= _MAX_RISK, 'HapiProxy: Invalid risk');

        AddressInfo storage _address = _addresses[address_];
        require(_address.category == Category.None, 'HapiProxy: Address already exists');

        _address.category = category_;
        _address.risk = risk_;

        emit CreateAddress(address_, category_, risk_);
        return true;
    }

    function createAddresses(
        address[] memory addresses_,
        Category category_,
        uint8 risk_
    ) external minReporterLevel1 returns (bool success) {
        require(risk_ <= _MAX_RISK, 'HapiProxy: Invalid risk');

        uint256 n = addresses_.length;
        for (uint256 i = 0; i < n; i++) {
            address address_ = addresses_[i];
            require(address_ != address(0), 'HapiProxy: Invalid address');

            AddressInfo storage _address = _addresses[address_];
            require(_address.category == Category.None, 'HapiProxy: Address already exists');

            _address.category = category_;
            _address.risk = risk_;

            emit CreateAddress(address_, category_, risk_);
        }
        return true;
    }

    function updateAddress(
        address address_,
        Category category_,
        uint8 risk_
    ) external minReporterLevel2 returns (bool success) {
        require(address_ != address(0), 'HapiProxy: Invalid address');
        require(risk_ <= _MAX_RISK, 'HapiProxy: Invalid risk');

        AddressInfo storage _address = _addresses[address_];
        require(_address.category != Category.None, 'HapiProxy: Address does not exist');
        require(_address.category != category_ || _address.risk != risk_, 'HapiProxy: Invalid params');

        _address.category = category_;
        _address.risk = risk_;

        emit UpdateAddress(address_, category_, risk_);
        return true;
    }

    function getAddress(address address_) external view returns (Category category, uint8 risk) {
        AddressInfo storage _addressInfo = _addresses[address_];
        return (_addressInfo.category, _addressInfo.risk);
    }

    function getReporter(address reporterAddress_) external view returns (uint8 permissionLevel) {
        return _reporters[reporterAddress_];
    }
}