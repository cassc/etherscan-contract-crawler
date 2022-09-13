// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./interfaces/IMintBurnableERC20.sol";
import "./ConfigHelper.sol";
import "./AlloyxConfig.sol";
import "./AdminUpgradeable.sol";

/**
 * @title StakeDesk
 * @notice All transactions or statistics related to staking
 * @author AlloyX
 */
contract StakeDesk is IStableCoinDesk, AdminUpgradeable {
  using SafeERC20Upgradeable for IMintBurnableERC20;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using SafeMath for uint256;

  AlloyxConfig public config;
  using ConfigHelper for AlloyxConfig;

  event Reward(address _tokenReceiver, uint256 _tokenAmount);
  event Claim(address _tokenReceiver, uint256 _tokenAmount);
  event Stake(address _staker, uint256 _amount);
  event Unstake(address _unstaker, uint256 _amount);
  event WithdrawGfiFromPoolTokens(uint256 _tokenID);
  event AlloyxConfigUpdated(address indexed who, address configAddress);

  function initialize(address _configAddress) external initializer {
    __AdminUpgradeable_init(msg.sender);
    config = AlloyxConfig(_configAddress);
  }

  /**
   * @notice If user operation is paused
   */
  modifier isPaused() {
    require(config.isPaused(), "all user operations should be paused");
    _;
  }

  /**
   * @notice If operation is not paused
   */
  modifier notPaused() {
    require(!config.isPaused(), "the user operation should be unpaused first");
    _;
  }

  /**
   * @notice Update configuration contract address
   */
  function updateConfig() external onlyAdmin isPaused {
    config = AlloyxConfig(config.configAddress());
    emit AlloyxConfigUpdated(msg.sender, address(config));
  }

  /**
   * @notice Total claimable and claimed CRWN tokens of all stakeholders
   */
  function totalClaimableAndClaimedCRWNToken() public view returns (uint256) {
    return
      config.getAlloyxStakeInfo().totalClaimableCRWNToken().add(config.getCRWN().totalSupply());
  }

  /**
   * @notice Stake more into the vault, which will cause the user's DURA token to transfer to treasury
   * @param _amount the amount the message sender intending to stake in
   */
  function stake(uint256 _amount) external notPaused {
    config.getAlloyxStakeInfo().addStake(msg.sender, _amount);
    config.getTreasury().transferERC20From(
      msg.sender,
      config.duraAddress(),
      config.treasuryAddress(),
      _amount
    );
    emit Stake(msg.sender, _amount);
  }

  /**
   * @notice Unstake some from the vault, which will cause the vault to transfer DURA token back to message sender
   * @param _amount the amount the message sender intending to unstake
   */
  function unstake(uint256 _amount) external notPaused {
    config.getAlloyxStakeInfo().removeStake(msg.sender, _amount);
    config.getTreasury().transferERC20(config.duraAddress(), msg.sender, _amount);
    emit Unstake(msg.sender, _amount);
  }

  /**
   * @notice Claim all alloy CRWN tokens of the message sender, the method will mint the CRWN token of the claimable
   * amount to message sender, and clear the past rewards to zero
   */
  function claimAllAlloyxCRWN() external notPaused returns (bool) {
    uint256 reward = config.getAlloyxStakeInfo().claimableCRWNToken(msg.sender);
    config.getCRWN().mint(msg.sender, reward);
    config.getAlloyxStakeInfo().resetStakeTimestampWithRewardLeft(msg.sender, 0);
    emit Claim(msg.sender, reward);
    return true;
  }

  /**
   * @notice Claim certain amount of alloy CRWN tokens of the message sender, the method will mint the CRWN token of
   * the claimable amount to message sender, and clear the past rewards to the remainder
   * @param _amount the amount to claim
   */
  function claimAlloyxCRWN(uint256 _amount) external notPaused returns (bool) {
    uint256 allReward = config.getAlloyxStakeInfo().claimableCRWNToken(msg.sender);
    require(allReward >= _amount, "User has claimed more than he's entitled");
    config.getCRWN().mint(msg.sender, _amount);
    config.getAlloyxStakeInfo().resetStakeTimestampWithRewardLeft(
      msg.sender,
      allReward.sub(_amount)
    );
    emit Claim(msg.sender, _amount);
    return true;
  }

  /**
   * @notice Claim certain amount of reward token based on alloy CRWN token, the method will burn the CRWN token of
   * the amount of message sender, and transfer reward token to message sender
   * @param _amount the amount to claim
   */
  function claimReward(uint256 _amount) external notPaused returns (bool) {
    (uint256 amountToReward, uint256 fee) = getRewardTokenCount(_amount);
    config.getTreasury().transferERC20(config.gfiAddress(), msg.sender, amountToReward.sub(fee));
    config.getTreasury().addEarningGfiFee(fee);
    config.getCRWN().burn(msg.sender, _amount);
    emit Reward(msg.sender, _amount);
    return true;
  }

  /**
   * @notice Widthdraw GFI from pool token
   * @param _tokenID the ID of token to sell
   */
  function withdrawGfiFromPoolTokens(uint256 _tokenID) external onlyAdmin {
    config.getTreasury().transferERC721(config.poolTokensAddress(), address(this), _tokenID);
    config.getBackerRewards().withdraw(_tokenID);
    config.getPoolTokens().safeTransferFrom(address(this), config.treasuryAddress(), _tokenID);
    config.getGFI().safeTransfer(
      config.treasuryAddress(),
      config.getGFI().balanceOf(address(this))
    );
    emit WithdrawGfiFromPoolTokens(_tokenID);
  }

  /**
   * @notice Widthdraw GFI from pool token
   * @param _tokenIDs the IDs of token to sell
   */
  function withdrawGfiFromMultiplePoolTokens(uint256[] calldata _tokenIDs) external onlyAdmin {
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      config.getTreasury().transferERC721(config.poolTokensAddress(), address(this), _tokenIDs[i]);
    }
    config.getBackerRewards().withdrawMultiple(_tokenIDs);
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      config.getPoolTokens().safeTransferFrom(
        address(this),
        config.treasuryAddress(),
        _tokenIDs[i]
      );
    }
    config.getGFI().safeTransfer(
      config.treasuryAddress(),
      config.getGFI().balanceOf(address(this))
    );
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      emit WithdrawGfiFromPoolTokens(_tokenIDs[i]);
    }
  }

  /**
   * @notice Get reward token count if the amount of CRWN tokens are claimed
   * @param _amount the amount to claim
   */
  function getRewardTokenCount(uint256 _amount) public view returns (uint256, uint256) {
    uint256 amountToReward = _amount
      .mul(
        config.getGFI().balanceOf(config.treasuryAddress()).sub(
          config.getTreasury().getAllGfiFees()
        )
      )
      .div(totalClaimableAndClaimedCRWNToken());
    uint256 permillageCRWNEarning = config.getPermillageCRWNEarning();
    require(permillageCRWNEarning < 1000, "the permillage of CRWN earning is not smaller than 100");
    uint256 fee = amountToReward.mul(permillageCRWNEarning).div(1000);
    return (amountToReward, fee);
  }

  /**
   * @dev See {IERC721Receiver-onERC721Received}.
   *
   * Always returns `IERC721Receiver.onERC721Received.selector`.
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual returns (bytes4) {
    return this.onERC721Received.selector;
  }
}