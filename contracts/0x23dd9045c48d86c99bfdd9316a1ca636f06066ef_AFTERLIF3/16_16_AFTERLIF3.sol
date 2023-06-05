// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/AFTERLIF3.sol";

contract $AFTERLIF3 is AFTERLIF3 {
    constructor(string memory name, string memory symbol, string memory initBaseURI) AFTERLIF3(name, symbol, initBaseURI) {}

    function $_cost() external view returns (uint256) {
        return _cost;
    }

    function $_maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function $_maxMintBatchQuantity() external view returns (uint256) {
        return _maxMintBatchQuantity;
    }

    function $_merkleRootHash() external view returns (bytes32) {
        return _merkleRootHash;
    }

    function $_baseTokenURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    function $_royalties() external view returns (ERC2981Base.RoyaltyInfo memory) {
        return _royalties;
    }

    function $_currentIndex() external view returns (uint256) {
        return _currentIndex;
    }

    function $_burnCounter() external view returns (uint256) {
        return _burnCounter;
    }

    function $_ownerships(uint256 arg0) external view returns (ERC721A.TokenOwnership memory) {
        return _ownerships[arg0];
    }

    function $_startTokenId() external view returns (uint256) {
        return super._startTokenId();
    }

    function $_validateTransaction(bytes32[] calldata proof,address user) external view returns (bool) {
        return super._validateTransaction(proof,user);
    }

    function $_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function $_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function $_totalMinted() external view returns (uint256) {
        return super._totalMinted();
    }

    function $_numberMinted(address owner) external view returns (uint256) {
        return super._numberMinted(owner);
    }

    function $_numberBurned(address owner) external view returns (uint256) {
        return super._numberBurned(owner);
    }

    function $_getAux(address owner) external view returns (uint64) {
        return super._getAux(owner);
    }

    function $_setAux(address owner,uint64 aux) external {
        return super._setAux(owner,aux);
    }

    function $_ownershipOf(uint256 tokenId) external view returns (ERC721A.TokenOwnership memory) {
        return super._ownershipOf(tokenId);
    }

    function $_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function $_safeMint(address to,uint256 quantity) external {
        return super._safeMint(to,quantity);
    }

    function $_safeMint(address to,uint256 quantity,bytes calldata _data) external {
        return super._safeMint(to,quantity,_data);
    }

    function $_mint(address to,uint256 quantity,bytes calldata _data,bool safe) external {
        return super._mint(to,quantity,_data,safe);
    }

    function $_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function $_burn(uint256 tokenId,bool approvalCheck) external {
        return super._burn(tokenId,approvalCheck);
    }

    function $_beforeTokenTransfers(address from,address to,uint256 startTokenId,uint256 quantity) external {
        return super._beforeTokenTransfers(from,to,startTokenId,quantity);
    }

    function $_afterTokenTransfers(address from,address to,uint256 startTokenId,uint256 quantity) external {
        return super._afterTokenTransfers(from,to,startTokenId,quantity);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}