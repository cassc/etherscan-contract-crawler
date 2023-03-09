// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Interface for ERC-721 token contract
interface IERC721 {
    event Approval(address indexed _owner, address indexed _spender, uint256 indexed _id);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _id);

    function approve(address _spender, uint256 _id) external;

    function balanceOf(address _owner) external view returns (uint256);

    function getApproved(uint256) external view returns (address);

    function isApprovedForAll(address, address) external view returns (bool);

    function name() external view returns (string memory);

    function ownerOf(uint256 _id) external view returns (address owner);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) external;

    function setApprovalForAll(address _operator, bool _approved) external;

    function supportsInterface(bytes4 _interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 _id) external view returns (string memory);

    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}