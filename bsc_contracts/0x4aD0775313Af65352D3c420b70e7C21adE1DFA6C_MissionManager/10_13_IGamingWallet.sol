// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

// Generic wallet contract to interact with GamingProxies
// TODO: Implement EIP 1271 to get isValidSignature function for games
interface IGamingWallet {
    event NFTDeposited(address collection, uint256 tokenID);
    event NFTWithdrawn(address collection, uint256 tokenID);
    event NFTReturned(address collection, uint256 tokenID);

    function bulkReturnAsset(
        address returnAddress,
        address[] calldata _collection,
        uint256[][] calldata _tokenID
    ) external;

    // Functions to allow users to deposit own assets
    function depositAsset(address collection, uint256 id) external;

    function withdrawAsset(address collection, uint256 id) external;

    // Generic functions to run delegatecalls with the game proxies
    function forwardCall(address gameContract, bytes calldata data_)
        external
        returns (bytes memory);

    function oasisClaimForward(address gameContract, bytes calldata data_)
        external
        returns (bytes memory);

    function oasisDistributeERC20Rewards(
        address _rewardToken,
        address _rewardReceiver,
        uint256 _rewardAmount
    ) external;

    function oasisDistributeERC721Rewards(
        address _receiver,
        address _collection,
        uint256 _tokenId
    ) external;

    function oasisDistributeERC1155Rewards(
        address _receiver,
        address _collection,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue);

    // Will be overridden to return the owner of the wallet
    function owner() external view returns (address);

    function revenueManager() external view returns (address);
}