// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.7.1;

interface IMinter {
    event Minted(address _sender, uint256 _amount);
    event Burned(address _sender, uint256 _amount);

    function mint(uint256 _amount) external;

    function burn(uint256 _amount) external;

    function iQ() external view returns (address);

    function wrappedIQ() external view returns (address);
}