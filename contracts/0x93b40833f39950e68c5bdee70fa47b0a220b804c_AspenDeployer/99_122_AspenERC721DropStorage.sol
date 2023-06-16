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

/// ========== External imports ==========
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
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

import "./types/DropERC721DataTypes.sol";
import "../terms/types/TermsDataTypes.sol";

import "./AspenERC721DropLogic.sol";
import "../terms/lib/TermsLogic.sol";

import "../api/issuance/IDropClaimCondition.sol";
import "../api/metadata/IContractMetadata.sol";
import "../api/royalties/IRoyalty.sol";
import "../api/ownable/IOwnable.sol";
import "../api/errors/IDropErrors.sol";
import "../api/config/IGlobalConfig.sol";

abstract contract AspenERC721DropStorage is
    Initializable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    EIP712Upgradeable,
    UpdateableDefaultOperatorFiltererUpgradeable
{
    /// ================================
    /// =========== Libraries ==========
    /// ================================
    using StringsUpgradeable for uint256;
    using AspenERC721DropLogic for DropERC721DataTypes.ClaimData;
    using TermsLogic for TermsDataTypes.Terms;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// ===============================================
    /// =========== State variables - public ==========
    /// ===============================================
    /// @dev Only MINTER_ROLE holders can lazy mint NFTs.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    /// @dev Only ISSUER_ROLE holders can issue NFTs.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    /// @dev Offset for token IDs.
    uint8 public constant TOKEN_INDEX_OFFSET = 1;
    /// @dev If true, users cannot claim.
    bool public claimIsPaused = false;
    /// @dev Indicates if a token is SBT (Soul-Bound Token).
    bool public isSBT;

    /// @dev Token name
    string public __name;
    /// @dev Token symbol
    string public __symbol;
    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address public _owner;
    /// @dev Contract level metadata.
    string public _contractUri;

    /// @dev Token ID => timestamp of when the token can be transfered
    mapping(uint256 => uint256) public transferableAt;
    /// @dev Time in seconds for chargeback protection
    uint256 public chargebackProtectionPeriod;

    /// @dev address of delegate logic contract
    address public delegateLogicContract;
    /// @dev address of restricted logic contract
    address public restrictedLogicContract;
    /// @dev global Aspen config
    IGlobalConfigV1 public aspenConfig;

    bytes32 public constant MESSAGE_HASH =
        keccak256("AcceptTerms(address acceptor,string termsURI,uint8 termsVersion)");

    struct AcceptTerms {
        address acceptor;
        string termsURI;
        uint8 termsVersion;
    }

    DropERC721DataTypes.ClaimData claimData;
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
        override(ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /// @dev See {ERC721-_transfer}.
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // We check if the token is transferable, i.e. if the transferableAt timestamp is in the past.
        // In case the token is not transferrable, we only allow transfers to any address with ISSUER_ROLE.
        // The latter is to make sure we allow the ISSUER to withdraw the token if needed.
        if (transferableAt[tokenId] > block.timestamp && !hasRole(ISSUER_ROLE, to))
            revert IDropErrorsV1.ChargebackProtectedTransferNotAvailable(transferableAt[tokenId], block.timestamp);
        super._transfer(from, to, tokenId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        if (to != address(this)) {
            if (
                termsData.termsActivated &&
                (from != address(0x0000000000000000000000000000000000000001) ||
                    to != address(0x0000000000000000000000000000000000000001))
            ) {
                if (!termsData.termsAccepted[to] || termsData.termsVersion != termsData.acceptedVersion[to])
                    revert IDropErrorsV0.TermsNotAccepted(to, termsData.termsURI, termsData.termsVersion);
            }
        }
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