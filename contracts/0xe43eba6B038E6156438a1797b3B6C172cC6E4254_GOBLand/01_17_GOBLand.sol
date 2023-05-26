// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface LandPassContract {
    function burnFromRedeem(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract GOBLand is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public maxLands;
    bytes32 public merkleRoot;
    mapping(address => uint256) public claimed;
    LandPassContract public landPassContract;
    Counters.Counter private _tokenIdCounter;
    mapping (address => bool) public authorizedContracts;
    bool public landpassRedeemable = false;
     string public baseURI;

    event Redeemed(address indexed account, uint256 amount);


    constructor(string memory uri, uint256 ml, address landPassAddress) ERC721("GOBLand", "LAND") {
        baseURI = uri;
        landPassContract = LandPassContract(landPassAddress); 
        maxLands = ml;
    }

    modifier onlyAuthorizedContracts() {
         require(authorizedContracts[msg.sender] == true, "Only allowed from authorized contracts");
        _;
    }

    modifier whenLandPassIsRedeemable() {
        require(landpassRedeemable == true, "Landpass exchange must be opened");
        _;
    }

    function updateBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
    
    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function authorizeContract(address addr) public onlyOwner {
        authorizedContracts[addr] = true;
    }

    function updateLandPassRedeemable(bool value) public {
        landpassRedeemable = value;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function _leaf(address account, uint256 amount) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, amount));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateLandPass(address addr) public onlyOwner {
        landPassContract = LandPassContract(addr); 
    }

    function _checkSupply(uint256 amount) private view {
        require(amount > 0, "Amount must be greater than 0");
        require((totalSupply().add(amount)) <= maxLands, "Max lands exceeded"); 
    }

    // MINT

    function forceMint(address account, uint256 amount) public onlyOwner
    {
        for (uint256 i = 0; i < amount; i++) {
            safeMint(account);
        }
    }

    function whitelistMint(uint256 amount, bytes32[] calldata proof) public whenNotPaused {
        _checkSupply(amount);
        require(claimed[msg.sender] < amount, "Claim: Not allowed to claim given amount");
        require(_verify(_leaf(msg.sender, amount), proof), "Invalid merkle proof");

        uint256 numberToClaim = amount.sub(claimed[msg.sender]);
        claimed[msg.sender] = claimed[msg.sender].add(numberToClaim);
        for(uint256 i = 0; i < numberToClaim; i++) {
            safeMint(msg.sender);
        }
    }

    function externalMint(address addr, uint256 amount) public onlyAuthorizedContracts whenNotPaused {
        _checkSupply(amount);
        for(uint256 i = 0; i < amount; i++) {
            safeMint(addr);
        }
    }

    function safeMint(address to) private {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Set the starting index block for the collection, essentially unblocking
     * setting starting index
     */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndex == 0, "Starting index is already set");
        startingIndexBlock = block.number;
    }

    function setSupply(uint256 value) public onlyOwner {
        maxLands = value;
    }

    /**
     * Set the starting index for the collection
     */
    function setStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % maxLands;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
                
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number - 1)) % maxLands;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function redeem() external whenNotPaused whenLandPassIsRedeemable {
        require(msg.sender == tx.origin, "Redeem: not allowed from contract");
        uint256 amount = landPassContract.balanceOf(msg.sender, 0);
        _checkSupply(amount);

        landPassContract.burnFromRedeem(msg.sender, 0, amount);
        for(uint256 i = 0; i < amount; i++) {
            safeMint(msg.sender);
        }

        emit Redeemed(msg.sender, amount);

        if (startingIndexBlock == 0 && totalSupply() == maxLands) {
            startingIndexBlock = block.number;
        }
    }
}