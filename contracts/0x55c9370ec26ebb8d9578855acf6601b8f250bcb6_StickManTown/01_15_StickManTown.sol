// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "erc721a/contracts/ERC721A.sol";

error ErrorSaleNotStarted();
error ErrorInsufficientFund();
error ErrorExceedTransactionLimit();
error ErrorExceedMaxSupply();

contract StickManTown is ERC721A, Ownable {
    using Address for address payable;
    using ECDSA for bytes32;
    using Strings for uint256;

    uint32 public constant TX_LIMIT = 10;

    uint256 public immutable _mintPrice;
    uint32 public immutable _maxSupply;
    uint32 public immutable _freeSupply;

    uint32 public _totalFreeMinted;
    bool public _started;
    string public _metadataURI;

    constructor(
        uint256 mintPrice,
        uint32 maxSupply,
        uint32 freeSupply
    ) ERC721A("StickManTown", "SMT") {
        require(freeSupply <= maxSupply);

        _mintPrice = mintPrice;
        _maxSupply = maxSupply;
        _freeSupply = freeSupply;
    }

    function mint(uint32 amount) external payable {
        if (!_started) revert ErrorSaleNotStarted();

        if (amount + _totalMinted() > _maxSupply) revert ErrorExceedMaxSupply();
        if (amount > TX_LIMIT) revert ErrorExceedTransactionLimit();

        uint256 requiredValue = amount * _mintPrice;
        if (_getAux(msg.sender) == 0) {
            requiredValue -= _mintPrice;
            _setAux(msg.sender, 1);
        }

        if (msg.value < requiredValue) revert ErrorInsufficientFund();

        _safeMint(msg.sender, amount);
    }

    function _aux(address minter) external view returns (uint32) {
        return uint32(_getAux(minter));
    }

    function _minted() external view returns (uint256) {
        return ERC721A._totalMinted();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }


    function setStarted(bool started) external onlyOwner {
        _started = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}