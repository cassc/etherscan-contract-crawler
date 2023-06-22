// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract ProxyWithdrawal is Ownable {

    using Address for address;

    /// Transfer event
    /// @param _to address  Destination address
    /// @param _amount uint  Transfer amount
    /// @param _tokenAddress address  Transfer token address (address(0) - native coins)
    event TransferEvent(address _to, uint _amount, address _tokenAddress);

    /// Return coni balance
    /// @return uint
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    /// Return token balance
    /// @return uint
    function getTokenBalance(IERC20 _token) public view returns(uint) {
        return _token.balanceOf(address(this));
    }

    /// Transfer coins (only for owner)
    /// @param _to address  Destination address
    /// @param _amount uint  Transfer amount
    function transferCoins(address _to, uint _amount) external onlyOwner {
        require(!_to.isContract(), "Withdrawal: target address is contract");
        require(getBalance() >= _amount, "Withdrawal: balance not enough");
        (bool successFee, ) = _to.call{value: _amount}("");
        require(successFee, "Withdrawal: transfer failed");
        emit TransferEvent(_to, _amount, address(0));
    }

    /// Transfer tokens (only for owner)
    /// @param _token IERC20  Token address
    /// @param _to address  Destination address
    /// @param _amount uint  Transfer amount
    function transferTokens(IERC20 _token, address _to, uint _amount) external onlyOwner {
        require(getTokenBalance(_token) >= _amount, "Withdrawal: not enough tokens");
        require(_token.transfer(_to, _amount), "Withdrawal: transfer request failed");
        emit TransferEvent(_to, _amount, address(_token));
    }
}