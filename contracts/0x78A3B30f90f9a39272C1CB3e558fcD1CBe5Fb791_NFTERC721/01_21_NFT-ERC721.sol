// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./NFT.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract NFTERC721 is NFT, ERC721EnumerableUpgradeable {
    
    using Counters for Counters.Counter;
    Counters.Counter private _counterForTokenId;

    uint256 public _mintUpperLimitAmount;
    event SetUpperLimitOfTokenId(address sender, uint256 indexed maxAmount);
    event Freemint(address sender, address indexed to, uint256 indexed tokenId);

    function initialize(string memory name_, string memory symbol_, string memory uri_, address config_) public override initializer { 
        super.initialize(name_, symbol_, uri_, config_);
        __ERC721_init(name_, symbol_); 
    }

    function setBaseURI(string memory uri_) external onlyAdmin {
        baseUri = uri_;
        emit SetBaseURI(msg.sender, uri_);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseURI(), Strings.toString(tokenId)));
    }

    function setUpperLimitOfTokenId(uint256 maxTokenId) external onlyAdmin {
        _mintUpperLimitAmount = maxTokenId;
        emit SetUpperLimitOfTokenId(_msgSender(), maxTokenId);
    }

    function freemint(address to) public allowFreemint returns (uint256 newTokenId) {
        _counterForTokenId.increment();
        newTokenId = _counterForTokenId.current();
        require(newTokenId <= _mintUpperLimitAmount, "ERC721: exceeded upper limit of tokenId minting");
        _safeMint(to, newTokenId);
        emit Freemint(_msgSender(), to, newTokenId);
    }

    function mint() public nonReentrant isMinter returns (uint256 newTokenId) {
        address to = _getPlatformAssetContract();
        _counterForTokenId.increment();
        newTokenId = _counterForTokenId.current();
        _safeMint(to, newTokenId);
    }

    function mintNFT(NFTParam[] memory params) public override nonReentrant isMinter returns (bool) {
        require(params.length > 0, "SN110: invalid parameters");
        address to = _getPlatformAssetContract();
        for (uint i = 0; i < params.length; i++) {
            uint tokenId = params[i].tokenId;
            require(params[i].amount == 1, "SN111: amount must be equal to 1");
            super._safeMint(to, tokenId);
        }
        return super.mintNFT(params);
    }

    function burnNFT(NFTParam[] memory params) public override nonReentrant isBurner returns (bool) {
        require(params.length > 0, "SN110: invalid parameters");
        address from = _getPlatformAssetContract();
        for (uint i = 0; i < params.length; i++) {
            uint tokenId = params[i].tokenId;
            require(params[i].amount == 1, "SN111: amount must be equal to 1");
            require(_isApprovedOrOwner(_msgSender(), tokenId), "SN112: caller is not token owner nor approved");
            require(ownerOf(tokenId) == from, "SN113: tokenId and owner mismatch");
            super._burn(tokenId);
        }
        return super.burnNFT(params);
    }

    function burn(uint256 tokenId) public selfBurn {
        require(ownerOf(tokenId) == msg.sender, "SN116: you do not have it");
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused isNotInTheFromBlacklist(from) isNotInTheToBlacklist(to) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function transferNFT(TransferParam[] memory params) public override nonReentrant isTransferer returns (bool) {
        address from = _msgSender();
        for (uint i = 0; i < params.length; i++) {
            address to = params[i].to;
            uint tokenId = params[i].tokenId;
            require(ownerOf(tokenId) == from, "SN113: tokenId and owner mismatch");
            super.safeTransferFrom(from, to, tokenId);
        }
        return super.transferNFT(params);
    }

}