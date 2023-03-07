// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//import "../_external/IWETH.sol";

import "../IUSDI.sol";

import "./IVault.sol";
import "./IVaultController.sol";
import "./VotingVaultController.sol";

import "../_external/CompLike.sol";
import "../_external/IERC20.sol";
import "../_external/Context.sol";
import "../_external/openzeppelin/SafeERC20Upgradeable.sol";

import "../_external/balancer/IGauge.sol";

import "hardhat/console.sol";

interface IRewardsPool {
  function stakeAll() external returns (bool);

  function getReward() external returns (bool);

  function getReward(address _account, bool _claimExtras) external returns (bool);

  function withdrawAll(bool claim) external;

  function withdrawAllAndUnwrap(bool claim) external;

  function balanceOf(address target) external view returns (uint256);

  function pid() external view returns (uint256);

  function extraRewardsLength() external view returns (uint256);

  function extraRewards(uint256 idx) external view returns (address);

  function rewardToken() external view returns (address);
}

interface IVirtualRewardPool {
  function getReward() external;

  function balanceOf(address target) external view returns (uint256);

  function rewardToken() external view returns (address);
}

interface IBooster {
  function depositAll(uint256 _pid, bool _stake) external returns (bool);
}

contract VaultBPT is Context {
  using SafeERC20Upgradeable for IERC20;

  /// @title VaultInfo struct
  /// @notice This vault holds the underlying token
  /// @notice The Capped token is held by the parent vault
  /// @notice Withdrawls must be initiated by the withdrawErc20() function on the parent vault

  /// @notice this struct is used to store the vault metadata
  /// this should reduce the cost of minting by ~15,000
  /// by limiting us to max 2**96-1 vaults
  struct VaultInfo {
    uint96 id;
    address vault_address;
  }
  /// @notice Metadata of vault, aka the id & the minter's address
  VaultInfo public _vaultInfo;

  VotingVaultController public _votingController;
  IVaultController public _controller;

  /// @notice if staked, then underlying is not in the vault so we need to unstake
  /// all assets stake all or nothing
  mapping(address => bool) public isStaked;

  mapping(address => stakeType) public typeOfStake;

  mapping(address => address) public lp_rewardtoken;

  enum stakeType {
    AURABAL,
    AURA_LP,
    BAL_LP
  }

  /// @notice checks if _msgSender is the controller of the voting vault
  modifier onlyVotingVaultController() {
    require(_msgSender() == address(_votingController), "sender not VotingVaultController");
    _;
  }
  /// @notice checks if _msgSender is the controller of the vault
  modifier onlyVaultController() {
    require(_msgSender() == address(_controller), "sender not VaultController");
    _;
  }
  /// @notice checks if _msgSender is the minter of the vault
  modifier onlyMinter() {
    require(_msgSender() == IVault(_vaultInfo.vault_address).minter(), "sender not minter");
    _;
  }

  /// @notice must be called by VotingVaultController, else it will not be registered as a vault in system
  /// @param id_ is the shared ID of both the voting vault and the standard vault
  /// @param vault_address address of the vault this is attached to
  /// @param controller_address address of the vault controller
  /// @param voting_controller_address address of the voting vault controller
  constructor(
    uint96 id_,
    address vault_address,
    address controller_address,
    address voting_controller_address //address _auraBal
  ) {
    _vaultInfo = VaultInfo(id_, vault_address);
    _controller = IVaultController(controller_address);
    _votingController = VotingVaultController(voting_controller_address);
  }

  function parentVault() external view returns (address) {
    return address(_vaultInfo.vault_address);
  }

  /// @notice id of the vault
  /// @return address of minter
  function id() external view returns (uint96) {
    return _vaultInfo.id;
  }

  /** auraBal && aura LP token staking */
  ///@param lp underlying lp
  function stakeAuraLP(IERC20 lp) external returns (bool) {
    require(isStaked[address(lp)] == false, "already staked");
    isStaked[address(lp)] = true;

    //stake auraBal directly on rewards pool
    if (address(lp) == _votingController._auraBal()) {
      (address rewardsToken, ) = _votingController.getAuraLpData(address(lp));
      IRewardsPool rp = IRewardsPool(rewardsToken);
      lp.approve(rewardsToken, lp.balanceOf(address(this)));

      require(rp.stakeAll(), "auraBal staking failed");
      return true;
    }

    //else we stake other LPs via booster contract
    IBooster booster = IBooster(_votingController._auraBooster());

    (, uint256 pid) = _votingController.getAuraLpData(address(lp));

    //approve booster
    lp.approve(address(booster), lp.balanceOf(address(this)));

    //deposit via booster
    require(booster.depositAll(pid, true), "Deposit failed");
    return true;
  }

  /// @param lp - the aura LP token address, or auraBal address
  /// @param claimExtra - claim extra token rewards, uses more gas
  function claimAuraLpRewards(IERC20 lp, bool claimExtra) external {
    //get rewards pool
    (address rewardsToken, ) = _votingController.getAuraLpData(address(lp));

    IRewardsPool rp = IRewardsPool(rewardsToken);

    rp.getReward(address(this), claimExtra);

    address minter = IVault(_vaultInfo.vault_address).minter();

    //send rewards to minter
    IERC20 rewardToken = IERC20(rp.rewardToken());
    rewardToken.transfer(minter, rewardToken.balanceOf(address(this)));

    if (claimExtra) {
      for (uint256 i = 0; i < rp.extraRewardsLength(); i++) {
        IVirtualRewardPool extraRewardPool = IVirtualRewardPool(rp.extraRewards(i));

        IERC20 extraRewardToken = IERC20(extraRewardPool.rewardToken());

        extraRewardPool.getReward();

        extraRewardToken.transfer(minter, extraRewardToken.balanceOf(address(this)));
      }
    }
    // if an underlying reward or extra reward token is used as collateral,
    // claiming rewards will empty the vault of this token, this check prevents this
    // if it is the case that the underlying reward token is registered collateral held by this vault
    // the liability will need to be repaid sufficiently in order to claim rewards
    require(_controller.checkVault(_vaultInfo.id), "Claim causes insolvency");
  }

  /// @notice manual unstake
  function unstakeAuraLP(IERC20 lp) external onlyMinter {
    //_unstakeAuraLP(lp);
  }

  function _unstakeAuraLP(IERC20 lp, bool auraBal) internal {
    isStaked[address(lp)] = false;
    (address rewardsToken, ) = _votingController.getAuraLpData(address(lp));
    IRewardsPool rp = IRewardsPool(rewardsToken);

    if (auraBal) {
      rp.withdrawAll(false);
    } else {
      rp.withdrawAllAndUnwrap(false);
    }
  }

  /**Balancer LP token staking */
  ///@notice claim rewards to the vault minter
  ///todo TX: https://etherscan.io/tx/0x4d5950df8da6b93a435a9b9762a3e54745bc4e67adbfcab3ebf459beb9baaf52
  function claimRewards(IGauge gauge) external {
    gauge.claim_rewards(address(this), IVault(_vaultInfo.vault_address).minter());
  }

  /// @notice function used by the VaultController to transfer tokens
  /// callable by the VaultController only
  /// not currently in use, available for future upgrades
  /// @param _token token to transfer
  /// @param _to person to send the coins to
  /// @param _amount amount of coins to move
  function controllerTransfer(
    address _token,
    address _to,
    uint256 _amount
  ) external onlyVaultController {
    if (isStaked[_token] == true) {
      _unstakeAuraLP(IERC20(_token), (_token == _votingController._auraBal()));
    }

    SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _to, _amount);
  }

  /// @notice function used by the VotingVaultController to transfer tokens
  /// callable by the VotingVaultController only
  /// @param _token token to transfer
  /// @param _to person to send the coins to
  /// @param _amount amount of coins to move
  function votingVaultControllerTransfer(
    address _token,
    address _to,
    uint256 _amount
  ) external onlyVotingVaultController {
    if (isStaked[_token] == true) {
      _unstakeAuraLP(IERC20(_token), (_token == _votingController._auraBal()));
    }

    SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_token), _to, _amount);
  }
}