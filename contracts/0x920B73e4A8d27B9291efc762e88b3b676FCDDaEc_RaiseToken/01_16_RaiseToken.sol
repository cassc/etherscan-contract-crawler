// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract RaiseToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    uint256 private immutable _cap = 100000000 * 10**18;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {
        _transferOwnership(msg.sender);
        _mint(msg.sender, _cap);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * @param _account Addess of the account whose tokens will be burned.
     * @param _amount Amount of tokens to be burned.
     */
    function burn(address _account, uint256 _amount) external onlyOwner {
        require(_amount != 0, "You can not burn zero tokens.");
        _burn(_account, _amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}