// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMRC721.sol";
import "./IUtherTrunks.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract UtherTrunksWlMinter is Ownable {

//   using ECDSA for bytes32;

  uint256 public unitPrice = 0.35 ether;
  uint256 public startTime = 1662760800;
  bytes32 public merkleRoot = 0xafe2212a583285e0f8cd127b2d9d934fa49c47211751d3461c10f11d4b9db432;

  IUtherTrunks public nftContract = IUtherTrunks(0xF37795C4FD07796B4371F08c9567cEE596dF238F);

  constructor(){}

  modifier isValidMerkleProof(address _to, bytes32[] calldata _proof) {
    if (!MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_to)))) {
      revert("Invalid access list proof");
    }
    _;
  }

  function mint(
    address _to,
    uint256 id,
    uint _count,
    bytes32[] calldata _proof
  ) public payable isValidMerkleProof(_to, _proof) {
    require(block.timestamp >= startTime, "not started");
    require(msg.value >= price(_count), "value");
    nftContract.privateMint(_to, id, _count, '0x');
  }

  function price(uint _count) public view returns (uint256) {
    return _count * unitPrice;
  }

  function updateUnitPrice(uint256 _unitPrice) public onlyOwner {
    unitPrice = _unitPrice;
  }

  function updateStartTime(uint256 _startTime) public onlyOwner {
    startTime = _startTime;
  }

  function setMerkleRoot(bytes32 _root) external onlyOwner {
    merkleRoot = _root;
  }

  function updateNftContrcat(IUtherTrunks _newAddress) public onlyOwner {
    nftContract = IUtherTrunks(_newAddress);
  }

  // allows the owner to withdraw tokens
  function ownerWithdraw(uint256 amount, address _to, address _tokenAddr) public onlyOwner{
    require(_to != address(0));
    if(_tokenAddr == address(0)){
      payable(_to).transfer(amount);
    }else{
      IERC20(_tokenAddr).transfer(_to, amount);
    }
  }
}