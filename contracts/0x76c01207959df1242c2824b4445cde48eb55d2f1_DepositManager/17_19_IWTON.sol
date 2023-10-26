// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWTON {

    function onApprove(
        address owner,
        address spender,
        uint256 tonAmount,
        bytes calldata data
    ) external returns (bool);

    function swapToTON(uint256 wtonAmount) external returns (bool);
    function swapToTONAndTransfer(address to, uint256 wtonAmount) external returns (bool);
    function swapFromTONAndTransfer(address to, uint256 tonAmount) external returns (bool);
    function renounceTonMinter() external;
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function renounceMinter() external ;
    function mint(address account, uint256 amount) external returns (bool);

}