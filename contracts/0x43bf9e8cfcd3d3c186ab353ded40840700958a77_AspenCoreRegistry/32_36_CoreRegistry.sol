// SPDX-License-Identifier: Apache-2.0

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                           //
//                      _'                    AAA                                                                                            //
//                    !jz_                   A:::A                                                                                           //
//                 ;Lzzzz-                  A:::::A                                                                                          //
//              '1zzzzxzz'                 A:::::::A                                                                                         //
//            !xzzzzzzi~                  A:::::::::A             ssssssssss   ppppp   ppppppppp       eeeeeeeeeeee    nnnn  nnnnnnnn        //
//         ;izzzzzzj^`                   A:::::A:::::A          ss::::::::::s  p::::ppp:::::::::p    ee::::::::::::ee  n:::nn::::::::nn      //
//              `;^.`````               A:::::A A:::::A       ss:::::::::::::s p:::::::::::::::::p  e::::::eeeee:::::een::::::::::::::nn     //
//              -;;;;;;;-              A:::::A   A:::::A      s::::::ssss:::::spp::::::ppppp::::::pe::::::e     e:::::enn:::::::::::::::n    //
//           .;;;;;;;_                A:::::A     A:::::A      s:::::s  ssssss  p:::::p     p:::::pe:::::::eeeee::::::e  n:::::nnnn:::::n    //
//         ;;;;;;;;`                 A:::::AAAAAAAAA:::::A       s::::::s       p:::::p     p:::::pe:::::::::::::::::e   n::::n    n::::n    //
//      _;;;;;;;'                   A:::::::::::::::::::::A         s::::::s    p:::::p     p:::::pe::::::eeeeeeeeeee    n::::n    n::::n    //
//            ;{jjjjjjjjj          A:::::AAAAAAAAAAAAA:::::A  ssssss   s:::::s  p:::::p    p::::::pe:::::::e             n::::n    n::::n    //
//         `+IIIVVVVVVVVI`        A:::::A             A:::::A s:::::ssss::::::s p:::::ppppp:::::::pe::::::::e            n::::n    n::::n    //
//       ^sIVVVVVVVVVVVVI`       A:::::A               A:::::As::::::::::::::s  p::::::::::::::::p  e::::::::eeeeeeee    n::::n    n::::n    //
//    ~xIIIVVVVVVVVVVVVVI`      A:::::A                 A:::::As:::::::::::ss   p::::::::::::::pp    ee:::::::::::::e    n::::n    n::::n    //
//  -~~~;;;;;;;;;;;;;;;;;      AAAAAAA                   AAAAAAAsssssssssss     p::::::pppppppp        eeeeeeeeeeeeee    nnnnnn    nnnnnn    //
//                                                                              p:::::p                                                      //
//                                                                              p:::::p                                                      //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             p:::::::p                                                     //
//                                                                             ppppppppp                                                     //
//                                                                                                                                           //
//  Website: https://aspenft.io/                                                                                                             //
//  Twitter: https://twitter.com/aspenft                                                                                                     //
//                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// import "./interfaces/ICoreRegistry.sol";
import "./interfaces/IContractProvider.sol";
import "./interfaces/IRegistry.sol";
import "./interfaces/ICoreRegistryEnabled.sol";
import "../api/registry/ICoreRegistry.sol";
import "../api/errors/ICoreErrors.sol";

