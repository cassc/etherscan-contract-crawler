pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ITransferHookProcessor } from "../interfaces/ITransferHookProcessor.sol";

contract GiantLP is ERC20 {
    uint256 constant MIN_TRANSFER_AMOUNT = 0.001 ether;

    /// @notice Address of giant pool that deployed the giant LP token
    address public pool;

    /// @notice Optional address of contract that will process transfers of giant LP
    ITransferHookProcessor public transferHookProcessor;

    /// @notice Last interacted timestamp for a given address
    mapping(address => uint256) public lastInteractedTimestamp;

    constructor(
        address _pool,
        address _transferHookProcessor,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        pool = _pool;
        transferHookProcessor = ITransferHookProcessor(_transferHookProcessor);
    }

    function mint(address _recipient, uint256 _amount) external {
        require(msg.sender == pool, "Only pool");
        _mint(_recipient, _amount);
    }

    function burn(address _recipient, uint256 _amount) external {
        require(msg.sender == pool, "Only pool");
        _burn(_recipient, _amount);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        require(_from != _to && _amount >= MIN_TRANSFER_AMOUNT, "Transfer Error");
        if (address(transferHookProcessor) != address(0)) ITransferHookProcessor(transferHookProcessor).beforeTokenTransfer(_from, _to, _amount);
    }

    function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        lastInteractedTimestamp[_from] = block.timestamp;
        lastInteractedTimestamp[_to] = block.timestamp;
        if (address(transferHookProcessor) != address(0)) ITransferHookProcessor(transferHookProcessor).afterTokenTransfer(_from, _to, _amount);
    }
}