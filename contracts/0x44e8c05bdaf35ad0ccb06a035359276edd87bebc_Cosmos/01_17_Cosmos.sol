pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IMerkle.sol";

contract Cosmos is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    string public baseUri = "https://ipfs.io/ipfs/QmaTxu3Kw1jZhZECxhKtjV4gEfAv5QuQwWgocx7MFvWE5v/";
    uint256 public supply = 9999;
    string public extension = ".json";  

    bool public whitelistLive;
    bool public raffleLive;
    address payable public paymentSplitter;
    IMerkle public whitelist;
    IMerkle public raffle;

    struct Config {
        uint256 mintPrice;
        uint256 wlPrice;
        uint256 rafflePrice;
        uint256 maxMint;
        uint256 maxWhitelist;
        uint256 maxRaffle;
        uint256 maxWhitelistPerTx;
        uint256 maxRafflePerTx;
        uint256 maxMintPerTx;
    }

    struct LimitPerWallet {
        uint256 mint;
        uint256 whitelist;
        uint256 raffle;
    }

    Config public config;
    
    mapping(address => LimitPerWallet) limitPerWallet;
    mapping(address => bool) admins;

    event WhitelistLive(bool live);
    event RaffleLive(bool live);

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) { 
        _pause(); 
        config.mintPrice = 0.12 ether;
        config.wlPrice = 0.1 ether;
        config.rafflePrice = 0.12 ether;
        config.maxMint = 5;
        config.maxWhitelist = 3;
        config.maxRaffle = 2;
        config.maxWhitelistPerTx = 3;
        config.maxRafflePerTx = 2;
        config.maxMintPerTx = 5;
    }

    function raffleMint(uint256 count, bytes32[] memory proof) external payable nonReentrant notBots {
        require(raffleLive, "Not live");     
        require(count <= config.maxRafflePerTx, "Exceeds max");
        require(raffle.isPermitted(msg.sender, proof), "Not in raffle");
        require(limitPerWallet[msg.sender].raffle + count <= config.maxRaffle, "Exceeds max");
        require(msg.value >= config.rafflePrice * count, "invalid price");
        limitPerWallet[msg.sender].raffle += count;
        _callMint(count, msg.sender);
    }

    function whitelistMint(uint256 count, bytes32[] memory proof) external payable nonReentrant notBots {
        require(whitelistLive, "Not live");
        require(count <= config.maxWhitelistPerTx, "Exceeds max");
        require(whitelist.isPermitted(msg.sender, proof), "not whitelisted");
        require(limitPerWallet[msg.sender].whitelist + count <= config.maxWhitelist, "Exceeds max");
        require(msg.value >= config.wlPrice * count, "invalid price");
        limitPerWallet[msg.sender].whitelist += count;
        _callMint(count, msg.sender);        
    }

    function mint(uint256 count) external payable nonReentrant whenNotPaused notBots {       
        require(count <= config.maxMintPerTx, "Exceeds max");
        require(limitPerWallet[msg.sender].mint + count <= config.maxMint, "Exceeds max");         
        require(msg.value >= config.mintPrice * count, "invalid price");
        limitPerWallet[msg.sender].mint += count;
        _callMint(count, msg.sender);        
    }

    modifier notBots {        
        require(_msgSender() == tx.origin, "no bots");
        _;
    }

    function adminMint(uint256 count, address to) external adminOrOwner {
        _callMint(count, to);
    }

    function _callMint(uint256 count, address to) internal {        
        uint256 total = totalSupply();
        require(count > 0, "Count is 0");
        require(total + count <= supply, "Sold out");
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

    function setUri(string memory _uri) external adminOrOwner {
        baseUri = _uri;
    }

    function setPaused(bool _paused) external adminOrOwner {
        if(_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function toggleWhitelistLive() external adminOrOwner {
        bool isLive = !whitelistLive;
        whitelistLive = isLive;
        emit WhitelistLive(isLive);
    }

    function toggleRaffleLive() external adminOrOwner {
        bool isLive = !raffleLive;
        raffleLive = isLive;
        emit RaffleLive(isLive);
    }

    function setMerkle(IMerkle _whitelist) external adminOrOwner {
        whitelist = _whitelist;
    }

    function setSupply(uint256 _supply) external adminOrOwner {
        supply = _supply;
    }

    function setRaffle(IMerkle _raffle) external adminOrOwner {
        raffle = _raffle;
    }

    function setConfig(Config memory _config) external adminOrOwner {
        config = _config;
    }

    function setPaymentSplitter(address payable _paymentSplitter) external adminOrOwner {
        paymentSplitter = _paymentSplitter;
    }
     
    function withdraw() external adminOrOwner {
        (bool success, ) = paymentSplitter.call{value: address(this).balance}("");
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