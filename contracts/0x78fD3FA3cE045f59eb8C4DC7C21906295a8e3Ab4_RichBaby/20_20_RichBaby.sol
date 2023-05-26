// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/RichBaby.sol";

contract XRichBaby is RichBaby {
    constructor(address punkAddress, address baycAddress, address _signerAddress, uint16 _collectionSize, uint64 _refundPeriod) RichBaby(punkAddress, baycAddress, _signerAddress, _collectionSize, _refundPeriod) {}

    function xvalidateMatingRequest(RichBaby.MatingRequest calldata matingRequest,bytes calldata sig) external view {
        return super.validateMatingRequest(matingRequest,sig);
    }

    function xverifyPunkOwnership(uint16 punkId,address holder) external view {
        return super.verifyPunkOwnership(punkId,holder);
    }

    function xverifyBaycOwnership(uint16 baycId,address holder) external view {
        return super.verifyBaycOwnership(baycId,holder);
    }

    function xpunkId2Index(uint16 punkId) external pure returns (uint16) {
        return super.punkId2Index(punkId);
    }

    function xbaycId2Index(uint16 baycId) external pure returns (uint16) {
        return super.baycId2Index(baycId);
    }

    function x_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function x_domainSeparatorV4() external view returns (bytes32) {
        return super._domainSeparatorV4();
    }

    function x_hashTypedDataV4(bytes32 structHash) external view returns (bytes32) {
        return super._hashTypedDataV4(structHash);
    }

    function x_afterTokenTransfers(address from,address to,uint256 startTokenId,uint256 quantity) external {
        return super._afterTokenTransfers(from,to,startTokenId,quantity);
    }

    function x_startTokenId() external view returns (uint256) {
        return super._startTokenId();
    }

    function x_totalMinted() external view returns (uint256) {
        return super._totalMinted();
    }

    function x_numberMinted(address owner) external view returns (uint256) {
        return super._numberMinted(owner);
    }

    function x_numberBurned(address owner) external view returns (uint256) {
        return super._numberBurned(owner);
    }

    function x_getAux(address owner) external view returns (uint64) {
        return super._getAux(owner);
    }

    function x_setAux(address owner,uint64 aux) external {
        return super._setAux(owner,aux);
    }

    function xownershipOf(uint256 tokenId) external view returns (ERC721A.TokenOwnership memory) {
        return super.ownershipOf(tokenId);
    }

    function x_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function x_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function x_safeMint(address to,uint256 quantity) external {
        return super._safeMint(to,quantity);
    }

    function x_safeMint(address to,uint256 quantity,bytes calldata _data) external {
        return super._safeMint(to,quantity,_data);
    }

    function x_mint(address to,uint256 quantity,bytes calldata _data,bool safe) external {
        return super._mint(to,quantity,_data,safe);
    }

    function x_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function x_beforeTokenTransfers(address from,address to,uint256 startTokenId,uint256 quantity) external {
        return super._beforeTokenTransfers(from,to,startTokenId,quantity);
    }

    function x_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function x_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}