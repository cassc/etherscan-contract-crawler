// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

contract Disperse is Ownable {
    using SafeERC20 for IERC20;

    function disperseNFT(
        address recipient,
        IERC721_IERC1155[] calldata tokens,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    )
        external
    {
        for (uint256 index; index < tokenIds.length; index++) {
            if (amounts[index] > 0) {
                tokens[index].safeTransferFrom(msg.sender, recipient, tokenIds[index], amounts[index], "");
            } else {
                tokens[index].safeTransferFrom(msg.sender, recipient, tokenIds[index]);
            }
        }
    }

    function disperseEther(address[] memory recipients, uint256[] memory values) external payable {
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(values[i]);
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }

    function disperseToken(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total += values[i];
        }
        token.safeTransferFrom(msg.sender, address(this), total);
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransfer(recipients[i], values[i]);
        }
    }

    function disperseTokenSimple(IERC20 token, address[] memory recipients, uint256[] memory values) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(msg.sender, recipients[i], values[i]);
        }
    }

    function disperseEtherSameValue(address[] memory recipients, uint256 value) external payable {
        for (uint256 i = 0; i < recipients.length; i++) {
            payable(recipients[i]).transfer(value);
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }

    function disperseTokenSameValue(IERC20 token, address[] memory recipients, uint256 value) external {
        uint256 total = value * recipients.length;
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], value));
        }
    }

    /// @notice Withdraws all tokens held by the contract.
    /// if client send asset to this contract by mistake, owner can withdraw it back.
    /// if you have any trouble, please contact us via https://discord.gg/onekey
    /// @param token The token contract address.
    /// @param to The address to send the tokens to.
    function withdraw(IERC20 token, address to) external onlyOwner {
        token.safeTransfer(to, token.balanceOf(address(this)));
    }

    /// @notice Withdraws erc721 or erc1155 held by the contract.
    /// if client send asset to this contract by mistake, owner can withdraw it back
    /// if you have any trouble, please contact us via https://discord.gg/onekey
    /// @param token The token contract address.
    /// @param tokenId The token id.
    /// @param amount The token amount.
    function withdrawNFT(address to, IERC721_IERC1155 token, uint256 tokenId, uint256 amount) external onlyOwner {
        if (amount > 0) {
            token.safeTransferFrom(address(this), to, tokenId, amount, "");
        } else {
            token.safeTransferFrom(address(this), to, tokenId);
        }
    }
}

interface IERC721_IERC1155 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes calldata data)
        external;
}