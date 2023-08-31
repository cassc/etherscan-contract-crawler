// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FlashGenesisPass is ERC1155Supply, Ownable {
    using SafeMath for uint256;
    bool public saleEthStatus = false;
    bool public saleTokenStatus = false;
    uint256 constant TOKEN_ID = 555;
    uint256 constant MARKETING_TOKENS = 5;
    uint256 public MAX_TOKENS_PER_MINT = 1;
    uint256 constant TOTAL_SUPPLY = 555;
    uint256 public TOTAL_UNLOCKD_SUPPLY = 105;
    uint256 public MINT_PRICE = 0.5 ether;
    string private _NAME;
    uint256 public FLASH_DECIMAL = 18; 
    uint256 public MINT_PRICE_FLASH_TOKENS = 1000000 * 10**FLASH_DECIMAL;
    IERC20 public token;
    address public constant deadAddress = address(0xdead);

    mapping(address => bool) public hasUsedWL;
    mapping(address => bool) public isWL;
    bool public isWhitelistEnabled = true;
    
    event Minted(uint256 _totalSupply);

    constructor(string memory uri) ERC1155(uri) {
        token = IERC20(0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47);
        _NAME = "Flash Genesis Pass";
        _mint(msg.sender, TOKEN_ID, MARKETING_TOKENS, "");
    }

    function updateToken(address tokenAddres) external onlyOwner {
        token = IERC20(tokenAddres);
    }

    function setSaleETHStatus(bool newState) public onlyOwner {
        saleEthStatus = newState;
    }

    function setSaleTokenStatus(bool newState) public onlyOwner {
        saleTokenStatus = newState;
    }
    
    function addWhiteLists(address[] memory _whitelists) external onlyOwner{
        for (uint256 index = 0; index < _whitelists.length; index++) {
            isWL[_whitelists[index]] = true;
            hasUsedWL[_whitelists[index]] = false;
        }
    }

    function getWhitelistStatus(address _whitelists) external view returns(bool){
        return isWL[_whitelists];
    }

    function getWhitelistUsedStatus(address _whitelists) external view returns(bool){
        return hasUsedWL[_whitelists];
    }

    function burn(address account, uint256 id, uint256 amount) public {
        require(msg.sender == account);
        _burn(account, id, amount);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function totalSupply() external view returns (uint256) {
        return totalSupply(TOKEN_ID);
    }

    function maxSupply() external pure returns (uint256) {
        return TOTAL_SUPPLY;
    }
      
    function setMintPriceETH(uint256 _price) external onlyOwner {
       MINT_PRICE = _price * 1 ether / 10;
    }

    function setMintPriceToken(uint256 _price) external onlyOwner {
       MINT_PRICE_FLASH_TOKENS = _price * 10**FLASH_DECIMAL;
    }

    function setMaxTokenPerMnt(uint256 _tokenPerMint) external onlyOwner {
       MAX_TOKENS_PER_MINT = _tokenPerMint;
    }

    function setWhitelistEnabled(bool _status) external onlyOwner {
       isWhitelistEnabled = _status;
    }

    function updateMintableTokens(uint256 _count) external onlyOwner {
        require(_count > 0, "Invalid Input");
        TOTAL_UNLOCKD_SUPPLY = TOTAL_UNLOCKD_SUPPLY + _count;
        require(TOTAL_UNLOCKD_SUPPLY <= TOTAL_SUPPLY, "Can not mint more than total supply");
    }

    function balanceOf(address account) external view virtual returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return  balanceOf(account, TOKEN_ID);
    }
    function name() external view returns (string memory) {
        return _NAME;
    }

    function recoverToken(address _to,uint256 _tokenamount) external onlyOwner returns(bool _sent){
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        require(_contractBalance >= _tokenamount);
        _sent = IERC20(token).transfer(_to, _tokenamount);
    }

    function burnToken() external onlyOwner returns(bool _sent){
        uint256 _contractBalance = IERC20(token).balanceOf(address(this));
        require(_contractBalance > 0);
        _sent = IERC20(token).transfer(deadAddress, _contractBalance);
    }

    receive() external payable {}

    function approveTokens(uint256 _tokenamount) external returns(bool){
       IERC20(token).approve(address(this), _tokenamount);
       return true;
   }

   function checkAllowance(address sender) public view returns(uint256){
       return IERC20(token).allowance(sender, address(this));
   }

    function mint(uint numberOfTokens) external payable {
        require(saleEthStatus, "Sale is Not active For ETh");
        require(numberOfTokens <= MAX_TOKENS_PER_MINT, "Max Limit per transaction Reached");
        require(totalSupply(TOKEN_ID) + numberOfTokens <= TOTAL_UNLOCKD_SUPPLY, "Total unlocked supply exceeds");
        require(totalSupply(TOKEN_ID) + numberOfTokens <= TOTAL_SUPPLY, "Total supply exceeds");
        require(MINT_PRICE * numberOfTokens <= msg.value, "Insufficient Balance");
        if(isWhitelistEnabled){
            require(!hasUsedWL[msg.sender], "Already minted");
            require(isWL[msg.sender], "Not whitelisted");
            hasUsedWL[msg.sender] = true;
        }
        _mint(msg.sender, TOKEN_ID, numberOfTokens, "");
        
        emit Minted(totalSupply(TOKEN_ID));
    }

    function mintUsingToken(uint256 _tokenamount,uint numberOfTokens) public returns(bool) {
        require(_tokenamount <= checkAllowance(msg.sender), "Please approve tokens before transferring");
        require(saleTokenStatus, "Sale is Not active For Token");
        require(numberOfTokens <= MAX_TOKENS_PER_MINT, "Max Limit per transaction Reached");
        require(totalSupply(TOKEN_ID) + numberOfTokens <= TOTAL_UNLOCKD_SUPPLY, "Total unlocked supply exceeds");
        require(totalSupply(TOKEN_ID) + numberOfTokens <= TOTAL_SUPPLY, "Total supply exceeds");
        require(MINT_PRICE_FLASH_TOKENS * numberOfTokens <= _tokenamount, "Insufficient Balance");
        if(isWhitelistEnabled){
            require(!hasUsedWL[msg.sender], "Already minted");
            require(isWL[msg.sender], "Not whitelisted");
            hasUsedWL[msg.sender] = true;
        }
        IERC20(token).transferFrom(msg.sender,address(this), _tokenamount);
        _mint(msg.sender, TOKEN_ID, numberOfTokens, "");
        
        emit Minted(totalSupply(TOKEN_ID));
       return true;
   }
}