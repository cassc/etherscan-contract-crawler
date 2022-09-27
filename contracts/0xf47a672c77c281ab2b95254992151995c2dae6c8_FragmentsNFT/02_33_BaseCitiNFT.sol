// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./BaseToken.sol";
import "../../contracts-generated/Versioned.sol";
import "../Validator.sol";

import "./Utils.sol";

/**
 * @dev Parameters required to initialize the NFT contract
 */
struct NFTContractInitializer {
    // `adminAddress` receives {DEFAULT_ADMIN_ROLE} and {PAUSER_ROLE}, assumes msg.sender if not specified.
    address adminAddress;
    
    // Dummy owner of the contract (optional)
    address dummyOwner;

    // Reference of the token contract (optional)
    BaseToken tokenContract;

    // Reference of the validator contract (optional)
    Validator validatorContract;

    // Contract level metadata, see https://docs.opensea.io/docs/contract-level-metadata
    string contractURI;

    // Default base token URI
    string baseTokenURI;

    // Default royalty recipient (optional)
    address royaltyRecipient;

    // Default royalty fraction (optional)
    uint96 royaltyFraction;
}

/**
 * @dev Implementation of upgradable NFT contract based on the OpenZeppelin templates.
 */
contract BaseCitiNFT is ERC721PausableUpgradeable, 
                        ERC721BurnableUpgradeable, 
                        ERC721RoyaltyUpgradeable,
                        AccessControlUpgradeable, 
                        ReentrancyGuardUpgradeable,
                        Versioned 
{
    /// @custom:oz-renamed-from __gap
    uint256[950] private _gap_;
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    // Counter for tokenId generation
    CountersUpgradeable.Counter private _tokenIdCounter;

    // Reference of a ERC20 token contract
    BaseToken internal _token;
    
    // Mapping from tokenId to nonce
    mapping(uint256 => uint256) private _tokenNonces;
    
    // Mapping from hash to nonce
    mapping(bytes32 => uint256) private _hashNonces;

    // Dummy owner address used for claiming contract ownership at Opensea
    // Should NOT be used for any business logic in the contract
    address private _dummyOwner;

    // Contract URI, see https://docs.opensea.io/docs/contract-level-metadata
    string private _contractURI;

    // Base URI for used token URI calculation
    string internal _baseTokenURI;

    // Reference to the validator contract
    Validator private _validator;

    /**
     * @dev Emitted when `tokenId` token's URI is changed from `oldURI` to `newURI`.
     */
    event TokenURIUpdated(uint256 indexed tokenId, string oldURI, string newURI);
    
    /**
     * @dev Emitted when the ERC20 token contract ref is changed from `oldContract` to `newContract`.
     */
    event TokenContractUpdated(BaseToken indexed oldContract, BaseToken indexed newContract);
    
    /**
     * @dev Emitted when the validator contract ref is changed from `oldContract` to `newContract`.
     */
    event ValidatorContractUpdated(Validator indexed oldContract, Validator indexed newContract);
    
    /**
     * @dev Emitted when `tokenId` token's nonce is changed from `oldNonce` to `newNonce`.
     */
    event TokenNonceUpdated(uint256 indexed tokenId, uint256 oldNonce, uint256 newNonce);
    
    /**
     * @dev Emitted when `tokenId` token is upgraded by using `tokenNonce`, `details`, which is validated by `validatorContract`.
     */
    event TokenUpgradedWithDetails(uint256 indexed tokenId, uint256 tokenNonce, string details, Validator validatorContract);
    
    /**
     * @dev Emitted when `tokenId` token is minted to `to`. The function is called by `from` with `details`, validated by `validatorContract`.
     */
    event TokenMintedWithDetails(uint256 indexed tokenId, address indexed to, address indexed from, string details, Validator validatorContract);

    /**
     * @dev Emitted when the dummy owner is changed from `previousOwner` to `newOwner`.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Emitted when the contract URI is changed from `oldURI` to `newURI`.
     */
    event ContractURIUpdated(string oldURI, string newURI);

    /**
     * @dev Emitted when the base token URI is changed from `oldURI` to `newURI`.
     */
    event BaseTokenURIUpdated(string oldURI, string newURI);

    /**
     * @dev Emitted when the default royalty info is updated
     */
    event DefaultRoyaltyInfoUpdated(address indexed recipient, uint96 royaltyFraction);

    /**
     * @dev Initializes the NFT contract from `_initializer`
     */
    function __BaseCitiNFT_init(string memory tokenName, string memory tokenSymbol,  NFTContractInitializer memory _initializer) 
        internal 
        onlyInitializing 
    {
        require(Utils.isKnownNetwork(), "unknown network");
        __ERC721_init(tokenName, tokenSymbol);
        __ERC721Pausable_init();
        __ERC721Burnable_init();
        __ERC721Royalty_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        address admin = _initializer.adminAddress;
        if (admin == address(0)) {
            admin = _msgSender();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);

        _token = _initializer.tokenContract;
        _dummyOwner = _initializer.dummyOwner;
        _validator = _initializer.validatorContract;
        _contractURI = _initializer.contractURI;
        _baseTokenURI = _initializer.baseTokenURI;

        if (_initializer.royaltyRecipient != address(0)) {
            _setDefaultRoyalty(_initializer.royaltyRecipient, _initializer.royaltyFraction);
        }
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) 
        public 
        view 
        virtual 
        override 
        returns (string memory) 
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (bytes(_baseTokenURI).length > 0) {
            // returns <base-uri>/<chain-id>/<contract-address>/<token-id>.json
            // note that _baseTokenURI is expected to end with "/"
            return string(abi.encodePacked(
                _baseTokenURI, 
                Utils.chainID().toString(), "/",
                Utils.addressToHexString(address(this)), "/",
                tokenId.toString(), ".json"
                ));
        } else {
            return "";
        }
    }
    
    /**
     * @dev See {ERC721Upgradeable}
     */
    function _baseURI() 
        internal 
        virtual 
        view 
        override(ERC721Upgradeable) 
        returns (string memory) 
    {
        return _baseTokenURI;
    }
    
    /**
     * @dev See {ERC721Upgradeable}, {ERC721RoyaltyUpgradeable}
     */
    function _burn(uint256 tokenId) 
        internal 
        virtual 
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable) 
    {
        ERC721RoyaltyUpgradeable._burn(tokenId);
    }

    /**
     * @dev Pause the contract, requires `PAUSER_ROLE`
     */
    function pause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _pause();
    }

    /**
     * @dev Unpause the contract, requires `PAUSER_ROLE`
     */
    function unpause() 
        public 
        onlyRole(PAUSER_ROLE) 
    {
        _unpause();
    }

    /**
     * @dev Mints a token to `to`, requires `MINTER_ROLE`
     *
     * Returns the minted tokenId.
     */
    function safeMint(address to) 
        public 
        virtual
        onlyRole(MINTER_ROLE) 
        returns (uint256) 
    {
        return _doSafeMint(to);
    }

    /**
     * @dev See {ERC721PausableUpgradeable}
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, ERC721PausableUpgradeable)
    {
        ERC721PausableUpgradeable._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {ERC721Upgradeable}, {AccessControlUpgradeable}
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        // No need to implement anything from IERC721MetadataUpgradeable
        return interfaceId == type(IERC721MetadataUpgradeable).interfaceId || 
               ERC721Upgradeable.supportsInterface(interfaceId) ||
               ERC721RoyaltyUpgradeable.supportsInterface(interfaceId) ||
               AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal utility function implementing the safe mint logic.
     */
    function _doSafeMint(address to) 
        internal 
        returns (uint256) 
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        return tokenId;
    }
    
    /**
     * @dev Returns the ERC20 token contract ref.
     */
    function tokenContract() 
        public 
        view 
        returns (BaseToken) 
    {
        return _token;
    }

    /**
     * @dev Admin function sets the default royalty info, see {ERC2981Upgradeable}
     *
     * Emits {DefaultRoyaltyInfoUpdated}
     */
    function adminSetDefaultRoyaltyInfo(address recipient, uint96 royaltyFraction) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        _setDefaultRoyalty(recipient, royaltyFraction);
        emit DefaultRoyaltyInfoUpdated(recipient, royaltyFraction);
    }

    /**
     * @dev Admin function sets the ERC20 token contract ref, requires `DEFAULT_ADMIN_ROLE`
     */
    function adminSetTokenContract(BaseToken token) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(token != BaseToken(address(0)), "invalid token contract");
        BaseToken oldTokenContract = _token;
        _token = token;
        emit TokenContractUpdated(oldTokenContract, token);
    }

    /**
     * @dev Admin function sets the validator contract ref, requires `DEFAULT_ADMIN_ROLE`
     */
    function adminSetValidatorContract(Validator validator) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(validator != Validator(address(0)), "invalid validator contract");
        Validator oldContract = _validator;
        _validator = validator;
        emit ValidatorContractUpdated(oldContract, validator);
    }

    /**
     * @dev Returns the validator contract ref.
     */
    function validatorContract() 
        public 
        view 
        returns (Validator) 
    {
        return _validator;
    }

    /**
     * @dev Returns the next nonce for `tokenId`
     */
    function getTokenNonce(uint256 tokenId) 
        public 
        view 
        returns (uint256) 
    {
        return _tokenNonces[tokenId];
    }

    /**
     * @dev Upgrades the `tokenId` token with info specified by `details`.
     * `tokenNonce`: the token nonce from which the signature is generated.
     * `numTokensToBurn`: how many tokens to burn from the caller in order to finish the upgrade.
     * `signature`: signature generated by the offchain validator service in order to verify
     * (tokenId, details, sender, tokenNonce, numTokensToBurn) with the validator contract.
     * 
     * Emits {TokenNonceUpdated} and {TokenUpgradedWithDetails}
     */
    function upgradeWithDetails(uint256 tokenId, string calldata details, uint256 tokenNonce, 
                                uint256 numTokensToBurn, bytes memory signature) 
        external
        nonReentrant
        whenNotPaused 
        whenHasValidator 
    {
        address sender = _msgSender();
        require(tokenNonce == _tokenNonces[tokenId], "invalid nonce");
        require(_isApprovedOrOwner(sender, tokenId), "not owner nor approved");
        // Don't use encodePacked to avoid hash collision
        bytes32 messageHash = keccak256(abi.encode(
            Utils.chainID(),
            address(this),
            tokenId, 
            details, 
            sender, 
            tokenNonce, 
            numTokensToBurn
        ));
        bool verified = _validator.verifySignature(abi.encodePacked(messageHash), signature);
        require(verified, "invalid signature");

        _tokenNonces[tokenId] = tokenNonce + 1;
        
        if (numTokensToBurn > 0) {
            require(_token != BaseToken(address(0)), "invalid token contract");
            _token.burnFrom(sender, numTokensToBurn);
        }
                
        emit TokenNonceUpdated(tokenId, tokenNonce, tokenNonce + 1);
        emit TokenUpgradedWithDetails(tokenId, tokenNonce, details, _validator);
    }    
    
    /**
     * @dev Mints a token for `to` with info specified by `details`.
     * `numTokensToBurn`: how many tokens to burn from the caller in order to finish the mint.
     * `signature`: signature generated by the offchain validator service in order to verify
     * (to, details, sender, numTokensToBurn) with the validator contract.
     * 
     * Emits {TokenMintedWithDetails} and {Transfer}
     */
    function mintWithDetails(address to, string calldata details, 
                             uint256 numTokensToBurn, bytes memory signature) 
        external 
        nonReentrant
        whenNotPaused 
        whenHasValidator 
        returns (uint256) 
    {
        address sender = _msgSender();
        // Don't use encodePacked to avoid hash collision
        bytes32 messageHash = keccak256(abi.encode(
            Utils.chainID(),
            address(this),
            to, 
            details, 
            sender, 
            numTokensToBurn
        ));
        require(_hashNonces[messageHash] == 0, "hash already used");
        
        bool verified = _validator.verifySignature(abi.encodePacked(messageHash), signature);
        require(verified, "invalid signature");

        _hashNonces[messageHash] = 1;
        
        if (numTokensToBurn > 0) {
            require(_token != BaseToken(address(0)), "invalid token contract");
            _token.burnFrom(sender, numTokensToBurn);
        }

        uint256 tokenId = _doSafeMint(to);        
        emit TokenMintedWithDetails(tokenId, to, sender, details, _validator);
        return tokenId;
    }
    
    /**
     * @dev Returns the current tokenId counter.
     */
    function currentTokenIdCounter() 
        public 
        view 
        returns (uint256) 
    {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Returns the dummy contract owner, used by Opensea.
     */
    function owner() 
        public 
        view 
        returns (address) 
    {
        return _dummyOwner;
    }

    /**
     * @dev Admin function to set the dummy owner, requires `DEFAULT_ADMIN_ROLE`.
     *
     * Emits {OwnershipTransferred}
     */
    function adminSetDummyOwner(address dummyOwner) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        require(dummyOwner != address(0), "invalid owner");
        address oldOwner = _dummyOwner;
        _dummyOwner = dummyOwner;
        emit OwnershipTransferred(oldOwner, dummyOwner);
    }

    /**
     * @dev Returns the contract URI, used by Opensea.
     */
    function contractURI() 
        public 
        view 
        returns (string memory) 
    {
        return _contractURI;
    }

    /**
     * @dev Admin function to set the dummy owner, requires `DEFAULT_ADMIN_ROLE`.
     *
     * Emits {ContractURIUpdated}
     */
    function adminSetContractURI(string calldata newContractURI) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        string memory oldURI = _contractURI;
        _contractURI = newContractURI;
        emit ContractURIUpdated(oldURI, newContractURI);
    }
    
    /**
     * @dev Returns the base token URI.
     */
    function baseTokenURI() 
        public 
        view 
        returns (string memory) 
    {
        return _baseTokenURI;
    }

    /**
     * @dev Admin function to set the base token URI, requires `DEFAULT_ADMIN_ROLE`.
     *
     * Emits {BaseTokenURIUpdated}
     */
    function adminSetBaseTokenURI(string calldata newBaseTokenURI) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        whenNotPaused 
    {
        string memory oldURI = _baseTokenURI;
        _baseTokenURI = newBaseTokenURI;
        emit BaseTokenURIUpdated(oldURI, newBaseTokenURI);
    }

    /**
     * @dev Modifier requiring a valid validator contract ref.
     */
    modifier whenHasValidator() {
        require(_validator != Validator(address(0)), "invalid validator contract");
        _;
    }
}