// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract TEASv2 is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    string public baseUri = "";
    uint256 public supply = 20000;
    string public extension = ".json";  

    bool public whitelistLive;
    address payable public payoutAddress;
    bytes32 public whitelistMerkleRoot;


    struct Config {
        uint256 mintPrice;
        uint256 wlPrice;
        uint256 whitelistMint;
        uint256 maxMint;
        uint256 maxWhitelist;
        uint256 maxWhitelistPerTx;
        uint256 maxMintPerTx;
    }

    struct LimitPerWallet {
        uint256 mint;
        uint256 whitelist;
    }

    Config public config;
    
    mapping(address => LimitPerWallet) limitPerWallet;
    mapping(address => bool) admins;

    event WhitelistLive(bool live);


    constructor() ERC721A("ThirdEyeSocietyV2", "TEASv2") { 
        _pause(); 
        config.mintPrice = 0.1 ether;
        config.wlPrice = 0.06 ether;
        config.maxMint = 100;
        config.maxWhitelist = 10;
        config.maxWhitelistPerTx = 10;
        config.maxMintPerTx = 10;
    }

        /**
     * @dev validates merkleProof
     */
    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }


    function whitelistMint(uint256 count, bytes32[] calldata proof) external payable isValidMerkleProof(proof, whitelistMerkleRoot) nonReentrant notBots {
        require(whitelistLive, "Not live");
        require(count <= config.maxWhitelistPerTx, "Exceeds max");
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




    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }


    function setSupply(uint256 _supply) external adminOrOwner {
        supply = _supply;
    }



    function setConfig(Config memory _config) external adminOrOwner {
        config = _config;
    }

    function setpayoutAddress(address payable _payoutAddress) external adminOrOwner {
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