contract CoreRegistry is IRegistry, IContractProvider, ICoreRegistryV0 {
    bytes4 public constant CORE_REGISTRY_ENABLED_INTERFACE_ID = 0x242e06bd;

    mapping(bytes32 => address) private _contracts;

    modifier isValidContactAddress(address addr) {
        if (addr == address(0)) revert IRegistryErrorsV0.ZeroAddressError();
        if (address(addr).code.length == 0) revert IRegistryErrorsV0.AddressNotContract();
        if (!IERC165(addr).supportsInterface(CORE_REGISTRY_ENABLED_INTERFACE_ID))
            revert IRegistryErrorsV0.CoreRegistryInterfaceNotSupported();
        _;
    }

    modifier canSetCoreRegistry(address addr) {
        ICoreRegistryEnabled coreRegistryEnabled = ICoreRegistryEnabled(addr);
        // Don't add the contract if this does not work.
        if (!coreRegistryEnabled.setCoreRegistryAddress(address(this)))
            revert IRegistryErrorsV0.FailedToSetCoreRegistry();
        _;
    }

    function getConfig(string calldata _version) public view returns (address) {
        return getContractForOrDie(keccak256(abi.encodePacked("AspenConfig_V", _version)));
    }

    function setConfigContract(address _configContract, string calldata _version) public virtual {
        if (!addContract(keccak256(abi.encodePacked("AspenConfig_V", _version)), _configContract)) {
            revert ICoreRegistryErrorsV0.FailedToSetConfigContract();
        }
        emit ConfigContractAdded(string(abi.encodePacked("AspenConfig_V", _version)), _configContract);
    }

    function getDeployer(string calldata _version) public view returns (address) {
        return getContractForOrDie(keccak256(abi.encodePacked("AspenDeployer_V", _version)));
    }

    function setDeployerContract(address _deployerContract, string calldata _version) public virtual {
        if (!addContract(keccak256(abi.encodePacked("AspenDeployer_V", _version)), _deployerContract)) {
            revert ICoreRegistryErrorsV0.FailedTosetDeployerContract();
        }
        emit DeployerContractAdded(string(abi.encodePacked("AspenDeployer_V", _version)), _deployerContract);
    }

    /// @notice Associates the given address with the given name.
    /// @param _nameHash - Name hash of contract whose address we want to set.
    /// @param _addr - Address of the contract
    function addContract(
        bytes32 _nameHash,
        address _addr
    ) public virtual isValidContactAddress(_addr) canSetCoreRegistry(_addr) returns (bool result) {
        _contracts[_nameHash] = _addr;
        emit ContractAdded(_nameHash, _addr);
        return true;
    }

    /// @notice Associates the given address with the given name.
    /// @param _name - Name of contract whose address we want to set.
    /// @param _addr - Address of the contract
    function addContractForString(
        string calldata _name,
        address _addr
    ) public virtual isValidContactAddress(_addr) canSetCoreRegistry(_addr) returns (bool result) {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        _contracts[nameHash] = _addr;
        emit ContractForStringAdded(_name, _addr);
        return true;
    }

    /// @notice Gets address associated with the given nameHash.
    /// @param _nameHash - Name hash of contract whose address we want to look up.
    /// @return address of the contract
    /// @dev Throws if address not set.
    function getContractForOrDie(bytes32 _nameHash) public view virtual override returns (address) {
        if (_contracts[_nameHash] == address(0)) revert IRegistryErrorsV0.ContractNotFound();
        return _contracts[_nameHash];
    }

    /// @notice Gets address associated with the given nameHash.
    /// @param _nameHash - Identifier hash of contract whose address we want to look up.
    /// @return address of the contract
    function getContractFor(bytes32 _nameHash) public view virtual override returns (address) {
        return _contracts[_nameHash];
    }

    /// @notice Gets address associated with the given name.
    /// @param _name - Identifier of contract whose address we want to look up.
    /// @return address of the contract
    /// @dev Throws if address not set.
    function getContractForStringOrDie(string calldata _name) public view virtual override returns (address) {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        if (_contracts[nameHash] == address(0)) revert IRegistryErrorsV0.ContractNotFound();
        return _contracts[nameHash];
    }

    /// @notice Gets address associated with the given name.
    /// @param _name - Identifier of contract whose address we want to look up.
    /// @return address of the contract
    function getContractForString(string calldata _name) public view virtual override returns (address) {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        return _contracts[nameHash];
    }
}