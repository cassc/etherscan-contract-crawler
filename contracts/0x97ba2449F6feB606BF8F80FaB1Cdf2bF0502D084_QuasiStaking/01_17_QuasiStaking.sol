// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./interfaces/IQuasiStaking.sol";
import "hardhat/console.sol";

contract QuasiStaking is ReentrancyGuard, Pausable, UUPSUpgradeable, IQuasiStaking {
    using SafeERC20 for IERC20;

    string public name;
    address public operator;
    IERC20 public rewardsToken;
    uint256 public baseTotal;
    IERC721[] public genesisNFT;
    IERC721[] public allianceNFT;
    DistributionData[] public distributions;
    uint256 public lastDistributionsIndex;
    mapping(address => mapping(uint256 => uint256)) public registerTable; // register timestamp set for NFT contract and ID
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public rewardsPaid; // reward be paid in NFT, ID and lastDistributionsIndex
    mapping(uint256 => uint256) public rewardsPaidTotal;

    function initialize(string memory _name, address _operator, address _rewardsToken, uint256 _baseTotal, address[] memory _genesisNFT, address[] memory _allianceNFT) external {
        require(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked("")), "Already initialized");
        super.initializePausable(_operator);
        super.initializeReentrancyGuard();

        name = _name;
        operator = _operator;
        rewardsToken = IERC20(_rewardsToken);
        baseTotal = _baseTotal;

        for(uint256 i = 0; i < _genesisNFT.length; i++) {
          genesisNFT.push(IERC721(_genesisNFT[i]));
        }
        for(uint256 i = 0; i < _allianceNFT.length; i++) {
          allianceNFT.push(IERC721(_allianceNFT[i]));
        }
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function getDistributionData(uint256 index) external view override returns (DistributionData memory) {
      return distributions[index];
    }

    function rewardsUnpaid(address nft, uint256 id) public view override returns (uint256) {
      uint256 registerTime = registerTable[nft][id];

      if (registerTime == 0) {
        return 0;
      }

      uint256 lastDistributionStartTime = distributions[lastDistributionsIndex].startTime;
      uint256 lastDistributionEndTime = distributions[lastDistributionsIndex].endTime;
      uint256 lastDistributionAmount = distributions[lastDistributionsIndex].amount;

      uint256 validTimeStart = registerTime > lastDistributionStartTime ? registerTime : lastDistributionStartTime;
      uint256 validTimeEnd = block.timestamp > lastDistributionEndTime ? lastDistributionEndTime : block.timestamp;
      uint256 validDuration = validTimeEnd - validTimeStart;
      uint256 distrubutionDuration = lastDistributionEndTime - lastDistributionStartTime;

      uint256 paid = rewardsPaid[nft][id][lastDistributionsIndex];
      uint256 stored = lastDistributionAmount * validDuration / distrubutionDuration / baseTotal;

      return stored - paid;
    }

    function batchRewardsUnpaid(address[] memory nfts, uint256[] memory ids) external view override returns (uint256) {
      require((nfts.length > 0) && (ids.length > 0), "Length should be greater than 0");
      require(nfts.length == ids.length, "Length needs to be the same");
      uint256 rewards;
      for (uint256 i = 0; i < nfts.length; i++) {
        rewards = rewards + rewardsUnpaid(nfts[i], ids[i]);
      }
      return rewards;
    }

    function addDistribution(uint256 duration, uint256 amount) external onlyOwner override {
      DistributionData memory distribution = DistributionData(block.timestamp, block.timestamp + duration, amount);
      if (distributions.length != 0) {
        lastDistributionsIndex = lastDistributionsIndex + 1;
      }
      distributions.push(distribution);

      emit AddDistribution(block.timestamp, block.timestamp + duration, amount);
    }

    function _register(address nft, uint256 id, address account) internal {
      require(IERC721(nft).ownerOf(id) == account, "Owner isn't equal to msg.sender");
      require(registerTable[nft][id] == 0, "Already register");
      registerTable[nft][id] = block.timestamp;

      emit Register(nft, id, block.timestamp);
    }

    function register(address nft, uint256 id) external notPaused ownGenesisNFT(msg.sender) override {
      _register(nft, id, msg.sender);
    }

    function batchRegister(address[] memory nfts, uint256[] memory ids) external notPaused ownGenesisNFT(msg.sender) override {
      require((nfts.length > 0) && (ids.length > 0), "Length should be greater than 0");
      require(nfts.length == ids.length, "Length needs to be the same");
      for (uint256 i = 0; i < nfts.length; i++) {
        _register(nfts[i], ids[i], msg.sender);
      }
    }

    function _updateRewards(address nft, uint256 id, address account) internal returns (uint256) {
      require(IERC721(nft).ownerOf(id) == account, "Owner isn't equal to msg.sender");
      uint256 reward = rewardsUnpaid(nft, id);

      rewardsPaid[nft][id][lastDistributionsIndex] = rewardsPaid[nft][id][lastDistributionsIndex] + reward;
      rewardsPaidTotal[lastDistributionsIndex] = rewardsPaidTotal[lastDistributionsIndex] + reward;

      emit GetReward(nft, id, reward);

      return reward;
    }

    function getRewards(address nft, uint256 id) external notPaused nonReentrant ownGenesisNFT(msg.sender) override {
      uint256 reward = _updateRewards(nft, id, msg.sender);

      rewardsToken.safeTransfer(msg.sender, reward);
    }

    function batchGetRewards(address[] memory nfts, uint256[] memory ids) external notPaused nonReentrant ownGenesisNFT(msg.sender) override {
      require((nfts.length > 0) && (ids.length > 0), "Length should be greater than 0");
      require(nfts.length == ids.length, "Length needs to be the same");
      uint256 rewards;
      for (uint256 i = 0; i < nfts.length; i++) {
        rewards = rewards + _updateRewards(nfts[i], ids[i], msg.sender);
      }
      rewardsToken.safeTransfer(msg.sender, rewards);
    }

    function settleRewardsToken() external onlyOwner {
        require(distributions[lastDistributionsIndex].endTime < block.timestamp, "Distribution is active");
        uint256 tokenAmount = distributions[lastDistributionsIndex].amount - rewardsPaidTotal[lastDistributionsIndex];
        rewardsToken.safeTransfer(operator, tokenAmount);
        emit Settle(tokenAmount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner {}

    modifier ownGenesisNFT(address account) {
      bool isPass = false;
      for (uint256 i = 0; i < genesisNFT.length; i++) {
        if (genesisNFT[i].balanceOf(account) > 0) {
          isPass = true;
          break;
        }
      }
      require(isPass == true, "You should own the genesis NFT");
      _;
    }

    event AddDistribution(uint256 start, uint256 end, uint256 amount);
    event Register(address nft, uint256 id, uint256 timestamp);
    event GetReward(address nft, uint256 id, uint256 amount);
    event Settle(uint256 tokenAmount);
}