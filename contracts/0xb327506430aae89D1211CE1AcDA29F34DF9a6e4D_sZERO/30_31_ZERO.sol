// SPDX-License-Identifier: MIT

pragma solidity >=0.8.7 <0.9.0;
import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable-new/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { ERC20CappedUpgradeable, ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable-new/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable-new/access/OwnableUpgradeable.sol";
import { MerkleProofUpgradeable as MerkleProof } from "@openzeppelin/contracts-upgradeable-new/utils/cryptography/MerkleProofUpgradeable.sol";

contract ZERO is OwnableUpgradeable, ERC20PermitUpgradeable {
  using MerkleProof for bytes32[];
  address constant multisig = 0x5E9B37149b7d7611bD0Eb070194dDA78EB11EfdC;
  address public _sZero;
  bytes32 public airdropMerkleRoot;
  mapping(address => bool) airdropClaimed;

  modifier onlysZeroOrOwner() {
    require(msg.sender == owner() || msg.sender == _sZero);
    _;
  }

  function initialize() public initializer {
    __ERC20Permit_init("ZERO");
    __ERC20_init_unchained("ZERO", "ZERO");
    __Ownable_init_unchained();
  }

  function changeSZero(address sZero) public onlyOwner {
    _sZero = sZero;
  }

  function mint(address account, uint256 amount) public onlysZeroOrOwner {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public onlysZeroOrOwner {
    _burn(account, amount);
  }

  // ===== Airdrop =====
  function setAirdropMerkleRoot(bytes32 value) external onlyOwner {
    airdropMerkleRoot = value;
  }

  function isAddressWhitelisted(
    bytes32[] memory proof,
    uint256 _index,
    address _account,
    uint256 _amount
  ) internal view returns (bool) {
    require(airdropMerkleRoot != bytes32(0), "merkle root not initialized");
    return proof.verify(airdropMerkleRoot, keccak256(abi.encodePacked(_index, _account, _amount)));
  }

  function redeemAirdrop(
    bytes32[] memory proof,
    uint256 _index,
    uint256 _amount
  ) public {
    require(isAddressWhitelisted(proof, _index, msg.sender, _amount), "address not part of airdrop");
    require(!airdropClaimed[msg.sender], "airdrop already claimed");
    airdropClaimed[msg.sender] = true;
    _transfer(multisig, msg.sender, _amount);
  }
}