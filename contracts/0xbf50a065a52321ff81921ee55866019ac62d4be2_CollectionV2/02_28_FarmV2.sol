// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FarmV2 is AccessControl {
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    uint256 public limit = 10000 ether;
    uint256 public total;

    bytes32 public constant COLLECTION_ROLE =
        bytes32(keccak256("COLLECTION_ROLE"));

    struct Staker {
        uint256 amount;
        uint256 stones;
        uint256 timestamp;
    }

    mapping(address => Staker) public stakers;
    ERC20 private _token;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setTokenAddress(ERC20 token_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _token = token_;
    }

    function giveAway(address _address, uint256 stones)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        stakers[_address].stones = stones;
    }

    function farmed(address sender) public view returns (uint256) {
        // Returns how many ERN this account has farmed
        return (stakers[sender].amount);
    }

    function farmedStart(address sender) public view returns (uint256) {
        // Returns when this account started farming
        return (stakers[sender].timestamp);
    }

    function payment(address buyer, uint256 amount)
        public
        onlyRole(COLLECTION_ROLE)
        returns (bool)
    {
        consolidate(buyer);

        require(rewardedStones(buyer) >= amount, "Insufficient stones!");

        stakers[buyer].stones = stakers[buyer].stones.sub(amount);
        stakers[buyer].timestamp = block.timestamp;

        return true;
    }

    function rewardedStones(address staker) public view returns (uint256) {
        if (stakers[staker].amount < 1000) {
            return stakers[staker].stones;
        }

        // solium-disable-next-line security/no-block-members
        uint256 _seconds = block.timestamp.sub(stakers[staker].timestamp).div(
            1 seconds
        );

        return
            stakers[staker].stones.add(
                stakers[staker].amount.div(1e18).mul(_seconds).mul(
                    11574074074074000
                )
            );
    }

    function consolidate(address staker) internal {
        uint256 stones = rewardedStones(staker);
        stakers[staker].stones = stones;
    }

    function deposit(uint256 amount) public {
        address account = msg.sender;

        require(_token.balanceOf(account) > 0, "your balance is insufficient");
        require(
            stakers[account].amount.add(amount) <= limit,
            "Limit 10000 ERN"
        );

        _token.safeTransferFrom(account, address(this), amount);
        consolidate(account);
        total = total.add(amount);
        stakers[account].amount = stakers[account].amount.add(amount);

        // solium-disable-next-line security/no-block-members
        stakers[account].timestamp = block.timestamp;
    }

    function withdraw(uint256 amount) public {
        address account = msg.sender;
        //require(account == msg.sender,"you are not authorized on this account!");
        require(stakers[account].amount >= amount, "Insufficient amount!");
        require(_token.transfer(account, amount), "Transfer error!");

        consolidate(account);
        stakers[account].amount = stakers[account].amount.sub(amount);
        total = total.sub(amount);

        // solium-disable-next-line security/no-block-members
        stakers[account].timestamp = block.timestamp;
    }

    function sell(
        uint256 stones,
        address from,
        address to
    ) public {
        require(
            hasRole(COLLECTION_ROLE, msg.sender),
            "you are not authorized on this account!"
        );

        consolidate(from);

        require(rewardedStones(from) >= stones, "Insufficient stones!");

        stakers[from].stones = stakers[from].stones.sub(stones);
        stakers[from].timestamp = block.timestamp;

        stakers[to].stones = stakers[to].stones.add(stones);
        stakers[to].timestamp = block.timestamp;
    }
}