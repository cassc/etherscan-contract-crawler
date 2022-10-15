// contracts/SmartNode.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SmartNode is AccessControl {

    struct Node {
        bool isExist;
        uint256 id;
        address referer;
        uint40 activated_at;
    }

    mapping (address => Node) private _nodes;
    mapping (uint256 => address) private _nodeList;
    uint256 private constant SEED = 9998;
    uint256 private _nodeCount;
    bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");

    event SmartNodeActivated(address indexed user, address indexed referer, uint256 id);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _nodeCount = SEED;
    }

    function join(address referer) public {
        return _join(msg.sender, referer);
    }

    function proxyJoin(
        address node, 
        address referer
    ) public onlyRole(PROXY_ROLE) returns(bool status) {
        _join(node, referer);
        return true;
    }

    function nodeUserOf(uint256 id) public view returns(address node) {
        return _nodeList[id];
    }

    function nodeIdOf(address node) public view returns(uint256 id) {
        return _nodes[node].id;
    }

    function nodeRefererOf(address node) public view returns(address referer) {
        return _nodes[node].referer;
    }

    function nodeUserReferrerOf(uint256 id) public view returns(address node, address referer) {
        node = _nodeList[id];
        return (node, _nodes[node].referer);
    }

    function totalNodes() public view returns(uint256 nodeCount) {
        return _nodeCount - SEED;
    }

    function isExistingId(uint256 id) public view returns(bool status) {
        return _nodes[_nodeList[id]].isExist;
    }

    function nodeLevelReferer(
        address node, 
        uint256 level
    ) public view returns (address referer) {
        referer = node;

        if (level != 0 && node != address(0)) {
            while(level >= 0) {
                referer = _nodes[referer].referer;
                if (level == 0) {
                    break;
                }
                level--;
            }
        }
    }

    function _join(address node, address referer) internal {
        require(referer != address(0), "!referer");
        require(!_nodes[node].isExist, "joined!");

        _nodeCount++;

        _nodes[node] = Node({
            isExist: true,
            id: _nodeCount,
            referer: referer,
            activated_at: uint40(block.timestamp)
        });

        _nodeList[_nodeCount] = node;

        emit SmartNodeActivated(node, referer, _nodeCount);
    }

}