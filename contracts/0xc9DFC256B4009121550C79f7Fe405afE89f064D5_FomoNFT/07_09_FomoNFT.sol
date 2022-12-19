pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FomoNFT is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string private uriPrefix = "";
    string public uriSuffix = ".json";
    string private hiddenMetadataUri;

    constructor() ERC721A("2022 FIFA World Cup Champion Argentina", "FWCCA") {
        setHiddenMetadataUri(
            "ipfs:/QmR6WFjxvbTXQ5mPEbww7PzSA6mqLWGapA1Gkj8qhF1c7G"
        );
    }

    uint256 public price = 0.008 ether;
    uint256 public maxPerTx = 20;
    uint256 public maxPerFree = 1;
    uint256 public maxFreeSupply = 2022;
    uint256 public maxSupply = 8888;

    bool public paused = false;
    bool public revealed = false;

    mapping(address => uint256) private _mintedFreeAmount;

    function changePrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    //mint
    function mint(uint256 count) external payable {
        uint256 cost = price;
        require(!paused, "The contract is paused!");
        require(count > 0, "Minimum 1 NFT has to be minted per transaction");
        if (msg.sender != owner()) {
            bool isFree = ((totalSupply() + count < maxFreeSupply + 1) &&
                (_mintedFreeAmount[msg.sender] + count <= maxPerFree));

            if (isFree) {
                cost = 0;
                _mintedFreeAmount[msg.sender] += count;
            }

            require(msg.value >= count * cost, "Please send the exact amount.");
            require(count <= maxPerTx, "Max per TX reached.");
        }

        require(totalSupply() + count <= maxSupply, "No more");

        _safeMint(msg.sender, count);
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
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

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setmaxPerTx(uint256 _maxPerTx) public onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setmaxPerFree(uint256 _maxPerFree) public onlyOwner {
        maxPerFree = _maxPerFree;
    }

    function setmaxFreeSupply(uint256 _maxFreeSupply) public onlyOwner {
        maxFreeSupply = _maxFreeSupply;
    }

    function setmaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
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

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}