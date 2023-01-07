// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

interface IBNBP {
    error AirdropTimeError();

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function isUserAddress(address addr) external view returns (bool);

    function calculatePairAddress() external view returns (address);

    function performAirdrop() external returns (uint256);

    function performBurn() external returns (uint256);

    function performLottery() external returns (address);

    function setPotContractAddress(address addr) external;

    function setAirdropPercentage(uint8 percentage) external;

    function setAirdropInterval(uint256 interval) external;

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}