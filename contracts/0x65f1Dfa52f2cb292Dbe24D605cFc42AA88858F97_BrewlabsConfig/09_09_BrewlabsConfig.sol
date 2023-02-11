// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract BrewlabsConfig is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    event RegisterFarm(address indexed farm);
    event RegisterPool(address indexed pool, bool isLockup);
    event RegisterMultiPool(address indexed pool);

    constructor() {}

    function initialize() public initializer {
        __Ownable_init();
    }

    function regFarm(address farm) external onlyOwner {
        emit RegisterFarm(farm);
    }

    function regPool(address pool, bool isLockup) external onlyOwner {
        emit RegisterPool(pool, isLockup);
    }

    function regMultiPool(address pool) external onlyOwner {
        emit RegisterMultiPool(pool);
    }

    /**
     * @notice Emergency withdraw tokens.
     * @param _token: token address
     */
    function rescueTokens(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            uint256 _ethAmount = address(this).balance;
            payable(msg.sender).transfer(_ethAmount);
        } else {
            uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, _tokenAmount);
        }
    }

    receive() external payable {}
}