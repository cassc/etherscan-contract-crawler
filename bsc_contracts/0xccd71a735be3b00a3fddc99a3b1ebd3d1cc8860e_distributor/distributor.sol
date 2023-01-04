/**
 *Submitted for verification at BscScan.com on 2023-01-03
*/

pragma solidity ^0.8.0;

// Token lock contract
// SPDX-License-Identifier: MIT

// ERC20 interface
interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Token lock contract
contract distributor is Ownable {
    // ERC20 token contract
    ERC20 public token;

    using SafeMath for uint256;

    function setToken(address _tokenAddress) public onlyOwner {
        token = ERC20(_tokenAddress);
    }

	function recoverERC20(ERC20 ERC20Token) external onlyOwner {
		ERC20Token.transfer(msg.sender, ERC20Token.balanceOf(address(this)));
	}


    function clearStuckBalance() external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB);
    }

    address public dev;
    address public lp;
    address public marketing;

    function setAddress(address _dev, address _lp, address _marketing) external onlyOwner{
        dev = _dev;
        lp = _lp;
        marketing = _marketing;
    }



    uint256 private a;
    uint256 private b;
    uint256 private c;

    function setRatio(uint256 _a, uint256 _b, uint256 _c) external onlyOwner {
        a = _a;
        b = _b;
        c = _c;
    }

    function distribute() external onlyOwner {
        uint256 total = a.add(b).add(c);
        uint256 amountA = token.balanceOf(address(this)).mul(a).div(total);
        uint256 amountB = token.balanceOf(address(this)).mul(b).div(total);
        uint256 amountC = token.balanceOf(address(this)).mul(c).div(total);
        require(token.transfer(dev, amountA),"error1");
        require(token.transfer(lp, amountB),"error2");
        require(token.transfer(marketing, amountC),"error3");
    }

}