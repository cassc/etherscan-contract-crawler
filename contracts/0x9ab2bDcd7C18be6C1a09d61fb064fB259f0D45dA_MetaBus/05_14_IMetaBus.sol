pragma solidity ^0.8.0;

interface IMetaBus {
    function mint(address _to) external;
    function numberMinted(address _to) external view returns (uint256);
}