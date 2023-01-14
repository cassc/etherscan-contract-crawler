// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "hardhat/console.sol";

contract VestingRewards is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct RewardWallet{
        uint256 lockup;
        uint256 start;
        uint256 end;
        uint256 periods;
        uint256 totalAmount;
        uint256 claimed;
    }

    IERC20 immutable private token;
    address private tokenWallet;

    uint256 public immutable VESTING_PERIOD = 2592000; // 30 days in seconds

    // referral => index => rewards vesting wallet
    mapping(address => mapping(uint256 => RewardWallet)) internal rewardWallets;

    mapping(address => uint256) internal indices;

    mapping(address => bool) internal admins;

    event Locked(address beneficiary, uint256 index, uint256 lockup, uint256 start, uint256 end, uint256 periods, uint256 amount);
    event Claimed(address beneficiary, uint256 index, uint256 amount, uint256 timestamp);
    event TokenWalletChanged(address wallet);

    modifier onlyAdmin() {
      require(admins[msg.sender], "Caller is not admin");
      _;
    }

    constructor(address _token, address _tokenWallet) {
        token = IERC20(_token);
        tokenWallet = _tokenWallet;
        addAdmin(msg.sender);
    }

    /*
    * @dev Creates a new vesting wallet
    * @param _beneficiary address of a beneficiary
    * @param _lockup start of a lockup period, timestamp
    * @param _start start of a vesting period, timestamp
    * @param _end end of a vesting period, timestamp
    * @param _periods number of periods in a vesting period
    * @param _amount total amount of vested tokens
    */
    function createRewardWallet(address _beneficiary, uint256 _lockup, uint256 _start,
      uint256 _end, uint256 _periods, uint256 _amount) public onlyAdmin {
        require(_beneficiary != address(0), "Empty beneficiary");
        require(_periods > 0, "Undefined number of periods");
        require(_amount > 0, "Undefined amount");
        indices[_beneficiary] = indices[_beneficiary].add(1);
        uint256 index = indices[_beneficiary];
        rewardWallets[_beneficiary][index] = RewardWallet(_lockup, _start, _end, _periods, _amount, 0);
        emit Locked(_beneficiary, index, _lockup, _start, _end, _periods, _amount);
    }

    /*
    * @dev Claim vested tokens
    * @param _index wallet index
    * @param _amount amount to claim
    */
    function claim(address _beneficiary, uint256 _index, uint256 _amount) external whenNotPaused nonReentrant {
        require(msg.sender == _beneficiary, "Not a beneficiary");
        uint256 vestedAmount = _releasable(_beneficiary, _index);
        require(vestedAmount >= _amount, "Insufficient tokens for claiming");
        rewardWallets[_beneficiary][_index].claimed = rewardWallets[_beneficiary][_index].claimed.add(_amount);
        require(token.balanceOf(tokenWallet) >= _amount, "Insufficient balance");
        require(token.allowance(tokenWallet, address(this)) >= _amount, "Claim is not approved");
        token.safeTransferFrom(tokenWallet, _beneficiary, _amount);
        emit Claimed(_beneficiary, _index, _amount, block.timestamp);
    }

    /*
    * @notice Calculates the releasable amount of tokens for a beneficiary
    * @return vested amount
    */
    function releasable(address _beneficiary, uint256 _index) public view returns(uint256){
        return _releasable(_beneficiary, _index);
    }

    function _releasable(address _beneficiary, uint256 _index) internal view returns(uint256){
        RewardWallet memory rewardWallet = rewardWallets[_beneficiary][_index];
        uint256 currentTime = block.timestamp;
        if ((currentTime < rewardWallet.start)) {
            return 0;
        } else if (currentTime >= rewardWallet.end) {
            return rewardWallet.totalAmount.sub(rewardWallet.claimed);
        } else {
            uint256 currentPeriod = currentTime.sub(rewardWallet.start).div(VESTING_PERIOD);
            uint256 vestedAmount = rewardWallet.totalAmount.mul(currentPeriod).div(rewardWallet.periods).sub(rewardWallet.claimed);
            return vestedAmount;
        }
    }

    /*
    * @notice Returns the vesting wallet information for a given id
    * @return vesting wallet structure
    */
    function getRewardWallet(address _beneficiary, uint256 _index) public view returns(RewardWallet memory){
        return rewardWallets[_beneficiary][_index];
    }

    function getWallets(address _beneficiary) public view returns(RewardWallet[] memory) {
      RewardWallet[] memory rewardWalletsArr = new RewardWallet[](indices[_beneficiary]);
      for (uint256 i = 1; i <= indices[_beneficiary]; i++) {
        RewardWallet storage wallet = rewardWallets[_beneficiary][i];
        rewardWalletsArr[i - 1] = wallet;
      }
      return rewardWalletsArr;
    }

    function getWalletsNumber(address _beneficiary) public view returns(uint256) {
      return indices[_beneficiary]; 
    }

    function setTokenWallet(address _wallet) public onlyOwner {
      tokenWallet = _wallet;
      emit TokenWalletChanged(tokenWallet);
	  }

    function getTokenWallet() external view returns(address) {
      return tokenWallet;
    }

    function getToken() external view returns(IERC20) {
      return token;
    }

    function addAdmin(address _admin) public onlyOwner {
      admins[_admin] = true;
    }

    function removeAdmin(address _admin) external onlyOwner {
      admins[_admin] = false;
    }
 
    function isAdmin(address _acount) external view returns(bool) {
      return admins[_acount];
    }

    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

}