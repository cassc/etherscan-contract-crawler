pragma solidity ^0.8.10;

interface ITokenEmitter {
    function buyToken(address[] memory _addresses, uint[] memory _percentages) external payable returns (uint256);
    function getTokenAmount(uint256 payment) external view returns (uint256);
    function UNSAFE_getOverestimateTokenAmount(uint256 payment) external view returns (uint256);
    function getTokenPrice(uint256 currentTotalSupply) external view returns (uint256);
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
}