// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

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

//  ==========  External imports    ==========
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "./extension/operatorFilterer/UpdateableDefaultOperatorFiltererUpgradeable.sol";
/// ========== Features ==========
import "./openzeppelin-presets/metatx/ERC2771ContextUpgradeable.sol";

import "./types/DropERC1155DataTypes.sol";
import "../terms/types/TermsDataTypes.sol";

import "./AspenERC1155DropLogic.sol";
import "../terms/lib/TermsLogic.sol";
import "../api/issuance/IDropClaimCondition.sol";
import "../api/errors/IDropErrors.sol";
import "../api/config/IGlobalConfig.sol";

abstract contract AspenERC1155DropStorage is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC1155Upgradeable,
    EIP712Upgradeable,
    UpdateableDefaultOperatorFiltererUpgradeable
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using TermsLogic for TermsDataTypes.Terms;
    using AspenERC1155DropLogic for DropERC1155DataTypes.ClaimData;

    /// ===============================================
    /// =========== State variables - public ==========
    /// ===============================================
    // FIXME: TRANSFER_ROLE is duplicated on AspenERC1155DropLogic (since we wish to access it from this contract externally)
    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only ISSUER_ROLE holders can issue NFTs.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    /// @dev Offset for token IDs.
    uint8 public constant TOKEN_INDEX_OFFSET = 1;
    /// @dev If true, users cannot claim.
    bool public claimIsPaused = false;

    /// @dev The address that receives all primary sales value.
    address public _primarySaleRecipient;
    /// @dev Token name
    string public __name;
    /// @dev Token symbol
    string public __symbol;
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address public _owner;
    /// @dev Contract level metadata.
    string public _contractUri;

    /// @dev Mapping from 'Largest tokenId of a batch of tokens with the same baseURI'
    ///         to base URI for the respective batch of tokens.
    mapping(uint256 => string) public baseURI;

    /// @dev address of delegate logic contract
    address public delegateLogicContract;
    /// @dev global Aspen config
    IGlobalConfigV0 public aspenConfig;

    /// @dev enable/disable operator filterer.
    // bool public operatorFiltererEnabled;
    // address public defaultSubscription;
    // address public operatorFilterRegistry;

    bytes32 public constant MESSAGE_HASH =
        keccak256("AcceptTerms(address acceptor,string termsURI,uint8 termsVersion)");

    struct AcceptTerms {
        address acceptor;
        string termsURI;
        uint8 termsVersion;
    }

    DropERC1155DataTypes.ClaimData claimData;
    TermsDataTypes.Terms termsData;

    modifier isValidTokenId(uint256 _tokenId) {
        if (_tokenId <= 0) revert IDropErrorsV0.InvalidTokenId(_tokenId);
        _;
    }

    /// @dev See ERC 165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /// @dev See {ERC1155-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        AspenERC1155DropLogic.beforeTokenTransfer(claimData, termsData, this, from, to, ids, amounts);
    }

    function _canSetOperatorRestriction() internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return true;
    }

    /// ======================================
    /// =========== Miscellaneous ============
    /// ======================================
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }
}