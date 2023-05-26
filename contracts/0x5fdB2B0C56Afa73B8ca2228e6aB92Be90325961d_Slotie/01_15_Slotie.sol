// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/** OPENSEA INTERFACES */
/**
 This is a contract that can act on behalf of an Opensea
 user. It's a proxy for the user
 */
contract OwnableDelegateProxy {}

/**
 This represents Opensea's ProxyRegistry contract.
 We use it to find and approve the opensea proxy contract of each 
 user, which allows for better opensea integration like gassless listing etc.
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * Interface for WATTs future token
 */
interface IWATTs {
	function updateReward(address _from, address _to) external;
}


contract Slotie is AccessControl, Ownable, ERC721URIStorage {
    using SafeMath for uint256;
    using Strings for uint256;

    IWATTs public WATTs;

    /** ADDRESSES */
    address public openseaProxyRegistryAddress;

    address public stakingContract;
    address public breedingContract;
    address public WATTS;
    address public lotteryContract;
    address public payoutContract;

    /** NFT DATA */
    string public baseURIString = "";
    string public preRevealBaseURIString = "https://gateway.pinata.cloud/ipfs/QmZg1fDgK7uDs24KuUZYpA8MMn7ZusdRT96gdNEWYoJazS/";
    uint256 public nextTokenId = 0;
    uint256 public revealDate = 1638903600 + 86400 * 365;

    /** SCHEDULING */

    /** ROLES */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    /** FLAGS */
    bool public isModifiable = true;

    /** MODIFIERS */
    modifier canModify {
        require(isModifiable, "NOT MODIFIABLE");
        _;
    }
    /** EVENTS */
    event Mint(address to, uint256 amount);
    event SetStakingContract(address _stakingContract);
    event SetBreedingContract(address _breedingContract);
    event SetWATTS(address _WATTS);
    event SetLotteryContract(address _lotteryContract);
    event SetPayoutContract(address _payoutContract);

    constructor(
        string memory _name,
        string memory _symbol,
        address _openseaProxyRegistryAddress
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
    }

    function setStakingContract(address _stakingContract) external onlyRole(DAO_ROLE) {
        stakingContract = _stakingContract;
        emit SetStakingContract(_stakingContract);
    }

    function setBreedingContract(address _breedingContract) external onlyRole(DAO_ROLE) {
        breedingContract = _breedingContract;
        emit SetBreedingContract(_breedingContract);
    }

    function setWATTSContract(address _WATTS) external onlyRole(DAO_ROLE) {
        WATTS = _WATTS;
        WATTs = IWATTs(_WATTS);
        emit SetWATTS(_WATTS);
    }

    function setLotteryContract(address _lotteryContract) external onlyRole(DAO_ROLE) {
        lotteryContract = _lotteryContract;
        emit SetLotteryContract(_lotteryContract);
    }

    function setPayoutContract(address _payoutContract) external onlyRole(DAO_ROLE) {
        payoutContract = _payoutContract;
        emit SetPayoutContract(_payoutContract);
    }

     function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (WATTS != address(0))
            WATTs.updateReward(from, to);
    }

    /**
    * @dev function to change the baseURI of the metadata
    */
    function setBaseURI(string memory _newBaseURI) external onlyRole(DEFAULT_ADMIN_ROLE) canModify {
        baseURIString = _newBaseURI;
    }

    /**
    * @dev function to change the baseURI of the metadata
    */
    function setRevealDate(uint256 _revealDate) external onlyRole(DEFAULT_ADMIN_ROLE) canModify {
        revealDate = _revealDate;
    }

    function disableModification() external onlyRole(DEFAULT_ADMIN_ROLE) {
        isModifiable = false;
    }

    /**
    * @dev returns the baseURI for the metadata. Used by the tokenURI method.
    * @return the URI of the metadata
    */
    function _baseURI() internal override view returns (string memory) {
        return baseURIString;
    }
    

     /**
     * @dev returns tokenURI of tokenId based on reveal date
     * @return the URI of token tokenid
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (block.timestamp >= revealDate) {
            return super.tokenURI(tokenId);
        } else {
            return string(abi.encodePacked(preRevealBaseURIString, tokenId.toString()));
        }        
    }

     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() external view returns (uint256) {
        return nextTokenId;
    }

    /**
    * @dev override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
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
    * @dev override msgSender to allow for meta transactions on OpenSea.
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
    * @dev function to mint tokens to an address. Only 
    * accessible by accounts with a role of MINTER_ROLE
    * @param amount the amount of tokens to be minted
    * @param _to the address to which the tokens will be minted to
    */
    function mintTo(uint256 amount, address _to) external onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < amount; i++) {
            _safeMint(_to, nextTokenId);
            nextTokenId = nextTokenId.add(1);
        }
        emit Mint(_to, amount);
    }

    /**
     * @dev function to burn token of tokenId. Only
     * accessible by accounts with a role of BURNER_ROLE
     * @param tokenId the tokenId to burn
     */
    function burn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }
}