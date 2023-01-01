pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WalletSizeLimit is Ownable {

    error WalletLimitReached();

    uint public walletLimit;
    mapping(address => bool) public isExcludedFromWalletSizeLimit;

    function setWalletLimit(uint tokenAmount) public onlyOwner {
        walletLimit = tokenAmount;
    }

    function setExcludedFromWalletSizeLimit(address addr, bool excluded) public onlyOwner {
        isExcludedFromWalletSizeLimit[addr] = excluded;
    }

    function walletSizeCheck(address recipient, uint balance) internal view {
        if(balance > walletLimit){
            if(!isExcludedFromWalletSizeLimit[recipient]){
                revert WalletLimitReached();
            }
        }
    }
}