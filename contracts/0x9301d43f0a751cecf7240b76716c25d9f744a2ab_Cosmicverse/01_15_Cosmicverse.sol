// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721A.sol";
import "./CosmicverseVoucherSigner.sol";
import "./CosmicverseVoucher.sol";

// Cosmicverse v1.2

contract Cosmicverse is ERC721A, Ownable, CosmicverseVoucherSigner {  
    using Address for address;
    using SafeMath for uint256;

    // Sale Controls
    bool public presaleActive = false;
    bool public saleActive = false;
    bool public claimActive = false;

    // Mint Price
    uint256 public price = 0.05 ether;

    // Token Supply
    uint public MAX_SUPPLY = 8888; // Max Collection Supply.
    uint public RESERVE_AMOUNT = 1702; // Free planet claim reserve.
    uint public GIFT_SUPPLY = 200;  // 200 Reserved for marketing, collabs and team.
    uint public PUBLIC_SUPPLY = MAX_SUPPLY - RESERVE_AMOUNT - GIFT_SUPPLY; // Total available during pre-sale and public sale.

    uint public MAX_MINT = 3;

    // Create New TokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Team Addresses
    address public a1 = 0xe225e1f3a614e2e9e8A6E1F39b08024f36078a55; 
    address public a2 = 0xC033fCAa2Eb544A9873A8BF94C353E7620d74f0f; 
    address public a3 = 0x84B304015790df208B401DEf59ADd3685848A871; 
    address public a4 = 0x0D3e47eCc0F3Be09Ae111F712A7fca35Cb58fA34; 
    address public a5 = 0xD914622B62C5E01C9D5a1FBb34D86FDC5b872124; 
    address public a6 = 0x889f2aa04D67AcFB522D3CCE158c40b140A61693; 
    
    // Multisig Wallet
    address public aMulti = 0xBF600B4339F3dBe86f70ad1B171FD4Da2D2BA841;

    // Address Mapping
    mapping (uint => uint) public claimedVouchers;
    mapping (uint => uint) public claimedPlanets;

    // Base Link That Leads To Metadata
    string public baseTokenURI;

    // Contract Construction
    constructor (string memory newBaseURI, address voucherSigner) 
    ERC721A ("Cosmicverse", "COSMICVERSE") 
    CosmicverseVoucherSigner(voucherSigner) {
        setBaseURI(newBaseURI);
    }

    // ================ Mint Functions ================ //

    // Minting Function
    function mintPlanets(uint256 _amount) external payable {
        require(msg.sender == tx.origin, "Not allowed");
        require(saleActive, "Public Sale Not Active" );
        require(_amount > 0 && _amount <= MAX_MINT, "Max 3 during public sale" );
        require(totalSupply() + _amount <= PUBLIC_SUPPLY, "All planets have been claimed.");
        require(msg.value == price * _amount, "Incorrect Amount Of ETH Sent" );
        _safeMint(msg.sender, _amount);
    }

    // Presale Minting
    function mintPresale(uint256 _amount, CosmicverseVoucher.Voucher calldata v) public payable {
        require(presaleActive, "Private Sale Not Active");
        require(claimedVouchers[v.voucherId] + _amount <= MAX_MINT, "Max 3 during presale");
        require(_amount <= MAX_MINT, "Can't Mint More Than 3");
        require(v.to == msg.sender, "You Are NOT Whitelisted");
        require(CosmicverseVoucher.validateVoucher(v, getVoucherSigner()), "Invalid Voucher");
        require(totalSupply() + _amount <= PUBLIC_SUPPLY, "All planets have been claimed.");
        require(msg.value == price * _amount,   "Incorrect Amount Of ETH Sent" );
        claimedVouchers[v.voucherId] += _amount;
        _safeMint(msg.sender, _amount);
    }

    // Free Planet Claim
    function claimPlanets(CosmicverseVoucher.Voucher calldata v) public {
        require(claimActive, "Claim period not active.");
        require(v.maxMint > 0, "You aren't eligible to claim planets.");
        require(claimedPlanets[v.voucherId] < v.maxMint, "You've claimed your planets.");
        require(v.to == msg.sender, "You Are NOT on claim list.");
        require(CosmicverseVoucher.validateVoucher(v, getVoucherSigner()), "Invalid Voucher.");
        require(totalSupply() + v.maxMint <= MAX_SUPPLY, "All planets have been claimed.");
        claimedPlanets[v.voucherId] += v.maxMint;
        _safeMint(msg.sender, v.maxMint);
    }

    // Validate Voucher
    function validateVoucher(CosmicverseVoucher.Voucher calldata v) external view returns (bool) {
        return CosmicverseVoucher.validateVoucher(v, getVoucherSigner());
    }

    // ================ Only Owner Functions ================ //

    // Gift Function - Collabs & Giveaways
    function gift(address _to, uint256 _amount) external onlyOwner() {
        require(totalSupply() + _amount <= MAX_SUPPLY, "All planets have been claimed.");
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

    // Public Sale On/Off
    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    // Planet Claim On/Off
    function setClaimActive(bool val) public onlyOwner {
        claimActive = val;
    }

    // ================ Withdraw Functions ================ //

    // Team Withdraw Function
    function withdrawTeam() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(a1, balance.mul(25).div(100)); 
        _widthdraw(a2, balance.mul(25).div(100)); 
        _widthdraw(a3, balance.mul(11).div(100)); 
        _widthdraw(a4, balance.mul(13).div(100)); 
        _widthdraw(a5, balance.mul(13).div(100)); 
        _widthdraw(a6, address(this).balance);
    }

    // Private Function -- Only Accesible By Contract
    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // Emergency Withdraw Function
    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(aMulti).transfer(balance);
    }

}