pragma solidity ^0.8.15;

interface IBurnable {

    function burn(
        address owner,
        uint256 id, 
        uint256 amount
    ) external;
 
    function burnBatch(
        address owner,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;
}