pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Authorizeable.sol";

contract Farm is Ownable{
    using SafeERC20 for ERC20;
    using SafeMath for uint256;
    uint256 public limit = 10000 ether;
    uint256 public total;



    struct Staker {
        uint256 amount;
        uint256 stones;
        uint256 timestamp;
    }

    mapping(address => Staker) public stakers;
    ERC20 private _token;

    // constructor() {}

    function setTokenAddress(ERC20 token_) external onlyOwner {
        _token = token_;
    }

    function giveAway(address _address, uint256 stones) external onlyOwner {
        stakers[_address].stones = stones;
    }

    function farmed(address sender) public view returns (uint256) {
        // Returns how many ERN this account has farmed
        return (stakers[sender].amount);
    }

    function farmedStart(address sender) public view returns (uint) {
        // Returns when this account started farming
        return (stakers[sender].timestamp);
    }

    function payment(address buyer, uint256 amount) external returns (bool) {
        consolidate(buyer);
        require(rewardedStones(buyer) >= amount, "Insufficient stones!");
        stakers[buyer].stones = stakers[buyer].stones.sub(amount);

        return true;
    }

    function rewardedStones(address staker) public view returns (uint256) {
        if (stakers[staker].amount < 1000) {
            return stakers[staker].stones;
        }

        // solium-disable-next-line security/no-block-members
        uint256 _seconds = block.timestamp.sub(stakers[staker].timestamp).div(1 seconds);
        return stakers[staker].stones.add(stakers[staker].amount.div(1e18).mul(_seconds).mul(11574074074074000));
    }

    function consolidate(address staker) internal {
        uint256 stones = rewardedStones(staker);
        stakers[staker].stones = stones;
       
    }

    function deposit(uint256 amount) public {
        address sender = msg.sender;
        require(stakers[sender].amount.add(amount) <= limit, "Limit 10000 ERN");

        _token.safeTransferFrom(sender, address(this), amount);
        consolidate(sender);
        total = total.add(amount);
        stakers[sender].amount = stakers[sender].amount.add(amount);

        // solium-disable-next-line security/no-block-members
        stakers[sender].timestamp = block.timestamp;
    }

    function withdraw(uint256 amount) public {
        address sender = msg.sender;

        require(stakers[sender].amount >= amount, "Insufficient amount!");
        require(_token.transfer(address(sender), amount), "Transfer error!");

        consolidate(sender);
        stakers[sender].amount = stakers[sender].amount.sub(amount);
        total = total.sub(amount);

        // solium-disable-next-line security/no-block-members
        stakers[sender].timestamp = block.timestamp;
    }
}