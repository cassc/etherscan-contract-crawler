// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error NotApprovedMinter();
error NotApprovedBurner();

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {iIngotToken} from "./interfaces/IIngotToken.sol";

/// @title Ignot ERC20 Token
/// @author 0xSimon_
/// @notice Ignot ERC20 provides a basic ERC20 with functions to approve and disapprove minters and burners based on the Titanforge ecosystem
contract IngotToken is ERC20, ERC20Burnable, iIngotToken, Ownable {
    mapping(address => bool) private approvedMinter;
    mapping(address => bool) private approvedBurner;
    mapping(address =>bool) private approvedTransferrer;
    mapping(address => bool) private approvedReceiver;
    bool public areAllTokenTransferrsAllowed;

    constructor() ERC20("Ingot", "IGN") {
        /// @notice approve contract creator to mint upon construction
        approveMinter(_msgSender());
        approvedReceiver[msg.sender] = true;
        // approvedTransferrer[diamondContract] = true;
        // approvedReceiver[diamondContract] = true;

    }

    /*
        ||<><>||
    *     Mint
        ||<><>||

    */
    function mint(address to, uint256 amount) public {
        if (!approvedMinter[_msgSender()]) revert NotApprovedMinter();
        _mint(to, amount);
    }

    /*
        |^^|
    *   Burn
        |^^|

    */
    function burn(address _from, uint256 _amount) public {
        if (!approvedBurner[_msgSender()]) revert NotApprovedBurner();
        /// @dev this will revert if user balance is insufficient
        _burn(_from, _amount);
    }
    function setAreAllTokenTransfersAllowed(bool status) external onlyOwner {
        areAllTokenTransferrsAllowed = status;
    }

    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        *Approve and Unapprove*
    */
    function approveMinter(address _address) public onlyOwner {
        approvedMinter[_address] = true;
    }

    function unapproveMinter(address _address) public onlyOwner {
        delete approvedMinter[_address];
    }

    //approve burner
    function approveBurner(address _address) public onlyOwner {
        approvedBurner[_address] = true;
    }

    function unapproveBurner(address _address) public onlyOwner {
        delete approvedBurner[_address];
    }

    function approveReceiver(address receiver) external onlyOwner{
        approvedReceiver[receiver] = true;

    }
    function unapproveReceiver(address receiver) external onlyOwner {
        delete approvedReceiver[receiver];
    }
    function approveTransferrer(address transferrer) external onlyOwner {
        approvedTransferrer[transferrer] = true;
    }
    function unapproveTransferrer(address transferrer) external onlyOwner {
        delete approvedTransferrer[transferrer];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) virtual {
        //if token transfers are still not allowed
        if(!areAllTokenTransferrsAllowed) {
            // either msg.sender should be approved to send tokens or the receiver must be approved to receive tokens
            require(approvedTransferrer[msg.sender] || approvedReceiver[to],"Ingot: Caller Not Approved To Send");
        }



    }

}