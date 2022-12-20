// SPDX-License-Identifier: MIT

// • ▌ ▄ ·. ▪  ▄▄▄   ▄▄▄·  ▄▄ • ▄▄▄ .     ▄▄· ▪  ▄▄▄▄▄ ▄· ▄▌
// ·██ ▐███▪██ ▀▄ █·▐█ ▀█ ▐█ ▀ ▪▀▄.▀·    ▐█ ▌▪██ •██  ▐█▪██▌
// ▐█ ▌▐▌▐█·▐█·▐▀▀▄ ▄█▀▀█ ▄█ ▀█▄▐▀▀▪▄    ██ ▄▄▐█· ▐█.▪▐█▌▐█▪
// ██ ██▌▐█▌▐█▌▐█•█▌▐█ ▪▐▌▐█▄▪▐█▐█▄▄▌    ▐███▌▐█▌ ▐█▌· ▐█▀·.
// ▀▀  █▪▀▀▀▀▀▀.▀  ▀ ▀  ▀ ·▀▀▀▀  ▀▀▀     ·▀▀▀ ▀▀▀ ▀▀▀   ▀ •

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ShadowPassAuthority.sol";
import "./ShadowPass.sol";
import "./ERC721A.sol";

contract MirageCity is DefaultOperatorFilterer, ERC721A, Ownable, ShadowPassAuthority {  
    using SafeMath for uint256;

    bool public presaleActive = false;
    bool public saleActive = false;

    uint256 public wl_price = 0.05 ether;
    uint256 public public_price = 0.07 ether;

    uint public max_supply = 7777;
    uint public max_mint = 5;

    string public baseTokenURI;

    mapping (uint => uint) public claimedShadowPasses;

    address public a1 = 0x0B819364c33db9EEB9E3025e0d20BBbadb3f537b;
    address public a2 = 0xE4467bD555d9DC1139b7BA926801C68A3e301005;
    address public a3 = 0xFA200E446A97341723Ec780257C907a76Bc2D879;
    address public a4 = 0x6C6A14d4d8d8dc5c84956BacBEcA79456Fe89a2a;

    constructor ( string memory newBaseURI, address shadowSigner ) 
    ERC721A ( "Mirage City", "MIRAGE" ) 
    ShadowPassAuthority( shadowSigner ) { setBaseURI( newBaseURI ); }

    // ================ Mint Functions ================ //

    // Public Mint
    function mintPublic(uint256 _amount) external payable {
        require( msg.sender == tx.origin, "Not allowed" );
        require( saleActive, "Public Sale Not Active" );
        require( _amount > 0 && _amount <= max_mint, "Can't Mint More Than 5 Per Transaction" );
        require( totalSupply() + _amount <= max_supply, "All Agents Allocated" );
        require( msg.value == public_price * _amount, "Not Enough ETH Sent" );
        _safeMint( msg.sender, _amount);
    }

    // Whitelist Mint
    function mintPresale(uint256 _amount, ShadowPassMain.ShadowPass calldata sp) public payable {
        require( ShadowPassMain.validateShadowPass(sp, getShadowSigner()), "Unauthorized ShadowPass Detected" );
        require( sp.to == msg.sender, "ShadowPass Input Does NOT Match Sender" );
        require( presaleActive, "Presale Not Active" );
        require( claimedShadowPasses[sp.shadowPassID] + _amount <= 3, "Max 3 During Presale" );
        require( _amount > 0 && _amount <= 3, "Can't Mint More Than 3" );
        require( totalSupply() + _amount <= max_supply, "All Agents Allocated" );
        require( msg.value == wl_price * _amount,   "Not Enough ETH Sent" );
        claimedShadowPasses[sp.shadowPassID] += _amount;
        _safeMint( msg.sender, _amount);
    }

    function validateShadowPass(ShadowPassMain.ShadowPass calldata sp) external view returns (bool) {
        return ShadowPassMain.validateShadowPass(sp, getShadowSigner());
    }

    // ================ Only Owner Functions ================ //

    function adminMint(address _to, uint256 _amount) external onlyOwner() {
        require( totalSupply() + _amount <= max_supply, "All Agents Allocated" );
        _safeMint( _to, _amount );
    }

    function setWLPrice(uint256 _newPrice) public onlyOwner() {
        wl_price = _newPrice;
    }

    function setPublicPrice(uint256 _newPrice) public onlyOwner() {
        public_price = _newPrice;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseTokenURI = _newURI;
    }

    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    function setSaleActive(bool val) public onlyOwner {
        saleActive = val;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function teamWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(a1, balance.mul(30).div(100));
        _widthdraw(a2, balance.mul(30).div(100));
        _widthdraw(a3, balance.mul(30).div(100));
        _widthdraw(a4, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    // ================ Opensea Operator Filter Functions ================ //

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}