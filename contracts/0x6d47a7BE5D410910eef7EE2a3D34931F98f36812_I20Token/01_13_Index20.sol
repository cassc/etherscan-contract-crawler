// SPDX-License-Identifier: MIT

// Developed By SS

pragma solidity ^0.8.0;

import "./VotingToken.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract I20Token is VotingToken, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Gets the available balance of a specified address.
     * @param _owner is the address to query the available balance of. 
     * @return uint256 representing the amount owned by the address.
     */

    function availableBalance(address _owner) public view returns (uint256) {
        return _balances[_owner]; 
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
        require(_balances[from] >= amount , "I20: not avaiable balance");
    }

    /**
     * @dev Sets the values for {name}, {symbol}, {totalsupply} and {deciamls}.
     *
     * {name}, {symbol} and {decimals} are immutable: they can only be set once during
     * construction. {totalsupply} may be changed by using mint and burn functions. 
     */

    constructor(address account) {
        _name = "Index20";
        _symbol = "I20";
        _decimals = 18;
        _transferOwnership(account);
        _mint(_msgSender(), 50000000000000000000000000);

    }

   function mint(address account, uint256 amount) public onlyAdminOrOwner returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    

    function transferAnyBEP20(address _tokenAddress, address _to, uint256 _amount) public onlyOwner returns (bool) {
        IBEP20(_tokenAddress).transfer(_to, _amount);
        return true;
    }
}