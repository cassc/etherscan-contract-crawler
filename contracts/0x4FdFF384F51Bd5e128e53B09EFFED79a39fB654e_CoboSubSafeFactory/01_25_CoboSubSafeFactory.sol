// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "EnumerableSet.sol";
import "Pausable.sol";

import "ERC1967Proxy.sol";
import "Ownable.sol";
import "CoboSubSafe.sol";

contract CoboSubSafeFactory is TransferOwnable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "Cobo SubSafe Factory";
    string public constant VERSION = "0.1.0";

    /// @dev the current SubSafe implementation address
    address public implementation;

    /// @dev total subSafes created by this factory
    address[] public subSafes;

    /// @dev mapping from `Cobo SubSafe` => `Name`
    mapping(address => string) public subSafesName;

    /// @dev mapping from `Gnosis safe address` => `Cobo SubSafes`
    mapping(address => EnumerableSet.AddressSet) safeToSubSafes;

    /// @dev mapping from `Cobo SubSafe` => `Gnosis safe address`
    mapping(address => address) public subSafeToSafe;

    /// @notice Event fired when a subSafe is created
    /// @dev Event fired when a subSafe is created  via `createSubSafe` method
    /// @param safe the parent safe address
    /// @param safe the Cobo subSafe address
    /// @param name the subSafe's name
    event SubSafeCreated(
        address indexed safe,
        address indexed subSafe,
        string name
    );

    /// @notice Constructor function for CoboSubSafeFactory
    /// @dev Deploy the factory with the default SubSafe implementation.
    /// @param _implementation the SubSafe implementation address
    constructor(address _implementation) {
        setImplementation(_implementation);
    }

    /// @notice Create the CoboSubSafe
    /// @dev To create the subSafe by using create2 method. The salt is generated based on
    ///      sender's address, factory address and nonce given. `SubSafeCreated` event is
    ///      fired after created successfully.
    /// @param name the subSafe's name.
    /// @param nonce the nonce to generate the salt.
    function createSubSafe(string memory name, uint256 nonce)
        external
        whenNotPaused
        returns (address subSafe)
    {
        address safe = _msgSender();
        bytes memory bytecode = type(ERC1967Proxy).creationCode;
        bytes memory initData = abi.encodeWithSignature('initialize(address)', safe);

        bytes memory creationCode = abi.encodePacked(
            bytecode,
            abi.encode(implementation, initData)
        );
        bytes32 salt = keccak256(abi.encodePacked(safe, address(this), nonce));

        assembly {
            subSafe := create2(0, add(creationCode, 32), mload(creationCode), salt)
        }
        require(subSafe != address(0), "Failed to create subSafe");

        require(subSafeToSafe[subSafe] == address(0), "Duplicated subSafe existed");
        emit SubSafeCreated(safe, subSafe, name);

        subSafes.push(subSafe);
        subSafesName[subSafe] = name;
        safeToSubSafes[safe].add(subSafe);
        subSafeToSafe[subSafe] = safe;
    }

    /// @notice Set the SubSafe implementation address
    /// @param _implementation SubSafe implementation address
    function setImplementation(address _implementation) public onlyOwner {
        require(_implementation != address(0), "invalid implementation address");
        implementation = _implementation;
    }

    /// @notice Set the factory pause status
    /// @param paused the paused status of true|false
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    /// @notice return the total count of created subSafes
    /// @return The total count of created subSafes
    function subSafesSize() external view returns (uint256) {
        return subSafes.length;
    }

    /// @notice Given a function, list all the roles that have permission to access to them
    /// @param safe the gnosis safe owned the subSafe
    /// @return list of subSafes
    function getSubSafesBySafe(address safe)
        public
        view
        returns (address[] memory)
    {
        bytes32[] memory store = safeToSubSafes[safe]._inner._values;
        address[] memory result;
        assembly {
            result := store
        }
        return result;
    }
}