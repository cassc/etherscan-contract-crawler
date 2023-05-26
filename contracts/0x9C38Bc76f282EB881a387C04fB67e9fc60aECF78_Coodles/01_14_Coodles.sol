// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC1155/IERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/utils/Counters.sol";


/**
 * @title Coodles contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation.
 * Optimized to no longer use ERC721Enumarable , but still provide a totalSupply() implementation.
 * @author @FrankPoncelet
 * 
 */

contract Coodles is Ownable, ERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenSupply;
    
    uint256 public tokenPrice = 0.045 ether; 
    uint256 public budgetFrank = 31.9968 ether; 
    uint256 public budgetSpencer = 9.59904 ether; 
    uint256 public budgetSimStone = 1.5 ether; 
    uint256 public constant MAX_TOKENS=8888;
    uint public constant MAX_PURCHASE = 26; // set 1 to high to avoid some gas
    uint public constant MAX_RESERVE = 26; // set 1 to high to avoid some gas
    
    bool public saleIsActive;
    bool public preSaleIsActive;
    bool public notIncreased=true;
    // Base URI for Meta data
    string private _baseTokenURI;
    
    address public coolCats = 0x1A92f7381B9F03921564a437210bB9396471050C;
    address public doodles = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
    address public mintpass = 0xD6cF1cdceE148E59e8c9d5E19CFEe3881892959e; 
    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address private constant FRANK = 0xF40Fd88ac59A206D009A07F8c09828a01e2ACC0d;
    address private constant SPENCER = 0x9840aECDcE9A75711942922357EB70eC44DF015F;
    address private constant SIMSTONE = 0x4d33c6485c8cd80E04b46eb5372DeA1D24D88B44; 
    address private constant VAULT = 0xE6232CE1d78500DC9377daaE7DD87A609d2E8259; 
    
    event priceChange(address _by, uint256 price);
    event PaymentReleased(address to, uint256 amount);
    
    constructor() ERC721("Coodles", "CDL") {
        _baseTokenURI = "ipfs://QmZpWD9oGzPQRTknJ3XMCpfobEByyq9zufrYSJMZkZtLF5/"; 
        _tokenSupply.increment();
        _safeMint( FRANK, 0);
    }

    /**
    * Change the OS proxy if ever needed.
    */
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * Used to mint Tokens to the teamMembers
     */
    function reserveTokens(address to,uint numberOfTokens) public onlyOwner {    
        uint supply = _tokenSupply.current();
        require(supply.add(numberOfTokens) <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
        require(numberOfTokens < MAX_RESERVE, "Can only mint 25 tokens at a time");
        for (uint i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
            _tokenSupply.increment();
        }
    }
    
    function reserveTokens() external onlyOwner {    
        reserveTokens(owner(),MAX_RESERVE);
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    /**
     * @dev Set the base token URI
     */
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * Pause sale if active, make active if paused
     */
    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }
    
    /**    
    * Set mintPass contract address
    */
    function setDoodlePass(address newAddress) external onlyOwner {
         doodles = newAddress;
    }

    /**    
    * Set mintPass contract address
    */
    function setMintPass(address newAddress) external onlyOwner {
         mintpass = newAddress;
    }
    /**    
    * Set mintPass contract address
    */
    function setCoolCatPass(address newAddress) external onlyOwner {
         coolCats = newAddress;
    }
    /**     
    * Set price 
    */
    function setPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
        emit priceChange(msg.sender, tokenPrice);
    }

    function mint(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        iternalMint(numberOfTokens);
    }

    function preSalemint(uint256 numberOfTokens) external payable {
        require(preSaleIsActive, "Sale must be active to mint Tokens");
        require(hasMintPass(msg.sender), "Must have a mintpass");
        iternalMint(numberOfTokens);
    }

    function hasMintPass(address sender) public view returns (bool){
        if(sender==address(0)){
            return false;
        } else if (IERC1155(mintpass).balanceOf(sender,1)>0){
            return true;
        } else if (IERC721(coolCats).balanceOf(sender)>0){
            return true;
        } else if (IERC721(doodles).balanceOf(sender)>0){
            return true;
        }
        return false;
    }

    function iternalMint(uint256 numberOfTokens) private{
        require(numberOfTokens > 0, "numberOfNfts cannot be 0");
        require(numberOfTokens < MAX_PURCHASE, "Can only mint 25 tokens at a time");
        uint256 supply = _tokenSupply.current();
        require(supply.add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
        require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");  
        for(uint256 i; i < numberOfTokens; i++){
            _safeMint( msg.sender, supply + i );
            _tokenSupply.increment();
        }
    }
    
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficent balance");
        uint256 witdrawAmount = calculateWithdraw(budgetFrank,(balance * 20) / 100);
        if (witdrawAmount>0){
            budgetFrank -= witdrawAmount;
            _withdraw(FRANK, witdrawAmount);
        }
        witdrawAmount = calculateWithdraw(budgetSpencer,(balance * 6) / 100);
        if (witdrawAmount>0){
            budgetSpencer -= witdrawAmount;
            _withdraw(SPENCER, witdrawAmount);
        }
        if (totalSupply()>3555 && notIncreased){
            notIncreased=false;
            budgetSimStone += 2 ether;
        }
        witdrawAmount = calculateWithdraw(budgetSimStone,(balance * 70) / 100);
        if (witdrawAmount>0){
            budgetSimStone -= witdrawAmount;
            _withdraw(SIMSTONE, witdrawAmount);
        }
        witdrawAmount = (balance * 3) / 100;
        _withdraw(owner(), witdrawAmount);
        _withdraw(VAULT, address(this).balance);
        emit PaymentReleased(owner(), balance);
    }

    function calculateWithdraw(uint256 budget, uint256 proposal) private pure returns (uint256){
        if (proposal>budget){
            return budget;
        } else{
            return proposal;
        }
    }
    
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{ value: _amount }("");
        require(success, "Failed to widthdraw Ether");
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view returns (uint256) {
        return _tokenSupply.current();
    }

    /**
    * override isApprovedForAll to allow the OS Proxie to list without fees.
    */
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if (operator == proxyRegistryAddress) {
            return true;
        }
        return super.isApprovedForAll(_owner, operator);
    }

    // contract can recieve Ether
    fallback() external payable { }
    receive() external payable { }
}