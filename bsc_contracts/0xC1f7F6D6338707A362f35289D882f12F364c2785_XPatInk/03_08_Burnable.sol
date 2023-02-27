//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Libraries.sol";
import "./Interfaces.sol";
import "./BaseErc20.sol";

abstract contract Burnable is BaseErc20, IBurnable {
    
    mapping (address => bool) public ableToBurn;

    modifier onlyBurner() {
        require(ableToBurn[msg.sender], "no burn permissions");
        _;
    }

    // Overrides
    
    function configure(address _owner) internal virtual override {
        ableToBurn[_owner] = true;
        super.configure(_owner);
    }
    
    
    // Admin methods

    function setAbleToBurn(address who, bool enabled) external onlyOwner {
        ableToBurn[who] = enabled;
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param value The amount that will be burnt.
     */
    function burn(uint256 value) external override onlyBurner {
        _burn(msg.sender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function burnFrom(address account, uint256 value) external override onlyBurner {
        _allowed[account][msg.sender] = _allowed[account][msg.sender] - value;
        _burn(account, value);
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
    }


    // Private methods

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply - value;
        _balances[account] = _balances[account] - value;
        emit Transfer(account, address(0), value);
    }
}