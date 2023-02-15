// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {IToken} from "../interfaces/IToken.sol";

abstract contract SupportToken is Ownable {
    mapping(address => bool) public blackListWallet;
    mapping(address => bool) public whiteListAddressBot;

    bool public enableWhiteListBot = false;
    bool public isEnable = true;
    address public investmentContract;
    address public airdropContract;

    event SetInvestmentContract(address newAddress, address oldAddress);
    event SetAirdropContract(address newAddress, address oldAddress);

    /**
	Set enable whitelist bot
	*/
    function setEnableWhiteListBot(bool _result) public onlyOwner {
        enableWhiteListBot = _result;
    }

    /**
	Set enable check Investment , Airdrop contract
	*/
    function setEnable(bool _result) public onlyOwner {
        isEnable = _result;
    }

    /**
	Set blacklist wallet can not transfer token
	*/
    function setBlackListWallet(
        address[] memory _address,
        bool result
    ) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            blackListWallet[_address[i]] = result;
        }
    }

    /**
	Set whitelist bot can transfer token
	*/
    function setWhiteListAddressBot(
        address[] memory _address,
        bool result
    ) public onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            whiteListAddressBot[_address[i]] = result;
        }
    }

    /**
	Clear unknown token
	*/
    function clearUnknownToken(address _tokenAddress) public onlyOwner {
        uint256 contractBalance = IERC20(_tokenAddress).balanceOf(
            address(this)
        );
        IERC20(_tokenAddress).transfer(address(msg.sender), contractBalance);
    }

    /**
	Check address is contract
	*/
    function isContract(address account) internal view returns (bool) {
        return Address.isContract(account);
    }

    /**
	set is investment contract
	*/
    function setInvestmentContract(
        address _investmentContract
    ) public onlyOwner {
        emit SetInvestmentContract(_investmentContract, investmentContract);
        investmentContract = _investmentContract;
    }

    /**
	set is airdrop contract
	*/
    function setAirdropContract(address _airdropContract) public onlyOwner {
        emit SetAirdropContract(_airdropContract, airdropContract);
        airdropContract = _airdropContract;
    }

    /**
     * @dev Withdraw Token to an address, revert if it fails.
     * @param recipient recipient of the transfer
     */
    function clearToken(
        address recipient,
        address token,
        uint256 amount
    ) public onlyOwner {
        IERC20(token).transfer(recipient, amount);
    }

    function checkTransfer(address account) public view returns (uint256) {
        uint256 amount = 0;
        if (investmentContract != address(0)) {
            amount += IToken(investmentContract).getITransferInvestment(
                account
            );
        }
        if (airdropContract != address(0)) {
            amount += IToken(airdropContract).getITransferAirdrop(account);
        }
        return amount;
    }
}