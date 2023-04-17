// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IBabyWonderlandMintable {
    function mint(address to) external;

    function batchMint(address _recipient, uint256 _number) external;

    function totalSupply() external view returns (uint256);
}