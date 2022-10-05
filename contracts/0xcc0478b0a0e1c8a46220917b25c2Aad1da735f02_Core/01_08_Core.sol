// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ICore.sol";
import "./interfaces/IOpenseaFactory.sol";
import "./interfaces/IRoyaltySplitter.sol";
import "./interfaces/INFT.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Core is ICore, Ownable {
    using Clones for address;

    bytes32 constant private SALTER = hex"10";

    address public immutable NFT_IMPLEMENTATION;
    address public immutable OPENSEA_MINTER_IMPLEMENTATION;
    address public immutable ROYALTY_SPLITTER_IMPLEMENTATION;

    constructor(address nftImp, address openseaImp, address splitterImp) {
        NFT_IMPLEMENTATION = nftImp;
        OPENSEA_MINTER_IMPLEMENTATION = openseaImp;
        ROYALTY_SPLITTER_IMPLEMENTATION = splitterImp;
    }

    function newNFT(NewNFTParams calldata params) external onlyOwner returns(address) {
        address nft = NFT_IMPLEMENTATION.cloneDeterministic(params.nftSalt);
        bytes32 salt = _salt(nft);
    
        address splitter = ROYALTY_SPLITTER_IMPLEMENTATION.cloneDeterministic(salt);
        address openseaMinter = OPENSEA_MINTER_IMPLEMENTATION.cloneDeterministic(salt);
        address splitterFirstSale = ROYALTY_SPLITTER_IMPLEMENTATION.cloneDeterministic(_alterSalt(salt));
    
        INFT(nft).initialize(
            params.metadata,
            params.totalSupply,
            params.royalties.royaltyInBasisPoints,
            params.isTypeBased,
            openseaMinter,
            splitter
        );
        IRoyaltySplitter(splitter).initialize(
            params.royalties.royals.accounts, params.royalties.royals.shares
        );
        IOpenseaFactory(openseaMinter).initialize(
            params.owner,
            splitterFirstSale,
            params.royalties.royaltyInBasisPointsFirstSale,
            nft,
            params.premintStart,
            params.premintEnd
        );
        IRoyaltySplitter(splitterFirstSale).initialize(
            params.royalties.royalsFirstSale.accounts, params.royalties.royalsFirstSale.shares
        );

        emit NewNFT(nft, openseaMinter, splitter, splitterFirstSale, params);
        return nft;
    }

    function _salt(address nft) private pure returns(bytes32) {
        return bytes32(abi.encode(nft));
    }

    function _alterSalt(bytes32 salt) private pure returns(bytes32) {
        return salt | SALTER;
    }

    function getNFTBySalt(bytes32 salt) external view returns(address) {
        return NFT_IMPLEMENTATION.predictDeterministicAddress(salt);
    }

    function getOpenseaMinterByNFT(address nft) external view returns(address) {
        return OPENSEA_MINTER_IMPLEMENTATION.predictDeterministicAddress(_salt(nft));
    }

    function getRoyaltySplitterByNFT(address nft) external view returns(address) {
        return ROYALTY_SPLITTER_IMPLEMENTATION.predictDeterministicAddress(_salt(nft));
    }

    function getRoyaltySplitterFirstSaleByNFT(address nft) external view returns(address) {
        return ROYALTY_SPLITTER_IMPLEMENTATION.predictDeterministicAddress(_alterSalt(_salt(nft)));
    }
}