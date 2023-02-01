// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PaymentSplitterUpgradeable } from "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import { ECDSAUpgradeable as ECDSA } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { AddressUpgradeable as Address } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { OperatorFilterer } from "closedsea/src/OperatorFilterer.sol";
import {
    IERC721AUpgradeable,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable
} from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

import { IStructPass } from "../../../interfaces/IStructPass.sol";
import { IStructNonceManager } from "../../../interfaces/IStructNonceManager.sol";
import { IStructRandomnessManager } from "../../../interfaces/IStructRandomnessManager.sol";

error StructERC721_ExceedsMaxPerAddress();
error StructERC721_FunctionLocked();
error StructERC721_InsufficientSupply();
error StructERC721_InvalidConfiguration();
error StructERC721_InvalidMetadataState();
error StructERC721_InvalidMintStatus();
error StructERC721_InvalidSignature();
error StructERC721_InvalidTransactionValue();
error StructERC721_NoContractMinting();

/**                       .-==+++++++++++++++++++++++++++++++=-:
                     :=*%##########################################+-
                  .+%##################################################-
                .*######################################################%=
               *##################%*##################*###################%:
             .###################+   :##############+   :###################=
            :####################=    ##############=    ####################*
           .#####################=    ##############=    #####################+
           ######################*   -##############*   -######################
          .#########################%##################%#######################=
          :####################################################################*
          .%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%=

       .-+*##############################*-                          .=########*+=.
     -######################################+:                     -###############%=
    *#########################################%=                :+####################
   *##############################################-          .+%######################%
  .##################################################-     =%##########################-
  :####################################################%#%#############################-
   ###################################################################################%
    *#################################################################################
     -#############################################################################%=
        -+*#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%##+=.

          .#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#=
          -####################################################################*
          .####################################################################=
           ####################################################################.
           .##################################################################+
            :################################################################*
             :##############################################################+
              .############################################################-
                :########################################################=
                  :*###################################################=
                     :+###########################################%*-.
                          :-=+******************************++=:.

 * @title Logic contract for standard ERC721 token drops through structNFT.com
 * @author Augminted Labs, LLC
 * @notice Contract has been optimized for security, transparency, and fairness
 */
