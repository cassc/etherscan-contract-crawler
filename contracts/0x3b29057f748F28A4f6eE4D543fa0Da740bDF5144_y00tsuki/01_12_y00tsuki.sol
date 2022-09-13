//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/cryptography/MerkleProof.sol";

contract y00tsuki is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant maxSupply = 2002;
    uint256 public cost = 0.0033 ether;
    uint256 public allowQ;
    bytes32 private merkleRoot;
    bytes32 private merkleRoot2;
    bool public premintActive;
    bool public pubActive;
    string private baseURI;
    bool public appendedID;
    mapping(address => uint256) public _mintedFreeAmountHolders;
    mapping(address => uint256) public _mintedFreeAmountWL;
    mapping(address => uint256) public _pubFreeMintAmount;

    constructor() ERC721A("y00tsuki Yacht Club", "Y00TSUKI") {
    }

    function mintFreeHolder(uint256 _quantity, bytes32[] memory _merkleProof) external payable {
        require(_quantity > 0);
        uint256 supply = totalSupply();
        allowQ = getWL(msg.sender);
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(supply + _quantity <= maxSupply, "Cant go over supply");
        require(premintActive, "PREMINTSALE_INACTIVE");
        require(_mintedFreeAmountHolders[msg.sender] + _quantity <= allowQ, "HOLDERSALEFREE_MAXED");
        unchecked {
            _mintedFreeAmountHolders[msg.sender] += _quantity;
        }
        _safeMint(msg.sender, _quantity);
    }

    function mintPaidHolder(uint256 _quantity, bytes32[] memory _merkleProof) external payable {
        require(_quantity > 0);
        uint256 supply = totalSupply();
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
        require(supply + _quantity <= maxSupply, "Cant go over supply");
        require(premintActive, "PREMINTSALE_INACTIVE");
        require(msg.value >= cost * _quantity, "INCORRECT_ETH");
        _safeMint(msg.sender, _quantity);
    }

    function mintFreePublic() external payable {
        uint256 s = totalSupply();
        require(s + 1 <= maxSupply, "Cant go over supply");
        require(pubActive, "PUBLIC_INACTIVE");
        require(_pubFreeMintAmount[msg.sender] + 1 <= 1, "PUBLICPAID_MAXED");
        unchecked {
            _pubFreeMintAmount[msg.sender] += 1;
        }
        _safeMint(msg.sender, 1);
    }

    function mintPaidPublic(uint256 _quantity) external payable {
        require(_quantity > 0);
        uint256 s = totalSupply();
        require(s + _quantity <= maxSupply, "Cant go over supply");
        require(pubActive, "PUBLIC_INACTIVE");
        require(msg.value >= cost * _quantity, "INCORRECT_ETH");
        _safeMint(msg.sender, _quantity);
    }

    function gift(address _account, uint256 _quantity)
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

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function activatePremintSale() external onlyOwner {
        !premintActive ? premintActive = true : premintActive = false;
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