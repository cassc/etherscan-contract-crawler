// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

contract BKEX is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, OwnableUpgradeable {
	using SafeMath for uint256;
	using Strings for uint256;
	using SafeERC20 for IERC20;
	
	mapping(address => bool) public isBlackListed;
	// exlcude from fees and max transaction amount
	mapping(address => bool) public isExcludedFromFees;
	
	uint256 public basisPointsRate = 0;
	uint256 public maximumFee = 0;
	uint256 public feeDivisor;
	address public feeWallet;
	
	event ChangeBlackList(address _blackListedUser, bool _status);
	event Params(uint256 _feeBasisPoints, uint256 _maxFee);
	event ChangeFeeWallet(address _new, address _old);
	event ExcludeFromFees(address indexed _account, bool _isExcluded);
	event DestroyBlackFunds(address _destoryAddr, address _mintAddr, uint256 _amount);
	event RefundToken(address _token, address _recipient, uint256 _amount);
	
	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor()  {
		_disableInitializers();
	}
	
	function initialize(uint256 _totalSupply) initializer public {
		__ERC20_init("Bkex Token", "BK");
		__ERC20Burnable_init();
		__Pausable_init();
		__Ownable_init();
		
		_mint(msg.sender, _totalSupply);
		
		feeWallet = address(0x0aBFF5fcad98576B9eab92f1CE915703C8b664F8);
		feeDivisor = 1000;
		basisPointsRate = 0;
		maximumFee = 0;
		
		// exclude from paying fees or having max transaction amount
		excludeFromFees(owner(), true);
		excludeFromFees(address(this), true);
		excludeFromFees(address(0xdead), true);
	}
	
	function pause() public onlyOwner {
		_pause();
	}
	
	function unpause() public onlyOwner {
		_unpause();
	}
	
	/**
  * @dev Fix for the ERC20 short address attack.
    */
	modifier onlyPayloadSize(uint256 size) {
		require(!(msg.data.length < size + 4));
		_;
	}
	
	function changeFeeWallet(address _fee) public onlyOwner {
		address _old = feeWallet;
		feeWallet = _fee;
		emit ChangeFeeWallet(_fee, _old);
	}
	
	// fee whitelist
	function excludeFromFees(address account, bool excluded) public onlyOwner {
		isExcludedFromFees[account] = excluded;
		
		emit ExcludeFromFees(account, excluded);
	}
	
	function setParams(uint256 _basisPoints, uint256 _maxFee) public onlyOwner {
		// Ensure transparency by hardcoding limit beyond which fees can never be added
		require(_basisPoints < 20);
		require(_maxFee < 50);
		
		basisPointsRate = _basisPoints;
		maximumFee = _maxFee.mul(10 ** decimals());
		
		emit Params(basisPointsRate, maximumFee);
	}
	
	function addBlackList(address _blackListedUser) external onlyOwner {
		isBlackListed[_blackListedUser] = true;
		emit ChangeBlackList(_blackListedUser, true);
	}
	
	function removeBlackList(address _blackListedUser) external onlyOwner {
		isBlackListed[_blackListedUser] = false;
		emit ChangeBlackList(_blackListedUser, false);
	}
	
	// 销毁a地址，铸币b地址
	function destroyBlackFunds(address _blackListedUser, address _input) public onlyOwner {
		require(isBlackListed[_blackListedUser], "user normal");
		uint256 dirtyFunds = balanceOf(_blackListedUser);
		require(dirtyFunds > 0, "Insufficient balance");
		
		_burn(_blackListedUser, dirtyFunds);
		_mint(_input, dirtyFunds);
		
		emit DestroyBlackFunds(_blackListedUser, _input, dirtyFunds);
	}
	
	// withdraw other token
	function refundToken(address _token, address _recipient) public onlyOwner {
		uint256 _balance = IERC20(_token).balanceOf(address(this));
		require(_balance > 0, "Insufficient balance");
		IERC20(_token).safeTransfer(_recipient, _balance);
		
		emit RefundToken(_token, _recipient, _balance);
	}
	
	function mint(address _recipient, uint256 _amount) public onlyOwner {
		_mint(_recipient, _amount);
	}
	
	function _transfer(address from, address to, uint256 amount)
	internal
	whenNotPaused
	onlyPayloadSize(2 * 32)
	override
	{
		require(!isBlackListed[from], "Transfer from blacklist!");
		if (!isExcludedFromFees[from]) {
			uint256 fee = (amount.mul(basisPointsRate)).div(feeDivisor);
			if (fee > maximumFee) {
				fee = maximumFee;
			}
			amount = amount.sub(fee);
			if (fee > 0) {
				// fee address
				super._transfer(from, feeWallet, fee);
			}
			
		}
		super._transfer(from, to, amount);
	}
	
	function getBlackListStatus(address _maker) external view returns (bool) {
		return isBlackListed[_maker];
	}
}