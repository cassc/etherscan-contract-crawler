// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./utils/Ownable.sol";
import "./utils/Context.sol";
import "./utils/SafeMath.sol";
import "./utils/IERC20.sol";

contract Invite is Ownable {

    using SafeMath for uint256;

    address public rootAddress;
    mapping(address => address)  public parents;
    mapping(address => address[]) public children;
    mapping(address => uint256) public groupCount;
    mapping(address => bool) public settingRole;

    constructor(address _rootAddress) {
        rootAddress = _rootAddress;
    }

    function setRootAddress(address _rootAddress) public onlyOwner {
        rootAddress = _rootAddress;
    }

    function getChildren(address _address) external view returns (address[] memory) {
        return children[_address];
    }

    function getParent(address _address) external view returns (address) {
        if (parents[_address] == address(0)) {
            return rootAddress;
        } else {
            return parents[_address];
        }
    }

    function setSettingRole(address _address, bool _role) external onlyOwner {
        settingRole[_address] = _role;
    }

    function setParentBySettingRole(address _address, address _parent) external {
        require(settingRole[_msgSender()], "not allowed");
        require(parents[_address] == address(0), "has parent");
        require(_parent != _address, "no self");
        require(
            parents[_parent] != address(0) || _parent == rootAddress,
            "parent must have parent or owner"
        );
        parents[_address] = _parent;
        children[_parent].push(_address);
        setGroupCount(_address);
    }

    function setParent(address _parent) public {
        require(parents[_msgSender()] == address(0), "has parent");
        require(_parent != _msgSender(), "no self");
        require(
            parents[_parent] != address(0) || _parent == rootAddress,
            "parent must have parent or owner"
        );
        parents[_msgSender()] = _parent;
        children[_parent].push(_msgSender());
        setGroupCount(_msgSender());
    }

    function setGroupCount(address _address) private {
        address parent = parents[_address];
        for (uint256 i = 0; i < 3; i++) {
            if (parent == address(0)) {
                break;
            }
            groupCount[parent]++;
            parent = parents[parent];
        }
    }

    function getParentsByLevel(address _address, uint256 level)
    public
    view
    returns (address[] memory)
    {
        address[] memory p = new address[](level);
        address parent = parents[_address];
        for (uint256 i = 0; i < level; i++) {
            p[i] = parent;
            parent = parents[parent];
        }
        return p;
    }

    function rescueToken(address tokenAddress, uint256 tokens)
    public
    onlyOwner
    returns (bool success)
    {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function rescueETH(address payable _recipient) public onlyOwner {
        _recipient.transfer(address(this).balance);
    }

}