pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SwampoGems is ERC20, Ownable {
    struct User {
        uint256 lastClaim;
        uint256 rate;
        bool claimed;
    }

    uint256 private constant DAY = 86400;
    uint256 private constant START_DATE = 1685573231; // May 31st 2023
    uint256 private constant INITIAL_RATE = 33;
    uint256 private constant DECREASE_RATE = 3;
    uint256 private constant INCREASE_RATE = 1;
    uint256 private constant NFT_INCREASE_RATE = 2;

    mapping(address => User) private users;

    IERC721 public nftContract;

    constructor(address _nftContract) ERC20("Swamp oGems", "SOGEM") {
        nftContract = IERC721(_nftContract);
    }

    function submitWallet(address wallet) public {
        require(users[wallet].lastClaim == 0, "Wallet already submitted");

        uint256 daysSinceStart = (block.timestamp - START_DATE) / DAY;
        uint256 rate = INITIAL_RATE - (daysSinceStart * DECREASE_RATE);
        users[wallet] = User(block.timestamp, rate, false);
    }

    function claimReward() external {
        User storage user = users[msg.sender];
        require(user.lastClaim != 0, "Wallet not submitted");
        uint256 daysSinceLastClaim = (block.timestamp - user.lastClaim) / DAY;
        uint256 reward = user.rate * DAY * daysSinceLastClaim;

        if (!user.claimed) {
            uint256 rateIncrease = daysSinceLastClaim * (userHasNFT(msg.sender) ? NFT_INCREASE_RATE : INCREASE_RATE);
            user.rate = user.rate + rateIncrease;
            user.claimed = true;
        }

        user.lastClaim = block.timestamp;
        _mint(msg.sender, reward);
    }

    function getUnclaimedoGems(address wallet) external view returns (uint256) {
        User storage user = users[wallet];
        require(user.lastClaim != 0, "Wallet not submitted");
        uint256 daysSinceLastClaim = (block.timestamp - user.lastClaim) / DAY;
        uint256 unclaimedoGems = user.rate * DAY * daysSinceLastClaim;
        return unclaimedoGems;
    }

    function userHasNFT(address wallet) private view returns (bool) {
        uint256 balance = nftContract.balanceOf(wallet);
        return balance > 0;
    }
}