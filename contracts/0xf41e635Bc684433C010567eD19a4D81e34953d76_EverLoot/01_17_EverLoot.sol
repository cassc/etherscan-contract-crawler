// SPDX-License-Identifier: MIT
// @author st4rgarden
pragma solidity ^0.8.2;

import "./Parents/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// @todo Edit price just prior to launch
contract EverLoot is ERC721A, AccessControl, ReentrancyGuard {

    bytes32 public constant ROOT_ROLE = keccak256("ROOT_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // max number of EverLoot that can be minted per call
    uint public constant MAXMINT = 10;

    // the Heroes of Evermore contract
    IERC721 public constant HEROES = IERC721(0xf1eF40f5aEa5D1501C1B8BCD216CF305764fca40);

    /*************************
     MAPPING STRUCTS EVENTS
     *************************/

    // tracks the merkle roots for each loot claim
    mapping(uint => bytes32) private _lootRoots;

    // tracks if user has claimed loot for a particular root
    mapping(address => mapping(uint => uint)) private _claimedLoot;

    // tracks if user has claimed prizes for a particular root
    mapping(address => mapping(uint => uint)) private _claimedPrize;

    // tracks if a user has completed the tutorial with this token
    mapping(address => mapping(uint => bool)) public _tutorialClaimed;

    // tracks a full bulk claim
    event ClaimLoot(address indexed to, uint256[] indexed indexedUniqueItemIds, uint256 indexed startingTokenId, uint256[] uniqueItemIds);

    // tracks a full prize claim
    event ClaimPrize(address indexed to, uint[] tokenIds, address[] tokenAddresses);

    // tracks a forged loot chunk
    event Forge(address indexed to, uint256 indexed amount, uint256 indexed startingTokenId, string forgeType);

    // tracks the promotion of claims on chain
    event PromoteClaims(uint rootIndex, bytes32 lootRoot);

    /*************************
     STATE VARIABLES
     *************************/

    // price of each EverLoot token
    uint private _price = 0.025 ether;
    // pauses minting when true
    bool private _paused = true;
    // increments when a weekly lootRoot is written
    uint private _rootIndex = 0;
    // baseURI for accessing token metadata
    string private _baseTokenURI;

    constructor() ERC721A("EverLoot", "EVER") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ROOT_ROLE, msg.sender);
        _baseTokenURI = "https://api.evermore.mud.xyz/everloot/";
    }


    /*************************
     MODIFIERS
     *************************/

    /**
    * @dev Modifier for preventing calls from contracts
    * Safety feature for preventing malicious contract call backs
    */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract!");
        _;
    }

    /**
    * @dev Modifier for preventing function calls
    * Safety feature that enforces the _paused
    */
    modifier notPaused() {
        require(!_paused, "Minting is paused!");
        _;
    }


    /*************************
     VIEW AND PURE FUNCTIONS
     *************************/

    /**
    * @dev Helper function for validating a merkle proof and leaf
    * @param merkleProof is an array of proofs needed to authenticate a transaction
    * @param root is used along with proofs and our leaf to authenticate our transaction
    * @param leaf is generated from parameter data which can be enforced
    */
    function verifyClaim(
        bytes32[] memory merkleProof,
        bytes32 root,
        bytes32 leaf
    )
        public
        pure
        returns (bool valid)
    {
        return MerkleProof.verify(merkleProof, root, leaf);
    }

    /**
    * @dev Internal function for returning the token URI
    * wrapped with showBaseUri
    */
    function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

    /**
    * @dev Public function for returning the base token URI
    * wraps _baseURI() function
    */
    function returnBaseURI() public view returns (string memory) {
    return _baseURI();
  }

    /**
    * @dev Public function for returning the price
    * wraps _price state variable
    */
    function getPrice() public view returns (uint price) {
        return _price;
    }

    /**
    * @dev Public function for returning the current root index
    * wraps _rootIndex state variable
    */
    function getRootIndex() public view returns (uint rootIndex) {
        return _rootIndex;
    }

    /**
    * @dev Public function for returning if a user has already claimed
    * @param claimedIndex the _claimedLoot index to check
    * @param user the user address to check
    * wraps _claimedLoot mapping
    */
    function getClaimStatus(uint claimedIndex, address user)
        public
        view
        returns (uint status) {
        return _claimedLoot[user][claimedIndex];
    }

    /**
    * @dev Public function for returning if a user has already completed the tutorial for this character
    * @param characterId the token id of the character to check
    * @param user the user address to check
    * wraps _tutorialClaimed mapping
    */
    function getTutorialStatus(uint characterId, address user)
    public
    view
    returns (bool status) {
        return _tutorialClaimed[user][characterId];
    }

    /**
    * @dev Public function for returning the pause status
    * helper function for front end consumption
    */
    function isPaused() public view returns (bool) {
        return _paused;
    }

    /*************************
     USER FUNCTIONS
     *************************/

    /**
    * @dev claims all earned NFTs for a specific claim period
    * @param to is the address which receives minted tokens
    * @param rootId is used to determine which loot root we access
    * @param uniqueItemIds is the array of items the user is claiming
    * @param merkleProof is an array of proofs needed to authenticate a transaction
    */
    function claimLoot(
        address to,
        uint256 rootId,
        uint256[] calldata uniqueItemIds,
        bytes32[] calldata merkleProof
    )
        external callerIsUser notPaused {

        // require that user is claiming less than 10
        require(uniqueItemIds.length <= MAXMINT, "Must not claim more than MAXMINT!");

        // require that user hasn't already claimed these items
        require(_claimedLoot[to][rootId] == 0, "Already claimed items!");

        // build our leaf from the recipient address and the hash of unique item ids
        bytes32 leaf = keccak256(abi.encodePacked(to, uniqueItemIds));

        // authenticate and enforce the correct unique item ids for the correct user
        require(verifyClaim(merkleProof, _lootRoots[rootId], leaf), "Incorrect merkle proof!");

        // set the claimed status for user
        _claimedLoot[to][rootId] = 1;

        // indexed data for assigning unique item id's metadata to the correct token id
        emit ClaimLoot(to, uniqueItemIds, _currentIndex, uniqueItemIds);

        // mint the new loot token's to user
        _safeMint(to, uniqueItemIds.length);
    }

    /**
    * @dev claims all prize NFTs for a specific claim period
    * @param to is the address which receives minted tokens
    * @param rootId is used to determine which loot root we access
    * @param tokenIds is the array of items the user is claiming
    * @param tokenAddresses is the array of NFT contract addresses
    * @param merkleProof is an array of proof needed to authenticate a transaction
    */
    function claimPrize(
        address to,
        uint rootId,
        uint[] calldata tokenIds,
        address[] calldata tokenAddresses,
        bytes32[] calldata merkleProof
    )
        external callerIsUser notPaused {

        // require that user hasn't already claimed these prizes
        require(_claimedPrize[to][rootId] == 0, "Already claimed items!");

        // require that our array lengths match
        require(tokenIds.length == tokenAddresses.length, "Arrays don't match!");

        // build our leaf from the user address, token Ids and token contract addresses
        bytes32 leaf = keccak256(abi.encodePacked(to, tokenIds, tokenAddresses));

        // authenticate and enforce the correct token ids, contracts and user user
        require(verifyClaim(merkleProof, _lootRoots[rootId], leaf), "Incorrect merkle proof!");

        // set the claimed status for user
        _claimedPrize[to][rootId] = 1;

        // log data for user claiming which tokens and collection
        emit ClaimPrize(to, tokenIds, tokenAddresses);

        for (uint256 i; i < tokenIds.length; i++) {

            // instantiate an interface for the ERC721 prize contract
            IERC721 prizeContract = IERC721(tokenAddresses[i]);

            // transfer token to prize winner
            prizeContract.transferFrom(address(this), to, tokenIds[i]);
        }

    }

    /**
    * @dev Forges new EverLoot tokens to the function caller
    * @param amount the number of tokens to forge
    */
    function forge(uint amount)
    external payable callerIsUser notPaused {

        // require that user is claiming less than 10
        require(amount <= MAXMINT, "Must not claim more than MAXMINT!");

        // require the correct amount of ETH is sent
        require(msg.value == amount * _price, "Must send exact ETH!");

        // emit data for generating loot tokens
        emit Forge(_msgSender(), amount, _currentIndex, "forge");

        // mints the new tokens to the user
        _safeMint(_msgSender(), amount);

    }

    /**
    * @dev Forges new EverLoot tokens to the function caller
    * @param tokenId The Heroes of Evermore character minting the token
    */
    function tutorial(uint tokenId)
    external callerIsUser notPaused {

        // require that user is claiming less than 10
        require(!getTutorialStatus(tokenId, _msgSender()), "Already claimed tutorial gear!");

        // require that the user owns the hero they are claiming
        require(HEROES.ownerOf(tokenId) == _msgSender(), "Doesn't own the hero!");

        // emit data for generating loot tokens
        emit Forge(_msgSender(), 1, _currentIndex, "tutorial");

        // mark user as claiming for this tokenId
        _tutorialClaimed[_msgSender()][tokenId] = true;

        // mints the new tokens to the user
        _safeMint(_msgSender(), 1);

    }

    /*************************
     ACCESS CONTROL FUNCTIONS
     *************************/

    /**
    * @dev Access control function allows Battle for Evermore to post new root hashes
    * @param newIndex the new index of our loot root mapping
    * @param newRoot the new merkle root to be stored on chain
    */
    function newLootRoot(
        uint newIndex,
        bytes32 newRoot
    )
        external onlyRole(ROOT_ROLE) {

        // enforces that we aren't rewriting merkle roots
        require(newIndex == _rootIndex + 1, "Cannot rewrite an older root!");

        // update the root index to the new root index
        _rootIndex = newIndex;

        // set the new root within the loot roots mapping
        _lootRoots[_rootIndex] = newRoot;

        // log the new loot root data
        emit PromoteClaims(newIndex, newRoot);
    }

    /**
    * @dev Forges new EverLoot tokens to the function caller
    * @param amount the number of tokens to forge
    */
    function specialForge(address to, uint amount, string calldata forgeType)
    external onlyRole(MINTER_ROLE) notPaused {

        // require that user is claiming less than 10
        require(amount <= MAXMINT, "Must not claim more than MAXMINT!");

        // emit data for generating loot tokens
        emit Forge(to, amount, _currentIndex, forgeType);

        // mints the new tokens to the user
        _safeMint(to, amount);

    }

    /**
    * @dev Access control function allows PAUSER_ROLE to toggle _paused flag
    * @param setPaused the new status of the paused variable
    */
    function setPause(
        bool setPaused
    )
        external onlyRole(PAUSER_ROLE) {
        _paused = setPaused;
    }

    /**
    * @dev Access control function allows DEFAULT_ADMIN_ROLE to change the URI
    * @param newBaseURI the new base token URI
    */
    function setBaseURI(string calldata newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = newBaseURI;
    }

    /**
    * @dev Access control function allows DEFAULT_ADMIN_ROLE to withdraw ETH
    */
    function withdrawAll()
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE) {

        // transfer contract's balance to the multi-sig
        (bool success, ) = msg.sender.call{value: address(this).balance}("");

        // revert if transfer fails
        require(success, "Transfer failed.");
  }

    /*************************
     OVERRIDES
     *************************/

    // required by Solidity
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Change the starting tokenId to 1
     */
    function _startTokenId()
    internal
    pure
    override(ERC721A) returns (uint256) {
        return 1;
    }

}