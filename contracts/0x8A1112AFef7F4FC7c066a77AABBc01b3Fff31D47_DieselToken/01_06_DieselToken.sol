// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IDieselToken } from "../interfaces/IDieselToken.sol";

/// @dev DieselToken is LP token for Gearbox pools
contract DieselToken is ERC20, IDieselToken {
    uint8 private immutable _decimals;
    address public immutable poolService;

    modifier onlyPoolService() {
        if (msg.sender != poolService) {
            revert PoolServiceOnlyException();
        }
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        poolService = msg.sender;
    }

    function mint(address to, uint256 amount) external onlyPoolService {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external onlyPoolService {
        _burn(to, amount);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}