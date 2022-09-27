pragma solidity ^0.8.9;

interface IBIBStaking {
    
    function getFreezeAmount(address _account) external view returns(uint256);
    
    function createNode(address operator, uint256 _ticket, uint256 _bibAmount) external;
    function disbandNode(address operator, uint256 _ticket) external;
    function transferNodeSetUp(address from, address to, uint256 _ticket) external;
    function nodeStake(uint256 _from, uint256 _to) external returns(uint256);
    function nodeUnStake(uint256 _from, uint256 _to) external returns(uint256);
}