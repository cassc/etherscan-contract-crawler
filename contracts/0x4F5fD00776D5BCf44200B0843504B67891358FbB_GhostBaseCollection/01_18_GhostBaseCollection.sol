// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../node_modules/@openzeppelin/contracts/utils/Counters.sol';
import '../node_modules/@openzeppelin/contracts/utils/Strings.sol';
import '../node_modules/erc721a/contracts/extensions/ERC721AQueryable.sol';
import './libraries/FactoryGenerated.sol';
import './libraries/SafeMath.sol';

/**
 * @title GhostBaseCollection
 * @notice Ghost base collection by factory
 */
contract GhostBaseCollection is FactoryGenerated, ERC721AQueryable {
    using SafeMath for uint256;

    // Used for generating the tokenId of new NFT minted
    address public creator;
    string private _contractURI;
    string private _BaseURI;

    event Mint(uint256 _tokenId, address _to);

    mapping(uint256 => string) public tokenURIs; // Details about token

    /**
     * @notice Constructor
     */
    constructor(string memory name, string memory symbol, address _creator) ERC721A(name, symbol) {
        creator = _creator;
        _transferOwnership(_creator);
        _updateFactory(msg.sender);
    }

    /**
     * @notice Allows the factory to mint a token to a specific address
     * @dev Callable by factory
     */
    function mint(string memory _tokenURI, address _to) external payable onlyFactory returns (uint256) {
        uint256 _newId = _nextTokenId();
        tokenURIs[_newId] = _tokenURI;
        _mint(_to, 1);
        emit Mint(_newId, _to);
        return _newId;
    }

    /**
     * @notice Allows the factory to mint a token to a specific address
     * @dev Callable by launch pad via factory
     */
    function batchMint(address _to, uint256 _quantity) external payable onlyFactory {
        uint256 _nextTokenId = _nextTokenId();
        for (uint256 index = 0; index < _quantity; index++) {
            uint256 _newId = index.add(_nextTokenId);
            emit Mint(_newId, _to);
        }
        return _mint(_to, _quantity);
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for a token ID
     * @param tokenId: token ID
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            return '';
        }
        if (bytes(tokenURIs[tokenId]).length != 0) {
            return tokenURIs[tokenId];
        }
        return bytes(_BaseURI).length != 0 ? string(abi.encodePacked(_BaseURI, _toString(tokenId))) : '';
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwnerOrFactoryWhitelist {
        _BaseURI = _newBaseURI;
    }

    function setContractURI(string memory _newContractURI) external onlyOwner {
        _contractURI = _newContractURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function updateTokenInfo(uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        tokenURIs[_tokenId] = _tokenURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function nextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }
}