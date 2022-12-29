// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./ERC721A.sol";

contract SploogeZone is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    
    uint256 public bssplgwallet;
    uint256 public jrsplgwallet;
    uint256 public yledsplgwallet;
    uint256 public lmblsplgwallet;
    uint256 public aypndsplgwallet;
    uint256 public nwosplgwallet;
    uint256 public baseSplge = 999;
    uint256 public JrSplge = 400;
    uint256 public LMBLSplge = 200;
    uint256 public YLEDSplge = 99;
    uint256 public AYPNDSplge = 75;
    uint256 public NWOSplge = 45;
    uint256 public totalSplooge = 1818;
    string public extension = ".json";
    string public baseUri = "";
    address payable public payoutAddress;
    
    struct Config {
        uint256 priceBaseSplge;
        uint256 priceJrSplge;
        uint256 priceLMBLSplge;
        uint256 priceYLEDSplge;
        uint256 priceAYPNDSplge;
        uint256 priceNWOSplge;
        uint256 maxBaseSplge;
        uint256 maxSplge;    
    }

    Config public config;

    mapping(address => uint256) mintedInWallet;
    mapping(address => bool) admins;


    constructor() ERC721A("SploogeZone", "SPLGE") {
        _pause();
        config.priceBaseSplge = 0.00 ether;
        config.priceJrSplge = 0.085 ether;
        config.priceLMBLSplge = 0.169 ether;
        config.priceYLEDSplge = 0.319 ether;
        config.priceAYPNDSplge = 0.523 ether;
        config.priceNWOSplge = 1.014 ether;
        config.maxBaseSplge = 1;
        config.maxSplge = 3;
       
    }

    function baseSplgeMint(uint256 count)
        external
        payable
        nonReentrant
        whenNotPaused
        notBots
    {
        require(count <= config.maxBaseSplge, "Exceeds max");
        require(_currentIndex <= baseSplge);
        require(
            mintedInWallet[msg.sender] + count <= config.maxBaseSplge,
            "Exceeds max"
        );
        require(msg.value >= config.priceBaseSplge * count, "more eth required");
        bssplgwallet = baseSplge - _currentIndex ;
        mintedInWallet[msg.sender] += count;
        _callMint(count, msg.sender);
    }

        function jrSplgeMint(uint256 count)
        external
        payable
        nonReentrant
        whenNotPaused
        notBots
    {
        require(count <= config.maxSplge, "Exceeds max");
        require(_currentIndex <= JrSplge);
        require(
            mintedInWallet[msg.sender] + count <= config.maxSplge,
            "Exceeds max"
        );
        require(msg.value >= config.priceJrSplge * count, "more eth required");
        jrsplgwallet = JrSplge - _currentIndex ;
        mintedInWallet[msg.sender] += count;
        _callMint(count, msg.sender);
    }


        function lmblSplgeMint(uint256 count)
        external
        payable
        nonReentrant
        whenNotPaused
        notBots
    {
        require(count <= config.maxSplge, "Exceeds max");
        require(_currentIndex <= LMBLSplge);
        require(
            mintedInWallet[msg.sender] + count <= config.maxSplge,
            "Exceeds max"
        );
        require(msg.value >= config.priceLMBLSplge * count, "more eth required");
        lmblsplgwallet = LMBLSplge - _currentIndex ;
        mintedInWallet[msg.sender] += count;
        _callMint(count, msg.sender);
    }
        function yledSplgeMint(uint256 count)
        external
        payable
        nonReentrant
        whenNotPaused
        notBots
    {
        require(count <= config.maxSplge, "Exceeds max");
        require(_currentIndex <= YLEDSplge);
        require(
            mintedInWallet[msg.sender] + count <= config.maxSplge,
            "Exceeds max"
        );
        require(msg.value >= config.priceYLEDSplge * count, "more eth required");
         yledsplgwallet = YLEDSplge - _currentIndex ;
        mintedInWallet[msg.sender] += count;
        _callMint(count, msg.sender);
    }    
        function aypndSplgeMint(uint256 count)
        external
        payable
        nonReentrant
        whenNotPaused
        notBots
    {
        require(count <= config.maxSplge, "Exceeds max");
        require(_currentIndex <= AYPNDSplge);
        require(
            mintedInWallet[msg.sender] + count <= config.maxSplge,
            "Exceeds max"
        );
        require(msg.value >= config.priceAYPNDSplge * count, "more eth required");
         aypndsplgwallet = AYPNDSplge - _currentIndex ;
        mintedInWallet[msg.sender] += count;
        _callMint(count, msg.sender);
    }



        function nwoSplgeMint(uint256 count)
        external
        payable
        nonReentrant
        whenNotPaused
        notBots
    {
        require(count <= config.maxSplge, "Exceeds max");
        require(_currentIndex <= NWOSplge);
        require(
            mintedInWallet[msg.sender] + count <= config.maxSplge,
            "Exceeds max"
        );
        require(msg.value >= config.priceNWOSplge * count, "more eth required");
        nwosplgwallet = NWOSplge - _currentIndex ;
        mintedInWallet[msg.sender] += count;
        _callMint(count, msg.sender);
    }



    modifier notBots() {
        require(_msgSender() == tx.origin, "no bots");
        _;
    }

    // add adminmint function for each tier of mint // 
    function adminMint(uint256 count, address to) external adminOrOwner {
        _callMint(count, to);
    }

    function _callMint(uint256 count, address to) internal {
        uint256 total = totalSupply();
        require(count > 0, "Count is 0");
        require(total + count <= totalSplooge, "Exceeds Max Supply");
        _safeMint(to, count);
    }

    function burn(uint256 tokenId) external {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        require(isApprovedOrOwner, "Not approved");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function setExtension(string memory _extension) external adminOrOwner {
        extension = _extension;
    }

    function setBaseUri(string memory _uri) external adminOrOwner {
        baseUri = _uri;
    }

    function setPaused(bool _paused) external adminOrOwner {
        if (_paused) {
            _pause();
        } else {
            _unpause();
        }
    }


    function lowerMaxSupply(uint256 _newmax) external onlyOwner {
        require(_newmax < totalSplooge, "Can only lower supply");
        require(_newmax > totalSupply(), "Can't set below current");
        totalSplooge = _newmax;
    }

    function setConfig(Config memory _config) external adminOrOwner {
        config = _config;
    }

    function setpayoutAddress(address payable _payoutAddress)
        external
        adminOrOwner
    {
        payoutAddress = _payoutAddress;
    }

    function withdraw() external adminOrOwner {
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        delete admins[_admin];
    }

    modifier adminOrOwner() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }
}