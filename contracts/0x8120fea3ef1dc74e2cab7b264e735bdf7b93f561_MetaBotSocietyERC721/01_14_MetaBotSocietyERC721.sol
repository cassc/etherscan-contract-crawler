// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/**
  __  __ ______ _______       ____   ____ _______    _____  ____   _____ _____ ______ _________     __
 |  \/  |  ____|__   __|/\   |  _ \ / __ \__   __|  / ____|/ __ \ / ____|_   _|  ____|__   __\ \   / /
 | \  / | |__     | |  /  \  | |_) | |  | | | |    | (___ | |  | | |      | | | |__     | |   \ \_/ / 
 | |\/| |  __|    | | / /\ \ |  _ <| |  | | | |     \___ \| |  | | |      | | |  __|    | |    \   /  
 | |  | | |____   | |/ ____ \| |_) | |__| | | |     ____) | |__| | |____ _| |_| |____   | |     | |   
 |_|  |_|______|  |_/_/    \_\____/ \____/  |_|    |_____/ \____/ \_____|_____|______|  |_|     |_|                                                                                                                                                                                                                                   
                             
 */

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
 * @title MetaBotSocietyERC721.
 *
 * @notice This smart contract can be used to represent an ERC-721 asset on the Ethereum network.
 * It supports delayed reveals, gas-efficient batch minting {ERC721A}, freezing of metadata
 * and role-based access control.
 *
 * @dev The ERC-721A standard developed by chiru-labs, is used as a basis for this contract.
 *
 */
contract MetaBotSocietyERC721 is ERC721A, AccessControl, Ownable {
    using Strings for uint256;

    /** 
     * @dev NFT PLATFORM INTEGRATION 
     */
    address public openseaProxyRegistryAddress;

    /**
     * @dev METADATA
     */
    string public baseURIString = "";

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
     * @dev PAYMENT
     */
    address[] public recipients;
    uint256[] public shares;

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
    event setRecipientsEvent(address[] indexed addresses, uint256[] indexed shares);
    event WithdrawAllEvent(address indexed to, uint256 amount);
    event ReceivedEther(address indexed sender, uint256 indexed amount);

    constructor(
        address _openseaProxyRegistryAddress
    ) ERC721A("METABOT Society", "MBS") Ownable() {
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
     * @dev VIEW ONLY
     */

    /**
     * @notice Function to get the URI for the metadata of a specific tokenId
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
     * @notice Set recipients for funds collected in smart contract.
     *
     * @dev Overrides old recipients and shares
     *
     * @param _addresses. The addresses of the new recipients.
     * @param _shares. The shares corresponding to the recipients.
     */
    function setRecipients(address[] calldata _addresses, uint256[] calldata _shares) external onlyOwner {
        require(_addresses.length > 0, "HAVE TO PROVIDE AT LEAST ONE RECIPIENT");
        require(_addresses.length == _shares.length, "PAYMENT SPLIT NOT CONFIGURED CORRECTLY");

        delete recipients;
        delete shares;

        for (uint i = 0; i < _addresses.length; i++) {
            recipients.push(_addresses[i]);
            shares.push(_shares[i]);
        }

        emit setRecipientsEvent(_addresses, _shares);
    }

    /**
     * @dev FINANCE
     */

    /**
     * @notice Allows owner to withdraw funds generated from sale to the specified recipients.
     *
     */
    function withdrawAll() external {
        bool senderIsRecipient = false;
        for (uint i = 0; i < recipients.length; i++) {
            senderIsRecipient = senderIsRecipient || (msg.sender == recipients[i]);
        }
        require(senderIsRecipient, "CAN ONLY BE CALLED BY RECIPIENT");
        require(recipients.length > 0, "CANNOT WITHDRAW TO ZERO ADDRESS");
        require(recipients.length == shares.length, "PAYMENT SPLIT NOT CONFIGURED CORRECTLY");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        for (uint i = 0; i < recipients.length; i++) {
            address _to = recipients[i];
            uint256 _amount = contractBalance * shares[i] / 1000;
            payable(_to).transfer(_amount);
            emit WithdrawAllEvent(_to, _amount);
        }        
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}