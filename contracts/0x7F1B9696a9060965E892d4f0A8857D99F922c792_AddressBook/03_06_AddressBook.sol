// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OwnedUpgradeabilityProxy } from "../packages/oz/upgradeability/OwnedUpgradeabilityProxy.sol";

/**
 * @title AddressBook Module
 */
contract AddressBook is Ownable {
    /// @dev ONtoken implementation key
    bytes32 private constant ON_TOKEN_IMPL = keccak256("ON_TOKEN_IMPL");
    /// @dev ONtokenFactory key
    bytes32 private constant ON_TOKEN_FACTORY = keccak256("ON_TOKEN_FACTORY");
    /// @dev Whitelist key
    bytes32 private constant WHITELIST = keccak256("WHITELIST");
    /// @dev Controller key
    bytes32 private constant CONTROLLER = keccak256("CONTROLLER");
    /// @dev MarginPool key
    bytes32 private constant MARGIN_POOL = keccak256("MARGIN_POOL");
    /// @dev MarginCalculator key
    bytes32 private constant MARGIN_CALCULATOR = keccak256("MARGIN_CALCULATOR");
    /// @dev Oracle key
    bytes32 private constant ORACLE = keccak256("ORACLE");

    /// @dev mapping between key and address
    mapping(bytes32 => address) private addresses;

    /// @notice emits an event when a new proxy is created
    event ProxyCreated(bytes32 indexed id, address indexed proxy);
    /// @notice emits an event when a new address is added
    event AddressAdded(bytes32 indexed id, address indexed add);

    /**
     * @notice return ONtoken implementation address
     * @return ONtoken implementation address
     */
    function getONtokenImpl() external view returns (address) {
        return getAddress(ON_TOKEN_IMPL);
    }

    /**
     * @notice return onTokenFactory address
     * @return ONtokenFactory address
     */
    function getONtokenFactory() external view returns (address) {
        return getAddress(ON_TOKEN_FACTORY);
    }

    /**
     * @notice return Whitelist address
     * @return Whitelist address
     */
    function getWhitelist() external view returns (address) {
        return getAddress(WHITELIST);
    }

    /**
     * @notice return Controller address
     * @return Controller address
     */
    function getController() external view returns (address) {
        return getAddress(CONTROLLER);
    }

    /**
     * @notice return MarginPool address
     * @return MarginPool address
     */
    function getMarginPool() external view returns (address) {
        return getAddress(MARGIN_POOL);
    }

    /**
     * @notice return MarginCalculator address
     * @return MarginCalculator address
     */
    function getMarginCalculator() external view returns (address) {
        return getAddress(MARGIN_CALCULATOR);
    }

    /**
     * @notice return Oracle address
     * @return Oracle address
     */
    function getOracle() external view returns (address) {
        return getAddress(ORACLE);
    }

    /**
     * @notice set ONtoken implementation address
     * @dev can only be called by the addressbook owner
     * @param _onTokenImpl ONtoken implementation address
     */
    function setONtokenImpl(address _onTokenImpl) external onlyOwner {
        setAddress(ON_TOKEN_IMPL, _onTokenImpl);
    }

    /**
     * @notice set ONtokenFactory address
     * @dev can only be called by the addressbook owner
     * @param _onTokenFactory ONtokenFactory address
     */
    function setONtokenFactory(address _onTokenFactory) external onlyOwner {
        setAddress(ON_TOKEN_FACTORY, _onTokenFactory);
    }

    /**
     * @notice set Whitelist address
     * @dev can only be called by the addressbook owner
     * @param _whitelist Whitelist address
     */
    function setWhitelist(address _whitelist) external onlyOwner {
        setAddress(WHITELIST, _whitelist);
    }

    /**
     * @notice set Controller address
     * @dev can only be called by the addressbook owner
     * @param _controller Controller address
     */
    function setController(address _controller) external onlyOwner {
        updateImpl(CONTROLLER, _controller);
    }

    /**
     * @notice set MarginPool address
     * @dev can only be called by the addressbook owner
     * @param _marginPool MarginPool address
     */
    function setMarginPool(address _marginPool) external onlyOwner {
        setAddress(MARGIN_POOL, _marginPool);
    }

    /**
     * @notice set MarginCalculator address
     * @dev can only be called by the addressbook owner
     * @param _marginCalculator MarginCalculator address
     */
    function setMarginCalculator(address _marginCalculator) external onlyOwner {
        setAddress(MARGIN_CALCULATOR, _marginCalculator);
    }

    /**
     * @notice set Oracle address
     * @dev can only be called by the addressbook owner
     * @param _oracle Oracle address
     */
    function setOracle(address _oracle) external onlyOwner {
        setAddress(ORACLE, _oracle);
    }

    /**
     * @notice return an address for specific key
     * @param _key key address
     * @return address
     */
    function getAddress(bytes32 _key) public view returns (address) {
        return addresses[_key];
    }

    /**
     * @notice set a specific address for a specific key
     * @dev can only be called by the addressbook owner
     * @param _key key
     * @param _address address
     */
    function setAddress(bytes32 _key, address _address) public onlyOwner {
        addresses[_key] = _address;

        emit AddressAdded(_key, _address);
    }

    /**
     * @dev function to update the implementation of a specific component of the protocol
     * @param _id id of the contract to be updated
     * @param _newAddress address of the new implementation
     **/
    function updateImpl(bytes32 _id, address _newAddress) public onlyOwner {
        address payable proxyAddress = payable(getAddress(_id));

        if (proxyAddress == address(0)) {
            bytes memory params = abi.encodeWithSignature("initialize(address,address)", address(this), owner());
            OwnedUpgradeabilityProxy proxy = new OwnedUpgradeabilityProxy();
            setAddress(_id, address(proxy));
            emit ProxyCreated(_id, address(proxy));
            proxy.upgradeToAndCall(_newAddress, params);
        } else {
            OwnedUpgradeabilityProxy proxy = OwnedUpgradeabilityProxy(proxyAddress);
            proxy.upgradeTo(_newAddress);
        }
    }
}