// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SXToken is ERC20, ERC20Burnable, AccessControl {

    address public ROUTER;
    address public DEV;

    constructor(
        address _LPRewards,
        address _gameRewardPool,
        address _devRewards,
        address _airDrop,
        address _ecologicalReservePool,
        address _inviteRewardPool,
        address _web3Cooperator
    ) ERC20("SX Token", "SX") {

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        DEV = _devRewards;

        uint256 total = 10500000 * 10**decimals();

        // pool
        _mint(0x20D1cFD452187B10Fcc76462E3CbCB0a72bA8a6A, (total * 3) / 100);

        // lp rewards
        _mint(_LPRewards, (total * 17) / 100);

        // operation
        _mint(0xA46EDa00E18D6A3d9946a02c1a8A40a06b92eF1C, (total * 3) / 100);

        // game rewards
        _mint(_gameRewardPool, (total * 31) / 100);

        // dev
        _mint(_devRewards, (total * 1) / 100);

        // airdrop
        _mint(_airDrop, (total * 13) / 100);

        // community
        _mint(0xA4dB8d85018A5093384807C3ff9ecc51a908e8c9, (total * 9) / 100);

        // ecological
        _mint(_ecologicalReservePool, (total * 10) / 100);

        //invited
        _mint(_inviteRewardPool, (total * 3) / 100);

        //web3
        _mint(_web3Cooperator, (total * 10) / 100);
    }


    function changeDev(address _dev) public onlyRole(DEFAULT_ADMIN_ROLE) {
        DEV = _dev;
    }

    function changeRouter(address _router) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ROUTER = _router;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 fee = 0;
        //sell
        if (to == ROUTER) {
            // 7% fee
            fee = (amount * 7) / 100;
            _transfer(from, DEV, fee);
        }
        super._beforeTokenTransfer(from, to, amount - fee);
    }
}