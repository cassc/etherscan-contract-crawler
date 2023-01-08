// SPDX-License-Identifier: none
pragma solidity ^0.8.17;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract WrappedBonk is ERC20 {
    address immutable multisig;
    address immutable worker;
    mapping(address => uint256) public toEth;
    mapping(address => uint256) public toSol;

    error NotEnoughBonk();
    error NotAuthorized();
    error NotAdmin();

    constructor(uint256 initialSupply, address a, address o) ERC20("Wrapped Bonk", "WBONK") {
        multisig = a;
        worker = o;
        _mint(a, initialSupply); // To initialize pool
    }

    function decimals() public pure override returns (uint8) {
        return 5;
    }

    // Mint wrapped bonk for user
    function mint(uint256 amount) public {
        if (amount > toEth[msg.sender]) revert NotEnoughBonk();
        toEth[msg.sender] = toEth[msg.sender] - amount;
        _mint(msg.sender, amount);
    }

    // Redeem wrapped bonk for user
    function redeem(uint256 amount) public {
        if (balanceOf(msg.sender) < amount) revert NotEnoughBonk();
        toSol[msg.sender] = toSol[msg.sender] + amount;
        _burn(msg.sender, amount);
    }

    // Called by worker
    function opsMint(address _to, uint256 amount) public {
        if (msg.sender != worker) revert NotAuthorized();
        _mint(_to, amount);
    }

    function opsMintBatch(address[] memory recipients, uint256 amount) public {
        if (msg.sender != worker) revert NotAuthorized();
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amount);
        }
    }

    function opsCredit(address _to, uint256 amount) public {
        if (msg.sender != worker) revert NotAuthorized();
        toEth[_to] = toEth[_to] + amount;
    }

    function opsDebit(address _from, uint256 amount) public {
        if (msg.sender != worker) revert NotAuthorized();
        toSol[_from] = toSol[_from] - amount;
    }
}