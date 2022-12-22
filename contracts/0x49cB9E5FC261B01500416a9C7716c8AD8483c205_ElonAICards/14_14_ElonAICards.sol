//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Elon AI Cards
 */
contract ElonAICards is Ownable, ERC721Enumerable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 8888;

    bool public paused = true;
    bool public revealed = false;

    string public uriPrefix = "https://eloncards.herokuapp.com/api/token/";
    string public uriSuffix = "";
    string public hiddenMetadataUri;

    /// Price is 0.08 wETH
    uint256 public price = 0.08 ether;
    uint256 public maxPerTx = 11;

    constructor() ERC721("Elon AI Cards", "ELONAI") {
        setHiddenMetadataUri(
            "ipfs://QmPC1d1ZWTjkfmzQZTce4T23USZeitDraiR64YEQAmeFv3"
        );
    }

    function changePrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

    function mint(uint256 count) external payable {
        uint256 cost = price;
        require(!paused, "The contract is paused!");
        require(count > 0, "Minimum 1 NFT has to be minted per transaction");
        if (msg.sender != owner()) {
            uint256 totalPrice = cost * count;
            require(msg.value >= totalPrice, "Please send the exact amount.");
            require(count <= maxPerTx, "Max per TX reached.");
        }

        require(totalSupply() + count <= MAX_SUPPLY, "No more");

        uint256 startNum = totalSupply();
        for (uint256 i = 0; i < count; i++) {
            uint256 id = startNum + i;
            _safeMint(msg.sender, id);
        }
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

    function setHiddenMetadataUri(
        string memory _hiddenMetadataUri
    ) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
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

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}