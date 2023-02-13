// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IVesting { 
  struct VestingWallet{
    address beneficiary;
    uint256 lockup;
    uint256 start;
    uint256 end;
    uint256 periods;
    uint256 totalAmount;
    uint256 claimed;
  } 
  function getVestingWallet(uint256 id) external view returns(VestingWallet memory);
  function setVestingWallet(address _beneficiary, uint256 _id, uint256 _lockup, uint256 _start,
    uint256 _end, uint256 _periods, uint256 _amount, uint256 _claimed) external;
  function transfer(uint256 id, address beneficiary) external;
  function setClaim(uint256 id, uint256 claimed) external;
}

contract Claiming is Ownable, Pausable, ReentrancyGuard{
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 private token;
  IERC721 public nft;
  IVesting public minter;
  IVesting public vesting;
  
  address private tokenWallet;

  uint256 public immutable VESTING_PERIOD = 2592000; // 30 days in seconds
  
  mapping(address => bool) internal admins;

  event Claimed(address beneficiary, uint256 id, uint256 amount, uint256 timestamp);
  event TokenWalletChanged(address newWallet);
  event NftChanged(address newNft);
  event MinterChanged(address newMinter);
  event VestingChanged(address newVesting);
  

  constructor(address _token, address _tokenWallet, address _nft, address _minter, address _vesting) {
    token = IERC20(_token);
    tokenWallet = _tokenWallet;
    nft = IERC721(_nft);
    minter = IVesting(_minter);
    vesting = IVesting(_vesting);
  }

  function releasable(uint256 _id) public view returns(uint256){
    IVesting.VestingWallet memory vestingWallet = vesting.getVestingWallet(_id);
    uint256 currentTime = block.timestamp;
    if (vestingWallet.start == 0) {
      vestingWallet = minter.getVestingWallet(_id);
    }
    if (currentTime < vestingWallet.start) {
      return 0;
    } else if (currentTime >= vestingWallet.end) {
      return vestingWallet.totalAmount.sub(vestingWallet.claimed);
    } else if (vestingWallet.periods == 0) { 
      return vestingWallet.totalAmount; 
    } else {
      uint256 currentPeriod = currentTime.sub(vestingWallet.start).div(VESTING_PERIOD);
      uint256 vestedAmount = vestingWallet.totalAmount.mul(currentPeriod).div(vestingWallet.periods).sub(vestingWallet.claimed);
      return vestedAmount;
    }
  }

  function claim(uint256 _id) public whenNotPaused nonReentrant {
    uint256 amount = releasable(_id);
    require(amount > 0, "Nothing to claim");
    address nftOwner = nft.ownerOf(_id);
    require((msg.sender == nftOwner) || isAdmin(msg.sender), "Not an owner or admin");
    require(token.balanceOf(tokenWallet) > amount, "Insufficient balance");
    require(token.allowance(tokenWallet, address(this)) >= amount, "Claim is not approved");
    IVesting.VestingWallet memory vestingWallet = vesting.getVestingWallet(_id);
    if (vestingWallet.start == 0) {
      IVesting.VestingWallet memory minterWallet = minter.getVestingWallet(_id);
      vesting.setVestingWallet(msg.sender, _id, minterWallet.lockup, minterWallet.start,
        minterWallet.end, minterWallet.periods, minterWallet.totalAmount, amount);
    } else {
      vesting.setClaim(_id, vestingWallet.claimed.add(amount));
      if (nftOwner != vestingWallet.beneficiary) {
        vesting.transfer(_id, nftOwner);
      }
    }
    
    token.safeTransferFrom(tokenWallet, nftOwner, amount);
    
    emit Claimed(nftOwner, _id, amount, block.timestamp);
  }

  function setTokenWallet(address _wallet) external onlyOwner {
    tokenWallet = _wallet;
    emit TokenWalletChanged(tokenWallet);
  }

  function getTokenWallet() external view returns(address) {
    return tokenWallet;
  }

  function getToken() external view returns(IERC20) {
    return token;
  }

  function setNft(address _nft) external onlyOwner {
    nft = IERC721(_nft);
    emit NftChanged(_nft);
  }

  function setMinter(address _minter) external onlyOwner {
    minter = IVesting(_minter);
    emit MinterChanged(_minter);
  }

  function setVesting(address _vesting) external onlyOwner {
    vesting = IVesting(_vesting);
    emit VestingChanged(_vesting);
  }

  function addAdmin(address _admin) public onlyOwner {
    admins[_admin] = true;
  }

  function removeAdmin(address _admin) external onlyOwner {
    admins[_admin] = false;
  }

  function isAdmin(address _account) public view returns(bool) {
    return admins[_account];
  }

  receive() external payable {
      revert();
  }

  fallback() external payable {
      revert();
  }

}