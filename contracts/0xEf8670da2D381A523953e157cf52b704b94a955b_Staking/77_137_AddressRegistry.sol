//SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../interfaces/IAddressRegistry.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import {SafeMathUpgradeable as SafeMath} from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import {EnumerableSetUpgradeable as EnumerableSet} from "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";
import {AccessControlUpgradeable as AccessControl} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract AddressRegistry is IAddressRegistry, Initializable, AccessControl {

    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (AddressTypes => EnumerableSet.AddressSet) private addressSets;

    // solhint-disable-next-line var-name-mixedcase 
    bytes32 public immutable REGISTERED_ADDRESS = keccak256("REGISTERED_ROLE");

    address public immutable override weth;

    modifier onlyRegistered () {
        require(hasRole(REGISTERED_ADDRESS, msg.sender), "NOT_REGISTERED");
        _;
    }

    //@custom:oz-upgrades-unsafe-allow constructor 
    //solhint-disable-next-line no-empty-blocks
    constructor(address wethAddress) public initializer {
        require(wethAddress != address(0), "INVALID_ADDRESS");

        weth = wethAddress;
    }

    function initialize() public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(REGISTERED_ADDRESS, _msgSender());
    }

    function addRegistrar(address _addr) external override {
        require(_addr != address(0), "INVALID_ADDRESS");
        grantRole(REGISTERED_ADDRESS, _addr);

        emit RegisteredAddressAdded(_addr);
    }

    function removeRegistrar(address _addr) external override {
        require(_addr != address(0), "INVALID_ADDRESS");
        revokeRole(REGISTERED_ADDRESS, _addr);

        emit RegisteredAddressRemoved(_addr);
    }

    function addToRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
        uint256 arrayLength = _addresses.length;
        require(arrayLength > 0, "NO_ADDRESSES");
        EnumerableSet.AddressSet storage structToAddTo = addressSets[_index];

        for (uint256 i = 0; i < arrayLength; ++i) {
            require(_addresses[i] != address(0), "INVALID_ADDRESS");
            require(structToAddTo.add(_addresses[i]), "ADD_FAIL");
        }

        emit AddedToRegistry(_addresses, _index);
    }

    function removeFromRegistry(address[] calldata _addresses, AddressTypes _index) external override onlyRegistered {
        EnumerableSet.AddressSet storage structToRemoveFrom = addressSets[_index];
        uint256 arrayLength = _addresses.length;
        require(arrayLength > 0, "NO_ADDRESSES");
        require(arrayLength <= structToRemoveFrom.length(), "TOO_MANY_ADDRESSES");

        for (uint256 i = 0; i < arrayLength; ++i) {
            address currentAddress = _addresses[i];
            require(structToRemoveFrom.remove(currentAddress), "REMOVE_FAIL");
        }

        emit RemovedFromRegistry(_addresses, _index);
    }

    function getAddressForType(AddressTypes _index) external view override returns (address[] memory) {
        EnumerableSet.AddressSet storage structToReturn = addressSets[_index];
        uint256 arrayLength = structToReturn.length();

        address[] memory registryAddresses = new address[](arrayLength);
        for (uint256 i = 0; i < arrayLength; ++i) {
            registryAddresses[i] = structToReturn.at(i);
        }
        return registryAddresses;
    }

    function checkAddress(address _addr, uint256 _index) external view override returns (bool) {
        EnumerableSet.AddressSet storage structToCheck = addressSets[AddressTypes(_index)];
        return structToCheck.contains(_addr);
    }
}