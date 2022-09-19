pragma solidity ^0.8.17;
interface IErc721ItemAsset {
    function getContractAddress() external returns (address);

    function getTokenId() external returns (uint256);
}