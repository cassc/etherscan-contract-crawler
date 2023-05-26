// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Puppies is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public nftSupply = 10_000;

    uint256 public claimingStart = 1641585600; // Jan 7 3pm EST
    uint256 public claimingEnd = 1642190400; // Jan 14 3pm EST

    uint256 public publicSaleStart = 1642194000; // Jan 14 4pm EST
    uint256 public publicSaleEnd = 1642366800; // Jan 16 4pm EST
    uint256 public publicSalePrice  = 0.06 ether;

    uint256 public revealDate = 1642546800; // Jan 18th 6pm EST

    string private _placeholderURI;
    string private _baseURIextended;

    uint256 public startingIndexBlock;
    uint256 public offset;

    bytes32 public merkleRoot;
    mapping(address=>uint256) private _claimed;

    Counters.Counter private _tokenSupply;

    constructor() ERC721("Puppies", "BGP") {}

    // claims new puppies
    //
    // kidsHeld corresponds to the number of Bubblegum Kid NFT's held
    // merkleProof is the proof of the merkle tree for the calling address
    function claimPuppies(uint256 kidsHeld, bytes32[] calldata merkleProof, uint256 amountToClaim) external payable returns (uint256, uint256) {
        require(block.timestamp >= claimingStart, "Claiming has not started.");
        require(block.timestamp < claimingEnd, "Claiming has ended.");
        require(merkleRoot != 0, "Merkle root not set yet.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, kidsHeld));
        bool valid = MerkleProof.verify(merkleProof, merkleRoot, leaf);
        
        require(valid, "Valid proof required.");
        require(_claimed[msg.sender] + amountToClaim <= kidsHeld, "Out of claims.");

        _claimed[msg.sender] += amountToClaim;

        return mintPuppies(amountToClaim);
    }

    // purchases new puppies
    function purchasePuppies(uint256 amountToClaim) external payable returns (uint256, uint256) {
        require(block.timestamp >= publicSaleStart, "Public sale has not started yet.");
        require(block.timestamp < publicSaleEnd, "Public sale is over");
        require(amountToClaim * publicSalePrice == msg.value, "Incorrect amount of ether sent.");

        return mintPuppies(amountToClaim);
    }

    function mintPuppies(uint256 amountToClaim) private returns (uint256, uint256) {
        require(amountToClaim > 0, "amount to claim must be positive");
        require(_tokenSupply.current() + amountToClaim <= nftSupply, "Not enough Puppies left.");

        uint256 firstMintId = _tokenSupply.current();

        for (uint256 i = 0; i < amountToClaim; i++) {
            _safeMint(msg.sender, firstMintId + i);
            _tokenSupply.increment();
        }

        if (startingIndexBlock == 0 && (firstMintId + amountToClaim == nftSupply || block.timestamp >= revealDate)) {
            startingIndexBlock = block.number;
        }

        return (firstMintId, amountToClaim);
    }

    function amountClaimed(address account) public view returns (uint256) {
        return _claimed[account];
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPlaceholderURI(string memory placeholderURI_) external onlyOwner() {
        _placeholderURI = placeholderURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();

        if (offset == 0) {
            return _placeholderURI;

        } else {
            uint256 puppyId = tokenId.add(offset) % nftSupply;
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, puppyId.toString(), ".json")) : "";
        }
    }

    function reveal() public onlyOwner {
        require(offset == 0, "Offset is already set.");
        require(startingIndexBlock != 0, "Starting index block is required.");
        require(block.timestamp >= revealDate, "Too early to reveal.");
        
        offset = uint(blockhash(startingIndexBlock)) % nftSupply;
        
        if (block.number.sub(startingIndexBlock) > 255) {
            offset = uint(blockhash(block.number - 1)) % nftSupply;
        }
        
        if (offset == 0) {
            offset = offset.add(1);
        }
   }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}