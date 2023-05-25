// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.8;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./Manager.sol";
import "./IONGv1.sol";

contract SoMeeToken is ERC20, ERC20Capped, ERC20Burnable, Manager {
    uint256 public constant HARD_CAP = 150_000_000 * 1e18;
    address public immutable oNGv1;

    constructor(address _oNGv1)
        public
        ERC20("SoMee.Social", "SOMEE")
        ERC20Capped(HARD_CAP)
        Manager()
    {
        oNGv1 = _oNGv1;
    }

    function transfer(address to, uint256 value)
        public
        override(ERC20)
        whenNotPaused()
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override(ERC20) whenNotPaused() returns (bool) {
        super.transferFrom(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value)
        public
        override(ERC20)
        whenNotPaused()
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function burn(uint256 value)
        public
        override(ERC20Burnable)
        whenNotPaused()
    {
        super.burn(value);
    }

    function burnFrom(address account, uint256 value)
        public
        override(ERC20Burnable)
        whenNotPaused()
    {
        super.burnFrom(account, value);
    }

    function mint(address to, uint256 value)
        external
        whenNotPaused()
        onlyOperator()
        returns (bool)
    {
        _mint(to, value);
        return true;
    }

    function migrateToken(uint256 value)
        external
        whenNotPaused()
        returns (bool)
    {
        IONGv1(oNGv1).transferFrom(msg.sender, address(this), value);
        IONGv1(oNGv1).burn(value);
        _mint(msg.sender, value);
        return true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Capped) {
        ERC20Capped._beforeTokenTransfer(from, to, amount);
    }
}