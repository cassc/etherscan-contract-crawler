// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Create2Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";

import { GSWProxy } from "./GSWProxy.sol";
import { IGaslessSmartWallet } from "./interfaces/IGaslessSmartWallet.sol";
import { IGSWVersionsRegistry } from "./interfaces/IGSWVersionsRegistry.sol";
import { IGSWFactory } from "./interfaces/IGSWFactory.sol";

error GSWFactory__NotEOA();
error GSWFactory__Unauthorized();
error GSWFactory__InvalidParams();

/// @title      GSWFactory
/// @notice     Deploys GSWProxy contracts at deterministic addresses using Create2
/// @dev        Upgradeable through GSWFactoryProxy
///             To deploy a new version of GSWProxy, the new factory contract must be deployed
///             and GSWFactoryProxy upgraded to that new contract
contract GSWFactory is IGSWFactory, Initializable {
    /***********************************|
    |           STATE VARIABLES         |
    |__________________________________*/

    /// @notice  registry holding the valid versions (addresses) for GSW implementation contracts
    ///          The registry is used to verify a valid version before setting a new gswImpl
    ///          as default for new deployments
    IGSWVersionsRegistry public immutable gswVersionsRegistry;

    /// @notice GSW logic contract address that new GSWProxy deployments point to
    ///         modifiable by GSWVersionsRegistry
    address public gswImpl;

    /***********************************|
    |               EVENTS              |
    |__________________________________*/

    /// @notice Emitted when a new gsw (proxy) has been deployed
    event GSWDeployed(address indexed owner, address indexed gsw);

    /***********************************|
    |              MODIFIERS            |
    |__________________________________*/

    /// @notice reverts if owner_ is a contract
    modifier onlyEOA(address owner_) {
        if (Address.isContract(owner_)) {
            revert GSWFactory__NotEOA();
        }
        _;
    }

    /// @notice reverts if msg.sender is not GSWVersionsRegistry
    modifier onlyRegistry() {
        if (msg.sender != address(gswVersionsRegistry)) {
            revert GSWFactory__Unauthorized();
        }
        _;
    }

    /***********************************|
    |    CONSTRUCTOR / INITIALIZERS     |
    |__________________________________*/

    /// @notice constructor sets the immutable gswVersionsRegistry address
    /// @param gswVersionsRegistry_ address of GSWVersionsRegistry
    /// @dev    setting the gswVersionsRegistry on the logic contract at deployment is ok because the
    ///         GSWVersionsRegistry is upgradeable so the address set here is the proxy address
    ///         which really shouldn't change. Even if it should change then worst case
    ///         a new GSWFactory logic contract has to be deployed pointing to a new registry
    constructor(IGSWVersionsRegistry gswVersionsRegistry_) {
        if (address(gswVersionsRegistry_) == address(0)) {
            revert GSWFactory__InvalidParams();
        }
        gswVersionsRegistry = gswVersionsRegistry_;

        // Ensure logic contract initializer is not abused by disabling initializing
        // see https://forum.openzeppelin.com/t/security-advisory-initialize-uups-implementation-contracts/15301
        // and https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#initializing_the_implementation_contract
        _disableInitializers();
    }

    /// @notice initializes the contract
    function initialize() public initializer {}

    /***********************************|
    |            PUBLIC API             |
    |__________________________________*/

    /// @inheritdoc IGSWFactory
    function computeAddress(address owner_) public view returns (address) {
        if (Address.isContract(owner_)) {
            // owner of a GSW must be an EOA, if it's a contract return zero address
            return address(0);
        }
        return _computeGSWProxyAddress(owner_);
    }

    /// @inheritdoc IGSWFactory
    function deploy(address owner_) external onlyEOA(owner_) returns (address) {
        address computedGSWProxyAddress_ = computeAddress(owner_);
        // for case if computedGSWProxyAddress_ == adress(0) then GSW.initialize will fail and revert tx anyway

        if (Address.isContract(computedGSWProxyAddress_)) {
            // if GSWProxy has already been deployed then just return it's address
            return computedGSWProxyAddress_;
        } else {
            return _deployGSWProxyDeterministic(owner_);
        }
    }

    /***********************************|
    |            ONLY  REGISTRY         |
    |__________________________________*/

    /// @inheritdoc IGSWFactory
    function setGSWImpl(address gswImpl_) external onlyRegistry {
        // do not requireValidGSWVersion because sender is registry anyway
        gswImpl = gswImpl_;
    }

    /***********************************|
    |              INTERNAL             |
    |__________________________________*/

    /// @dev            computes the deterministic contract address for a GSWProxy deployment for owner_
    /// @param  owner_  GSW owner
    /// @return         the computed contract address
    function _computeGSWProxyAddress(address owner_) internal view returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _getSalt(owner_), keccak256(_getGSWProxyBytecode()))
        );

        // cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    /// @dev                         deploys a GSWProxy deterministically for owner_
    /// @param owner_                GSW owner
    /// @return deployedGSWProxy_    the deployed contract address
    function _deployGSWProxyDeterministic(address owner_) internal returns (address deployedGSWProxy_) {
        // deploy GSWProxy using CREATE2 opcode (through specifying salt)
        deployedGSWProxy_ = address(new GSWProxy{ salt: _getSalt(owner_) }(gswImpl));

        // initialize GSW through proxy with IGaslessSmartWallet interface
        IGaslessSmartWallet(deployedGSWProxy_).initialize(owner_);

        emit GSWDeployed(owner_, deployedGSWProxy_);
    }

    /// @dev            gets the salt used for deterministic deployment for owner_
    /// @param owner_   GSW owner
    /// @return         the bytes32 (keccak256) salt
    function _getSalt(address owner_) internal pure returns (bytes32) {
        // only owner is used as salt
        // no extra salt is needed because even if another version of GSWFactory would be deployed,
        // deterministic deployments take into account the deployers address (i.e. the factory address)
        return keccak256(abi.encode(owner_));
    }

    /// @dev     gets the byteCode for the GSWProxy contract that is deployed by this factory
    /// @return  the bytes byteCode for the contract
    function _getGSWProxyBytecode() internal view returns (bytes memory) {
        bytes memory bytecode_ = type(GSWProxy).creationCode;

        return abi.encodePacked(bytecode_, abi.encode(gswImpl));
    }
}