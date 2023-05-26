// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity 0.8.9;


interface IGoldenTicket {
    function tokensByOwner(address owner, uint256 fromIndex, uint256 toIndex) external view returns (uint256[] memory);

    function mintGoldenTicketViaBurn(uint256 amountToBuy, uint256[] calldata tokenIds) external;

    function mintGoldenTicketViaETH(uint256 amountToBuy) external payable;

    function mintGoldenTicketViaAdmin(uint256 amountToBuy) external;

    function setErc721Pepe(address pepe) external;

    function setBaseURI(string memory uri) external;

    function setPrice(uint256 price) external;

    function setDeadline(uint256 deadline) external;

    function setMaxSupply(uint256 maxSupply) external;
}