// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface INFT {
    function mint(
        address to,
        uint256 seri,
        uint256 startTime,
        uint256 endTime,
        string calldata result,
        uint256 status,
        uint256 winTickets,
        address buyer,
        uint256 buyTickets,
        string calldata asset
    ) external returns (uint256);

    function metadatas(uint256 _tokenId)
        external
        view
        returns (
            uint256 seri,
            uint256 startTime,
            uint256 endTime,
            string memory result,
            uint256 status,
            uint256 winTickets,
            address buyer,
            uint256 buyTickets,
            string memory asset
        );

    function burn(uint256 tokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}