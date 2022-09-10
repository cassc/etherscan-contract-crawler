//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";


contract FlowerAI is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant maxSupply = 1111;
    uint256 public premintCost = 0.02 ether;
    uint256 public publicCost = 0.03 ether;
    uint256 public cosmicAllow;
    bytes32 private merkleRoot;
    bytes32 private merkleRootWL;
    bool public presaleActive;
    bool public publicsaleActive;
    bool public freeWLActive;
    string private baseURI;
    bool public appendedID;
    mapping(address => uint256) public holderFreeMintCount;
    mapping(address => uint256) public holderPaidMintCount;
    mapping(address => uint256) public whitelistPaidCount;
    mapping(address => uint256) public publicMintCount;

    constructor() ERC721A("Murakami FlowerAI", "FLOWERAI") {
    }

    function mintFreeHolder(uint256 _quantity, bytes32[] memory _merkleProof) external payable {
        require(_quantity > 0);
        uint256 supply = totalSupply();
        cosmicAllow = getCosmicAllow(msg.sender);
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(supply + _quantity <= maxSupply, "Cant go over supply");
        require(presaleActive, "HOLDERSALE_INACTIVE");
        require(holderFreeMintCount[msg.sender] + _quantity <= cosmicAllow, "HOLDERSALEFREE_MAXED");
        unchecked {
            holderFreeMintCount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    function mintPaidHolder(uint256 _quantity, bytes32[] memory _merkleProof) external payable {
        require(_quantity > 0);
        uint256 supply = totalSupply();
        cosmicAllow = getCosmicAllow(msg.sender);
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(supply + _quantity <= maxSupply, "Cant go over supply");
        require(presaleActive, "HOLDERSALE_INACTIVE");
        require(holderPaidMintCount[msg.sender] + _quantity <= cosmicAllow, "HOLDERSALEPAID_MAXED");
        require(msg.value >= premintCost * _quantity, "INCORRECT_ETH");
        unchecked {
            holderPaidMintCount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    function mintFreeWL(uint256 _quantity, bytes32[] memory _merkleProof) public payable {
        require(_quantity > 0);
        require(freeWLActive, "FREEWL_INACTIVE");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRootWL, leaf), 'Invalid proof!');
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(whitelistPaidCount[msg.sender] + _quantity <= 1, "WLPAID_MAXED");
        unchecked {
            whitelistPaidCount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
        delete s;
    }

    function mintPaidWL(uint256 _quantity, bytes32[] memory _merkleProof) public payable {
        require(_quantity > 0);
        require(publicsaleActive, "PUBLICSALE_INACTIVE");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRootWL, leaf), 'Invalid proof!');
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(msg.value >= premintCost * _quantity);
        require(whitelistPaidCount[msg.sender] + _quantity <= 2, "WLPAID_MAXED");
        unchecked {
            whitelistPaidCount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
        delete s;
    }

    function mintPaidPublic(uint256 _quantity) external payable {
        require(_quantity > 0);
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(presaleActive, "PUBLIC_INACTIVE");
        require(msg.value >= publicCost * _quantity, "INCORRECT_ETH");
        require(publicMintCount[msg.sender] + _quantity <= 4, "PUBLICPAID_MAXED");
        unchecked {
            publicMintCount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    function reserveMint(address _account, uint256 _quantity)
        external
        onlyOwner
    {
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Over Supply");
        require(_quantity > 0, "QUANTITY_INVALID");
        _safeMint(_account, _quantity);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMerkleRootWL(bytes32 _merkleRoot) external onlyOwner {
        merkleRootWL = _merkleRoot;
    }

    function setPremintCost(uint256 _newCost) public onlyOwner {
        premintCost = _newCost;
    }

    function setPublicCost(uint256 _newCost) public onlyOwner {
        publicCost = _newCost;
    }

    function activateHolderSale() external onlyOwner {
        !presaleActive ? presaleActive = true : presaleActive = false;
    }

    function activatePublicSale() external onlyOwner {
        !publicsaleActive ? publicsaleActive = true : publicsaleActive = false;
    }

    function activateFreeMintWL() external onlyOwner {
        !freeWLActive ? freeWLActive = true : freeWLActive = false;
    }

    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata _baseURI, bool appendID) external onlyOwner {
        if (!appendedID && appendID) appendedID = appendID; 
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Cannot query non-existent token");
        if (appendedID) {
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
        } else {
            return baseURI;
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawAny(uint256 _amount) public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success);
    }
}