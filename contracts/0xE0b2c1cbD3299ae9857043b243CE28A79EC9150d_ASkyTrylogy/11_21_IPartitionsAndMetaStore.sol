//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPartitionsAndMetaStore {

    struct PrizeState {
        uint256 id;
        string codePrize;
        bool used;
        bool delegated;
        address proxy;
        uint256 winTimestamp;
        uint256 changedTimestamp;
    }

    function setDownSideBaseUri(string memory _downSideBaseUri) external;

    function getMetadata(uint256 tokenId) external view returns (string memory);

    function setNewWinner(uint256 tokenId, string memory codePrize, string memory winBaseUri) external;

    function withdrawPrize(uint256 tokenId, uint256 prizeId, string memory newWinBaseUri, bytes memory signature) external;

    function getPrizeStateByTokenId(uint256 tokenId) external view returns (PrizeState[] memory);

    function delegateAWinner(uint256 tokenId, uint256 prizeId, address delegated, string memory newBaseURI) external;

    function setWinBaseURI(uint256 tokenId, string memory newBaseURI) external;

    function usePrize(uint256 tokenId, uint256 prizeId, string memory newBaseURI) external;

    function revealBlock(uint8 _partition, string memory baseURI) external;

    function getListClosePartition() external view returns(uint256[] memory);

    function checkClosePartition(uint256 tokenId) external ;

    function getRevealedPartitions() external view returns(uint256[] memory);

    function getPartitionByTkId(uint256 tokenId) external view returns(uint64);

}