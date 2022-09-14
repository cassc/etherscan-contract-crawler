// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @custom:security-contact [email protected]
contract PublicLimitedNFT is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Royalty {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public baseTokenURI;
    uint256 public supplyCap;
    uint256 public price;
    address public paymentAddress;

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _baseTokenURI,
        uint256 _supplyCap,
        uint256 _price, 
        address _paymentAddress,
        uint96 _royalty
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;

        supplyCap = _supplyCap;
        price = _price;

        paymentAddress = _paymentAddress;
        _setDefaultRoyalty(_paymentAddress, _royalty);
        _pause();
    }

    // PUBLIC FUNCTIONS

    function mint() external payable whenNotPaused {
        require(msg.value == price, "MintError: payment must equal price");
        _mint(_msgSender());
        payable(paymentAddress).transfer(address(this).balance);
    }

    function tokensOfAddress(address _address) public view returns (uint256[] memory) {
        uint256 count = balanceOf(_address);
        uint256[] memory tokens = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            tokens[i] = tokenOfOwnerByIndex(_address, i);
        }

        return tokens;
    }

    // OWNER FUNCTIONS

    function airdrop(address _to) external onlyOwner {
        _mint(_to);
    }

    function updateBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function updateDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function updatePaymentAddress(address _paymentAddress) external onlyOwner {
        paymentAddress = _paymentAddress;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // INTERNAL

    function _mint(address _to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < supplyCap, "MintError: supplyCap reached");
        _tokenIdCounter.increment();

        _safeMint(_to, tokenId);
    }

    // OVERRIDES

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}