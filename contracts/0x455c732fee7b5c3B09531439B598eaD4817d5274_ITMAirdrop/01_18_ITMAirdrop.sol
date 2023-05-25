// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "openzeppelin-contracts/contracts/utils/Counters.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./ERC721A/ERC721A.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";

contract ITMAirdrop is ERC721A, Ownable, ERC2981ContractWideRoyalties {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    string public hiddenMetadataUri;

    bool public revealed = false;

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;

    constructor(string memory __name, string memory __symbol) ERC721A(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
    }

    function mint(address receiver, uint256 amount) public onlyOwner {
        for (uint256 i; i < amount; ) {
            _mint(receiver, amount);

            unchecked {
                i++;
            }
        }
    }

    function mintMany(address[] calldata _to, uint256[] calldata _amount) external onlyOwner {
        for (uint256 i; i < _to.length; ) {
            _mint(_to[i], _amount[i]);

            unchecked {
                i++;
            }
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
                : hiddenMetadataUri;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setNameAndSymbol(string memory __name, string memory __symbol) public onlyOwner {
        _name = __name;
        _symbol = __symbol;
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
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

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981Base) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalties(address recipient, uint256 value) public onlyOwner {
        _setRoyalties(recipient, value);
    }
}