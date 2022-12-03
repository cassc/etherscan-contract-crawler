// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Collection721Impl is ERC721Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, PausableUpgradeable {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 private PROJECT_ADMIN;
    CountersUpgradeable.Counter internal _tokenIds;
    string internal baseTokenURI;
    mapping(uint256 => string) internal _tokenURIs;

    string internal cname;
    string internal csymbol;
    uint maxSupply;
    uint maxPerMint;
    uint reserveQty;
    uint maxPerAddress;
    address payable royaltyAddress;
    uint royPercentage;
    DROPPHASE internal currentPhase;
    bool revealed;
    string uri;

    struct DROPPHASE {
        uint id;
        uint price;
        uint qtyAvailable;
        uint totalMinted;
        bytes32 restrictedMerkleRoot;
    }

    //////Public//////

    function initialize(
        string memory _name,
        string memory _symbol,
        uint _maxSupply,
        uint _maxPerMint,
        uint _maxPerAddress,
        uint _royPercentage,
        address payable _royaltyAddress,
        address owner,
        address _adminAddress,
        string memory _uri,
        string memory _revealURI) public initializer {

        __Ownable_init();
        __AccessControl_init();
        __Pausable_init();
        __ERC721_init(_name, _symbol);

        cname = _name;
        csymbol = _symbol;
        maxSupply = _maxSupply;
        maxPerMint = _maxPerMint;
        revealed = bytes(_revealURI).length == 0;
        maxPerAddress = _maxPerAddress;
        require(_royaltyAddress != address(0x0), "");
        royaltyAddress = _royaltyAddress;
        royPercentage = _royPercentage;
        uri =_uri;
        baseTokenURI = _revealURI;

        transferOwnership(owner);
        PROJECT_ADMIN = keccak256("PROJECT_ADMIN");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(PROJECT_ADMIN, _adminAddress);
        grantRole(PROJECT_ADMIN, owner);
    }

    function contractURI() public view returns (string memory) {
        return uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "1");

        // If collection is not revealed return the base URI
        return revealed ? _tokenURIs[tokenId] : baseTokenURI;
    }

    function mintNFT(string memory _metaData, bytes32[] memory proof) public whenNotPaused payable {
        //Basic checks
        uint totalMinted = _tokenIds.current();
        require(totalMinted + 1 <= maxSupply, "2");
        require(currentPhase.id > 0, "E");

        if (maxPerAddress > 0) {
            require(balanceOf(msg.sender) < maxPerAddress, "4");
        }

        //Supply Checks
        DROPPHASE memory phase = currentPhase;
        if (phase.qtyAvailable > 0) {
            require(phase.totalMinted + 1 <= phase.qtyAvailable, "6");
        }

        //Price checks
        uint currentPrice = phase.price;
        require(msg.value >= currentPrice, "7");

        //Permissions Checks
        if (phase.id != 0) {
            if (phase.restrictedMerkleRoot > 0) {
                bool verified = verify(phase.restrictedMerkleRoot, proof);
                require(verified, "8");
            }
        }

        _mintSingleNFT(_metaData, msg.sender);
        uint fee = (currentPrice * royPercentage) / 100;
        (royaltyAddress).transfer(fee);
    }

    function mintNFTMulti(string[] memory _metaData, bytes32[] memory proof) public whenNotPaused payable {
        //Basic checks
        uint totalMinted = _tokenIds.current();
        require(totalMinted + _metaData.length <= maxSupply, "2");
        require(_metaData.length > 0 && _metaData.length <= maxPerMint, "3");
        require(currentPhase.id > 0, "E");

        if (maxPerAddress > 0) {
            require(balanceOf(msg.sender) < maxPerAddress, "4");
        }

        //Supply Checks
        DROPPHASE memory phase = currentPhase;
        if (phase.qtyAvailable > 0) {
            require(phase.totalMinted + _metaData.length <= phase.qtyAvailable, "6");
        }

        //Price checks
        uint currentPrice = phase.price;
        require(msg.value >= (currentPrice * _metaData.length), "7");

        //Permissions Checks
        if (phase.id != 0) {
            if (phase.restrictedMerkleRoot > 0) {
                bool verified = verify(phase.restrictedMerkleRoot, proof);
                require(verified, "8");
            }
        }
        uint len = _metaData.length;
        uint fee = (currentPrice * royPercentage) / 100;
        (royaltyAddress).transfer(fee * len);
        for (uint i = 0; i < len; i++) {
            _mintSingleNFT(_metaData[i], msg.sender);
        }
    }

    function setURI(bool _revealed, string memory _URI, uint256 tokenId) public whenNotPaused {
        require(hasRole(PROJECT_ADMIN, msg.sender), "9");
        if(_exists(tokenId)){
            //To set a tokens IPFS
            _tokenURIs[tokenId] = _URI;
        }
        else{
            //To reveal/hide a drop
            revealed = _revealed;
            baseTokenURI = _URI;
        }
    }

    function activatePhase(uint id, uint price, uint qtyAvailable, uint totalMinted, bytes32 restrictedMerkleRoot) public whenNotPaused {
        require(hasRole(PROJECT_ADMIN, msg.sender), "9");
        currentPhase = DROPPHASE({
            id : id,
            price : price,
            qtyAvailable : qtyAvailable,
            totalMinted : totalMinted,
            restrictedMerkleRoot : restrictedMerkleRoot
        });
    }

    function deactivatePhase() public whenNotPaused {
        require(hasRole(PROJECT_ADMIN, msg.sender), "E");
        currentPhase.id = 0;
    }

    //Owner
    function pause(bool doPause) public {
        require(hasRole(PROJECT_ADMIN, msg.sender), "E");
        doPause ? _pause() : _unpause();
    }

    function withdraw() public payable onlyOwner whenNotPaused {
        uint balance = address(this).balance;
        require(balance > 0, "12");

        payable(msg.sender).transfer(balance);
    }

    //Private
    function _mintSingleNFT(string memory _metaData, address to) private {
        uint256 newTokenID = _tokenIds.current();
        _safeMint(to, newTokenID);
        _tokenIds.increment();
        _setTokenURI(newTokenID, _metaData);
        currentPhase.totalMinted += 1;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "1");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function verify(bytes32 root, bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        bytes32 computedHash = leaf;

        uint256 len = proof.length;
        for (uint256 i = 0; i < len; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

    function airDrop(address[] memory accounts, string[] memory metaURIs) public whenNotPaused {
        require(hasRole(PROJECT_ADMIN, msg.sender), "9");
        require(accounts.length == metaURIs.length);
        uint totalMinted = _tokenIds.current();
        require(totalMinted + accounts.length <= maxSupply, "11");
        uint len = accounts.length;
        for (uint i = 0; i < len; i++) {
            _mintSingleNFT(metaURIs[i], accounts[i]);
        }
    }
}