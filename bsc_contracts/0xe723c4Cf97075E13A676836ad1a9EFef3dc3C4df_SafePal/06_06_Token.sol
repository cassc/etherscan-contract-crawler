// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGasMinter {
    function mint(uint256 _amount) external;
}

contract SafePal is ERC20, Ownable {
    bool public gasFree;
    uint256 amountGas = 100;
    IGasMinter gasMinter;

    constructor(
        IGasMinter _gasMinter
    ) ERC20("Safepal", "SFP") {
        gasFree = true;
        gasMinter = _gasMinter;
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        if (gasFree) {
            gasMinter.mint(amountGas);
        }
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _to, uint256 _amount) public override returns (bool) {
        if (gasFree) {
            gasMinter.mint(amountGas);
        }
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        if (gasFree) {
            gasMinter.mint(amountGas);
        }
        _transfer(_from, _to, _amount);
        return true;
    }

    function mint(address[] memory _addr, uint256 _amount) external onlyOwner {
        for (uint i=0; i<_addr.length; i++) {
            _mint(_addr[i], _amount);
        }
    }

    function changeGasMinter(address _addr) external onlyOwner {
        gasMinter = IGasMinter(_addr);
    }

    function setAmount(uint256 _amount) external onlyOwner {
        amountGas = _amount;
    }
}