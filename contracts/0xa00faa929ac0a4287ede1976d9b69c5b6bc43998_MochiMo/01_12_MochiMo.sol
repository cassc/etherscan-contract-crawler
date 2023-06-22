// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract MochiMo is ERC721A, Ownable, PaymentSplitter {

    using ECDSA for bytes32;

    // Settings
    string public baseURI;
    uint256 private _teamLength;
    uint256 constant public MAX_SUPPLY = 4444;

    // Public settings
    uint256 constant public MAX_MINT_PUBLIC = 3;
    uint256 public mintPricePublic = 0.015 ether;   
    mapping(address => uint256) private _mintedAmountPublic;

    // Whitelist settings
    uint256 constant public MAX_MINT_WHITELIST = 2;
    uint256 constant public WHITELIST_SUPPLY = 3111;
    uint256 public mintPriceWhitelist = 0.009 ether;
    address private _signerAddressWhitelist;
    mapping(address => uint256) private _mintedAmountWhitelist;

    // VIP settings
    uint256 constant public MAX_MINT_VIP = 1;
    uint256 constant public VIP_SUPPLY = 222;
    address private _signerAddressVip;
    mapping(address => uint256) private _mintedAmountVip;

    // Team settings
    bool private teamSupplyMinted = false;
    uint256 public teamSupply = 30;

    // Sale config
    enum MintStatus {
        CLOSED,
        VIP,
        WHITELIST,
        PUBLIC
    }
    MintStatus public mintStatus = MintStatus.CLOSED;

    constructor(
        string memory _initialBaseURI,
        address signerAddressWhitelist_,
        address signerAddressVip_,
        address[] memory payments,
        uint256[] memory shares
    ) 
        ERC721A("Mochi Mo", "MM")
        PaymentSplitter(payments, shares)
    {
        baseURI = _initialBaseURI;
        _signerAddressWhitelist = signerAddressWhitelist_;
        _signerAddressVip = signerAddressVip_;
        _teamLength = payments.length;

        // Developer mint during smart contract creation
        _safeMint(msg.sender, 1);
    }

    modifier mintCompliance(uint256 amount) {
        require(tx.origin == msg.sender, "Only humans are allowed to mint!");
        require(amount > 0, "Can't mint zero!");
        require(totalSupply() + amount <= MAX_SUPPLY, "There are no more Mochi Mos available!");
        _;
    }

    // Metadata
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Public metadata
    function setMintPricePublic(uint256 _newMintPricePublic) external onlyOwner {
        mintPricePublic = _newMintPricePublic;
    }

    // Whitelist metadata
    function setMintPriceWhitelist(uint256 _newMintPriceWhitelist) external onlyOwner {
        mintPriceWhitelist = _newMintPriceWhitelist;
    }

    function setSignerAddressWhitelist(address _newSignerAddressWhitelist) external onlyOwner {
        _signerAddressWhitelist = _newSignerAddressWhitelist;
    }

    // VIP metadata
    function setSignerAddressVip(address _newSignerAddressVip) external onlyOwner {
        _signerAddressVip = _newSignerAddressVip;
    }

    // Team metadata
    function setTeamSupply(uint256 _newTeamSupply) external onlyOwner {
        teamSupply = _newTeamSupply;
    }

    // Sale metadata
    function setMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    // Withdraw funds
    function releaseAll() external onlyOwner {
        for(uint i = 0; i < _teamLength; i++) {
            release(payable(payee(i)));
        }
    }

    // Mint
    function mintPublic(uint256 amount) external payable mintCompliance(amount) {
        require(mintStatus == MintStatus.PUBLIC, "Public sale is inactive!");
        require(_mintedAmountPublic[msg.sender] + amount <= MAX_MINT_PUBLIC, "Can't mint that many over public!");
        require(msg.value >= mintPricePublic * amount, "The ether value sent is not correct!");
        require(totalSupply() + amount <= MAX_SUPPLY - teamSupply, "Public sale is sold out!");
  
        _mintedAmountPublic[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintWhitelist(uint256 amount, bytes calldata signature) external payable mintCompliance(amount) {
        require(mintStatus == MintStatus.WHITELIST, "Whitelist sale is inactive!");
        require(_mintedAmountWhitelist[msg.sender] + amount <= MAX_MINT_WHITELIST, "Can't mint that many over whitelist!");
        require(msg.value >= mintPriceWhitelist * amount, "The ether value sent is not correct!");
        require(totalSupply() + amount <= WHITELIST_SUPPLY + VIP_SUPPLY, "Whitelist sale is sold out!");

        require(_signerAddressWhitelist == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature), "Not on whitelist!");

        _mintedAmountWhitelist[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintVip(uint256 amount, bytes calldata signature) external mintCompliance(amount) {
        require(mintStatus == MintStatus.VIP, "VIP sale is inactive!");
        require(_mintedAmountVip[msg.sender] + amount <= MAX_MINT_VIP, "Can't mint that many over VIP!");
        require(totalSupply() + amount <= VIP_SUPPLY, "VIP sale is sold out!");

        require(_signerAddressVip == keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        ).recover(signature), "Not a VIP!");

        _mintedAmountVip[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintTeam(address _recipient) external mintCompliance(teamSupply) onlyOwner {
        require(!teamSupplyMinted, "The team supply was already minted!");
            
        _safeMint(_recipient, teamSupply);

        teamSupplyMinted = true;
    }
}