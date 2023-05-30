//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IKaratDistributor.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KaratDistributor is IKaratDistributor {
  string public override baseInfoURI;
  bool public override isActive;

  //Frozen
  address public immutable override owner;
  bytes32 public immutable override merkleRoot;
  uint256 public immutable override reach;
  string public override frozenInfoURI;
  uint256 public override claimedNum;
  mapping(address => bool) public override claimed;

  constructor(
    address _owner,
    bytes32 _merkleRoot,
    uint256 _reach,
    string memory _baseInfoURI,
    string memory _frozenInfoURI
  ) {
    require(_merkleRoot != bytes32(0), "MerkleRoot null");
    require(_reach != 0, "Reach cannot be zero");
    owner = _owner;
    merkleRoot = _merkleRoot;
    reach = _reach;
    claimedNum = 0;
    isActive = true;
    baseInfoURI = _baseInfoURI;
    frozenInfoURI = _frozenInfoURI;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Caller is not the owner");
    _;
  }
  modifier campaignActive() {
    require(isActive, "Campaign is stopped");
    _;
  }

  function stopCampaign() external override onlyOwner campaignActive {
    isActive = false;
    emit CampaignStopped(owner);
  }

  function updateBaseInfoURI(string calldata _baseInfoURI)
    external
    override
    onlyOwner
    campaignActive
  {
    baseInfoURI = _baseInfoURI;
    emit BaseInfoURIUpdated(owner, _baseInfoURI);
  }

  function _verify(
    address account,
    uint256 amount,
    bytes32[] memory merkleProof
  ) internal campaignActive {
    require(claimedNum < reach, "Exceed max claim number");
    require(!claimed[account], "Account has claimed");

    // Verify the merkle proof.
    bytes32 leaf = keccak256(abi.encodePacked(account, amount));
    require(
      MerkleProof.verify(merkleProof, merkleRoot, leaf),
      "AirdropDistributor: Invalid proof."
    );

    // Mark it claimed and send the token.
    claimedNum += 1;
    claimed[account] = true;
  }

  function claim(
    address account,
    uint256 amount,
    bytes32[] memory merkleProof
  ) external virtual override {}
}