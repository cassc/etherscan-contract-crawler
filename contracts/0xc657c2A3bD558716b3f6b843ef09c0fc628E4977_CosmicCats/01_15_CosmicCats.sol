// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC721A.sol";
import "./CosmicVoucherSigner.sol";
import "./CosmicVoucher.sol";

// Cosmic Cats v1.3

contract CosmicCats is ERC721A, Ownable, CosmicVoucherSigner {  
    using Address for address;
    using SafeMath for uint256;

    // Sale Controls
    bool public presaleActive = false;
    bool public reducedPresaleActive = false;
    bool public saleActive = false;

    // Mint Price
    uint256 public price = 0.04 ether;
    uint256 public reducedPrice = 0.03 ether;

    uint public MAX_SUPPLY = 8888;
    uint public PUBLIC_SUPPLY = 8688;
    uint public GIFT_SUPPLY = 200;  // 200 Reserved For Collabs, Team & Giveaways

    // Create New TokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Team Addresses
    address public a1 = 0x65e682bDC103884c3Cb3e82288a9F65a8d80CA54; // Justin
    address public a2 = 0xC033fCAa2Eb544A9873A8BF94C353E7620d74f0f; // Dontblink
    address public a3 = 0x84B304015790df208B401DEf59ADd3685848A871; // Skelligore
    
    // Community Multisig Wallet Address
    address public a4 = 0xBF600B4339F3dBe86f70ad1B171FD4Da2D2BA841; // Community Wallet

    // Presale Address List
    mapping (uint => uint) public claimedVouchers;

    // Base Link That Leads To Metadata
    string public baseTokenURI;

    // Contract Construction
    constructor ( 
    string memory newBaseURI, 
    address voucherSigner,
    uint256 maxBatchSize_,
    uint256 collectionSize_ 
    ) 
    ERC721A ("Cosmic Cats", "COSMIC", maxBatchSize_, collectionSize_) 
    CosmicVoucherSigner(voucherSigner) {
        setBaseURI(newBaseURI);
    }

    // ================ Mint Functions ================ //

    // Minting Function
    function mintCosmicCats(uint256 _amount) external payable {
        uint256 supply = totalSupply();
        require( saleActive, "Public Sale Not Active" );
        require( _amount > 0 && _amount <= maxBatchSize, "Can't Mint More Than 10" );
        require( supply + _amount <= PUBLIC_SUPPLY, "Not Enough Supply" );
        require( msg.value == price * _amount, "Incorrect Amount Of ETH Sent" );
        _safeMint( msg.sender, _amount);
    }

    // Presale Minting
    function mintPresale(uint256 _amount, CosmicVoucher.Voucher calldata v) public payable {
        uint256 supply = totalSupply();
        require(presaleActive, "Private Sale Not Active");
        require(claimedVouchers[v.voucherId] + _amount <= 3, "Max 3 During Presale");
        require(_amount <= 3, "Can't Mint More Than 3");
        require(v.to == msg.sender, "You Are NOT Whitelisted");
        require(CosmicVoucher.validateVoucher(v, getVoucherSigner()), "Invalid Voucher");
        require( supply + _amount <= PUBLIC_SUPPLY, "Not Enough Supply" );
        require( msg.value == price * _amount,   "Incorrect Amount Of ETH Sent" );
        claimedVouchers[v.voucherId] += _amount;
        _safeMint( msg.sender, _amount);
    }

    // Presale Reduced Minting
    function mintReducedPresale(uint256 _amount, CosmicVoucher.Voucher calldata v) public payable {
        uint256 supply = totalSupply();
        require(reducedPresaleActive, "Reduced Private Sale Not Active");
        require(claimedVouchers[v.voucherId] + _amount <= 1, "Max 1 During Reduced Presale");
        require(v.voucherId >= 6000, "Not Eligible For Reduced Mint");
        require(_amount <= 1, "Can't Mint More Than 1");
        require(v.to == msg.sender, "You Are NOT Whitelisted");
        require(CosmicVoucher.validateVoucher(v, getVoucherSigner()), "Invalid Voucher");
        require( supply + _amount <= PUBLIC_SUPPLY, "Not Enough Supply" );
        require( msg.value == reducedPrice * _amount,   "Incorrect Amount Of ETH Sent" );
        claimedVouchers[v.voucherId] += _amount;
        _safeMint( msg.sender, _amount);
    }

    // Validate Voucher
    function validateVoucher(CosmicVoucher.Voucher calldata v) external view returns (bool) {
        return CosmicVoucher.validateVoucher(v, getVoucherSigner());
    }

    // ================ Only Owner Functions ================ //

    // Gift Function - Collabs & Giveaways
    function gift(address _to, uint256 _amount) external onlyOwner() {
        uint256 supply = totalSupply();
        require( supply + _amount <= MAX_SUPPLY, "Not Enough Supply" );
        _safeMint( _to, _amount );
    }

     // Incase ETH Price Rises Rapidly
    function setPrice(uint256 newPrice) public onlyOwner() {
        price = newPrice;
    }

    // Set New baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // ================ Sale Controls ================ //

    // Pre Sale On/Off
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // Reduced Pre Sale On/Off
    function setReducedPresaleActive(bool val) public onlyOwner {
        reducedPresaleActive = val;
    }

    // Public Sale On/Off
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // ================ Withdraw Functions ================ //

    // Team Withdraw Function
    function withdrawTeam() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(a1, balance.mul(25).div(100)); // Justin
        _widthdraw(a2, balance.mul(25).div(100)); // Dontblink
        _widthdraw(a3, balance.mul(25).div(100)); // Skelligore
        _widthdraw(a4, address(this).balance); // Community Wallet
    }

    // Private Function -- Only Accesible By Contract
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // Emergency Withdraw Function -- Sends to Multisig Wallet
    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(a4).transfer(balance);
    }

}