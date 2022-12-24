// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@1inch/erc20-pods/contracts/ERC20Pods.sol";
import "./interfaces/IDelegatedShare.sol";

contract DelegatedShare is IDelegatedShare, ERC20Pods {
    error ApproveDisabled();
    error TransferDisabled();
    error NotOwner();

    address immutable private _owner;

    modifier onlyOwner {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxUserPods,
        uint256 podCallGasLimit
    ) ERC20(name, symbol) ERC20Pods(maxUserPods, podCallGasLimit) {
        _owner = msg.sender;
    }

    function addDefaultFarmIfNeeded(address account, address farm) external onlyOwner {
        if (!hasPod(account, farm)) {
            _addPod(account, farm);
        }
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }

    function approve(address /* spender */, uint256 /* amount */) public pure override(ERC20, IERC20) returns (bool) {
        revert ApproveDisabled();
    }

    function transfer(address /* to */, uint256 /* amount */) public pure override(IERC20, ERC20) returns (bool) {
        revert TransferDisabled();
    }

    function transferFrom(address /* from */, address /* to */, uint256 /* amount */) public pure override(IERC20, ERC20) returns (bool) {
        revert TransferDisabled();
    }

    function increaseAllowance(address /* spender */, uint256 /* addedValue */) public pure override returns (bool) {
        revert ApproveDisabled();
    }

    function decreaseAllowance(address /* spender */, uint256 /* subtractedValue */) public pure override returns (bool) {
        revert ApproveDisabled();
    }
}