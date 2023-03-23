// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

contract Rel {
    event Bind(address indexed user, address indexed parent);
    event Upgrade(address indexed user, uint256 indexed level);

    address public pool;

    mapping(address => address) public parents;

    mapping(bytes32 => address[]) public children;

    mapping(address => uint256) public levelPerUser;

    mapping(address => mapping(uint256 => uint256)) public countPerLevelPerUser;

    constructor(address genesis) {
        parents[genesis] = address(1);
        emit Bind(genesis, address(1));
    }

    function bind(address parent) external {
        require(parents[msg.sender] == address(0), "already bind");
        require(parents[parent] != address(0), "parent invalid");
        parents[msg.sender] = parent;
        addChild(msg.sender, parent);
        countPerLevelPerUser[parent][0]++;
        emit Bind(msg.sender, parent);
    }

    function setPool(address adr) external {
        require(pool == address(0) && adr != address(0));
        pool = adr;
    }

    function setLevel(address adr, uint256 level) external {
        require(msg.sender == pool, "not allowed");
        levelPerUser[adr] = level;
        emit Upgrade(adr, level);
    }

    function updateCountPerLevel(
        address user,
        uint256 minusLevel,
        uint256 addLevel
    ) external {
        require(msg.sender == pool, "not allowed");
        countPerLevelPerUser[user][minusLevel]--;
        countPerLevelPerUser[user][addLevel]++;
    }

    function addChild(address user, address p) private {
        for (
            uint256 i = 1;
            i <= 10 && p != address(0) && p != address(1);
            ++i
        ) {
            children[keccak256(abi.encode(p, i))].push(user);
            p = parents[p];
        }
    }

    function getChildren(
        address user,
        uint256 level
    ) external view returns (address[] memory) {
        return children[keccak256(abi.encode(user, level))];
    }

    function getChildrenLength(
        address user,
        uint256 level
    ) external view returns (uint256) {
        return children[keccak256(abi.encode(user, level))].length;
    }

    function getChildrenLength(address user) external view returns (uint256) {
        uint256 len;
        for (uint256 i = 1; i <= 10; ++i) {
            len += children[keccak256(abi.encode(user, i))].length;
        }
        return len;
    }

    function getChildren(
        address user,
        uint256 level,
        uint256 pageIndex,
        uint256 pageSize
    ) external view returns (address[] memory) {
        bytes32 key = keccak256(abi.encode(user, level));
        uint256 len = children[key].length;
        address[] memory list = new address[](
            pageIndex * pageSize <= len
                ? pageSize
                : len - (pageIndex - 1) * pageSize
        );
        uint256 start = (pageIndex - 1) * pageSize;
        for (uint256 i = start; i < start + list.length; ++i) {
            list[i - start] = children[key][i];
        }
        return list;
    }
}