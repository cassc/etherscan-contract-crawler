// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NeuronToken is ERC20 {
    address public transferAllower;

    bool public isTransfersAllowed;

    event TransfersAllowed();

    event TransferAllowerUpdated(address indexed newTransferAllower);

    struct InitialHolder {
        address recipient;
        uint256 amount;
    }

    constructor(InitialHolder[] memory _initialHolders, address _transferAllower) ERC20("Neuron", "NEUR") {
        for (uint256 i; i < _initialHolders.length; i++) {
            _mint(_initialHolders[i].recipient, _initialHolders[i].amount);
        }
        transferAllower = _transferAllower;
    }

    function allowTranfers() external {
        require(msg.sender == transferAllower, "!transferAllower");
        require(!isTransfersAllowed, "Transfers already allowed");
        isTransfersAllowed = true;
        emit TransfersAllowed();
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(isTransfersAllowed, "The Token is currently non-transferrable");
        super._transfer(sender, recipient, amount);
    }

    function setTransferAllower(address _newTransferAllower) external {
        require(msg.sender == transferAllower, "!transferAllower");
        transferAllower = _newTransferAllower;
        emit TransferAllowerUpdated(_newTransferAllower);
    }
}