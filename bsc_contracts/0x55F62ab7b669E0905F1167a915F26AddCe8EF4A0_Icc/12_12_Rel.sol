// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Rel is Ownable {
    event Bind(address indexed user, address indexed parent);

    mapping(address => address) public parents;

    mapping(bytes32 => address[]) public children;

    constructor(address _receiver, address genesis) {
        parents[genesis] = address(1);
        emit Bind(genesis, address(1));
        parents[_receiver] = genesis;
        addChild(_receiver, genesis);
        emit Bind(_receiver, genesis);
    }

    function bind(address parent) external {
        require(parents[msg.sender] == address(0), "already bind");
        require(parents[parent] != address(0), "parent invalid");
        parents[msg.sender] = parent;
        addChild(msg.sender, parent);
        emit Bind(msg.sender, parent);
    }

    function addChild(address user, address p) private {
        for (uint256 i = 1; i <= 2 && p != address(0) && p != address(1); ++i) {
            children[keccak256(abi.encode(p, i))].push(user);
            p = parents[p];
        }
    }

    function getChildren(address user, uint256 level)
        external
        view
        returns (address[] memory)
    {
        return children[keccak256(abi.encode(user, level))];
    }

    function getChildrenLength(address user, uint256 level)
        external
        view
        returns (uint256)
    {
        return children[keccak256(abi.encode(user, level))].length;
    }

    function getChildrenLength(address user) external view returns (uint256) {
        uint256 len;
        for (uint256 i = 1; i <= 2; ++i) {
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

    function initRel(address[] calldata addr, address[] calldata p)
        external
        onlyOwner
    {
        require(addr.length == p.length, "addrLen!=pLen");
        for (uint256 i = 0; i < addr.length; ++i) {
            require(parents[addr[i]] == address(0), "already bind");
            require(parents[p[i]] != address(0), "parent invalid");
            parents[addr[i]] = p[i];
            addChild(addr[i], p[i]);
            emit Bind(addr[i], p[i]);
        }
    }
}