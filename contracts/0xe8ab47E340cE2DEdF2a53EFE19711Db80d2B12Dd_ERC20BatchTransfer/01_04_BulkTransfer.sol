// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract ERC20BatchTransfer is Ownable {
    mapping(address => bool) private whitelist;
    function addToWhitelist(address user) external onlyOwner {
        whitelist[user] = true;
    }
    function removeFromWhitelist(address user) external onlyOwner {
        whitelist[user] = false;
    }
    function isWhitelisted(address user) public view returns (bool) {
        return whitelist[user];
    }
    function batchTransfer(
        IERC20 token,
        address[] memory recipients,
        uint256[] memory amounts
    ) external {
        require(
            isWhitelisted(msg.sender),
            "Caller is not whitelisted for batch transfers."
        );
        require(
            recipients.length == amounts.length,
            "Recipients and amounts arrays must have the same length."
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            require(
                recipients[i] != address(0),
                "Recipient address cannot be zero address."
            );
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
    }
}