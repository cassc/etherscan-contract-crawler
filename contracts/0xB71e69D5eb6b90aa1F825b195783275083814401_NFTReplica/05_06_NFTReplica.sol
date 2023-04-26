pragma solidity ^0.8.4;

import "./ERC/ERC173.sol";
import "./ERC/ERC721A.sol";

contract NFTReplica is ERC173, ERC721A {
    string public _baseTokenURI;

    event Minted(address indexed receiver, uint256 quantity);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenUri
    ) ERC721A(_name, _symbol) ERC173(msg.sender) {
        _baseTokenURI = _tokenUri;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC173) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC173.supportsInterface(interfaceId);
    }

    /* URI */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setTokenUri(
        uint256 tokenId,
        string calldata newUri
    ) external onlyOwner {
        _setTokenURI(tokenId, newUri);
    }

    /* MINT */

    function mint(address to, string calldata tokenUri) external onlyOwner {
        _mint(to, 1);
        _setTokenURI(_nextTokenId() - 1, tokenUri);
        emit Minted(to, 1);
    }

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function totalMinted() external view virtual returns (uint256) {
        return _totalMinted();
    }
}