// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "OpenNFTs/contracts/interfaces/IOpenReceiverInfos.sol";

interface IOpenMarketable is IOpenReceiverInfos {
    enum Approve {
        None,
        One,
        All
    }

    event SetDefaultRoyalty(address receiver, uint96 fee);

    event SetTokenRoyalty(uint256 tokenID, address receiver, uint96 fee);

    event SetMintPrice(uint256 price);

    event SetTokenPrice(uint256 tokenID, uint256 price);

    event Pay(
        uint256 tokenID,
        uint256 price,
        address seller,
        uint256 paid,
        address receiver,
        uint256 royalties,
        uint256 fee,
        address buyer,
        uint256 unspent
    );

    receive() external payable;

    function withdraw() external;

    function setMintPrice(uint256 price) external;

    function setDefaultRoyalty(address receiver, uint96 fee) external;

    function setTokenPrice(uint256 tokenID, uint256 price) external;

    function setTokenRoyalty(uint256 tokenID, address receiver, uint96 fee) external;

    function minimal() external view returns (bool);

    function getMintPrice() external view returns (uint256 price);

    function getDefaultRoyalty() external view returns (ReceiverInfos memory receiver);

    function getTokenPrice(uint256 tokenID) external view returns (uint256 price);

    function getTokenRoyalty(uint256 tokenID)
        external
        view
        returns (ReceiverInfos memory receiver);
}