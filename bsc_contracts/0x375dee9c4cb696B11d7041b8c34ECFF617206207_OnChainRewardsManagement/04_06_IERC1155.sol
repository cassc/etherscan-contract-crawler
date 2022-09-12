// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IERC165.sol";

interface IERC1155 is IERC165 {
    function balanceOf(address _account, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _accounts, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _account, address _operator) external view returns (bool);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
    event TransferSingle(address _operator, address _from, address _to, uint256 _id, uint256 _value);
    event TransferBatch(address _operator, address _from, address _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address _account, address _operator, bool _approved);
    event URI(string _value, uint256 _id);

    function mint(address _to, uint256 _id, uint256 _amount) external;
}