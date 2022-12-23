// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "Pausable.sol";

import "ERC1967Proxy.sol";
import "Ownable.sol";
import "CoboSafeModule.sol";

contract CoboSafeFactory is TransferOwnable, Pausable {
    string public constant NAME = "Cobo Safe Factory";
    string public constant VERSION = "0.5.0";

    /// @dev the current SubSafeModule implementation address
    address public implementation;

    /// @dev the default subSafe factory to work with
    address public subSafeFactory;

    /// @dev the module list
    address[] public modules;
    /// @dev mapping from `safe` => `module`
    mapping(address => address) public safeToModule;
    /// @dev mapping from `module` => `safe`
    mapping(address => address) public moduleToSafe;

    /// @notice Event fired when a module is created
    /// @dev Event fired when a a module is created via `createModule` or `createSubSafeModuleWithNonce`
    /// @param safe the module's owner
    /// @param module the module created
    /// @param sender the owner who created the module
    event NewModule(
        address indexed safe,
        address indexed module,
        address indexed sender
    );

    /// @notice Constructor function for CoboSafeFactory
    /// @dev The factory contract to create CoboSafeModule.
    /// @param _implementation the SubSafe implementation address
    /// @param _subSafeFactory the SubSafeFactory instance's address
    constructor(address _implementation, address _subSafeFactory) {
        setImplementation(_implementation);
        setSubSafeFactory(_subSafeFactory);
    }

    /// @notice Create the module for given safe with the modulesSize as salt seed
    /// @dev It is compatible with previous implementation. The factory contract to create CoboSafeModule
    ///      by using default nonce and subSafeFactory.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    function createModule(address payable _safe)
        external
        whenNotPaused
        returns (address _module)
    {
        _module = createSafeModuleWithNonce(_safe, modulesSize());
    }

    /// @notice Create the module with nonce and subSafeFactory
    /// @dev The factory contract to create CoboSafeModule by using provided nonce and subSafeFactory.
    ///      If _subSafeFactory is zero address, the default is used.
    /// @param _safe the Gnosis Safe (GnosisSafeProxy) instance's address
    /// @param _nonce as the seed of salt
    function createSafeModuleWithNonce(address payable _safe, uint256 _nonce)
        public
        whenNotPaused
        returns (address _module)
    {
        require(_safe != address(0), "Invalid safe address");
        require(safeToModule[_safe] == address(0), "Module already created");
        bytes memory bytecode = type(ERC1967Proxy).creationCode;
        bytes memory initData = abi.encodeWithSignature('initialize(address,address)', _safe, subSafeFactory);

        bytes memory creationCode = abi.encodePacked(
            bytecode,
            abi.encode(implementation, initData)
        );
        bytes32 salt = keccak256(abi.encodePacked(_safe, address(this), _nonce));

        assembly {
            _module := create2(
                0,
                add(creationCode, 32),
                mload(creationCode),
                salt
            )
        }
        require(_module != address(0), "Failed to create module");
        modules.push(_module);
        safeToModule[_safe] = _module;
        moduleToSafe[_module] = _safe;

        emit NewModule(_safe, _module, _msgSender());
    }

    /// @notice Set the SafeModule implementation address
    /// @param _implementation SubSafeModule implementation address
    function setImplementation(address _implementation) public onlyOwner {
        require(_implementation != address(0), "Invalid implementation address");
        implementation = _implementation;
    }

    /// @notice Set the SubSafeFactory instance's address
    /// @dev to handle the upgrade of SubSafeFactory
    /// @param _subSafeFactory the SubSafeFactory instance's address
    function setSubSafeFactory(address _subSafeFactory) public onlyOwner {
        require(_subSafeFactory != address(0), "Invalid subSafeFactory address");
        subSafeFactory = _subSafeFactory;
    }

    /// @notice Set the factory pause status
    /// @param paused the paused status of true|false
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    /// @notice return the total count of created modules
    /// @return The total count of created modules
    function modulesSize() public view returns (uint256) {
        return modules.length;
    }
}