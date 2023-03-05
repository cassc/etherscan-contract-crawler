// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IBlitkinRenderV3 {

    struct ContractInfo {
        string animationBase;
        string animationPostfix;
        string imageBase;
        string imagePostfix;
        string title;
        string description;
        string contractURI;
        uint16 royaltyFee; 
        address royaltyReciever;
        address blitmapAddress;
    }

    struct Inscription {
        string artist;
        bytes32 btc_txn;
        string composition;
    }

    function getContractInfo() external view returns(string memory);

    function tokenURI(uint256 tokenId, uint256 inscriptionId, uint256 blitmapPaletteId) external view returns (string memory);
}