// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./ITokenDelegate.sol";
import "./AntiBot.sol";

/**
 * @title Token
 * @dev BEP20 compatible token.
 */
contract Token is Ownable, ERC20Burnable, AntiBot {

    uint8 private _decimals;
    ITokenDelegate public delegate;
    event DelegateAddressChanged(address indexed addr);

    /**
     * @dev Mints all tokens to deployer
     * @param amount Initial supply
     * @param name Token name.
     * @param symbol Token symbol.
     */
    constructor(uint256 amount, string memory name, string memory symbol, uint8 dec) ERC20(name, symbol) {
        _decimals = dec;
        _mint(_msgSender(), amount);
    }

    function setDelegateAddress(ITokenDelegate _delegate) public onlyOwner {
        require(address(_delegate) != address(0), 'Token: delegate address needs to be different than zero!');
        delegate = _delegate;
        emit DelegateAddressChanged(address(delegate));
    }

    /**
     * @dev Returns the address of the current owner.
     *
     * IMPORTANT: This method is required to be able to transfer tokens directly between their Binance Chain
     * and Binance Smart Chain. More on this issue can be found in:
     * https://github.com/binance-chain/BEPs/blob/master/BEP20.md#5116-getowner
     */
    function getOwner() external view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function _transfer(address sender, address recipient, uint256 amount)
    internal virtual override transferThrottler(sender, recipient, amount)
    {
        super._transfer(sender, recipient, amount);
    }

    /**
     * @dev Inform external contract about tokens being moved
     */
    function _afterTokenTransfer(address from, address to, uint256 amount)
    internal virtual override
    {
        super._afterTokenTransfer(from, to, amount);
        _moveSpendingPower(from, to, amount);
    }

    /**
     * @dev Inform external contract about tokens being moved
     */
    function _moveSpendingPower(address src, address dst, uint256 amount) internal {
        if (src != dst && amount > 0 && address(delegate) != address(0)) {
            delegate.moveSpendingPower(src, dst, amount);
        }
    }
}