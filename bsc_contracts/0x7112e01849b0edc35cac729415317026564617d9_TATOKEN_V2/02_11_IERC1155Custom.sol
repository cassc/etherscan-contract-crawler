pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";

interface IERC1155Custom is IERC1155Upgradeable {

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data, string calldata keyAuth) external;

    function safeBatchTransferFrom(address from,address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data,string memory key_auth) external;

}