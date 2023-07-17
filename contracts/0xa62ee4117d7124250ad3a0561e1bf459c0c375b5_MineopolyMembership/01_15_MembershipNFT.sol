// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MineopolyMembership is ERC721, Ownable {
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    mapping(uint256 => uint256) private _activeTimestamp;
    mapping(address => bool) private _hasMinted;
    mapping(address => uint256[]) private _ownedNFTs;
    bool public RevealedActive = true;

    uint256 public Price = 50 * 10**6; 
    uint256 private constant _duration = 365 days;
    address adminWallet = 0xD1d6629585f2C631081CBbE45334bdd4bf5a33D2;

    IERC20 public USDToken;
    
    constructor(string memory _BaseURI, string memory _NotRevealedUri)
        ERC721("Mineopoly Membership", "MPLYM")
    {
        USDToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        setURIBase(_BaseURI);
        setNotRevealedURI(_NotRevealedUri);
    }

    function mintNFT() public {
        require(!_hasMinted[msg.sender]);
        require( USDToken.transferFrom(msg.sender, adminWallet, Price), "Failed to transfer Admin fee" );

        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _hasMinted[msg.sender] = true;

        _activeTimestamp[newItemId] = block.timestamp + _duration;
        _ownedNFTs[msg.sender].push(newItemId);
    }

    function isActive(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "NFT no exist");

        if (_activeTimestamp[tokenId] > block.timestamp) {
            return true;
        } else {
            return false;
        }
    }

    function getExpirationDate(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        require(_exists(tokenId), "NFT not exist");
        return _activeTimestamp[tokenId];
    }

    function reactivateNFT(uint256 tokenId) public {
        require(_exists(tokenId), "NFT not exist");
        require(ownerOf(tokenId) == msg.sender, "Yo arent the owner");
        require(_activeTimestamp[tokenId] < block.timestamp);

        require(
            USDToken.transferFrom(msg.sender, adminWallet, Price),
            "Failed to transfer USDC"
        );

        _activeTimestamp[tokenId] = block.timestamp + _duration; 
    }

    function getOwnedNFTIds(address user)
        public
        view
        returns (uint256[] memory)
    {
        return _ownedNFTs[user];
    }

    function getAllNFTs()
        public
        view
        returns (
            uint256[] memory,
            address[] memory,
            bool[] memory
        )
    {
        uint256[] memory tokenIds = new uint256[](_tokenIds.current());
        address[] memory owners = new address[](_tokenIds.current());
        bool[] memory iActive = new bool[](_tokenIds.current());

        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            uint256 tokenId = i + 1; 
            tokenIds[i] = tokenId;
            owners[i] = ownerOf(tokenId);
            iActive[i] = isActive(tokenId);
        }

        return (tokenIds, owners, iActive);
    }

    function getActiveNFTIds() public view returns (uint256[] memory) {
        uint256 activeCount = 0;

        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            uint256 tokenId = i + 1;
            if (isActive(tokenId)) {
                activeCount++;
            }
        }

        uint256[] memory activeIds = new uint256[](activeCount);
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            uint256 tokenId = i + 1;
            if (isActive(tokenId)) {
                activeIds[currentIndex] = tokenId;
                currentIndex++;
            }
        }

        return activeIds;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "");
        if (RevealedActive == false) {
            return notRevealedUri;
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

    function setURIBase(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        Price = _newPrice;
    }

    function Reveal() public onlyOwner {
        RevealedActive = true;
    }
}