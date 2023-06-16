// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

struct Payment {
  uint256 amount;
  address sender;
  uint256 nonce;
}

contract Crowdfunding is Ownable, EIP712, ReentrancyGuard {
  // Store the amount each address has contributed
  mapping(address => uint256) public contributors;
  uint256 public deadline;
  uint256 public startTime;

  address public masterAddress;

  address public collectorAddress;

  event ChangedDeadLine(uint256 newDeadLine);
  event ChangedStartTime(uint256 newStartTime);

  bytes32 private EIP712_DOMAIN_TYPE_HASH =
    keccak256(
      "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
  bytes32 private DOMAIN_SEPARATOR =
    keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPE_HASH,
        keccak256(bytes("Crowdfunding")),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );

  receive() external payable {
    // contribute();
  }

  constructor() EIP712("Crowdfunding", "1") {}

  function changeDeadLine(uint256 newDeadLine) external onlyOwner {
    deadline = newDeadLine;
    emit ChangedDeadLine(newDeadLine);
  }

  function changeStartTime(uint256 newStartTime) external onlyOwner {
    startTime = newStartTime;
    emit ChangedStartTime(newStartTime);
  }

  function changeMasterAddress(address newAddress) external onlyOwner {
    masterAddress = newAddress;
  }

  function changeCollectorAddress(
    address newCollectorAddress
  ) external onlyOwner {
    collectorAddress = newCollectorAddress;
  }

  function getSignedAddress(
    uint256 amount,
    uint256 maxcontribute,
    bytes memory signature
  ) public view returns (address) {
    bytes32 VALIDATE_BUY = keccak256(
      "Payment(uint256 amount,address sender,uint256 maxcontribute)"
    );
    bytes32 structHash = keccak256(
      abi.encode(VALIDATE_BUY, amount, msg.sender, maxcontribute)
    );
    bytes32 digest = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, structHash);

    address recoveredAddress = ECDSA.recover(digest, signature);
    return recoveredAddress;
  }

  function contribute(
    uint256 amount,
    uint256 maxcontribute,
    bytes memory signature
  ) public payable nonReentrant {
    require(
      block.timestamp >= startTime,
      "The Crowdfunding campaign hasn't started yet."
    );
    require(block.timestamp < deadline, "The Crowdfunding campaign is over.");

    uint256 receivedValue = msg.value;
    address recoveredAddress = getSignedAddress(
      amount,
      maxcontribute,
      signature
    );

    require(
      contributors[msg.sender] + receivedValue <= maxcontribute,
      "You have exceeded contribute limit"
    );

    require(recoveredAddress == masterAddress, "Invalid Signer Address");
    // // Ensure the value sent matches the signed amount
    require(msg.value == amount, "Incorrect value sent");

    (bool sent, bytes memory data) = collectorAddress.call{ value: msg.value }(
      ""
    );
    require(sent, "Failed to send Ether");
    // // Add the contribution to the mapping
    contributors[msg.sender] += receivedValue;
  }
}