// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeSplitter is Ownable {
    using SafeERC20 for IERC20;

    struct Recipient {
        address account;
        uint256 share;
    }

    bool internal entered;

    uint256 public totalShares;
    Recipient[] public recipients;

    receive() external payable {}

    function distribute() external {
        require(!entered, "REENTERED");
        entered = true;

        uint256 balance = address(this).balance;
        require(balance > 0, "NO_ETH");

        uint256 shares = totalShares;

        Recipient[] memory recipientsList = recipients;
        uint256 length = recipientsList.length;

        for (uint256 i; i < length; ++i) {
            Recipient memory recipient = recipientsList[i];
            (bool success, bytes memory result) = recipient.account.call{
                value: (balance * recipient.share) / shares
            }("");
            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }
        }

        entered = false;
    }

    function addRecipient(Recipient calldata _recipient) external onlyOwner {
        require(_recipient.share > 0, "INVALID_SHARE");
        require(_recipient.account != address(0), "INVALID_ACCOUNT");

        totalShares += _recipient.share;
        recipients.push(_recipient);
    }

    function removeRecipient(uint256 _idx) external onlyOwner {
        uint256 length = recipients.length;
        require(_idx < length, "INVALID_IDX");

        totalShares -= recipients[_idx].share;

        if (_idx == length - 1) recipients.pop();
        else {
            recipients[_idx] = recipients[length - 1];
            recipients.pop();
        }
    }

    function changeRecipientShare(uint256 _idx, uint256 _newShares)
        external
        onlyOwner
    {
        uint256 length = recipients.length;
        require(_idx < length, "INVALID_IDX");

        totalShares = totalShares + _newShares - recipients[_idx].share;
    }

    function rescueToken(IERC20 _token, uint256 _amount) external onlyOwner {
        _token.safeTransfer(owner(), _amount);
    }

    function rescueETH(uint256 _amount) external onlyOwner {
        (bool success, bytes memory result) = msg.sender.call{value: _amount}(
            ""
        );
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}