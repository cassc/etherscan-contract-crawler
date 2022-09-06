// SPDX-License-Identifier: MIT
// Creator: Andrei Toma
pragma solidity ^0.8.0;

import "ERC721A.sol";
import "Strings.sol";
import "Ownable.sol";
import "MerkleProof.sol";

contract LegendaryOwls is ERC721A, Ownable {
    using Strings for uint256;

    string internal uriPrefix;
    string internal hiddenMetadataUri =
        "ipfs://QmcHey6vNjKSn2N6WgCD6SLmBqLUjNdoDUY36PN3AyxgFF";
    string internal backgroundMetadataUri;
    string internal cagedBackgroundMetadataUri;

    // The cost to mint 1 NFT
    uint256 public cost = 0.05 ether;

    // The cost to mint 1 NFT for OG and WL
    uint256 public whitelistCost = 0.04 ether;

    // The maximum supply of Owls
    uint256 internal maxSupply = 2000;

    // Mapping of Token Id to timer for URI change
    mapping(uint256 => uint256) internal uriTimer;

    // Mapping of Token Id to URI Level
    mapping(uint256 => uint256) internal tokenIdToLevel;

    // Mapping of address to bool that determins wether the address already claimed the whitelist mint
    mapping(address => bool) public whitelistClaimed;

    // Owners
    address[] internal owners;

    // The WL Merkle Root
    bytes32 internal wlMerkleRoot =
        0x75f1e020be78b415f4cad620bc266e4877bbfd028836e3adccd692d8cead396e;

    // The Owner Merkle Root
    bytes32 internal ownerMerkleRoot =
        0x2de5f81c981d53936299e6f0a04ad7ffe5e626fa8d26b8ffce0ec7dd79728921;

    // Admin address
    address internal admin;

    // Minting state
    bool public paused = true;

    // Revealed state
    bool public revealed = false;

    constructor(address[] memory _owners) ERC721A("Legendary Owls", "LO") {
        admin = msg.sender;
        owners = _owners;
    }

    ///////////////
    // Modifiers //
    ///////////////

    // Keeps mint limit per tx to 7 and keeps max supply at set amount
    modifier mintCompliance(uint256 _mintAmount) {
        require(!paused, "The contract is paused!");
        require(_mintAmount > 0 && _mintAmount <= 5, "Invalid mint amount!");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    // Gives access to function only for Owner or Admin
    modifier onlyOwnerAndAdmin() {
        require(
            owner() == _msgSender() || admin == _msgSender(),
            "Not owner or Admin"
        );
        _;
    }

    ////////////////////
    // Mint Functions //
    ////////////////////

    // The main mint function
    // _mintAmount = How many NFTs to mint in the tx
    function mint(uint256 _mintAmount)
        external
        payable
        mintCompliance(_mintAmount)
    {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        if (_currentIndex <= 2000) {
            for (uint256 i; i < _mintAmount; ++i) {
                uriTimer[_currentIndex + i] = block.timestamp;
            }
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
        mintCompliance(_mintAmount)
    {
        require(
            msg.value >= whitelistCost * _mintAmount,
            "Insufficient funds!"
        );
        require(!whitelistClaimed[msg.sender], "Address has already claimed.");
        bytes32 leaf = keccak256(abi.encodePacked((msg.sender)));
        require(
            MerkleProof.verify(_merkleProof, wlMerkleRoot, leaf),
            "Invalid proof"
        );
        whitelistClaimed[msg.sender] = true;
        if (_currentIndex <= 2000) {
            for (uint256 i; i < _mintAmount; ++i) {
                uriTimer[_currentIndex + i] = block.timestamp;
            }
        }
        _safeMint(msg.sender, _mintAmount);
    }

    function ownerMint(uint256 _mintAmount, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(!paused, "The contract is paused!");
        require(_mintAmount > 0 && _mintAmount <= 7, "Invalid mint amount!");
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(
            msg.value >= whitelistCost * _mintAmount,
            "Insufficient funds!"
        );
        bytes32 leaf = keccak256(abi.encodePacked((msg.sender)));
        require(
            MerkleProof.verify(_merkleProof, ownerMerkleRoot, leaf),
            "Invalid proof"
        );
        if (_currentIndex <= 2000) {
            for (uint256 i; i < _mintAmount; ++i) {
                uriTimer[_currentIndex + i] = block.timestamp;
            }
        }
        _safeMint(msg.sender, _mintAmount);
    }

    // Function that allows the team to mint for other addresses for free
    // Will be used for giveaways
    function mintForAddresses(
        uint256[] calldata _mintAmounts,
        address[] calldata _receivers
    ) external onlyOwnerAndAdmin {
        for (uint256 i; i < _mintAmounts.length; i++) {
            if (_currentIndex <= 2000) {
                for (uint256 j; j < _mintAmounts[i]; ++j) {
                    uriTimer[_currentIndex + j] = block.timestamp;
                }
            }
            _safeMint(_receivers[i], _mintAmounts[i]);
        }
    }

    ///////////////////
    // URI Functions //
    ///////////////////

    // ERC721 standard tokenURI function.
    // Will return hidden, caged or uncaged URI based on reveal state and uncaged state
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI(_tokenId);
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    // Administrative function
    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        external
        onlyOwnerAndAdmin
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    // Override for ERC721 Smart Contract
    function _baseURI(uint256 _tokenId)
        internal
        view
        virtual
        returns (string memory)
    {
        if (_tokenId > 2000) {
            return uriPrefix;
        }
        if (
            block.timestamp > uriTimer[_tokenId] + (172800 * 2) ||
            tokenIdToLevel[_tokenId] == 2
        ) {
            return uriPrefix;
        }
        if (
            tokenIdToLevel[_tokenId] == 1 &&
            block.timestamp > uriTimer[_tokenId] + 172800
        ) {
            return uriPrefix;
        }
        if (
            block.timestamp > uriTimer[_tokenId] + 172800 ||
            tokenIdToLevel[_tokenId] == 1
        ) {
            return backgroundMetadataUri;
        }
        return cagedBackgroundMetadataUri;
    }

    /////////////////////
    // State functions //
    /////////////////////

    // Administrative function
    function setPaused(bool _state) public onlyOwnerAndAdmin {
        paused = _state;
    }

    // Administrative function
    function reveal(
        string memory _uriPrefix,
        string memory _backgroundMetadataUri,
        string memory _cagedBackgroundMetadataUri
    ) external onlyOwnerAndAdmin {
        revealed = true;
        uriPrefix = _uriPrefix;
        backgroundMetadataUri = _backgroundMetadataUri;
        cagedBackgroundMetadataUri = _cagedBackgroundMetadataUri;
    }

    ///////////////////////
    // Withdraw function //
    ///////////////////////

    function withdraw(uint256 amount) external onlyOwnerAndAdmin {
        uint256 devTax = (amount * 55) / 1000;
        (bool hs, ) = payable(admin).call{value: devTax}("");
        require(hs);
        for (uint256 i; i < owners.length; i++) {
            (bool sc, ) = payable(owners[i]).call{
                value: (amount - devTax) / owners.length
            }("");
            require(sc);
        }
    }

    ///////////
    // Utils //
    ///////////

    // Returns bool true if address has used the whitelist/og spot
    function getWhitelistState(address _address) external view returns (bool) {
        return whitelistClaimed[_address];
    }

    // Returns the Sale State
    function getSaleState() external view returns (bool) {
        return paused;
    }

    // Administrative function
    function setwlMerkleRoot(bytes32 _newwlMerkleRoot)
        public
        onlyOwnerAndAdmin
    {
        wlMerkleRoot = _newwlMerkleRoot;
    }

    function setCost(uint256 _cost) external onlyOwnerAndAdmin {
        cost = _cost;
    }

    function setWhitelistCost(uint256 _whitelistCost)
        external
        onlyOwnerAndAdmin
    {
        whitelistCost = _whitelistCost;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwnerAndAdmin {
        maxSupply = _maxSupply;
    }

    // Returns an array of tokens of _owner address
    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= 8888) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }
        return ownedTokenIds;
    }

    receive() external payable {}

    // Overrides

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (
            block.timestamp > uriTimer[startTokenId] + (172800 * 2) ||
            tokenIdToLevel[startTokenId] == 2
        ) {
            tokenIdToLevel[startTokenId] = 2;
        } else if (
            tokenIdToLevel[startTokenId] == 1 &&
            block.timestamp > uriTimer[startTokenId] + 172800
        ) {
            tokenIdToLevel[startTokenId] = 2;
        } else if (block.timestamp > uriTimer[startTokenId] + 172800) {
            tokenIdToLevel[startTokenId] = 1;
            uriTimer[startTokenId] = block.timestamp;
        } else {
            uriTimer[startTokenId] = block.timestamp;
        }
    }

    // If you got this far you are a hardcore geek! :)
}