//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract MultiSender is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using Address for address;

    receive() external payable {}

    /*SendBNBEquallyByValue 
        # First parameter is array of address.
        # This function will send msg.value to all adddress one by one.
        # Must check the total BNB balance must be equal to msg.value * length of address you 
            provided, before calling this function. If the balance is low this function will
            revert with an error and gas fees will be levied.
    */

    function SendBNBEquallyByValue(address payable[] calldata _address,uint256 _value) external payable onlyOwner returns (bool) {
        uint16 length = uint16(_address.length);
        uint value = _value*length;
        require(msg.value == value);

        for (uint16 i; i < length; ++i) {
            _address[i].transfer(_value);
        }

        return true;
    }


    /*SendTokensEquallyByValue 
        # First parameter is array of address.
        # Second parameter is value.
        # This function will send token value to all adddress one by one.
        # Must check the total token balance must be equal to value * length of address you 
            provided, before calling this function. If the token balance is low this function will
            revert with an error and gas fees will be levied.
    */

    function SendTokensEquallyByValue(
        address _tokenAddress,
        address[] calldata _address,
        uint256 _value
    ) external returns (bool) {
        uint16 length = uint16(_address.length);

        for (uint16 i; i < length; i++) {
            IERC20(_tokenAddress).transferFrom(msg.sender, _address[i], _value);
        }

        return true;
    }



    // Get the balance of all the BNB present in this smart contract

    function BNBBalance() external view returns (uint256 balance) {
        balance = address(this).balance;
        return balance;
    }

    // Get the balance of tokens present in this smart contract

    function TokensBalance(address _tokenAddress)
        external
        view
        returns (uint256 balance)
    {
        IERC20(_tokenAddress).balanceOf(address(this));
        return balance;
    }

    // Withdraw BNB from this smart contract

    function withdraw(address _address, uint256 _value) external onlyOwner {
        payable(_address).transfer(_value);
    }

    // Withdraw tokens from this smart contract

    function withdrawTokens(address _tokenAddress, uint256 _value)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).transfer(_msgSender(), _value);
    }
}