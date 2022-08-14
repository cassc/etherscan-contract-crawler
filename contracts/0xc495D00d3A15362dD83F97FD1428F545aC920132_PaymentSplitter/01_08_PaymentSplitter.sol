// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract PaymentSplitter is Context {
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event ERC721Released(IERC721 indexed token, address to, uint256 tokenId);
    event PaymentReceived(address from, uint256 amount);

    Member[] private _members;
    struct Member {
        address account;
        uint32 value;
    }

    ///@notice Shares total 10000 = 100%
    ///@dev Support 2 decimals after 0 e.g. 1337 = 13.37%
    uint256 public constant SHARES_TOTAL = 10_000;

    function initialize(Member[] calldata m) public {
        require(_members.length == 0, "PaymentSplitter: already initialized");

        uint256 sharesTotal = 0;
        for (uint256 i = 0; i < m.length; i++) {
            sharesTotal += m[i].value;
        }
        require(
            sharesTotal == SHARES_TOTAL,
            "PaymentSplitter: shares total != 10000"
        );

        for (uint256 i = 0; i < m.length; i++) {
            _members.push(m[i]);
        }
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function release() external virtual {
        uint256 balance = address(this).balance;
        Member[] memory members_ = _members;
        for (uint256 i = 0; i < members_.length; i++) {
            address account = members_[i].account;
            uint256 payment = (balance * members_[i].value) / SHARES_TOTAL;
            emit PaymentReleased(account, payment);
            Address.sendValue(payable(account), payment);
        }
    }

    function releaseERC20(IERC20 token) external virtual {
        uint256 balance = token.balanceOf(address(this));
        Member[] memory members_ = _members;
        for (uint256 i = 0; i < members_.length; i++) {
            address account = members_[i].account;
            uint256 payment = (balance * members_[i].value) / SHARES_TOTAL;
            emit ERC20PaymentReleased(token, account, payment);
            SafeERC20.safeTransfer(token, account, payment);
        }
    }

    function releaseERC721(IERC721 token, uint256 tokenId) external virtual {
        address account = _members[0].account;

        emit ERC721Released(token, account, tokenId);
        token.safeTransferFrom(address(this), account, tokenId);
    }

    function members() external view returns (Member[] memory) {
        return _members;
    }

    function isMember(address account) external view returns (bool) {
        for (uint256 i = 0; i < _members.length; i++) {
            if (account == _members[i].account) {
                return true;
            }
        }
        return false;
    }
}