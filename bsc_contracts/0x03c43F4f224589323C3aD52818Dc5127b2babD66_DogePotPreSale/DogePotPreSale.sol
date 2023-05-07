/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

contract DogePotPreSale is Ownable {
    IERC20 public token;
    uint256 public tokenprice;
    uint256 public totalsold;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalRaised;
    
    mapping(address => uint256) public tokensPurchased;
    mapping(address => uint256) public bnbContributed;

    event Sell(address sender,uint256 totalvalue);

    modifier withinSalePeriod() {
        require(block.timestamp >= startDate && block.timestamp <= endDate, "TokenPreSale: not within sale period");
        _;
    }
   
    constructor(address _tokenaddress, uint256 _tokenvalue, uint256 _startDate, uint256 _endDate) {
        tokenprice = _tokenvalue;
        token  = IERC20(_tokenaddress);
        startDate = _startDate;
        endDate = _endDate;
        softCap = 4 ether;
        hardCap = 8 ether;
    }
   
    function buyTokens() public payable withinSalePeriod {
        uint256 bnbAmount = msg.value;
        require(totalRaised + bnbAmount <= hardCap, "TokenPreSale: hard cap reached");

        uint256 tokenAmount = bnbAmount * tokenprice;
        require(token.balanceOf(address(this)) >= tokenAmount, 'TokenPreSale: insufficient tokens in contract');

        tokensPurchased[msg.sender] += tokenAmount;
        bnbContributed[msg.sender] += bnbAmount;
        totalRaised += bnbAmount;

        emit Sell(msg.sender, tokenAmount);
    }

    function claimTokens() public {
        require(block.timestamp > endDate, "TokenPreSale: presale not ended yet");
        require(totalRaised >= softCap, "TokenPreSale: soft cap not reached");

        uint256 purchasedTokens = tokensPurchased[msg.sender];
        require(purchasedTokens > 0, "TokenPreSale: no tokens to claim");

        tokensPurchased[msg.sender] = 0;
        token.transfer(msg.sender, purchasedTokens);
    }

    function refund() public {
        require(block.timestamp > endDate, "TokenPreSale: presale not ended yet");
        require(totalRaised < softCap, "TokenPreSale: soft cap reached");

        uint256 contributedBNB = bnbContributed[msg.sender];
        require(contributedBNB > 0, "TokenPreSale: no BNB to refund");

        bnbContributed[msg.sender] = 0;
        payable(msg.sender).transfer(contributedBNB);
    }

    function endsale() public onlyOwner {
        require(block.timestamp > endDate, "TokenPreSale: presale not ended yet");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
    
    function withdrawFunds() public onlyOwner {
    require(block.timestamp > endDate, "TokenPreSale: presale not ended yet");
    require(totalRaised >= softCap, "TokenPreSale: soft cap not reached");

    uint256 balance = address(this).balance;
    require(balance > 0, "TokenPreSale: no BNB to withdraw");

    payable(owner()).transfer(balance);
}
}