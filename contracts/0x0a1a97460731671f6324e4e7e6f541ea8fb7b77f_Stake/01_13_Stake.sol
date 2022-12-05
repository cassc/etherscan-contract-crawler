pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Stake is IERC721Receiver, Ownable, ReentrancyGuard {
    IERC20 public coinAddress;
    IERC721 public NFTcontract;
    bool public locked;
    uint256 minimumStakeTimeS;
    uint256 coinPerS;

    struct StakeInfo {
        address staker;
        uint256 stakedAt;
    }

    mapping(uint256 => StakeInfo) stakers;

    event Staked(uint256 indexed tokenId, uint256 time, address indexed user);

    event Unstaked(uint256 indexed tokenId, uint256 time, address indexed user);

    event UserEmergencyWithdraw(
        uint256 indexed tokenId,
        uint256 time,
        address indexed user
    );

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    constructor(IERC20 coin, IERC721 nft) {
        coinAddress = coin;
        NFTcontract = nft;
        locked = true;
    }

    function stake(uint256 tokenId) internal {
        require(!locked, "Contract locked");
        require(NFTcontract.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(stakers[tokenId].staker == address(0), "Already being staked");

        stakers[tokenId].staker = msg.sender;
        stakers[tokenId].stakedAt = block.timestamp;
        NFTcontract.safeTransferFrom(msg.sender, address(this), tokenId);
        emit Staked(tokenId, block.timestamp, msg.sender);
    }

    function batchStake(
        uint256[] memory _calldata
    ) external nonReentrant callerIsUser {
        for (uint256 i = 0; i < _calldata.length; ++i) {
            stake(_calldata[i]);
        }
    }

    function unstake(uint256 tokenId) internal {
        require(!locked, "Contract locked");
        require(
            stakers[tokenId].staker == msg.sender,
            "Not being staked by you"
        );
        require(
            (block.timestamp - stakers[tokenId].stakedAt) > minimumStakeTimeS,
            "Not staked long enough"
        );
        uint256 reward = (block.timestamp - stakers[tokenId].stakedAt) *
            coinPerS;

        delete stakers[tokenId];
        SafeERC20.safeTransfer(coinAddress, msg.sender, reward);
        NFTcontract.safeTransferFrom(address(this), msg.sender, tokenId);
        emit Unstaked(tokenId, block.timestamp, msg.sender);
    }

    function batchUnstake(
        uint256[] memory _calldata
    ) external nonReentrant callerIsUser {
        for (uint256 i = 0; i < _calldata.length; ++i) {
            unstake(_calldata[i]);
        }
    }

    function userEmergencyWithdraw(
        uint256 tokenId
    ) external nonReentrant callerIsUser {
        require(
            stakers[tokenId].staker == msg.sender,
            "Not being staked by you"
        );
        delete stakers[tokenId];
        NFTcontract.safeTransferFrom(address(this), msg.sender, tokenId);
        emit UserEmergencyWithdraw(tokenId, block.timestamp, msg.sender);
    }

    function toggleLock() external onlyOwner {
        locked = !locked;
    }

    function emergencyWithdrawCoin() external onlyOwner {
        SafeERC20.safeTransfer(
            coinAddress,
            msg.sender,
            coinAddress.balanceOf(address(this))
        );
    }

    function emergencyWithdrawNFTs(uint256[] memory tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; ++i) {
            delete stakers[tokens[i]];
            NFTcontract.safeTransferFrom(address(this), msg.sender, tokens[i]);
            emit UserEmergencyWithdraw(tokens[i], block.timestamp, msg.sender);
        }
    }

    function setMinimumStakeTime(uint64 minTime) external onlyOwner {
        minimumStakeTimeS = minTime;
    }

    function setCoinPerS(uint256 _coinPerS) external onlyOwner {
        coinPerS = _coinPerS;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function stakeInfo(
        uint256 tokenId
    ) external view returns (address, uint256) {
        return (stakers[tokenId].staker, stakers[tokenId].stakedAt);
    }
}