// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/@openzeppelin/token/ERC20/ERC20.sol";
import "./dependencies/@openzeppelin/access/Ownable.sol";
import "./dependencies/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./dependencies/@openzeppelin/utils/math/SafeMath.sol";

/**
 * @title Mock VSP.
 */
contract MockVSP is ERC20, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @dev Mint VSP. Only owner can mint
    function mint(address _recipient, uint256 _amount) external onlyOwner {
        _mint(_recipient, _amount);
    }
}