//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";


contract SLICEOFHEAVEN is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant maxSupply = 1000;
    uint256 public cost = 0.02 ether;
    uint256 public WLcost = 0.02 ether;
    uint256 public pubCost = 0.04 ether;
    uint256 public holderQ;
    bytes32 private merkleRoot;
    bool public holderSaleActive;
    bool public pubActive;
    string private baseURI;
    bool public appendedID;
    mapping(address => uint256) public holderFreeMintAmount;
    mapping(address => uint256) public holderPaidMintAmount;
    mapping(address => uint256) public whitelistPaidClaimed;
    mapping(address => uint256) public pubPaidMintAmount;

    constructor() ERC721A("Slice of Heaven by BEEBLE", "SLICEOFHEAVEN") {
    }

    function mintFreeHolder(uint256 _quantity, bytes32[] memory _merkleProof) external payable {
        uint256 supply = totalSupply();
        holderQ = getHolderWL(msg.sender);
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(supply + _quantity <= maxSupply, "Cant go over supply");
        require(holderSaleActive, "HOLDERSALE_INACTIVE");
        require(holderFreeMintAmount[msg.sender] + _quantity <= holderQ, "HOLDERSALEFREE_MAXED");
        unchecked {
            holderFreeMintAmount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    function mintPaidHolder(uint256 _quantity, bytes32[] memory _merkleProof) external payable {
        uint256 supply = totalSupply();
        holderQ = getHolderWL(msg.sender);
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(supply + _quantity <= maxSupply, "Cant go over supply");
        require(holderSaleActive, "HOLDERSALE_INACTIVE");
        require(holderPaidMintAmount[msg.sender] + _quantity <= holderQ*2, "HOLDERSALEPAID_MAXED");
        require(msg.value >= cost, "INCORRECT_ETH");
        unchecked {
            holderPaidMintAmount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    function mintPaidWL(uint256 _quantity, bytes32[] memory _merkleProof) public payable {
        require(holderSaleActive, "HOLDERSALE_INACTIVE");
        holderQ = getHolderWL(msg.sender);
        require(holderQ == 0);
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(msg.value >= WLcost);
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(whitelistPaidClaimed[msg.sender] + _quantity <= 2, "WLPAID_MAXED");
        unchecked {
            whitelistPaidClaimed[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
        delete s;
    }


    function mintPaidPublic(uint256 _quantity) external payable {
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(pubActive, "PUBLIC_INACTIVE");
        require(msg.value >= pubCost, "INCORRECT_ETH");
        require(pubPaidMintAmount[msg.sender] + _quantity <= 4, "PUBLICPAID_MAXED");
        unchecked {
            pubPaidMintAmount[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    function treasuryMint(address _account, uint256 _quantity)
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

    function setHolderCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPubCost(uint256 _newCost) public onlyOwner {
        pubCost = _newCost;
    }

    function activateHolderSale() external onlyOwner {
        !holderSaleActive ? holderSaleActive = true : holderSaleActive = false;
    }

    function activatePublicSale() external onlyOwner {
        !pubActive ? pubActive = true : pubActive = false;
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