// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// OZ Imports

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/Initializable.sol";

// Tornado Imports

import { ITornadoInstance } from "tornado-anonymity-mining/contracts/interfaces/ITornadoInstance.sol";

// Local imports

import { ENSResolver } from "./libraries/ENSResolver.sol";
import { NameEncoder } from "./libraries/NameEncoder.sol";
import { TornadoRouter } from "./TornadoRouter.sol";

/**
 * @title InstanceRegistry
 * @author AlienTornadosaurusHex
 * @notice A contract which enumerates Tornado Cash pool instances, and also stores essential data regarding
 * them.
 * @dev This contract will help us layout storage properly for a proxy upgrade for the impl
 * InstanceRegistry.
 */
contract InstanceRegistryLegacyStorage {
    /* From first contract, just so right uint type is chosen */
    enum LegacyStatePlaceholder {
        DISABLED,
        ENABLED
    }

    /* From first contract, just if necessary to be able to properly unpack and determine value storage
    addresses and offsets */
    struct LegacyInstanceStructPlaceholder {
        bool deprecatedIsERC20;
        address deprecatedToken;
        LegacyStatePlaceholder deprecatedState;
        uint24 deprecatedUniswapPoolSwappingFee;
        uint32 deprecatedProtocolFeePercentage;
    }

    /**
     * @dev From Initializable.sol of first contract
     */
    bool private _deprecatedInitialized;

    /**
     * @dev From Initializable.sol of first contract
     */
    bool private _deprecatedInitializing;

    /**
     * @dev From first contract
     */
    address private _deprecatedRouterAddress;

    /**
     * @dev From first contract
     */
    mapping(address => LegacyInstanceStructPlaceholder) private _deprecatedInstances;

    /**
     * @dev From first contract
     */
    ITornadoInstance[] private _deprecatedInstanceIds;
}

/**
 * @dev This struct holds barebones information regarding an instance and its data location in storage.
 */
struct InstanceState {
    IERC20 token;
    uint80 index;
    bool isERC20;
    bool isEnabled;
}

/**
 * @title InstanceRegistry
 * @author AlienTornadosaurusHex
 * @notice A contract which enumerates Tornado Cash pool instances, and also stores essential data regarding
 * them.
 * @dev This is an improved version of the InstanceRegistry with a modified design from the original contract.
 */
