// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TheFuckUps is ERC721A, Ownable {
    using Strings for uint256;

    mapping(address => uint256) public userWhitelistMintCount;
    mapping(address => uint256) public userPublicMintCount;
    mapping(address => bool) public isWhitelisted;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    uint256 public maxSupply;
    uint256 public maxMintWhitelist;
    uint256 public maxMintPublicsale;

    uint256 public totalUserWhitelisted;
    uint256 public totalMintsReserve;
    uint256 public totalMintsSale;

    uint256 public lastTokenId;
    uint256 public maxTokenId;

    uint256 public reservenftLastTokenId;
    uint256 public reservenftMaxTokenId;

    bool public pausedPublicsale;
    bool public whitelistMintEnabled;
    bool public revealed;

    constructor(string memory _tokenName, string memory _tokenSymbol, string memory _hiddenMetadataUri)
        ERC721A(_tokenName, _tokenSymbol)
    {
        maxMintWhitelist = 1;
        maxMintPublicsale = 1;
        whitelistMintEnabled = true;
        maxSupply = 5555;
        maxTokenId = 5205;
        reservenftLastTokenId = 5205; 
        reservenftMaxTokenId = 5555;
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    modifier mintComplianceWhitelist(uint256 _mintAmount) {
        require(
            _mintAmount > 0 &&
                userWhitelistMintCount[_msgSender()] + _mintAmount <=
                maxMintWhitelist,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintCompliancePublicsale(uint256 _mintAmount) {
        require(
            _mintAmount > 0 &&
                userPublicMintCount[_msgSender()] + _mintAmount <=
                maxMintPublicsale,
            "Invalid mint amount!"
        );
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setConfig_maxTokenId(uint256 _maxTokenId) external onlyOwner {
        maxTokenId = _maxTokenId;
    }

    function setConfig_reservetokenrange(
        uint256 _lastTokenId,
        uint256 _maxTokenId
    ) external onlyOwner {
        reservenftLastTokenId = _lastTokenId;
        reservenftMaxTokenId = _maxTokenId;
    }

    function doWhitelist(address[] calldata users) external onlyOwner {
        uint256 length = users.length;
        for (uint256 i = 0; i < length; i++) {
            address entry = users[i];
            require(entry != address(0), "Cannot add zero address");
            require(!isWhitelisted[users[i]], "already whitelisted");

            isWhitelisted[users[i]] = true;
            totalUserWhitelisted++;
        }
    }

    function whitelistMint(uint256 _mintAmount)
        public
        mintComplianceWhitelist(_mintAmount)
    {
        // Verify whitelist requirements
        require(whitelistMintEnabled, "The whitelist sale is not enabled!");
        require(isWhitelisted[_msgSender()], "You are not whitelist user");

        require(
            lastTokenId + _mintAmount <= maxTokenId,
            "Sale Mint Maximum cap reached"
        );

        totalMintsSale += _mintAmount;
        lastTokenId += _mintAmount;
        userWhitelistMintCount[_msgSender()] += _mintAmount;

        _safeMint(_msgSender(), _mintAmount);
    }

    function publicSaleMint(uint256 _mintAmount)
        public
        mintCompliancePublicsale(_mintAmount)
    {
        require(pausedPublicsale, "The public sale is paused!");
        require(
            lastTokenId + _mintAmount <= maxTokenId,
            "Sale Mint Maximum cap reached"
        );

        totalMintsSale += _mintAmount;
        lastTokenId += _mintAmount;
        userPublicMintCount[_msgSender()] += _mintAmount;

        _safeMint(_msgSender(), _mintAmount);
    }

    function airdropSingle(address _receiver, uint256 _mintAmount)
        public
        onlyOwner
    {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(
            lastTokenId + _mintAmount <= maxTokenId,
            "Airdrop Mint Maximum cap reached"
        );

        totalMintsSale += _mintAmount;
        lastTokenId += _mintAmount;

        _safeMint(_receiver, _mintAmount);
    }

    function airdropBatch(address[] memory users) external onlyOwner {
        uint256 length = users.length;
        require(totalSupply() + length <= maxSupply, "Max supply exceeded!");
        require(
            lastTokenId + length <= maxTokenId,
            "Sale Mint Maximum cap reached"
        );
        for (uint256 i = 0; i < length; i++) {
            address user = users[i];
            require(user != address(0), "Cannot add zero address");

            totalMintsSale++;
            lastTokenId++;
            _safeMint(user, 1);
        }
    }

    function reserveMint(address[] memory teamAddresses) external onlyOwner {
        uint256 walletsLength = teamAddresses.length;
        require(lastTokenId == maxTokenId, "Reserve Minting not allowed yet");
        require(
            totalSupply() + walletsLength <= maxSupply,
            "Max supply exceeded!"
        );

        require(
            reservenftLastTokenId + walletsLength <= reservenftMaxTokenId,
            "Reserve Mint Maximum cap reached"
        );

        for (uint256 i = 0; i < walletsLength; i++) {
            _safeMint(teamAddresses[i], 1);
            reservenftLastTokenId++;
            totalMintsReserve++;
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex
        ) {
            TokenOwnership memory ownership = _ownerships[currentTokenId];

            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    latestOwnerAddress = ownership.addr;
                }

                if (latestOwnerAddress == _owner) {
                    ownedTokenIds[ownedTokenIndex] = currentTokenId;

                    ownedTokenIndex++;
                }
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

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

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setMaxMintWhitelist(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintWhitelist = _maxMintAmountPerTx;
    }

    function setMaxMintPublicsale(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintPublicsale = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPublicsalePaused(bool _state) public onlyOwner {
        pausedPublicsale = _state;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
        whitelistMintEnabled = _state;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}