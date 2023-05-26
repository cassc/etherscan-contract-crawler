/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
         _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
         _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context,IERC20 {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

	uint256 internal immutable _RELEASE_TIME_TEAM_TOKENS;
	uint256 internal immutable _RELEASE_TIME_COMPANY1_TOKENS;
    uint256 internal immutable _RELEASE_TIME_COMPANY2_TOKENS;
    
	address constant internal _ADDRESS_1 = 0x3a3E5fe09A28218E34d5b0Fd2562738853f567C3;
    address constant internal _ADDRESS_2 = 0x16d0865Ac2405e90fF4Aec7Fc6dd0200F9B2719c;
	address constant internal _ADDRESS_3 = 0x770211caaB03028A4C45E19c7C68bB2284ca628A;
	address constant internal _ADDRESS_4 = 0x89c7285fe5490a23C8bc32A99f99B984C53e0858;
	address constant internal _ADDRESS_5 = 0x598388f9a2730E4bEb5645aDb2E208f27c98831D;

    address constant internal _COMPANY_1 = 0x689df33f77EE4BAE8Aa4E48Ce366322C62cC3c31;
    address constant internal _COMPANY_2 = 0x42eef6f9c1134140e0c31FB60C231fCE9565E228;

    address constant internal _TEAM_1 = 0x19Afc08C5Aa632aD6fA5e157eD8e3ABCB53dE9e3;
	address constant internal _TEAM_2 = 0xd4548F12889e5B668acBe2AF8a84Bbd090FC2313;
	address constant internal _TEAM_3 = 0x8E5D186dF7632C1ed1191ddB83Ed0e761DA4059c;
	address constant internal _TEAM_4 = 0xF88971abaf47546E30F816Fcdb27c3b115250083;
	address constant internal _TEAM_5 = 0x0389C115CB588489394c6F6b57e99b851BCc77a5;

	address[] internal teams  = [_TEAM_1,_TEAM_2,_TEAM_3,_TEAM_4,_TEAM_5];

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

		_RELEASE_TIME_COMPANY1_TOKENS = block.timestamp + 365 days;
        _RELEASE_TIME_COMPANY2_TOKENS = block.timestamp + 730 days;

        _RELEASE_TIME_TEAM_TOKENS = block.timestamp + 365 days;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
         unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
         }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
		_initBalances();
    }

	function _setBalance(address addr,uint256 amount) private
    {
        amount =amount * 10 ** decimals();
        _balances[addr] =  amount;
        emit Transfer(address(0), addr, amount);
    }

	 function _initBalances() private{

		_setBalance(_msgSender(), 15000000);

		_setBalance(_ADDRESS_1, 10000000);
		_setBalance(_ADDRESS_2, 10000000); 
		_setBalance(_ADDRESS_3, 10000000); 
		_setBalance(_ADDRESS_4, 10000000); 
		_setBalance(_ADDRESS_5, 10000000); 

        _setBalance(_COMPANY_1,10000000); 
        _setBalance(_COMPANY_2,10000000); 

        _setBalance(_TEAM_1,5250000); 
		_setBalance(_TEAM_2,3000000); 
		_setBalance(_TEAM_3,3000000); 
		_setBalance(_TEAM_4,3000000); 
		_setBalance(_TEAM_5,750000); 
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

abstract contract ERC20Burnable is Context,ERC20 {

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
         unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
         }
        _burn(account, amount);
    }
}

abstract contract ERC20Snapshot is ERC20 {

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    Counters.Counter private _currentSnapshotId;

    event Snapshot(uint256 id);

    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId =_getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }
     function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    function totalSupplyAt(uint256 snapshotId) public view virtual returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {
        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {
        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {
        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

contract LEGSToken is ERC20, ERC20Burnable, ERC20Snapshot, Ownable {

    constructor() ERC20("Coinlegs", "LEGS") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

	function distributeTokens(address[] calldata addresses, uint256[] calldata values) external onlyOwner {
		
		require(addresses.length == values.length, "Invalid Parameters");
		address sender = owner();
		uint len = addresses.length;
		uint256 multiply = 10 ** decimals();

		uint256 amount;
		uint256 senderBalance ;
		address recipient;

     	for (uint i = 0; i < len; i++) {
			
			amount = values[i] * multiply;
			senderBalance = _balances[sender];
			recipient = addresses[i];

			require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
			unchecked {
				_balances[sender] = senderBalance - amount;
			}
			_balances[recipient] += amount;

			emit Transfer(sender, recipient, amount);
		}
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        bool locked=false;
        if(from == _COMPANY_1){
            locked = block.timestamp < _RELEASE_TIME_COMPANY1_TOKENS;
        }
        else if(from == _COMPANY_2){
            locked = block.timestamp < _RELEASE_TIME_COMPANY2_TOKENS;
        }
        else{
			for (uint8 index = 0; index < teams.length; index++) {
				if(from == teams[index] ){
					locked = block.timestamp < _RELEASE_TIME_TEAM_TOKENS;
					break;	
				}
			}
		}

        require(locked == false, "Account Locked");

        super._beforeTokenTransfer(from, to, amount);
    }
}

library Arrays {

    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

library Counters {
    struct Counter {
        uint256 _value; 
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }
}