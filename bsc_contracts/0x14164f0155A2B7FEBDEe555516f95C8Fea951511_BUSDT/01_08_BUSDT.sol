// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BUSDT is ERC20, ERC20Burnable, Pausable, Ownable {
    // this execute only on deployment i.e it runs only once.
    constructor() ERC20("Binance-Peg BUSD-T Stablecoin", "USDT") {
        // minting 8000 to msg.sender (BUSDT deployer)
        _mint(msg.sender, 8000 * 10**decimals());
    }

    /// @dev
    /// mint(address, uint256) function mints new tokens to specific
    /// address `to`
    /// NB: Only callable by BUSDT deployer (onlyOwner)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// @dev
    /// pause() function pauses token transfer on BUSDT
    /// NB: Only callable by BUSDT deployer (onlyOwner)
    function pause() public onlyOwner {
        _pause();
    }

    /// @dev
    /// unpause() function un-pauses token transfer on BUSDT
    /// NB: Only callable by BUSDT deployer (onlyOwner)
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @dev
    /// _beforeTokenTransfer() function override method in `ERC20` i.e
    /// super._beforeTokenTransfer(from, to, amount) making transfer of
    /// BUSDT token only possible `whenNotPaused`.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}