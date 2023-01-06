// SPDX-License-Identifier: none
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract WrappedBonk is ERC20 {
    address immutable admin;
    mapping(address => uint256) public toEth;
    mapping(address => uint256) public toSol;

    error NotEnoughBonk();
    error NotAdmin();

    //supply = 1000000000000000000
    constructor(uint256 initialSupply, address a) ERC20("Wrapped Bonk", "WBONK") {
        admin = a;
        _mint(a, initialSupply);
    }

    // Mint wrapped bonk for user
    function mint(uint256 amount) public {
        if (amount > toEth[msg.sender]) revert NotEnoughBonk();
        toEth[msg.sender] = toEth[msg.sender] - amount;
        _transfer(address(this), msg.sender, amount);
    }

    // Redeem wrapped bonk for user
    function redeem(uint256 amount) public {
        if (balanceOf(msg.sender) < amount) revert NotEnoughBonk();
        toSol[msg.sender] = toSol[msg.sender] + amount;
        _transfer(msg.sender, address(this), amount);
    }

    function decimals() public pure override returns (uint8) {
        return 5;
    }

    // Admin mint as more bonk bridging to eth
    function adminMint(address _to, uint256 amount) public {
        if (msg.sender != admin) revert NotAdmin();
        _mint(_to, amount);
    }

    function adimCredit(address _to, uint256 amount) public {
        if (msg.sender != admin) revert NotAdmin();
        toEth[_to] = toEth[_to] + amount;
    }

    function adimDebit(address _from, uint256 amount) public {
        if (msg.sender != admin) revert NotAdmin();
        toSol[_from] = toSol[_from] - amount;
    }

    // Burn as bonk bridging to sol
    function burn(uint256 amount) public {
        if (amount > balanceOf(msg.sender)) revert NotEnoughBonk();
        _burn(msg.sender, amount);
    }
}