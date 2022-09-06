// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TUBBYPXGAN is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 2999;
    uint256 public FREE_MINT_SUPPLY = 1000;

    uint256 public mintPrice = 0.02 ether;

    string private tokenBaseURI;

    bytes32 public merkleRoot;
    mapping(address => uint256) public whitelistMinted;

    bool airdropped;
    bool saleOpen;

    constructor(bytes32 _merkleRoot) ERC721A("tubbypxgan", "TUBBYPXGAN") {
        merkleRoot = _merkleRoot;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(tokenBaseURI, tokenId.toString()));
    }

    function setTokenBaseURI(string calldata tokenBaseURI_) external onlyOwner {
        tokenBaseURI = tokenBaseURI_;
    }

    function changeSaleState() external onlyOwner {
        saleOpen = !saleOpen;
    }

    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function changePrice(uint256 price_) external onlyOwner {
        mintPrice = price_;
    }

    function airdrop(address[] memory airdropAddresses) external onlyOwner { 
        require(airdropped == false, "already airdropped");
        for(uint i = 0; i < airdropAddresses.length; i++){
            _mint(airdropAddresses[i], 1);
        }
        FREE_MINT_SUPPLY -= airdropAddresses.length;
        airdropped = true;
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

function whitelistMint(bytes32[] calldata _merkleProof, uint256 amountToMint, uint256 merkleProofAmount) external {
    require(saleOpen, "sale has not started");
    require(totalSupply() <= MAX_SUPPLY, "token supply reached");
    whitelistMinted[msg.sender] += amountToMint;
    require(whitelistMinted[msg.sender] <= merkleProofAmount, "you have no more free mints");

    FREE_MINT_SUPPLY -= amountToMint;
    
    _mint(msg.sender, amountToMint);
    
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, merkleProofAmount.toString()));
    require(
        MerkleProof.verify(_merkleProof, merkleRoot, leaf),
        "Invalid Merkle Proof."
    );
}

    function publicMint(uint256 amountToMint) public payable {
        require(saleOpen, "sale has not started");
        require(amountToMint <= 50, "max mintable is 50");
        uint cost;
        unchecked {
            cost = amountToMint * mintPrice;
        }
        require(msg.value == cost, "must pay correct mint price");
        _mint(msg.sender, amountToMint);
        require(totalSupply() <= MAX_SUPPLY, "token supply reached");
    }
}