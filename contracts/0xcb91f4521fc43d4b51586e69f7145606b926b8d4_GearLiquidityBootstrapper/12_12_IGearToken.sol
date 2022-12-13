pragma solidity ^0.8.10;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGearToken is IERC20 {
    function allowTransfers() external;

    function transferOwnership(address newManager) external;

    function setMiner(address _miner) external;

    function miner() external view returns (address);

    function manager() external view returns (address);

    function balances(int128 i) external view returns (uint256);

    function transfersAllowed() external view returns (bool);
}