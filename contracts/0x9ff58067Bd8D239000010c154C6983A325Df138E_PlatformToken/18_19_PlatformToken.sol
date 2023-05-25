// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../access_controller/PlatformAccessController.sol';
import './price_provider/IPlatformTokenPriceProvider.sol';
import './EIP3009/EIP3009.sol';
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import "./IplatformToken/IPlatformToken.sol";

interface IAntisnipe {
    function assureCanTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external;
}

/**
 * @notice ERC20 token with some extra functionality
 * By default, there are restrictions on transfers to contracts not in whitelist
 * Method for transferring without approval, you can see the contracts that use it
 */
contract PlatformToken is ERC20, PlatformAccessController, EIP3009, ReentrancyGuard, IPlatformToken {
    using SafeERC20Upgradeable for IERC20;

    address private _vesting;
    address private _staking;

    IAntisnipe public antisnipe;
    bool public antisnipeDisable;

    event UpdateVesting(
        address _address,
        uint256 timestamp
    );

    event UpdateStaking(
        address _address,
        uint256 timestamp
    );

    event disableAntisnipe(
        uint256 timestamp
    );

    event UpdateAntisnipe(
        address _address,
        uint256 timestamp
    );

    error InvalidAddress();
    error ZeroAmount();
    error InvalidSender();
    error AntisnipeDisabled();

    /**
     * @param adminPanel platform admin panel address
     */
    constructor(
        address adminPanel,
        address recipient,
        uint256 supply
    ) ERC20('Propchain Token', 'PROPC') {
        if(adminPanel == address(0) || recipient == address(0))
            revert InvalidAddress();
        if(supply == 0)
            revert ZeroAmount();

        _initiatePlatformAccessController(adminPanel);
        _mint(recipient, supply);
    }

    /**
     * @notice Removed the initiate function as recommended and created various setters
     */
    function updateVestingAddress(address vesting) external onlyPlatformAdmin {
        if(vesting == address(0))
            revert InvalidAddress();

        _vesting = vesting;
        emit UpdateVesting(vesting, block.timestamp);
    }

    function updateStakingAddress(address staking) external onlyPlatformAdmin {
        if(staking == address(0))
            revert InvalidAddress();

        _staking = staking;
        emit UpdateStaking(staking, block.timestamp);
    }

    /**
     * @notice Burn tokens from the sender balance
     * Only platform admin can do
     */
    function burn(uint256 amount) external onlyPlatformAdmin {
        _burn(msgSender(), amount);
    }

    /**
     * @dev Similar to transferFrom, but to address is sender
     * Only vesting, staking and cashback contracts can call
     * Designed to save money, transfers without approval
     */
    function specialTransferFrom(
        address from,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        address to = msgSender();

        if(to != _vesting && to != _staking)
            revert InvalidSender();
        if(value == 0)
            revert ZeroAmount();

        transferWithAuthorization(
            from,
            to,
            value,
            validAfter,
            validBefore,
            nonce,
            v,
            r,
            s
        );

        _transfer(from, to, value);
    }

    /**
     * @dev Call before transfer
     * @param to address to tokens are transferring
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == address(0) || to == address(0)) return;
        if (!antisnipeDisable && address(antisnipe) != address(0))
            antisnipe.assureCanTransfer(msg.sender, from, to, amount);
    }

    function setAntisnipeDisable() external onlyPlatformAdmin {
        if(antisnipeDisable)
            revert AntisnipeDisabled();
        antisnipeDisable = true;

        emit disableAntisnipe(block.timestamp);
    }

    function setAntisnipeAddress(address addr) external onlyPlatformAdmin {
        if(addr == address(0))
            revert InvalidAddress();
        antisnipe = IAntisnipe(addr);

        emit UpdateAntisnipe(addr, block.timestamp);
    }
}