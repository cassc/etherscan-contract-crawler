// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SXToken is ERC20, ERC20Burnable, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
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
        _grantRole(PAUSER_ROLE, msg.sender);
        DEV = msg.sender;
        uint256 total = 10500000 * 10**decimals();

        // pool
        _mint(0xB8Be3672C92D3F59F9Ab39bb83635E3970965aa8, (total * 3) / 100);

        // lp rewards
        _mint(_LPRewards, (total * 17) / 100);

        // operation
        _mint(0x737c14Ba2D0E14967b3dF90c15246711A88f5Fc1, (total * 3) / 100);

        // game rewards
        _mint(_gameRewardPool, (total * 31) / 100);

        // dev
        _mint(_devRewards, (total * 1) / 100);

        // airdrop
        _mint(_airDrop, (total * 13) / 100);

        // community
        _mint(0xfc3670c5c64d78686fD10A4ac441AaD4A5625E41, (total * 9) / 100);

        // ecological
        _mint(_ecologicalReservePool, (total * 10) / 100);

        //invited
        _mint(_inviteRewardPool, (total * 3) / 100);

        //web3
        _mint(_web3Cooperator, (total * 10) / 100);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
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
    ) internal override whenNotPaused {
        uint256 fee = 0;
        //sell
        if (to == ROUTER) {
            // 7% fee
            fee = (amount * 7) / 100;
            transfer(DEV, fee);
        }
        super._beforeTokenTransfer(from, to, amount - fee);
    }
}