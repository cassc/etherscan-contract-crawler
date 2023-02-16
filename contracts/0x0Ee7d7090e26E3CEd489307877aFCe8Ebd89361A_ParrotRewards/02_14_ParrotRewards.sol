// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IParrotRewards.sol";

contract ParrotRewards is IParrotRewards, Ownable {
    event DistributeReward(address indexed wallet, address receiver);
    event DepositRewards(address indexed wallet, uint256 amountETH);

    IERC20 public usdc;

    address public immutable shareholderToken;
    uint256 public totalLockedUsers;
    uint256 public totalSharesDeposited;
    uint256 public totalRewards;
    uint256 public totalDistributed;

    uint160[] private shareHolders;

    mapping(address => uint256) private shares;
    mapping(address => uint256) private unclaimedRewards;
    mapping(address => uint256) private claimedRewards;

    uint256 private constant ACC_FACTOR = 10 ** 36;

    constructor(address _shareholderToken) {
        shareholderToken = _shareholderToken;
    }

    function deposit(uint256 _amount) external {
        IERC20 tokenContract = IERC20(shareholderToken);
        tokenContract.transferFrom(msg.sender, address(this), _amount);
        _addShares(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        address shareholder = msg.sender;
        _removeShares(shareholder, _amount);
        IERC20(shareholderToken).transfer(shareholder, _amount);
    }

    function _addShares(address shareholder, uint256 amount) internal {
        uint256 sharesBefore = shares[shareholder];
        totalSharesDeposited += amount;
        shares[shareholder] += amount;
        if (sharesBefore == 0 && shares[shareholder] > 0) {
            shareHolders.push(uint160(shareholder));
            totalLockedUsers++;
        }
    }

    function _removeShares(address shareholder, uint256 amount) internal {
        require(
            shares[shareholder] > 0 && amount <= shares[shareholder],
            "only withdraw what you deposited"
        );
        _distributeReward(shareholder);

        totalSharesDeposited -= amount;
        shares[shareholder] -= amount;
        if (shares[shareholder] == 0) {
            if (shareHolders.length > 1) {
                for (uint256 i = 0; i < shareHolders.length; ) {
                    if (shareHolders[i] == uint160(shareholder)) {
                        shareHolders[i] = shareHolders[shareHolders.length - 1];
                        delete shareHolders[shareHolders.length - 1];
                    }
                    unchecked {
                        ++i;
                    }
                }
            } else {
                delete shareHolders[0];
            }
            totalLockedUsers--;
        }
    }

    function depositRewards(uint256 _amount) external {
        require(totalSharesDeposited > 0, "no reward recipients");
        usdc.transferFrom(msg.sender, address(this), _amount);

        uint256 shareAmount = (ACC_FACTOR * _amount) / totalSharesDeposited;
        for (uint256 i = 0; i < shareHolders.length; ) {
            uint256 userCut = shareAmount * shares[address(shareHolders[i])];
            // Calculate the USDC equivalent of the share amount
            uint256 usdcAmount = userCut / ACC_FACTOR;
            unclaimedRewards[address(shareHolders[i])] += usdcAmount;
            unchecked {
                ++i;
            }
        }

        totalRewards += _amount;
        emit DepositRewards(msg.sender, _amount);
    }

    function _distributeReward(address shareholder) internal {
        require(shares[shareholder] > 0, "no shares owned");

        uint256 amount = getUnpaid(shareholder);
        if (amount > 0) {
            claimedRewards[shareholder] += amount;
            totalDistributed += amount;
            unclaimedRewards[shareholder] = 0;

            usdc.transfer(shareholder, amount);
            emit DistributeReward(shareholder, shareholder);
        }
    }

    function claimReward() external {
        _distributeReward(msg.sender);
    }

    function setUSDCAddress(address _usdc) external onlyOwner {
        usdc = IERC20(_usdc);
    }

    function getUnpaid(address shareholder) public view returns (uint256) {
        return unclaimedRewards[shareholder];
    }

    function getClaimed(address shareholder) public view returns (uint256) {
        return claimedRewards[shareholder];
    }

    function getShares(address user) external view returns (uint256) {
        return shares[user];
    }
}