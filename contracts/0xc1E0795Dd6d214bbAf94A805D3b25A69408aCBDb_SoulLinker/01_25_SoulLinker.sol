// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./libraries/Errors.sol";
import "./dex/PaymentGateway.sol";
import "./interfaces/ILinkableSBT.sol";
import "./interfaces/ISoulboundIdentity.sol";

/// @title Soul linker
/// @author Masa Finance
/// @notice Soul linker smart contract that let add links to a Soulbound token.
contract SoulLinker is PaymentGateway, EIP712, Pausable, ReentrancyGuard {
    /* ========== STATE VARIABLES =========================================== */

    ISoulboundIdentity public soulboundIdentity;

    // token => tokenId => readerIdentityId => signatureDate => LinkData
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => LinkData))))
        private _links;
    // token => tokenId => readerIdentityId
    mapping(address => mapping(uint256 => uint256[]))
        private _linkReaderIdentityIds;
    // token => tokenId => readerIdentityId => signatureDate
    mapping(address => mapping(uint256 => mapping(uint256 => uint256[])))
        private _linkSignatureDates;
    // readerIdentityId => ReaderLink
    mapping(uint256 => ReaderLink[]) private _readerLinks;

    struct LinkData {
        bool exists;
        uint256 ownerIdentityId;
        uint256 expirationDate;
        bool isRevoked;
    }

    struct ReaderLink {
        address token;
        uint256 tokenId;
        uint256 signatureDate;
    }

    struct LinkKey {
        uint256 readerIdentityId;
        uint256 signatureDate;
    }

    /* ========== INITIALIZE ================================================ */

    /// @notice Creates a new soul linker
    /// @param admin Administrator of the smart contract
    /// @param _soulboundIdentity Soulbound identity smart contract
    /// @param paymentParams Payment gateway params
    constructor(
        address admin,
        ISoulboundIdentity _soulboundIdentity,
        PaymentParams memory paymentParams
    ) EIP712("SoulLinker", "1.0.0") PaymentGateway(admin, paymentParams) {
        if (address(_soulboundIdentity) == address(0)) revert ZeroAddress();

        soulboundIdentity = _soulboundIdentity;
    }

    /* ========== RESTRICTED FUNCTIONS ====================================== */

    /// @notice Sets the SoulboundIdentity contract address linked to this soul name
    /// @dev The caller must have the admin role to call this function
    /// @param _soulboundIdentity Address of the SoulboundIdentity contract
    function setSoulboundIdentity(ISoulboundIdentity _soulboundIdentity)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (address(_soulboundIdentity) == address(0)) revert ZeroAddress();
        if (soulboundIdentity == _soulboundIdentity) revert SameValue();
        soulboundIdentity = _soulboundIdentity;
    }

    /// @notice Pauses the smart contract
    /// @dev The caller must have the admin role to call this function
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpauses the smart contract
    /// @dev The caller must have the admin role to call this function
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /* ========== MUTATIVE FUNCTIONS ======================================== */

    /// @notice Stores the link, validating the signature of the given read link request
    /// @dev The token must be linked to this soul linker
    /// @param readerIdentityId Id of the identity of the reader
    /// @param ownerIdentityId Id of the identity of the owner of the SBT
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param signatureDate Signature date of the signature
    /// @param expirationDate Expiration date of the signature
    /// @param signature Signature of the read link request made by the owner
    function addLink(
        address paymentMethod,
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        uint256 signatureDate,
        uint256 expirationDate,
        bytes calldata signature
    ) external payable whenNotPaused nonReentrant {
        address ownerAddress = soulboundIdentity.ownerOf(ownerIdentityId);
        address readerAddress = soulboundIdentity.ownerOf(readerIdentityId);
        address tokenOwner = IERC721Enumerable(token).ownerOf(tokenId);

        if (ownerAddress != tokenOwner)
            revert IdentityOwnerNotTokenOwner(tokenId, ownerIdentityId);
        if (readerAddress != _msgSender()) revert CallerNotReader(_msgSender());
        if (ownerIdentityId == readerIdentityId)
            revert IdentityOwnerIsReader(readerIdentityId);
        if (signatureDate == 0) revert InvalidSignatureDate(signatureDate);
        if (expirationDate < block.timestamp)
            revert ValidPeriodExpired(expirationDate);
        if (_links[token][tokenId][readerIdentityId][signatureDate].exists)
            revert LinkAlreadyExists(
                token,
                tokenId,
                readerIdentityId,
                signatureDate
            );
        if (
            !_verify(
                _hash(
                    readerIdentityId,
                    ownerIdentityId,
                    token,
                    tokenId,
                    signatureDate,
                    expirationDate
                ),
                signature,
                ownerAddress
            )
        ) revert InvalidSignature();

        _pay(paymentMethod, getPriceForAddLink(paymentMethod, token));

        // token => tokenId => readerIdentityId => signatureDate => LinkData
        _links[token][tokenId][readerIdentityId][signatureDate] = LinkData(
            true,
            ownerIdentityId,
            expirationDate,
            false
        );
        if (_linkSignatureDates[token][tokenId][readerIdentityId].length == 0) {
            _linkReaderIdentityIds[token][tokenId].push(readerIdentityId);
        }
        _linkSignatureDates[token][tokenId][readerIdentityId].push(
            signatureDate
        );
        _readerLinks[readerIdentityId].push(
            ReaderLink(token, tokenId, signatureDate)
        );

        emit LinkAdded(
            readerIdentityId,
            ownerIdentityId,
            token,
            tokenId,
            signatureDate,
            expirationDate
        );
    }

    /// @notice Revokes the link
    /// @dev The links can be revoked, wether the token is linked or not.
    /// The caller must be the owner of the token.
    /// The owner of the token can revoke a link even if the reader has not added it yet.
    /// @param readerIdentityId Id of the identity of the reader
    /// @param ownerIdentityId Id of the identity of the owner of the SBT
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param signatureDate Signature date of the signature
    function revokeLink(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        uint256 signatureDate
    ) external whenNotPaused {
        address ownerAddress = soulboundIdentity.ownerOf(ownerIdentityId);
        address tokenOwner = IERC721Enumerable(token).ownerOf(tokenId);

        if (ownerAddress != tokenOwner)
            revert IdentityOwnerNotTokenOwner(tokenId, ownerIdentityId);
        if (ownerAddress != _msgSender()) revert CallerNotOwner(_msgSender());
        if (ownerIdentityId == readerIdentityId)
            revert IdentityOwnerIsReader(readerIdentityId);
        if (_links[token][tokenId][readerIdentityId][signatureDate].isRevoked)
            revert LinkAlreadyRevoked();

        if (_links[token][tokenId][readerIdentityId][signatureDate].exists) {
            // token => tokenId => readerIdentityId => signatureDate => LinkData
            _links[token][tokenId][readerIdentityId][signatureDate]
                .isRevoked = true;
        } else {
            // if the link doesn't exist, store it
            // token => tokenId => readerIdentityId => signatureDate => LinkData
            _links[token][tokenId][readerIdentityId][signatureDate] = LinkData(
                true,
                ownerIdentityId,
                0,
                true
            );
            if (
                _linkSignatureDates[token][tokenId][readerIdentityId].length ==
                0
            ) {
                _linkReaderIdentityIds[token][tokenId].push(readerIdentityId);
            }
            _linkSignatureDates[token][tokenId][readerIdentityId].push(
                signatureDate
            );
            _readerLinks[readerIdentityId].push(
                ReaderLink(token, tokenId, signatureDate)
            );
        }

        emit LinkRevoked(
            readerIdentityId,
            ownerIdentityId,
            token,
            tokenId,
            signatureDate
        );
    }

    /* ========== VIEWS ===================================================== */

    /// @notice Returns the identityId owned by the given token
    /// @dev The token must be linked to this soul linker
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @return Id of the identity
    function getIdentityId(address token, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        address owner = IERC721Enumerable(token).ownerOf(tokenId);
        return soulboundIdentity.tokenOfOwner(owner);
    }

    /// @notice Returns the list of connected SBTs by a given SBT token
    /// @param identityId Id of the identity
    /// @param token Address of the SBT contract
    /// @return List of connected SBTs
    function getSBTConnections(uint256 identityId, address token)
        external
        view
        returns (uint256[] memory)
    {
        address owner = soulboundIdentity.ownerOf(identityId);

        return getSBTConnections(owner, token);
    }

    /// @notice Returns the list of connected SBTs by a given SBT token
    /// @param owner Address of the owner of the identity
    /// @param token Address of the SBT contract
    /// @return List of connectec SBTs
    function getSBTConnections(address owner, address token)
        public
        view
        returns (uint256[] memory)
    {
        uint256 connections = IERC721Enumerable(token).balanceOf(owner);
        uint256[] memory sbtConnections = new uint256[](connections);
        for (uint256 i = 0; i < connections; i++) {
            sbtConnections[i] = IERC721Enumerable(token).tokenOfOwnerByIndex(
                owner,
                i
            );
        }

        return sbtConnections;
    }

    /// @notice Returns the list of link signature dates for a given SBT token and reader
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @return List of linked SBTs
    function getLinks(address token, uint256 tokenId)
        public
        view
        returns (LinkKey[] memory)
    {
        uint256 nLinkKeys = 0;
        for (
            uint256 i = 0;
            i < _linkReaderIdentityIds[token][tokenId].length;
            i++
        ) {
            uint256 readerIdentityId = _linkReaderIdentityIds[token][tokenId][
                i
            ];
            for (
                uint256 j = 0;
                j <
                _linkSignatureDates[token][tokenId][readerIdentityId].length;
                j++
            ) {
                nLinkKeys++;
            }
        }

        LinkKey[] memory linkKeys = new LinkKey[](nLinkKeys);
        uint256 n = 0;
        for (
            uint256 i = 0;
            i < _linkReaderIdentityIds[token][tokenId].length;
            i++
        ) {
            uint256 readerIdentityId = _linkReaderIdentityIds[token][tokenId][
                i
            ];
            for (
                uint256 j = 0;
                j <
                _linkSignatureDates[token][tokenId][readerIdentityId].length;
                j++
            ) {
                uint256 signatureDate = _linkSignatureDates[token][tokenId][
                    readerIdentityId
                ][j];
                linkKeys[n].readerIdentityId = readerIdentityId;
                linkKeys[n].signatureDate = signatureDate;
                n++;
            }
        }
        return linkKeys;
    }

    /// @notice Returns the list of link signature dates for a given SBT token and reader
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param readerIdentityId Id of the identity of the reader of the SBT
    /// @return List of linked SBTs
    function getLinkSignatureDates(
        address token,
        uint256 tokenId,
        uint256 readerIdentityId
    ) external view returns (uint256[] memory) {
        return _linkSignatureDates[token][tokenId][readerIdentityId];
    }

    /// @notice Returns the information of link dates for a given SBT token and reader
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param readerIdentityId Id of the identity of the reader of the SBT
    /// @param signatureDate Signature date of the signature
    /// @return linkData List of linked SBTs
    function getLinkInfo(
        address token,
        uint256 tokenId,
        uint256 readerIdentityId,
        uint256 signatureDate
    ) external view returns (LinkData memory) {
        return _links[token][tokenId][readerIdentityId][signatureDate];
    }

    /// @notice Returns the list of links for a given reader identity id
    /// @param readerIdentityId Id of the identity of the reader of the SBT
    /// @return List of links for the reader
    function getReaderLinks(uint256 readerIdentityId)
        public
        view
        returns (ReaderLink[] memory)
    {
        return _readerLinks[readerIdentityId];
    }

    /// @notice Validates the link of the given read link request and returns the
    /// data that reader can read if the link is valid
    /// @dev The token must be linked to this soul linker
    /// @param readerIdentityId Id of the identity of the reader
    /// @param ownerIdentityId Id of the identity of the owner of the SBT
    /// @param token Address of the SBT contract
    /// @param tokenId Id of the token
    /// @param signatureDate Signature date of the signature
    /// @return True if the link is valid
    function validateLink(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        uint256 signatureDate
    ) external view returns (bool) {
        address ownerAddress = soulboundIdentity.ownerOf(ownerIdentityId);
        address tokenOwner = IERC721Enumerable(token).ownerOf(tokenId);

        LinkData memory link = _links[token][tokenId][readerIdentityId][
            signatureDate
        ];

        if (ownerAddress != tokenOwner)
            revert IdentityOwnerNotTokenOwner(tokenId, ownerIdentityId);
        if (!link.exists) revert LinkDoesNotExist();
        if (link.expirationDate < block.timestamp)
            revert ValidPeriodExpired(link.expirationDate);
        if (link.isRevoked) revert LinkAlreadyRevoked();

        return true;
    }

    /// @notice Returns the price for storing a link
    /// @dev Returns the current pricing for storing a link
    /// @param paymentMethod Address of token that user want to pay
    /// @param token Token that user want to store link
    /// @return Current price for storing a link
    function getPriceForAddLink(address paymentMethod, address token)
        public
        view
        returns (uint256)
    {
        uint256 addLinkPrice = ILinkableSBT(token).addLinkPrice();
        uint256 addLinkPriceMASA = ILinkableSBT(token).addLinkPriceMASA();
        if (addLinkPrice == 0 && addLinkPriceMASA == 0) {
            return 0;
        } else if (
            paymentMethod == masaToken &&
            enabledPaymentMethod[paymentMethod] &&
            addLinkPriceMASA > 0
        ) {
            // price in MASA without conversion rate
            return addLinkPriceMASA;
        } else if (
            paymentMethod == stableCoin && enabledPaymentMethod[paymentMethod]
        ) {
            // stable coin
            return addLinkPrice;
        } else if (enabledPaymentMethod[paymentMethod]) {
            // ETH and ERC 20 token
            return _convertFromStableCoin(paymentMethod, addLinkPrice);
        } else {
            revert InvalidPaymentMethod(paymentMethod);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========================================= */

    function _hash(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        uint256 signatureDate,
        uint256 expirationDate
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "Link(uint256 readerIdentityId,uint256 ownerIdentityId,address token,uint256 tokenId,uint256 signatureDate,uint256 expirationDate)"
                        ),
                        readerIdentityId,
                        ownerIdentityId,
                        token,
                        tokenId,
                        signatureDate,
                        expirationDate
                    )
                )
            );
    }

    function _verify(
        bytes32 digest,
        bytes memory signature,
        address owner
    ) internal pure returns (bool) {
        return ECDSA.recover(digest, signature) == owner;
    }

    /* ========== MODIFIERS ================================================= */

    /* ========== EVENTS ==================================================== */

    event LinkAdded(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        uint256 signatureDate,
        uint256 expirationDate
    );

    event LinkRevoked(
        uint256 readerIdentityId,
        uint256 ownerIdentityId,
        address token,
        uint256 tokenId,
        uint256 signatureDate
    );
}