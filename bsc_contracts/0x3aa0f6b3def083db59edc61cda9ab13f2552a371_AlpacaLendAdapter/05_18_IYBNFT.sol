// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

interface IYBNFT {
    struct Adapter {
        uint256 allocation;
        address token;
        address addr;
    }

    function getCurrentTokenId() external view returns (uint256);

    function performanceFee(uint256 tokenId) external view returns (uint256);

    function getAdapterInfo(uint256 tokenId)
        external
        view
        returns (Adapter[] memory);

    function exists(uint256) external view returns (bool);

    function mint(
        uint256[] calldata,
        address[] calldata,
        address[] calldata,
        uint256,
        string memory
    ) external;
}