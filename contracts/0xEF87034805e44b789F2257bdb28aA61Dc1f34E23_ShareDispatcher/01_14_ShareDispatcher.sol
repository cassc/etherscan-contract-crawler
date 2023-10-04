pragma solidity ^0.8.0;

import "./utils/AddressArray.sol";
import "./utils/SafeMath.sol";
import "./utils/Ownable.sol";
import "./interfaces/TokenBankInterface.sol";
import "./erc20/IERC20.sol";
import "./interfaces/IShareProof.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

//import "forge-std/Test.sol";

contract ShareDispatcher is Initializable, ERC20Upgradeable, OwnableUpgradeable{
  using SafeMath for uint;
  using AddressArray for address[];

  struct EmployeeInfo{
    uint256 userRewardPerTokenPaid;
    uint256 cumulateTokenReward;
    uint256 lockedTokenReward;
    uint256 tokenFromPause;
    uint256 unlockAmount;
    bool paused;
  }

  TokenBankInterface public erc20Bank;
  address public shareToken;
  uint256 public rewardPerBlockNum;      
  uint256 public rewardPerBlockDen;      


  uint256 public lastUpdateBlock;                             // last updated block
  uint256 public rewardPerTokenStored;                        // reward per token that has stored before
  uint256 public startBlock;
  uint256 public totalUnlockAmount;
  uint256 public endBlock;

  //uint256 constant blockInOneYear = 10;
  //uint256 public nextUnlockBlock;
  uint256 public unlockRatio;
  uint256 constant ratioBase = 10000;

  mapping (address => EmployeeInfo) public employeeInfos;

  event ClaimedShare(address account, address to, uint amount);

  function initialize(address _erc20Bank,
              address _shareToken, uint unitAmountNum, uint unitAmountDen, uint _startBlock) external initializer{
    __ERC20_init("RDS proof", "RDSS");
    __Ownable_init();
    erc20Bank = TokenBankInterface(_erc20Bank);
    shareToken = _shareToken;
    rewardPerBlockNum = unitAmountNum;
    rewardPerBlockDen = unitAmountDen;
    startBlock = _startBlock;
    lastUpdateBlock = startBlock;
    unlockRatio = 2000;
  }

  event NewTokenBank(address newBank);

  function changeTokenBank(address _addr) public onlyOwner{
    require(_addr != address(0x0), "invalid address");
    erc20Bank = TokenBankInterface(_addr);
    emit NewTokenBank(_addr);
  }

  function bankBalance() public view returns(uint){
    return IERC20(shareToken).balanceOf(address(erc20Bank));
  }
  /**
    * @dev calculate reward per token
  */
  function rewardPerToken(uint256 _block) public view returns (uint256) {
    if (totalSupply() == 0) {
        return rewardPerTokenStored;
    }
    return
        rewardPerTokenStored +
        (((_block - lastUpdateBlock) * rewardPerBlockNum * 1e18) /
            (totalSupply() * rewardPerBlockDen));
  }

  function earnedFromLast(address account, uint256 _block) public view returns (uint256) {
    return
        (balanceOf(account) *
            (rewardPerToken(_block) - employeeInfos[account].userRewardPerTokenPaid)) /
        1e18; 
  }

  event EarnLockedRewardFromLast(address account, uint256 amount);
  event PausedRewardFromLast(address account, uint256 amount);

  function Block() public view returns(uint256){
    return ((endBlock != 0) && (block.number > endBlock)) ? endBlock : block.number;
  }

  function _updateReward(address _account) internal {
    uint256 _block = Block();
    if (_block <= startBlock) return;
    rewardPerTokenStored = rewardPerToken(_block);
    lastUpdateBlock = _block;
    EmployeeInfo storage ei = employeeInfos[_account];
    uint256 efl = earnedFromLast(_account, _block);
    ei.cumulateTokenReward += efl;
    if (!ei.paused){
      ei.lockedTokenReward += efl;
      emit EarnLockedRewardFromLast(_account, efl);
    }
    else{
      ei.tokenFromPause += efl;
      emit PausedRewardFromLast(_account, efl);
    }
    ei.userRewardPerTokenPaid = rewardPerTokenStored;
  }

  event UnlockReward(address account, uint256 amount);
  function _updateAndUnlock(address _account) internal {
    _updateReward(_account);
    EmployeeInfo storage ei = employeeInfos[_account];
    uint256 unlockAmount = ei.lockedTokenReward * unlockRatio / ratioBase;
    ei.lockedTokenReward -= unlockAmount;
    require(unlockAmount <= bankBalance(), "bank out of money");
    erc20Bank.issue(shareToken, payable(_account), unlockAmount);
    ei.unlockAmount += unlockAmount;
    totalUnlockAmount += unlockAmount;
    emit UnlockReward(_account, unlockAmount);
  }
  event EmployeePause(address account, bool isPaused);

  function pauseEmployee(address account, bool pause) public onlyOwner{
    _updateReward(account);
    employeeInfos[account].paused = pause;
    emit EmployeePause(account, pause);
  }
  function _mintProof(address _account, uint256 _amount) internal{
    _updateReward(_account);
    _mint(_account, _amount);
  }

  function _burnProof(address _account, uint256 _amount) internal{
    _updateReward(_account);
    _burn(_account, _amount);
  }
  function unlockMultiReward(address[] memory accounts) public onlyOwner{
    for (uint i; i < accounts.length; ){
      _updateAndUnlock(accounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  function decimals() public view virtual override returns (uint8) {
    return 4;
  }

  event NewRewardPerBlock(uint256 numerator, uint256 denominator);
  function changeRewardPerBlock(uint256 num, uint256 den) public onlyOwner{
    uint256 _block = Block();
    rewardPerTokenStored = rewardPerToken(_block);
    lastUpdateBlock = _block;
    rewardPerBlockNum = num;
    rewardPerBlockDen = den;
    emit NewRewardPerBlock(num, den);
  }

  function mintProof(address account, uint256 amount) public onlyOwner{
    _mintProof(account, amount);
  }

  function burnProof(address account, uint256 amount) public onlyOwner{
    _burnProof(account, amount);
  }

  function mintMultiProof(address[] memory accounts, uint256[] memory amounts) public onlyOwner{
    require(accounts.length == amounts.length, "invalid length");
    for (uint i; i < accounts.length; ){
      _mintProof(accounts[i], amounts[i]);
      unchecked {
        ++i;
      }
    }
  }
  function burnMultiProof(address[] memory accounts, uint256[] memory amounts) public onlyOwner{
    require(accounts.length == amounts.length, "invalid length");
    for (uint i; i < accounts.length; ){
      _burnProof(accounts[i], amounts[i]);
      unchecked {
        ++i;
      }
    }
  }

  function employeeQuit(address account) public onlyOwner{
    _burnProof(account, balanceOf(account));
    employeeInfos[account].lockedTokenReward = 0;
  }

  event NewUnlockRatio(uint256 newUnlockRatio);
  function changeUnlockRatio(uint256 ratio) public onlyOwner{
    unlockRatio = ratio;
    emit NewUnlockRatio(ratio);
  }

  function getEmployeeInfoWithAccount(address account) public view
    returns(EmployeeInfo memory){
      return employeeInfos[account];
  }

  function getEmployeeLockedShare(address account) public view returns(uint256){
    uint256 _block = Block();
    return employeeInfos[account].lockedTokenReward + 
    (employeeInfos[account].paused ? 0 : earnedFromLast(account, _block));
  }

  function getEmployeeTotalShare(address account) public view returns(uint256){
    return  getEmployeeLockedShare(account) + IERC20(shareToken).balanceOf(account);
  }
  event SetEndBlock(uint256 endBlock);
  function setSelfEnd(uint newEndBlock) public onlyOwner{
    require(newEndBlock > lastUpdateBlock, "input block too early");
    endBlock = newEndBlock;
    emit SetEndBlock(newEndBlock);
  }
  function _transfer(address from, address to, uint256 amount) internal virtual override{
    revert("transfer disable");
  }
}