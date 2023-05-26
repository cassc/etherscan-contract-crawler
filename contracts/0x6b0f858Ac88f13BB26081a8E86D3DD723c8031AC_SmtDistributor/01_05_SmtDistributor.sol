//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmtDistributor is Ownable {
    using SafeMath for uint256;

    struct Reward {
        address beneficiary;
        uint256 amount;
    }

    /// @dev Emitted when `beneficiary` claims its `reward`.
    event Claim(address indexed beneficiary, uint256 reward);

    /// @dev ERC20 basic token contract being held
    IERC20 public token;

    /// @dev Beneficiaries of reward tokens
    mapping(address => uint256) public beneficiaries;

    /**
     * @dev Sets the value for {token}.
     *
     * Sets ownership to the account that deploys the contract.
     *
     */
    constructor(address _token, address _owner) {
        require(_token != address(0), "token is the zero address");
        token = IERC20(_token);
        transferOwnership(_owner);
    }

    /**
     * @dev Deposits a new `totalAmount` to be claimed by beneficiaries distrubuted in `rewards`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     * - the accumulated rewards' amount should be equal to `totalAmount`.
     *
     * @param rewards Array indicating each benaficiary reward from the total to be deposited.
     * @param totalAmount Total amount to be deposited.
     */
    function depositRewards(Reward[] memory rewards, uint256 totalAmount) external onlyOwner returns (bool) {
        require(totalAmount > 0, "totalAmount is zero");
        require(rewards.length > 0, "rewards can not be empty");
        require(token.transferFrom(_msgSender(), address(this), totalAmount), "Transfer failed");

        uint256 accByRewards = 0;
        for (uint256 i = 0; i < rewards.length; i++) {
            Reward memory reward = rewards[i];
            accByRewards += reward.amount;
            beneficiaries[reward.beneficiary] += reward.amount;
        }

        require(accByRewards == totalAmount, "total amount mismatch");

        return true;
    }

    /**
     * @dev Claims beneficiary reward.
     */
    function claim() external returns (bool) {
        uint256 amount = beneficiaries[_msgSender()];
        require(amount > 0, "no rewards");
        beneficiaries[_msgSender()] = 0;

        emit Claim(_msgSender(), amount);

        require(token.transfer(_msgSender(), amount), "Transfer failed");
        return true;
    }
}