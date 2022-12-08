// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import "./ERC1155Mintable.sol";

contract MogulERC1155Mintable is ERC1155AMintable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    constructor() {}

    function _mintToken(
        address recipient,
        uint256 tokenId,
        uint256 amount,
        bytes calldata data
    ) private {
        totalSupply[tokenId] += amount;
        _mint(recipient, tokenId, amount, data);

        if (tokenId > currentMaxTokenId) {
            currentMaxTokenId = tokenId;
        }
    }

    function _payment(
        address _paymentToken,
        uint256[] memory _tokensIds,
        uint256[] memory _amounts,
        bytes32[] calldata _merkleProof
    ) private {
        if (!isPaymentToken[_paymentToken])
            revert InvalidAction("Invalid token");

        if (_merkleProof.length > 0) {
            if (!isAvailable(startTimeWhitelist, endTimeWhitelist))
                revert InvalidAction("Mint unavailable");

            if (whitelistClaimed[msg.sender])
                revert InvalidAction("Whitelist Claimed");

            //Verify provided _merkelProof via APi call
            if (!isWhiteListed(_merkleProof, msg.sender))
                revert InvalidAction("Invalid proof");
        } else if (!isAvailable(startTime, endTime)) {
            revert InvalidAction("Mint unavailable");
        }

        uint256 totalCost = getTotalCost(_paymentToken, _tokensIds, _amounts);

        if (_paymentToken != address(0)) {
            IERC20(_paymentToken).transferFrom(
                msg.sender,
                address(this),
                totalCost
            );
        } else if (msg.value < totalCost) {
            revert InvalidAction("Insufficient balance");
        }

        if (_merkleProof.length > 0) {
            whitelistClaimed[msg.sender] = true;
        }
    }

    /**
   * @dev Mint a new ERC1155 Token

    * Params:
    * recipient: recipient of the new tokens
    * tokenId: the id of the token
    * amount: amount to mint
    * data: data
    */

    function mintToken(
        address recipient,
        uint256 tokenId,
        uint256 amount,
        address paymentToken,
        bytes calldata data,
        bytes32[] calldata merkleProof
    ) external payable {
        verifySupply(amount, tokenId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        _payment(paymentToken, tokenIds, amounts, merkleProof);

        _mintToken(recipient, tokenId, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address paymentToken,
        bytes calldata data,
        bytes32[] calldata merkleProof
    ) external payable verifyMintAmount(tokenIds, amounts) {
        _payment(paymentToken, tokenIds, amounts, merkleProof);

        for (uint256 j = 0; j < amounts.length; j++) {
            totalSupply[tokenIds[j]] += amounts[j];

            if (tokenIds[j] > currentMaxTokenId) {
                currentMaxTokenId = tokenIds[j];
            }
        }

        _mintBatch(to, tokenIds, amounts, data);
    }

    function mintBatchMultipleRecipients(
        address[] memory tos,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        address paymentToken,
        bytes calldata data,
        bytes32[] calldata merkleProof
    ) external payable verifyMintAmount(tokenIds, amounts) {
        if (tokenIds.length != amounts.length || tokenIds.length != tos.length)
            revert InvalidAction("Arrays do not match");

        _payment(paymentToken, tokenIds, amounts, merkleProof);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _mintToken(tos[i], tokenIds[i], amounts[i], data);
        }
    }
}