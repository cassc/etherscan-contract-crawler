// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../modules/common/IModule.sol";
import "./IVault.sol";
import {ModuleRegistry} from "../infrastructure/ModuleRegistry.sol";

/**
 * @title BaseVault
 * @notice Simple modular vault that authorises modules to call its invoke() method.
 */
contract BaseVault is IVault {

    // Zero address
    address constant internal ZERO_ADDRESS = address(0);
    // The owner
    address public owner;
    // The authorised modules
    mapping (address => bool) public authorised;
    // module executing static calls
    address public staticCallExecutor;
    // The number of modules
    uint256 public modules;

    event AuthorisedModule(address indexed module, bool value);
    event Invoked(address indexed module, address indexed target, uint256 indexed value, bytes data);
    event Received(uint256 indexed value, address indexed sender, bytes data);
    event StaticCallEnabled(address indexed module);

    /**
     * @notice Throws if the sender is not an authorised module.
     */
    modifier moduleOnly {
        require(authorised[msg.sender], "BV: sender not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Inits the vault by setting the owner and authorising a list of modules.
     * @param _owner The owner.
     * @param _initData bytes32 initilization data specific to the module.
     * @param _modules The modules to authorise.
     */
    function init(address _owner, address[] calldata _modules, bytes[] calldata _initData) external {
        uint256 len = _modules.length;
        require(owner == ZERO_ADDRESS, "BV: vault already initialised");
        require(len > 0, "BV: empty modules");
        require(_initData.length == len, "BV: inconsistent lengths");
        owner = _owner;
        modules = len;
        for (uint256 i = 0; i < len; i++) {
            require(_modules[i] != ZERO_ADDRESS, "BV: Invalid address");
            require(!authorised[_modules[i]], "BV: Invalid module");
            authorised[_modules[i]] = true;
            IModule(_modules[i]).init(address(this), _initData[i]);
            emit AuthorisedModule(_modules[i], true);
        }
    }

    /**
     * @inheritdoc IVault
     */
    function authoriseModule(
        address _module,
        bool _value,
        bytes memory _initData
    ) 
        external
        moduleOnly
    {
        if (authorised[_module] != _value) {
            emit AuthorisedModule(_module, _value);
            if (_value) {
                modules += 1;
                authorised[_module] = true;
                IModule(_module).init(address(this), _initData);
            } else {
                modules -= 1;
                require(modules > 0, "BV: cannot remove last module");
                delete authorised[_module];
            }
        }
    }

    /**
    * @inheritdoc IVault
    */
    function enabled(bytes4 _sig) public view returns (address) {
        address executor = staticCallExecutor;
        if(executor != ZERO_ADDRESS && IModule(executor).supportsStaticCall(_sig)) {
            return executor;
        }
        return ZERO_ADDRESS;
    }

    /**
    * @inheritdoc IVault
    */
    function enableStaticCall(address _module) external moduleOnly {
        if(staticCallExecutor != _module) {
            require(authorised[_module], "BV: unauthorized executor");
            staticCallExecutor = _module;
            emit StaticCallEnabled(_module);
        }
    }

    /**
     * @inheritdoc IVault
     */
    function setOwner(address _newOwner) external moduleOnly {
        require(_newOwner != ZERO_ADDRESS, "BV: address cannot be null");
        owner = _newOwner;
    }

    /**
     * @notice Performs a generic transaction.
     * @param _target The address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     * @return _result The bytes result after call.
     */
    function invoke(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) 
        external 
        moduleOnly 
        returns(bytes memory _result) 
    {
        bool success;
        require(address(this).balance >= _value, "BV: Insufficient balance");
        emit Invoked(msg.sender, _target, _value, _data);
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @notice This method delegates the static call to a target contract if the data corresponds
     * to an enabled module, or logs the call otherwise.
     */
    fallback() external payable {
        address module = enabled(msg.sig);
        if (module == ZERO_ADDRESS) {
            emit Received(msg.value, msg.sender, msg.data);
        } else {
            require(authorised[module], "BV: unauthorised module");

            // solhint-disable-next-line no-inline-assembly
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := staticcall(gas(), module, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {revert(0, returndatasize())}
                default {return (0, returndatasize())}
            }
        }
    }

    receive() external payable {
        emit Received(msg.value, msg.sender, "");
    }
}