// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Vesting is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct VestingWallet{
        address beneficiary;
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

    // nft id => vesting wallet
    mapping(uint256 => VestingWallet) internal vestingWallets;

    mapping(address => bool) internal admins;

    event Locked(address beneficiary, uint256 id, uint256 lockup, uint256 start, uint256 end, uint256 periods, uint256 amount);
    event Claimed(address beneficiary, uint256 id, uint256 amount, uint256 timestamp);
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
    function createVestingWallet(address _beneficiary, uint256 _id, uint256 _lockup, uint256 _start,
      uint256 _end, uint256 _periods, uint256 _amount) public onlyAdmin {
        require(_beneficiary != address(0), "Empty beneficiary");
        require(_id > 0, "Undefined nft id");
        require(_periods > 0, "Undefined number of periods");
        require(_amount > 0, "Undefined amount");
        vestingWallets[_id] = VestingWallet(_beneficiary, _lockup, _start, _end, _periods, _amount, 0);
        
        emit Locked(_beneficiary, _id, _lockup, _start, _end, _periods, _amount);
    }

    /*
    * @dev Claim vested tokens
    * @param _id nft token id
    * @param _amount amount to claim
    */
    function claim(uint256 _id, uint256 _amount) external nonReentrant {
        require(msg.sender == vestingWallets[_id].beneficiary, "Not a beneficiary");
        uint256 vestedAmount = _releasable(_id);
        require(vestedAmount >= _amount, "Not enough vested tokens");
        vestingWallets[_id].claimed = vestingWallets[_id].claimed.add(_amount);
        require(token.balanceOf(tokenWallet) > _amount, "Insufficient balance");
        require(token.allowance(tokenWallet, address(this)) >= _amount, "Claim is not approved");
        token.safeTransferFrom(tokenWallet, vestingWallets[_id].beneficiary, _amount);
        emit Claimed(vestingWallets[_id].beneficiary, _id, _amount, block.timestamp);
    }

    /*
    * @notice Calculates the releasable amount of tokens for a given id
    * @return vested amount
    */
    function releasable(uint256 _id) public view returns(uint256){
        return _releasable(_id);
    }

    function _releasable(uint256 _id) internal view returns(uint256){
        VestingWallet memory vestingWallet = vestingWallets[_id];
        uint256 currentTime = block.timestamp;
        if ((currentTime < vestingWallet.start)) {
            return 0;
        } else if (currentTime >= vestingWallet.end) {
            return vestingWallet.totalAmount.sub(vestingWallet.claimed);
        } else {
            uint256 currentPeriod = currentTime.sub(vestingWallet.start).div(VESTING_PERIOD);
            uint256 vestedAmount = vestingWallet.totalAmount.mul(currentPeriod).div(vestingWallet.periods).sub(vestingWallet.claimed);
            return vestedAmount;
        }
    }

    /*
    * @notice Returns the vesting wallet information for a given id
    * @return vesting wallet structure
    */
    function getVestingWallet(uint256 _id) external view returns(VestingWallet memory){
        return vestingWallets[_id];
    }

    function changeTokenWallet(address _wallet) external onlyOwner {
		  _changeTokenWallet(_wallet);
	  }

    function _changeTokenWallet(address _wallet) internal onlyOwner {
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