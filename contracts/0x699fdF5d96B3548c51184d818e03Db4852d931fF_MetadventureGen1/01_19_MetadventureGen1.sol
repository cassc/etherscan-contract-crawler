// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MetadventureGen1 is ERC721Enumerable, ERC721Royalty, VRFConsumerBaseV2, Ownable {
    using Strings for uint256;

    VRFCoordinatorV2Interface COORDINATOR;

    uint256 public cost = 0.04 ether;
    uint256 public whitelistedCost = 0.02 ether;
    uint256 public maxSupply = 8000;
    uint256 public maxMintAmount = 4;
    bool public paused = false;
    uint public releaseDate = 1667070000;
    uint public whitelistReleaseDate = 1667055600;

    string public allInitialMetadataEncrypted;
    string public allMetadataEncrypted = "";
    string public baseURI = "";
    string public basePermanentURI = "";
    bytes32 public whitelistRoot;
    uint256 public tokenGap = 0;
    uint256 public requestId;

    uint64 subscriptionId;
    bytes32 keyHash;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        bytes32 _whitelistRoot,
        string memory _allInitialMetadataEncrypted,
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash
    )
    VRFConsumerBaseV2(_vrfCoordinator)
    ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setRoyalty(msg.sender, 5000);
        whitelistRoot = _whitelistRoot;
        allInitialMetadataEncrypted = _allInitialMetadataEncrypted;

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    // internal

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        tokenGap = (_randomWords[0] % 8000) + 1;
        requestId = _requestId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    // public

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
                : "";
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(releaseDate <= block.timestamp, "Mint isn't opened");
        require(!paused, "Contract in pause..");
        require(tx.origin == _to, "The caller is another contract");
        require(supply + _mintAmount <= maxSupply, "No enough supply");
        require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount, "Mint limit reached");
        require(msg.value >= cost*_mintAmount, "Invalid amount of eth");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + 1);
        }
    }

    function isWhitelisted(bytes32[] memory _proof, bytes32 _leaf) public view returns (bool) {
        return MerkleProof.verify(_proof, whitelistRoot, _leaf);
    }

    function whitelistedMint(bytes32[] memory _proof, bytes32 _leaf, uint256 _mintAmount) public payable {
        require(!paused, "Contract in pause..");

        bool isWhitelistedAddress = isWhitelisted(_proof, _leaf);
        uint256 supply = totalSupply();

        require(isWhitelistedAddress, "Address not whitelisted");
        require(whitelistReleaseDate <= block.timestamp, "Whitelist mint isn't opened");
        require(supply + _mintAmount <= maxSupply, "No enough supply");
        require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount, "Mint limit reached");

        uint256 amount = 0;

        if (balanceOf(msg.sender) > 0) {
            amount = _mintAmount * cost;
        } else {
            amount = whitelistedCost + ((_mintAmount-1)*cost);
        }

        require(msg.value >= amount, "Invalid amount of eth");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply = totalSupply();
            _safeMint(msg.sender, supply + 1);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    //only owner
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setWhitelistedCost(uint256 _newCost) public onlyOwner {
        whitelistedCost = _newCost;
    }

    function setMaxMintAmount(uint8 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setReleaseDate(uint _newReleaseDate) public onlyOwner {
        releaseDate = _newReleaseDate;
    }

    function setWhitelistReleaseDate(uint _newWhitelistReleaseDate) public onlyOwner {
        whitelistReleaseDate = _newWhitelistReleaseDate;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPermanentBaseURI(string calldata _newPermanentBaseUri) public onlyOwner {
        require(bytes(basePermanentURI).length == 0, 'uri locked');
        basePermanentURI = _newPermanentBaseUri;
    }

    function setAllMetadataEncrypted(string memory _newAllMetadataEncrypted) public onlyOwner {
        require(keccak256(abi.encodePacked(allMetadataEncrypted)) == keccak256(abi.encodePacked("")), "Hash already setted");
        allMetadataEncrypted = _newAllMetadataEncrypted;
    }

    function setSubscriptionId(uint64 _subscriptionId) public onlyOwner {
        subscriptionId = _subscriptionId;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function defineTokenGap() public onlyOwner returns (uint256 _requestId) {
        require(tokenGap == 0, "tokenGap already defined");
        // Will revert if subscription is not set and funded.
        _requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            3,
            100000,
            1
        );

        return _requestId;
    }

    function setRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function ownerMint(address _to, uint256 _mintAmount) public onlyOwner {
        require(!paused, "Contract in pause..");

        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply);

        for (uint256 i = 1; i <= _mintAmount; i++) {
            supply = totalSupply();
            _safeMint(_to, supply + 1);
        }
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}