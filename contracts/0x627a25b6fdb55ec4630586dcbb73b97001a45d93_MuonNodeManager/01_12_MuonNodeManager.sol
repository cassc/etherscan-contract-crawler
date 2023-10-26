// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IMuonNodeManager.sol";

contract MuonNodeManager is
    Initializable,
    AccessControlUpgradeable,
    IMuonNodeManager
{
    struct EditLog {
        uint64 nodeId;
        uint256 editTime;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DAO_ROLE = keccak256("DAO_ROLE");

    // nodeId => Node
    mapping(uint64 => Node) public nodes;

    // nodeAddress => nodeId
    mapping(address => uint64) public nodeAddressIds;

    // stakerAddress => nodeId
    mapping(address => uint64) public stakerAddressIds;

    uint64 public lastNodeId;

    // muon nodes check lastUpdateTime to sync their memory
    uint256 public lastUpdateTime;

    EditLog[] public editLogs;

    // commit id => git commit id
    mapping(string => string) public configs;

    // role id => node id => index + 1
    mapping(uint64 => mapping(uint64 => uint16)) public nodesRoles;

    // ======== Events ========
    event NodeAdded(uint64 indexed nodeId, Node node);
    event NodeDeactivated(uint64 indexed nodeId);
    event ConfigSet(string indexed key, string value);
    event NodeRoleSet(uint64 indexed nodeId, uint64 indexed roleId);
    event NodeRoleUnset(uint64 indexed nodeId, uint64 indexed roleId);
    event TierSet(uint64 indexed nodeId, uint8 indexed tier);

    // ======== Modifiers ========
    /**
     * @dev Modifier to update the lastUpdateTime state variable.
     */
    modifier updateState() {
        lastUpdateTime = block.timestamp;
        _;
    }

    /**
     * @dev Modifier to update the lastEditTime of a specific node.
     * @param nodeId The id of the node.
     */
    modifier updateNodeState(uint64 nodeId) {
        nodes[nodeId].lastEditTime = block.timestamp;
        editLogs.push(EditLog(nodeId, block.timestamp));
        _;
    }

    /**
     * @dev Initializes the contract.
     */
    function initialize() external initializer {
        __MuonNodeManagerUpgradeable_init();
    }

    function __MuonNodeManagerUpgradeable_init() internal initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(DAO_ROLE, msg.sender);

        lastNodeId = 0;
        lastUpdateTime = block.timestamp;
    }

    function __MuonNodeManagerUpgradeable_init_unchained()
        internal
        initializer
    {}

    /**
     * @dev Adds a new node.
     * Only callable by the ADMIN_ROLE.
     * @param nodeAddress The address of the node.
     * @param stakerAddress The address of the staker associated with the node.
     * @param peerId The peer ID of the node.
     * @param active Indicates whether the node is active or not.
     */
    function addNode(
        address nodeAddress,
        address stakerAddress,
        string calldata peerId,
        bool active
    ) external override onlyRole(ADMIN_ROLE) updateState {
        require(nodeAddressIds[nodeAddress] == 0, "Duplicate node address.");

        require(
            stakerAddressIds[stakerAddress] == 0,
            "Duplicate staker address."
        );

        lastNodeId++;
        Node storage node = nodes[lastNodeId];
        node.id = lastNodeId;
        node.nodeAddress = nodeAddress;
        node.stakerAddress = stakerAddress;
        node.peerId = peerId;
        node.active = active;
        node.startTime = block.timestamp;
        node.lastEditTime = block.timestamp;

        nodeAddressIds[nodeAddress] = lastNodeId;
        stakerAddressIds[stakerAddress] = lastNodeId;

        editLogs.push(EditLog(lastNodeId, block.timestamp));

        emit NodeAdded(lastNodeId, nodes[lastNodeId]);
    }

    /**
     * @dev Allows the admins to deactivate the nodes.
     * Only callable by the ADMIN_ROLE.
     * @param nodeId The ID of the node to be deactivated.
     */
    function deactiveNode(
        uint64 nodeId
    )
        external
        override
        onlyRole(ADMIN_ROLE)
        updateState
        updateNodeState(nodeId)
    {
        require(nodes[nodeId].id == nodeId, "Node not found.");

        require(nodes[nodeId].active, "Already deactivated.");

        nodes[nodeId].endTime = block.timestamp;
        nodes[nodeId].active = false;

        emit NodeDeactivated(nodeId);
    }

    /**
     * @dev Adds a role to a given node.
     * Only callable by the DAO_ROLE.
     * @param nodeId The ID of the node.
     * @param roleId The ID of the role.
     */
    function setNodeRole(
        uint64 nodeId,
        uint64 roleId
    ) external onlyRole(DAO_ROLE) updateState updateNodeState(nodeId) {
        require(roleId > 0, "Invalid role ID.");

        require(nodesRoles[roleId][nodeId] == 0, "Already set.");

        nodes[nodeId].roles.push(roleId);
        nodesRoles[roleId][nodeId] = uint16(nodes[nodeId].roles.length);
        emit NodeRoleSet(nodeId, roleId);
    }

    /**
     * @dev Removes a role from a given node.
     * Only callable by the DAO_ROLE.
     * @param nodeId The ID of the node.
     * @param roleId The ID of the role.
     */
    function unsetNodeRole(
        uint64 nodeId,
        uint64 roleId
    ) external onlyRole(DAO_ROLE) updateState updateNodeState(nodeId) {
        require(roleId > 0, "Invalid role ID.");

        require(nodesRoles[roleId][nodeId] > 0, "Already unset.");

        uint16 index = nodesRoles[roleId][nodeId] - 1;
        Node storage node = nodes[nodeId];
        uint64 lRoleId = node.roles[node.roles.length - 1];
        node.roles[index] = lRoleId;
        nodesRoles[lRoleId][nodeId] = index + 1;
        node.roles.pop();
        nodesRoles[roleId][nodeId] = 0;
        emit NodeRoleUnset(nodeId, roleId);
    }

    /**
     * @dev Sets the tier of a node.
     * Only callable by the DAO_ROLE.
     * @param nodeId The ID of the node.
     * @param tier The tier to set.
     */
    function setTier(
        uint64 nodeId,
        uint8 tier
    ) external onlyRole(ADMIN_ROLE) updateState updateNodeState(nodeId) {
        require(nodes[nodeId].id == nodeId, "Node not found.");

        require(nodes[nodeId].tier != tier, "Already set.");

        nodes[nodeId].tier = tier;
        emit TierSet(nodeId, tier);
    }

    /**
     * @dev Sets a configuration value.
     * Only callable by the DAO_ROLE.
     * @param key The key of the configuration value.
     * @param val The value to be set.
     */
    function setConfig(
        string memory key,
        string memory val
    ) external onlyRole(DAO_ROLE) {
        configs[key] = val;
        emit ConfigSet(key, val);
    }

    /**
     * @dev Returns whether a given node has a given role.
     * @param nodeId The ID of the node.
     * @param roleId The roleId to check.
     * @return A boolean indicating whether the node has the role.
     */
    function nodeHasRole(
        uint64 nodeId,
        uint64 roleId
    ) external view returns (bool) {
        return nodesRoles[roleId][nodeId] > 0;
    }

    /**
     * @dev Returns the information of a node.
     * @param nodeId The ID of the node.
     * @return The node information.
     */
    function getNode(uint64 nodeId) external view returns (Node memory) {
        Node memory node = nodes[nodeId];
        node.roles = getNodeRoles(nodeId);
        return node;
    }

    /**
     * @dev Returns a list of nodes that have been edited.
     * @param lastEditTime The time of the last edit.
     * @param startId The starting node ID.
     * @param endId The ending node ID.
     * @return nodesList An array of edited nodes.
     */
    function getAllNodes(
        uint256 lastEditTime,
        uint64 startId,
        uint64 endId
    ) external view returns (Node[] memory nodesList) {
        startId = startId > 0 ? startId : 1;
        endId = endId <= lastNodeId ? endId : lastNodeId;
        require(startId <= endId, "Invalid range.");

        nodesList = new Node[](endId - startId + 1);
        uint8 n = 0;
        for (uint64 i = startId; i <= endId; i++) {
            Node memory node = nodes[i];

            if (node.lastEditTime > lastEditTime) {
                nodesList[n] = node;
                nodesList[n].roles = getNodeRoles(i);
                n++;
            }
        }

        // Resize the array to remove any unused elements
        assembly {
            mstore(nodesList, n)
        }
    }

    /**
     * @dev Returns a list of nodes that have been edited.
     * @param lastEditTime The time of the last edit.
     * @param index The index to start retrieving the edited nodes or zero.
     * @return nodesList An array of edited nodes.
     * @return lastIndex The index of the last retrieved edit log in the `editLogs` array.
     */
    function getEditedNodes(
        uint256 lastEditTime,
        uint256 index,
        uint16 maxNodesToRetrieve
    ) external view returns (Node[] memory nodesList, uint256 lastIndex) {
        uint256 startIndex = index == 0 ? editLogs.length - 1 : index - 1;
        nodesList = new Node[](maxNodesToRetrieve);
        uint8 nodesIndex = 0;
        lastIndex = 0;

        for (uint256 i = startIndex + 1; i > 0; i--) {
            EditLog memory log = editLogs[i - 1];

            if (log.editTime <= lastEditTime) {
                break;
            }

            if (log.editTime == nodes[log.nodeId].lastEditTime) {
                nodesList[nodesIndex] = nodes[log.nodeId];
                nodesList[nodesIndex].roles = getNodeRoles(log.nodeId);
                nodesIndex++;
            }

            if (nodesIndex == maxNodesToRetrieve) {
                lastIndex = i - 1;
                break;
            }
        }
        // Resize the array to remove any unused elements
        assembly {
            mstore(nodesList, nodesIndex)
        }

        return (nodesList, lastIndex);
    }

    /**
     * @dev Returns the information of a node associated with the provided node address.
     * @param nodeAddress The node address.
     * @return node The node information.
     */
    function nodeAddressInfo(
        address nodeAddress
    ) external view returns (Node memory node) {
        node = nodes[nodeAddressIds[nodeAddress]];
    }

    /**
     * @dev Returns the information of a node associated with the provided staker address.
     * @param stakerAddress The staker address.
     * @return node The node information.
     */
    function stakerAddressInfo(
        address stakerAddress
    ) external view override returns (Node memory node) {
        node = nodes[stakerAddressIds[stakerAddress]];
    }

    /**
     * @dev Retrieves various contract information.
     * @param configKeys An array of configuration keys to retrieve.
     * @return lastUpdateTime The value of lastUpdateTime state variable.
     * @return lastNodeId The value of lastNodeId state variable.
     * @return configValues An array of configuration values corresponding to the keys.
     */
    function getInfo(
        string[] memory configKeys
    ) external view returns (uint256, uint64, string[] memory) {
        uint256 configLength = configKeys.length;
        string[] memory configValues = new string[](configLength);
        for (uint256 i = 0; i < configLength; i++) {
            configValues[i] = configs[configKeys[i]];
        }
        return (lastUpdateTime, lastNodeId, configValues);
    }

    /**
     * @dev Returns a list of roles associated with a node.
     * @param nodeId The ID of the node.
     * @return An array of role IDs.
     */
    function getNodeRoles(uint64 nodeId) public view returns (uint64[] memory) {
        return nodes[nodeId].roles;
    }
}