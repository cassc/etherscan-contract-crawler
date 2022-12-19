pragma solidity ^0.8.15;

interface IMintable {
    function mint(address owner, uint256 id, uint256 amount) external;

    function mintBatch(address owner, uint256[] memory ids, uint256[] memory amounts) external;
}