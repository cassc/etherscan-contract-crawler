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

    struct ChargebackProtectionDetails {
        uint256 quantity;
        uint256 withdrawnQuantity;
        uint256 transferableAt;
    }

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
    /// @dev Time in seconds for chargeback protection
    uint256 public chargebackProtectionPeriod;

    /// @dev Issue buffer size per wallet address per token id
    mapping(address => mapping(uint256 => uint256)) public issueBufferSize;
    /// @dev chargeback protection details per wallet address per token id
    mapping(address => mapping(uint256 => mapping(uint256 => ChargebackProtectionDetails))) public embargoedTokens;

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
    /// @dev address of restricted logic contract
    address public restrictedLogicContract;
    /// @dev global Aspen config
    IGlobalConfigV1 public aspenConfig;

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
        AspenERC1155DropLogic.beforeTokenTransfer(claimData, termsData, from, to, ids, amounts);
    }

    function _canSetOperatorRestriction() internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        return true;
    }

    /// @dev See {ERC1155-_safeTransferFrom}.
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        // In case the token is not transferrable, we only allow transfers to any address with ISSUER_ROLE.
        // This is to make sure we allow the ISSUER to withdraw the token if needed.
        (bool canTransfer, uint256 transferTimestamp) = _canTransfer(from, id, amount);
        if (!canTransfer && !hasRole(ISSUER_ROLE, to))
            revert IDropErrorsV1.ChargebackProtectedTransferNotAvailable(transferTimestamp, block.timestamp);
        super._safeTransferFrom(from, to, id, amount, data);
    }

    /// @dev See {ERC1155-_safeBatchTransferFrom}.
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        for (uint256 i = 0; i < ids.length; ++i) {
            (bool canTransfer, uint256 transferTimestamp) = _canTransfer(from, ids[i], amounts[i]);
            if (!canTransfer && !hasRole(ISSUER_ROLE, to))
                revert IDropErrorsV1.ChargebackProtectedTransferNotAvailable(transferTimestamp, block.timestamp);
        }
        super._safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /// @dev Checks if a transfer can take place.
    ///     Any tokens claimed (not issued) can be transferred right away while any tokens issued
    ///     can only be transferred when the chargeback protection period in the past - see _getTransferTimesForToken()
    ///     It also trims the issueBufferSize - see _getTransferTimesForToken()
    function _canTransfer(
        address _holder,
        uint256 _tokenId,
        uint256 _quantity
    ) internal returns (bool, uint256) {
        uint256 tokensAvailableForTransfer = 0;
        uint256 timestampAvailableForTransfer = 0;
        (
            uint256[] memory quantityOfTokens,
            uint256[] memory transferableAt,
            uint256 largestActiveSlotId
        ) = _getTransferTimesForToken(_tokenId, _holder);

        for (uint256 i = 0; i < quantityOfTokens.length; i += 1) {
            if (block.timestamp >= transferableAt[i]) {
                tokensAvailableForTransfer = tokensAvailableForTransfer + quantityOfTokens[i];
            }
            // We return the next available timestamp that a transfer can take place
            if (timestampAvailableForTransfer == 0 || timestampAvailableForTransfer > transferableAt[i]) {
                timestampAvailableForTransfer = transferableAt[i];
            }
        }
        issueBufferSize[_holder][_tokenId] = largestActiveSlotId;

        return (tokensAvailableForTransfer >= _quantity, timestampAvailableForTransfer);
    }

    /// @dev Returns the transfer times for a token and a token owner. This method returns 2 arrays and the largest active slot id:
    ///     First one is the quantity of tokens and second one is the timestamps on which the respective
    ///     quantity of first array can be transferred. The first item of the array always returns the tokens
    ///     that are available for trasfer immediatly, either because they were claimed or because the chargeback
    ///     protection period is in the past.
    ///     The largest slot id is the slot id from the issueBufferSize that is still active and is used for trimming
    ///     the issueBufferSize for reduced gas costs. See example below on how it works:
    ///     ====================================================
    ///     o is expired, x is active
    ///     [o x o x x x x o x o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o]
    ///     can be trimmed to --> [o x o x x x x o x ]
    ///     BUT
    ///     [o x o x x x x o x o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o o x]
    ///     CANNOT be trimmed
    ///     ====================================================
    /// @return quantityOfTokens - array with quantity of tokens
    /// @return transferableAt - array with timestamps at which the respective quantity from first array can be transferred
    /// @return largestActiveSlotId - slot Id from issueBufferSize that is still active, i.e. transferableAt is in the future
    function _getTransferTimesForToken(uint256 _tokenId, address _tokenOwner)
        internal
        view
        returns (
            uint256[] memory quantityOfTokens,
            uint256[] memory transferableAt,
            uint256 largestActiveSlotId
        )
    {
        //
        uint256 _largestActiveSlotId = 0;
        // We get the issue counter
        uint256 _issueBufferSize = issueBufferSize[_tokenOwner][_tokenId];
        // We initiate the return objects
        uint256[] memory _quantityOfTokens = new uint256[](_issueBufferSize + 1);
        uint256[] memory _tokenTransferableAt = new uint256[](_issueBufferSize + 1);

        uint256 totalUntransferrableQuantity = 0;
        // We start from 1 as we want to keep the returns for index 0 to be whatever
        // tokens can be transferred (either claimed or issued but transferableAt is in the past)
        for (uint256 i = 1; i <= _issueBufferSize; i += 1) {
            uint256 _transferableAt = embargoedTokens[_tokenOwner][_tokenId][i].transferableAt;
            // We only care for tokens that their transferableAt timestamp is in the past
            if (_transferableAt > block.timestamp) {
                // The quantity is always the tokens issued minus any tokens that might have been withdrawn
                uint256 _quantity = embargoedTokens[_tokenOwner][_tokenId][i].quantity -
                    embargoedTokens[_tokenOwner][_tokenId][i].withdrawnQuantity;
                _quantityOfTokens[i] = _quantity;
                _tokenTransferableAt[i] = _transferableAt;
                totalUntransferrableQuantity = totalUntransferrableQuantity + _quantity;
                _largestActiveSlotId = i;
            }
        }
        _quantityOfTokens[0] = balanceOf(_tokenOwner, _tokenId) - totalUntransferrableQuantity;
        _tokenTransferableAt[0] = 0;

        return (_quantityOfTokens, _tokenTransferableAt, _largestActiveSlotId);
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