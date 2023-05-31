// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { VanillaV1Converter } from "./VanillaV1Migration01.sol";
import "./interfaces/IVanillaV1Token02.sol";
import "./interfaces/v1/VanillaV1Token01.sol";

/**
 @title Governance Token for Vanilla Finance.
 */
contract VanillaV1Token02 is ERC20("Vanilla", "VNL"), VanillaV1Converter, IVanillaV1Token02 {
    string private constant _ERROR_ACCESS_DENIED = "c1";
    address private immutable _owner;

    /**
        @notice Deploys the token and sets the caller as an owner.
     */
    constructor(IVanillaV1MigrationState _migrationState, address _vnlAddress) VanillaV1Converter(_migrationState, IERC20(_vnlAddress)) {
        _owner = msg.sender;
    }

    /**
        @dev set the decimals explicitly to 12, for (theoretical maximum of) VNL reward of a 1ETH of profit should be displayed as 1000000VNL (18-6 = 12 decimals).
     */
    function decimals() public pure override returns (uint8) {
        return 12;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, _ERROR_ACCESS_DENIED);
        _;
    }

    function mintConverted(address target, uint256 amount) internal override {
        _mint(target, amount);
    }

    /**
        @notice Mints the tokens. Used only by the VanillaRouter-contract.

        @param to The recipient address of the minted tokens
        @param tradeReward The amount of tokens to be minted
     */
    function mint(address to, uint256 tradeReward) external override onlyOwner {
        _mint(to, tradeReward);
    }
}