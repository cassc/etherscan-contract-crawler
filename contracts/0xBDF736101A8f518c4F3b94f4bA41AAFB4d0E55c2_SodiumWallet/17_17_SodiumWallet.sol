// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/ISodiumRegistry.sol";
import "./interfaces/ISodiumWallet.sol";

contract SodiumWallet is ISodiumWallet, Initializable, ERC721Holder, ERC1155Holder {
    address private borrower;
    address private core;
    address private registry;

    modifier onlyCore() {
        require(msg.sender == core, "Sodium Wallet: Core only");
        _;
    }

    function initialize(
        address borrower_,
        address core_,
        address registry_
    ) external override initializer {
        borrower = borrower_;
        core = core_;
        registry = registry_;
    }

    function execute(
        address[] calldata contractAddresses_,
        bytes[] memory calldatas_,
        uint256[] calldata values_
    ) external payable override {
        require(msg.sender == borrower, "Sodium Wallet: Borrower only");

        for (uint256 i = 0; i < contractAddresses_.length; i++) {
            bytes memory cd = calldatas_[i];
            bytes4 signature;

            assembly {
                signature := mload(add(cd, 32))
            }

            require(
                ISodiumRegistry(registry).getCallPermission(contractAddresses_[i], signature),
                "Sodium Wallet: Non-permitted call"
            );

            (bool success, ) = contractAddresses_[i].call{value: values_[i]}(calldatas_[i]);

            require(success, "Sodium Wallet: Call failed");
        }
    }

    function transferERC721(
        address recipient_,
        address tokenAddress_,
        uint256 tokenId_
    ) external override onlyCore {
        IERC721(tokenAddress_).safeTransferFrom(address(this), recipient_, tokenId_);
    }

    function transferERC1155(
        address recipient_,
        address tokenAddress_,
        uint256 tokenId_
    ) external override onlyCore {
        IERC1155(tokenAddress_).safeTransferFrom(address(this), recipient_, tokenId_, 1, "");
    }

    receive() external payable {}
}