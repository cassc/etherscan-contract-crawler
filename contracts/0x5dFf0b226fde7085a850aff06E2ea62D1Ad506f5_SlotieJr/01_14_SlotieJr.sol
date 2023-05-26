// SPDX-License-Identifier: MIT
// Developed by KG Technologies (https://kgtechnologies.io)

pragma solidity 0.8.11;

/**
   _____ _      ____ _______ _____ ______        _ _    _ _   _ _____ ____  _____   
  / ____| |    / __ \__   __|_   _|  ____|      | | |  | | \ | |_   _/ __ \|  __ \  
 | (___ | |   | |  | | | |    | | | |__         | | |  | |  \| | | || |  | | |__) | 
  \___ \| |   | |  | | | |    | | |  __|    _   | | |  | | . ` | | || |  | |  _  /  
  ____) | |___| |__| | | |   _| |_| |____  | |__| | |__| | |\  |_| || |__| | | \ \  
 |_____/|______\____/  |_|  |_____|______|  \____/ \____/|_| \_|_____\____/|_|  \_\ 
                                          
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
 * @notice Represents any Smart Contract in the Slotie Ecosystem
 * that implements the ISlotieJrTransferExtender interface.
 */
interface ISlotieJrTransferExtender {
    function onSlotieJrBeforeTransfer(address from, address to, uint256 startTokenId, uint256 quantity) external;
    function onSlotieJrAfterTransfer(address from, address to, uint256 startTokenId, uint256 quantity) external;
}

/**
 * @title SlotieJr.
 *
 * @author KG Technologies (https://kgtechnologies.io).
 *
 * @notice This smart contract can be used to represent an ERC-721 asset on the Ethereum network.
 * It supports delayed reveals, gas-efficient batch minting {ERC721A}, freezing of metadata
 * and role-based access control.
 *
 * @dev The ERC-721A standard developed by chiru-labs, is used as a basis for this contract.
 *
 */
