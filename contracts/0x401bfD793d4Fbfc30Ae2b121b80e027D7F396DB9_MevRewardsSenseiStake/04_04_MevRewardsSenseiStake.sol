//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MevRewardsSenseiStake is Ownable, ReentrancyGuard {
    
    /// @notice claimable eth per eoa or smart contract for external validators
    mapping(address => uint256) public balance;

    /// @notice senseistake tokenId mapping to owner
    /// @dev used for determining if there was a transfer made in senseistake contract
    /// if it was we need to assure that the balance has not an old owner balance
    mapping(uint256 => address) public nftOwner;

    /// @notice address used for senseinode fees
    address payable public immutable senseiRewards;

    /// @notice rewards struct for updating balance variable
    struct Reward {
        address to;
        uint256 amount;
    }

    /// @notice nft owner struct for updating nft ownership
    struct NFTOwner {
        uint256 tokenId;
        address owner;
    }

    event Claimed(address indexed owner, uint256 amount);

    error BalancesMismatch(uint256 expected, uint256 provided);
    error ErrorSendingETH();
    error InvalidAddress();
    error NotEnoughBalance();
    error NothingToDistribute();

    /// @notice receive callback
    receive() external payable {}

    /// @notice senseinode fee wallet address
    /// @param _senseiRewards address to send eth to
    constructor(address _senseiRewards) {
        if (_senseiRewards == address(0)) {
            revert InvalidAddress();
        }
        senseiRewards = payable(_senseiRewards);
    }

    /// @notice for checking real claimable amount of address
    /// @param owner address to check amount claimable
    function claimableAmount(address owner) external view returns (uint256) {
        uint256 fee = balance[owner] * 10 / 100;
        uint256 amount = balance[owner] - fee;
        return amount;
    }

    /// @notice allows eoa or contract to claim mev rewards
    function claim() external nonReentrant {
        uint256 fee = balance[msg.sender] * 10 / 100;
        uint256 amount = balance[msg.sender] - fee;
        if (amount == 0) {
            revert NotEnoughBalance();
        }
        balance[msg.sender] = 0;
        bool ok = payable(msg.sender).send(amount);
        if (!ok) {
            revert ErrorSendingETH();
        }
        bool ok_fee = senseiRewards.send(fee);
        if (!ok_fee) {
            revert ErrorSendingETH();
        }
        emit Claimed(msg.sender, amount);
    }

    /// @notice allows to claim mev rewards from another eoa or contract
    /// @param _owner eoa/contract address to whom send the rewards
    function claimTo(address _owner) external nonReentrant {
        if (_owner == address(0)) {
            revert InvalidAddress();
        }
        uint256 fee = balance[_owner] * 10 / 100;
        uint256 amount = balance[_owner] - fee;
        if (amount == 0) {
            revert NotEnoughBalance();
        }
        balance[_owner] = 0;
        bool ok = payable(_owner).send(amount);
        if (!ok) {
            revert ErrorSendingETH();
        }
        bool ok_fee = senseiRewards.send(fee);
        if (!ok_fee) {
            revert ErrorSendingETH();
        }
        emit Claimed(_owner, amount);
    }

    /// @notice function called to increase balance variable
    /// @dev it is used for distributing mev rewards into all eoas or contracts
    /// @param _rewards array of structs of rewards to be added to balances for current period
    /// @param _total the total amount of eth to distribute
    function distribute(Reward[] calldata _rewards, uint256 _total) external onlyOwner {
        if (_total == 0) {
            revert NothingToDistribute();
        }
        if (address(this).balance < _total) {
            revert BalancesMismatch({ expected: address(this).balance, provided: _total });
        }
        for (uint256 i = 0; i < _rewards.length; ) {
            balance[_rewards[i].to] = _rewards[i].amount;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice function for adding current ownership status of senseistake tokenId
    /// @param _nftOwner struct array containig all ownsership updates
    function setNFTOwner(NFTOwner[] calldata _nftOwner) external onlyOwner {
        for (uint256 i = 0; i < _nftOwner.length; ) {
            nftOwner[_nftOwner[i].tokenId] = _nftOwner[i].owner;
            unchecked {
                ++i;
            }
        }
    }
}