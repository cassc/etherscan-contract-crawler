// SPDX-License-Identifier: Apache 2.0

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

/// ========== External imports ==========
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import "../drop/lib/CurrencyTransferLib.sol";
import "../api/errors/IUUPSUpgradeableErrors.sol";
import "../api/errors/IPaymentsErrors.sol";
import "../generated/impl/BaseAspenPaymentsNotaryV1.sol";
import "./extension/PaymentsNotary.sol";

/// @title AspenPaymentsNotary
/// @notice This smart contract acts as the Aspen notary for payments. It is responsible for keeping track of payments
///         by emitting an event when a payment happens. No funds are stored on this contract.
contract AspenPaymentsNotary is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    BaseAspenPaymentsNotaryV1,
    PaymentsNotary
{
    using ERC165CheckerUpgradeable for address;

    function initialize(address _feeReceiver, uint256 _feeBPS) public initializer {
        __UUPSUpgradeable_init();
        __PaymentsNotary_init(_feeReceiver, _feeBPS);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function _authorizeUpgrade(address _newImplementation) internal view override onlyRole(DEFAULT_ADMIN_ROLE) {
        (uint256 major, uint256 minor, uint256 patch) = this.implementationVersion();
        if (!_newImplementation.supportsInterface(type(IAspenVersionedV2).interfaceId)) {
            revert IUUPSUpgradeableErrorsV0.ImplementationNotVersioned(_newImplementation);
        }
        (uint256 newMajor, uint256 newMinor, uint256 newPatch) = IAspenVersionedV2(_newImplementation)
            .implementationVersion();
        // Do not permit a breaking change via an UUPS proxy upgrade - this requires a new proxy. Otherwise, only allow
        // minor/patch versions to increase
        if (major != newMajor || minor > newMinor || (minor == newMinor && patch > newPatch)) {
            revert IUUPSUpgradeableErrorsV0.IllegalVersionUpgrade(major, minor, patch, newMajor, newMinor, newPatch);
        }
    }

     /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, BaseAspenPaymentsNotaryV1)
        returns (bool)
    {
        return BaseAspenPaymentsNotaryV1.supportsInterface(interfaceId) || 
        AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function minorVersion() public pure virtual override returns (uint256 minor, uint256 patch) {
        minor = 0;
        patch = 0;
    }
}