/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library TransferHelper {
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract BabMine is Ownable {
    using SafeMath for uint256;

    address public WETH=0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;//BNB地址

    mapping (address => mapping (address => uint256)) private tokenAmount;//会员币种余额，币种 => ( 地址 => 数量 )
    mapping(address => RecordData[]) public recordMap;//记录
    struct RecordData {
        address currency;
        uint256 value;
        uint256 time;
    }

    //购买（id:套餐id）
    function buyMine(uint256 id) public payable{}

    //修改用户数量：添加用户的奖金数量：币种地址、用户地址、数量
    function addUserAmount(address _currency,address _user,  uint256 _amount) public onlyOwner{
        require( _amount > 0 , "_amount error");
        tokenAmount[_currency][_user]=tokenAmount[_currency][_user].add(_amount);
    }
    //获取用户代币数量：币种地址、用户地址/（返回）/代币数量【币种】【用户地址】
    function getUserTokenAmount(address _currency,address _user) public view returns(uint256)  {
       return tokenAmount[_currency][_user];
    }
    
    //提现
    function claim(address _currency) public {
        uint256 balance = tokenAmount[_currency][msg.sender];
        require(balance > 0, "Claim: not balance");
        if(_currency == WETH){
            safeTransferETH(msg.sender, balance);
        }else{
            safeTransferToken(_currency,address(msg.sender), balance);
        }
        tokenAmount[_currency][msg.sender] = 0;

        RecordData memory record = RecordData({currency:_currency,value:balance,time:block.timestamp});
        recordMap[msg.sender].push(record);
    }

    function getRecord(address _user) public view returns (RecordData[] memory){
        return recordMap[_user];
    }

    function safeTransferETH(address _to, uint256 _amount) internal {
        uint256 tokenBal =  address(this).balance;
        require(tokenBal >0 && tokenBal >= _amount , "AwardPool: pool not balance"); 
        TransferHelper.safeTransferETH(_to, _amount);
    }

    function safeTransferToken(address _currency,address _to, uint256 _amount) internal {
        uint256 tokenBal = IERC20(_currency).balanceOf(address(this));
        require(tokenBal >0 && tokenBal >= _amount, "AwardPool: pool not balance"); 
        IERC20(_currency).transfer(_to, _amount);    
    }
}