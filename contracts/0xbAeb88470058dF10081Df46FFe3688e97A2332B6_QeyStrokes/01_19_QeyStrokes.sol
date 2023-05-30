/**
    Baushaus: https://www.baushaus.xyz/
 */

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "./interfaces/IRandom.sol";

contract QeyStrokes is ERC1155Burnable, Ownable, ReentrancyGuard, Pausable, PaymentSplitter {
    using Strings for uint256;
    string public tokenURI = "https://ipfs.io/ipfs/QmUZ2QJrnmFymgEiyZdGsU1Z3q6vK96PxQ3QjvMzdYGmtA/";
    bytes32 public root;
    uint256 public cost = 0.1 ether;
    bool public whitelistActive = false;
    bool public burnActive = false;
    uint256 public supply;
    uint256 public tokenId = 0;    
    uint256 public max = 1;
    string public extension = ".json";
    IRandom private rng;
    mapping(uint256 => uint256) parcelCount;
    mapping(uint256 => uint256) tokenToParcel;    
    mapping(address => uint256) holdings;
    address[] _addresses = [
        // dev wallet
        0x99151DEd55907fd2A256C882EA5c16D3f84340C9,
        // owner wallet
        0x5f4D7F30583D321909d61fd54e4612072917b023,
        // owner wallet
        0x9c48A44fAe51EA948259E3fea93461Fb8989246e
    ];
    uint256[] _shares = [1750 ,4215, 4215];
    event ParcelMinted(uint256 tokenId, uint256 parcelID, address owner);
    event GenesisMinted(uint256 tokenId, uint256[] tokenIds, uint256[] parcelIDs, address owner);
    
    constructor(uint256 parcel1, uint256 parcel2, uint256 parcel3, uint256 parcel4, IRandom _rng, bytes32 _root) ERC1155(tokenURI) PaymentSplitter(_addresses, _shares) {
        parcelCount[1] = parcel1;
        parcelCount[2] = parcel2;
        parcelCount[3] = parcel3;
        parcelCount[4] = parcel4;
        setSupply(parcel1 + parcel2 + parcel3 + parcel4);
        rng = _rng;
        root = _root;
        pause();
    }

    function contractURI() public view returns (string memory) {
        return "https://ipfs.io/ipfs/QmV83ZHZwwFm7sAiipxFxJZKjsmMiFxW5nHWRifZXcQQgY";
    }

    function whitelistMint(uint256 _amount, uint256 _tokenId, bytes32[] calldata proof) external payable nonReentrant {
        require(whitelistActive, "Whitelist is not active");
        require(_verify(_leaf(_msgSender(), _tokenId), proof), "Invalid");
        require(holdings[_msgSender()] + _amount <= _tokenId, "Cannot exceed allocated");
        require(_amount * cost == msg.value, "Incorrect ETH");
        callMint(_amount);
        holdings[_msgSender()] += _amount;
    }

    function adminMint() external nonReentrant onlyOwner {
        callMint(1);
    }

    function mint(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(_amount <= max, "Cannot be more than max");
        require(_amount * cost == msg.value, "Incorrect ETH");
        callMint(_amount);
    }

    /**
        @dev filter out all parcels with supply > 0
        randomly choose one from the filtered list
     */
    function getParcelID(uint256 _tokenId) internal view returns (uint256) {
        uint256 resultCount;

        for(uint256 i = 1; i <= 4; i++) {
            if (parcelCount[i] > 0) { 
                resultCount++;
            }
        }

        require(resultCount > 0);

        uint256[] memory result = new uint256[](resultCount);
        uint256 j;

        for (uint256 i = 1; i <= 4; i++) {
            if (parcelCount[i] > 0) {
                result[j] = i;
                j++;
            }
        }
        uint256 _index = rng.random(_tokenId) % result.length;
        return result[_index];
    }

    /**
        @dev utility function for public mint and whitelist mint
        get parcel ID, decrement supply of parcel id and update
        mapping of token and parcelID for burn reference
     */
    function callMint(uint256 amount) internal {
        require(tokenId + amount <= supply, "Cannot exceed");
        for(uint256 i; i < amount; i++) {
            uint nextToken = tokenId + i;
            uint256 _parcelID = getParcelID(nextToken);
            parcelCount[_parcelID] -= 1;
            _mint(_msgSender(), nextToken, 1, "");
            tokenToParcel[nextToken] = _parcelID;            
            emit ParcelMinted(nextToken, _parcelID, _msgSender());
        }        
        tokenId += amount;
    }

    /** ================== ADMIN ONLY FUNCTIONS ================== */

    function setMax(uint256 _max) external onlyOwner {
        max = _max;
    }

    function toggleWhitelist() external onlyOwner {
        whitelistActive = !whitelistActive;
    }

    function toggleBurnActive() external onlyOwner {
        burnActive = !burnActive;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setSupply(uint256 _supply) public onlyOwner {
        supply = _supply;
    }

    function setExtension(string memory _extension) external onlyOwner {
        extension = _extension;
    }

    function setURI(string memory _tokenURI) external onlyOwner {
        tokenURI = _tokenURI;
    }

    function parcelID(uint256 id) public view returns (uint256) {
        return tokenToParcel[id];
    }

    function uri(uint256 id) public view override returns (string memory) {
	    return bytes(tokenURI).length > 0	? string(abi.encodePacked(tokenURI, id.toString(), extension)) : "";
    }

    /**
        @dev burning a single parcel 4 will mint a genesis that exceeds 3939
        emit event for subgraph to categorize correct genesis (should be category 6)
     */
    function burnOne(uint256 id) external {
        require(burnActive, "Burn not active");
        require(tokenToParcel[id] == 4, "First should be parcel 4");
        _burn(_msgSender(), id, 1);
        _mint(_msgSender(), tokenId, 1, "");        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = id;
        uint256[] memory parcelIDs = new uint256[](1);
        parcelIDs[0] = tokenToParcel[id];
        emit GenesisMinted(tokenId, tokenIds, parcelIDs, _msgSender());
        tokenId++;
    }

    /**
        @dev burn 3 parcels of type 1,2 and 3 to mint a genesis that exceeds 3939
        emit event for subgraph to categorize correct genesis (categories 1 - 6)
     */
    function burnThree(uint256[] memory ids) external {
        require(burnActive, "Burn not active");
        uint256 first = ids[0];
        uint256 second = ids[1];
        uint256 third = ids[2];
        require(tokenToParcel[first] == 1, "First should be parcel 1");
        require(tokenToParcel[second] == 2, "Second should be parcel 2");
        require(tokenToParcel[third] == 3, "Third should be parcel 3");        
        uint256[] memory burnAmount = new uint256[](3);
        burnAmount[0] = 1;
        burnAmount[1] = 1;
        burnAmount[2] = 1;
        _burnBatch(_msgSender(), ids, burnAmount);
        _mint(_msgSender(), tokenId, 1, "");        
        uint256[] memory parcelIDs = new uint256[](3);
        parcelIDs[0] = tokenToParcel[first];
        parcelIDs[1] = tokenToParcel[second];
        parcelIDs[2] = tokenToParcel[third];
        emit GenesisMinted(tokenId, ids, parcelIDs, _msgSender());
        tokenId++;
    }

    function _leaf(address account, uint256 _tokenId)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_tokenId, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}