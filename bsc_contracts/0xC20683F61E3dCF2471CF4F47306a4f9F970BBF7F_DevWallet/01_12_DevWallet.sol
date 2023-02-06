// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RupeeCashAdmin.sol";

contract DevWallet is Ownable {
    
    IERC20 public BUSD;

    address[] public dev_wallets;
    uint[] public percents;

    uint public dev_count;

    constructor(IERC20 _BUSD, RupeeCashAdmin admin) {
        BUSD = _BUSD;
        admin.set_auto_exchange(true);
        admin.set_auto_settlement(true);
    }

    function set_dev_wallets(address[] memory _dev_wallets, uint[] memory _percents) external onlyOwner {
        uint current_wallet_count = dev_wallets.length;
        uint new_wallet_count = _dev_wallets.length;
        uint i;
        uint total_percent;
        for(i = 0; i < new_wallet_count; i ++) {
            total_percent += _percents[i];   
        }
        require(total_percent == 1e4, "Percent sum should be 100%");
        for(i = 0; i < _min(current_wallet_count, new_wallet_count); i++) {
            dev_wallets[i] = _dev_wallets[i];
            percents[i] = _percents[i];
        }
        for(; i < new_wallet_count; i++) {
            dev_wallets.push(_dev_wallets[i]);
            percents.push(_percents[i]);
        }
        dev_count = new_wallet_count;
    }

    function withdraw() external {
        uint balance = BUSD.balanceOf(address(this));
        uint balance_for_dev;
        uint i;
        for(i = 0; i < dev_count; i++) {
            balance_for_dev = percents[i] * balance / 1e4;
            BUSD.transfer(dev_wallets[i], balance_for_dev);
        }
    }

}