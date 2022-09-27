pragma solidity ^0.8.9;

interface IBIBDividend {
    
    function setNodeBalance(address nodeOwner, uint256 amount, uint256 ticketId, uint256 weight) external;
    function setUserBalance(address user, uint256 ticketId, uint256 amount) external;
    function process(uint256 gas) external returns (uint256, uint256, uint256);
    function disbandNode(address nodeOwner, uint256 ticketId) external;
    function transferNode(address olduser, address newUser) external;
}