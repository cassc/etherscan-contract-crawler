// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '../lib/ITFT.sol';

contract TFTToken is ITFT, ERC20Votes, Ownable {
    uint256 public constant MAX_AMOUNT = 10000000 * 10**18;

    constructor() ERC20("VUL TOKEN", "VUL") ERC20Permit("VUL TOKEN") {}

    /**
     * @notice Mint tokens.
     * @param _to: recipient address
     * @param _amount: amount of tokens
     *
     * @dev Callable by owner
     *
     */
    function mint(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(
            totalSupply() + _amount <= MAX_AMOUNT,
            "Can't mint more than max amount"
        );

        _mint(_to, _amount);
    }

    /**
     * @notice Burn tokens.
     * @param _amount: amount of tokens
     *
     * @dev Callable by owner
     *
     */
    function burn(
        uint256 _amount
    ) external onlyOwner {
        _burn(msg.sender, _amount);
    }

    /**
     * @notice Override hook _afterTokenTransfer
     * @param _from: Sender address
     * @param _to: Receiver address
     * @param _amount: amount of tokens
     *
     */
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        super._afterTokenTransfer(_from, _to, _amount);
    }

    /**
     * @notice Override hook _mint
     * @param _to: Receiver address
     * @param _amount: amount of tokens
     *
     */
    function _mint(
        address _to,
        uint256 _amount
    ) internal override {
        super._mint(_to, _amount);
    }

    /**
     * @notice Override hook _burn
     * @param _account: Burner address
     * @param _amount: amount of tokens
     *
     */
    function _burn(
        address _account,
        uint256 _amount
    ) internal override {
        super._burn(_account, _amount);
    }
}