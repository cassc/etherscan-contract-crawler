// SPDX-License-Identifier: MIT

//** Decubate Locking Contract */
//** Author Aaron & Vipin : Decubate Vesting Contract 2021.6 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDecubateVesting.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecubateVesting is IDecubateVesting, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /**
   *
   * @dev whitelistPools store all active whitelist members.
   *
   */

  MaxTokenTransferValue public maxTokenTransfer;
  VestingPool[] public vestingPools;

  IERC20 private _token;

  constructor(address token) {
    _token = IERC20(token);
  }

  modifier optionExists(uint256 _option) {
    require(_option < vestingPools.length, "Vesting option does not exist");
    _;
  }

  modifier userInWhitelist(uint256 _option, address _wallet) {
    require(_option < vestingPools.length, "Vesting option does not exist");
    require(
      vestingPools[_option].hasWhitelist[_wallet].active,
      "User is not in whitelist"
    );
    _;
  }

  function addVestingStrategy(
    string memory _name,
    uint256 _cliff,
    uint256 _start,
    uint256 _duration,
    uint256 _initialUnlockPercent,
    bool _revocable
  ) external override onlyOwner returns (bool) {
    VestingPool storage newStrategy = vestingPools.push();

    newStrategy.cliff = _start.add(_cliff);
    newStrategy.name = _name;
    newStrategy.start = _start;
    newStrategy.duration = _duration;
    newStrategy.initialUnlockPercent = _initialUnlockPercent;
    newStrategy.revocable = _revocable;

    return true;
  }

  function setVestingStrategy(
    uint256 _strategy,
    string memory _name,
    uint256 _cliff,
    uint256 _start,
    uint256 _duration,
    uint256 _initialUnlockPercent,
    bool _revocable
  ) external override onlyOwner returns (bool) {
    require(_strategy < vestingPools.length, "Strategy does not exist");

    VestingPool storage vest = vestingPools[_strategy];

    vest.cliff = _start.add(_cliff);
    vest.name = _name;
    vest.start = _start;
    vest.duration = _duration;
    vest.initialUnlockPercent = _initialUnlockPercent;
    vest.revocable = _revocable;

    return true;
  }

  function setMaxTokenTransfer(uint256 _amount, bool _active)
    external
    onlyOwner
    returns (bool)
  {
    maxTokenTransfer.amount = _amount;
    maxTokenTransfer.active = _active;
    return true;
  }

  function getAllVestingPools() external view returns (VestingInfo[] memory) {
    VestingInfo[] memory infoArr = new VestingInfo[](vestingPools.length);

    for (uint256 i = 0; i < vestingPools.length; i++) {
      infoArr[i] = getVestingInfo(i);
    }

    return infoArr;
  }

  /**
   *
   * @dev get vesting info
   *
   * @param {uint256} strategy of vesting info
   *
   * @return return vesting strategy
   *
   */
  function getVestingInfo(uint256 _strategy)
    public
    view
    optionExists(_strategy)
    returns (VestingInfo memory)
  {
    return
      VestingInfo({
        name: vestingPools[_strategy].name,
        cliff: vestingPools[_strategy].cliff,
        start: vestingPools[_strategy].start,
        duration: vestingPools[_strategy].duration,
        initialUnlockPercent: vestingPools[_strategy].initialUnlockPercent,
        revocable: vestingPools[_strategy].revocable
      });
  }

  /**
   *
   * @dev add the address to whitelist
   *
   * @param {address} address of the user
   *
   * @return {bool} return status of the whitelist
   *
   */
  function addWhitelist(
    address _wallet,
    uint256 _dcbAmount,
    uint256 _option
  ) public override onlyOwner optionExists(_option) returns (bool) {
    HasWhitelist storage whitelist = vestingPools[_option].hasWhitelist[
      _wallet
    ];
    require(!whitelist.active, "Whitelist already available");

    WhitelistInfo[] storage pool = vestingPools[_option].whitelistPool;

    whitelist.active = true;
    whitelist.arrIdx = pool.length;

    pool.push(
      WhitelistInfo({
        wallet: _wallet,
        dcbAmount: _dcbAmount,
        distributedAmount: 0,
        joinDate: block.timestamp,
        revoke: false,
        disabled: false
      })
    );

    emit AddWhitelist(_wallet);

    return true;
  }

  function batchAddWhitelist(
    address[] memory wallets,
    uint256[] memory amounts,
    uint256 option
  ) external onlyOwner returns (bool) {
    require(wallets.length == amounts.length, "Sizes of inputs do not match");

    for (uint256 i = 0; i < wallets.length; i++) {
      addWhitelist(wallets[i], amounts[i], option);
    }

    return true;
  }

  /**
   *
   * @dev set the address as whitelist user address
   *
   * @param {address} address of the user
   *
   * @return {bool} return status of the whitelist
   *
   */
  function setWhitelist(
    address _wallet,
    uint256 _dcbAmount,
    uint256 _option
  )
    external
    override
    onlyOwner
    userInWhitelist(_option, _wallet)
    returns (bool)
  {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo storage info = vestingPools[_option].whitelistPool[idx];
    info.dcbAmount = _dcbAmount;

    return true;
  }

  /**
   *
   * @dev set the address as whitelist user address
   *
   * @param {address} address of the user
   *
   * @return {Whitelist} return whitelist instance
   *
   */
  function getWhitelist(uint256 _option, address _wallet)
    external
    view
    userInWhitelist(_option, _wallet)
    returns (WhitelistInfo memory)
  {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    return vestingPools[_option].whitelistPool[idx];
  }

  /**
   *
   * @dev set token address for contract
   *
   * @param {_token} address of IERC20 instance
   * @return {bool} return status of token address
   *
   */
  function setToken(address _addr) external override onlyOwner returns (bool) {
    _token = IERC20(_addr);
    return true;
  }

  /**
   *
   * @dev getter function for deployed decubate token address
   *
   * @return {address} return deployment address of decubate token
   *
   */
  function getToken() external view override returns (address) {
    return address(_token);
  }

  /**
   *
   * @dev calculate the total vested amount by the time
   *
   * @param {address} user wallet address
   *
   * @return {uint256} return vested amount
   *
   */
  function calculateVestAmount(uint256 _option, address _wallet)
    internal
    view
    userInWhitelist(_option, _wallet)
    returns (uint256)
  {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo memory whitelist = vestingPools[_option].whitelistPool[idx];
    VestingPool storage vest = vestingPools[_option];

    // initial unlock
      uint256 initial = whitelist.dcbAmount.mul(vest.initialUnlockPercent).div(
        1000
      );

    if(whitelist.revoke) {
      return whitelist.dcbAmount;
    }
    if (block.timestamp < vest.start) {
      return 0;
    } 
    else if(block.timestamp >= vest.start && block.timestamp < vest.cliff) {
      return initial;
    } 
    else if(block.timestamp >= vest.cliff && block.timestamp < vest.cliff.add(vest.duration)) {
      // remaining locked token
      uint256 remaining = whitelist.dcbAmount.sub(initial); //More accurate

      // return initial unlock + remaining x % of time passed
      return
        initial +
        remaining.mul(block.timestamp.sub(vest.cliff)).div(vest.duration);
    } 
    else {
      return whitelist.dcbAmount;
    }
  }

  /**
   *
   * @dev calculate releasable amount by subtracting distributed amount
   *
   * @param {address} investor wallet address
   *
   * @return {uint256} releasable amount of the whitelist
   *
   */
  function calculateReleasableAmount(uint256 _option, address _wallet)
    internal
    view
    userInWhitelist(_option, _wallet)
    returns (uint256)
  {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    return
      calculateVestAmount(_option, _wallet).sub(
        vestingPools[_option].whitelistPool[idx].distributedAmount
      );
  }

  /**
   *
   * @dev distribute the token to the investors
   *
   * @param {address} wallet address of the investor
   *
   * @return {bool} return status of distribution
   *
   */
  function claimDistribution(uint256 _option, address _wallet)
    external
    override
    nonReentrant
    returns (bool)
  {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo storage whitelist = vestingPools[_option].whitelistPool[idx];

    require(!whitelist.disabled, "User is disabled from claiming token");

    uint256 releaseAmount = calculateReleasableAmount(_option, _wallet);

    require(releaseAmount > 0, "Zero amount to claim");

    if (maxTokenTransfer.active && releaseAmount > maxTokenTransfer.amount) {
      releaseAmount = maxTokenTransfer.amount;
    }

    whitelist.distributedAmount = whitelist.distributedAmount.add(
      releaseAmount
    );

    _token.transfer(_wallet, releaseAmount);

    emit Claim(_wallet, releaseAmount, _option, block.timestamp);

    return true;
  }

  /**
   *
   * @dev allow the owner to revoke the vesting
   *
   */
  function revoke(uint256 _option, address _wallet)
    public
    onlyOwner
    userInWhitelist(_option, _wallet)
  {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo storage whitelist = vestingPools[_option].whitelistPool[idx];

    require(vestingPools[_option].revocable, "Strategy is not revocable");
    require(!whitelist.revoke, "already revoked");

    whitelist.revoke = true;

    emit Revoked(_wallet);
  }

  /**
   *
   * @dev allow the owner to enable/disable the vesting
   *
   * User will not be able to claim his tokens, but claimable balance remains unchanged
   *
   */
  function setVesting(uint256 _option, address _wallet, bool _status)
    public
    onlyOwner
    userInWhitelist(_option, _wallet)
  {
    uint256 idx = vestingPools[_option].hasWhitelist[_wallet].arrIdx;
    WhitelistInfo storage whitelist = vestingPools[_option].whitelistPool[idx];

    whitelist.disabled = _status;

    emit StatusChanged(_wallet,_status);
  }

  /**
   *
   * @dev Allow owner to transfer token from contract
   *
   * @param {address} contract address of corresponding token
   * @param {uint256} amount of token to be transferred
   *
   * This is a generalized function which can be used to transfer any accidentally
   * sent (including DCB) out of the contract to wowner
   *
   */
  function transferToken(address _addr, uint256 _amount)
    external
    onlyOwner
    returns (bool)
  {
    IERC20 token = IERC20(_addr);
    bool success = token.transfer(address(owner()), _amount);
    return success;
  }

  /**
   *
   * @dev Retrieve total amount of token from the contract
   *
   * @param {address} address of the token
   *
   * @return {uint256} total amount of token
   *
   */
  function getTotalToken(address _addr) external view returns (uint256) {
    IERC20 token = IERC20(_addr);
    return token.balanceOf(address(this));
  }

  function hasWhitelist(uint256 _option, address _wallet)
    external
    view
    returns (bool)
  {
    return vestingPools[_option].hasWhitelist[_wallet].active;
  }

  function getVestAmount(uint256 _option, address _wallet)
    external
    view
    override
    returns (uint256)
  {
    return calculateVestAmount(_option, _wallet);
  }

  function getReleasableAmount(uint256 _option, address _wallet)
    external
    view
    override
    returns (uint256)
  {
    return calculateReleasableAmount(_option, _wallet);
  }

  function getWhitelistPool(uint256 _option)
    external
    view
    optionExists(_option)
    returns (WhitelistInfo[] memory)
  {
    return vestingPools[_option].whitelistPool;
  }
}