// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./MerkleProofLib.sol";

interface IWorm {
  function isDisciple(address _address) external view returns (bool);
}

contract MechFlashPact {
  uint256 constant public DEPOSIT = 0.01 ether;
  uint256 immutable public MAX_JOIN_DEADLINE; 

  address constant private EDWONE = 0xf65D6475869F61c6dce6aC194B6a7dbE45a91c63;
  address constant private MECH = 0xB1763F78e6116228326256292BeBF37aB762cE52;
  address immutable private DEPLOYER;
  address immutable private PACT_LEADER;

  uint256 public joinDeadline;

  mapping(address => uint256) private active;
  bytes32 private merkleRoot;
  address[] private pactMembers;

  constructor(
    address pactLeader,
    bytes32 root,
    uint256 initJoinDeadline
  ) {
    DEPLOYER = msg.sender;
    MAX_JOIN_DEADLINE = block.timestamp + 5 days;
    PACT_LEADER = pactLeader;
    merkleRoot = root;
    joinDeadline = initJoinDeadline;
    pactMembers.push(pactLeader);
  }

  function executePact(address endOfPact) external {
    _onlyPactLeaderOrDeployer();
    require(joinDeadline < block.timestamp && block.timestamp <= _fulfillmentDeadline());

    pactMembers.push(endOfPact);
    uint256 length = pactMembers.length;

    uint256 last;
    uint256 next = 1;
    while (next <= length - 1) {
      if (next == length - 1 || _pactReady(pactMembers[next])) {
        IERC721(MECH).transferFrom(pactMembers[last], pactMembers[next], 0);
        last = next;
        ++next;
      } else {
        ++next;
      }
    }

    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success);
  }

  function joinPact(bytes32[] calldata merkleProof) external payable {
    require(_pactReady(msg.sender));
    require(block.timestamp <= joinDeadline);
    require(msg.value >= DEPOSIT);
    require(active[msg.sender] == 0);
    require(!IWorm(EDWONE).isDisciple(msg.sender));
    require(MerkleProofLib.verify(merkleProof, merkleRoot, keccak256(abi.encodePacked(msg.sender))));

    active[msg.sender] = 1;
    pactMembers.push(msg.sender);
  }

  function extendJoinDeadline(uint256 newDeadline) external {
    _onlyPactLeaderOrDeployer();
    require(
      block.timestamp < joinDeadline &&
      joinDeadline < newDeadline &&
      newDeadline < MAX_JOIN_DEADLINE
    );
    joinDeadline = newDeadline;
  }

  function updateMerkleRoot(bytes32 newRoot) external {
    _onlyPactLeaderOrDeployer();
    merkleRoot = newRoot;
  }

  function withdraw() external {
    require(block.timestamp > _fulfillmentDeadline());
    require(active[msg.sender] > 0);

    active[msg.sender] = 0;
    (bool success, ) = msg.sender.call{value: DEPOSIT}("");
    require(success);
  }

  function _fulfillmentDeadline() private view returns (uint256) {
    return joinDeadline + 24 hours;
  }

  function _onlyPactLeaderOrDeployer() private view {
    require(msg.sender == PACT_LEADER || msg.sender == DEPLOYER);
  }

  function _pactReady(address target) private view returns (bool) {
    return IERC721(MECH).isApprovedForAll(target, address(this));
  }
}