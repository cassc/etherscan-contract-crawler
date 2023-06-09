// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;


import "./lib/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * @notice Represents opensea's proxy contract for delegated transactions
 */
contract OwnableDelegateProxy {}

/**
 * @notice Represents opensea's ProxyRegistry contract.
 * Used to find the opensea proxy contract of a user
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title BoredDogeClubERC721.
 *
 * @notice This smart contract can be used to represent an ERC-721 asset on the Ethereum network.
 * It supports delayed reveals, gas-efficient batch minting {ERC721A}, freezing of metadata
 * and role-based access control.
 *
 * @dev The ERC-721A standard developed by chiru-labs, is used as a basis for this contract.
 *
 */
contract BoredDogeClubERC721 is ERC721A, AccessControl, Ownable {
    using Strings for uint256;

    /** 
     * @dev NFT PLATFORM INTEGRATION 
     */
    address public openseaProxyRegistryAddress;

    /**
     * @dev METADATA
     */
    string public baseURIString = "https://d2b4lhkyu87bfm.cloudfront.net/metadata/";

    /** 
     * @dev FREEZE 
     */
    bool public isFrozen = false;

    /** 
     * @dev ROLES 
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /** 
     * @dev MODIFIERS 
     */
    modifier notFrozen() {
        require(!isFrozen, "CONTRACT FROZEN");
        _;
    }

    /** 
     * @dev EVENTS 
     */    
    event setBaseURIEvent(string indexed baseURI);
    event setOwnersExplicitEvent(uint256 indexed quantity);
    event ReceivedEther(address indexed sender, uint256 indexed amount);

    constructor(
        address _openseaProxyRegistryAddress
    ) ERC721A("Bored Doge Club", "BDC") Ownable() {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
    }

    /**
     * @dev MINTING 
     */

    /**
     * @notice Function to mint NFTs to a specified address. Only 
     * accessible by accounts with a role of MINTER_ROLE
     *
     * @param amount The amount of NFTs to be minted
     * @param _to The address to which the NFTs will be minted to
     */
    function mintTo(uint256 amount, address _to) external onlyRole(MINTER_ROLE) {
        _safeMint(_to, amount);
    }

    /**
     * @dev BURNING
     */

    /**
     * @dev Burns `tokenId`. See {ERC721A-_burn}.
     *
     * @param tokenId. The token ID to burn
     */
    function burn(uint256 tokenId) external onlyRole(BURNER_ROLE)  {
        _burn(tokenId);
    }

    /** 
     * @dev VIEW ONLY
     */

    /**
     * @notice Function to get the URI for the metadata of a specific tokenId
     * @dev Return value is based on revealDate.
     *
     * @param tokenId. The tokenId which we want to know the URI of.
     * @return The URI of token tokenid
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURIString, tokenId.toString(), ".json"));     
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721A) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns _currentIndex from ERC721-a, which
     * is the next tokenId to be minted
     */
    function getNextTokenId() external view returns(uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns whether tokenId exists
     *
     * @param tokenId. The tokenId to check
     *
     * @return boolean indicating whether the tokenId exists.
     */
    function exists(uint256 tokenId) external view returns(bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Expose ERC721-a _numberMinted method.
     */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @dev Expose ERC721-a _numberBurned method.
     */
    function numberBurned(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy account to enable gas-less listings.
     * @dev Used for integration with opensea's Wyvern exchange protocol.
     * See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Create an instance of the ProxyRegistry contract from Opensea
        ProxyRegistry proxyRegistry = ProxyRegistry(openseaProxyRegistryAddress);
        // whitelist the ProxyContract of the owner of the NFT
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        if (openseaProxyRegistryAddress == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Override msgSender to allow for meta transactions on OpenSea.
     */
    function _msgSender()
        override
        internal
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    /**
     * @dev OWNER  ONLY
     */

    /**
     * @notice Allow for changing of metadata URL.
     * @dev Can be turned off by freezing the contract.
     *
     * @param _newBaseURI. The new base URL for the metadata of the collection.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner notFrozen {
        baseURIString = _newBaseURI;
        emit setBaseURIEvent(_newBaseURI);
    }

    /** 
     * @dev FINANCE 
     */

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}