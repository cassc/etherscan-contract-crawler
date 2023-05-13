// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableSet.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IChallenge.sol";

contract ExerciseSupplementNFT is Initializable , ERC721Upgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable { 
    // Importing Solidity libraries
    // The Strings library provides a way to concatenate strings with other types
    // The SafeMath library provides safe arithmetic operations to prevent overflow and underflow errors
    // The Counters library provides a way to generate unique sequential IDs
    // The EnumerableSet library provides a set data structure to store and manipulate data 
    using StringsUpgradeable for uint256;
    using SafeMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    CountersUpgradeable.Counter private _tokenIdCounter; // Counter for tracking token IDs

    string public baseURI; // Base URI for token metadata

    string private baseExtension; // Extension for token metadata files

    EnumerableSet.AddressSet private admins; // Set of addresses with admin privileges

    mapping(uint256 => mapping(address => address)) private _historySendNFT; // Mapping from id to address contract to sender address

    // Contract size
    uint256 private sizeContract; // Set size contract

    modifier onlyAdmin() {
    // check if the sender is an admin
    require(admins.contains(_msgSender()), "NOT ADMIN");
        _;
    }

    /**
    * @dev Initializes the contract by setting the name, symbol, base URI, and admins.
    * @param _initBaseURI The initial base URI for the NFTs.
    */
    function initialize(string memory _initBaseURI, uint256 _sizeContract) 
        initializer 
        public 
    {
        __ERC721_init("ExerciseSupplementNFT1", "ESPLNFT");
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        
        // Set the initial base URI for the NFT
        baseURI = _initBaseURI;
        
        // Add the contract deployer and the contract itself as admins
        admins.add(msg.sender);

        baseExtension = ".json";

        sizeContract = _sizeContract;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        // return the current base URI for the NFT
        return baseURI;
    }

    function safeMint(address to) public payable onlyAdmin{
        // get the next available token ID
        uint256 tokenId = _tokenIdCounter.current();
        // increment the token ID counter
        _tokenIdCounter.increment();
        // mint the new NFT to the specified address
        _safeMint(to, tokenId);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        // Check if the given token ID exists
        require(
            _exists(tokenId),
            "ERC721METADATA: URI QUERY FOR NONEXISTENT TOKEN"
        );

        // Get the base URI and concatenate it with the token ID and base extension to form the final URI
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyAdmin {
        // Update the base URI with the new URI provided by the owner
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyAdmin {
        // Update the base extension with the new extension provided by the owner
        baseExtension = _newBaseExtension;
    }

    // Update the admin address and add/remove it to/from the list of admins
    function updateAdmin(address _adminAddr, bool _flag) external onlyAdmin {
        require(_adminAddr != address(0), "INVALID ADDRESS");
        if (_flag) {
            admins.add(_adminAddr);
        } else {
            admins.remove(_adminAddr);
        }
    }

    // This function returns the list of admin addresses
    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }

    // This function compares two strings and returns a boolean value indicating if they are equal
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    // This function returns the next token ID to be minted
    function nextTokenIdToMint() public view returns(uint256) {
        return _tokenIdCounter.current();
    }

    // This function sets the size of the contract
    function setSizeContract(uint256 _sizeCodeContract) external onlyAdmin {
        require(_sizeCodeContract > 0, "Size contract must be great then zero");
        sizeContract = _sizeCodeContract;
    }

    /**
     * @dev get history transfer NFT 
     */
    function getHistoryNFT(uint256 tokenId, address to) public view returns(address) {
        return _historySendNFT[tokenId][to];
    }

    /**
    @dev Internal function to authorize the upgrade of the contract implementation.
    @param newImplementation Address of the new implementation contract.
    */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyAdmin
        override
    {}
    
    /**
    * @dev Hook function called before any token transfer, including minting and burning.
    * This function sets the history of transfers for the first token ID in the batch.
    * @param from The address tokens are transferred from.
    * @param to The address tokens are transferred to.
    * @param firstTokenId The ID of the first token in the batch.
    * @param batchSize The number of tokens in the batch.
    */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
        // Set history transfer token
        if(to != address(0) && from != address(0) && batchSize >= 0) {
            uint256 size;
            assembly { size := extcodesize(to) }
            if(size > 0) {
                _historySendNFT[firstTokenId][to] = from;
            }

            if(size == sizeContract) {
                require(!IChallenge(payable(to)).isFinished(), "ERC20: Challenge was finished");
            } 
        }
    }
}