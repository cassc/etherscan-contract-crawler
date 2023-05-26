// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IERC721AQueryable.sol";

contract Claim is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public treasury;
    address public immutable dhAddress;
    address public rewardDistributor;
    address public rewardToken;
    address public immutable strayDogzAddress;

    bool public claimsEnabled;

    uint256 public constant dhNFTSupply = 3333;
    uint256 public constant sharesPerDhNFT = 1;
    uint256 public constant sharesPerStrayDogzNFT = 5;
    uint256 public constant strayDogzNFTSupply = 7777;

    uint256 private scalingFactor = 10 ** 18;
    uint256 public rewardsPerDHNFT;
    uint256 public rewardsPerStrayDogzNFT;
    uint256 public totalClaims;
    uint256 public totalRewards;
    uint256 public totalShares = 42218; //strayDogzNFTSupply * 5 + dhNFTSupply;

    mapping(uint256 => uint256) public strayDogzNFTClaimed;
    mapping(uint256 => uint256) public dhNFTClaimed;

    error AddressIsZero(string name);
    error ClaimDisabled();
    error EmptyArrays();
    error FailedETHSend();
    error InvalidArrays();
    error InvalidDHNFTId(uint256 id);
    error InvalidStrayDogzNFTId(uint256 id);
    error NoRewardsToClaim();
    error NotDHNFTOwner(uint256 id);
    error NotRewardDistributor();
    error NotStrayDogzNFTOwner(uint256 id);

    event AddRewards(address indexed user, uint256 indexed amount);
    event ClaimRewards(address indexed user, uint256 indexed amount);
    event ClaimRewardByAddress(address indexed user, uint256 indexed amount);
    event RecoverTokens(address indexed msgSender, address indexed token);

    modifier NotZeroAddress(address _address) {
        if (_address == address(0)) revert AddressIsZero("_address");
        _;
    }

    modifier RewardDistributor(address _address) {
        if (_address != rewardDistributor && _address != owner())
            revert NotRewardDistributor();
        _;
    }

    constructor(
        address _treasury,
        address _rewardToken,
        address _strayDogzAddress,
        address _dhAddress
    )
        NotZeroAddress(_treasury)
        NotZeroAddress(_rewardToken)
        NotZeroAddress(_strayDogzAddress)
        NotZeroAddress(_dhAddress)
    {
        treasury = _treasury;
        rewardToken = _rewardToken;
        rewardDistributor = _rewardToken;

        strayDogzAddress = _strayDogzAddress;
        dhAddress = _dhAddress;
    }

    function addRewards(
        uint256 amount
    ) external RewardDistributor(_msgSender()) {
        IERC20(rewardToken).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
        totalRewards += amount;
        uint256 rewardsPerShare = (amount * scalingFactor) / totalShares;
        rewardsPerStrayDogzNFT +=
            (rewardsPerShare * sharesPerStrayDogzNFT) /
            scalingFactor;
        rewardsPerDHNFT += (rewardsPerShare * sharesPerDhNFT) / scalingFactor;
        emit AddRewards(_msgSender(), amount);
    }

    function claimAllRewards(
        uint256[] calldata strayDogsNftIds,
        uint256[] calldata dhNftIds
    ) external nonReentrant {
        if (!claimsEnabled) revert ClaimDisabled();
        if (strayDogsNftIds.length == 0 && dhNftIds.length == 0)
            revert EmptyArrays();

        uint256 amount;
        unchecked {
            uint256 _rewardsPerStrayDogzNFT = rewardsPerStrayDogzNFT;
            address _strayDogzAddress = strayDogzAddress;
            uint256 _counter = strayDogsNftIds.length;
            for (uint256 x; x < _counter; ) {
                uint256 id = strayDogsNftIds[x];
                if (IERC721(_strayDogzAddress).ownerOf(id) != _msgSender())
                    revert NotStrayDogzNFTOwner(id);
                amount += _rewardsPerStrayDogzNFT - strayDogzNFTClaimed[id];
                strayDogzNFTClaimed[id] = _rewardsPerStrayDogzNFT;
                ++x;
            }
        }
        unchecked {
            uint256 _rewardsPerDHNFT = rewardsPerDHNFT;
            address _dhAddress = dhAddress;
            uint256 _counter = dhNftIds.length;
            for (uint256 x; x < _counter; ) {
                uint256 id = dhNftIds[x];
                if (IERC721(_dhAddress).ownerOf(id) != _msgSender())
                    revert NotDHNFTOwner(id);
                amount += _rewardsPerDHNFT - dhNFTClaimed[id];
                dhNFTClaimed[id] = _rewardsPerDHNFT;
                ++x;
            }
        }

        if (amount == 0) revert NoRewardsToClaim();
        totalClaims += amount;
        IERC20(rewardToken).safeTransfer(_msgSender(), amount);
        emit ClaimRewards(_msgSender(), amount);
    }

    function claimRewardsInRange(
        uint256[] calldata strayDogzRange,
        uint256[] calldata dhNFTRange
    ) external nonReentrant {
        if (!claimsEnabled) revert ClaimDisabled();

        uint256 amount;
        if (strayDogzRange[0] > 0) {
            uint256[] memory strayDogsNftIds = IERC721AQueryable(
                strayDogzAddress
            ).tokensOfOwnerIn(
                    _msgSender(),
                    strayDogzRange[0],
                    strayDogzRange[1]
                );
            unchecked {
                uint256 _rewardsPerStrayDogzNFT = rewardsPerStrayDogzNFT;
                uint256 _counter = strayDogsNftIds.length;
                for (uint256 x; x < _counter; ) {
                    uint256 id = strayDogsNftIds[x];
                    amount += _rewardsPerStrayDogzNFT - strayDogzNFTClaimed[id];
                    strayDogzNFTClaimed[id] = _rewardsPerStrayDogzNFT;
                    ++x;
                }
            }
        }
        if (dhNFTRange[0] > 0) {
            uint256[] memory dhNftIds = IERC721AQueryable(dhAddress)
                .tokensOfOwnerIn(_msgSender(), dhNFTRange[0], dhNFTRange[1]);
            uint256 _rewardsPerDHNFT = rewardsPerDHNFT;
            uint256 _counter = dhNftIds.length;
            unchecked {
                for (uint256 x; x < _counter; ) {
                    uint256 id = dhNftIds[x];
                    amount += _rewardsPerDHNFT - dhNFTClaimed[id];
                    dhNFTClaimed[id] = _rewardsPerDHNFT;
                    ++x;
                }
            }
        }

        if (amount == 0) revert NoRewardsToClaim();
        totalClaims += amount;
        IERC20(rewardToken).safeTransfer(_msgSender(), amount);
        emit ClaimRewardByAddress(_msgSender(), amount);
    }

    function recoverTokens() external onlyOwner {
        IERC20(rewardToken).safeTransfer(
            _msgSender(),
            IERC20(rewardToken).balanceOf(address(this))
        );
        emit RecoverTokens(_msgSender(), address(this));
    }

    function rewards(
        uint256[] calldata strayDogsNftIds,
        uint256[] calldata dhNftIds
    ) external view returns (uint256, uint256) {
        if (strayDogsNftIds.length == 0 && dhNftIds.length == 0)
            revert EmptyArrays();

        uint256 amount;
        uint256 totalAmount;
        for (uint256 x; x < strayDogsNftIds.length; x++) {
            uint256 id = strayDogsNftIds[x];
            if (id > strayDogzNFTSupply) revert InvalidStrayDogzNFTId(id);
            totalAmount += rewardsPerStrayDogzNFT;
            amount += rewardsPerStrayDogzNFT - strayDogzNFTClaimed[id];
        }
        for (uint256 x; x < dhNftIds.length; x++) {
            uint256 id = dhNftIds[x];
            if (id > dhNFTSupply) revert InvalidDHNFTId(id);
            totalAmount += rewardsPerDHNFT;
            amount += rewardsPerDHNFT - dhNFTClaimed[id];
        }

        return (totalAmount, amount);
    }

    function setClaimsEnabled(bool value) external onlyOwner {
        claimsEnabled = value;
    }
}