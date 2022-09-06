// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * Amplifi
 * Website: https://perpetualyield.io/
 * Telegram: https://t.me/Amplifi_ERC
 * Twitter: https://twitter.com/amplifidefi
 */
contract FeeSplitter is Ownable, ReentrancyGuard {
    address[] public recipients;
    uint16[] public shares;
    uint16 public totalShares;

    constructor(address[] memory _recipients, uint16[] memory _shares) {
        _setRecipients(_recipients, _shares);
    }

    function claim() external nonReentrant {
        uint256 length = shares.length;
        uint256 totalBalance = address(this).balance;

        bool success = false;

        for (uint256 i = 0; i < length; ) {
            (success, ) = recipients[i].call{value: (totalBalance * shares[i]) / totalShares}("");
            require(success, "Could not send ETH");
            unchecked {
                ++i;
            }
        }
    }

    function setRecipients(address[] calldata _recipients, uint16[] calldata _shares) external onlyOwner {
        _setRecipients(_recipients, _shares);
    }

    function _setRecipients(address[] memory _recipients, uint16[] memory _shares) internal {
        uint256 length = _shares.length;
        require(_recipients.length == length, "Lengths not aligned");

        recipients = _recipients;
        shares = _shares;

        totalShares = 0;
        for (uint256 i = 0; i < length; ) {
            totalShares += _shares[i];
            unchecked {
                ++i;
            }
        }
    }

    receive() external payable {}
}