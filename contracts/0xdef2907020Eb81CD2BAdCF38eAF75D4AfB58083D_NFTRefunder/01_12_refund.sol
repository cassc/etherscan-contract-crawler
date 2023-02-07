// contracts/nftrefunder.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTRefunder is ReentrancyGuard {
    address public owner = 0xAdCa2CCcF35CbB27fD757f1c0329DF767f8E38F0;
    uint256 public REFUND_AMOUNT = 0.05 ether;
    ERC721 public nftContract = ERC721(0xBDA937F5C5f4eFB2261b6FcD25A71A1C350FdF20);

    // Call this with your token ID to get a refund
    // This will refund you REFUND_AMOUNT and burn your NFT
    // Don't forget to approve this contract to transfer your NFT first!
    //
    // Approve option 1 (I just have 1 NFT / I have many NFTs and don't care about gas)
    // 1. Call approve(this_contract_address, token_id) on the NFT contract
    // 2. Call getRefundForNFT(token_id)
    // 3. Repeat steps 1 and 2 for each NFT you want to refund
    //
    // Approve option 2 (I have many NFTs and want to save gas)
    // 1. Call setApprovalForAll(this_contract_address, true) on the NFT contract
    // 2. Get refunds for each NFT by calling getRefundForNFT(token_id)
    // 3. Call setApprovalForAll(this_contract_address, false) on the NFT contract
    //    to undo the approval
    function getRefundForNFT(uint256 _tokenId) external nonReentrant {
        // Make sure the NFT is owned by the sender
        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "Only the owner of the NFT can send it to the contract"
        );
        // Burn the NFT
        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        // Send the refund
        payable(msg.sender).transfer(REFUND_AMOUNT);
    }

    // This is just for safety, in case something unexpected happens and
    // the team needs to withdraw funds from the refund contract.
    // You don't need to call this to get a refund.
    function withdraw() external nonReentrant {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        payable(owner).transfer(address(this).balance);
    }

    // Get contract balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    // Needed so that the contract can receive ETH
    receive() external payable {}

    fallback() external payable {}
}