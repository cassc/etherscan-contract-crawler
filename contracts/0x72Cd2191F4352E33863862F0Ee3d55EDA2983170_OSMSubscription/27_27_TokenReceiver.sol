// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Subscribable.sol";
import "./LockableTransferrable.sol";
import { SetReceivable, ReceivableData, ReceivedTokenNonExistent, ReceivedTokenNonOwner, MintNotLive } from "./SetReceivable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";

error ReceiverNotImplemented();

abstract contract TokenReceiver is Subscribable,IERC721Receiver {
    using Address for address;
    using SetReceivable for ReceivableData; // this is the crucial change
    ReceivableData receivables;
      

    function balanceOfWallet(address wallet, address contracted) public view returns (uint256) {
        return receivables.balanceOfWallet(wallet,contracted);
    }  

    function hasReceived(address wallet, address contracted) public view returns (uint256[] memory) {
        return receivables.receivedFromWallet(wallet,contracted);
    }

    function _addTokenToReceivedEnumeration(address from, address contracted, uint256 tokenId) private {
        receivables._addTokenToReceivedEnumeration(from,contracted,tokenId);
    }    

    function _removeTokenFromReceivedEnumeration(address from, address contracted, uint256 tokenId) private {
        receivables._removeTokenFromReceivedEnumeration(from,contracted,tokenId);
    }

    function tokenReceivedByIndex(address wallet, address contracted, uint256 index) public view returns (uint256) {
        return receivables.tokenReceivedByIndex(wallet,contracted,index);
    }

    function withdraw(address contracted, uint256[] calldata tokenIds) public {
        return receivables.withdraw(contracted,tokenIds);
    }
 
    function onERC721Received(address, address from, uint256 tokenId, bytes memory) public virtual override returns (bytes4) {
        _addTokenToReceivedEnumeration(from, msg.sender, tokenId);
        return this.onERC721Received.selector;
    }     

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId, data);
        receivables.swapOwner(from,to);
    }   

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        super.transferFrom(from, to, tokenId);
        receivables.swapOwner(from,to);
    }
     
}