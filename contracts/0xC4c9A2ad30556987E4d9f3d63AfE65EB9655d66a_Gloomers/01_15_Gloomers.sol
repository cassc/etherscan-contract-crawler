// SPDX-License-Identifier: MIT

//     ▄██████▄   ▄█        ▄██████▄   ▄██████▄    ▄▄▄▄███▄▄▄▄      ▄████████    ▄████████    ▄████████ 
//    ███    ███ ███       ███    ███ ███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███   ███    ███   ███    ███ 
//    ███    █▀  ███       ███    ███ ███    ███ ███   ███   ███   ███    █▀    ███    ███   ███    █▀  
//   ▄███        ███       ███    ███ ███    ███ ███   ███   ███  ▄███▄▄▄      ▄███▄▄▄▄██▀   ███        
//  ▀▀███ ████▄  ███       ███    ███ ███    ███ ███   ███   ███ ▀▀███▀▀▀     ▀▀███▀▀▀▀▀   ▀███████████ 
//    ███    ███ ███       ███    ███ ███    ███ ███   ███   ███   ███    █▄  ▀███████████          ███ 
//    ███    ███ ███▌    ▄ ███    ███ ███    ███ ███   ███   ███   ███    ███   ███    ███    ▄█    ███ 
//    ████████▀  █████▄▄██  ▀██████▀   ▀██████▀   ▀█   ███   █▀    ██████████   ███    ███  ▄████████▀  
//               ▀                                                              ███    ███              

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./GloomersVoucherSigner.sol";
import "./GloomersVoucher.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Gloomers v1.2

contract Gloomers is ERC721A, Ownable, GloomersVoucherSigner {  
    using Address for address;
    using SafeMath for uint256;

    // Sale Controls
    bool public presaleActive = false;
    bool public saleActive = false;

    uint public constant MAX_SUPPLY = 5000;
    uint public constant MAX_PUBLIC = 4900;
    uint public constant MAX_MINT = 2;

    // Create New TokenURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // Presale Address Mapping
    mapping (uint => uint) public claimedVouchers;

    // Public Sale Address Mapping
    mapping(address => uint256) public claimedAddress;

    // Base Link That Leads To Metadata
    string public baseTokenURI;

    // Contract Construction
    constructor ( 
    string memory newBaseURI, 
    address voucherSigner
    ) 
    ERC721A ("Gloomers", "GLOOM") 
    GloomersVoucherSigner(voucherSigner) {
        setBaseURI(newBaseURI);
    }

    // ================ Mint Functions ================ //

    // Minting Function
    function mintGloomers() external {
        require(msg.sender == tx.origin, "Not allowed");
        require(saleActive, "Public sale not active");
        require(claimedAddress[msg.sender] < MAX_MINT, "You've already claimed your free Gloomers, don't be greedy!");
        require(totalSupply() + 2 <= MAX_PUBLIC, "All Gloomers have been minted!");
        claimedAddress[msg.sender] += 2;
        _safeMint(msg.sender, 2);
    }

    // Presale Minting
    function mintPresale(GloomersVoucher.Voucher calldata v) public {
        require(presaleActive, "Pre-sale not active");
        require(claimedVouchers[v.voucherId] < MAX_MINT, "You can only claim 2 Gloomers during pre-sale.");
        require(v.to == msg.sender, "You are NOT whitelisted");
        require(GloomersVoucher.validateVoucher(v, getVoucherSigner()), "Invalid Voucher");
        require(totalSupply() + 2 <= MAX_PUBLIC, "All Gloomers have been minted!");
        claimedVouchers[v.voucherId] += 2;
        _safeMint(msg.sender, 2);
    }

    // Validate Voucher
    function validateVoucher(GloomersVoucher.Voucher calldata v) external view returns (bool) {
        return GloomersVoucher.validateVoucher(v, getVoucherSigner());
    }

    // ================ Only Owner Functions ================ //

    // Gift Function - Collabs & Giveaways
    function gift(address _to, uint256 _amount) external onlyOwner() {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Not Enough Supply");
        _safeMint( _to, _amount);
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

}