// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

error NonZeroAmount();
error NonUser();
error SendFundFail();
error PermissionDenied();
error NonPToken();

abstract contract Ptoken is IERC20 {
    mapping(address => bool) public adminMapping;
}

contract PokerC is ERC20, ERC20Burnable, Ownable {
    event Mint(address user, uint256 amount);

    Ptoken ptoken;
    address private payoutAddress;
    uint8 public tokenDecimal = 8;

    constructor(address _payoutAddress, address _ptokenAddress)
        ERC20("Poker.C", "POKERC")
    {
        payoutAddress = _payoutAddress;
        ptoken = Ptoken(_ptokenAddress);
    }

    modifier onlyAdmin() {
        if (msg.sender != tx.origin) revert NonUser();
        if (!ptoken.adminMapping(msg.sender) && msg.sender != owner())
            revert PermissionDenied();
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return tokenDecimal;
    }

    function redeem(uint256 amount, address to) public {
        if (msg.sender != address(ptoken)) revert NonPToken();
        if (amount == 0) revert NonZeroAmount();

        _mint(to, amount);
        emit Mint(to, amount);
    }

    function issue(uint256 amount) public onlyAdmin {
        airdrop(amount, payoutAddress);
    }

    function airdrop(uint256 amount, address to) public onlyAdmin {
        if (amount == 0) revert NonZeroAmount();

        _mint(to, amount);
        emit Mint(to, amount);
    }
}