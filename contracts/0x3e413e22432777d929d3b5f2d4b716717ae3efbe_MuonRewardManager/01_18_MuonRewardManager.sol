// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBondedToken.sol";

contract MuonRewardManager is
    Initializable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    using ECDSA for bytes32;

    struct User {
        uint256 rewardAmount;
        uint256 tokenId;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REWARD_ROLE = keccak256("REWARD_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public totalReward;

    IERC20 public muonToken;
    IBondedToken public bondedToken;

    mapping(address => User) public users;

    // ======== Events ========
    event RewardClaimed(
        address indexed claimer,
        uint256 rewardAmount,
        uint256 indexed tokenId
    );

    /**
     * @dev Initializes the contract.
     * @param _muonTokenAddress The address of the Muon token.
     * @param _bondedTokenAddress The address of the BondedToken contract.
     */
    function initialize(address _muonTokenAddress, address _bondedTokenAddress)
        external
        initializer
    {
        __MuonRewardManager_init(_muonTokenAddress, _bondedTokenAddress);
    }

    function __MuonRewardManager_init(
        address _muonTokenAddress,
        address _bondedTokenAddress
    ) internal initializer {
        __AccessControl_init();
        __Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);

        muonToken = IERC20(_muonTokenAddress);
        bondedToken = IBondedToken(_bondedTokenAddress);
    }

    function __MuonRewardManager_init_unchained() internal initializer {}

    function claimReward(uint256 rewardAmount, bytes memory signature)
        external
        whenNotPaused
        returns (uint256)
    {
        require(users[msg.sender].tokenId == 0, "Already claimed the reward.");

        bytes32 messageHash = keccak256(
            abi.encodePacked(msg.sender, rewardAmount)
        );
        address signer = messageHash.recover(signature);
        require(hasRole(REWARD_ROLE, signer), "Invalid signature.");

        require(
            muonToken.approve(address(bondedToken), rewardAmount),
            "Failed to approve to the bondedToken contract."
        );

        address[] memory tokens = new address[](1);
        tokens[0] = address(muonToken);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = rewardAmount;

        uint256 tokenId = bondedToken.mintAndLock(tokens, amounts, msg.sender);

        users[msg.sender].rewardAmount = rewardAmount;
        users[msg.sender].tokenId = tokenId;

        totalReward += rewardAmount;

        emit RewardClaimed(msg.sender, rewardAmount, tokenId);

        return tokenId;
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function withdraw(
        address tokenAddress,
        uint256 amount,
        address to
    ) external onlyRole(ADMIN_ROLE) {
        require(to != address(0));

        if (tokenAddress == address(0)) {
            payable(to).transfer(amount);
        } else {
            IERC20(tokenAddress).transfer(to, amount);
        }
    }
}