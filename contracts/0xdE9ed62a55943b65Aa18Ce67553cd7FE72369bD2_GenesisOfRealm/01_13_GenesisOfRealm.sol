// SPDX-License-Identifier: MIT

// @creator:     GenesisOfRealm
// @author:      Aytaç BİÇER - twitter.com/aytacbicerdev
// @website:     https://genesisofrealm.com/

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GenesisOfRealm is ERC721A, Ownable {
    using Strings for uint256;    
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant MAX_MINT = 2;
    uint256 public constant MAX_PUBLIC_MINT = 1;
    uint256 public constant SALE_WL_PRICE = 0 ether;
    uint256 public constant SALE_PRICE = 0.02 ether;

    string private baseTokenUri;
    string public placeholderTokenUri ="https://metadata.genesisofrealm.com/hidden.json";

    bool public isRevealed;
    bool public publicSale;
    bool public whiteListSale;    

    bytes32 private merkleRootWhite;    
    // Minted count per stage per wallet.    
    mapping(address => uint256) public totalMint;

    constructor(bytes32 _merklerootWhite)
        ERC721A("Genesis Of Realm", "GOR")
    {
        merkleRootWhite = _merklerootWhite;        
    }

    // ====== Settings ======
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    function _startTokenId() internal pure override returns (uint256){
        return 1;
    }

    function mint(uint256 _quantity) external payable callerIsUser {
        require(publicSale, "Public Sale Is Not Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require((totalMint[msg.sender] + _quantity) <= MAX_PUBLIC_MINT,"Beyond public max mint!");      
        require(msg.value >= (SALE_PRICE * _quantity), "Payment is below the price");

        totalMint[msg.sender] += _quantity;        
        _safeMint(msg.sender, _quantity);       
    }

    function whitelistMint(bytes32[] memory _merkleProof, uint256 _quantity) external payable callerIsUser {
        require(whiteListSale, "Whitelist Sale Is Not Active.");
        require((totalSupply() + _quantity) <= MAX_SUPPLY,"Beyond Max Supply");
        require((totalMint[msg.sender] + _quantity) <= MAX_MINT,"Beyond whitelist max mint!");
        require(msg.value >= (SALE_WL_PRICE * _quantity),"Payment is below the price");

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRootWhite, sender),"You are not whitelisted");
        
        totalMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }    

    function ownerMint(uint256 _quantity) external onlyOwner {
        require(_quantity > 0, "need to mint at least 1 NFT");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        
        _safeMint(msg.sender, _quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"URI query for nonexistent token");

        if (!isRevealed) {
            return placeholderTokenUri;
        }        
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, tokenId.toString(), ".json")) : "";
    }

    /// @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256[] memory a = new uint256[](balanceOf(owner));
            uint256 end = _currentIndex;
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            for (uint256 i; i < end; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    a[tokenIdsIdx++] = i;
                }
            }
            return a;
        }
    }

    function isValidWhiteList(bytes32[] memory proof, bytes32 leaf) public view returns (bool)
    {
        return MerkleProof.verify(proof, merkleRootWhite, leaf);
    }    

    function setTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner {
        placeholderTokenUri = _placeholderTokenUri;
    }

    function setMerkleRootWhite(bytes32 _merkleRoot) external onlyOwner {
        merkleRootWhite = _merkleRoot;
    }    

    function getMerkleRootWhite() external view returns (bytes32) {
        return merkleRootWhite;
    }        

    function toggleWhiteListSale() external onlyOwner {
        whiteListSale = !whiteListSale;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner {
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner {        
        payable(msg.sender).transfer(address(this).balance);
    }
}