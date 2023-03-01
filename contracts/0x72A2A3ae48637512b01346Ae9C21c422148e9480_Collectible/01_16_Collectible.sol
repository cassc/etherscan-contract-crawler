// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EncodeKey.sol";

contract Collectible is ERC1155 {
  using Strings for uint256;

  string public constant name = "ENCODE Graphics Collectible";
  string public constant symbol = "ENC";

  EncodeKey public encodeKey;

  mapping(address => bool) adminAddresses;

  enum CollectibleType {
    Null,
    Collectible,
    Packdrop,
    Raffle
  }

  struct Issue {
    uint8[] permissions;
    uint256 cost;
    uint128 maxSupply;
    uint128 currentSupply;
    CollectibleType t;
    bool hasPhysicalDelivery;
    address[] thirdPartyAddresses;
    // percentage of cost, 10000 = 100%
    uint256[] thirdPartyFees;
    uint256 startRaffle;
    uint256 endRaffle;
  }

  struct IssueFactory {
    uint256 tokenId;
    uint8[] permissions;
    uint256 cost;
    uint256 supply;
    CollectibleType t;
    bool hasPhysicalDelivery;
    address[] thirdPartyAddresses;
    uint256[] thirdPartyFees;
    // This is used for raffles and packdrops
    uint256[] withPhysicalDelivery;
    uint256 startRaffle;
    uint256 endRaffle;
  }

  struct ExplicitUri {
    string uri;
    bool isExplicit;
  }

  mapping(uint256 => ExplicitUri) public explicitTokenURIs;
  mapping(uint256 => Issue) public issues;
  mapping(uint256 => mapping(uint256 => bool)) public claimed;

  mapping(address => uint256) public nonce;
  mapping(address => uint256) public thirdPartyPayment;

  event PackdropPurchased(address indexed account, uint256 indexed blockId, uint256 quantity);
  event RafflePurchased(address indexed account, uint256 indexed tokenId, uint256 quantity);
  event ClaimedPhysicalDelivery(address indexed account, uint256 indexed tokenId, uint256 quantity);
  
  constructor(address _key) ERC1155("") {
    encodeKey = EncodeKey(_key);
  }

  function getIssue(uint256 _id) public view returns (Issue memory) {
    return issues[_id];
  }

  function getIssues(uint256[] calldata tokenIds) public view returns (Issue[] memory) {
    Issue[] memory result = new Issue[](tokenIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      result[i] = getIssue(tokenIds[i]);
    }
    return result;
  }

  function claimedBatch(uint256[] calldata keyIds, uint256[] calldata tokenIds) public view returns (bool[] memory) {
    require(keyIds.length == tokenIds.length, "keyIds and tokenIds must be the same length");
    bool[] memory result = new bool[](keyIds.length);
    for (uint256 i = 0; i < tokenIds.length; i++) {
      result[i] = claimed[tokenIds[i]][keyIds[i]];
    }
    return result;
  }

  function getKeyType(uint256 keyId) public pure returns (uint8) {
    if (keyId <= 50) {
      return 0;
    } else if (keyId <= 450) {
      return 1;
    } else if (keyId <= 1450) {
      return 2;
    } else {
      return 3;
    }
  }

  function getDiscount(uint8 keyType) public pure returns (uint256) {
    if (keyType == 0) {
      return 80;
    } else if (keyType == 1) {
      return 85;
    } else if (keyType == 2) {
      return 90;
    } else {
      return 0;
    }
  }

  function setTokenUri(uint256 tokenId, string calldata _uri) public {
    require(encodeKey.hasMasterKey(msg.sender), "Only with the master key you can set the token URI");
    explicitTokenURIs[tokenId] = ExplicitUri(_uri, true);
  }

  function editIssue(uint256 tokenId, uint256 cost, uint128 maxSupply) public {
    require(encodeKey.hasMasterKey(msg.sender), "Only with the master key you can set the token URI");
    require(issues[tokenId].t != CollectibleType.Null, "Issue does not exist");
    issues[tokenId].cost = cost;
    issues[tokenId].maxSupply = maxSupply;
  }

  function uri(uint256 tokenId) public view override returns (string memory) {
    if (explicitTokenURIs[tokenId].isExplicit) {
      return explicitTokenURIs[tokenId].uri;
    }
    return string(abi.encodePacked("https://api.encode.network/metadata/collectibles/", tokenId.toString()));
  }

  function checkPermissions(uint256 tokenId, uint256 keyId) internal view {
    require(!claimed[tokenId][keyId], "Token already claimed");
    uint8 keyType = getKeyType(keyId);
    require(encodeKey.ownerOf(keyId) == msg.sender, "Key is not owned by sender");
    for (uint8 i = 0; i < issues[tokenId].permissions.length; i++) {
      if (issues[tokenId].permissions[i] == keyType) {
        return;
      }
    }
    revert("Key is not allowed to use this token");
  }

  function toggleAdminAddress(address _adminAddress) public {
    require(encodeKey.hasMasterKey(msg.sender), "Only users with the master key");
    adminAddresses[_adminAddress] = !adminAddresses[_adminAddress];
  }

  function addIssue(IssueFactory memory issue) public {
    require(issue.t != CollectibleType.Null, "Invalid type");
    require(encodeKey.hasMasterKey(msg.sender), "Only with the master key new issues can be added");
    require(issues[issue.tokenId].t == CollectibleType.Null && issues[100 * uint256(issue.tokenId / 100)].t == CollectibleType.Null, "Token already exists");
    require(issue.permissions.length < 5 && issue.permissions.length > 0, "Permissions must have up to 4 elements");
    require(issue.thirdPartyAddresses.length == issue.thirdPartyFees.length, "thirdPartyAddresses and thirdPartyFees must be the same length");
    if (issue.t == CollectibleType.Packdrop) {
      require(issue.tokenId % 100 == 0, "TokenId must be a multiple of 100");
    } else if (issue.t == CollectibleType.Collectible || issue.t == CollectibleType.Raffle) {
      require(issue.withPhysicalDelivery.length == 0, "Collectibles cannot have multiples physical delivery");
      require(issue.tokenId % 100 != 0, "TokenId must not be a multiple of 100");
    }

    if (issue.t != CollectibleType.Raffle) {
      require(issue.startRaffle == 0 && issue.endRaffle == 0, "Raffle dates must be 0");
    } else {
      require(issue.endRaffle > issue.startRaffle, "Raffle dates must be in the future");
    }

    for (uint256 i = 0; i < issue.withPhysicalDelivery.length; i++) {
      uint256 tokenId = issue.withPhysicalDelivery[i];
      require(100 * uint256(tokenId / 100) == issue.tokenId && (tokenId % 100) < 50, "Incorrect tokenId on packdrop physical delivery");
      issues[tokenId].hasPhysicalDelivery = true;
    }

    for (uint256 i = 0; i < issue.thirdPartyFees.length; i++) {
      require(issue.thirdPartyFees[i] > 0 && issue.thirdPartyFees[i] <= 10000, "Third party fee must be greater than 0 and less or equal than 10k");
    }

    issues[issue.tokenId] = Issue({
      permissions: issue.permissions,
      cost: issue.cost,
      maxSupply: uint128(issue.supply),
      currentSupply: 0,
      t: issue.t,
      hasPhysicalDelivery: issue.hasPhysicalDelivery,
      thirdPartyFees: issue.thirdPartyFees,
      thirdPartyAddresses: issue.thirdPartyAddresses,
      startRaffle: issue.startRaffle,
      endRaffle: issue.endRaffle
    });
  }

  function addSimpleIssues(uint256[] calldata tokenIds, uint8[] calldata permissions, uint256[] calldata costs, uint128[] calldata maxSupply) public {
    require(encodeKey.hasMasterKey(msg.sender), "Only with the master key new issues can be added");
    require(tokenIds.length == permissions.length && tokenIds.length == costs.length && tokenIds.length == maxSupply.length, "tokenIds, permissions, costs and maxSupply must be the same length");
    for (uint256 i = 0; i < tokenIds.length; i++) {
      require(issues[tokenIds[i]].t == CollectibleType.Null, "Token already exists");
      uint8[] memory permissionsArray = new uint8[](1);
      permissionsArray[0] = permissions[i];
      issues[tokenIds[i]] = Issue({
        permissions: permissionsArray,
        cost: costs[i],
        maxSupply: maxSupply[i],
        currentSupply: 0,
        t: CollectibleType.Collectible,
        hasPhysicalDelivery: false,
        thirdPartyFees: new uint256[](0),
        thirdPartyAddresses: new address[](0),
        startRaffle: 0,
        endRaffle: 0
      });
    }
  }

  function claim(uint256 tokenId, uint256[] calldata keyIds) public {
    require(keyIds.length > 0, "No keys to claim");

    if (issues[tokenId].t == CollectibleType.Raffle) {
      require(issues[tokenId].startRaffle <= block.timestamp && issues[tokenId].endRaffle > block.timestamp, "Raffle is not active");
    }

    for (uint16 i = 0; i < keyIds.length; i++) {
      checkPermissions(tokenId, keyIds[i]);
      claimed[tokenId][keyIds[i]] = true;
    }
    Issue storage issue = issues[tokenId];
    if (issue.t == CollectibleType.Packdrop) {
      emit PackdropPurchased(msg.sender, tokenId, keyIds.length);
    } else if (issue.t == CollectibleType.Collectible) {
      _mint(msg.sender, tokenId, keyIds.length, "");
    } else if (issue.t == CollectibleType.Raffle) {
      emit RafflePurchased(msg.sender, tokenId, keyIds.length);
    }
  }

  function purchase(uint256 tokenId, uint256 amount, uint256 keyId) public payable {
    require(amount > 0, "Amount must be greater than 0");
    Issue storage issue = issues[tokenId];
    require(amount <= issue.maxSupply - issue.currentSupply, "Not enough remaining");
    if (issue.t == CollectibleType.Raffle) {
      require(issue.startRaffle <= block.timestamp && issue.endRaffle > block.timestamp, "Raffle is not active");
    }
    uint256 cost = issue.cost;

    if (keyId > 0) {
      require(encodeKey.ownerOf(keyId) == msg.sender, "Key is not owned by sender");
      uint256 discount = getDiscount(getKeyType(keyId));
      cost = cost * discount / 100;
    }

    require(msg.value >= cost * amount, "Not enough ETH");

    issue.currentSupply += uint128(amount);

    if (issue.thirdPartyFees.length > 0) {
      uint256 totalFee = 0;
      for (uint256 i = 0; i < issue.thirdPartyFees.length; i++) {
        uint256 fee = issue.thirdPartyFees[i] * cost / 10000;
        totalFee += fee;
        thirdPartyPayment[issue.thirdPartyAddresses[i]] += fee;
      }
      thirdPartyPayment[address(0)] += totalFee;
    }

    if (issue.t == CollectibleType.Packdrop) {
      emit PackdropPurchased(msg.sender, tokenId, amount);
    } else if (issue.t == CollectibleType.Collectible) {
      _mint(msg.sender, tokenId, amount, "");
    } else if (issue.t == CollectibleType.Raffle) {
      emit RafflePurchased(msg.sender, tokenId, amount);
    }
  }

  function compress(uint256[] memory list) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(list));
  }

  function redeem(uint256[] calldata tokenIds, uint256[] calldata amounts, bytes calldata signature) public {
    require(tokenIds.length > 0 && tokenIds.length == amounts.length, "TokenIds and amounts must have the same length");
  
    bytes32 t = compress(tokenIds);
    bytes32 a = compress(amounts);
    bytes32 messageHash = keccak256(abi.encodePacked('encode packdrop redeem', msg.sender, nonce[msg.sender], t, a));
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);

    address signer = ECDSA.recover(digest, signature);
    require(adminAddresses[signer], "Invalid signature");

    nonce[msg.sender]++;
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _mint(msg.sender, tokenIds[i], amounts[i], "");
    }
  }

  function claimPhysicalDelivery(uint256 tokenId, uint256 amount) public {
    Issue storage issue = issues[tokenId];
    require(issue.hasPhysicalDelivery, "Physical delivery is not enabled for this token");
    require(balanceOf(msg.sender, tokenId) >= amount, "Not enough tokens");
    _burn(msg.sender, tokenId, amount);
    _mint(msg.sender, tokenId + 50, amount, "");
    emit ClaimedPhysicalDelivery(msg.sender, tokenId, amount);
  }

  function withdrawThirdParty(address payable recipient) internal {
    uint256 amount = thirdPartyPayment[recipient];
    thirdPartyPayment[recipient] = 0;
    thirdPartyPayment[address(0)] -= amount;
    (bool sent,) = recipient.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  function withdraw(address payable recipient) public {
    if (thirdPartyPayment[recipient] > 0) {
      return withdrawThirdParty(recipient);
    }
    require(encodeKey.hasMasterKey(msg.sender), "Only with the master key you can withdraw");
    uint256 amount = address(this).balance - thirdPartyPayment[address(0)];
    (bool sent,) = recipient.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }
}