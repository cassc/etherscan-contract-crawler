// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./interfaces/IBaseCollection.sol";
import "./interfaces/INiftyKit.sol";
import "./interfaces/IDropKitPass.sol";

contract NiftyKitV2 is Initializable, OwnableUpgradeable, INiftyKit {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using ERC165CheckerUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    address private _treasury;
    uint96 private constant _rate = 500; // parts per 10,000
    EnumerableSetUpgradeable.AddressSet _collections;
    mapping(address => uint256) private _fees;
    mapping(address => uint256) private _feesClaimed;
    mapping(uint96 => address) private _implementations;
    mapping(address => INiftyKit.Entry) private _rateOverride;
    IDropKitPass private _dropKitPass;
    mapping(address => INiftyKit.Entry) private _rateOverrideByUser;
    address private _admin;

    modifier onlyAdmin() {
        require(_admin == _msgSender(), "Not admin");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        _treasury = _msgSender();
    }

    function createCollection(
        uint96 typeId,
        string memory name,
        string memory symbol,
        address treasury,
        address royalty,
        uint96 royaltyFee
    ) external {
        address implementation = _implementations[typeId];
        require(implementation != address(0), "Invalid implementation");
        require(
            implementation.supportsInterface(type(IBaseCollection).interfaceId),
            "Not supported"
        );

        address deployed = _createCollection(
            implementation,
            name,
            symbol,
            treasury,
            royalty,
            royaltyFee
        );
        _collections.add(deployed);
        emit CollectionCreated(typeId, deployed);
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function setDropKitPass(address passAddress) external onlyOwner {
        _dropKitPass = IDropKitPass(passAddress);
    }

    function setTreasury(address treasury) external onlyOwner {
        _treasury = treasury;
    }

    function setImplementation(uint96 typeId, address implementation)
        external
        onlyOwner
    {
        _implementations[typeId] = implementation;
    }

    function addCollection(uint96 typeId, address collection)
        external
        onlyOwner
    {
        require(!_collections.contains(collection), "Already exists");

        _collections.add(collection);
        emit CollectionCreated(typeId, collection);
    }

    function setRateOverride(address collection, uint256 rate)
        external
        onlyOwner
    {
        require(_collections.contains(collection), "Does not exist");

        _rateOverride[collection].isValue = true;
        _rateOverride[collection].value = rate;
    }

    function setUserRate(address user, uint256 rate) external onlyAdmin {
        _rateOverrideByUser[user].isValue = true;
        _rateOverrideByUser[user].value = rate;

        emit UserRateUpdated(user, rate);
    }

    function removeUserRate(address user) external onlyAdmin {
        _rateOverrideByUser[user].isValue = false;

        emit UserRateRemoved(user, _rateOverrideByUser[user].value);
    }

    function getDropKitPass() external view returns (address) {
        return address(_dropKitPass);
    }

    function withdraw(uint256 amount) external {
        require(address(this).balance >= amount, "Not enough to withdraw");

        AddressUpgradeable.sendValue(payable(_treasury), amount);
    }

    function addFees(uint256 amount) external override {
        require(_collections.contains(_msgSender()), "Invalid collection");

        unchecked {
            _fees[_msgSender()] = _fees[_msgSender()].add(
                commission(_msgSender(), amount)
            );
        }
    }

    function addFeesClaimed(uint256 amount) external override {
        require(_collections.contains(_msgSender()), "Invalid collection");

        unchecked {
            _feesClaimed[_msgSender()] = _feesClaimed[_msgSender()].add(amount);
        }
    }

    function commission(address collection, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 rate = _rateOverride[collection].isValue
            ? _rateOverride[collection].value
            : _rate;

        return rate.mul(amount).div(10000);
    }

    function getFees(address account) external view override returns (uint256) {
        return _fees[account].sub(_feesClaimed[account]);
    }

    function getImplementation(uint96 typeId) public view returns (address) {
        return _implementations[typeId];
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
            _msgSender(),
            name,
            symbol,
            treasury,
            royalty,
            royaltyFee
        );

        if (address(_dropKitPass) != address(0)) {
            _rateOverride[deployed].isValue = true;
            _rateOverride[deployed].value = _dropKitPass.getFeeRateOf(
                _msgSender()
            );
        }

        if (_rateOverrideByUser[_msgSender()].isValue) {
            _rateOverride[deployed].isValue = true;
            _rateOverride[deployed].value = _rateOverrideByUser[_msgSender()]
                .value;
        }
        return deployed;
    }
}