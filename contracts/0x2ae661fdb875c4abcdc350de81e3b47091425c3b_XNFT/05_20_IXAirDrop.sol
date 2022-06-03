pragma solidity ^0.8.2;

interface IXAirDrop {

    function execution(address nftContract,  address airDropContract, address receiver, uint256 tokenIds, uint256 ercType) external;

}