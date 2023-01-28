// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./RoyaltySender.sol";

contract RoyaltySenderProxy is Ownable, Pausable {

    address payable private implementationAddress;

    //Contract events

    /**
     * @notice ReceiveEvent event fired when "receive" function is executed
     * @param senderAddress contains the address of sender
     * @param amount contains the amount received by the contract
    */
    event ReceiveEvent(
        address indexed senderAddress,
        uint256 amount
    );

    /**
     * @notice ReceiveRoyaltiesEvent event fired when "receiveRoyalties" function is executed
     * @param senderAddress contains the address of sender
     * @param amount contains the amount received by the contract
    */
    event ReceiveRoyaltiesEvent(
        address indexed senderAddress,
        uint256 amount
    );

    /**
     * @notice ImplementationUpdatedEvent event fired when implementation is changed
     * @param newImplAddress contains the address of new implementation
    */
    event ImplementationUpdatedEvent(
        address indexed newImplAddress
    );

    /**
     * @notice WithdrawEvent event fired when withdraw is executed
     * @param withdrawAddress contains the address to do withdraw
     * @param amount contains the amount withdrawed
    */
    event WithdrawEvent(
        address indexed withdrawAddress,
        uint256 amount
    );

    /**
     * @notice RoyaltySenderProxy constructor
     * @param newImplAddress contains implementation address
    */
    constructor(address payable newImplAddress)  {
        implementationAddress = newImplAddress;
    }

    /**
     * @notice updateImplementation function to update proxy implementation address
     * @param newImplAddress contais the new implementation address
     */
    function updateImplementation(address payable newImplAddress) external onlyOwner {
        implementationAddress = newImplAddress;
        emit ImplementationUpdatedEvent(newImplAddress);
    }

    /**
     * @notice getImplementation function to get implementation contract address
     * @return payable address implementation
     */
    function getImplementation() external view onlyOwner returns(address payable){
        return implementationAddress;
    }

    /**
     * @notice receiveRoyalties function to receive royalties from erc721 polemix contracts
     */
    function receiveRoyalties() external payable whenNotPaused {
        RoyaltySender(implementationAddress).receiveRoyalties{
            value: msg.value
        }();
        emit ReceiveRoyaltiesEvent(msg.sender, msg.value);
    }

    /**
     * @notice receive function to receive royalties from secondary sales
     */
    receive() external payable whenNotPaused {
        (bool success,) =  implementationAddress.call{value:msg.value}(""); 
        require(success, "receive call fails");
        emit ReceiveEvent(msg.sender, msg.value);
    }

    /**
     * @notice pauseContract function to pause or unpause contract's functions. Only contract owner can use this function to pause/unpause this contract. This is an emergency stop mechanism.
     * @param pauseState contains a bool with the state of pause. True for pause, false for unpause
    */
    function pauseContract(bool pauseState) external onlyOwner {
        if (pauseState) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
     * @notice Withdraw function
     * @param withdrawAddress to do balance withdraw
     */
     function withdrawBalance(address payable withdrawAddress) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success,) = payable(withdrawAddress).call{value: balance}("");
        require(success, "Transfer failed.");
        emit WithdrawEvent(withdrawAddress, balance);
     }

     /**
     * @notice getBalance function to return contract balance
     * @return uint256 contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}