// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./BlackList.sol";

contract ERC20 is IERC20, BlackList, Pausable {
    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowed;

    uint256 internal _totalSupply;

    function totalSupply() external view override virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address user) external view override returns (uint256) {
        return _balances[user];
    }

    function allowance(address user, address spender) external view returns (uint256) {
        return _allowed[user][spender];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        require(msg.sender != address(0));

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool)
    {
        require(spender != address(0), 'Spender zero address prohibited');
        require(msg.sender != address(0), 'Zero address could not call method');

        _allowed[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }
    
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external returns (bool)
    {
        require(spender != address(0), 'Spender zero address prohibited');
        require(msg.sender != address(0), 'Zero address could not call method');

        _allowed[msg.sender][spender] -= subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(value <= _allowed[from][msg.sender], 'Not allowed to spend');
        _transfer(from, to, value);
        _allowed[from][msg.sender] -= value;

        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);

        return true;
    }

    function _transfer(address from, address to, uint256 value) internal whenNotPaused {
        require(!isBlacklisted(from), 'Sender address in blacklist');
        require(!isBlacklisted(to), 'Receiver address in blacklist');
        require(to != address(0), 'Zero address can not be receiver');

        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply += value;
        _balances[account] += value;
        emit Transfer(address(0), account, value);
    }

    function burn(uint256 amount) external onlyOwner() virtual {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply -= value;
        _balances[account] -= value;
        emit Transfer(account, address(0), value);
    }

    function destroyBlackFunds (address _blackListedUser) external onlyOwner  {
        require(isBlacklisted(_blackListedUser), 'Address is not in blacklist');
        uint dirtyFunds = _balances[_blackListedUser];
        _balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
}