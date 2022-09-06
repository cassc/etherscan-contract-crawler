// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Yuki is ERC721A, Ownable {
    bytes32 public merkleRoot;
    string public baseTokenURI;

    uint256 public MAX_SUPPLY = 2500;
    uint256 public MAX_PER_PRESALE = 5;
    uint256 public MAX_PER_TX = 6;
    uint256 public PRESALE_PRICE = 0.03 ether;
    uint256 public PRICE = 0.04 ether;
    uint256 public STATUS;

    constructor() ERC721A("Yuki", "YUKI") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setStatus(uint256 _status) external onlyOwner {
        STATUS = _status;
    }

    function setPresalePrice(uint256 _price) external onlyOwner {
        PRESALE_PRICE = _price;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function numberMinted(address _address)
        public
        view
        returns (uint256 amount)
    {
        return _numberMinted(_address);
    }

    function ownerMint(uint256 _amount) external payable onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Mint Amount Denied");

        _safeMint(msg.sender, _amount);
    }

    function devMint(address _to, uint256 _amount) external payable onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Mint Amount Denied");

        _safeMint(_to, _amount);
    }

    function mintPresale(bytes32[] calldata _merkleProof, uint256 _amount)
        external
        payable
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(STATUS == 1, "Phase Is Not Active");
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Incorrect Whitelist Proof"
        );
        require(tx.origin == msg.sender, "Contract Denied");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Mint Amount Denied");
        require(
            numberMinted(msg.sender) + _amount <= MAX_PER_PRESALE,
            "Mint Amount Denied"
        );
        require(msg.value >= PRESALE_PRICE * _amount, "Ether Amount Denied");

        _safeMint(msg.sender, _amount);
    }

    function mint(uint256 _amount) external payable {
        require(STATUS == 2, "Phase Is Not Active");
        require(tx.origin == msg.sender, "Contract Denied");
        require(_amount <= MAX_PER_TX, "Mint Amount Denied");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Mint Amount Denied");
        require(msg.value >= PRICE * _amount, "Ether Amount Denied");

        _safeMint(msg.sender, _amount);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}