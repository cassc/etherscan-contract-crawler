// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Airdrop is Ownable, ReentrancyGuard {
    event Fund(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount
    );

    event Claimed(
        address indexed tokenAddress,
        address indexed user,
        uint256 amount,
        address to
    );

    mapping(address => mapping(address => uint256)) timestamps;
    mapping(address => mapping(address => uint256)) balances;

    function fund(
        address tokenAddress,
        address[] memory users,
        uint256[] memory amounts
    ) public {
        uint256 total;
        for (uint256 i = 0; i < users.length; i++) {
            balances[users[i]][tokenAddress] += amounts[i];
            timestamps[users[i]][tokenAddress] = block.timestamp;
            total += amounts[i];
            emit Fund(tokenAddress, users[i], amounts[i]);
        }
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), total);
    }

    function claimable(address user, address tokenAddress)
        public
        view
        returns (uint256)
    {
        return balances[user][tokenAddress];
    }

    function claim(address tokenAddress) public nonReentrant {
        require(balances[msg.sender][tokenAddress] > 0, "unclaimable");

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, balances[msg.sender][tokenAddress]);
        emit Claimed(
            tokenAddress,
            msg.sender,
            balances[msg.sender][tokenAddress],
            msg.sender
        );
        balances[msg.sender][tokenAddress] = 0;
    }

    function refund(address user, address tokenAddress)
        public
        nonReentrant
        onlyOwner
    {
        require(balances[user][tokenAddress] > 0, "empty balance");
        require(
            block.timestamp - timestamps[user][tokenAddress] > 30 * 24 * 3600,
            "cooldown"
        );

        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, balances[user][tokenAddress]);

        emit Claimed(
            tokenAddress,
            msg.sender,
            balances[msg.sender][tokenAddress],
            msg.sender
        );
        balances[user][tokenAddress] = 0;
    }
}