// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @notice Airdrop contract for Refinable NFT Marketplace
 */
contract ERC1155AirdropMatic is Context, ReentrancyGuard {

    /// @notice ERC1155 NFT
    IERC1155 public token;

    event AirdropContractDeployed();
    event AirdropFinished(
        uint256 tokenId,
        address[] recipients
    );

    /**
     * @dev Constructor Function
    */
    constructor(
        IERC1155 _token
    ) public {
        require(address(_token) != address(0), "Invalid NFT");

        token = _token;

        emit AirdropContractDeployed();
    }

    /**
     * @dev Owner of token can airdrop tokens to recipients
     * @param _tokenId id of the token
     * @param _recipients addresses of recipients
     */
    function airdrop(IERC1155 _token, uint256 _tokenId, address[] memory _recipients) external nonReentrant {
        require(
            _token == token,
            "ERC1155Airdrop: Token is not allowed"
        );
        require(
            _token.balanceOf(_msgSender(), _tokenId) >= _recipients.length,
            "ERC1155Airdrop: Caller does not have amount of tokens"
        );
        require(
            _token.isApprovedForAll(_msgSender(), address(this)),
            "ERC1155Airdrop: Owner has not approved"
        );

        for (uint256 i = 0; i < _recipients.length; i++) {
            _token.safeTransferFrom(_msgSender(), _recipients[i], _tokenId, 1, "");
        }

        emit AirdropFinished(_tokenId, _recipients);
    }
}