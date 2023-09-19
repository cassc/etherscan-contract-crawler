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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "../api/errors/IUUPSUpgradeableErrors.sol";
import "../generated/impl/BaseAspenCoreRegistryV1.sol";
import "./config/TieredPricingUpgradeable.sol";
import "./config/OperatorFiltererConfig.sol";
import "./CoreRegistry.sol";

contract AspenCoreRegistry is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    CoreRegistry,
    TieredPricingUpgradeable,
    OperatorFiltererConfig,
    BaseAspenCoreRegistryV1
{
    using ERC165CheckerUpgradeable for address;

    function initialize(address _platformFeeReceiver) public virtual initializer {
        __TieredPricingUpgradeable_init(_platformFeeReceiver);
        super._addOperatorFilterer(
            IOperatorFiltererDataTypesV0.OperatorFilterer(
                keccak256(abi.encodePacked("NO_OPERATOR")),
                "No Operator",
                address(0),
                address(0)
            )
        );

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @dev See ERC 165
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(BaseAspenCoreRegistryV1, AccessControlUpgradeable) returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            BaseAspenCoreRegistryV1.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /// ===================================
    /// ========== Tiered Pricing =========
    /// ===================================
    function setPlatformFeeReceiver(address _platformFeeReceiver) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPlatformFeeReceiver(_platformFeeReceiver);
    }

    function setDefaultTier(bytes32 _namespace, bytes32 _tierId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultTier(_namespace, _tierId);
    }

    function addTier(
        bytes32 _namespace,
        ITieredPricingDataTypesV0.Tier calldata _tierDetails
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _addTier(_namespace, _tierDetails);
    }

    function updateTier(
        bytes32 _namespace,
        bytes32 _tierId,
        ITieredPricingDataTypesV0.Tier calldata _tierDetails
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _updateTier(_namespace, _tierId, _tierDetails);
    }

    function removeTier(bytes32 _namespace, bytes32 _tierId) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeTier(_namespace, _tierId);
    }

    function addAddressToTier(
        bytes32 _namespace,
        address _account,
        bytes32 _tierId
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _addAddressToTier(_namespace, _account, _tierId);
    }

    function removeAddressFromTier(bytes32 _namespace, address _account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _removeAddressFromTier(_namespace, _account);
    }

    /// ========================================
    /// ========== Operator Filterers ==========
    /// ========================================
    function addOperatorFilterer(
        IOperatorFiltererDataTypesV0.OperatorFilterer memory _newOperatorFilterer
    )
        public
        override(IOperatorFiltererConfigV0, OperatorFiltererConfig)
        isValidOperatorConfig(_newOperatorFilterer)
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        super._addOperatorFilterer(_newOperatorFilterer);
    }

    /// ========================================
    /// ============ Core Registry =============
    /// ========================================
    function addContract(
        bytes32 _nameHash,
        address _addr
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool result) {
        return super.addContract(_nameHash, _addr);
    }

    function addContractForString(
        string calldata _name,
        address _addr
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool result) {
        return super.addContractForString(_name, _addr);
    }

    function setConfigContract(
        address _configContract,
        string calldata _version
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.setConfigContract(_configContract, _version);
    }

    function setDeployerContract(
        address _deployerContract,
        string calldata _version
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.setDeployerContract(_deployerContract, _version);
    }

    // Concrete implementation semantic version - provided for completeness but not designed to be the point of dispatch
    function minorVersion() public pure virtual override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }
}