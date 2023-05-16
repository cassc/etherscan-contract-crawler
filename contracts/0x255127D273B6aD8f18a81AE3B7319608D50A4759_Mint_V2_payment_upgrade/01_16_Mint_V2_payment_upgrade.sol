// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ECDSAUpgradeable.sol";
import "StringsUpgradeable.sol";
import "ERC721EnumerableUpgradeable.sol";
import "OwnableUpgradeable.sol";
import "Initializable.sol";

contract Mint_V2_payment_upgrade is
    Initializable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using ECDSAUpgradeable for bytes32;
    using ECDSAUpgradeable for bytes;
    using StringsUpgradeable for uint256;

    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) private _tokenOwners;
    uint256 private counter;
    address private server_address;
    uint256 private quantity_paid;
    uint256 private mint_price;

    function initialize(
        uint256 _counter,
        address _server_address,
        string memory token_name_symbol
    ) public initializer {
        counter = _counter;
        server_address = _server_address;
        __ERC721_init(token_name_symbol, token_name_symbol);
        __Ownable_init();
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = string(
            abi.encodePacked(
                _tokenURI,
                "/",
                StringsUpgradeable.toString(tokenId)
            )
        );
    }

    function get_quantity_paid() public view returns (uint256) {
        return quantity_paid;
    }

    function set_quantity_paid(uint256 _quantity_paid) public onlyOwner {
        quantity_paid = _quantity_paid;
    }

    function get_mint_price() public view returns (uint256) {
        return mint_price;
    }

    function set_mint_price(uint256 _price) public onlyOwner {
        mint_price = _price;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        return _tokenURI;
    }

    function mint(address addr, string memory url) public {
        require(msg.sender == server_address, "Address mismatch");
        _safeMint(addr, counter + 1);
        _setTokenURI(counter + 1, url);
        _tokenOwners[addr] = counter + 1;
        counter += 1;
    }

    function mint_pay(string memory url) public payable {
        require(quantity_paid > 0, "NFT sold out");
        require(msg.value >= mint_price, "Under mint price");

        _safeMint(msg.sender, counter + 1);
        _setTokenURI(counter + 1, url);
        _tokenOwners[msg.sender] = counter + 1;
        counter += 1;
        quantity_paid -= 1;
    }

    function burn(address owner) public {
        require(msg.sender == server_address, "Address mismatch");
        _burn(_tokenOwners[owner]);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}