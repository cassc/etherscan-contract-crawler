// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libraries/token/IERC20.sol";
import "./libraries/math/SafeMath.sol";
import "./interfaces/ILGEToken.sol";

contract LGEToken is IERC20, ILGEToken {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public override totalSupply;

    address public distributor;
    address public override token;

    uint256 public override refBalance;
    uint256 public override refSupply;

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;

    event SetRefBalance(uint256 refBalance);
    event SetRefSupply(uint256 refSupply);

    modifier onlyDistributor() {
        require(msg.sender == distributor, "LGEToken: forbidden");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _distributor,
        address _token
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        distributor = _distributor;
        token = _token;
    }

    function mint(address _account, uint256 _amount) public override onlyDistributor returns (bool) {
        _mint(_account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) public override onlyDistributor returns (bool) {
        _burn(_account, _amount);
        return true;
    }

    function setRefBalance(uint256 _refBalance) public override onlyDistributor returns (bool) {
        refBalance = _refBalance;
        emit SetRefBalance(_refBalance);
        return true;
    }

    function setRefSupply(uint256 _refSupply) public override onlyDistributor returns (bool) {
        refSupply = _refSupply;
        emit SetRefSupply(_refSupply);
        return true;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        uint256 nextAllowance = allowances[_sender][msg.sender].sub(_amount, "LGEToken: transfer amount exceeds allowance");
        _approve(_sender, msg.sender, nextAllowance);
        _transfer(_sender, _recipient, _amount);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "LGEToken: transfer from the zero address");
        require(_recipient != address(0), "LGEToken: transfer to the zero address");

        balances[_sender] = balances[_sender].sub(_amount, "LGEToken: transfer amount exceeds balance");
        balances[_recipient] = balances[_recipient].add(_amount);
        emit Transfer(_sender, _recipient, _amount);
    }

    function _mint(address account, uint256 _amount) private {
        require(account != address(0), "LGEToken: mint to the zero address");

        balances[account] = balances[account].add(_amount);
        totalSupply = totalSupply.add(_amount);
        emit Transfer(address(0), account, _amount);
    }

    function _burn(address _account, uint256 _amount) private {
        require(_account != address(0), "LGEToken: burn from the zero address");

        balances[_account] = balances[_account].sub(_amount, "LGEToken: burn amount exceeds balance");
        totalSupply = totalSupply.sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "LGEToken: approve from the zero address");
        require(_spender != address(0), "LGEToken: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
}