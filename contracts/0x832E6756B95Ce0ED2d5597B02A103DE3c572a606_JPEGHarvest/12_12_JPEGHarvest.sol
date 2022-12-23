// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

interface ERCBase {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function isApprovedForAll(address account, address operator) external view returns (bool);
}

interface ERC721Partial is ERCBase {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC1155Partial is ERCBase {
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata) external;
}

contract JPEGHarvest is ReentrancyGuard, Pausable, Ownable, ERC721Holder, ERC1155Holder {

    bytes4 _ERC721 = 0x80ac58cd;
    bytes4 _ERC1155 = 0xd9b67a26;

    uint256 public sellPrice = 1 wei;
    uint256 public maxTokensPerTx = 100;

    function setSellPrice(uint256 _sellPrice) onlyOwner public {
        sellPrice = _sellPrice;
    }

    function setMaxTokensPerTx(uint256 _maxTokensPerTx) onlyOwner public {
        maxTokensPerTx = _maxTokensPerTx;
    }

    function pause() onlyOwner public {
        _pause();
    }

    function unpause() onlyOwner public {
        _unpause();
    }

    function batchTransfer(address[] calldata tokenContracts, uint256[] calldata tokenIds, uint256[] calldata counts) external whenNotPaused nonReentrant {
        require(tokenContracts.length > 0, "Must have 1 or more token contracts");
        require(tokenContracts.length == tokenIds.length && tokenIds.length == counts.length, "All params must have equal length");

        ERCBase tokenContract;
        uint256 totalTokens = 0;
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < tokenContracts.length; i++) {
            require(counts[i] > 0, "Token count must be greater than zero.");

            tokenContract = ERCBase(tokenContracts[i]);

            if (tokenContract.supportsInterface(_ERC721)) {
                totalTokens += 1;
                totalPrice += sellPrice;
            }
            else if (tokenContract.supportsInterface(_ERC1155)) {
                totalTokens += counts[i];
                totalPrice += sellPrice * counts[i];
            }
            else {
                continue;
            }

            require(totalTokens < maxTokensPerTx, "Maximum token count reached.");
            require(address(this).balance > totalPrice, "Not enough ether in contract.");
            require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Token not yet approved for all transfers");

            if (tokenContract.supportsInterface(_ERC721)) {
                ERC721Partial(tokenContracts[i]).transferFrom(msg.sender, address(this), tokenIds[i]);
            }
            else {
                ERC1155Partial(tokenContracts[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i], counts[i], "");
            }
        }

        (bool sent, ) = payable(msg.sender).call{ value: totalPrice }("");
        require(sent, "Failed to send ether.");
    }

    function batchTransferOnlyERC721(address[] calldata tokenContracts, uint256[] calldata tokenIds) external whenNotPaused nonReentrant {
        require(tokenContracts.length > 0, "Must have 1 or more token contracts");
        require(tokenContracts.length == tokenIds.length, "All params must have equal length");
        require(tokenContracts.length < maxTokensPerTx, "Maximum token count reached.");

        ERCBase tokenContract;
        uint256 totalTokens = 0;
        uint256 totalPrice = 0;

        for (uint256 i = 0; i < tokenContracts.length; i++) {
            tokenContract = ERCBase(tokenContracts[i]);

            if (tokenContract.supportsInterface(_ERC721)) {
                totalTokens += 1;
                require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Token not yet approved for all transfers");
                ERC721Partial(tokenContracts[i]).transferFrom(msg.sender, address(this), tokenIds[i]);
            } 
            else {
                continue;
            }
        }

        totalPrice = totalTokens * sellPrice;
        require(address(this).balance > totalPrice, "Not enough ether in contract.");

        (bool sent, ) = payable(msg.sender).call{ value: totalPrice }("");
        require(sent, "Failed to send ether.");
    }

    receive () external payable { }

    function withdrawBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(address[] calldata tokenContracts, uint256[] calldata tokenIds, uint256[] calldata counts) external onlyOwner {
        require(tokenContracts.length == tokenIds.length && tokenIds.length == counts.length, "All params must have equal length");

        ERCBase tokenContract;
        for (uint256 i = 0; i < tokenContracts.length; i++) {
            require(counts[i] > 0, "Token count must be greater than zero.");

            tokenContract = ERCBase(tokenContracts[i]);

            if (tokenContract.supportsInterface(_ERC721)) {
                ERC721Partial(tokenContracts[i]).transferFrom(address(this), msg.sender, tokenIds[i]);
            }
            else {
                ERC1155Partial(tokenContracts[i]).safeTransferFrom(address(this), msg.sender, tokenIds[i], counts[i], "");
            }
        }
    }
}