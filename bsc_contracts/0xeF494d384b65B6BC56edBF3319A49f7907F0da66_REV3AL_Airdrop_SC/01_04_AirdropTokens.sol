// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.10;

contract REV3AL_Airdrop_SC is Ownable {

    IERC20 public tokenAddress;

     // Events
    event AirdropTokens(
        address _who,
        uint256 _amount
    );

    constructor(IERC20 _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    // Airdrop tokens
    function airdopTokens(address[] memory _recipients, uint256[] memory _amounts) external onlyOwner() {
        // Fetch variables
        uint256 _listSizeAddress = _recipients.length;
        uint256 _listSizeAmounts = _amounts.length;

        require(_listSizeAddress == _listSizeAmounts, "Something is wrong! Check the lists again!");
       
        for (uint i = 0; i < _listSizeAddress; i++) {
            address _who = _recipients[i];
            uint256 _amount = _amounts[i];

            tokenAddress.transfer(_who, _amount);
        }
    }

    // What we do if somebody send blockchain's native tokens to the smart contract
    receive() external payable {
        // @Note
        // Calling a revert statement implies an exception is thrown, 
        // the unused gas is returned and the state reverts to its original state.
            revert("You are not allowed to do that!");
        }

    // Withdraw wrong tokens
    function withdrawWrongTokens(address _whatToken) external onlyOwner() {

        IERC20 _tokenToWitdhraw = IERC20(_whatToken);

        // Fetch the balance of the smart contract
        uint256 _balanceOfTheSmartContract = _tokenToWitdhraw.balanceOf(address(this));

        // Transfer the tokens to the owner of the smart contract
        _tokenToWitdhraw.transfer(owner(), _balanceOfTheSmartContract);
    }
}