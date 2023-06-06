// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract TuttleUpgrade is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    address proxyRegistryAddress;
    uint256 basePrice;
    uint256 _totalSupply;
    uint256 _wlSupply;
    bytes32 merkleRoot;
    bool _wlMint;
    bool _publicMint;

    mapping (address => bool) public teamMinters;
    mapping (address => bool) public dayOfMinters;

    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721_init("Tuttle Tribe", "TUTT");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        address _proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
        proxyRegistryAddress = _proxyRegistryAddress;
        basePrice = 50000000000000000;
        _totalSupply = 5050;
        _wlSupply = 2500;
        _tokenIdCounter.increment();
        _wlMint = false;
        _publicMint = true;
        // initial 80 to team wallet
        for(uint256 i=0; i< 80; i++){
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(0x6fBe1EaF0fc2b2D8ffe10Fbe951aF2dA7dA3f1bF, tokenId);
        }
    }

    function wlMint(uint256 count, bytes32[] calldata proof) public payable {
        require(_wlMint == true, 'MINTING NOT YET STARTED');
        require(count <= 5, 'MAX 5 PER TRANSACTION');
        if(teamMinters[msg.sender] == true) {
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId <= _wlSupply);
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
            teamMinters[msg.sender] = false;
            uint256 _count = msg.value / basePrice;
            for(uint256 i=0; i< _count; i++) {
                uint256 tkenId = _tokenIdCounter.current();
                require(tkenId <= _wlSupply);
                _tokenIdCounter.increment();
                _safeMint(msg.sender, tkenId);
            }
            return;
        }
        else require(msg.value >= basePrice * count, 'INCREASE PAYMENT TO MINT');
        require(count >= 1, 'DONT DRINK UNNEEDED GAS');
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(proof, merkleRoot, leaf),'NOT ON ALLOWLIST');
        for(uint256 i=0; i< count; i++){
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId <= _wlSupply);
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }

    function batchMint(uint256 count) public payable {
        require(_publicMint == true, 'PUBLIC MINTING NOT YET STARTED');
        require(count <= 5, 'MAX 5 PER TRANSACTION');
        require(msg.value >= basePrice * count, 'INCREASE PAYMENT TO MINT');
        for(uint256 i=0; i< count; i++){
            uint256 tokenId = _tokenIdCounter.current();
            require(tokenId <= _totalSupply);
            _tokenIdCounter.increment();
            _safeMint(msg.sender, tokenId);
        }
    }  

    function addTeamMinters(address[] calldata users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            teamMinters[users[i]] = true;
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function commenceWlMint() public onlyOwner {
        _wlMint = true;
    }
    
    function commencePublicMint() public onlyOwner {
        _publicMint = true;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function currentToken() public view returns (uint256) {
        uint256 currentNFT = _tokenIdCounter.current();
        return currentNFT;
    }

    // function _baseURI() internal pure override returns (string memory) {
    //     return "https://api.goatkeepers.sh/v1/tuttle/metadata/";
    // }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawAll() public {
        uint256 amount = address(this).balance;
        require(payable(owner()).send(amount));
    }

    function awardItem(address recipient, string memory metadata) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, metadata);
        return newItemId;
    }
}