// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721URIStorage.sol";
import "./ERC2981GlobalRoyalties.sol";
import "./URIManager.sol";
import "./CryptographicUtils.sol";


contract RealVisionProCryptoGenesis is ERC721,
                                       CryptographicUtils,
                                       ERC721URIStorage,
                                       ERC2981GlobalRoyalties,
                                       URIManager,
                                       Pausable,
                                       AccessControl,
                                       ERC721Burnable {
    // create the hashes that identify various roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // create the hash that identifies a role that is allowed to issue signatures
    // which can be used to mint an NFT
    bytes32 public constant MINT_SIGNING_ROLE = keccak256("MINT_SIGNING_ROLE");
    // create the hash that identifies a role that is allowed to issue signatures
    // which can be used to update the URI (location) of the metadata of an NFT
    bytes32 public constant URI_SIGNING_ROLE = keccak256("URI_SIGNING_ROLE");
    bytes32 public constant ROYALTY_SETTING_ROLE = keccak256("ROYALTY_SETTING_ROLE");
    bytes32 public constant METADATA_UPDATER_ROLE = keccak256("METADATA_UPDATER_ROLE");
    bytes32 public constant METADATA_FREEZER_ROLE = keccak256("METADATA_FREEZER_ROLE");

    // The owner variable below is 'honorary' in the sense that it serves no purpose
    // as far as the smart contract itself is concerned. The only reason for implementing this variable
    // is that OpenSea queries owner() (according to an article in their Help Center) in order to decide
    // who can login to the OpenSea interface and change collection-wide settings such as the collection
    // banner, or more importantly, royalty amount and destination (as of this writing, OpenSea
    // implements their own royalty settings, rather than EIP-2981.)
    // Semantically, for our purposes (because this contract uses AccessControl rather than Ownable) it
    // would be more accurate to call this variable something like 'openSeaCollectionAdmin' (but sadly
    // OpenSea is looking for 'owner' specifically.)
    address public owner;

    uint16 constant MAX_SUPPLY = 6000;
    uint16 public numTokensMinted;

    // From testing, it seems OpenSea will only honor a new collection-level administrator (the person who can
    // login to the interface and, for example, change royalty amount/destination), if an event
    // is emmitted, as coded in the OpenZeppelin Ownable contract, announcing the ownership transfer.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(string memory name, string memory symbol, string memory domain, string memory version, string memory baseTokenURI)
    ERC721(name, symbol)
    CryptographicUtils(domain, version)
    URIManager(baseTokenURI) {
        // To start with we will only grant the DEFAULT_ADMIN_ROLE role to the msg.sender
        // The DEFAULT_ADMIN_ROLE is not granted any rights initially. The only privileges
        // the DEFAULT_ADMIN_ROLE has at contract deployment time are: the ability to grant other
        // roles, and the ability to set the 'honorary' contract owner (see comments above.)
        // For any functionality to be enabled, the DEFAULT_ADMIN_ROLE must explicitly grant those roles to
        // other accounts or to itself.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setHonoraryOwner(msg.sender);
    }

    // The 'honorary' portion of this function's name refers to the fact that the 'owner' variable
    // serves no purpose in this smart contract itself. 'Ownership' (so to speak) is only implemented here
    // to allow for certain collection-wide admin functionality within the OpenSea web interface.
    function setHonoraryOwner(address honoraryOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(honoraryOwner != address(0), "New owner cannot be the zero address.");
        address priorOwner = owner;
        owner = honoraryOwner;
        emit OwnershipTransferred(priorOwner, honoraryOwner);
    }

    // Capabilities of the PAUSER_ROLE

    // create a function which can be called externally by an acount with the
    // PAUSER_ROLE. This function, calls the internal _pause() function
    // inherited from Pausable contract, and its purpose is to pause all transfers
    // of tokens in the contract (which includes minting/burning/transferring)
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    // create a function which can be called externally by an acount with the
    // PAUSER_ROLE. This function, calls the internal _uppause() function
    // inherited from Pausable contract, and its purpose is to *un*pause all transfers
    // of tokens in the contract (which includes minting/burning/transferring)
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }


    // Capabilities of the MINTER_ROLE

    // a mint function we will keep in place in case we need to manually do any minting
    // but this will not be the main function used (by customers) to mint
    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _internalMint(to, tokenId);
    }


    // Capabilities of the ROYALTY_SETTING_ROLE
    
    function setRoyaltyAmountInBips(uint16 newRoyaltyInBips) external onlyRole(ROYALTY_SETTING_ROLE) {
        _setRoyaltyAmountInBips(newRoyaltyInBips);
    }

    function setRoyaltyDestination(address newRoyaltyDestination) external onlyRole(ROYALTY_SETTING_ROLE) {
        _setRoyaltyDestination(newRoyaltyDestination);
    }


    // Capabilities of the METADATA_UPDATER_ROLE

    function setBaseURI(string calldata newURI) external onlyRole(METADATA_UPDATER_ROLE) allowIfNotFrozen {
        _setBaseURI(newURI);
    }
        
    function setCustomTokenURI(uint256 tokenId, string calldata newTokenURI) external onlyRole(METADATA_UPDATER_ROLE) allowIfNotFrozen{
        _setCustomTokenURI(tokenId, newTokenURI);
    }

    function deleteCustomTokenURI(uint256 tokenId) external onlyRole(METADATA_UPDATER_ROLE) allowIfNotFrozen {
        _deleteCustomTokenURI(tokenId);
    }

    function setContractURI(string calldata newContractURI) external onlyRole(METADATA_UPDATER_ROLE) allowIfNotFrozen {
        _setContractURI(newContractURI);
    }


    // Capabilities of the METADATA_FREEZER_ROLE

    function freezeURIsForever() external onlyRole(METADATA_FREEZER_ROLE) allowIfNotFrozen {
        _freezeURIsForever();
    }

    // Information fetching - external/public

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address, uint256)
    {
        require(_exists(tokenId), "Royalty requested for non-existing token");
        return _globalRoyaltyInfo(salePrice);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    // Other public/external capabilities

    // This is the main minting function. This is the function customers will be calling
    // when they press the 'mint' button on our website. Their call to this function must
    // include a valid signature, created by an account that has the MINT_SIGNING_ROLE
    // in this contract. The signature must be created with an EIP712 domain, as well as
    // the tokenId to be issued to the NFT, and the EOA of the customer.
    function signatureBasedSafeMint(address to, uint256 tokenId, bytes calldata signature) external {
        // the line below calls a function which uses ECDSA to recover the account that created
        // the signature that allows the minting.
        address theSigner = _recoverSigner(to, tokenId, signature);
        require(hasRole(MINT_SIGNING_ROLE, theSigner), "Invalid Signature");
        // if everything above checks-out, the safeMint function can be summoned.
        _internalMint(to, tokenId);
    }

    // This function allows for safe 'authorization' of the owner of a token to update
    // the URI for their token themselves, but ONLY to something that has been signed-off on
    // off-chain by an account that has the URI_SIGNING_ROLE (so that an owner cannot update the
    // URI to whatever they want. They must provided a valid signature.)
    // NOTE! The purpose of this function is to allow RV and/or the community to implement very specific, and 
    // time-limited projects where an owner can update their metadata URI with some specific purpose in mind (as 
    // envisioned and authorized by RV and/or the community.) After a specific project/timeframe/purpose has
    // ellapsed, the key of the URI_SIGNING_ROLE should be rotated to something new; otherwise a savvy owner
    // would be able to update the metadata URI to a previously authorized version.
    function signatureBasedSetTokenURI(uint256 tokenId, string calldata newTokenURI, bytes calldata signature) external allowIfNotFrozen {
        require(msg.sender == ownerOf(tokenId), "signatureBasedSetTokenURI: The caller of the function is not the owner of the token");        
        // the line below calls a function which uses ECDSA to recover the account that created
        // the signature that allows the minting.
        address theSigner = _recoverSigner(newTokenURI, tokenId, signature);
        require(hasRole(URI_SIGNING_ROLE, theSigner), "Invalid Signature");
        _setCustomTokenURI(tokenId, newTokenURI);
    }


    // Internal/private functions

    function _baseURI() internal view override returns (string memory) {
        return _getBaseURI();
    }

    function _internalMint(address to, uint256 tokenId) private {
        require(numTokensMinted < MAX_SUPPLY, "The maximum number of tokens that can ever be minted has been reached.");
        numTokensMinted += 1;
        _safeMint(to, tokenId);
    }


    // Required overrides

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl, ERC2981GlobalRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);        
    }

    // Override the _beforeTokenTransfer hook implemented in ERC721 to require that
    // the contract be 'not paused' when this hook is called; which is before mints,
    // transfers, and burns.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}