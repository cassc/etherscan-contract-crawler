//SPDX-License-Identifier: Unlicensed
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./interfaces/ServiceInterface.sol";
import "./interfaces/IServiceV21.sol";
import "./interfaces/IMultiNode.sol";
import "./interfaces/IERC1155Preset.sol";
import "./interfaces/StrongNFTBonusLegacyInterface.sol";
import "./interfaces/IStrongPool.sol";
import "./lib/SafeMath.sol";
import "./lib/ERC1155Receiver.sol";

contract StrongNFTBonusV11 {

  using SafeMath for uint256;

  event Staked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);
  event Unstaked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);

  ServiceInterface public CService;
  IERC1155Preset public CERC1155;
  StrongNFTBonusLegacyInterface public CStrongNFTBonus;

  bool public initDone;

  address public serviceAdmin;
  address public superAdmin;

  string[] public nftBonusNames;
  mapping(string => uint256) public nftBonusLowerBound;
  mapping(string => uint256) public nftBonusUpperBound;
  mapping(string => uint256) public nftBonusValue;
  mapping(string => uint256) public nftBonusEffectiveBlock;

  mapping(uint256 => address) public nftIdStakedToEntity;
  mapping(uint256 => uint128) public nftIdStakedToNodeId;
  mapping(uint256 => uint256) public nftIdStakedAtBlock;
  mapping(address => mapping(uint128 => uint256)) public entityNodeStakedNftId;

  mapping(bytes4 => bool) private _supportedInterfaces;

  mapping(string => uint8) public nftBonusNodesLimit;
  mapping(uint256 => uint8) public nftIdStakedToNodesCount;
  mapping(uint128 => uint256) public nodeIdStakedAtBlock;
  mapping(address => uint256[]) public entityStakedNftIds;

  mapping(address => mapping(uint128 => uint256)) public entityNodeStakedAtBlock;

  mapping(address => bool) private serviceContracts;
  mapping(address => mapping(address => mapping(uint128 => uint256))) public entityServiceNodeStakedNftId;
  mapping(address => mapping(address => mapping(uint128 => uint256))) public entityServiceNodeStakedAtBlock;

  event StakedToNode(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block, address serviceContract);
  event UnstakedFromNode(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block, address serviceContract);

  mapping(address => bool) private serviceUsesTime;
  mapping(address => mapping(string => uint256)) public serviceNftBonusEffectiveAt;
  mapping(address => mapping(string => uint256)) public serviceNftBonusValue;
  mapping(address => mapping(address => mapping(uint128 => uint256))) public entityServiceNodeStakedAtTimestamp;

  function init(address serviceContract, address nftContract, address strongNFTBonusContract, address serviceAdminAddress, address superAdminAddress) external {
    require(initDone == false, "init done");

    _registerInterface(0x01ffc9a7);
    _registerInterface(
      ERC1155Receiver(0).onERC1155Received.selector ^
      ERC1155Receiver(0).onERC1155BatchReceived.selector
    );

    serviceAdmin = serviceAdminAddress;
    superAdmin = superAdminAddress;
    CService = ServiceInterface(serviceContract);
    CERC1155 = IERC1155Preset(nftContract);
    CStrongNFTBonus = StrongNFTBonusLegacyInterface(strongNFTBonusContract);
    initDone = true;
  }

  //
  // Getters
  // -------------------------------------------------------------------------------------------------------------------

  function isNftStaked(uint256 _nftId) external view returns (bool) {
    return nftIdStakedToNodeId[_nftId] != 0 || nftIdStakedToNodesCount[_nftId] > 0;
  }

  function isNftStakedLegacy(uint256 _nftId) external view returns (bool) {
    return CStrongNFTBonus.isNftStaked(_nftId);
  }

  function getStakedNftId(address _entity, uint128 _nodeId, address _serviceContract) public view returns (uint256) {
    bool isEthNode = isEthereumNode(_serviceContract);
    uint256 stakedNftIdNew = entityServiceNodeStakedNftId[_entity][_serviceContract][_nodeId];
    uint256 stakedNftId = isEthNode ? entityNodeStakedNftId[_entity][_nodeId] : 0;
    uint256 stakedNftIdLegacy = isEthNode ? CStrongNFTBonus.getStakedNftId(_entity, _nodeId) : 0;

    return stakedNftIdNew != 0 ? stakedNftIdNew : (stakedNftId != 0 ? stakedNftId : stakedNftIdLegacy);
  }

  function getStakedNftIdInternal(address _entity, uint128 _nodeId, address _serviceContract) public view returns (uint256) {
    bool isEthNode = isEthereumNode(_serviceContract);
    uint256 stakedNftIdNew = entityServiceNodeStakedNftId[_entity][_serviceContract][_nodeId];
    uint256 stakedNftId = isEthNode ? entityNodeStakedNftId[_entity][_nodeId] : 0;

    return stakedNftIdNew != 0 ? stakedNftIdNew : stakedNftId;
  }

  function getStakedNftIds(address _entity) external view returns (uint256[] memory) {
    return entityStakedNftIds[_entity];
  }

  function getStakedNftBonusName(address _entity, uint128 _nodeId, address _serviceContract) external view returns (string memory) {
    uint256 nftId = getStakedNftId(_entity, _nodeId, _serviceContract);
    return getNftBonusName(nftId);
  }

  function getNftBonusNames() external view returns (string[] memory) {
    return nftBonusNames;
  }

  function getNftNodesLeft(uint256 _nftId) external view returns (uint256) {
    return nftBonusNodesLimit[getNftBonusName(_nftId)] - nftIdStakedToNodesCount[_nftId];
  }

  function getNftBonusName(uint256 _nftId) public view returns (string memory) {
    for (uint8 i = 0; i < nftBonusNames.length; i++) {
      if (_nftId >= nftBonusLowerBound[nftBonusNames[i]] && _nftId <= nftBonusUpperBound[nftBonusNames[i]]) {
        return nftBonusNames[i];
      }
    }

    return "";
  }

  function getBonus(address _entity, uint128 _nodeId, uint256 _from, uint256 _to) external view returns (uint256) {
    return getBonusValue(_entity, _nodeId, _from, _to, 0);
  }

  function getBonusValue(address _entity, uint128 _nodeId, uint256 _from, uint256 _to, uint256 _bonusValue) public view returns (uint256) {
    address serviceContract = msg.sender;
    require(serviceContracts[serviceContract], "service doesnt exist");

    uint256 nftId = getStakedNftId(_entity, _nodeId, serviceContract);
    string memory bonusName = getNftBonusName(nftId);
    if (keccak256(abi.encode(bonusName)) == keccak256(abi.encode(""))) return 0;

    uint256 stakedAt = 0;
    if (serviceUsesTime[serviceContract]) {
      stakedAt = entityServiceNodeStakedAtTimestamp[_entity][serviceContract][_nodeId];
    }
    else {
      stakedAt = entityServiceNodeStakedAtBlock[_entity][serviceContract][_nodeId] > 0
      ? entityServiceNodeStakedAtBlock[_entity][serviceContract][_nodeId]
      : (entityNodeStakedAtBlock[_entity][_nodeId] > 0 ? entityNodeStakedAtBlock[_entity][_nodeId] : nftIdStakedAtBlock[nftId]);
    }

    uint256 bonusValue = _bonusValue != 0 ? _bonusValue : serviceNftBonusValue[serviceContract][bonusName] > 0
    ? serviceNftBonusValue[serviceContract][bonusName] : nftBonusValue[bonusName];

    uint256 effectiveAt = serviceNftBonusEffectiveAt[serviceContract][bonusName] > 0
    ? serviceNftBonusEffectiveAt[serviceContract][bonusName] : nftBonusEffectiveBlock[bonusName];

    uint256 startFrom = stakedAt > _from ? stakedAt : _from;
    if (startFrom < effectiveAt) {
      startFrom = effectiveAt;
    }

    if (stakedAt == 0 && keccak256(abi.encode(bonusName)) == keccak256(abi.encode("BRONZE"))) {
      return CStrongNFTBonus.getBonus(_entity, _nodeId, startFrom, _to);
    }

    if (nftId == 0) return 0;
    if (stakedAt == 0) return 0;
    if (effectiveAt == 0) return 0;
    if (startFrom >= _to) return 0;
    if (CERC1155.balanceOf(address(this), nftId) == 0) return 0;

    return _to.sub(startFrom).mul(bonusValue);
  }

  function isNftStaked(address _entity, uint256 _nftId, uint128 _nodeId, address _serviceContract) public view returns (bool) {
    return (isEthereumNode(_serviceContract) && entityNodeStakedNftId[_entity][_nodeId] == _nftId)
    || entityServiceNodeStakedNftId[_entity][_serviceContract][_nodeId] == _nftId;
  }

  function isEthereumNode(address _serviceContract) public view returns (bool) {
    return _serviceContract == address(CService);
  }

  //
  // Staking
  // -------------------------------------------------------------------------------------------------------------------

  function stakeNFT(uint256 _nftId, uint128 _nodeId, address _serviceContract) external payable {
    string memory bonusName = getNftBonusName(_nftId);
    require(keccak256(abi.encode(bonusName)) != keccak256(abi.encode("")), "not eligible");
    require(CERC1155.balanceOf(msg.sender, _nftId) != 0
      || (CERC1155.balanceOf(address(this), _nftId) != 0 && nftIdStakedToEntity[_nftId] == msg.sender), "not enough");
    require(nftIdStakedToNodesCount[_nftId] < nftBonusNodesLimit[bonusName], "over limit");
    require(serviceContracts[_serviceContract], "service doesnt exist");
    require(getStakedNftId(msg.sender, _nodeId, _serviceContract) == 0, "already staked");
    if (serviceUsesTime[_serviceContract]) require(IMultiNode(_serviceContract).doesNodeExist(msg.sender, uint(_nodeId)), "node doesnt exist");
    else require(IServiceV21(_serviceContract).doesNodeExist(msg.sender, _nodeId), "node doesnt exist");

    entityServiceNodeStakedNftId[msg.sender][_serviceContract][_nodeId] = _nftId;
    nftIdStakedToEntity[_nftId] = msg.sender;
    nftIdStakedToNodesCount[_nftId] += 1;

    if (serviceUsesTime[_serviceContract]) {
      entityServiceNodeStakedAtTimestamp[msg.sender][_serviceContract][_nodeId] = block.timestamp;
    }
    else {
      entityServiceNodeStakedAtBlock[msg.sender][_serviceContract][_nodeId] = block.number;
    }

    bool alreadyExists = false;
    for (uint8 i = 0; i < entityStakedNftIds[msg.sender].length; i++) {
      if (entityStakedNftIds[msg.sender][i] == _nftId) {
        alreadyExists = true;
        break;
      }
    }
    if (!alreadyExists) {
      entityStakedNftIds[msg.sender].push(_nftId);
    }

    if (CERC1155.balanceOf(address(this), _nftId) == 0) {
      CERC1155.safeTransferFrom(msg.sender, address(this), _nftId, 1, bytes(""));
    }

    emit StakedToNode(msg.sender, _nftId, _nodeId, serviceUsesTime[_serviceContract] ? block.timestamp : block.number, _serviceContract);
  }

  function migrateNFT(address _entity, uint128 _fromNodeId, uint128 _toNodeId, address _toServiceContract) external {
    address fromServiceContract = address(CService);
    uint256 nftId = getStakedNftId(_entity, _fromNodeId, fromServiceContract);

    require(msg.sender == fromServiceContract);
    require(serviceContracts[_toServiceContract], "service doesnt exist");
    require(IServiceV21(_toServiceContract).doesNodeExist(_entity, _toNodeId), "node doesnt exist");
    require(getStakedNftId(_entity, _toNodeId, _toServiceContract) == 0, "already staked");

    bool alreadyExists = false;
    for (uint8 i = 0; i < entityStakedNftIds[_entity].length; i++) {
      if (entityStakedNftIds[_entity][i] == nftId) {
        alreadyExists = true;
        break;
      }
    }

    if (nftId == 0 || !alreadyExists) {
      return;
    }

    entityServiceNodeStakedNftId[_entity][fromServiceContract][_fromNodeId] = 0;
    entityNodeStakedNftId[_entity][_fromNodeId] = 0;

    entityServiceNodeStakedNftId[_entity][_toServiceContract][_toNodeId] = nftId;
    nftIdStakedToEntity[nftId] = _entity;

    entityServiceNodeStakedAtTimestamp[_entity][_toServiceContract][_toNodeId] = block.timestamp;

    emit UnstakedFromNode(_entity, nftId, _fromNodeId, block.number, fromServiceContract);
    emit StakedToNode(_entity, nftId, _toNodeId, serviceUsesTime[_toServiceContract] ? block.timestamp : block.number, _toServiceContract);
  }

  function unstakeNFT(address _entity, uint128 _nodeId, address _serviceContract) external {
    uint256 nftId = getStakedNftIdInternal(_entity, _nodeId, _serviceContract);

    require(msg.sender == _serviceContract);
    require(serviceContracts[_serviceContract], "service doesnt exist");
    if (nftId == 0) return;

    entityServiceNodeStakedNftId[_entity][_serviceContract][_nodeId] = 0;
    nftIdStakedToNodeId[nftId] = 0;

    if (isEthereumNode(_serviceContract)) {
      entityNodeStakedNftId[_entity][_nodeId] = 0;
    }

    if (nftIdStakedToNodesCount[nftId] > 0) {
      nftIdStakedToNodesCount[nftId] -= 1;
    }

    if (nftIdStakedToNodesCount[nftId] == 0) {
      nftIdStakedToEntity[nftId] = address(0);

      for (uint8 i = 0; i < entityStakedNftIds[_entity].length; i++) {
        if (entityStakedNftIds[_entity][i] == nftId) {
          _deleteIndex(entityStakedNftIds[_entity], i);
          break;
        }
      }

      CERC1155.safeTransferFrom(address(this), _entity, nftId, 1, bytes(""));
    }

    emit UnstakedFromNode(_entity, nftId, _nodeId, block.number, _serviceContract);
  }

  function unStakeNFT(uint256 _nftId, uint128 _nodeId, uint256 _blockNumber, address _serviceContract, uint256 _claimedTotal, bytes memory _signature) external payable {
    require(isNftStaked(msg.sender, _nftId, _nodeId, _serviceContract), "wrong node");
    require(nftIdStakedToEntity[_nftId] != address(0), "not staked");
    require(nftIdStakedToEntity[_nftId] == msg.sender, "not staker");
    require(serviceContracts[_serviceContract], "service doesnt exist");

    bool hasNodeExpired = serviceUsesTime[_serviceContract]
      ? IMultiNode(_serviceContract).hasNodeExpired(msg.sender, uint(_nodeId))
      : (IServiceV21(_serviceContract).isNodeOverDue(msg.sender, _nodeId)
        || IServiceV21(_serviceContract).hasNodeExpired(msg.sender, _nodeId));

    if (!hasNodeExpired) {
      if (serviceUsesTime[_serviceContract]) IMultiNode(_serviceContract).claim{value : msg.value}(_nodeId, _blockNumber, address(0));
      else IServiceV21(_serviceContract).claim{value : msg.value}(_nodeId, _blockNumber, false, _claimedTotal, _signature);
    }

    entityServiceNodeStakedNftId[msg.sender][_serviceContract][_nodeId] = 0;
    nftIdStakedToNodeId[_nftId] = 0;

    if (isEthereumNode(_serviceContract)) {
      entityNodeStakedNftId[msg.sender][_nodeId] = 0;
    }

    if (nftIdStakedToNodesCount[_nftId] > 0) {
      nftIdStakedToNodesCount[_nftId] -= 1;
    }

    if (nftIdStakedToNodesCount[_nftId] == 0) {
      nftIdStakedToEntity[_nftId] = address(0);

      for (uint8 i = 0; i < entityStakedNftIds[msg.sender].length; i++) {
        if (entityStakedNftIds[msg.sender][i] == _nftId) {
          _deleteIndex(entityStakedNftIds[msg.sender], i);
          break;
        }
      }

      CERC1155.safeTransferFrom(address(this), msg.sender, _nftId, 1, bytes(""));
    }

    emit UnstakedFromNode(msg.sender, _nftId, _nodeId, _blockNumber, _serviceContract);
  }

  //
  // Admin
  // -------------------------------------------------------------------------------------------------------------------

  function updateServiceBonus(string memory _name, uint256 _value, uint256 _effectiveAt, address _serviceContract) external {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    serviceNftBonusValue[_serviceContract][_name] = _value;
    serviceNftBonusEffectiveAt[_serviceContract][_name] = _effectiveAt;
  }

  function updateBonusLimits(string memory _name, uint256 _lowerBound, uint256 _upperBound, uint8 _nodesLimit) external {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    bool alreadyExists = false;
    for (uint8 i = 0; i < nftBonusNames.length; i++) {
      if (keccak256(abi.encode(nftBonusNames[i])) == keccak256(abi.encode(_name))) {
        alreadyExists = true;
      }
    }

    if (!alreadyExists) {
      nftBonusNames.push(_name);
    }

    nftBonusLowerBound[_name] = _lowerBound;
    nftBonusUpperBound[_name] = _upperBound;
    nftBonusNodesLimit[_name] = _nodesLimit;
  }

  function updateBonus(string memory _name, uint256 _lowerBound, uint256 _upperBound, uint256 _value, uint256 _block, uint8 _nodesLimit) external {
    require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

    bool alreadyExists = false;
    for (uint8 i = 0; i < nftBonusNames.length; i++) {
      if (keccak256(abi.encode(nftBonusNames[i])) == keccak256(abi.encode(_name))) {
        alreadyExists = true;
      }
    }

    if (!alreadyExists) {
      nftBonusNames.push(_name);
    }

    nftBonusLowerBound[_name] = _lowerBound;
    nftBonusUpperBound[_name] = _upperBound;
    nftBonusValue[_name] = _value;
    nftBonusEffectiveBlock[_name] = _block != 0 ? _block : block.number;
    nftBonusNodesLimit[_name] = _nodesLimit;
  }

  function updateContracts(address _nftContract) external {
    require(msg.sender == superAdmin, "not admin");
    CERC1155 = IERC1155Preset(_nftContract);
  }

  function addServiceContract(address _contract, bool _useTime) external {
    require(msg.sender == superAdmin, "not admin");
    serviceContracts[_contract] = true;
    serviceUsesTime[_contract] = _useTime;
  }

  function removeServiceContract(address _contract) external {
    require(msg.sender == superAdmin, "not admin");
    serviceContracts[_contract] = false;
    serviceUsesTime[_contract] = false;
  }

  function updateServiceAdmin(address newServiceAdmin) external {
    require(msg.sender == superAdmin, "not admin");
    serviceAdmin = newServiceAdmin;
  }

  //
  // ERC1155 support
  // -------------------------------------------------------------------------------------------------------------------

  function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function supportsInterface(bytes4 interfaceId) public view returns (bool) {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId) internal virtual {
    require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
    _supportedInterfaces[interfaceId] = true;
  }

  function _deleteIndex(uint256[] storage array, uint256 index) internal {
    uint256 lastIndex = array.length.sub(1);
    uint256 lastEntry = array[lastIndex];
    if (index == lastIndex) {
      array.pop();
    } else {
      array[index] = lastEntry;
      array.pop();
    }
  }
}