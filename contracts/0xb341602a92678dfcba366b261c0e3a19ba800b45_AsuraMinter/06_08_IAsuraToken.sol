// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract IAsuraToken {
    function mint(address _to, uint256 _amount) external virtual;

    function totalSupply() external view virtual returns (uint256);

    function numberMinted(address _owner)
        external
        view
        virtual
        returns (uint256);
}