// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAdapter } from "@gearbox-protocol/core-v2/contracts/interfaces/adapters/IAdapter.sol";
import { AddressProvider } from "@gearbox-protocol/core-v2/contracts/core/AddressProvider.sol";
import { IPriceOracleV2 } from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceOracle.sol";
import { IGasPricer } from "../interfaces/IGasPricer.sol";
import { RAY } from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

uint256 constant ZERO_BALANCE_INIT_GAS_COST = 20_000;

struct GasUsage {
    address targetContract;
    bytes32 key;
    uint256 usage;
}

contract GasPricer is IGasPricer, Ownable {
    IPriceOracleV2 public priceOracle;
    address public immutable wethToken;

    mapping(address => mapping(bytes32 => uint256)) public gasUsage;

    constructor(address _addressProvider) {
        AddressProvider ap = AddressProvider(_addressProvider);

        wethToken = ap.getWethToken(); // F:[CPF-1]
        priceOracle = IPriceOracleV2(ap.getPriceOracle()); // F:[CPF-1]
    }

    function setGasUsage(
        address targetContract,
        bytes32 key,
        uint256 usage
    ) external onlyOwner {
        gasUsage[targetContract][key] = usage;
    }

    function setGasUsageBatch(GasUsage[] memory batchUsages)
        external
        onlyOwner
    {
        uint256 len = batchUsages.length; // F:[GET-3]
        unchecked {
            for (uint256 i; i < len; ++i) {
                GasUsage memory g = batchUsages[i]; // F:[GET-3,4]
                gasUsage[g.targetContract][g.key] = g.usage; // F:[GET-3,4]
            }
        }
    }

    function getGasPriceTokenOutRAY(address token)
        public
        view
        returns (uint256 gasPrice)
    {
        try priceOracle.convert(block.basefee * RAY, wethToken, token) returns (
            uint256 price
        ) {
            gasPrice = price;
        } catch {
            gasPrice = block.basefee * RAY * 10**9;
        }
    }
}