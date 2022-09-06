// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Alpha is ERC1155, Ownable, ReentrancyGuard {
    string public name = "Alpha Escola de NFT";
    string public symbol = "CHAVEALPHA";
    uint256 public price = 0 ether;
    uint16 public maxSupply = 5000;

    //Reserves are minted automatically on contract deployment.
    uint8 public reservedSupply = 10;

    bool public paused = false;

    uint8 public chaveIndex = 0;
    uint8 public totalMinted = 0;

    bytes32 public allowlistMerkle = 0x506aa4866c365d1fb54fe6150e07c3f0b0e764bfa720c94b2d01a37dccecd148;

    mapping (address => bool) public _minted;

    constructor() ERC1155("ipfs://QmTWzGFxixsQhPCAXwTzZ9vd5Tp8Rr9Q9HGpDjyhqNqz9Z") {
        _mint(msg.sender, chaveIndex, reservedSupply, "");
        totalMinted+= 10;
    }

    // Mints

    function mint(bytes32[] calldata _merkleProof) public payable nonReentrant {
        require(!paused, "Alpha: Contrato esta pausado.");
        require(msg.value >= price, "Alpha: Valor insuficiente.");
        require(!_minted[msg.sender], "Alpha: Cada carteira so pode mintar uma Chave.");
        require(totalMinted < maxSupply, "Alpha: Supply maximo atingido.");

        //Check sender is on whitelist.
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));        
        require(MerkleProof.verify(_merkleProof, allowlistMerkle, leaf), "Alpha: Merkle proof invalido (nao esta na AL?).");

        _mint(msg.sender, chaveIndex, 1, "");

        _minted[msg.sender] = true;
        totalMinted += 1;        
    }

    function mintOwner(uint8 amount) public onlyOwner nonReentrant {
        require(!paused, "Alpha: Contrato esta pausado.");
        require(totalMinted < maxSupply, "Alpha: Supply maximo atingido.");

        _mint(msg.sender, chaveIndex, amount, "");

        totalMinted += amount;
    }

    // Write functions

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setAllowlistMerkle(bytes32 _merkleRoot) public onlyOwner {
        allowlistMerkle = _merkleRoot;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Call functions

    function hasToken(address account) public view returns (bool) {
        return balanceOf(account, chaveIndex) > 0;
    }

    function getSupplyLeft() public view returns (uint16) {
        return maxSupply - totalMinted;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function totalSupply() external view returns (uint256) {
        return totalMinted;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}