// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ISattvaSoulSupporters {
    function mint(
        address to,
        uint256 amount
    ) external;

    function burn(
        uint256 id
    ) external;

    function sssTotalSupply() external view returns (uint256);

    function sadhana(
        uint256 _tokenId
    ) external;
}