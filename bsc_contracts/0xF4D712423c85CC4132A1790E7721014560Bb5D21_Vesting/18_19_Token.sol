// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interface/ITokenVesting.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Token for distribution.
 */
contract Token is ERC20, ERC20Burnable, Ownable {
    /**
     * @notice The max amount of tokens.
     */
    uint256 public constant MAX_TOTAL_SUPPLY = 809710000e18;

    /**
     * @notice True if TGE has been executed.
     */
    bool public isExecuted;

    error TGEExecuted();

    constructor(
        string memory name_,
        string memory symbol_,
        address to_
    ) ERC20(name_, symbol_) {
        _mint(to_, MAX_TOTAL_SUPPLY);
    }

    /**
     * @notice Executes TGE, startes vesting.
     * @param _vesting The vesting contract address.
     * @param _amount The amount of transfering.
     */
    function executeTGE(address _vesting, uint256 _amount) external onlyOwner {
        if (isExecuted) {
            revert TGEExecuted();
        }

        isExecuted = true;

        transfer(_vesting, _amount);

        ITokenVesting(_vesting).setStartAt();
    }
}