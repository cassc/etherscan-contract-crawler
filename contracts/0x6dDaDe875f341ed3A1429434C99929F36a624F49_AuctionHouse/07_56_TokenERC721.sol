// SPDX-License-Identifier: Apache-2.0
// @Kairos V1.0

pragma solidity ^0.8.11;

import "../lib/Constants.sol";
import "../lib/Roles.sol";
import "../lib/CommonErrors.sol";
import "../lib/TokenErrors.sol";

// Interface
import { ITokenERC721 } from "../interfaces/token/ITokenERC721.sol";

import "../interfaces/IThirdwebContract.sol";
import "../extension/interface/IPlatformFee.sol";
import "../extension/interface/IPrimarySale.sol";
import "../extension/interface/IRoyalty.sol";
import "../extension/interface/IOwnable.sol";

// Token
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

// Signature utils
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

// Access Control + security
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// Utils
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../lib/CurrencyTransferLib.sol";
import "../lib/FeeType.sol";

// Helper interfaces
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

struct CollectionSettings {
  address defaultAdmin;
  string name;
  string symbol;
  string contractURI;
  address saleRecipient;
  address royaltyRecipient;
  uint128 royaltyBps;
  uint128 platformFeeBps;
  address platformFeeRecipient;
}

struct TransferFromRequest {
    address from;
    address to;
    uint256 tokenId;
}

struct FiatMintRequest {
    address to;
    string uri;
    bytes32 uid;
}

