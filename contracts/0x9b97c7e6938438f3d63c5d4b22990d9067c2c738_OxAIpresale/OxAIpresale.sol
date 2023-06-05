/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract OxAIpresale is Ownable {

    mapping(address => uint256) public walletBalances;

    address tokenOwner;

    address tokenAddress;

    bool openToClaim = false;


    function DepositForPresale() external payable {
        uint256 amount = msg.value;
        walletBalances[msg.sender] += amount;
    }

    function addTokensOwner(address _TokenOwner) external onlyOwner{
      tokenOwner = _TokenOwner;
    }

    function addTokenAddress(address _TokenAddress) external onlyOwner{
      tokenAddress = _TokenAddress;
    }

    function claim() external  {
        require(openToClaim, "Not open yet");
        IERC20(tokenAddress).transferFrom(tokenOwner, msg.sender, walletBalances[msg.sender]);
        walletBalances[msg.sender] = 0;
    }

    function addLiquidity(uint256 tokenAmountForLP) external onlyOwner{
      payable(owner()).transfer(address(this).balance);
    }


    function openClaiming() external onlyOwner {
      openToClaim = true;
    }
}