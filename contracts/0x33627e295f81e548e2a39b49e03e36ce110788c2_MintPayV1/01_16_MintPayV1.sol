// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ECDSAUpgradeable.sol";
import "StringsUpgradeable.sol";
import "ERC721EnumerableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "Initializable.sol";

contract MintPayV1 is
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using ECDSAUpgradeable for bytes;
    using StringsUpgradeable for uint256;

    mapping(uint256 => string) private tokenURIs;
    uint256 private counter;
    uint256 private maxQuantity;
    address private mintAddress;
    uint256 private mintPrice;
    string[] private newTokenURIs;

    function initialize(
        uint256 _counter,
        uint256 _maxQuantity,
        address _mintAddress,
        uint256 _mintPrice,
        string[] memory _newTokenURIs,
        string memory _tokenNameAndSymbol
    ) public initializer {
        counter = _counter;
        maxQuantity = _maxQuantity;
        mintAddress = _mintAddress;
        mintPrice = _mintPrice;
        newTokenURIs = _newTokenURIs;
        __ERC721_init(_tokenNameAndSymbol, _tokenNameAndSymbol);
        __Ownable_init();
    }

    function _setTokenURI(
        uint256 _tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        tokenURIs[_tokenId] = _tokenURI;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return tokenURIs[_tokenId];
    }

    function mint(address _addr) public {
        require(msg.sender == mintAddress, "Address mismatch");
        require(counter < maxQuantity, "NFT sold out");

        string memory newTokenURI = newTokenURIs[
            (counter + 1) % newTokenURIs.length
        ];

        _safeMint(_addr, counter + 1);
        _setTokenURI(counter + 1, newTokenURI);
        counter += 1;
    }

    function mintPay(address _to, uint256 _count) public payable {
        require(mintPrice > 0, "Mint price not set");
        require(msg.value >= mintPrice * _count, "Under mint price");
        require(counter + _count <= maxQuantity, "NFT sold out");

        for (uint256 i = 0; i < _count; i++) {
            string memory newTokenURI = newTokenURIs[
                (counter + 1) % newTokenURIs.length
            ];

            _safeMint(_to, counter + 1);
            _setTokenURI(counter + 1, newTokenURI);
            counter += 1;
        }
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }

    function setCounter(uint256 _counter) public onlyOwner {
        counter = _counter;
    }

    function getMaxQuantity() public view returns (uint256) {
        return maxQuantity;
    }

    function setMaxQuantity(uint256 _maxQuantity) public onlyOwner {
        maxQuantity = _maxQuantity;
    }

    function getMintAddress() public view returns (address) {
        return mintAddress;
    }

    function setMintAddress(address _mintAddress) public onlyOwner {
        mintAddress = _mintAddress;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function getNewTokenURIs() public view returns (string[] memory) {
        return newTokenURIs;
    }

    function setNewTokenURIs(string[] memory _newTokenURIs) public onlyOwner {
        newTokenURIs = _newTokenURIs;
    }
}