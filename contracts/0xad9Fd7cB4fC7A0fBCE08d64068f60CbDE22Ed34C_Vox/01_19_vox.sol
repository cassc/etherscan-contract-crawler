// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Vox is VRFConsumerBase, ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    constructor(
        uint256 _saleStartTimestamp, 
        uint256 _revealSupply,
        uint256 _maxSupply
    )
    ERC721("VOX Series 1", "VOX") 
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
        0x514910771AF9Ca656af840dff83E8264EcF986CA
    )
    {
        saleStartTimestamp = _saleStartTimestamp;
        revealSupply = _revealSupply;
        maxSupply = _maxSupply;

        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18;
    }

    bytes32 internal keyHash;
    uint256 internal fee;

    string public constant PROVENANCE = "a5d0c1a1f96a62cd6188c1227baf7061361777fc295ce80d23af4576aad40f2e";
    
    uint256 public constant MAX_PURCHASE = 5;

    uint256 public constant PRICE = 0.0888 * 10 ** 18;

    uint256 public saleStartTimestamp;
    uint256 public revealSupply;
    uint256 public maxSupply;

    bytes32 internal vrfRequestId;
    uint256 public offset;
    
    function mintNFT(uint256 numberOfNfts) public payable {
        require(block.timestamp >= saleStartTimestamp, "Sale has not started");
        require(totalSupply() < maxSupply, "Sale has ended");
        require(numberOfNfts > 0, "Cannot buy 0");
        require(numberOfNfts <= MAX_PURCHASE, "You may not buy that many NFTs at once");
        require(totalSupply().add(numberOfNfts) <= maxSupply, "Exceeds max supply");
        require(PRICE.mul(numberOfNfts) == msg.value, "Ether value sent is not correct");

        for (uint i = 0; i < numberOfNfts; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function reveal() public {
        require(offset == 0, "Offset is already set");
        require(vrfRequestId == 0, "Randomness already requested");
        require(totalSupply() >= revealSupply, "Can not be revealed yet");
        vrfRequestId = requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        require(offset == 0, "Offset is already set");
        require(vrfRequestId == requestId, "VRF Request Id must match");
        offset = (randomness % (maxSupply - 1)) + 1;
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();

        if (offset == 0) {
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "mystery")) : "";
        } else {
            uint256 voxId = tokenId.add(offset) % maxSupply;
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, voxId.toString())) : "";
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://www.collectvox.com/metadata/town-star/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}