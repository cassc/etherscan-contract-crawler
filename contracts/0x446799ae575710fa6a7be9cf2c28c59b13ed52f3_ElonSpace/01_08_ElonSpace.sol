// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "ERC721A/extensions/ERC721AQueryable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract ElonSpace is ERC721A, ERC721AQueryable, Ownable {
    uint256 public constant TOKEN_PRICE = 0.69 ether;
    uint256 public constant MAX_PER_ADDRESS = 2;
    uint256 public constant MAX_TOKEN_SUPPLY = 420;

    bool public hasMintedTreasury;
    string private baseURI;

    uint256 public publicSaleStart;
    mapping(address => uint256) public totalMinted;

    bytes32 public reserveRoot;
    mapping(address => bool) public hasMintedReserve;

    constructor() ERC721A("ElonSpace", "ELON") {}

    function setReserveRoot(bytes32 newRoot) public onlyOwner {
        reserveRoot = newRoot;
    }

    function setPublicSaleStart(uint256 newStart) public onlyOwner {
        publicSaleStart = newStart;
    }

    function setBaseURI(string calldata newURI) public onlyOwner {
        baseURI = newURI;
    }

    function canMintPublic(address sender, uint256 amount) public view returns(bool) {
        return publicSaleStart != 0
            && block.timestamp > publicSaleStart
            && totalSupply() + amount <= MAX_TOKEN_SUPPLY
            && totalMinted[sender] + amount <= MAX_PER_ADDRESS;
    }

    function canMintReserve(address sender, uint256 amount) public view returns(bool) {
        return reserveRoot != bytes32(0)
            && totalSupply() + amount <= MAX_TOKEN_SUPPLY
            && totalMinted[sender] + amount <= MAX_PER_ADDRESS;
    }

    function mintPublic() public payable {
        uint256 amount = msg.value / TOKEN_PRICE;
        require(msg.value % TOKEN_PRICE == 0, "ElonSpace: invalid amount");
        require(canMintPublic(msg.sender, amount), "ElonSpace: cannot mint");
        totalMinted[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    function mintReserved(bytes32[] calldata proof, uint256 proofAmount, uint256 amount) public payable {
        require(proofAmount >= amount, "ElonSpace: mint over reserve");
        require(canMintReserve(msg.sender, amount), "ElonSpace: cannot mint");
        require(msg.value == TOKEN_PRICE * amount, "ElonSpace: invalid amount");
        require(MerkleProof.verify(proof, reserveRoot, keccak256(abi.encodePacked(msg.sender, proofAmount))), "ElonSpace: invalid proof");
        totalMinted[msg.sender] += amount;
        _mint(msg.sender, amount);
    }

    function mintTreasury(address _to) public onlyOwner {
        require(!hasMintedTreasury);
        hasMintedTreasury = true;
        _mint(_to, 40);
    }

    function withdrawAll(address _to) public onlyOwner {
        (bool success,) = _to.call{value: address(this).balance}("");
        require(success);
    }

    function _baseURI() internal view override returns(string memory) {
        return baseURI;
    }
}