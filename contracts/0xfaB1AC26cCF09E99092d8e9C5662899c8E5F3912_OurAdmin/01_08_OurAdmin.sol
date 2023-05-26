// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";

contract OurAdmin is ERC721Holder, ERC1155Holder {

    event Execution(bytes32 hash);
    event ExecutionFailure(bytes32 hash);
    event LogSetWhiteList(address indexed sender, address indexed whiteList, bool isAdd);
    event LogDropSelf(address indexed sender);
    event LogTransferOwnership(address indexed sender, address indexed newOwner);
    event LogClaimOwner(address indexed sender);

    mapping (bytes32 => bool) executed;
    mapping (address => bool) whiteList;
    address owner;
    address newOwner;
    //bool suspend = false;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyWhiteList() {
        require (whiteList[msg.sender] || msg.sender == owner);
        _;
    }

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    function execute(
        address _destination,
        bytes memory _data,
        uint256 _nonce) external onlyWhiteList returns (bool)
    {
        //require(!suspend);
        bytes32 hash = keccak256(abi.encodePacked(this, _destination, _nonce, _data));
        require(!executed[hash]);
        (bool success, ) = _destination.call{value: 0}(_data);
        if (success) {
            executed[hash] = true;
            emit Execution(hash);
            return true;
        } else {
            emit ExecutionFailure(hash);
            return false;
        }
    }

    function setWhiteList(address _whiteList, bool _isAdd) external onlyOwner returns (bool) {
        //require(!suspend);
        whiteList[_whiteList] = _isAdd;
        emit LogSetWhiteList(msg.sender, _whiteList, _isAdd);
        return true;
    }

    //function dropSelf() external onlyOwner returns (bool) {
    //    suspend = true;
    //    emit LogDropSelf(msg.sender);
    //    return true;
    //}

    function transferOwnership(address _newOwner) external onlyOwner returns (bool) {
        newOwner = _newOwner;
        emit LogTransferOwnership(msg.sender, _newOwner);
        return true;
    }

    function claimOwner() external returns (bool) {
        require (msg.sender == newOwner);
        owner = newOwner;
        emit LogClaimOwner(msg.sender);
        return true;
    }

    function isInWhiteList(address _whiteList) public view returns (bool) {
        return whiteList[_whiteList];
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getNewOwner() public view returns (address) {
        return newOwner;
    }

    //function isSuspend() public view returns (bool) {
    //    return suspend;
    //}
}