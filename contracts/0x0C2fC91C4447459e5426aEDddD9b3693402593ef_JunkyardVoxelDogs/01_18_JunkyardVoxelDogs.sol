// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./ERC721A.sol";
import "./Staker.sol";

contract JunkyardVoxelDogs is Ownable, ERC721A {
  IERC721 jyd;
  Staker staker;

  mapping(uint256 => bool) public usedParents;
  uint256 purchaseableLimit = 10000;
  bool public isBreedingActive = false;
  uint256 cost = 0.035 ether;
  mapping(address => uint256) public whitelistMinted;
  uint256 constant whitelistMaxAmount = 5;
  uint256 public whitelistLimit;

  constructor(address _jyd, address _staker) ERC721A("Junkyard VoxelDogs", "JVXD") {
    jyd = IERC721(_jyd);
    staker = Staker(_staker);
  }

  function canMint() public view returns (uint256) {
    if (purchaseableLimit > 10000) {
      return block.timestamp > whitelistLimit ? 2 : 1;
    }
    return 0;
  }

  function checkParent(uint256 tokenId, address account) public view returns (bool) {
    return jyd.ownerOf(tokenId) == account || staker.stakings(address(jyd), account, tokenId) > 0;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
    uint256 limit = _nextTokenId();
    for (uint256 tokenId = 1; tokenId < limit; tokenId++) {
      if (exists(tokenId) && owner == ownerOf(tokenId)) {
        if (index == 0) {
          return tokenId;
        }
        index--;
      }
      if (tokenId > 8007) {
        tokenId = 10000;
      }
    }
    return 0;
  }

  function tokensOfOwner(address owner) public view returns (uint256[] memory) {
    uint256 limit = _nextTokenId();
    uint256 count = 0;
    uint256[] memory result = new uint256[](balanceOf(owner));
    for (uint256 tokenId = 1; tokenId < limit; tokenId++) {
      if (exists(tokenId) && owner == ownerOf(tokenId)) {
        result[count++] = tokenId;
      }
      if (tokenId > 8007 && tokenId < 10000) {
        tokenId = 10000;
      }
      if (count >= result.length) {
        break;
      }
    }
    return result;
  }

  function bredTokens() public view returns (uint256) {
    uint256 count = 0;
    for (uint256 tokenId = 1; tokenId < 8009; tokenId++) {
      if (exists(tokenId)) {
        count++;
      }
    }
    return count;
  }

  function listBredTokens(uint256 start, uint256 end) public view returns (uint256[] memory) {
    require(start <= end, "Start must be less than or equal to end");
    require(end <= 8008, "End must be less than or equal to bredTokens");
    uint256 count = 0;
    uint256[] memory result = new uint256[](end - start);
    for (uint256 tokenId = start; tokenId <= end; tokenId++) {
      if (exists(tokenId)) {
        result[count++] = tokenId;
      }
    }
    return result;
  }

  function breed(uint256[] calldata parents, bool both) public payable {
    require(isBreedingActive, "Breeding is not active");
    require(parents.length == 2, "Too many or too few tokenIds");
    require(!usedParents[parents[0]] && !usedParents[parents[1]], "TokenId already used");
    require(checkParent(parents[0], msg.sender) && checkParent(parents[1], msg.sender), "Must own both parents");
    usedParents[parents[0]] = true;
    usedParents[parents[1]] = true;

    _breed(msg.sender, parents[0]);

    if (both) {
      require(msg.value >= 0.02 ether, "Not enough ether");
      _breed(msg.sender, parents[1]);
    }
  }

  function purchase(uint256 amount) public payable {
    require(amount > 0, "Amount must be greater than 0");
    require(msg.value >= amount * cost, "Not enough ether sent");
    require(_nextTokenId() + amount - 1 <= purchaseableLimit, "Not enough purchaseable");
    _mint(msg.sender, amount);
  }

  function whitelistPurchase(uint256 amount, bytes calldata signature) public payable {
    require(amount > 0, "Amount must be greater than 0");
    require(amount <= whitelistMaxAmount, "You can only purchase 5 at a time");
    require(whitelistMinted[msg.sender] + amount <= whitelistMaxAmount, "You can only own 5 at this stage");
    require(msg.value >= amount * cost, "Not enough ether sent");
    require(_nextTokenId() + amount - 1 <= purchaseableLimit, "Not enough purchaseable");

    bytes32 messageHash = keccak256(abi.encodePacked('vx ascension', address(this), msg.sender));
    bytes32 digest = ECDSA.toEthSignedMessageHash(messageHash);

    address signer = ECDSA.recover(digest, signature);
    require(signer == owner(), "Invalid signature, you are not whitelisted");
    whitelistMinted[msg.sender] += amount;
    _mint(msg.sender, amount);
  }

  function mintAsOwner(uint256 amount) public payable onlyOwner {
    require(amount > 0, "Amount must be greater than 0");
    _mint(msg.sender, amount);
  }

  function setPurchaseable(uint256 value, uint256 c) public onlyOwner {
    require(value >= _nextTokenId(), "Value must be greater than the next tokenId");
    if (purchaseableLimit == 10000) {
      whitelistLimit = block.timestamp + 1 hours;
    }
    purchaseableLimit = value;
    cost = c;
  }

  function setBreedinActive(bool value) public onlyOwner {
    isBreedingActive = value;
  }

  function withdraw() public onlyOwner {
    require(address(this).balance > 0, "No ether to withdraw");
    (bool sent,) = payable(owner()).call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");
  }

  function checkIfParentUsed(uint256[] calldata parents) public view returns (bool[] memory) {
    bool[] memory used = new bool[](parents.length);

    for (uint16 i = 0; i < parents.length; i++) {
      used[i] = usedParents[parents[i]];
    }

    return used;
  }

  function _baseURI() internal pure override returns (string memory) {
    return "https://api.junkyarddogs.io/voxeldogs/?tokenId=";
  }
}