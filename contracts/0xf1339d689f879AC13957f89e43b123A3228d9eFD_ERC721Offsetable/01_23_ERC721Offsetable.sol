// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";

import "../../interfaces/Offsetable.sol";

error ERC721Offsetable_CallerNotOffsetManager();
error ERC721Offsetable_ExceedsMaxPerAddress();
error ERC721Offsetable_FunctionLocked();
error ERC721Offsetable_InsufficientSupply();
error ERC721Offsetable_InvalidMintStatus();
error ERC721Offsetable_InvalidPaymentSplitterValues();
error ERC721Offsetable_InvalidSignature();
error ERC721Offsetable_InvalidValue();
error ERC721Offsetable_NoContractMinting();
error ERC721Offsetable_CollectionNotRevealed();
error ERC721Offsetable_ProvenanceHashNotSet();
error ERC721Offsetable_TokenOffsetAlreadySet();
error ERC721Offsetable_TokenOffsetBypassed();
error ERC721Offsetable_TokenOffsetNotSet();


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

 * @title Base contract for standard ERC721 token drops
 * @author Augminted Labs, LLC
 * @notice Contract has been optimized for security and fairness
 */
contract ERC721Offsetable is
    ERC2981Upgradeable,
    ERC721AQueryableUpgradeable,
    PaymentSplitterUpgradeable,
    OwnableUpgradeable,
    Offsetable
{
    using AddressUpgradeable for address;
    using ECDSAUpgradeable for bytes32;

    enum MintStatus { CLOSED, PUBLIC, PRIVATE, BOTH }

    struct Config {
        address signer;
        uint32 maxSupply;
        uint32 reserveAmount;
        uint16 maxPerAddress;
        MintStatus status;
        bool revealed;
        bool bypassOffset;
        uint120 privatePrice;
        uint120 publicPrice;
    }

    address payable internal constant _STRUCT_ADDRESS = payable(0x3b5de8FEFF2AE3C07f2DcD3cFbBd5951B6EA4093);
    address internal constant _OFFSET_MANAGER = 0x49d438246De154E48C74b2D47aa0D60cA7584Cee;
    uint256 internal constant _TOTAL_SHARES = 100_000;
    uint256 internal constant _STRUCT_SHARES = 5_000;
    uint256 internal _tokenOffset;

    Config public config;
    string public uri;
    string public provenanceHash;
    mapping(bytes4 => bool) public functionLocked;

    /**
     * @notice Initialize a new proxy instance of the contract
     * @param _payees Addresses to receive split of the revenue
     * @param _shares Corresponding shares for each address
     * @param _name Name of the contract
     * @param _symbol Symbol of the contract
     * @param _uri Placeholder or base token URI depending on revealed state
     * @param _provenanceHash Hash of the metadata to commit before reveal
     * @param _config Contract configuration
     */
    function initialize(
        address[] memory _payees,
        uint256[] memory _shares,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        string memory _provenanceHash,
        Config memory _config
    )
        initializerERC721A
        initializer
        public
    {
        __ERC2981_init();
        __Ownable_init();

        __ERC721A_init(_name, _symbol);

        _validatePaymentSplitterValues(_payees, _shares);
        __PaymentSplitter_init(_payees, _shares);

        uri = _uri;
        provenanceHash = _provenanceHash;
        config = _config;

        if (config.reserveAmount > 0) {
            _mint(
                _msgSender(),
                config.reserveAmount > config.maxSupply ? config.maxSupply : config.reserveAmount
            );
        }

        if (config.revealed) config.bypassOffset = true;
    }

    /**
     * @notice Validate values used to initialize the payment splitter
     * @param _payees Array of payee addresses including `_STRUCT_ADDRESS`
     * @param _shares Array of share values totalling `_TOTAL_SHARES`
     */
    function _validatePaymentSplitterValues(
        address[] memory _payees,
        uint256[] memory _shares
    )
        private
        pure
    {
        uint256 totalShares;

        for (uint256 i; i < _shares.length;) {
            totalShares += _shares[i];
            unchecked { ++i; }
        }

        if (
            totalShares != _TOTAL_SHARES ||
            _payees[_payees.length - 1] != _STRUCT_ADDRESS ||
            _shares[_shares.length - 1] != _STRUCT_SHARES
        ) revert ERC721Offsetable_InvalidPaymentSplitterValues();
    }

    /**
     * @notice Modifier applied to functions that will be disabled when they're no longer needed
     */
    modifier lockable() {
        if (functionLocked[msg.sig]) revert ERC721Offsetable_FunctionLocked();
        _;
    }

    /**
     * @notice Return token metadata
     * @param tokenId Token to return the metadata for
     * @return Token URI for the specified token
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(IERC721AUpgradeable, ERC721AUpgradeable)
        returns (string memory)
    {
        return config.revealed ? ERC721AUpgradeable.tokenURI(tokenId) : _baseURI();
    }

    /**
     * @notice Override ERC721 _baseURI function to use base URI pattern
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    /**
     * @notice Token offset is added to the token ID (wrapped on overflow) to get metadata asset index
     */
    function tokenOffset() external view returns (uint256) {
        if (config.bypassOffset) revert ERC721Offsetable_TokenOffsetBypassed();
        if (_tokenOffset == 0) revert ERC721Offsetable_TokenOffsetNotSet();

        return _tokenOffset;
    }

    /**
     * @notice Return the number of tokens an address has minted
     * @param account Address to return the number of tokens minted for
     */
    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    /**
     * @inheritdoc ERC721AUpgradeable
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC721AUpgradeable, ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Set new royalties settings for the collection
     * @param receiver Address to receive royalties
     * @param royaltyFraction Royalty fee respective to fee denominator (10_000)
     */
    function setRoyalties(address receiver, uint96 royaltyFraction) external onlyOwner {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    /**
     * @notice Set new configuration for the collection
     * @dev `revealed` must be set in `setRevealed` to ensure token offset has been set
     * @dev `maxSupply` and `bypassOffset` cannot be changed to ensure fairness
     * @dev `reserveAmount` is irrelevant but maintained for transparency purposes
     * @param _config New configuration for the collection
     */
    function setConfig(Config memory _config) external onlyOwner {
        _config.revealed = config.revealed;
        _config.maxSupply = config.maxSupply;
        _config.bypassOffset = config.bypassOffset;
        _config.reserveAmount = config.reserveAmount;

        config = _config;
    }

    /**
     * @notice Set provenance hash for the collection
     * @param _provenanceHash New hash of the metadata
     */
    function setProvenanceHash(string calldata _provenanceHash) external lockable onlyOwner {
        if (config.bypassOffset) revert ERC721Offsetable_TokenOffsetBypassed();
        if (_tokenOffset != 0) revert ERC721Offsetable_TokenOffsetAlreadySet();

        provenanceHash = _provenanceHash;
    }

    /**
     * @notice Set collection revealed status and token URI
     * @param _revealed New token reveal status
     * @param _uri Placeholder or base token URI depending on revealed state
     */
    function setRevealed(bool _revealed, string calldata _uri) external lockable onlyOwner {
        if (!config.bypassOffset && _tokenOffset == 0) revert ERC721Offsetable_TokenOffsetNotSet();

        config.revealed = _revealed;
        uri = _uri;
    }

    /**
     * @notice Set the offset for the token metadata
     * @param randomness Random value used to seed offset
     */
    function setOffset(uint256 randomness) external virtual override {
        if (config.bypassOffset) revert ERC721Offsetable_TokenOffsetBypassed();
        if (_msgSender() != _OFFSET_MANAGER) revert ERC721Offsetable_CallerNotOffsetManager();
        if (bytes(provenanceHash).length == 0) revert ERC721Offsetable_ProvenanceHashNotSet();
        if (_tokenOffset != 0) revert ERC721Offsetable_TokenOffsetAlreadySet();

        _tokenOffset = randomness % config.maxSupply;
    }

    /**
     * @notice Mint a specified amount of tokens using a signature
     * @param amount Amount of tokens to mint
     * @param signature Ethereum signed message, created by `signer`
     */
    function privateMint(uint256 amount, bytes memory signature) external payable {
        if (msg.value != config.privatePrice * amount) revert ERC721Offsetable_InvalidValue();
        if (config.status != MintStatus.PRIVATE && config.status != MintStatus.BOTH)
            revert ERC721Offsetable_InvalidMintStatus();
        if (config.signer != ECDSAUpgradeable.recover(
            ECDSAUpgradeable.toEthSignedMessageHash(keccak256(abi.encodePacked(_msgSender()))),
            signature
        )) revert ERC721Offsetable_InvalidSignature();

        _mint(amount);
    }

    /**
     * @notice Mint a specified number of tokens
     * @param amount Amount of tokens to mint
     */
    function publicMint(uint256 amount) external payable {
        if (msg.value != config.publicPrice * amount) revert ERC721Offsetable_InvalidValue();
        if (config.status != MintStatus.PUBLIC && config.status != MintStatus.BOTH)
            revert ERC721Offsetable_InvalidMintStatus();

        _mint(amount);
    }

    /**
     * @notice Internal function to mint a specified amount of tokens
     * @param amount Amount of tokens to mint
     */
    function _mint(uint256 amount) internal {
        if (_msgSender() != tx.origin) revert ERC721Offsetable_NoContractMinting();
        if (_totalMinted() + amount > config.maxSupply) revert ERC721Offsetable_InsufficientSupply();
        if (_numberMinted(_msgSender()) + amount > config.maxPerAddress)
            revert ERC721Offsetable_ExceedsMaxPerAddress();

        _mint(_msgSender(), amount);
    }

    /**
     * @notice Permanently commit the state of the collection. WARNING: THIS CANNOT BE UNDONE
     * @dev Metadata should be migrated to a decentralized and (ideally) permanent storage solution
     */
    function commitMetadata() external onlyOwner {
        if (!config.revealed) revert ERC721Offsetable_CollectionNotRevealed();

        functionLocked[this.setProvenanceHash.selector] = true;
        functionLocked[this.setRevealed.selector] = true;
    }

    /**
     * @inheritdoc PaymentSplitterUpgradeable
     */
    function release(address payable account) public override {
        PaymentSplitterUpgradeable.release(account);

        if (account != _STRUCT_ADDRESS)
            PaymentSplitterUpgradeable.release(_STRUCT_ADDRESS);
    }
}