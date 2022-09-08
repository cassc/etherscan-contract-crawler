//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ILiquidityToken.sol";
import "../external/IERC677Receiver.sol";
import "../external/IERC677Token.sol";
import "../lib/Utils.sol";

/// @title The liquidity token of a Futureswap exchange
///        Note: The owner of the liquidity token is the exchange that uses the token
contract LiquidityToken is ERC20, IERC677Token, Ownable, ILiquidityToken, GitCommitHash {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @inheritdoc ILiquidityToken
    function mint(uint256 amount) external override onlyOwner {
        _mint(msg.sender, amount);
    }

    /// @inheritdoc ILiquidityToken
    function burn(uint256 amount) external override onlyOwner {
        _burn(msg.sender, amount);
    }

    /// @inheritdoc ERC20
    function totalSupply() public view override(ERC20, IERC20) returns (uint256) {
        return ERC20.totalSupply();
    }

    /// @inheritdoc ERC20
    function balanceOf(address account) public view override(ERC20, IERC20) returns (uint256) {
        return ERC20.balanceOf(account);
    }

    /// @inheritdoc IERC677Token
    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external override returns (bool success) {
        super.transfer(to, value);
        if (Address.isContract(to)) {
            IERC677Receiver receiver = IERC677Receiver(to);
            return receiver.onTokenTransfer(msg.sender, value, data);
        }
        return true;
    }
}