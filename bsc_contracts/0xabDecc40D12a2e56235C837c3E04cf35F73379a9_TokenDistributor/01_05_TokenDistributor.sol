pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RecoverableFunds.sol";


contract TokenDistributor is Ownable, RecoverableFunds {

    IERC20 public token;

    function setToken(address newTokenAddress) external onlyOwner {
        token = IERC20(newTokenAddress);
    }

    function distribute(address[] memory receivers, uint[] memory balances) external onlyOwner {
        require(receivers.length == balances.length, "TokenDistributor: Invalid array length");
        for (uint i = 0; i < receivers.length; i++) {
            token.transfer(receivers[i], balances[i]);
        }
    }

    function retrieveTokens(address recipient, address tokenAddress) external onlyOwner() {
        return _retrieveTokens(recipient, tokenAddress);
    }

    function retriveETH(address payable recipient) external onlyOwner() {
        return _retrieveETH(recipient);
    }

}