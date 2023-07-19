// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ECDSAUpgradeable.sol";
import "StringsUpgradeable.sol";
import "ERC721EnumerableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "Initializable.sol";

contract MintYeti is
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using ECDSAUpgradeable for bytes;
    using StringsUpgradeable for uint256;

    mapping(uint256 => string) private _tokenURIs;
    uint256 private counter;
    address private yetiAddress;
    uint256 private counterPay;
    uint256 private mintPrice;

    function initialize(
        uint256 _counter,
        address _yetiAddress
    ) public initializer {
        counter = _counter;
        yetiAddress = _yetiAddress;
        __ERC721_init("Callback Yeti", "CY");
        __Ownable_init();
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string.concat(
                "https://callback.is/yeti/",
                StringsUpgradeable.toString(_tokenId)
            );
    }

    // Reserved NFTs for community members
    function mint(address _addr) public {
        require(msg.sender == yetiAddress, "Address mismatch");
        require(counter < 1111, "NFT sold out");

        _safeMint(_addr, counter + 1, "");
        counter += 1;
    }

    function mintPay(address _to, uint256[] memory _tokenIds) public payable {
        require(mintPrice > 0, "Mint price not set");
        require(msg.value >= mintPrice * _tokenIds.length, "Under mint price");

        // Require _tokenIds all belong to owner address
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                _ownerOf(_tokenIds[i]) == owner(),
                "Token not owned by contract owner"
            );
        }

        // Transfer token from owner
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _safeTransfer(owner(), _to, _tokenIds[i], "");
        }
    }

    function mintToOwner(uint256 _quantity) public onlyOwner {
        require(counterPay + _quantity <= 2222, "NFT sold out");

        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(owner(), 1111 + counterPay + 1, "");
            counterPay += 1;
        }
    }

    function mintZeroToOwner() public onlyOwner {
        _safeMint(owner(), 0, "");
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawContractBalance() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }

    function getYetiAddress() public view returns (address) {
        return yetiAddress;
    }

    function setYetiAddress(address _yetiAddress) public onlyOwner {
        yetiAddress = _yetiAddress;
    }

    function getCounterPay() public view returns (uint256) {
        return counterPay;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }
}