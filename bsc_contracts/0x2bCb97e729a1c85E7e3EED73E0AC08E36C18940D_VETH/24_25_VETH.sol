// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./VPool.sol";
import "../interfaces/token/IToken.sol";

//solhint-disable no-empty-blocks
contract VETH is VPool {
    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) VPool(_name, _symbol, _token) {}

    /// @dev Handle incoming ETH to the contract address.
    receive() external payable {
        if (msg.sender != address(token)) {
            deposit();
        }
    }

    /// @dev Burns tokens/shares and returns the ETH value, after fee, of those.
    function withdrawETH(uint256 _shares) external whenNotShutdown nonReentrant {
        withdrawInETH = true;
        _updateRewards(_msgSender());
        _withdraw(_shares);
        withdrawInETH = false;
    }

    /// @dev Burns tokens/shares and returns the ETH value and claim rewards if any
    function withdrawETHAndClaim(uint256 _shares) external whenNotShutdown nonReentrant {
        withdrawInETH = true;
        _withdrawAndClaim(_shares);
        withdrawInETH = false;
    }

    /**
     * @dev After burning hook, it will be called during withdrawal process.
     * It will withdraw collateral from strategy and transfer it to user.
     */
    function _afterBurning(uint256 _amount) internal override returns (uint256) {
        if (withdrawInETH) {
            TokenLike(address(token)).withdraw(_amount);
            Address.sendValue(payable(_msgSender()), _amount);
        } else {
            super._afterBurning(_amount);
        }
        return _amount;
    }

    /**
     * @dev Receives ETH and grants new tokens/shares to the sender depending
     * on the value of pool's share.
     */
    function deposit() public payable whenNotPaused nonReentrant {
        _updateRewards(_msgSender());
        _depositETH();
    }

    /// @dev Deposit ETH and claim rewards if any
    function depositAndClaim() external payable whenNotPaused nonReentrant {
        _claimRewards(_msgSender());
        _depositETH();
    }

    function _depositETH() internal {
        uint256 _shares = calculateMintage(msg.value);
        // Wraps ETH in WETH
        TokenLike(address(token)).deposit{value: msg.value}();
        _mint(_msgSender(), _shares);
        emit Deposit(_msgSender(), _shares, msg.value);
    }
}