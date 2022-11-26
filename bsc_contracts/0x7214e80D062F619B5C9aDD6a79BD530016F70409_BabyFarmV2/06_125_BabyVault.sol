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
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event MinterChanged(address minter, bool available);

    uint256 public constant maxSupply = 10 ** 27;
    IERC20 public immutable babyToken;

    mapping(address => bool) public minters;
    address public vault;

    constructor(IERC20 _babyToken) {
        babyToken = _babyToken;
    }

    function addMinter(address _minter) external onlyOwner {
        require(_minter != address(0) && !minters[_minter], "illegal minter");
        minters[_minter] = true;
        emit MinterChanged(_minter, true);
    }

    function delMinter(address _minter) external onlyOwner {
        require(minters[_minter], "illegal minter");
        delete minters[_minter];
        emit MinterChanged(_minter, false);
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "only minter can do this");
        _;
    }

    function mint(address _to, uint _amount) external onlyMinter returns (uint) {
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

    function recoverWrongToken(IERC20 _token, uint _amount, address _receiver) external onlyOwner {
        require(_receiver != address(0), "illegal receiver");
        _token.safeTransfer(_receiver, _amount); 
    }

    function execute(address _to, bytes memory _data) external onlyOwner {
        _to.call(_data);
    }

}