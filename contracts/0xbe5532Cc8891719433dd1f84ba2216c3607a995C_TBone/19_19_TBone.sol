// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract TBone is ERC20Capped, Ownable, ReentrancyGuard {
  bool public phaseOneOpen = false;
  bool public phaseTwoOpen = false;

  // Phase Supply Limit

  uint256 public _phaseOneSupply = 20984691 * 1e18; // phase 1 supply
  uint256 public _phaseTwoSupply = 29849070 * 1e18; // phase 2 supply

  uint256 public _reserveSupply = 18166239 * 1e18; // reserved supply

  address signer;

  struct Claim {
    bool isClaimed;
    address addressClaimed;
  }

  mapping(address => uint256) addressBlockBought;
  mapping(string => bool) signatureUsed;
  mapping(uint256 => Claim) public isTboneClaimed;
  mapping(string => Claim) public isPhaseTwoClaimed;

  constructor(
    uint256 cap, 
    address _signer, 
    address[] memory receipient, 
    uint256[] memory amount
    ) ERC20("TBone", "TBONE") ERC20Capped(cap * 1e18) {
    signer = _signer;
    _mint(msg.sender, _reserveSupply);

    for(uint256 i = 0; i < receipient.length; i++) {
      _mint(receipient[i], amount[i] * 1e18);
    }
  }

  modifier isSecured(uint8 phaseType) {
    require(addressBlockBought[msg.sender] < block.timestamp, "Not allowed to proceed in the same block");
    require(tx.origin == msg.sender, "Sender is not allowed to mint");

    if (phaseType == 1) {
      require(phaseOneOpen, "Phase 1 not active");
    }
    if (phaseType == 2) {
      require(phaseTwoOpen, "Phase 2 not active");
    }
    _;
  }

  function togglePhaseOne() external onlyOwner {
    phaseOneOpen = !phaseOneOpen;
  }

  function togglePhaseTwo() external onlyOwner {
    phaseTwoOpen = !phaseTwoOpen;
  }

  function claimTbonePhaseOne(uint64 expireTime, bytes memory sig, uint256 amount, uint256[] memory tokenIds) external isSecured(1) {
    bytes32 digest = keccak256(abi.encodePacked(msg.sender, amount, expireTime));
    uint256 claim_amount = amount * 1e18;
    require(isAuthorized(sig, digest), "Signature is invalid");
    require(totalSupply() + claim_amount <= _phaseOneSupply + _reserveSupply, "Amount exceeds the phase supply");
    require(totalSupply() + claim_amount <= cap(), "Supply is depleted");
    require(signatureUsed[string(sig)] == false, "Signature is already used");
    require(amount > 0, "Amount should be greater than 0");

    for(uint256 i = 0; i < tokenIds.length; i++) {
      require(!isTboneClaimed[tokenIds[i]].isClaimed, "Already Claimed");
      isTboneClaimed[tokenIds[i]] = Claim(true, msg.sender);
    }
    signatureUsed[string(sig)] = true;
    addressBlockBought[msg.sender] = block.timestamp;
    _mint(msg.sender, claim_amount);
  }

  function claimTbonePhaseTwo(bytes memory sig, uint64 exp, uint256 amount, string[] memory entryId) external isSecured(2) {
    bytes32 digest = keccak256(abi.encodePacked(msg.sender, amount, exp));
    uint256 claim_amount = amount * 1e18;
    require(isAuthorized(sig, digest), "Signature is invalid");
    require(totalSupply() + claim_amount <= _phaseOneSupply + _phaseTwoSupply + _reserveSupply, "Amount exceeds the phase supply");
    require(totalSupply() + claim_amount <= cap(), "Supply is depleted");
    require(signatureUsed[string(sig)] == false, "Signature is already used");
    require(amount > 0, "Amount should be greater than 0");

    for(uint256 i = 0; i < entryId.length; i++) {
      require(!isPhaseTwoClaimed[entryId[i]].isClaimed, "Already Claimed");
      isPhaseTwoClaimed[entryId[i]] = Claim(true, msg.sender);
    }
    
    signatureUsed[string(sig)] = true;
    addressBlockBought[msg.sender] = block.timestamp;
    _mint(msg.sender, claim_amount);
  }

  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
  }

  function setIsClaimed(uint256[] memory _tokenIds, address[] memory owner, bool _isClaimed) external onlyOwner {
    for(uint256 i = 0; i < _tokenIds.length; i++) {
      isTboneClaimed[_tokenIds[i]] = Claim(_isClaimed, owner[i]);
    }
  }

  function isAuthorized(bytes memory sig, bytes32 digest) private view returns (bool) {
    return ECDSA.recover(digest, sig) == signer;
  }
}