contract InstanceRegistry is InstanceRegistryLegacyStorage, ENSResolver, Initializable {
    using SafeERC20 for IERC20;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ VARIABLES ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    /**
     * @notice The address of the Governance proxy
     */
    address public immutable governanceProxyAddress;

    /**
     * @notice Essential data regarding instances, see struct above
     */
    mapping(ITornadoInstance => InstanceState) public instanceData;

    /**
     * @notice All instances enumerable
     */
    ITornadoInstance[] public instances;

    /**
     * @notice The router which processes txs which we must command to approve tokens
     */
    TornadoRouter public router;

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ EVENTS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    event RouterRegistered(address newRouterAddress);
    event InstanceAdded(address indexed instance, uint80 dataIndex, bool isERC20);
    event InstanceRemoved(address indexed instance);

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ LOGIC ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    constructor(address _governanceProxyAddress) public {
        governanceProxyAddress = _governanceProxyAddress;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceProxyAddress, "InstanceRegistry: only governance");
        _;
    }

    function version() public pure virtual returns (string memory) {
        return "v2-infrastructure-upgrade";
    }

    function initialize(ITornadoInstance[] memory _instances, TornadoRouter _router)
        external
        onlyGovernance
        initializer
    {
        uint256 numInstances = _instances.length;

        // Router must be initialized before otherwise below will fail
        router = _router;

        for (uint256 i = 0; i < numInstances; i++) {
            addInstance(_instances[i]);
        }
    }

    function addInstance(ITornadoInstance _instance) public virtual onlyGovernance {
        // The instance may not already be enabled

        bool isEnabled = instanceData[_instance].isEnabled;

        require(!isEnabled, "InstanceRegistry: can't add the same instance.");

        // Determine whether it is an ERC20 or not

        IERC20 token = IERC20(address(0));

        bool isERC20 = false;

        // ETH instances do not know of a `token()` call
        try _instance.token() returns (address _tokenAddress) {
            token = IERC20(_tokenAddress);
            isERC20 = true;
        } catch {
            /* It's an ETH instance, do nothing */
        }

        // If it is ERC20 then make the router give an approval for the Tornado instance to allow the token
        // amount, if it hasn't already done so
        if (isERC20) {
            uint256 routerAllowanceForInstance = token.allowance(address(router), address(_instance));

            if (routerAllowanceForInstance == 0) {
                router.approveTokenForInstance(token, address(_instance), type(uint256).max);
            }
        }

        // Add it to the enumerable
        instances.push(_instance);

        // Read out the index of the instance in the enumerable
        uint64 instanceIndex = uint64(instances.length - 1);

        // Store the collected data of the instance
        instanceData[_instance] =
            InstanceState({ token: token, index: instanceIndex, isERC20: isERC20, isEnabled: true });

        // Log
        emit InstanceAdded(address(_instance), instanceIndex, isERC20);
    }

    /**
     * @notice Remove an instance, only callable by Governance.
     * @dev The access modifier is in the internal call.
     * @param _instanceIndex The index of the instance to remove.
     */
    function removeInstanceByIndex(uint256 _instanceIndex) public virtual {
        _removeInstanceByAddress(address(instances[_instanceIndex]));
    }

    /**
     * @notice Remove an instance, only callable by Governance.
     * @dev The access modifier is in the internal call.
     * @param _instanceAddress The adress of the instance to remove.
     */
    function removeInstanceByAddress(address _instanceAddress) public virtual {
        _removeInstanceByAddress(_instanceAddress);
    }

    function _removeInstanceByAddress(address _instanceAddress) internal virtual onlyGovernance {
        // Grab data needed to remove the instance

        ITornadoInstance instance = ITornadoInstance(_instanceAddress);
        InstanceState memory data = instanceData[instance];

        // Checks whether already removed, so allowance can't be killed

        require(data.isEnabled, "InstanceRegistry: already removed");

        // Kill the allowance of the router first (arbitrary order)

        if (data.isERC20) {
            uint256 routerAllowanceForInstance = data.token.allowance(address(router), _instanceAddress);

            if (routerAllowanceForInstance != 0) {
                router.approveTokenForInstance(data.token, _instanceAddress, 0);
            }
        }

        // We need to revert all changes, meaning modify position of last instance and change index in data

        uint64 lastInstanceIndex = uint64(instances.length - 1);

        ITornadoInstance lastInstance = instances[lastInstanceIndex];

        // Swap position of last instance with old

        instances[data.index] = lastInstance;

        instanceData[lastInstance].index = data.index;

        instances.pop();

        // Delete old instance data

        delete instanceData[instance];

        // Log

        emit InstanceRemoved(_instanceAddress);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ SETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    function setTornadoRouter(address _newRouterAddress) external onlyGovernance {
        router = TornadoRouter(_newRouterAddress);
        emit RouterRegistered(_newRouterAddress);
    }

    /* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ GETTERS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */

    function getAllInstances() public view virtual returns (ITornadoInstance[] memory allInstances) {
        return getInstancesByIndex(0, instances.length - 1);
    }

    function getInstancesByIndex(uint256 _inclusiveStartIndex, uint256 _inclusiveEndIndex)
        public
        view
        virtual
        returns (ITornadoInstance[] memory allInstances)
    {
        allInstances = new ITornadoInstance[](1 + _inclusiveEndIndex - _inclusiveStartIndex);

        for (uint256 i = _inclusiveStartIndex; i < _inclusiveEndIndex + 1; i++) {
            allInstances[i - _inclusiveStartIndex] = instances[i];
        }
    }

    function getInstanceByENSName(string memory _instanceENSName)
        public
        view
        virtual
        returns (ITornadoInstance)
    {
        return ITornadoInstance(resolveByName(_instanceENSName));
    }

    function getInstanceByIndex(uint256 _index) public view virtual returns (ITornadoInstance) {
        return instances[_index];
    }

    function getAllInstanceStates() public view virtual returns (InstanceState[] memory data) {
        return getInstanceStatesByIndex(0, instances.length - 1);
    }

    function getInstanceStatesByENSName(string[] memory _instanceENSNames)
        public
        view
        virtual
        returns (InstanceState[] memory data)
    {
        uint256 len = _instanceENSNames.length;

        data = new InstanceState[](_instanceENSNames.length);

        for (uint256 i = 0; i < len; i++) {
            data[i] = instanceData[getInstanceByENSName(_instanceENSNames[i])];
        }
    }

    function getInstanceStatesByIndex(uint256 _inclusiveStartIndex, uint256 _inclusiveEndIndex)
        public
        view
        virtual
        returns (InstanceState[] memory data)
    {
        data = new InstanceState[](1 + _inclusiveEndIndex - _inclusiveStartIndex);

        for (uint256 i = _inclusiveStartIndex; i < _inclusiveEndIndex + 1; i++) {
            data[i - _inclusiveStartIndex] = instanceData[instances[i]];
        }
    }

    function getInstanceStateByENSName(string memory _instanceENSName)
        public
        view
        virtual
        returns (InstanceState memory data)
    {
        return getInstanceState(getInstanceByENSName(_instanceENSName));
    }

    function getInstanceStateByIndex(uint256 _index)
        public
        view
        virtual
        returns (InstanceState memory data)
    {
        return instanceData[getInstanceByIndex(_index)];
    }

    function getInstanceState(ITornadoInstance _instance)
        public
        view
        virtual
        returns (InstanceState memory data)
    {
        return instanceData[_instance];
    }

    function getInstanceTokenByENSName(string memory _instanceENSName) public view virtual returns (IERC20) {
        return getInstanceToken(getInstanceByENSName(_instanceENSName));
    }

    function getInstanceToken(ITornadoInstance _instance) public view virtual returns (IERC20) {
        return instanceData[_instance].token;
    }

    function getInstanceIndexByENSName(string memory _instanceENSName) public view virtual returns (uint80) {
        return getInstanceIndex(getInstanceByENSName(_instanceENSName));
    }

    function getInstanceIndex(ITornadoInstance _instance) public view virtual returns (uint80) {
        return instanceData[_instance].index;
    }

    function isERC20InstanceByENSName(string memory _instanceENSName) public view virtual returns (bool) {
        return isERC20Instance(getInstanceByENSName(_instanceENSName));
    }

    function isERC20Instance(ITornadoInstance _instance) public view virtual returns (bool) {
        return instanceData[_instance].isERC20;
    }

    function isRegisteredInstanceByENSName(string memory _instanceENSName)
        public
        view
        virtual
        returns (bool)
    {
        return isEnabledInstanceByENSName(_instanceENSName);
    }

    function isRegisteredInstance(ITornadoInstance _instance) public view virtual returns (bool) {
        return isEnabledInstance(_instance);
    }

    function isEnabledInstanceByENSName(string memory _instanceENSName) public view virtual returns (bool) {
        return isEnabledInstance(getInstanceByENSName(_instanceENSName));
    }

    function isEnabledInstance(ITornadoInstance _instance) public view virtual returns (bool) {
        return instanceData[_instance].isEnabled;
    }
}