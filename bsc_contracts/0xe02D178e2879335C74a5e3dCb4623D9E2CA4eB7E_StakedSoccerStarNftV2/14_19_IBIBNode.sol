pragma solidity ^0.8.9;

interface IBIBNode {

    struct Node {
        address ownerAddress;
        uint256 cardNftId;
        uint256 createTime;
        uint256 upNode;
    }
    
    function isStakedAsNode(uint tokenId) external view returns(bool);

    function getFreezeAmount(address _account) external view returns(uint256);

    function nodeMap(uint256 ticketId) external view returns(Node memory);

}