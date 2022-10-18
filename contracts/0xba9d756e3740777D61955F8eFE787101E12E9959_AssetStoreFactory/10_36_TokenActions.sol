//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../structs/ApprovalsStruct.sol";

/**
 * @title TokenActions Library
 *
 * Here contains the common functions for interacting with
 * tokens for importing in different parts of the ecosystem
 * to save space hopefully in other places
 */
library TokenActions {
    /**
     * @notice internal function for sending erc20s
     *
     * creating this function to save space while sending coins
     * to charities and for beneficiaries
     *
     * @param _approval of the Approvals type in storage
     */
    function sendERC20(Approvals storage _approval) internal {
        IERC20 ERC20 = IERC20(_approval.token.tokenAddress);

        /// @notice gather the preset approved token amount for this beneficiary
        uint256 _tokenAmount = (_approval.approvedTokenAmount);

        /// @notice If the allowance for the member by claimer is greater than the _tokenAmount
        /// take the allowance for the beneficiary that called this function: why ?
        if (
            ERC20.allowance(_approval.approvedWallet, msg.sender) > _tokenAmount
        ) {
            _tokenAmount = ERC20.allowance(
                _approval.approvedWallet,
                msg.sender
            );
        }

        ERC20.transferFrom(
            _approval.approvedWallet,
            _approval.beneficiary.beneficiaryAddress,
            _tokenAmount
        );

        _approval.claimed = true;
    }

    /**
     *
     * @dev checkAssetContract
     * @param _contractAddress contract of the token we are checking
     * @param _tokenType the given tokentype as a string ERC721 etc...
     *
     * Checks if the assets passed through are assets of the determined type or not.
     * it can handle upgradable versions as well if needed
     *
     */
    function checkAssetContract(
        address _contractAddress,
        string memory _tokenType
    ) public view {
        if (
            (keccak256(abi.encodePacked((_tokenType))) ==
                keccak256(abi.encodePacked(("ERC721"))))
        ) {
            require(
                (IERC721Upgradeable(_contractAddress).supportsInterface(
                    type(IERC721Upgradeable).interfaceId
                ) ||
                    IERC721(_contractAddress).supportsInterface(
                        type(IERC721).interfaceId
                    )),
                "Does not support a Supported ERC721 Interface"
            );
        } else if (
            keccak256(abi.encodePacked((_tokenType))) ==
            keccak256(abi.encodePacked(("ERC20")))
        ) {
            require(
                (IERC20(_contractAddress).totalSupply() >= 0 ||
                    IERC20Upgradeable(_contractAddress).totalSupply() >= 0),
                "Is not an ERC20 Contract Address"
            );
        } else if (
            keccak256(abi.encodePacked((_tokenType))) ==
            keccak256(abi.encodePacked(("ERC1155")))
        ) {
            require(
                (IERC1155Upgradeable(_contractAddress).supportsInterface(
                    type(IERC1155Upgradeable).interfaceId
                ) ||
                    IERC1155(_contractAddress).supportsInterface(
                        type(IERC1155).interfaceId
                    )),
                "Does not support a Supported ERC1155 Interface"
            );
        } else {
            revert("Invalid token type");
        }
    }
}