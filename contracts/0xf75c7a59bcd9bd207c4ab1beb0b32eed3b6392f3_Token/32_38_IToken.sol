// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

interface IToken {

    event LogicUpdate(address indexed prevLogic, address indexed newLogic, address indexed sender);

    struct TransferResult {
        uint128 mint;
        uint128 burn;
        uint128 fee;
        uint128 amount;
    }

    function MINT_ROLE() external view returns (bytes32);

    function logic() external view returns (address);
    function updateLogic(address newLogic) external;
    function predictTransfer(address from, address to, uint256 amount) external view returns (TransferResult memory);

    function mint(uint256 amount) external;
    function burn(uint256 amount) external;
}