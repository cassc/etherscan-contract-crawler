// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../util/Ownablearama.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract TreatExchange is Ownablearama {
    IERC1155 public immutable treats;

    address public vault;

    mapping(uint256 => address) public treatIdToExhangeForContract;

    uint256 public startTimestamp = type(uint256).max;

    constructor(IERC1155 _treats) {
        treats = _treats;
    }

    function exchange(uint256 treatTokenId, uint256 receivingTokenId) external {
        require(block.timestamp >= startTimestamp, "TreatExchange: not open");

        address exchangeForContract = treatIdToExhangeForContract[treatTokenId];

        require(
            exchangeForContract != address(0),
            "TokenExchange: treat token ID not eligible"
        );

        treats.safeTransferFrom(msg.sender, vault, treatTokenId, 1, "");

        IERC721(exchangeForContract).safeTransferFrom(
            vault,
            msg.sender,
            receivingTokenId
        );
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function setTreatExchangeContract(
        uint256 treatTokenId,
        address exchangeForContract
    ) external onlyOwner {
        treatIdToExhangeForContract[treatTokenId] = exchangeForContract;
    }

    function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function rescueERC721(
        address token,
        uint256 tokenId,
        address receiver
    ) external onlyOwner {
        IERC721(token).safeTransferFrom(address(this), receiver, tokenId);
    }

    function rescueERC1155(
        address token,
        uint256 tokenId,
        uint256 quantity,
        bytes memory data,
        address receiver
    ) external onlyOwner {
        IERC1155(token).safeTransferFrom(
            address(this),
            receiver,
            tokenId,
            quantity,
            data
        );
    }
}