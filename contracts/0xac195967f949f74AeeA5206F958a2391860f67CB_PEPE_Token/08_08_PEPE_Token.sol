// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PEPE_Token is ERC20, ERC20Burnable, Ownable {
    bytes32 public merkleRoot;
    uint256 public cost = 0.00001 ether;
    uint256 public maxTx = 300000 * 10 ** decimals();
    uint256 public _totalSupply;

    mapping(address => uint256) balances;

    constructor() ERC20("Tadpole", "TAD") {
        _totalSupply = 2000000000 * 10 ** decimals();
        balances[owner()] = _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function claim(
        uint256 _mintAmount,
        bytes32[] calldata _merkleProof
    ) public payable {
        require(
            _mintAmount > 0 && _mintAmount <= maxTx,
            "Invalid mint amount!"
        );
        if (isAllowlist(_merkleProof)) {
            require(msg.value >= 0, "Insufficient funds!");
        } else {
            require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        }
        _mint(msg.sender, _mintAmount);
    }

    function airdrop(uint256 _mintAmount, address _to) public payable {
        _mint(_to, _mintAmount);
    }

    function isAllowlist(
        bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(_merkleProof, merkleRoot, leaf)) {
            return true;
        }
        return false;
    }

    function setAllowlist(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxTx(uint256 _maxTx) public onlyOwner {
        maxTx = _maxTx * 10 ** decimals();
    }
}