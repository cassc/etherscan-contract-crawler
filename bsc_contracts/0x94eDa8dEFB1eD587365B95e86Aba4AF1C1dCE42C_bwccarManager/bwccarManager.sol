/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
  function decimals() external pure returns (uint8);
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface INFT {
  function ProcessTokenRequest(address account,uint256 _nftrarity,uint256 _objecttype) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
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
        require(_owner == _msgSender());
        _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, account);
        _owner = account;
    }

}

contract bwccarManager is Context, Ownable {

  uint256 public object_count;

  address public nftContract;

  mapping(uint256 => string) public object_name;
  mapping(uint256 => address) public object_token;
  mapping(uint256 => uint256) public object_price;
  mapping(uint256 => address) public object_receiver;

  mapping(address => bool) public permission;

  modifier onlyPermission() {
    require(permission[msg.sender], "!PERMISSION");
    _;
  }

  constructor(address _nftContract) {
    nftContract = _nftContract;
  }

  function setupContract(address _nftContract) public onlyOwner returns (bool) {
    nftContract = _nftContract;
    return true;
  }

  function flagePermission(address _account,bool _flag) public onlyOwner returns (bool) {
    permission[_account] = _flag;
    return true;
  }

  function addnewObject(string memory _name,address _accesstoken,uint256 _price,address _receiver) public onlyOwner returns (bool) {
    object_count += 1;
    object_name[object_count] = _name;
    object_token[object_count] = _accesstoken;
    object_price[object_count] = _price;
    object_receiver[object_count] = _receiver;
    return true;
  }

  function updateObjectData(uint256 objectid,string memory _name,address _accesstoken,uint256 _price,address _receiver) public onlyPermission returns (bool) {
    object_name[objectid] = _name;
    object_token[objectid] = _accesstoken;
    object_price[objectid] = _price;
    object_receiver[objectid] = _receiver;
    return true;
  }

  function MintFor(address account,uint256 objecttype) external returns (bool) {
    IERC20 token = IERC20(object_token[objecttype]);
    token.transferFrom(msg.sender,object_receiver[objecttype],object_price[objecttype]);
    INFT(nftContract).ProcessTokenRequest(account,_createRandomNum(10000),objecttype);
    return true;
  }

  function _createRandomNum(uint256 _mod) internal view returns (uint256) {
    uint256 randomNum = uint256(
      keccak256(abi.encodePacked(block.timestamp, msg.sender))
    );
    return randomNum % _mod;
  }

  function emergencyWithdraw(address tokenaddress) external onlyOwner {
    IERC20 token = IERC20(tokenaddress);
    uint256 amount = token.balanceOf(address(this));
    token.transfer(msg.sender,amount);
  }

  function callStuckETH() external onlyOwner {
    (bool success,) = msg.sender.call{ value: address(this).balance }("");
    require(success, "Failed to send ETH");
  }
  
  receive() external payable { }
}