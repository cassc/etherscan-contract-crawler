// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract TokyoClone is ERC721A, Ownable {
    bytes32 public merkleRoot;
    string public baseTokenURI;

    uint256 public MAX_SUPPLY = 3333;
    uint256 public MAX_PER_PRESALE = 2;
    uint256 public MAX_PER_TX = 3;
    uint256 public PRESALE_PRICE = 0.049 ether;
    uint256 public PRICE = 0.059 ether;
    uint256 public STATUS;

    address private GUNDY = 0x82F1CaA00a11b9C0A7508808232455F4C3B6c9Bf;
    address private YAKUZA = 0x2ECbfc217e9368Dc63eDdf2e855488CbF456E408;

    constructor() ERC721A("TokyoClone", "TOKYOCLONE") {}

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

    function numberMinted(address _address)
        public
        view
        returns (uint256 amount)
    {
        return _numberMinted(_address);
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

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _withdraw(YAKUZA, (balance * 100) / 1000);
        _withdraw(GUNDY, (balance * 75) / 1000);
        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    
}