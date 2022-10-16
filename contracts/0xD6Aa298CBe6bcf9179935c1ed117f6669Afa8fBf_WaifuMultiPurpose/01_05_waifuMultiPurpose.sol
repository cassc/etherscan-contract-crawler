// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Multicall helper functions
contract WaifuMultiPurpose is Ownable {
    /// @dev multicall implemenation to check eth balances in a single call
    /// @param addresses array of addresses to check
    /// @return balances array of balances
    function getEthBalances(address[] calldata addresses)
        external
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](addresses.length);
        for (uint256 i; i < addresses.length; ) {
            balances[i] = address(addresses[i]).balance;
            unchecked {
                i++;
            }
        }
    }

    /// @dev multicall implemenation to disperse uniform amounts of eth to multiple addresses
    /// @param recipients array of addresses to disperse to
    function disperseEther(address[] calldata recipients) external payable {
        uint256 value = msg.value / recipients.length;
        for (uint256 i; i < recipients.length; ) {
            (bool success, ) = recipients[i].call{value: value}("");
            require(success, "ETH transfer failed");
            unchecked {
                i++;
            }
        }
    }

    struct EthTransfer {
        address recipient;
        uint256 amount;
    }

    /// @dev multicall implemenation to disperse non-unitform amounts of eth to multiple addresses
    /// @param transfers array of EthTransfers structs denoting recipient and amount of eth to disperse
    function disperseEther(EthTransfer[] calldata transfers) external payable {
        for (uint256 i; i < transfers.length; ) {
            (bool success, ) = transfers[i].recipient.call{value: transfers[i].amount}("");
            require(success, "ETH TRANSFER FAILED");
            unchecked {
                i++;
            }
        }

        uint256 balance = address(this).balance;

        if (balance > 0) {
            (bool success, ) = msg.sender.call{value: balance}("");
            require(success, "ETH TRANSFER FAILED");
        }
    }

    /// @dev multicall implemenation to check ERC721 balances of multiple addresses in a single call
    /// @param nft address of ERC721 contract
    /// @param addresses array of addresses to check
    /// @return balances array of ERC721 balances
    function getERC721Balance(IERC721 nft, address[] calldata addresses)
        external
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](addresses.length);
        for (uint256 i; i < addresses.length; ) {
            balances[i] = nft.balanceOf(addresses[i]);
            unchecked {
                i++;
            }
        }
    }

    struct ERC721Transfer {
        address recipient;
        uint256 tokenId;
    }

    /// @dev multicall implemenation to disperse ERC721 tokens to one or more addresses
    /// @param nft address of ERC721 contract
    /// @param transfers array of ERC721Transfer structs denoting recipient and tokenId of ERC721 to disperse
    function batchTransferERC721(IERC721 nft, ERC721Transfer[] calldata transfers) external {
        for (uint256 i; i < transfers.length; ) {
            nft.transferFrom(msg.sender, transfers[i].recipient, transfers[i].tokenId);
            unchecked {
                i++;
            }
        }
    }

    receive() external payable {}

    /// @dev in the off chance eth winds up stuck in this contract
    function rescueEth() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ETH TRANSFER FAILED");
    }

    /// @dev in the off chance ERC721s winds up stuck in this contract
    /// @param nft the nft to rescue
    /// @param tokenId the tokenId to rescue
    function rescueERC721(IERC721 nft, uint256 tokenId) external onlyOwner {
        nft.transferFrom(address(this), msg.sender, tokenId);
    }
}


///Special thanks to ButtrMyToast