contract SlotieJr is ERC721A, AccessControl, Ownable {
    using Strings for uint256;

    /**
     * @dev UTILITY ADDRESSES
     */
    address public slotieVerseDao;
    address public theSandboxEmbassyDao;
    address public slotieJrTransferExtender;
    address public slotieVerseBaseContract;
    address public stakingContract;
    address public payoutContract;

    /** 
     * @dev NFT PLATFORM INTEGRATION 
     */
    address public openseaProxyRegistryAddress;

    /**
     * @dev METADATA
     */
    string public baseURIString = "";
    string public preRevealBaseURIString = "https://slotie.mypinata.cloud/ipfs/QmSaA2M1zoqgSJkzShrm9Cztm7WtnSmxEthjCXbJETffpy/";
    string public extension = ".json";

    /**
     * @dev MINT SETTINGS 
     */
    uint256 public immutable maxMintPerTransaction = 500;

    /** 
     * @dev FREEZE 
     */
    bool public isFrozen = false;

    /** 
     * @dev REVEAL 
     */
    uint256 public revealDate = 1923870486;

    /** 
     * @dev ROLES 
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

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
    event setPreRevealBaseURIEvent(string indexed preRevealBaseURI);
    event setRevealDateEvent(uint256 indexed revealDate);
    event setExtensionEvent(string indexed extension);
    event setOwnersExplicitEvent(uint256 indexed quantity);
    event ReceivedEther(address indexed sender, uint256 indexed amount);

    event setSlotieVerseDaoEvent(address indexed dao);
    event setTheSandboxEmbassyDaoEvent(address indexed dao);
    event setSlotieJrTransferExtenderEvent(address indexed extender);
    event setSlotieVerseBaseContractEvent(address indexed baseContract);
    event setStakingContractEvent(address indexed staking);
    event setPayoutContractEvent(address indexed payout);
    event WithdrawAllEvent(address indexed to, uint256 amount);

    constructor(
        address _openseaProxyRegistryAddress
    ) ERC721A("Slotie Junior", "SLOTIE JR", maxMintPerTransaction) Ownable() {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(BURNER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
    }

    /**
     * @dev UTILITY ADDONS
     */

    /**
     * @notice Future Slotie verse smart contracts
     * can hook into this function to perform actions
     * before juniors are transfered.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
         super._beforeTokenTransfers(from, to, startTokenId, quantity);
         if (slotieJrTransferExtender != address(0)) {
             ISlotieJrTransferExtender( slotieJrTransferExtender ).onSlotieJrBeforeTransfer(from, to, startTokenId, quantity);
         }
    }

    /**
     * @notice Future Slotie verse smart contracts
     * can hook into this function to perform actions
     * after juniors are transfered.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        super._afterTokenTransfers(from, to, startTokenId, quantity);
        if (slotieJrTransferExtender != address(0)) {
             ISlotieJrTransferExtender( slotieJrTransferExtender ).onSlotieJrAfterTransfer(from, to, startTokenId, quantity);
         }
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
     * @dev Return value is based on revealDate.
     *
     * @param tokenId. The tokenId which we want to know the URI of.
     * @return The URI of token tokenid
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (block.timestamp >= revealDate) {
            return string(abi.encodePacked(baseURIString, tokenId.toString(), extension));
        } else {
            return string(abi.encodePacked(preRevealBaseURIString, tokenId.toString(), extension));
        }    
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
     * @notice Function to set address of Slotie Verse DAO
     *
     * @param _dao. The address of the Slotie Verse DAO
     */
    function setSlotieVerseDao(address _dao) external onlyRole(DAO_ROLE) {
        slotieVerseDao = _dao;
        emit setSlotieVerseDaoEvent(_dao);
    }

    /**
     * @notice Function to set address of Slotie Jr Sanbox Embassy DAO
     *
     * @param _dao. The address of the Slotie Jr Sanbox Embassy DAO
     */
    function setTheSandboxEmbassyDao(address _dao) external onlyRole(DAO_ROLE) {
        theSandboxEmbassyDao = _dao;
        emit setTheSandboxEmbassyDaoEvent(_dao);
    }

    /**
     * @notice Function to set address of Slotie Jr Transfer Extender
     *
     * @param _extender. The address of the Slotie Jr Transfer Extender
     */
    function setSlotieJrTransferExtender(address _extender) external onlyRole(DAO_ROLE) {
        slotieJrTransferExtender = _extender;
        emit setSlotieJrTransferExtenderEvent(_extender);
    }

    /**
     * @notice Function to set address of Slotie Verse base contract
     *
     * @param _baseContract. The address of the Slotie Verse base contract
     */
    function setSlotieVerseBaseContract(address _baseContract) external onlyRole(DAO_ROLE) {
        slotieVerseBaseContract = _baseContract;
        emit setSlotieVerseBaseContractEvent(_baseContract);
    }

    /**
     * @notice Function to set address of Slotie Jr staking contract
     *
     * @param _staking. The address of the Slotie JR staking contract
     */
    function setStakingContract(address _staking) external onlyRole(DAO_ROLE) {
        stakingContract = _staking;
        emit setStakingContractEvent(_staking);
    }

    /**
     * @notice Function to set address of Slotie Jr payout contract
     *
     * @param _payout. The address of the Slotie JR payout contract
     */
    function setPayoutContract(address _payout) external onlyRole(DAO_ROLE) {
        payoutContract = _payout;
        emit setPayoutContractEvent(_payout);
    }

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
     * @notice Allow for changing of placeholder metadata URL.
     * @dev Can be turned off by freezing the contract.
     *
     * @param _newBaseURI. The new base URL for the placeholder metadata of the collection.
     */
    function setPreRevealBaseURI(string memory _newBaseURI) external onlyOwner notFrozen {
        preRevealBaseURIString = _newBaseURI;
        emit setPreRevealBaseURIEvent(_newBaseURI);
    }

    /**
     * @notice Allow for changing of the reveal date of the collection.
     * @dev Can be turned off by freezing the contract.
     *
     * @param _newRevealDate. The new reveal date for the collection.
     */
    function setRevealDate(uint256 _newRevealDate) external onlyOwner notFrozen {
        revealDate = _newRevealDate;
        emit setRevealDateEvent(_newRevealDate);
    }

    /**
     * @notice Allows owner to set the extension of the metadata file
     *
     * @param _extension. The metadata extension.
     */
    function setExtension(string calldata _extension) external onlyOwner notFrozen {
        extension = _extension;
        emit setExtensionEvent(_extension);
    }

    /**
     * @notice Allow for explicitly setting of an NFT's owner.
     * @dev Can be used in the future to avoid expensive in contract ownerOf query.
     * See {ERC721A-_setOwnersExplicit}.
     *
     * @param _quantity. The amount of NFT's to set the owner of explicitly.
     */
    function setOwnersExplicit(uint256 _quantity) external onlyOwner {
        _setOwnersExplicit(_quantity);
        emit setOwnersExplicitEvent(_quantity);
    }

    /**
     * @notice Emit transfer event on NFT in case opensea missed minting event.
     *
     * @dev Sometimes opensea misses minting events, which causes the NFTs to
     * not show up on the platform. We can fix this by re-emitting the transfer 
     * event on the NFT.
     *
     * @param start. The NFT to start from.
     * @param end. The NFT to finish with.
     */
    function emitTransferEvent(uint256 start, uint256 end) external onlyOwner {
        require(start < end, "START CANNOT BE GREATED THAN OR EQUAL TO END");
        require(end <= totalSupply(), "CANNOT EMIT ABOVE TOTAL SUPPY");

        for (uint i = start; i < end; i++) {
            address owner = ownerOf(i);
            emit Transfer(owner, owner, i);
        }
    }

    /** 
     * @dev FINANCE 
     */
    
    /**
     * @notice Allows owner to withdraw funds sent to the contract.
     *
     * @param _to. The address to send the funds to.
     */
    function withdrawAll(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "NO ETHER TO WITHDRAW");

        payable(_to).transfer(contractBalance);

        emit WithdrawAllEvent(_to, contractBalance);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}