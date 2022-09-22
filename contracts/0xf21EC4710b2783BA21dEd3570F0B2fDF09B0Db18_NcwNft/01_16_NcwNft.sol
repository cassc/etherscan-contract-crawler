// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NcwNft is ERC721, ERC2981, ERC721Enumerable, ERC721URIStorage, Ownable {
    uint256 public maxSupply;
    uint256 public currentTokenId;
    uint256 private _MINT_FEE;
    event WithdrawPayments(uint256 _amount);
    event SetMintFee(uint256 oldMintFee, uint256 newMinFee);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _mint_fee,
        uint256 _maxSupply,
        address _owner,
        address _royaltyReceiver,
        uint96 _royaltyFee // 100 = 1%
    ) ERC721(_name, _symbol) {
        require(_owner != address(0), "invalid address");
        require(_maxSupply > 0, "maxSupply is 0");
        if (_royaltyReceiver != address(0)) {
            _setDefaultRoyalty(_royaltyReceiver, _royaltyFee);
        }
        maxSupply = _maxSupply;
        _MINT_FEE = _mint_fee;
        _transferOwnership(_owner);
    }

    function safeMint(
        address to,
        string calldata _tokenURI,
        uint96 royaltyFee
    ) external payable {
        require(msg.value == _MINT_FEE, "insufficient fee");
        require(totalSupply() < maxSupply, "max supply reached");
        require(bytes(_tokenURI).length != 0, "tokenURI is empty");
        _safeMint(to, currentTokenId);
        _setTokenURI(currentTokenId, _tokenURI);
        if (royaltyFee > 0) {
            _setTokenRoyalty(currentTokenId, to, royaltyFee);
        }
        currentTokenId++;
    }

    function batchMint(
        address to,
        uint256 tokenAmount,
        string[] memory tokenURIList,
        uint96 royaltyFee
    ) external payable {
        require(tokenAmount == tokenURIList.length, "length mismatch");
        require(totalSupply() + tokenAmount <= maxSupply, "max supply reached");
        require(msg.value == tokenAmount * _MINT_FEE, "insufficient fee");
        for (uint256 i; i < tokenAmount; i++) {
            require(bytes(tokenURIList[i]).length != 0, "tokenURI is empty");
            _safeMint(to, currentTokenId);
            _setTokenURI(currentTokenId, tokenURIList[i]);
            if (royaltyFee > 0) {
                _setTokenRoyalty(currentTokenId, to, royaltyFee);
            }
            currentTokenId++;
        }
    }

    function withdrawPayments(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "amount exceeds balance");
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "transfer failed");
        // owner.transfer(_amount);
        emit WithdrawPayments(_amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 _tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    function _burn(uint256 _tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory _tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            _tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return _tokenIds;
    }

    function setMintFee(uint256 _mint_fee) external onlyOwner {
        emit SetMintFee(_MINT_FEE, _mint_fee);
        _MINT_FEE = _mint_fee;
    }

    function mintFee() public view returns (uint256) {
        return _MINT_FEE;
    }
}