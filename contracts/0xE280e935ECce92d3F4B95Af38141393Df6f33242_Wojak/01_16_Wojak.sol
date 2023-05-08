// SPDX-License-Identifier: MIT
/*
 __       __                              __       
|  \  _  |  \                            |  \      
| $$ / \ | $$  ______       __   ______  | $$   __ 
| $$/  $\| $$ /      \     |  \ |      \ | $$  /  \
| $$  $$$\ $$|  $$$$$$\     \$$  \$$$$$$\| $$_/  $$
| $$ $$\$$\$$| $$  | $$    |  \ /      $$| $$   $$ 
| $$$$  \$$$$| $$__/ $$    | $$|  $$$$$$$| $$$$$$\ 
| $$$    \$$$ \$$    $$    | $$ \$$    $$| $$  \$$\
 \$$      \$$  \$$$$$$__   | $$  \$$$$$$$ \$$   \$$
                     |  \__/ $$                    
                      \$$    $$                    
                       \$$$$$$                     
*/
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

contract Wojak is ERC721Royalty, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public uriPrefix =
        "ipfs://bafybeiemodevpprikz6ue2tngrtc4gffc443uwmvlgrm43dmkk22jv5iyu/";
    string public uriSuffix = ".json";

    uint256 public mintCost = 0.00 ether;
    uint256 public maxSupply = 6969;
    uint256 public maxMintAmountPerTx = 10;
    uint96 public royaltyFraction = 690; // 0.069
    uint256 mintLimit = 10;
    mapping(address => uint256) public mintCount;

    event Mint(address msgSender, uint amount, uint when);
    event SetBaseURI(address msgSender, string baseURI, uint when);

    constructor() ERC721("Wojak Legends", "WOJAK") {
        supply.increment();
        _setDefaultRoyalty(msg.sender, royaltyFraction);
    }

    modifier mintRequire(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            supply.current() + _mintAmount - 1 <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current() - 1;
    }

    function mint(uint256 _mintAmount) public payable mintRequire(_mintAmount) {
        require(msg.value >= mintCost * _mintAmount, "Insufficient funds!");
        require(
            mintCount[msg.sender] + _mintAmount <= mintLimit,
            "public mint limit exceeded"
        );

        _mintLoop(msg.sender, _mintAmount);
        mintCount[msg.sender] += _mintAmount;

        emit Mint(msg.sender, _mintAmount, block.timestamp);
    }

    function getMintCount() public view returns (uint256) {
        return mintCount[msg.sender];
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
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

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_receiver, supply.current());
            supply.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        uriPrefix = baseURI;
        emit SetBaseURI(msg.sender, baseURI, block.timestamp);
    }

    function setMintCost(uint256 _mintCost) external onlyOwner {
        mintCost = _mintCost;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
    
}