pragma solidity 0.8.9;

import {IEscrow} from "./IEscrow.sol";

interface IEscrowedLine {
    event Liquidate(bytes32 indexed id, uint256 indexed amount, address indexed token, address escrow);

    function liquidate(uint256 amount, address targetToken) external returns (uint256);

    function escrow() external returns (IEscrow);
}