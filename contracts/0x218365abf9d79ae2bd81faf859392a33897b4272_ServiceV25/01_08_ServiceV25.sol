// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../lib/openzeppelin/contracts/3.4.1/token/ERC20/IERC20.sol";
import "./lib/SafeMath.sol";
import "./interfaces/StrongPoolInterface.sol";
import "./interfaces/INodePackV3.sol";
import "./interfaces/IERC1155Preset.sol";
import "./interfaces/StrongNFTBonusInterface.sol";
import "./lib/rewards.sol";

contract ServiceV25 {
  uint constant public V20_DEPLOYED_AT_BLOCK = 14806408;

  event Requested(address indexed miner);
  event Claimed(address indexed miner, uint256 reward);

  using SafeMath for uint256;
  bool public initDone;
  address public admin;
  address public pendingAdmin;
  address public superAdmin;
  address public pendingSuperAdmin;
  address public serviceAdmin;
  address public parameterAdmin;
  address payable public feeCollector;

  IERC20 public strongToken;
  StrongPoolInterface public strongPool;

  uint256 public rewardPerBlockNumerator;
  uint256 public rewardPerBlockDenominator;

  uint256 public naasRewardPerBlockNumerator;
  uint256 public naasRewardPerBlockDenominator;

  uint256 public claimingFeeNumerator;
  uint256 public claimingFeeDenominator;

  uint256 public requestingFeeInWei;

  uint256 public strongFeeInWei;

  uint256 public recurringFeeInWei;
  uint256 public recurringNaaSFeeInWei;
  uint256 public recurringPaymentCycleInBlocks;

  uint256 public rewardBalance;

  mapping(address => uint256) public entityBlockLastClaimedOn;

  address[] public entities;
  mapping(address => uint256) public entityIndex;
  mapping(address => bool) public entityActive;
  mapping(address => bool) public requestPending;
  mapping(address => bool) public entityIsNaaS;
  mapping(address => uint256) public paidOnBlock;
  uint256 public activeEntities;

  string public desciption;

  uint256 public claimingFeeInWei;

  uint256 public naasRequestingFeeInWei;

  uint256 public naasStrongFeeInWei;

  bool public removedTokens;

  mapping(address => uint256) public traunch;

  uint256 public currentTraunch;

  mapping(bytes => bool) public entityNodeIsActive;
  mapping(bytes => bool) public entityNodeIsBYON;
  mapping(bytes => uint256) public entityNodeTraunch;
  mapping(bytes => uint256) public entityNodePaidOnBlock;
  mapping(bytes => uint256) public entityNodeClaimedOnBlock;
  mapping(address => uint128) public entityNodeCount;

  event Paid(address indexed entity, uint128 nodeId, bool isBYON, bool isRenewal, uint256 upToBlockNumber);
  event Migrated(address indexed from, address indexed to, uint128 fromNodeId, uint128 toNodeId, bool isBYON);

  uint256 public rewardPerBlockNumeratorNew;
  uint256 public rewardPerBlockDenominatorNew;
  uint256 public naasRewardPerBlockNumeratorNew;
  uint256 public naasRewardPerBlockDenominatorNew;
  uint256 public rewardPerBlockNewEffectiveBlock;

  StrongNFTBonusInterface public strongNFTBonus;

  uint256 public gracePeriodInBlocks;

  uint128 public maxNodes;
  uint256 public maxPaymentPeriods;

  event Deactivated(address indexed entity, uint128 nodeId, bool isBYON, uint256 atBlockNumber);
  event MigratedToNodePack(address indexed entity, uint128 fromNodeId, uint toPackId);

  uint256 public secondsPerBlock;
  uint256 public nodeLifetimeReward;
  mapping(bytes => uint256) public entityNodeClaimedTotal;
  mapping(address => uint128) public entityNodeDeactivatedCount;

  function init(
    address strongTokenAddress,
    address strongPoolAddress,
    address adminAddress,
    address superAdminAddress,
    uint256 rewardPerBlockNumeratorValue,
    uint256 rewardPerBlockDenominatorValue,
    uint256 naasRewardPerBlockNumeratorValue,
    uint256 naasRewardPerBlockDenominatorValue,
    uint256 requestingFeeInWeiValue,
    uint256 strongFeeInWeiValue,
    uint256 recurringFeeInWeiValue,
    uint256 recurringNaaSFeeInWeiValue,
    uint256 recurringPaymentCycleInBlocksValue,
    uint256 claimingFeeNumeratorValue,
    uint256 claimingFeeDenominatorValue,
    string memory desc
  ) external {
    require(!initDone, "init done");
    strongToken = IERC20(strongTokenAddress);
    strongPool = StrongPoolInterface(strongPoolAddress);
    admin = adminAddress;
    superAdmin = superAdminAddress;
    rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
    rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
    naasRewardPerBlockNumerator = naasRewardPerBlockNumeratorValue;
    naasRewardPerBlockDenominator = naasRewardPerBlockDenominatorValue;
    requestingFeeInWei = requestingFeeInWeiValue;
    strongFeeInWei = strongFeeInWeiValue;
    recurringFeeInWei = recurringFeeInWeiValue;
    recurringNaaSFeeInWei = recurringNaaSFeeInWeiValue;
    claimingFeeNumerator = claimingFeeNumeratorValue;
    claimingFeeDenominator = claimingFeeDenominatorValue;
    recurringPaymentCycleInBlocks = recurringPaymentCycleInBlocksValue;
    desciption = desc;
    initDone = true;
  }

  function updateServiceAdmin(address newServiceAdmin) external {
    require(msg.sender == superAdmin);
    serviceAdmin = newServiceAdmin;
  }

  function updateParameterAdmin(address newParameterAdmin) external {
    require(newParameterAdmin != address(0));
    require(msg.sender == superAdmin);
    parameterAdmin = newParameterAdmin;
  }

  function updateFeeCollector(address payable newFeeCollector) external {
    require(newFeeCollector != address(0));
    require(msg.sender == superAdmin);
    feeCollector = newFeeCollector;
  }

  function setPendingAdmin(address newPendingAdmin) external {
    require(msg.sender == admin);
    pendingAdmin = newPendingAdmin;
  }

  function acceptAdmin() external {
    require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
    admin = pendingAdmin;
    pendingAdmin = address(0);
  }

  function setPendingSuperAdmin(address newPendingSuperAdmin) external {
    require(msg.sender == superAdmin, "not superAdmin");
    pendingSuperAdmin = newPendingSuperAdmin;
  }

  function acceptSuperAdmin() external {
    require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
    superAdmin = pendingSuperAdmin;
    pendingSuperAdmin = address(0);
  }

  function isEntityActive(address entity) external view returns (bool) {
    return entityActive[entity] || (doesNodeExist(entity, 1) && !hasNodeExpired(entity, 1));
  }

  function updateRewardPerBlock(uint256 numerator, uint256 denominator) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(denominator != 0);
    rewardPerBlockNumerator = numerator;
    rewardPerBlockDenominator = denominator;
  }

  function updateNaaSRewardPerBlock(uint256 numerator, uint256 denominator) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(denominator != 0);
    naasRewardPerBlockNumerator = numerator;
    naasRewardPerBlockDenominator = denominator;
  }

  function updateRewardPerBlockNew(
    uint256 numerator,
    uint256 denominator,
    uint256 numeratorNass,
    uint256 denominatorNass,
    uint256 effectiveBlock
  ) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);

    rewardPerBlockNumeratorNew = numerator;
    rewardPerBlockDenominatorNew = denominator;
    naasRewardPerBlockNumeratorNew = numeratorNass;
    naasRewardPerBlockDenominatorNew = denominatorNass;
    rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
  }

  function deposit(uint256 amount) external {
    require(msg.sender == superAdmin);
    require(amount > 0);
    rewardBalance = rewardBalance.add(amount);
    require(strongToken.transferFrom(msg.sender, address(this), amount), "transfer failed");
  }

  function withdraw(address destination, uint256 amount) external {
    require(msg.sender == superAdmin);
    require(amount > 0);
    require(rewardBalance >= amount, "not enough");
    rewardBalance = rewardBalance.sub(amount);
    require(strongToken.transfer(destination, amount), "transfer failed");
  }

  function updateRequestingFee(uint256 feeInWei) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    requestingFeeInWei = feeInWei;
  }

  function updateStrongFee(uint256 feeInWei) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    strongFeeInWei = feeInWei;
  }

  function updateNaasRequestingFee(uint256 feeInWei) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    naasRequestingFeeInWei = feeInWei;
  }

  function updateNaasStrongFee(uint256 feeInWei) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    naasStrongFeeInWei = feeInWei;
  }

  function updateClaimingFee(uint256 numerator, uint256 denominator) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(denominator != 0);
    claimingFeeNumerator = numerator;
    claimingFeeDenominator = denominator;
  }

  function updateRecurringFee(uint256 feeInWei) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    recurringFeeInWei = feeInWei;
  }

  function updateRecurringNaaSFee(uint256 feeInWei) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    recurringNaaSFeeInWei = feeInWei;
  }

  function updateRecurringPaymentCycleInBlocks(uint256 blocks) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(blocks > 0);
    recurringPaymentCycleInBlocks = blocks;
  }

  function updateGracePeriodInBlocks(uint256 blocks) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
    require(blocks > 0);
    gracePeriodInBlocks = blocks;
  }

  function requestAccess(bool isNaaS) external payable {
    require(entityNodeCount[msg.sender] < maxNodes, "limit reached");

    uint256 rFee;
    uint256 sFee;

    uint128 nodeId = entityNodeCount[msg.sender] + 1;
    bytes memory id = getNodeId(msg.sender, nodeId);

    if (isNaaS) {
      rFee = naasRequestingFeeInWei;
      sFee = naasStrongFeeInWei;
      activeEntities = activeEntities.add(1);
    } else {
      rFee = requestingFeeInWei;
      sFee = strongFeeInWei;
      entityNodeIsBYON[id] = true;
    }

    require(msg.value == rFee, "invalid fee");

    entityNodePaidOnBlock[id] = block.number;
    entityNodeClaimedOnBlock[id] = block.number;
    entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;

    emit Paid(msg.sender, nodeId, entityNodeIsBYON[id], false, entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks));

    require(strongToken.transferFrom(msg.sender, address(this), sFee), "transfer failed");
    require(strongToken.transfer(feeCollector, sFee), "transfer failed");
    sendValue(feeCollector, msg.value);
  }

  function setEntityActiveStatus(address entity, bool status) external {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);
    uint256 index = entityIndex[entity];
    require(entities[index] == entity, "invalid entity");
    require(entityActive[entity] != status, "already set");
    entityActive[entity] = status;
    if (status) {
      activeEntities = activeEntities.add(1);
      entityBlockLastClaimedOn[entity] = block.number;
    } else {
      activeEntities = activeEntities.sub(1);
      entityBlockLastClaimedOn[entity] = 0;
    }
  }

  function payFee(uint128 nodeId, uint256 claimedTotal, bytes calldata signature) public payable {
    address sender = msg.sender == address(this) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(sender, nodeId);

    updateNodeClaimedTotal(sender, nodeId, claimedTotal, signature);

    require(doesNodeExist(sender, nodeId), "doesnt exist");
    require(!hasNodeExpired(sender, nodeId), "too late");
    require(!hasMaxPayments(sender, nodeId), "too soon");

    if (entityNodeIsBYON[id]) {
      require(msg.value == recurringFeeInWei, "invalid fee");
    } else {
      require(msg.value == recurringNaaSFeeInWei, "invalid fee");
    }

    entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

    emit Paid(sender, nodeId, entityNodeIsBYON[id], true, entityNodePaidOnBlock[id]);

    sendValue(feeCollector, msg.value);
  }

  function getReward(address entity, uint128 nodeId) external view returns (uint256) {
    return getRewardByBlock(entity, nodeId, block.number);
  }

  function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) public view returns (uint256) {
    bytes memory id = getNodeId(entity, nodeId);

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];

    if (hasNodeExpired(entity, nodeId)) return 0;
    if (blockNumber > block.number) return 0;
    if (blockLastClaimedOn == 0) return 0;
    if (blockNumber < blockLastClaimedOn) return 0;
    if (activeEntities == 0) return 0;
    if (entityNodeIsBYON[id] && !entityNodeIsActive[id]) return 0;

    uint256 rewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumerator : naasRewardPerBlockNumerator;
    uint256 rewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominator : naasRewardPerBlockDenominator;
    uint256 newRewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumeratorNew : naasRewardPerBlockNumeratorNew;
    uint256 newRewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominatorNew : naasRewardPerBlockDenominatorNew;

    uint256 bonus = address(strongNFTBonus) != address(0)
    ? strongNFTBonus.getBonus(entity, nodeId, blockLastClaimedOn, blockNumber)
    : 0;

    uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, blockNumber);
    uint256 rewardOld = rewardDenominator > 0 ? rewardBlocks[0].mul(rewardNumerator).div(rewardDenominator) : 0;
    uint256 rewardNew = newRewardDenominator > 0 ? rewardBlocks[1].mul(newRewardNumerator).div(newRewardDenominator) : 0;

    uint256 rewardTotal = rewardOld.add(rewardNew).add(bonus);

    if (nodeLifetimeReward > 0) {
      if (entityNodeClaimedTotal[id] >= nodeLifetimeReward) {
        return 0;
      } else if (entityNodeClaimedTotal[id].add(rewardTotal) > nodeLifetimeReward) {
        return nodeLifetimeReward.sub(entityNodeClaimedTotal[id]);
      }
    }

    return rewardTotal;
  }

  function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool, uint256 claimedTotal, bytes memory signature) public payable returns (uint256) {
    address sender = msg.sender == address(this) || msg.sender == address(strongNFTBonus) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(sender, nodeId);

    uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

    require(blockLastClaimedOn != 0, "never claimed");
    require(blockNumber <= block.number, "invalid block");
    require(blockNumber > blockLastClaimedOn, "too soon");
    require(!entityNodeIsBYON[id] || entityNodeIsActive[id], "not active");

    if (
      (!entityNodeIsBYON[id] && recurringNaaSFeeInWei != 0) || (entityNodeIsBYON[id] && recurringFeeInWei != 0)
    ) {
      require(blockNumber < blockLastPaidOn.add(recurringPaymentCycleInBlocks), "pay fee");
    }

    uint256 reward = getRewardByBlock(sender, nodeId, blockNumber);
    if (msg.sender == address(strongNFTBonus) && reward == 0) {
      return 0;
    }
    require(reward > 0, "no reward");

    uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
    require(msg.value >= fee, "invalid fee");

    if (msg.sender != address(this)) {
      updateNodeClaimedTotal(sender, nodeId, claimedTotal, signature);
    }

    rewardBalance = rewardBalance.sub(reward);
    entityNodeClaimedOnBlock[id] = blockNumber;
    entityNodeClaimedTotal[id] = entityNodeClaimedTotal[id].add(reward);

    emit Claimed(sender, reward);

    if (toStrongPool) {
      require(strongToken.approve(address(strongPool), reward), "approve failed");
      strongPool.mineFor(sender, reward);
    } else {
      require(strongToken.transfer(sender, reward), "transfer failed");
    }

    sendValue(feeCollector, fee);

    return fee;
  }

  function getRewardAll(address entity, uint256 blockNumber) public view returns (uint256) {
    uint256 rewardsAll = 0;

    for (uint128 i = 1; i <= entityNodeCount[entity]; i++) {
      rewardsAll = rewardsAll.add(getRewardByBlock(entity, i, blockNumber > 0 ? blockNumber : block.number));
    }

    return rewardsAll;
  }

  function canBePaid(address entity, uint128 nodeId) public view returns (bool) {
    return !isNodeBYON(entity, nodeId) && !hasNodeExpired(entity, nodeId) && !hasMaxPayments(entity, nodeId);
  }

  function doesNodeExist(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    return entityNodePaidOnBlock[id] > 0;
  }

  function hasNodeExpired(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

    if (entityNodeIsBYON[id]) return !entityNodeIsActive[id];
    if (!doesNodeExist(entity, nodeId)) return true;

    return block.number > blockLastPaidOn.add(recurringPaymentCycleInBlocks).add(gracePeriodInBlocks);
  }

  function isNodeOverDue(address entity, uint128 nodeId) public view returns (bool) {
    return block.number > entityNodePaidOnBlock[getNodeId(entity, nodeId)].add(recurringPaymentCycleInBlocks);
  }

  function hasMaxPayments(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    uint256 blockLastPaidOn = entityNodePaidOnBlock[id];
    uint256 limit = block.number.add(recurringPaymentCycleInBlocks.mul(maxPaymentPeriods));

    return blockLastPaidOn.add(recurringPaymentCycleInBlocks) >= limit;
  }

  function getNodeId(address entity, uint128 nodeId) public view returns (bytes memory) {
    uint128 id = nodeId != 0 ? nodeId : entityNodeCount[entity] + 1;
    return abi.encodePacked(entity, id);
  }

  function getNodePaidOn(address entity, uint128 nodeId) external view returns (uint256) {
    bytes memory id = getNodeId(entity, nodeId);
    return entityNodePaidOnBlock[id];
  }

  function getEntityNodeActiveCount(address entity) external view returns (uint256) {
    return entityNodeCount[entity] - entityNodeDeactivatedCount[entity];
  }

  function getEntityNodeClaimedTotal(address entity, uint128 nodeId) public view returns (uint256) {
    return entityNodeClaimedTotal[getNodeId(entity, nodeId)];
  }

  function isNodeActive(address entity, uint128 nodeId) external view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    return entityNodeIsActive[id] || !entityNodeIsBYON[id];
  }

  function isNodeBYON(address entity, uint128 nodeId) public view returns (bool) {
    bytes memory id = getNodeId(entity, nodeId);
    return entityNodeIsBYON[id];
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success,) = recipient.call{value : amount}("");
    require(success, "send failed");
  }

  function addNFTBonusContract(address _contract) external {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

    strongNFTBonus = StrongNFTBonusInterface(_contract);
  }

  function disableNodeAdmin(address entity, uint128 nodeId) external {
    require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

    bytes memory id = getNodeId(entity, nodeId);
    entityNodePaidOnBlock[id] = 0;
    entityNodeClaimedOnBlock[id] = 0;

    emit Deactivated(entity, nodeId, entityNodeIsBYON[id], block.number);
  }

  function updateLimits(uint128 _maxNodes, uint256 _maxPaymentPeriods) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);

    maxNodes = _maxNodes;
    maxPaymentPeriods = _maxPaymentPeriods;
  }

  function setTokenContract(IERC20 tokenAddress) external {
    require(msg.sender == superAdmin);
    strongToken = tokenAddress;
  }

  function withdrawToken(IERC20 token, address recipient, uint256 amount) external {
    require(msg.sender == superAdmin);
    require(token.transfer(recipient, amount));
  }

  function withdrawEth(address payable recipient, uint256 amount) external {
    require(msg.sender == superAdmin);

    sendValue(recipient, amount);
  }

  function updateNodeLifetimeReward(uint256 _nodeLifetimeReward) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);

    nodeLifetimeReward = _nodeLifetimeReward;
  }

  function updateNodeClaimedTotal(address entity, uint128 nodeId, uint256 claimedTotal, bytes memory signature) internal {
    bytes memory id = getNodeId(entity, nodeId);

    if (entityNodeClaimedTotal[id] != 0) {
      return;
    }

    bytes32 hash = prefixed(keccak256(abi.encodePacked(entity, nodeId, claimedTotal)));
    address signer = recoverSigner(hash, signature);

    require(signer == admin || signer == parameterAdmin || signer == superAdmin, "wrong signer");
    entityNodeClaimedTotal[id] = claimedTotal;
  }

  function updateSecondsPerBlock(uint256 _secondsPerBlock) external {
    require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);

    secondsPerBlock = _secondsPerBlock;
  }

  function migrateAll(address _contract, uint256 _blockNumber) external payable {
    require(entityNodeCount[msg.sender] > 0, "no nodes");

    uint256 totalClaimed = 0;
    uint128 migratedNodes = 0;
    uint256 totalSeconds = 0;
    uint256 rewardsDue = getRewardAll(msg.sender, _blockNumber);

    for (uint128 nodeId = 1; nodeId <= entityNodeCount[msg.sender]; nodeId++) {
      bytes memory id = getNodeId(msg.sender, nodeId);
      bool migrated = migrate(nodeId, _blockNumber);
      if (migrated) {
        migratedNodes += 1;
        totalClaimed = totalClaimed.add(entityNodeClaimedTotal[id]);
        totalSeconds = totalSeconds.add(block.timestamp - ((block.number - entityNodePaidOnBlock[id]) * secondsPerBlock));
        entityNodePaidOnBlock[id] = 0;
        entityNodeClaimedOnBlock[id] = 0;
      }
    }

    require(migratedNodes > 0, "nothing to migrate");

    entityNodeDeactivatedCount[msg.sender] += migratedNodes;
    INodePackV3(_contract).migrateNodes(msg.sender, 1, migratedNodes, totalSeconds / migratedNodes, rewardsDue, totalClaimed);
  }

  function migrate(uint128 _nodeId, uint256 _blockNumber) internal returns (bool) {
    address sender = msg.sender == address(this) ? tx.origin : msg.sender;
    bytes memory id = getNodeId(sender, _nodeId);

    if (hasNodeExpired(sender, _nodeId) || isNodeBYON(sender, _nodeId) || entityNodeClaimedTotal[id] >= nodeLifetimeReward) {
      return false;
    }

    require(entityNodeClaimedTotal[id] > 0 || entityNodePaidOnBlock[id] > V20_DEPLOYED_AT_BLOCK, "claim first");

    emit MigratedToNodePack(sender, _nodeId, 1);

    strongNFTBonus.unstakeNFT(sender, _nodeId, address(this));

    return true;
  }

  // Signatures

  function recoverSigner(bytes32 _hash, bytes memory _sig) public pure returns (address) {
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_sig);

    return ecrecover(_hash, v, r, s);
  }

  function prefixed(bytes32 _hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
  }

  function splitSignature(bytes memory _sig) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
    require(_sig.length == 65);

    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

    return (v, r, s);
  }

}