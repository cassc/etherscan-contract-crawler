// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import "./openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./access/Governable.sol";
import "./CapsuleFactoryStorage.sol";
import "./Errors.sol";
import "./Capsule.sol";

contract CapsuleFactory is Initializable, Governable, CapsuleFactoryStorage {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant VERSION = "1.1.1";
    uint256 internal constant MAX_CAPSULE_CREATION_TAX = 0.1 ether;

    event AddedToWhitelist(address indexed user);
    event RemovedFromWhitelist(address indexed user);
    event AddedToBlacklist(address indexed user);
    event RemovedFromBlacklist(address indexed user);
    event FlushedTaxAmount(uint256 taxAmount);
    event CapsuleCollectionTaxUpdated(uint256 oldTax, uint256 newTax);
    event CapsuleCollectionCreated(address indexed caller, address indexed capsule);
    event CapsuleOwnerUpdated(address indexed capsule, address indexed previousOwner, address indexed newOwner);
    event TaxCollectorUpdated(address indexed oldTaxCollector, address indexed newTaxCollector);

    function initialize() external initializer {
        __Governable_init();
        capsuleCollectionTax = 0.025 ether;
        taxCollector = _msgSender();
    }

    /******************************************************************************
     *                              Read functions                                *
     *****************************************************************************/

    /// @notice Get list of all Capsule Collections created
    function getAllCapsuleCollections() external view returns (address[] memory) {
        return capsules;
    }

    /// @notice Get list of all Capsules created by an input owner address
    function getCapsuleCollectionsOf(address _owner) external view returns (address[] memory) {
        return capsulesOf[_owner].values();
    }

    /// @notice Get list of all whitelisted addresses
    function getWhitelist() external view returns (address[] memory) {
        return whitelist.values();
    }

    /// @notice Get list of all blacklisted addresses
    function getBlacklist() external view returns (address[] memory) {
        return blacklist.values();
    }

    /// @notice Return whether a given address is blacklisted or not
    function isBlacklisted(address _user) public view returns (bool) {
        return blacklist.contains(_user);
    }

    /// @notice Return whether a given address is whitelisted or not
    function isWhitelisted(address _user) public view returns (bool) {
        return whitelist.contains(_user);
    }

    /******************************************************************************
     *                         Public write function                             *
     *****************************************************************************/
    /**
     * @notice Create a Capsule NFT Collection which the CapsuleMinter can manage
     */
    function createCapsuleCollection(
        string calldata _name,
        string calldata _symbol,
        address _tokenURIOwner,
        bool _isCollectionPrivate
    ) external payable returns (address) {
        address _owner = _msgSender();
        if (!whitelist.contains(_owner)) {
            require(msg.value == capsuleCollectionTax, Errors.INCORRECT_TAX_AMOUNT);
        }
        Capsule _capsuleCollection = new Capsule(_name, _symbol, _tokenURIOwner, _isCollectionPrivate);

        address _capsuleAddress = address(_capsuleCollection);

        isCapsule[_capsuleAddress] = true;
        capsules.push(_capsuleAddress);
        capsulesOf[_owner].add(_capsuleAddress);

        emit CapsuleCollectionCreated(_owner, _capsuleAddress);
        _capsuleCollection.transferOwnership(_owner);
        return _capsuleAddress;
    }

    /******************************************************************************
     *                            Governor functions                              *
     *****************************************************************************/

    /// @notice Governor or tax collector can call this function to withdraw all ETH stored in this contract
    function flushTaxAmount() external {
        require(_msgSender() == governor || _msgSender() == taxCollector, Errors.UNAUTHORIZED);
        uint256 _taxAmount = address(this).balance;
        emit FlushedTaxAmount(_taxAmount);
        Address.sendValue(payable(taxCollector), _taxAmount);
    }

    function addToWhitelist(address _user) external onlyGovernor {
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(!isBlacklisted(_user), Errors.BLACKLISTED);
        require(whitelist.add(_user), Errors.ADDRESS_ALREADY_EXIST);
        emit AddedToWhitelist(_user);
    }

    function removeFromWhitelist(address _user) external onlyGovernor {
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(whitelist.remove(_user), Errors.ADDRESS_DOES_NOT_EXIST);
        emit RemovedFromWhitelist(_user);
    }

    function addToBlacklist(address _user) external onlyGovernor {
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(!isWhitelisted(_user), Errors.WHITELISTED);
        require(blacklist.add(_user), Errors.ADDRESS_ALREADY_EXIST);
        emit AddedToBlacklist(_user);
    }

    function removeFromBlacklist(address _user) external onlyGovernor {
        require(_user != address(0), Errors.ZERO_ADDRESS);
        require(blacklist.remove(_user), Errors.ADDRESS_DOES_NOT_EXIST);
        emit RemovedFromBlacklist(_user);
    }

    /// @notice Set CapsuleMinter address. This method can only be called once.
    function setCapsuleMinter(address _newCapsuleMinter) external onlyGovernor {
        require(_newCapsuleMinter != address(0), Errors.ZERO_ADDRESS);
        // Below check will make sure we only set minter once
        require(capsuleMinter == address(0), Errors.NON_ZERO_ADDRESS);
        capsuleMinter = _newCapsuleMinter;
    }

    /// @notice update Capsule Collection creation tax
    function updateCapsuleCollectionTax(uint256 _newTax) external onlyGovernor {
        require(_newTax <= MAX_CAPSULE_CREATION_TAX, Errors.INCORRECT_TAX_AMOUNT);
        require(_newTax != capsuleCollectionTax, Errors.SAME_AS_EXISTING);
        emit CapsuleCollectionTaxUpdated(capsuleCollectionTax, _newTax);
        capsuleCollectionTax = _newTax;
    }

    /// @notice update tax collector
    function updateTaxCollector(address _newTaxCollector) external onlyGovernor {
        require(_newTaxCollector != address(0), Errors.ZERO_ADDRESS);
        require(_newTaxCollector != address(taxCollector), Errors.SAME_AS_EXISTING);
        emit TaxCollectorUpdated(taxCollector, _newTaxCollector);
        taxCollector = _newTaxCollector;
    }

    /******************************************************************************
     *                             Capsule function                               *
     *****************************************************************************/
    /**
     * @notice Update owner of a Capsule Collection. Only the Capsule Collection can call this method.
     * @dev Called as part of the transferOwnership function in a Capsule Collection.
     */
    function updateCapsuleCollectionOwner(address _previousOwner, address _newOwner) external {
        address _capsule = _msgSender();
        require(isCapsule[_capsule], Errors.NOT_CAPSULE);
        require(capsulesOf[_previousOwner].remove(_capsule), Errors.ADDRESS_DOES_NOT_EXIST);
        require(capsulesOf[_newOwner].add(_capsule), Errors.ADDRESS_ALREADY_EXIST);
        emit CapsuleOwnerUpdated(_capsule, _previousOwner, _newOwner);
    }
}