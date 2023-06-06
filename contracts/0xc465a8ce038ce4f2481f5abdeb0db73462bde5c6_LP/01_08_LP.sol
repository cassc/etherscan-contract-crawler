// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LP is ERC20Upgradeable, OwnableUpgradeable {
    address public swapPool;

    event SwapPoolChanged(address newSwapPool);

    modifier onlySwapPool() {
        require(msg.sender == swapPool, "only swap pool can call this function");
        _;
    }

    function initialize(string calldata _name, string calldata _symbol)
    external
    initializer
    {
        __ERC20_init_unchained(_name, _symbol);
        __Ownable_init();
    }

    function setSwapPool(address _swapPool) external onlyOwner {
        require(swapPool == address(0), "swap pool can be set only once");
        swapPool = _swapPool;

        emit SwapPoolChanged(_swapPool);
    }

    function mint(address _account, uint256 _amount) external onlySwapPool {
        _mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external onlySwapPool {
        _burn(_account, _amount);
    }
}