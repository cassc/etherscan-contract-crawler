// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error WithdrawalFailedUser1();
error WithdrawalFailedUser2();
error WithdrawalFailedUser3();
error WithdrawalFailedUser4();
error WithdrawalFailedUser5();
error WithdrawalFailedUser6();
error ZeroBalance();
error ZeroAddress();

contract JungleFreaksMotorClubWithdrawal is Ownable, ReentrancyGuard {
    address public user1;
    address public user2;
    address public user3;
    address public user4;
    address public user5;
    address public user6;

    constructor() {
        user1 = 0x8e5F332a0662C8c06BDD1Eed105Ba1C4800d4c2f;
        user2 = 0x954BfE5137c8D2816cE018EFd406757f9a060e5f;
        user3 = 0x2E7D93e2AdFC4a36E2B3a3e23dE7c35212471CfB;
        user4 = 0x6fA183959B387a57b4869eAa34c2540Ff237886F;
        user5 = 0x901FC05c4a4bC027a8979089D716b6793052Cc16;
        user6 = 0xd196e0aFacA3679C27FC05ba8C9D3ABBCD353b5D;
    }

    receive() external payable {}

    function calculateSplit(uint256 balance)
        public
        pure
        returns (
            uint256 user1Amount,
            uint256 user2Amount,
            uint256 user3Amount,
            uint256 user4Amount,
            uint256 user5Amount,
            uint256 user6Amount
        )
    {
        uint256 rest = balance;
        user1Amount = (balance * 4000) / 10000; // 40.00%
        rest -= user1Amount;

        user2Amount = (balance * 1500) / 10000; // 15.00%
        rest -= user2Amount;

        user3Amount = (balance * 1000) / 10000; // 10.00%
        rest -= user3Amount;

        user4Amount = (balance * 500) / 10000; // 5.00%
        rest -= user4Amount;

        user5Amount = (balance * 1000) / 10000; // 10.00%
        rest -= user5Amount;

        user6Amount = rest; // 20.00%
    }

    function withdrawErc20(IERC20 token) public nonReentrant {
        uint256 totalBalance = token.balanceOf(address(this));
        if (totalBalance == 0) revert ZeroBalance();
        (
            uint256 user1Amount,
            uint256 user2Amount,
            uint256 user3Amount,
            uint256 user4Amount,
            uint256 user5Amount,
            uint256 user6Amount
        ) = calculateSplit(totalBalance);

        if (!token.transfer(user1, user1Amount)) revert WithdrawalFailedUser1();

        if (!token.transfer(user2, user2Amount)) revert WithdrawalFailedUser2();

        if (!token.transfer(user3, user3Amount)) revert WithdrawalFailedUser3();

        if (!token.transfer(user4, user4Amount)) revert WithdrawalFailedUser4();

        if (!token.transfer(user5, user5Amount)) revert WithdrawalFailedUser5();

        if (!token.transfer(user6, user6Amount)) revert WithdrawalFailedUser6();
    }

    function withdrawEth() public nonReentrant {
        uint256 totalBalance = address(this).balance;
        if (totalBalance == 0) revert ZeroBalance();
        (
            uint256 user1Amount,
            uint256 user2Amount,
            uint256 user3Amount,
            uint256 user4Amount,
            uint256 user5Amount,
            uint256 user6Amount
        ) = calculateSplit(totalBalance);

        if (!payable(user1).send(user1Amount)) revert WithdrawalFailedUser1();

        if (!payable(user2).send(user2Amount)) revert WithdrawalFailedUser2();

        if (!payable(user3).send(user3Amount)) revert WithdrawalFailedUser3();

        if (!payable(user4).send(user4Amount)) revert WithdrawalFailedUser4();

        if (!payable(user5).send(user5Amount)) revert WithdrawalFailedUser5();

        if (!payable(user6).send(user6Amount)) revert WithdrawalFailedUser6();
    }

    function setUser1(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user1 = address_;
    }

    function setUser2(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user2 = address_;
    }

    function setUser3(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user3 = address_;
    }

    function setUser4(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user4 = address_;
    }

    function setUser5(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user5 = address_;
    }

    function setUser6(address address_) external onlyOwner {
        if (address_ == address(0)) revert ZeroAddress();
        user6 = address_;
    }
}