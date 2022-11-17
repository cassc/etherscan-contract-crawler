// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/INFTSport.sol";

import "../libraries/Utils.sol";
import "../libraries/TransferHelper.sol";

import "./ERC1155.sol";

contract MysteryCube is ERC1155, Ownable, AccessControl, ReentrancyGuard {
  using SafeMath for uint256;
  using Utils for uint256;
  using Strings for string;
  using Address for address;

  enum CubeTier {
    Bronze,
    Silver,
    Diamond
  }

  enum NFTTier {
    Tier0,
    Tier1,
    Tier2,
    Tier3
  }

  struct CubeInfo {
    uint256[4] weights;
  }

  struct NFTInfo {
    NFTTier tier;
    uint256 weight;
    uint256 totalSupply;
  }

  struct UserInfo {
    address referrer;
    uint256 referrals;
    uint256 commissions;
    uint256 claimed;
    uint256 timestamp;
  }

  uint256 public constant COMMISSION_BPS = 1000;

  INFTSport public nft;

  uint256[] public ids = [0, 1, 2];
  uint256[] public amounts = [224_000, 64_000, 32_000];
  uint256 public NUMBER_OF_BOXES = 320_000;
  uint256[] public prices = [0.02 ether, 0.04 ether, 0.08 ether];

  mapping(CubeTier => CubeInfo) internal cubeInfo;
  mapping(uint256 => uint256) public tokenSupply;

  uint256 public constant NUMBER_OF_TEAMS = 32;
  mapping(uint256 => NFTInfo) public nftInfo;

  mapping(address => UserInfo) public userInfo;

  event OpenCube(address indexed account, uint256 teamId, uint256 tokenId, address indexed referrer);
  event ClaimCommissions(address indexed account, uint256 amount);

  constructor(string memory _uri, INFTSport _nft) public ERC1155(_uri) {
    nft = _nft;
    cubeInfo[CubeTier.Bronze] = CubeInfo([uint256(1), 6, 30, 63]);
    cubeInfo[CubeTier.Silver] = CubeInfo([uint256(5), 35, 60, 0]);
    cubeInfo[CubeTier.Diamond] = CubeInfo([uint256(20), 80, 0, 0]);
    _mintBatch(msg.sender, ids, amounts, bytes(""));
  }

  receive() external payable {}

  uint256 public startTime;
  modifier whenOpenCubeEnabled() {
    require(block.timestamp >= startTime, "whenOpenCubeEnabled: not enabled");
    _;
  }

  function updateOpenCubeEnabled(uint256 _startTime) external onlyOwner {
    startTime = _startTime;
  }

  function totalSupply(uint256 _id) public view returns (uint256) {
    return tokenSupply[_id];
  }

  function _mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory data
  ) internal virtual override {
    super._mintBatch(_to, _ids, _amounts, data);
    for (uint256 i = 0; i < ids.length; i += 1) {
      tokenSupply[ids[i]] = amounts[ids[i]];
    }
  }

  function updateNFTTiers(NFTTier[NUMBER_OF_TEAMS] memory _tiers) external onlyOwner {
    for (uint8 i = 0; i < NUMBER_OF_TEAMS; i += 1) {
      nftInfo[i].tier = _tiers[i];
    }
  }

  function updateWeights(uint256[NUMBER_OF_TEAMS] memory _weights) external onlyOwner {
    for (uint8 i = 0; i < NUMBER_OF_TEAMS; i += 1) {
      nftInfo[i].weight = _weights[i];
    }
  }

  function updateWeight(uint8 _i, uint256 _weight) external onlyOwner {
    nftInfo[_i].weight = _weight;
  }

  function open(uint256 _id) external whenOpenCubeEnabled nonReentrant {
    require(!address(msg.sender).isContract(), "open: only EOA");
    require(balanceOf(msg.sender, _id) > 0, "open: invalid balance");
    _burn(msg.sender, _id, 1);
    CubeInfo storage _cubeInfo = cubeInfo[CubeTier(_id)];
    uint256 teamId = _getRandomId(_cubeInfo);
    uint256 tokenId = nft.mint(msg.sender, teamId);
    nftInfo[teamId].totalSupply = nftInfo[teamId].totalSupply.add(1);
    UserInfo memory user = userInfo[msg.sender];
    if (user.referrer != address(0)) {
      userInfo[user.referrer].commissions = userInfo[user.referrer].commissions.add(
        prices[_id].mul(COMMISSION_BPS).div(10_000)
      );
    }
    emit OpenCube(msg.sender, teamId, tokenId, user.referrer);
  }

  function _getRandomId(CubeInfo memory _cubeInfo) internal view returns (uint256) {
    uint256 totalWeight = 0;
    uint256[] memory weights = new uint256[](NUMBER_OF_TEAMS);
    for (uint8 i = 0; i < weights.length; i += 1) {
      NFTInfo memory _nftInfo = nftInfo[i];
      if (_nftInfo.totalSupply < NUMBER_OF_BOXES.divRoundUp(NUMBER_OF_TEAMS)) {
        weights[i] = _nftInfo.weight.mul(_cubeInfo.weights[uint256(_nftInfo.tier)]);
        totalWeight = totalWeight.add(weights[i]);
      }
    }
    uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))).mod(
      totalWeight
    );
    for (uint8 i = 0; i < NUMBER_OF_TEAMS; i += 1) {
      if (weights[i] > random) {
        return i;
      }
      random = random.sub(weights[i]);
    }
  }

  function activate(address referrer) external {
    UserInfo storage user = userInfo[msg.sender];
    require(user.timestamp == 0, "activate: account is activated.");
    if (referrer != address(0)) {
      require(userInfo[referrer].timestamp != 0, "activate: referrer is not activated.");
      userInfo[referrer].referrals = userInfo[referrer].referrals.add(1);
    }
    user.referrer = referrer;
    user.timestamp = block.timestamp;
  }

  function claimCommissions() external {
    UserInfo storage user = userInfo[msg.sender];
    require(user.commissions > 0, "claimCommissions: nothing to claim.");
    uint256 amount = user.commissions.sub(user.claimed);
    user.claimed = user.claimed.add(amount);
    TransferHelper.safeTransferETH(msg.sender, amount);
    emit ClaimCommissions(msg.sender, amount);
  }

  function setURI(string memory newuri) external onlyOwner {
    _setURI(newuri);
  }
}