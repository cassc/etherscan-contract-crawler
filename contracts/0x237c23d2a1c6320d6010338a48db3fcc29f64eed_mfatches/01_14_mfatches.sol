// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract mfatches is ERC721, Ownable, ERC721Enumerable {
    using ECDSA for bytes32;

    string private _baseTokenURI;
    uint256 private _maxTokenSupply;

    uint256 public publicSalePrice;
    uint256 private publicSaleLimit = 50;
    bool public publicSaleActive = false;

    uint256 public presaleId = 1;
    bool public presaleActive = false;
    mapping(bytes32 => uint256) private _mintedPresale;

    constructor(string memory baseURI, uint256 maxTokenSupply)
        ERC721('mfatch', 'MFATCH')
    {
        _baseTokenURI = baseURI;
        _maxTokenSupply = maxTokenSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _mintAmount(address to, uint256 amount) internal {
        require(amount > 0, 'Must mint at least one token');

        uint256 supply = totalSupply();
        require(supply + amount <= _maxTokenSupply, 'Minting would exceed max supply');

        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(to, supply + i);
        }
    }

    function _mintForPrice(uint256 amount, uint256 price) internal {
        require(amount * price == msg.value, 'Ether value sent is not correct');
        _mintAmount(msg.sender, amount);
    }

    function _verifySignature(
        address signer,
        bytes32 data,
        bytes memory signature
    ) internal pure returns (bool) {
        return data.toEthSignedMessageHash().recover(signature) == signer;
    }

    function setPresaleId(uint256 _presaleId) external onlyOwner {
        require(presaleId != _presaleId, 'Presale ID is already set');
        presaleId = _presaleId;
    }

    function startPresale() external onlyOwner {
        require(!presaleActive, 'Presale has already begun');
        presaleActive = true;
    }

    function pausePresale() external onlyOwner {
        require(presaleActive, 'Presale is not active');
        presaleActive = false;
    }

    function presaleMint(
        uint256 amount,
        uint256 price,
        uint256 limit,
        bytes memory signature
    ) external payable {
        require(presaleActive, 'Presale is not active');

        bytes32 data = keccak256(abi.encodePacked(address(this), msg.sender, price, limit, presaleId));
        require(_verifySignature(owner(), data, signature), 'Invalid signature for presale');

        uint256 minted = _mintedPresale[data] + amount;
        require(minted <= limit, 'Minting would exceed presale limit');

        _mintForPrice(amount, price);
        _mintedPresale[data] = minted;
    }

    function startPublicSale(uint256 price) external onlyOwner {
        require(!publicSaleActive, 'Public sale has already begun');
        publicSalePrice = price;
        publicSaleActive = true;
    }

    function pausePublicSale() external onlyOwner {
        require(publicSaleActive, 'Public sale is not active');
        publicSaleActive = false;
    }

    function publicMint(uint256 amount) external payable {
        require(publicSaleActive, 'Public sale is not active');
        require(amount <= publicSaleLimit, 'Can only mint 50 watches at once');
        _mintForPrice(amount, publicSalePrice);
    }

    function airdrop(address to, uint256 amount) external onlyOwner {
        _mintAmount(to, amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, 'No balance to withdraw');
        require(payable(owner()).send(balance));
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory tokens) {
        uint256 balance = balanceOf(owner);
        uint256[] memory result = new uint256[](balance);
        for (uint256 index = 0; index < balance; index++) {
            result[index] = tokenOfOwnerByIndex(owner, index);
        }
        return result;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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