contract StructERC721 is
    ERC721AQueryableUpgradeable,
    PaymentSplitterUpgradeable,
    OwnableUpgradeable,
    OperatorFilterer
{
    using Address for address;
    using ECDSA for bytes32;

    struct Config {
        address signer;
        uint16 maxSupply;
        uint16 reserveAmount;
        bool offsetEnabled;
        bool operatorFilterEnabled;
        bool revealed;
    }

    struct MintSettings {
        MintStatus status;
        uint16 maxPerAddress;
        uint112 privatePrice;
        uint112 publicPrice;
    }

    enum MintStatus { UNINITIALIZED, CLOSED, PUBLIC, PRIVATE, OPEN }

    uint16 private constant _MAX_SUPPLY_LIMIT = 10_000;
    uint256 private constant _FREE_MINT_TOKEN_PRICE = 0.00005 ether;
    uint112 private constant _PAID_MINT_PRICE_MIN = 0.0025 ether;
    uint256 private constant _TOTAL_SHARES_ALLOC = 100_000;
    uint256 private constant _STRUCT_SHARES_ALLOC = 5_000;

    address payable private immutable _STRUCT;
    address private immutable _RECEIPT_ISSUER;
    IStructPass private immutable _STRUCT_PASS;
    IStructNonceManager private immutable _NONCE_MANAGER;
    IStructRandomnessManager private immutable _RANDOMNESS_MANAGER;
    bytes32 private immutable _TOKEN_OFFSET_SLOT;

    uint256 private _payeesCount;

    Config public config;
    MintSettings public mintSettings;
    string public provenanceHash;
    string public uri;
    mapping(bytes4 => bool) public functionLocked;

    constructor(
        address _struct,
        address _receiptIssuer,
        IStructPass _structPass,
        IStructNonceManager _nonceManager,
        IStructRandomnessManager _randomnessManager
    ) {
        _STRUCT = payable(_struct);
        _RECEIPT_ISSUER = _receiptIssuer;
        _STRUCT_PASS = _structPass;
        _NONCE_MANAGER = _nonceManager;
        _RANDOMNESS_MANAGER = _randomnessManager;
        _TOKEN_OFFSET_SLOT = _randomnessManager.TOKEN_OFFSET_SLOT();
    }

    /**
     * @notice Initialize a new proxy instance of the contract
     * @param _name Name of the contract
     * @param _symbol Symbol of the contract
     * @param _uri Placeholder or base token URI depending on revealed state
     * @param _provenanceHash Hash of the metadata to commit before reveal
     * @param _config Contract configuration
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        string calldata _uri,
        string calldata _provenanceHash,
        Config calldata _config
    )
        initializerERC721A
        initializer
        payable
        public
    {
        if (_config.maxSupply > _MAX_SUPPLY_LIMIT) revert StructERC721_InvalidConfiguration();
        if (_config.revealed && _config.offsetEnabled) revert StructERC721_InvalidConfiguration();

        __ERC721A_init(_name, _symbol);
        __Ownable_init();

        uri = _uri;
        provenanceHash = _provenanceHash;
        config = _config;

        if (_config.operatorFilterEnabled) _registerForOperatorFiltering();

        _mintReserve(msg.sender);
    }

    /**
     * @notice Initialize mint
     * @param _payees Addresses to receive split of the revenue
     * @param _shares Corresponding shares for each address
     * @param _mintSettings Initial mint settings
     * @param _receipt Signature created by _RECEIPT_ISSUER indicating fee was prepaid
     * @param _nonce Once usable value use as a unique identifier for receipts
     */
    function initializeMint(
        address[] calldata _payees,
        uint256[] calldata _shares,
        MintSettings calldata _mintSettings,
        bytes calldata _receipt,
        uint256 _nonce
    )
        reinitializer(2)
        onlyOwner
        payable
        public
    {
        if (_mintSettings.status == MintStatus.UNINITIALIZED) revert StructERC721_InvalidMintStatus();
        if (_payees.length == 0) revert StructERC721_InvalidConfiguration();

        __PaymentSplitter_init(_payees, _shares);
        _payeesCount = _payees.length;

        if (_STRUCT_PASS.balanceOf(msg.sender) == 0) {
            if (
                _mintSettings.publicPrice < _PAID_MINT_PRICE_MIN
                || _mintSettings.privatePrice < _PAID_MINT_PRICE_MIN
            ) {
                if (!_validatePrepaid(_receipt, _nonce))
                    Address.sendValue(_STRUCT, _FREE_MINT_TOKEN_PRICE * uint256(config.maxSupply));
            } else {
                if (totalShares() != _TOTAL_SHARES_ALLOC || shares(_STRUCT) != _STRUCT_SHARES_ALLOC)
                    revert StructERC721_InvalidConfiguration();
            }
        }

        mintSettings = _mintSettings;
    }

    /**
     * @notice Throws if function has been permanently disabled
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert StructERC721_FunctionLocked();
        _;
    }

    /**
     * @notice Override ERC721 _baseURI function to use base URI pattern
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    /**
     * @notice Internal function for minting reserves to a specified address
     * @dev This should only be called in the initializer
     * @param _to Receiving address of the minted reserve tokens
     */
    function _mintReserve(address _to) internal {
        if (config.reserveAmount > config.maxSupply) revert StructERC721_InsufficientSupply();
        if (config.reserveAmount > 0) _mint(_to, config.reserveAmount);
    }

    /**
     * @notice Internal function for validating receipts
     * @param _receipt Signature created by _RECEIPT_ISSUER indicating fee was prepaid
     * @param _nonce Once usable value use as a unique identifier for receipts
     */
    function _validatePrepaid(bytes calldata _receipt, uint256 _nonce) internal returns (bool) {
        if (_receipt.length == 0 || _NONCE_MANAGER.nonceConsumed(_nonce)) return false;

        bool validated =
            _RECEIPT_ISSUER == ECDSA.recover(
                ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_nonce, address(this), msg.sender))),
                _receipt
            );

        if (validated) _NONCE_MANAGER.consumeNonce(_nonce);

        return validated;
    }

    /**
     * @notice Return token metadata
     * @param tokenId Token to return the metadata for
     * @return Token URI for the specified token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        return config.revealed ? ERC721AUpgradeable.tokenURI(tokenId) : _baseURI();
    }

    /**
     * @notice Token offset is added to the token ID (wrapped on overflow) to get metadata asset index
     */
    function tokenOffset() public view returns (uint256) {
        if (!config.offsetEnabled) revert StructERC721_InvalidConfiguration();

        return _RANDOMNESS_MANAGER.randomness(address(this), _TOKEN_OFFSET_SLOT) % config.maxSupply;
    }

    /**
     * @notice Return the number of tokens an address has minted
     * @param account Address to return the number of tokens minted for
     */
    function numberMinted(address account) public view returns (uint256) {
        return _numberMinted(account);
    }

    /**
     * @notice One-directional lock for functions that are no longer needed
     * @dev WARNING: A LOCKED FUNCTION CAN NEVER BE UNLOCKED
     * @dev struct IS NOT RESPONSIBLE FOR ACCIDENTALLY LOCKED FUNCTIONS
     * @param id First 4 bytes of the calldata (i.e. function identifier)
     */
    function lockFunction(bytes4 id) public lockable onlyOwner {
        functionLocked[id] = true;
    }

    /**
     * @notice Set new mint configuration for the collection
     * @param newMintSettings New mint settings
     * @param receipt Signature created by _RECEIPT_ISSUER indicating fee was prepaid
     * @param nonce Once usable value use as a unique identifier for receipts
     */
    function setMintSettings(
        MintSettings calldata newMintSettings,
        bytes calldata receipt,
        uint256 nonce
    )
        public
        payable
        lockable
        onlyOwner
    {
        if (mintSettings.status == MintStatus.UNINITIALIZED || newMintSettings.status == MintStatus.UNINITIALIZED)
            revert StructERC721_InvalidMintStatus();

        if (
            _STRUCT_PASS.balanceOf(msg.sender) == 0
            && (mintSettings.publicPrice >= _PAID_MINT_PRICE_MIN && newMintSettings.publicPrice < _PAID_MINT_PRICE_MIN)
            || (mintSettings.privatePrice >= _PAID_MINT_PRICE_MIN && newMintSettings.privatePrice < _PAID_MINT_PRICE_MIN)
        ) {
            if (!_validatePrepaid(receipt, nonce))
                Address.sendValue(_STRUCT, _FREE_MINT_TOKEN_PRICE * uint256(config.maxSupply));
        }

        mintSettings = newMintSettings;
    }

    /**
     * @notice Set collection operator filter status
     * @dev Qualification for OpenSea royalties is not strongly defined
     * @dev https://github.com/ProjectOpenSea/operator-filter-registry#creator-earnings-enforcement
     * @dev This setting is ideally enabled/disabled a single time before any tokens are minted
     * @dev struct IS NOT RESPONSIBLE FOR DISQUALIFICATION DUE TO EXPERIMENTATION WITH OPERATOR FILTER
     * @param enabled New state of the operator filter
     */
    function setOperatorFilter(bool enabled) public payable lockable onlyOwner {
        config.operatorFilterEnabled = enabled;

        if (enabled) _registerForOperatorFiltering();
    }

    /**
     * @notice Set provenance hash for the collection
     * @param newProvenanceHash New hash of the metadata
     */
    function setProvenanceHash(string calldata newProvenanceHash) public payable lockable onlyOwner {
        if (config.offsetEnabled)
            _RANDOMNESS_MANAGER.requireRandomnessState(address(this), _TOKEN_OFFSET_SLOT, false);

        provenanceHash = newProvenanceHash;
    }

    /**
     * @notice Set collection revealed status and token URI
     * @param revealed New token reveal status
     * @param newUri Placeholder or base token URI depending on revealed state
     */
    function setRevealed(bool revealed, string calldata newUri) public payable lockable onlyOwner {
        if (config.offsetEnabled)
            _RANDOMNESS_MANAGER.requireRandomnessState(address(this), _TOKEN_OFFSET_SLOT, true);

        config.revealed = revealed;
        uri = newUri;
    }

    /**
     * @notice Set the offset for the token metadata
     * @param useVRF Indicates if the Chainlink VRF should be used to generated randomness
     */
    function setOffset(bool useVRF) public payable lockable onlyOwner {
        if (!config.offsetEnabled) revert StructERC721_InvalidConfiguration();
        if (bytes(provenanceHash).length == 0) revert StructERC721_InvalidMetadataState();

        (useVRF
        ? _RANDOMNESS_MANAGER.setWithVRF
        : _RANDOMNESS_MANAGER.setWithPRNG
        )(address(this), _TOKEN_OFFSET_SLOT);
    }

    /**
     * @notice Mint a specified amount of tokens using a signature
     * @param amount Amount of tokens to mint
     * @param signature Ethereum signed message, created by `signer`
     */
    function privateMint(uint256 amount, bytes memory signature) public payable lockable {
        if (mintSettings.status != MintStatus.PRIVATE && mintSettings.status != MintStatus.OPEN)
            revert StructERC721_InvalidMintStatus();

        if (config.signer != ECDSA.recover(
            ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender))),
            signature
        )) revert StructERC721_InvalidSignature();

        _mint(amount, mintSettings.privatePrice);
    }

    /**
     * @notice Mint a specified number of tokens
     * @param amount Amount of tokens to mint
     */
    function publicMint(uint256 amount) public payable lockable {
        if (mintSettings.status != MintStatus.PUBLIC && mintSettings.status != MintStatus.OPEN)
            revert StructERC721_InvalidMintStatus();

        _mint(amount, mintSettings.publicPrice);
    }

    /**
     * @notice Internal function to mint a specified amount of tokens
     * @param _amount Amount of tokens to mint
     */
    function _mint(uint256 _amount, uint112 _price) internal {
        if (msg.sender != tx.origin) revert StructERC721_NoContractMinting();
        if (msg.value != _amount * _price) revert StructERC721_InvalidTransactionValue();
        if (_totalMinted() + _amount > config.maxSupply) revert StructERC721_InsufficientSupply();
        if (_numberMinted(msg.sender) + _amount > mintSettings.maxPerAddress)
            revert StructERC721_ExceedsMaxPerAddress();

        _mint(msg.sender, _amount);
    }

    /**
     * @notice Release funds to all share holders
     */
    function releaseAll() public payable onlyOwner {
        for (uint256 i; i < _payeesCount;) {
            release(payable(payee(i)));
            unchecked { ++i; }
        }
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator, config.operatorFilterEnabled)
    {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator, config.operatorFilterEnabled)
    {
        super.approve(operator, tokenId);
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from, config.operatorFilterEnabled)
    {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from, config.operatorFilterEnabled)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        onlyAllowedOperator(from, config.operatorFilterEnabled)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}