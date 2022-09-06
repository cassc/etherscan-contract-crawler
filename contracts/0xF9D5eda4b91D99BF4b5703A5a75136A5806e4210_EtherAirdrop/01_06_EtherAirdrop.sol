// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract EtherAirdrop is Ownable {

    event Funded(address sender, uint256 amount);
    event UnFunded(address caller, address recipient, uint256 amount);
    event Airdrop(uint256 amount, uint256 recipients);

    constructor() public {}

    function airdropEther(
        address[] memory _recipients,
        uint256 _numRecipients,
        uint256 _amountToAirdropPerRecipient
    ) public onlyOwner(){

        // Check to make sure that there's enough ether in the contract
        require(
            address(this).balance >= _numRecipients * _amountToAirdropPerRecipient,
            "EADC0: Insufficient contract balance"
        );

        // Try to airdrop ether to each address, given it's not a contract
        for (uint256 i = 0; i < _numRecipients; i++) {
            if (!Address.isContract(_recipients[i])) {
                payable(_recipients[i]).transfer(_amountToAirdropPerRecipient);
            }
            else {
                console.log("Aborted transferring funds to contract!");
            }
        }
        emit Airdrop(_amountToAirdropPerRecipient, _numRecipients);
    }

    /// @dev allows contract owner to remove funds from contract
    function transfer(address to, uint256 amount) public onlyOwner() {
        require(!Address.isContract(to), "Transferring funds to contract is forbidden!");
        payable(to).transfer(amount);
        emit UnFunded(msg.sender, to, amount);
    }

    receive() external payable {
        emit Funded(msg.sender, msg.value);
    }
}