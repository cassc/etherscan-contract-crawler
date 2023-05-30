//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICore.sol";
import "./IStkEth.sol";
import "./IOracle.sol";

/// @title CoreRef interface
/// @author Ankit Parashar
interface ICoreRef {

    event SetCore(address _core);

    function setCore(address core) external;

    function pause() external;

    function unpause() external;

    // ----------- Getters -----------

    function core() external view returns (ICore);

    function stkEth() external view returns (IStkEth);

    function oracle() external view returns (IOracle);
}