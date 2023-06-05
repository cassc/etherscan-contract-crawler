// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract PLSIOUToken is ERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => bool) public isWhitelisted;
    bool public isTradingEnabled;
    address public redeemContract;

    constructor(address owner) ERC20('Pulsechain IOU', 'PLSIOU') {
        isWhitelisted[owner] = true;
        _transferOwnership(owner);
        _mint(owner, 1000000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal view override {
        if (!isTradingEnabled) {
            require(isWhitelisted[from] || isWhitelisted[to], 'Trading disabled');
        }
    }

    function setTradingEnabled(bool value) external onlyOwner {
        isTradingEnabled = value;
    }

    function setWhitelisted(address addr, bool value) external onlyOwner {
        isWhitelisted[addr] = value;
    }

    function setRedeemContract(address addr) external onlyOwner {
        redeemContract = addr;
    }

    function redeemBurn(address addr, uint256 amount) external {
        require(msg.sender == redeemContract, 'only redeem contract');
        _burn(addr, amount);
    }
}