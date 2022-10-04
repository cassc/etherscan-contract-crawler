pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Dropys {
    function dropysAirdropsEtherValue(address[] calldata recipients, uint256 value) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(value);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(msg.sender).transfer(balance);
    }

    function dropysAirdropsEther(address[] calldata recipients, uint256[] calldata values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            payable(msg.sender).transfer(balance);
    }

    function dropysAirdropsTokenValue(IERC20 token, address[] calldata recipients, uint256 value) external {
        require(token.transferFrom(msg.sender, address(this), value * recipients.length));
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], value));
    }

    function dropysAirdropsToken(IERC20 token, address[] calldata recipients, uint256[] calldata values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function dropysAirdropsNFT721Increment(IERC721 token, address[] calldata recipients, uint256 startingTokenId) external {
        for (uint256 i = 0; i < recipients.length; i++)
            token.transferFrom(msg.sender, recipients[i], i + startingTokenId);
    }

    function dropysAirdropsNFT721(IERC721 token, address[] calldata recipients, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < recipients.length; i++)
            token.transferFrom(msg.sender, recipients[i], tokenIds[i]);
    }

    function dropysAirdropsNFT1155IdValue(IERC1155 token, address[] calldata recipients, uint256 tokenId, uint256 value) external {
        for (uint256 i = 0; i < recipients.length; i++)
            token.safeTransferFrom(msg.sender, recipients[i], tokenId, value, "");
    }

    function dropysAirdropsNFT1155IdsValue(IERC1155 token, address[] calldata recipients, uint256[] calldata tokenIds, uint256 value) external {
        for (uint256 i = 0; i < recipients.length; i++)
            token.safeTransferFrom(msg.sender, recipients[i], tokenIds[i], value, "");
    }

    function dropysAirdropsNFT1155Id(IERC1155 token, address[] calldata recipients, uint256 tokenId, uint256[] calldata values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            token.safeTransferFrom(msg.sender, recipients[i], tokenId, values[i], "");
    }

    function dropysAirdropsNFT1155(IERC1155 token, address[] calldata recipients, uint256[] calldata tokenIds, uint256[] calldata values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            token.safeTransferFrom(msg.sender, recipients[i], tokenIds[i], values[i], "");
    }
}