contract TokenERC721 is
    Initializable,
    IThirdwebContract,
    IOwnable,
    IRoyalty,
    IPrimarySale,
    IPlatformFee,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ITokenERC721
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    bytes32 private constant MODULE_TYPE = bytes32("TokenERC721");
    uint256 private constant VERSION = 1;

    bytes32 private constant TYPEHASH_TRANSFER_FROM =
        keccak256(
            "TransferFromRequest(address from,address to,uint256 tokenId)"
        );
    bytes32 private constant TYPEHASH =
        keccak256(
            "MintRequest(address to,string uri,uint256 price,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev The token ID of the next token to mint.
    uint256 public nextTokenIdToMint;

    /// @dev The adress that receives all primary sales value.
    address public primarySaleRecipient;

    /// @dev The adress that receives all primary sales value.
    address public platformFeeRecipient;

    /// @dev The recipient of who gets the royalty.
    address private royaltyRecipient;

    /// @dev The percentage of royalty how much royalty in basis points.
    uint128 private royaltyBps;

    /// @dev The % of primary sales collected by the contract as fees.
    uint128 public platformFeeBps;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    mapping(bytes32 => bool) private minted;

    /// @dev Mapping from tokenId => URI
    mapping(uint256 => string) private uri;

    event Kairos_TokenURIChanged(uint256 tokenId, string uri);
    event Kairos_FiatMint(address to, string uri, uint256 tokenId, bytes32 mintId);
    event Kairos_SignatureTransfer(address from, address to, uint256 tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @dev Initiliazes the contract, like a constructor.
    function initialize(CollectionSettings calldata _st) external initializer {
        // Initialize inherited contracts, most base-like -> most derived.
        __ReentrancyGuard_init();
        __EIP712_init("TokenERC721", "1");
        __ERC721_init(_st.name, _st.symbol);

        // Initialize this contract's state.
        royaltyRecipient = _st.royaltyRecipient;
        royaltyBps = _st.royaltyBps;
        platformFeeRecipient = _st.platformFeeRecipient;
        primarySaleRecipient = _st.saleRecipient;
        contractURI = _st.contractURI;
        platformFeeBps = _st.platformFeeBps;

        _owner = _st.defaultAdmin;
        _setupRole(DEFAULT_ADMIN_ROLE, _st.defaultAdmin);
        _setupRole(MINTER_ROLE, _st.defaultAdmin);
        _setupRole(TRANSFER_ROLE, _st.defaultAdmin);
        _setupRole(TRANSFER_ROLE, address(0));
    }

    ///     =====   Public functions  =====

    /// @dev Returns the module type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev Verifies that a mint request is signed by an account holding DEFAULT_ADMIN_ROLE (at the time of the function call).
    function verify(MintRequest calldata _req, bytes calldata _signature) public view returns (bool, address) {
        address signer = recoverAddress(_req, _signature);
        return (!minted[_req.uid] && hasRole(DEFAULT_ADMIN_ROLE, signer), signer);
    }

    /// @dev Returns the URI for a tokenId
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return uri[_tokenId];
    }

    /// @dev Lets an account with MINTER_ROLE mint an NFT.
    function mintTo(address _to, string calldata _uri) external onlyRole(MINTER_ROLE) returns (uint256) {
        // `_mintTo` is re-used. `mintTo` just adds a minter role check.
        return _mintTo(_to, _uri);
    }

    ///     =====   External functions  =====

    /// @dev See EIP-2981
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyRecipient;
        royaltyAmount = (salePrice * royaltyBps) / MAX_BPS;
    }

    ///   =====   Kairos functions  =====

    /// @dev Returns the address of the signer of the transfer request.
    function recoverAddressTransferFrom(TransferFromRequest calldata _req, bytes calldata _signature) 
        private view returns (address) 
    {
        return _hashTypedDataV4(keccak256(_encodeRequestTransferFrom(_req))).recover(_signature);
    }

    /// @dev Resolves 'stack too deep' error in `recoverAddressTransferFrom`.
    function _encodeRequestTransferFrom(TransferFromRequest calldata _req) 
        private pure returns (bytes memory) 
    {
        return
            abi.encode(
                TYPEHASH_TRANSFER_FROM,
                _req.from,
                _req.to,
                _req.tokenId
            );
    }

    /**
     * Allow transfers approved from a trusted source
     * @dev See {IERC721-transferFrom}.
     */
    function signatureTransferFrom(TransferFromRequest calldata _req, bytes calldata _signature) 
        external 
    {
        address signer = recoverAddressTransferFrom(_req, _signature);
        if (!hasRole(DEFAULT_ADMIN_ROLE, signer)) {
            revert InvalidSignature(signer);
        }

        _safeTransfer(_req.from, _req.to, _req.tokenId, '');
        emit Kairos_SignatureTransfer(_req.from, _req.to, _req.tokenId);
    }

    /// @dev This is a mint to function with a signature mint uid check
    function _fiatMint (FiatMintRequest calldata _req)        
        internal
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        if (minted[_req.uid]) {
            revert AlreadyMinted(_req.uid);
        }
        minted[_req.uid] = true;
        uint256 id = _mintTo(_req.to, _req.uri);
        emit Kairos_FiatMint(_req.to, _req.uri, id, _req.uid);
        return id;
    }

    /// @dev This is a mint to function with a signature mint uid check
    function fiatMint (FiatMintRequest calldata _req)        
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
       return _fiatMint(_req);
    }

    /// @dev This is a mint to function with a signature mint uid check
    /// accepts an array of mints, mints the first one possible
    function tryFiatMint (FiatMintRequest[] calldata _reqArray)        
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (uint256)
    {
        for (uint i=0; i < _reqArray.length; i++) {
            if (minted[_reqArray[i].uid]) {
                continue;
            }
            return _fiatMint(_reqArray[i]);
        }
        revert MintChoicesMinted();
    }

    function multiFiatMint (FiatMintRequest[] calldata _reqArray, bool revertOnFail)        
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint i=0; i < _reqArray.length; i++) {
            if (minted[_reqArray[i].uid] && !revertOnFail) {
                continue;
            }
            _fiatMint(_reqArray[i]);
        }
    }

    /// @dev Mints an NFT according to the provided mint request.
    function _mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        private
        returns (uint256 tokenIdMinted)
    {
        address signer = verifyRequest(_req, _signature);
        address receiver = _req.to == address(0) ? _msgSender() : _req.to;

        tokenIdMinted = _mintTo(receiver, _req.uri);

        collectPrice(_req);

        emit Kairos_TokensMintedWithSignature(signer, receiver, tokenIdMinted, _req);
    }

    /// @dev Mints an NFT according to the provided mint request.
    function mintWithSignature(MintRequest calldata _req, bytes calldata _signature)
        external
        payable
        nonReentrant
        returns (uint256 tokenIdMinted)
    {
        return _mintWithSignature(_req, _signature);
    }

    /// @dev Try mint an NFT according to the provided mint request.
    /// accepts an array of siganture mints, mints the first one possible
    function tryMintWithSignature(MintRequest[] calldata _reqArray, bytes[] calldata _signatureArray)
        external
        payable
        nonReentrant
        returns (uint256 tokenIdMinted)
    {
        for (uint i=0; i < _reqArray.length; i++) {
            if (minted[_reqArray[i].uid]) {
                continue;
            }
            return _mintWithSignature(_reqArray[i], _signatureArray[i]);
        }
        revert MintChoicesMinted();
    }

    //      =====   Setter functions  =====

    /// @dev Sets the URI for a tokenId
    function setTokenURI(uint256 _tokenId, string calldata _uri) external 
    onlyRole(DEFAULT_ADMIN_ROLE) {
        uri[_tokenId]= _uri;
        emit Kairos_TokenURIChanged(_tokenId, _uri);
    }

    /// @dev Lets a module admin set the default recipient of all primary sales.
    function setPrimarySaleRecipient(address _saleRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        primarySaleRecipient = _saleRecipient;
        emit PrimarySaleRecipientUpdated(_saleRecipient);
    }

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_royaltyBps > MAX_BPS) {
            revert MaxBPS(_royaltyBps, MAX_BPS);
        }

        royaltyRecipient = _royaltyRecipient;
        royaltyBps = uint128(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    /// @dev Lets a module admin update the fees on primary sales.
    function setPlatformFeeInfo(address _platformFeeRecipient, uint256 _platformFeeBps)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (_platformFeeBps > MAX_BPS) {
            revert MaxBPS(_platformFeeBps, MAX_BPS);
        }

        platformFeeBps = uint64(_platformFeeBps);
        platformFeeRecipient = _platformFeeRecipient;

        emit PlatformFeeInfoUpdated(_platformFeeRecipient, _platformFeeBps);
    }

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _newOwner)) {
            revert NewOwnerNotModuleAdmin(_newOwner);
        }
        address _prevOwner = _owner;
        _owner = _newOwner;

        emit OwnerUpdated(_prevOwner, _newOwner);
    }

    /// @dev Lets a module admin set the URI for contract-level metadata.
    function setContractURI(string calldata _uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractURI = _uri;
    }

    ///     =====   Getter functions    =====

    /// @dev Returns the platform fee bps and recipient.
    function getPlatformFeeInfo() external view returns (address, uint16) {
        return (platformFeeRecipient, uint16(platformFeeBps));
    }

    /// @dev Returns the platform fee bps and recipient.
    function getDefaultRoyaltyInfo() external view returns (address, uint16) {
        return (royaltyRecipient, uint16(royaltyBps));
    }

    ///     =====   Internal functions  =====

    /// @dev Mints an NFT to `to`
    function _mintTo(address _to, string calldata _uri) internal returns (uint256 tokenIdToMint) {
        tokenIdToMint = nextTokenIdToMint;
        nextTokenIdToMint += 1;

        uri[tokenIdToMint] = _uri;

        _mint(_to, tokenIdToMint);

        emit Kairos_TokensMinted(_to, tokenIdToMint, _uri);
    }

    /// @dev Returns the address of the signer of the mint request.
    function recoverAddress(MintRequest calldata _req, bytes calldata _signature) private view returns (address) {
        return _hashTypedDataV4(keccak256(_encodeRequest(_req))).recover(_signature);
    }

    /// @dev Resolves 'stack too deep' error in `recoverAddress`.
    function _encodeRequest(MintRequest calldata _req) private pure returns (bytes memory) {
        return
            abi.encode(
                TYPEHASH,
                _req.to,
                keccak256(bytes(_req.uri)),
                _req.price,
                _req.currency,
                _req.validityStartTimestamp,
                _req.validityEndTimestamp,
                _req.uid
            );
    }

    /// @dev Verifies that a mint request is valid.
    function verifyRequest(MintRequest calldata _req, bytes calldata _signature) internal returns (address) {
        (bool success, address signer) = verify(_req, _signature);
        if (!success) {
            revert InvalidSignature(signer);
        }

        if (!(_req.validityStartTimestamp <= block.timestamp && _req.validityEndTimestamp >= block.timestamp)) {
            revert RequestExpired(_req.validityStartTimestamp, _req.validityEndTimestamp, block.timestamp);
        }

        minted[_req.uid] = true;

        return signer;
    }

    /// @dev Collects and distributes the primary sale value of tokens being claimed.
    function collectPrice(MintRequest memory _req) internal {
        if (_req.price == 0) {
            return;
        }

        uint256 totalPrice = _req.price;
        uint256 platformFees = (totalPrice * platformFeeBps) / MAX_BPS;

        if (_req.currency == NATIVE_TOKEN) {
            if (msg.value != totalPrice) {
                revert ETHMismatch(msg.value, totalPrice);
            }
        }

        CurrencyTransferLib.transferCurrency(_req.currency, _msgSender(), platformFeeRecipient, platformFees);
        CurrencyTransferLib.transferCurrency(_req.currency, _msgSender(), primarySaleRecipient, totalPrice - platformFees);
    }

    ///     =====   Low-level overrides  =====

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert CallerIsNotOwnerOrApproved(_msgSender(), tokenId);
        }
        _burn(tokenId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            if (!(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to))) {
                revert AccessControl();
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable, IERC165Upgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981Upgradeable).interfaceId;
    }
}