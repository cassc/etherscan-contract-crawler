// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WFIST is ERC20, Ownable {
    uint256 public buyFeePercent;
    uint256 public sellFeePercent;
    address public deadwallet = 0x000000000000000000000000000000000000dEaD;
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public _isWhitelisted;

    constructor() ERC20("WFIST Token", "WFIST") {
        _mint(msg.sender, 200000000 * 1e18); 
        _isWhitelisted[msg.sender]=true;
        buyFeePercent = 0;
        sellFeePercent = 0;
    }

    function _transfer(address from,address to,uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "black address");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        bool contractF = isContract(from);
        bool contractT = isContract(to);

        bool takeFee = true;
        if(_isWhitelisted[from] || _isWhitelisted[to]){
            takeFee=false;
        }

        if(takeFee){
            uint256 fees;
            if (contractF) {
                fees = (amount*buyFeePercent)/100;
            }
            if (contractT) {
                fees = (amount*sellFeePercent)/100;
            }
            if(fees>0) super._transfer(from,deadwallet,fees);
            amount=amount-fees;
        }
        super._transfer(from, to, amount);
    }

    function setBuyFeePercent(uint256 _buyFeePercent) external onlyOwner {
        require(_buyFeePercent <= 100, "Fee is too high");
        buyFeePercent = _buyFeePercent;
    }

    function setSellFeePercent(uint256 _sellFeePercent) external onlyOwner {
        require(_sellFeePercent <= 100, "Fee is too high");
        sellFeePercent = _sellFeePercent;
    }

    function setWhitelist(address[] calldata addresses, bool flag) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _isWhitelisted[addresses[i]] = flag;
        }
    }

    function setBlacklist(address[] calldata accounts, bool flag) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isBlacklisted[accounts[i]] = flag;
        }
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size; assembly {
            size := extcodesize(account)
        } return size > 0;
    }

    
}