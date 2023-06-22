// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol';
import '../core/SafeOwnable.sol';

contract PuffGo is ERC20Capped, SafeOwnable {

    event MinterChanged(address indexed minter, uint maxAmount);

    uint256 public constant MAX_SUPPLY = 10 * 10 ** 8 * 10 ** 18;
    mapping(address => uint) public minters;

    constructor() ERC20Capped(MAX_SUPPLY) ERC20("Puffverse Governance Token", "PGT") {
    }

    function addMinter(address _minter, uint _maxAmount) public onlyOwner {
        require(_minter != address(0), "illegal minter");
        require(minters[_minter] == 0, "already minter");
        minters[_minter] = _maxAmount;
        emit MinterChanged(_minter, _maxAmount);
    }

    function delMinter(address _minter) public onlyOwner {
        require(_minter != address(0), "illegal minter");
        require(minters[_minter] > 0, "not minter");
        delete minters[_minter];
        emit MinterChanged(_minter, 0);
    }

    modifier onlyMinter(uint _amount) {
        require(minters[msg.sender] >= _amount, "caller is not minter or not enough");
        _;
    }

    function mint(address to, uint256 amount) external onlyMinter(amount) returns (uint) {
        if (amount > MAX_SUPPLY - totalSupply()) {
            return 0;
        }
        if (minters[msg.sender] < amount) {
            amount = minters[msg.sender];
        }
        minters[msg.sender] = minters[msg.sender] - amount;
        _mint(to, amount);
        return amount; 
    }
}