// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721PresetMinterPauserAutoId} from "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract Badge is Ownable, ERC721PresetMinterPauserAutoId {
    address private _feeCollector;
    string private _baseContractURI;

    constructor(
        string memory _baseTokenURI,
        string memory _contractURI,
        address _collector
    ) ERC721PresetMinterPauserAutoId("OnePunchSwap Early Adopter NFT", "OPEA", _baseTokenURI) {
        _feeCollector = _collector;
        _baseContractURI = _contractURI;
    }

    /**
     * @notice
     * Implement ERC2981, but actually the most marketplaces have their own royalty logic. Only LooksRare
     *
     * @param _tokenId The token ID of current sold item
     * @param _salePrice The Sale price of current sold item
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_feeCollector, 0);
    }

    /**
     * @notice
     * Return the contract-level metadata for opensea
     * https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() external view returns (string memory) {
        return _baseContractURI;
    }

    /**
     * @notice
     * Transfer ownership to new owner. And transfer mint role from old owner to new owenr.
     *
     * @param _newOwner The new owner
     */
    function transferOwnership(address _newOwner) public override onlyOwner {
        _setupRole(MINTER_ROLE, _newOwner);
        _revokeRole(MINTER_ROLE, _msgSender());

        super.transferOwnership(_newOwner);
    }
}