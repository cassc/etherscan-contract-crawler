pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';

contract Matos is ERC1155, ERC1155Supply, Ownable {
  uint256 constant TOKEN_PRICE = 0.02 ether;
  uint256 public constant MAX_TOKENS = 100;

  bytes32 public immutable merkleRoot;

  mapping(address => bool) public userClaimed;

  constructor(bytes32 _merkleRoot)
    ERC1155('https://gateway.pinata.cloud/ipfs/QmQxo8Jogon3DaC59y1CjVWHns9QiQDbxr9fQPdo5VpbPY/{id}')
  {
    merkleRoot = _merkleRoot;
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  function mint() public payable {
    require(totalSupply(0) + 1 <= MAX_TOKENS, 'Purchase would exceed max supply of tokens');
    require(TOKEN_PRICE == msg.value, 'Ether value sent is not correct');
    _mint(msg.sender, 0, 1, '');
  }

  function onSaleMint(bytes32[] calldata proof) external payable {
    require(totalSupply(0) + 1 <= MAX_TOKENS, 'Purchase would exceed max supply of tokens');
    require(!userClaimed[msg.sender], 'Address already claimed');

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, msg.value));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    require(isValidLeaf, 'Address is not elegible for mint with discount');

    _mint(msg.sender, 0, 1, '');

    userClaimed[msg.sender] = true;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal override(ERC1155, ERC1155Supply) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }
}