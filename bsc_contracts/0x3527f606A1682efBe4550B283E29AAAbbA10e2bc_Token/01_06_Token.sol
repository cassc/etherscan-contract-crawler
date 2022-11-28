// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    uint256 public constant BURN_FEE = 5;
    address public constant BURN_ADDR = 0x000000000000000000000000000000000000dEaD;
    mapping (address => bool) internal isExcludedFromFee;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _wallet
    ) ERC20 (_name, _symbol) {
        isExcludedFromFee[_msgSender()] = true;

        _mint(_wallet, _totalSupply * (10 ** decimals()));
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal override {
        
        bool _takeFee;
        if(!isExcludedFromFee[_sender] && !isExcludedFromFee[_recipient]) 
            _takeFee = true;

        uint256 _burnAmt = 0;
        if(_takeFee) {
            _burnAmt = _amount * BURN_FEE / 100;
            super._transfer(_sender, BURN_ADDR, _burnAmt);
        }

        super._transfer(_sender, _recipient, _amount - _burnAmt);
    }

    function setExcludedFromFee(address _account, bool _excluded) external onlyOwner {
        require(_account != address(0), "Empty accounts");

        isExcludedFromFee[_account] = _excluded;
        
        emit SetExcludedFromFee(_account, _excluded);
    }

    event SetExcludedFromFee(address account, bool isExcluded);
}