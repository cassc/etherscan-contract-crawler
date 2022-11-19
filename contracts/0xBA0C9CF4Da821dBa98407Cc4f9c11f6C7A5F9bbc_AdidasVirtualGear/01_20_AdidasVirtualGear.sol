// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./DefaultOperatorFilterer.sol";
import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

interface ITMAirdrop {
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address account) external view returns (uint256);
}

contract AdidasVirtualGear is ERC721Enumerable, ERC2981, Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    string public baseUri = "";
    string public uriSuffix = ".json";

    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // minting status
    bool private _mintEnabled = false;
    // max supply
    uint256 private _maxSupply; 
    // v1 airdrop contract address
    ITMAirdrop private _airdropContract;

    constructor(string memory __name, string memory __symbol, address _address, string memory _baseUri, string memory _uriSuffix, uint256 __maxSupply) ERC721(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
        baseUri = _baseUri;
        uriSuffix = _uriSuffix;
        _maxSupply = __maxSupply;
        _airdropContract = ITMAirdrop(_address);
    }

    // Max Amount of Token that can ever be minted
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function setNameAndSymbol(string calldata __name, string calldata __symbol) public onlyOwner {
        _name = __name;
        _symbol = __symbol;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token.");

        string memory currentBaseURI = _baseURI();
        return string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix));
    }

    function reduceMaxSupply(uint256 amount) private {
        _maxSupply -= amount;
    }

    // Token Burning
    function batchBurn(uint256[] calldata _tokenIds) public {
        for (uint256 i; i < _tokenIds.length; ) {
            require(msg.sender == ownerOf(_tokenIds[i]), "Only token owner can burn.");
            _burn(_tokenIds[i]);
            unchecked {
                i++;
            }
        }

        // Reducing Max Supply
        reduceMaxSupply(_tokenIds.length);
    }

    // Upgrade Token
    function upgradeToken(uint256[] calldata _tokenIds) public {
        uint256 numToken = _tokenIds.length;
        require(numToken > 1, "More than 1 token must be submitted.");
        for (uint256 i=1; i < numToken; ) {
            require(msg.sender == ownerOf(_tokenIds[i]), "Only token owner can burn.");
            _burn(_tokenIds[i]);
            unchecked {
                i++;
            }
        }

        // Reducing Max Supply
        reduceMaxSupply(numToken - 1);
    }

    // Burns and Mints, also requires Approval
    function burnToMint(uint256[] calldata _tokenIds) public {
        require(_mintEnabled == true, "Minting not enabled yet!");

        uint256 newSupplyAmount = totalSupply() + _tokenIds.length;
        require(newSupplyAmount <= _maxSupply, "Reached minting limit.");
        
        for (uint256 i; i<_tokenIds.length;) {
            require(msg.sender == _airdropContract.ownerOf(_tokenIds[i]), "Only token owner can burn and mint."); 
            _airdropContract.burn(_tokenIds[i]);
            _mint(msg.sender, _tokenIds[i]);
            unchecked{
               i++;
            }
        }    
    }

    // Airdrop minting
    function mintMany(address[] calldata _to, uint256[] calldata _tokenIds) public onlyOwner {
        require(_to.length == _tokenIds.length, "Mismatched lengths.");

        uint256 newSupplyAmount = totalSupply() + _tokenIds.length;
        require(newSupplyAmount <= _maxSupply, "Reached minting limit.");

        for (uint256 i; i < _to.length; ) {
            _mint(_to[i], _tokenIds[i]);
            unchecked {
                i++;
            }
        }
    }

    // Token Ownership
    function walletOfCapsuleOwner(address __owner, uint256 _startingIndex, uint256 _endingIndex) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = _airdropContract.balanceOf(__owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startingIndex;
        uint256 ownedTokenIndex = 0;

        uint256 capsuleSupply = _endingIndex;

        if (ownerTokenCount > 0) {
            unchecked {
                while (ownedTokenIndex < ownerTokenCount && currentTokenId < capsuleSupply) {
                    try _airdropContract.ownerOf(currentTokenId) returns (address currentTokenOwner) {
                        if (currentTokenOwner == __owner) {
                            ownedTokenIds[ownedTokenIndex] = currentTokenId;
                                ownedTokenIndex++;
                        }
                    } catch {
                        // Do nothing for now
                    }
                        currentTokenId++;
                }
            }
        } 
        return ownedTokenIds;
    }

    function walletOfOwner(address __owner) public view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(__owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i<ownerTokenCount;){
            ownedTokenIds[i] = tokenOfOwnerByIndex(__owner, i);
            unchecked {
                i++;
            }
        }
        return ownedTokenIds;
    }

    // Minting Status
    function setMintStatus(bool enabled) public onlyOwner {
        _mintEnabled = enabled;
    }

    // URI methods
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string calldata _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setUriSuffix(string calldata _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    // Operator Registry Controls
    function updateOperator(address _operator, bool _filtered) public onlyOwner {
        OPERATOR_FILTER_REGISTRY.updateOperator(address(this), _operator, _filtered);
    }

    // Royalties
    function setRoyalties(address recipient, uint96 value) public onlyOwner {
        _setDefaultRoyalty(recipient, value);
    }

    // @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Registry Validated Transfers 
    function setApprovalForAll(address operator, bool approved) public override(ERC721,IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721,IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721,IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}