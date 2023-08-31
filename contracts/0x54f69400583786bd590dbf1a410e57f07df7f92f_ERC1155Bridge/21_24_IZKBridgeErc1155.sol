// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZKBridgeErc1155 {
    function zkBridgeMint(
        address _to,
        uint256 _id,
        uint256 _amount,
        string calldata _uri
    ) external;

    function zkBridgeBurn(address _from, uint256 _id, uint256 _amount) external;

    function uri(uint256 tokenId) external view returns (string memory);
}