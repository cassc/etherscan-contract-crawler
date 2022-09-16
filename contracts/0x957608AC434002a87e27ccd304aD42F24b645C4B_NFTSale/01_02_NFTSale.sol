// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTSale {
    address public owner;
    
    mapping(address=>uint256[]) userData;
    mapping(uint256=>uint256) public nftPrice;
    
    event tokenTransfer(address from, address to, uint256 amount);
    
    event coinTransfer(address from, address to, uint256 amount);
    
    event ownerWithdraw(address to, uint256 amount);
    
    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    modifier isbalanceEnough(address _tokenAddress, uint256 _amount) {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        require(balance >= _amount, "balance not enogh");
        _;
    }

    constructor(
        address _owner
    ) {
        owner = _owner;
    }
     
    function updateOwner(address _owner) external onlyOwner
    {
        owner = _owner;
    }

    function tokenPayment(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount
    ) external priceGreaterThanZero(_amount) 
    {
        tokenTransaction(_tokenAddress, msg.sender, address(this), _amount);
        userData[msg.sender].push(_tokenId);
        nftPrice[_tokenId] = _amount;
        emit tokenTransfer(msg.sender, address(this), _amount);
    }

    function coinPayment(uint256 _tokenId)
        external
        payable
        priceGreaterThanZero(msg.value)
    {
        userData[msg.sender].push(_tokenId);
        nftPrice[_tokenId] = msg.value;
        emit coinTransfer(msg.sender, address(this), msg.value);
    }

    function tokenWithdraw(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
        isbalanceEnough(_tokenAddress, _amount)
    {
        IERC20(_tokenAddress).transfer(owner, _amount);
    }
    
    function withdrawCoin(uint256 _amount) external onlyOwner
    {
        coinTransaction(owner, _amount);
    }

    function getUserData(address _user) external view returns(uint256[] memory)
    {
        return userData[_user];
    }

    
    function tokenTransaction(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20(_tokenAddress).transferFrom(_from, _to, _amount);
    }

    function coinTransaction(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "refund failed");
    }

    receive() payable external {}
}