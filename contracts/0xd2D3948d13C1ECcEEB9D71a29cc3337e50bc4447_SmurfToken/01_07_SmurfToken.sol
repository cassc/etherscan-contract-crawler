// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

error TransferDelay();
error TransferDisabled();

contract SmurfToken is ERC20, ERC20Burnable, Ownable {
    bool public transferDelay = true;
    bool public transferEnabled;

    mapping(address => uint256) private _lastTransfersPerAddr;

    constructor(uint256 _totalSupply) ERC20("Smurf", "SMRF") payable {
        _mint(_msgSender(), _totalSupply);
    }

    function flipTransferDelay() external payable onlyOwner {
        transferDelay = !transferDelay;
    }

    function flipTransferEnabled() external payable onlyOwner {
        transferEnabled = !transferEnabled;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && amount != 0) {
            if (!transferEnabled) _revert(TransferDisabled.selector);
            if (transferDelay) {
                if (_lastTransfersPerAddr[tx.origin] >= block.number) _revert(TransferDelay.selector);
                unchecked {
                    _lastTransfersPerAddr[tx.origin] = block.number;
                }
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _revert(bytes4 errorSelector) internal pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}