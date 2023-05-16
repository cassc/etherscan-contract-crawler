// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorInterface} from "./lib/chainlink/AggregatorInterface.sol";
import {IGasChecker} from "./IGasChecker.sol";

contract GasChecker is Ownable, IGasChecker {

    address immutable public override gasOracle; // chainlink fast gas oracle;
    uint256 public override gasTolerance; // for example, 40 gwei;

    /// @param _gasOracle chainlink gas oracle
    /// @param _gasTolerance gas tolerance threshold for transactions (for example, 40 gwei)
    constructor(
        address _gasOracle,
        uint256 _gasTolerance
    ) {
        require(_gasTolerance > 0, "invalid gasTolerance");

        gasTolerance = _gasTolerance;
        gasOracle = _gasOracle;

        emit DeployGasChecker(
            msg.sender,
            _gasOracle,
            _gasTolerance
        );
    }

    /// Sets the gas tolerance threshold for transactions
    /// @param _gasTolerance gas tolerance threshold in gwei
    function setGasTolerance(uint256 _gasTolerance) external override onlyOwner {
        require(_gasTolerance > 0, "invalid gasTolerance");
        gasTolerance = _gasTolerance;
        emit SetGasTolerance(msg.sender, _gasTolerance);
    }

    function checkGas() override external view
        returns (int256 gas)
    {
        gas = AggregatorInterface(gasOracle).latestAnswer();
    }

    function isGasAcceptable() override external view
        returns (bool isAcceptable)
    {
        int256 gas = AggregatorInterface(gasOracle).latestAnswer();
        isAcceptable = uint256(gas) <= gasTolerance * 10 ** 9;
    }

}