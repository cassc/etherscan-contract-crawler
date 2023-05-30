// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SeedToken is ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    modifier onlyAllowed(address _allowed) {
        require(
            _msgSender() == owner() || _msgSender() == _allowed,
            "not-authorized"
        );
        _;
    }

    address public minter; // breeder contract
    address public treasury; // team reserves wallet
    address public playerRewards; // play to earn rewards wallet

    uint256 public immutable tokenStart;
    uint256 public treasuryClaimed;
    uint256 public treasuryAmount = 5_406_500 * (10**18);
    uint256 public treasuryDuration = (365 days) * 2;

    uint256 public playerRewardsClaimed;
    uint256 public playerRewardsAmount = 54_060_555 * (10**18);
    uint256 public playerRewardsDuration = (365 days) * 10;

    event UpdatedMinter(
        address indexed previousMinter,
        address indexed newMinter
    );
    event UpdatedTreasury(
        address indexed previousTreasury,
        address indexed newTreasury
    );
    event UpdatedPlayerRewards(
        address indexed previousPlayerRewards,
        address indexed newPlayerRewards
    );

    //solhint-disable no-empty-blocks
    constructor() ERC20("Birdez Gang Seed", "SEED") {
        tokenStart = block.timestamp;
    }

    modifier onlyMinter() {
        require(_msgSender() == minter, "caller-is-not-minter");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    function burn(address _to, uint256 _amount) external onlyMinter {
        _burn(_to, _amount);
    }

    function updateMinter(address _newMinter) external onlyOwner {
        require(_newMinter != address(0), "minter-address-is-zero");
        require(minter != _newMinter, "same-minter");
        emit UpdatedMinter(minter, _newMinter);
        minter = _newMinter;
    }

    function updateTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "treasury-address-is-zero");
        require(treasury != _newTreasury, "same-treasury");
        emit UpdatedTreasury(treasury, _newTreasury);
        treasury = _newTreasury;
    }

    function updatePlayerRewards(address _playerRewards) external onlyOwner {
        require(_playerRewards != address(0), "rewards-address-is-zero");
        require(playerRewards != _playerRewards, "same-rewards");
        emit UpdatedPlayerRewards(playerRewards, _playerRewards);
        playerRewards = _playerRewards;
    }

    function pendingTreasury() public view returns (uint256) {
        uint256 _trasuryPerSec = treasuryAmount / treasuryDuration;
        uint256 _elapsed = block.timestamp - tokenStart;
        uint256 _pending = (_trasuryPerSec * _elapsed) - treasuryClaimed;
        if (_pending + treasuryClaimed > treasuryAmount) {
            _pending = treasuryAmount - treasuryClaimed;
        }
        return _pending;
    }

    function pendingPlayerRewards() public view returns (uint256) {
        uint256 _trasuryPerSec = playerRewardsAmount / playerRewardsDuration;
        uint256 _elapsed = block.timestamp - tokenStart;
        uint256 _pending = (_trasuryPerSec * _elapsed) - playerRewardsClaimed;
        if (_pending + playerRewardsClaimed > playerRewardsAmount) {
            _pending = playerRewardsAmount - playerRewardsClaimed;
        }
        return _pending;
    }

    function claimTreasury() external onlyAllowed(treasury) {
        require(playerRewards != address(0), "player-rewards-not-set");
        uint256 _pending = pendingTreasury();
        if (_pending != 0) {
            treasuryClaimed += _pending;
            _mint(treasury, _pending);
        }
    }

    function claimPlayerRewards() external onlyAllowed(playerRewards) {
        require(playerRewards != address(0), "player-rewards-not-set");
        uint256 _pending = pendingPlayerRewards();
        if (_pending != 0) {
            playerRewardsClaimed += _pending;
            _mint(playerRewards, _pending);
        }
    }
}