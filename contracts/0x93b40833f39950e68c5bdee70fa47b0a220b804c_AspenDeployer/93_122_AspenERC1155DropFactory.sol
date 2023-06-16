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

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../api/deploy/types/DropFactoryDataTypes.sol";
import "../api/config/types/OperatorFiltererDataTypes.sol";
import "../api/deploy/IAspenDeployer.sol";
import "./AspenERC1155Drop.sol";

contract AspenERC1155DropFactory is Ownable, IDropFactoryEventsV1, ICedarImplementationVersionedV0 {
    /// ===============================================
    ///  ========== State variables - public ==========
    /// ===============================================
    AspenERC1155Drop public implementation;

    /// =============================
    /// ========== Structs ==========
    /// =============================
    struct EventParams {
        address contractAddress;
        address defaultAdmin;
        string name;
        string symbol;
        bytes32 operatorFiltererId;
        uint256 majorVersion;
        uint256 minorVersion;
        uint256 patchVersion;
    }

    constructor() {
        // Deploy the implementation contract and set implementationAddress
        implementation = new AspenERC1155Drop();

        implementation.initialize(
            IDropFactoryDataTypesV2.DropConfig(
                address(0),
                address(0),
                IGlobalConfigV1(address(0)),
                IDropFactoryDataTypesV2.TokenDetails(
                    _msgSender(),
                    "default",
                    "default",
                    "",
                    new address[](0),
                    "",
                    false
                ),
                IDropFactoryDataTypesV2.FeeDetails(address(0), address(0), 0, 0),
                IOperatorFiltererDataTypesV0.OperatorFilterer("", "", address(0), address(0))
            )
        );

        (uint256 major, uint256 minor, uint256 patch) = implementation.implementationVersion();
        emit AspenImplementationDeployed(address(implementation), major, minor, patch, "IAspenERC1155DropV3");
    }

    /// ==================================
    /// ========== Public methods ========
    /// ==================================
    function deploy(IDropFactoryDataTypesV2.DropConfig memory _dropConfig)
        external
        onlyOwner
        returns (AspenERC1155Drop newClone)
    {
        newClone = AspenERC1155Drop(Clones.clone(address(implementation)));

        newClone.initialize(_dropConfig);
        (uint256 major, uint256 minor, uint256 patch) = newClone.implementationVersion();

        EventParams memory params;

        params.name = _dropConfig.tokenDetails.name;
        params.symbol = _dropConfig.tokenDetails.symbol;
        params.defaultAdmin = _dropConfig.tokenDetails.defaultAdmin;
        params.operatorFiltererId = _dropConfig.operatorFilterer.operatorFiltererId;
        params.contractAddress = address(newClone);
        params.majorVersion = major;
        params.minorVersion = minor;
        params.patchVersion = patch;

        _emitEvent(params);
    }

    /// ===========================
    /// ========== Getters ========
    /// ===========================
    function implementationVersion()
        external
        view
        override
        returns (
            uint256 major,
            uint256 minor,
            uint256 patch
        )
    {
        return implementation.implementationVersion();
    }

    /// ===================================
    /// ========== Private methods ========
    /// ===================================
    function _emitEvent(EventParams memory params) private {
        emit DropContractDeployment(
            params.contractAddress,
            params.majorVersion,
            params.minorVersion,
            params.patchVersion,
            params.defaultAdmin,
            params.name,
            params.symbol,
            params.operatorFiltererId
        );
    }
}