// 286064380f2292c5d67e96f2fb855818ef275e4b
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "EnumerableSet.sol";

import "ERC1967Proxy.sol";
import "Ownable.sol";

contract CoboSafeAclFactory is TransferOwnable {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant NAME = "CoboSafe Acl Factory";
    string public constant VERSION = "0.1.0";

    /// @dev total acls created by this factory
    address[] public acls;

    /// @dev mapping from `contract` => `acl implementation`
    mapping(address => address) public contractToAclImplementation;

    /// @dev mapping from `module` => `contract` => `acl`
    mapping(address => mapping(address => address)) public moduleContractToAcl;

    /// @dev mapping from `acl` => `module`
    mapping(address => address) public aclToModule;
    /// @dev mapping from `acl` => `contract`
    mapping(address => address) public aclToContract;

    /// @notice Event fired when a acl is created
    /// @dev Event fired when a acl is created  via `createAcl` method
    /// @param safe the target safe
    /// @param module the target module
    /// @param targetContract the target contract
    /// @param acl the created acl
    event AclCreated(
        address indexed safe,
        address indexed module,
        address indexed targetContract,
        address acl
    );

    /// @notice Create the Acl for target contract in safe/module
    /// @param targetContract Target contract protected by Acl
    /// @param safe the target safe
    /// @param module the target module
    /// @param nonce the nonce to generate the salt.
    function createAcl(address targetContract, address safe, address module, uint256 nonce)
        external
        returns (address acl)
    {
        require(targetContract != address(0), "Invalid target address");
        require(safe != address(0), "Invalid safe address");
        require(module != address(0), "Invalid module address");

        address implementation = contractToAclImplementation[targetContract];
        require(implementation != address(0), "Invalid implementation address");

        bytes memory bytecode = type(ERC1967Proxy).creationCode;
        bytes memory initData = abi.encodeWithSignature('initialize(address,address)', safe, module);

        bytes memory creationCode = abi.encodePacked(
            bytecode,
            abi.encode(implementation, initData)
        );
        bytes32 salt = keccak256(abi.encodePacked(safe, address(this), nonce));

        assembly {
            acl := create2(0, add(creationCode, 32), mload(creationCode), salt)
        }
        require(acl != address(0), "Failed to create acl");
        emit AclCreated(safe, module, targetContract, acl);

        acls.push(acl);
        moduleContractToAcl[module][targetContract] = acl;
        aclToModule[acl] = module;
        aclToContract[acl] = targetContract;
    }

    /// @notice Set the Acl implementation address to protect target contract
    /// @param targetContract Target contract protected by Acl
    /// @param implementation Acl implementation address
    function setImplementation(address targetContract, address implementation) public onlyOwner {
        require(targetContract != address(0), "Invalid target address");
        require(implementation != address(0), "Invalid implementation address");
        contractToAclImplementation[targetContract] = implementation;
    }

    /// @notice return the total count of created subSafes
    /// @return The total count of created subSafes
    function aclsSize() external view returns (uint256) {
        return acls.length;
    }
}