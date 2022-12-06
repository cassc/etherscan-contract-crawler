// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function mint(address _to, uint256 _tokenId, uint256 _amount) external;
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes[] memory serialNumbers) external;
    function burn(address _from, uint256 _tokenId, uint256 _amount) external;
    function mintWithSerial(address _to, uint256 _tokenId, uint256 _amount, bytes memory serialNumber) external;
}

interface IERC1155Receiver {
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);
}

interface IERC1155MetadataURI  {
    function uri(uint256 id) external view returns (string memory);
}