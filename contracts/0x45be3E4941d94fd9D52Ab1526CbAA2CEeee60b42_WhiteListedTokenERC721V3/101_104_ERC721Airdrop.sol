// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @notice Airdrop contract for Refinable NFT Marketplace
 */
contract ERC721Airdrop is Context, ReentrancyGuard {

    /// @notice ERC721 NFT
    IERC721 public token;
    IERC721 public tokenV2;

    event AirdropContractDeployed();
    event AirdropFinished(
        uint256[] tokenIds,
        address[] recipients
    );

    /**
     * @dev Constructor Function
    */
    constructor(
        IERC721 _token,
        IERC721 _tokenV2
    ) public {
        require(address(_token) != address(0), "Invalid NFT");
        require(address(_tokenV2) != address(0), "Invalid NFT");

        token = _token;
        tokenV2 = _tokenV2;

        emit AirdropContractDeployed();
    }

    /**
     * @dev Owner of token can airdrop tokens to recipients
     * @param _tokenIds array of token id
     * @param _recipients addresses of recipients
     */
    function airdrop(IERC721 _token, uint256[] memory _tokenIds, address[] memory _recipients) external nonReentrant {
        require(
            _token == token || _token == tokenV2,
            "ERC721Airdrop: Token is not allowed"
        );
        require(
            _recipients.length == _tokenIds.length,
            "ERC721Airdrop: Count of recipients should be same as count of token ids"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _token.ownerOf(_tokenIds[i]) == _msgSender(),
                "ERC721Airdrop: Caller is not the owner"
            );
        }

        require(
            _token.isApprovedForAll(_msgSender(), address(this)),
            "ERC721Airdrop: Owner has not approved"
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _token.safeTransferFrom(_msgSender(), _recipients[i], _tokenIds[i]);
        }

        emit AirdropFinished(_tokenIds, _recipients);
    }
}