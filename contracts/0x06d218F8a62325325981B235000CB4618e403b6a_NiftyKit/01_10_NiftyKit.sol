// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./interfaces/IBaseCollection.sol";
import "./interfaces/INiftyKit.sol";

contract NiftyKit is Initializable, OwnableUpgradeable, INiftyKit {
    struct Entry {
        uint256 value;
        bool isValue;
    }

    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 private constant _rate = 500; // parts per 10,000

    address private _treasury;
    EnumerableSetUpgradeable.AddressSet _collections;

    mapping(address => Entry) private _rateOverride;

    mapping(address => uint256) private _fees;
    mapping(address => uint256) private _feesClaimed;

    /** deprecated */
    mapping(address => Entry) private _partners;
    /** deprecated */
    mapping(address => address) private _referrals;

    /** deprecated */
    uint256 private _partnersBalance;
    /** deprecated */
    mapping(address => uint256) private _partnerFees;
    /** deprecated */
    mapping(address => uint256) private _partnerFeesClaimed;

    /** deprecated */
    address private _implementation;

    address private _dropImplementation;
    address private _tokenImplementation;

    /** deprecated */
    address private _trustedForwarder;

    function initialize(
        address dropImplementation,
        address tokenImplementation
    ) public initializer {
        __Ownable_init();
        _treasury = _msgSender();
        _dropImplementation = dropImplementation;
        _tokenImplementation = tokenImplementation;
    }

    function createDropCollection(
        string memory name,
        string memory symbol,
        address treasury,
        address royalty,
        uint96 royaltyFee
    ) external {
        address deployed = _createCollection(
            _dropImplementation,
            name,
            symbol,
            treasury,
            royalty,
            royaltyFee
        );
        _collections.add(deployed);
        emit CollectionCreated(deployed);
    }

    function createTokenCollection(
        string memory name,
        string memory symbol,
        address treasury,
        address royalty,
        uint96 royaltyFee
    ) external {
        address deployed = _createCollection(
            _tokenImplementation,
            name,
            symbol,
            treasury,
            royalty,
            royaltyFee
        );
        _collections.add(deployed);
        emit CollectionCreated(deployed);
    }

    function setTreasury(address treasury) external onlyOwner {
        _treasury = treasury;
    }

    function setDropImplementation(address implementation) external onlyOwner {
        _dropImplementation = implementation;
    }

    function setTokenImplementation(address implementation) external onlyOwner {
        _tokenImplementation = implementation;
    }

    function addCollection(address collection) external onlyOwner {
        _collections.add(collection);
    }

    function removeCollection(address collection) external onlyOwner {
        _collections.remove(collection);
    }

    function setRateOverride(address collection, uint256 rate) external onlyOwner {
        _rateOverride[collection].isValue = true;
        _rateOverride[collection].value = rate;
    }

    function withdraw(uint256 amount) external {
        require(
            address(this).balance >= amount,
            "Not enough to withdraw"
        );

        AddressUpgradeable.sendValue(payable(_treasury), amount);
    }

    function addFees(uint256 amount) external override {
        require(_collections.contains(_msgSender()), "Invalid Collection");

        _fees[_msgSender()] = _fees[_msgSender()].add(commission(_msgSender(), amount));
    }

    function addFeesClaimed(uint256 amount) external override {
        require(_collections.contains(_msgSender()), "Invalid Collection");

        _feesClaimed[_msgSender()] = _feesClaimed[_msgSender()].add(amount);
    }

    function commission(address collection, uint256 amount) public view override returns (uint256) {
        uint256 rate = _rateOverride[collection].isValue
            ? _rateOverride[collection].value
            : _rate;

        return ((rate * amount) / 10000);
    }

    function getFees(address account) external view override returns (uint256) {
        return _fees[account] - _feesClaimed[account];
    }

    receive() external payable {}

    function _createCollection(
        address implementation,
        string memory name,
        string memory symbol,
        address treasury,
        address royalty,
        uint96 royaltyFee
    ) private returns (address) {
        address deployed = ClonesUpgradeable.clone(implementation);
        IBaseCollection collection = IBaseCollection(deployed);
        collection.initialize(
            name,
            symbol,
            treasury,
            royalty,
            royaltyFee
        );
        collection.transferOwnership(_msgSender());

        return deployed;
    }
}