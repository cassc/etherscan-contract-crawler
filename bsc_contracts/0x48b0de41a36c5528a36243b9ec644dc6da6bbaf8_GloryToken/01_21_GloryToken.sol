// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";


contract GloryToken is ERC20PresetMinterPauserUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public constant  MAX_SUPPLY = 150000000 * 10 ** 18;

    uint256 public constant TIME_MINT_TO_TEAM = 1707238111;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 public constant OPERATOR_TEAM = keccak256("OPERATOR_TEAM");


    function initialize()
    public
    initializer
    {
        __ERC20PresetMinterPauser_init("Glory", "GLR");
    }

    function mint(address to, uint256 amount) public virtual override {
        require(
            hasRole(OPERATOR_ROLE, _msgSender()),
            "must have operator role"
        );
        require(super.totalSupply() + amount + (15000000 * 10 ** 18) < MAX_SUPPLY, "Total supply over max supply");
        super.mint(to, amount);
    }

    function mintToTeam(address to) public {
        require(
            hasRole(OPERATOR_TEAM, _msgSender()),
            "must have operator role"
        );
        require(block.timestamp >= TIME_MINT_TO_TEAM, "Time mint invalid");

        super.mint(to, 15000000 * 10 ** 18);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool){
        uint256 balanceOf = super.balanceOf(from);
        require(amount <= balanceOf, "Balance not enough");
        uint256 amountTransfer = amount.mul(99).div(100);
        uint256 amountFee = amount.sub(amountTransfer);
        super.transfer(address(this), amountFee);
        return super.transferFrom(from, to, amountTransfer);
    }


}