pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@nomiclabs/buidler/console.sol";

import "./interfaces/IVNFT.sol";

contract TokenRecover is Ownable {
    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        public
        onlyOwner
    {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}

contract Nanny is Ownable, TokenRecover {
    mapping(address => uint256) public fee;

    using SafeMath for uint256;
    IVNFT public vnft;
    IERC20 public muse;
    uint256 public gem;

    // overflow
    uint256 public MAX_INT = 2**256 - 1;

    constructor(
        IVNFT _vnft,
        IERC20 _muse,
        uint256 _gem
    ) public {
        vnft = _vnft;
        muse = _muse;
        gem = _gem;

        muse.approve(address(vnft), MAX_INT);
    }

    modifier canClaimRewards(uint256 petId) {
        uint256 lastTimeMined = vnft.lastTimeMined(petId);
        require(lastTimeMined + 1 days < now, "Can't mine yet");
        _;
    }

    function timeUntilReward(uint256 petId) public view returns (uint256) {
        uint256 lastTimeMined = vnft.lastTimeMined(petId);
        return lastTimeMined.add(1 days).sub(block.timestamp);
    }

    /**
        @notice Claim rewards and feed a pet if hungry, a % goes to the pet owner.
        @dev Original pet owner must add contract as care taker  
     */
    function claimRewards(uint256 petId) external canClaimRewards(petId) {
        uint256 _timeUntilStarving = vnft.timeUntilStarving(petId);

        vnft.claimMiningRewards(petId);

        if (
            _timeUntilStarving.sub(1 days) <= block.timestamp ||
            _timeUntilStarving == 0
        ) {
            vnft.buyAccesory(petId, gem);
        }

        uint256 feeAmount;
        if (fee[vnft.ownerOf(petId)] > 0) {
            feeAmount = muse
                .balanceOf(address(this))
                .mul(fee[vnft.ownerOf(petId)])
                .div(100);
        } else {
            // 5% default fee
            feeAmount = muse.balanceOf(address(this)).mul(5).div(100);
        }

        //transfer proceedings
        require(muse.transfer(vnft.ownerOf(petId), feeAmount));
        require(muse.transfer(msg.sender, muse.balanceOf(address(this))));
    }

    /**
        @notice feeding outide of strategy to increase levels
        @dev give contract MUSE allowance  
     */
    function feed(uint256 petId, uint256 gemId) external {
        uint256 price = vnft.itemPrice(gemId);
        require(muse.transferFrom(msg.sender, address(this), price));
        vnft.buyAccesory(petId, gemId);
    }

    // change default 5% fee for your specific pets.
    function setFee(uint256 _fee) external {
        require(_fee > 0 && _fee < 50);
        fee[msg.sender] = _fee;
    }

    //owner
    function setStrat(uint256 _id) external onlyOwner {
        gem = _id;
    }
}