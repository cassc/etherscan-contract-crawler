// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/math/Math.sol';
import '../core/SafeOwnable.sol';

interface IMintable {
    function mintFor(address _to, uint256 _amount) external;
}

contract BabyVault is SafeOwnable {
    using SafeERC20 for IERC20;

    event MinterChanged(address minter, bool available);

    uint256 public constant maxSupply = 10 ** 27;
    IERC20 public immutable babyToken;

    mapping(address => uint) public minters;

    constructor(IERC20 _babyToken, address _owner) {
        babyToken = _babyToken;
        if (_owner != address(0)) {
            _transferOwnership(_owner);
        }
    }

    function addMinter(address _minter, uint _amount) external onlyOwner {
        require(_amount != 0 && _minter != address(0) && minters[_minter] == 0, "illegal minter address");
        minters[_minter] = _amount;
        emit MinterChanged(_minter, true);
    }

    function setMinter(address _minter, uint _amount) external onlyOwner {
        require(minters[_minter] > 0 && _amount != 0, "illegal minter");
        minters[_minter] = _amount;
    }

    function delMinter(address _minter) external onlyOwner {
        require(minters[_minter] > 0, "illegal minter");
        delete minters[_minter];
        emit MinterChanged(_minter, false);
    }

    modifier onlyMinter(uint _amount) {
        require(minters[msg.sender] > _amount, "only minter can do this");
        _;
        minters[msg.sender] -= _amount;
    }

    function mint(address _to, uint _amount) external onlyMinter(_amount) returns (uint) {
        uint remained = _amount;
        //first from balance
        if (remained != 0) {
            uint currentBalance = babyToken.balanceOf(address(this)); 
            uint amount = Math.min(currentBalance, remained);
            if (amount > 0) {
                babyToken.safeTransfer(_to, amount);
                //sub is safe
                remained -= amount;
            }
        }
        //then mint
        if (remained != 0) {
            uint amount = Math.min(maxSupply - babyToken.totalSupply(), remained);
            if (amount > 0) {
                IMintable(address(babyToken)).mintFor(_to, amount);
                remained -= amount;
            }
        }
        return _amount - remained;
    }

    function mintOnlyFromBalance(address _to, uint _amount) external onlyMinter(_amount) returns (uint) {
        uint remained = _amount;
        //first from balance
        if (remained != 0) {
            uint currentBalance = babyToken.balanceOf(address(this)); 
            uint amount = Math.min(currentBalance, remained);
            if (amount > 0) {
                babyToken.safeTransfer(_to, amount);
                //sub is safe
                remained -= amount;
            }
        }
        return _amount - remained;
    }

    function mintOnlyFromToken(address _to, uint _amount) external onlyMinter(_amount) returns (uint) {
        uint remained = _amount;
        if (remained != 0) {
            uint amount = Math.min(maxSupply - babyToken.totalSupply(), remained);
            if (amount > 0) {
                IMintable(address(babyToken)).mintFor(_to, amount);
                remained -= amount;
            }
        }
        return _amount - remained;
    }

    function recoverWrongToken(IERC20 _token, uint _amount, address _receiver) external onlyOwner {
        require(_receiver != address(0), "illegal receiver");
        _token.safeTransfer(_receiver, _amount); 
    }

    function execute(address _to, bytes memory _data) external onlyOwner {
        (bool success, ) = _to.call(_data);
        require(success, "failed");
    }

}