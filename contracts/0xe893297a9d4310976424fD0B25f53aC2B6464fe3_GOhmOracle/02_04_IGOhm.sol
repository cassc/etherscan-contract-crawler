// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.17;

// NOTE: This file generated from gOHm contract at https://etherscan.io/address/0x0ab87046fBb341D058F17CBC4c1133F25a20a52f#code

interface IGOhm {
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function approved() external view returns (address);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);

    function burn(address _from, uint256 _amount) external;

    function checkpoints(address, uint256) external view returns (uint256 fromBlock, uint256 votes);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function delegate(address delegatee) external;

    function delegates(address) external view returns (address);

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function index() external view returns (uint256);

    function migrate(address _staking, address _sOHM) external;

    function migrated() external view returns (bool);

    function mint(address _to, uint256 _amount) external;

    function name() external view returns (string memory);

    function numCheckpoints(address) external view returns (uint256);

    function sOHM() external view returns (address);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}