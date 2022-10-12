// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";


abstract contract Defii is IDefii {
    address public owner;
    address public factory;

    function init(address owner_, address factory_) external {
        require(owner == address(0), "Already initialized");
        owner = owner_;
        factory = factory_;
    }

    // owner functions
    function enter() external onlyOwner {
        _enter();
    }

    function runTx(address target, uint256 value, bytes memory data) external onlyOwner {
        (bool success,) = target.call{value: value}(data);
        require(success, "runTx failed");
    }

    // owner and executor functions
    function exit() external onlyOnwerOrExecutor {
        _exit();
    }
    function exitAndWithdraw() public onlyOnwerOrExecutor {
        _exit();
        _withdrawFunds();
    }

    function harvest() external onlyOnwerOrExecutor {
        _harvest();
    }

    function withdrawFunds() external onlyOnwerOrExecutor {
        _withdrawFunds();
    }

    function withdrawERC20(IERC20 token) public onlyOnwerOrExecutor {
        _withdrawERC20(token);
    }

    function withdrawETH() public onlyOnwerOrExecutor {
        _withdrawETH();
    }
    receive() external payable {}

    // internal functions - common logic
    function _withdrawERC20(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.transfer(owner, tokenAmount);
        }
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success,) = owner.call{value: balance}("");
            require(success, "Transfer failed");
        }
    }

    // internal functions - defii specific logic
    function _enter() internal virtual;
    function _exit() internal virtual;
    function _harvest() internal virtual;
    function _withdrawFunds() internal virtual;

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOnwerOrExecutor() {
        require(msg.sender == owner || msg.sender == IDefiiFactory(factory).executor(), "Only owner or executor");
        _;
    }
}