// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC2981Setter.sol";
import "./AuthorizedAgent.sol";

contract WallStBullsOptionsToken is ERC1155Burnable, ERC2981Setter, AuthorizedAgent {
    uint256 public constant GOLD = 1;

    uint256 public salePrice = 1 ether;
    uint256 public mintCount = 0;
    uint256 public mintCap = 0;

    bool public baseURIFinal;

    bool public publicSaleActive;
    bool public presaleActive;

    bytes32 private _presaleMerkleRoot;

    event BaseURIChanged(string _baseURI);
    event PermanentURI(string _value, uint256 indexed _id);

    constructor(uint256 initialPriceWei, uint256 initialMintCap, string memory initialBaseURI) ERC1155(initialBaseURI) {
        salePrice = initialPriceWei;
        mintCap = initialMintCap;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view virtual override returns (bool isOperator) {
        if (isAgent(_operator)) {
            return true;
        }
        return super.isApprovedForAll(_owner, _operator);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        require(!baseURIFinal, "Base URI is unchangeable");
        _setURI(_newBaseURI);
        emit BaseURIChanged(_newBaseURI);
    }

    function finalizeBaseURI() external onlyOwner {
        baseURIFinal = true;
    }

    function emitPermanent(uint256 tokenId) external onlyOwner {
        require(baseURIFinal, "Base URI must be finalized first");
        emit PermanentURI(string(abi.encodePacked(uri(tokenId), Strings.toString(tokenId))), tokenId);
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        require(!presaleActive && !publicSaleActive, "Sale is currently active");
        _presaleMerkleRoot = _merkleRoot;
    }

    function setSalePrice(uint256 _salePriceWei) external onlyOwner {
        salePrice = _salePriceWei;
    }

    function setMintCap(uint256 _mintCap) external onlyOwner {
        mintCap = _mintCap;
    }

    function withdraw(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        (bool success,) = _to.call{value : _amount}("");
        require(success, "Failed to withdraw Ether");
    }

    function mintReserved(
        address _to,
        uint256 _tokenCount
    ) external onlyOwner {
        require(mintCount + _tokenCount <= mintCap, "No tokens available to mint");
        require(_tokenCount > 0, "Must mint at least one token");

        _mint(_to, GOLD, _tokenCount, "");
        mintCount += _tokenCount;
    }

    function _verifyPresaleEligible(
        address _account,
        uint8 _maxAllowed,
        bytes32[] calldata _merkleProof
    ) private view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(_account, _maxAllowed));
        return MerkleProof.verify(_merkleProof, _presaleMerkleRoot, node);
    }

    function mintPresale(
        uint256 _tokenCount,
        uint8 _maxAllowed,
        bytes32[] calldata _merkleProof
    ) external payable {
        require(presaleActive && !publicSaleActive, "Presale sale is not active");
        require(_verifyPresaleEligible(msg.sender, _maxAllowed, _merkleProof), "Address not found in presale list");
        require(mintCount + _tokenCount <= mintCap, "No tokens available to mint");
        require(_tokenCount > 0, "Must mint at least one token");
        require(salePrice * _tokenCount == msg.value, "ETH amount is incorrect");

        _mint(msg.sender, GOLD, _tokenCount, "");
        mintCount += _tokenCount;
    }

    function mint(uint256 _tokenCount) external payable {
        require(publicSaleActive, "Sale is not active");
        require(mintCount + _tokenCount <= mintCap, "No tokens available to mint");
        require(_tokenCount > 0, "Must mint at least one token");
        require(salePrice * _tokenCount == msg.value, "ETH amount is incorrect");

        _mint(msg.sender, GOLD, _tokenCount, "");
        mintCount += _tokenCount;
    }
}