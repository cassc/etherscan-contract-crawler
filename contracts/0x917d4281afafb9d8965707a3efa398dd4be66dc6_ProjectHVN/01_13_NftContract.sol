// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ProjectHVN is ERC721Enumerable, Ownable {
    //--------------------------------------------------------------------
    // VARIABLES
    using Strings for uint256;

    string public baseURI;
    string public baseExtension = ".json";
    string public hiddenMetadataUri;

    uint256 public cost;
    uint256 public immutable maxSupply;
    uint256 public maxMintAmountPerTx;
    // Number of NFTs is limited to 3 per user during whitelisting
    uint256 public nftPerAddressLimit = 1;
    bool public paused = true;
    bool public revealed = false;
    bool public whitelistMintEnabled = false;

    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;

    //--------------------------------------------------------------------
    // ERRORS

    error NFT__ContractIsPaused();
    error NFT__InvalidMintAmount();
    error NFT__ExceededMaxMintAmountPerTx();
    error NFT__MaxSupplyExceeded();
    error NFT__ExceededMaxNftPerAddress();
    error NFT__NotWhitelisted(address user);
    error NFT__InsufficientFunds();
    error NFT__QueryForNonExistentToken(uint256 tokenId);

    //--------------------------------------------------------------------
    // CONSTRUCTOR

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmountPerTx,
        string memory _hiddenMetadataUri
    ) ERC721(_name, _symbol) {
        hiddenMetadataUri = _hiddenMetadataUri;
        cost = _cost;
        maxMintAmountPerTx = _maxMintAmountPerTx;
        maxSupply = _maxSupply;
    }

    //--------------------------------------------------------------------
    // FUNCTIONS

    function mint(uint256 _mintAmount) external payable {
        if (paused) revert NFT__ContractIsPaused();
        if (_mintAmount == 0) revert NFT__InvalidMintAmount();
        if (_mintAmount > maxMintAmountPerTx) {
            revert NFT__ExceededMaxMintAmountPerTx();
        }
        uint256 supply = totalSupply();
        if (supply + _mintAmount > maxSupply) {
            revert NFT__MaxSupplyExceeded();
        }

        if (msg.sender != owner()) {
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            if (ownerMintedCount + _mintAmount > nftPerAddressLimit) {
                revert NFT__ExceededMaxNftPerAddress();
            }
            if (whitelistMintEnabled == true && !isWhitelisted(msg.sender)) {
                revert NFT__NotWhitelisted(msg.sender);
            }
            if (msg.value < cost * _mintAmount) revert NFT__InsufficientFunds();
        }

        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 tokenId = uint256(
                keccak256(abi.encodePacked(block.timestamp, i, msg.sender))
            ) % maxSupply;
            tokenId = tokenId + 1; // Adding 1 to avoid tokenId being 0
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, tokenId);
        }
    }

    function bulkMint(address[] memory _addresses, uint256 _mintAmount)
        external
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(
            supply + (_addresses.length * _mintAmount) <= maxSupply,
            "NFT__MaxSupplyExceeded"
        );
        require(
            _mintAmount <= maxMintAmountPerTx,
            "NFT__ExceededMaxMintAmountPerTx"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            address recipient = _addresses[i];
            uint256 ownerMintedCount = addressMintedBalance[recipient];
            require(
                ownerMintedCount + _mintAmount <= nftPerAddressLimit,
                "NFT__ExceededMaxNftPerAddress"
            );

            for (uint256 j = 0; j < _mintAmount; j++) {
                addressMintedBalance[recipient]++;
                _safeMint(recipient, supply + 1);
                supply++;
            }
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        uint256 whitelistedCount = whitelistedAddresses.length;
        for (uint256 i; i < whitelistedCount; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NFT__QueryForNonExistentToken(tokenId);
        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //--------------------------------------------------------------------
    // OWNER FUNCTIONS

    function reveal(string memory _newBaseURI) external payable onlyOwner {
        revealed = true;
        setBaseURI(_newBaseURI);
    }

    function setNftPerAddressLimit(uint256 _limit) external payable onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) external payable onlyOwner {
        cost = _newCost;
    }

    function setMaxMintAmountPerTx(uint256 _newmaxMintAmount)
        external
        payable
        onlyOwner
    {
        maxMintAmountPerTx = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public payable onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        external
        payable
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        external
        payable
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function pause(bool _state) external payable onlyOwner {
        paused = _state;
    }

    function setWhitelistMintEnabled(bool _state) external payable onlyOwner {
        whitelistMintEnabled = _state;
    }

    function whitelistUsers(address[] calldata _users)
        external
        payable
        onlyOwner
    {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function removeWhitelistedUser(address _user) external onlyOwner {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                whitelistedAddresses[i] = whitelistedAddresses[
                    whitelistedAddresses.length - 1
                ];
                whitelistedAddresses.pop();
                return;
            }
        }
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}