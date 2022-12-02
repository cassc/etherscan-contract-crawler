// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract RubicTokenGOV is ERC20Burnable, ERC20Capped, Ownable{
    using SafeERC20 for IERC20;

    event SweepTokens(address token, uint256 amount, address recipient);

    constructor(
        address[] memory _minters,
        uint256[] memory _amounts
    ) ERC20("GOVERNANCE RBC", "gRBC") ERC20Capped(1_000_000_000 ether) {
        require(_minters.length == _amounts.length, 'Diff length');

        uint256 length = _minters.length;
        for (uint i; i < length; i++) {
            _mint(_minters[i], _amounts[i]);
        }
    }

    function sendToken(
        address _token,
        uint256 _amount,
        address _receiver
    ) internal virtual {
        if (_token == address(0)) {
            Address.sendValue(
                payable(_receiver),
                _amount
            );
        } else {
            IERC20(_token).safeTransfer(
                _receiver,
                _amount
            );
        }
    }

    /**
     * @dev A function to rescue stuck tokens from the contract
     * @param _token The token to sweep
     * @param _amount The amount of tokens
     * @param _recipient The recipient
     */
    function sweepTokens(
        address _token,
        uint256 _amount,
        address _recipient
    ) external onlyOwner {
        sendToken(_token, _amount, _recipient);

        emit SweepTokens(_token, _amount, _recipient);
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}