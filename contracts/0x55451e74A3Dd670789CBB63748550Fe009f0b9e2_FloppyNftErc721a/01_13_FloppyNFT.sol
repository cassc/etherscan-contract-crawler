//SPDX-License-Identifier: MIT
/** 
   _______  ___      _______  _______  _______  __   __ 
  |       ||   |    |       ||       ||       ||  | |  |
  |    ___||   |    |   _   ||    _  ||    _  ||  |_|  |
  |   |___ |   |    |  | |  ||   |_| ||   |_| ||       |
  |    ___||   |___ |  |_|  ||    ___||    ___||_     _|
  |   |    |       ||       ||   |    |   |      |   |  
  |___|    |_______||_______||___|    |___|      |___|  
                   By zensein#5412
*/

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract FloppyNftErc721a is ERC721A, Ownable {
    bytes32 public presaleMerkleRoot =
        0x9b92444ae5937c08f92a28f173ab522152ea72d7f0b9280c5784cc4223e6e2a7;
    bytes32 public vipMerkleRoot =
        0xa706c83966f471a85962cd2f5611019ed2390d2f561b0b893066b80d71e3e07f;
    bytes32 public constant FLOPPY_PROVENANCE =
        0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855;

    uint256 public constant TOTAL_COL_SIZE = 10000;
    uint256 public constant MINT_PRICE = 0.07 ether;
    string private _baseTokenURI;
    bool public publicSaleActive;
    bool public presaleActive;

    mapping(address => uint256) public mintList;
    mapping(address => bool) public vipList;

    constructor() ERC721A("Floppy", "FLP") {
        _baseTokenURI = "ipfs://QmRjDWygKKJaGkJCtACBbxXdq5NB7uF4RU7WXua1KMb35z/";
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Caller is contract");
        _;
    }

    modifier onlyPublicSaleActive() {
        require(publicSaleActive, "Public sale is not active");
        _;
    }

    modifier onlyPreSaleActive() {
        require(presaleActive, "Pre-sale is not active");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function vipMint(bytes32[] calldata _merkleProof)
        external
        payable
        onlyPreSaleActive
        callerIsUser
    {
        require(!vipList[msg.sender], "VIP already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, vipMerkleRoot, leaf),
            "Merkle proof invalid"
        );

        vipList[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function whitelistMint(bytes32[] calldata _merkleProof, uint256 quantity)
        external
        payable
        onlyPreSaleActive
        callerIsUser
    {
        require(mintList[msg.sender] + quantity <= 2, "Up to 2 mints allowed");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient funds");
        require(totalSupply() + quantity <= TOTAL_COL_SIZE, "EXCEED_COL_SIZE");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf),
            "Merkle proof invalid"
        );

        mintList[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity)
        external
        payable
        onlyPublicSaleActive
        callerIsUser
    {
        require(mintList[msg.sender] + quantity <= 2, "Up to 2 mints allowed");
        require(msg.value >= MINT_PRICE * quantity, "Insufficient funds");
        require(totalSupply() + quantity <= TOTAL_COL_SIZE, "EXCEED_COL_SIZE");

        mintList[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function togglePreSale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setPresaleMerkleRoot(bytes32 _presaleMerkleRoot)
        external
        onlyOwner
    {
        presaleMerkleRoot = _presaleMerkleRoot;
    }

    function setVipMerkleRoot(bytes32 _vipMerkleRoot) external onlyOwner {
        vipMerkleRoot = _vipMerkleRoot;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        payable(0x99DaD544D50dd3A71F72309731942a8a022E4d39).transfer(
            ((_balance * 1500) / 10000)
        );
        payable(0xB06CCA8aA6527875436be6f944d47904ACf37814).transfer(
            ((_balance * 3235) / 10000)
        );
        payable(0x8d432127A4d579daA0eD3fAAdaeb6C1592738630).transfer(
            ((_balance * 3235) / 10000)
        );
        payable(0x60B802765217f6E6D5f7c6a1444C4354F300330a).transfer(
            ((_balance * 595) / 10000)
        );
        payable(0xC66D69f396e4D00978EC331614ca6b8DBb8DBe02).transfer(
            ((_balance * 425) / 10000)
        );
        payable(0x6a659e987e0E85f516f450689c3321011C589AB8).transfer(
            ((_balance * 255) / 10000)
        );
        payable(0xe1e7D471E854CcbBfaCEfad70692cbbEA058c055).transfer(
            ((_balance * 500) / 10000)
        );
        payable(0xdbe728D8dcC93E5B08279B669812211365F6756c).transfer(
            ((_balance * 255) / 10000)
        );
    }
}