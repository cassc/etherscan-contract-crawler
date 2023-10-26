// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, Data} from "../libraries/HeyMintStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract HeyMintERC1155ExtensionG is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    // ============ FREE CLAIM ============

    /**
     * @notice To be updated by contract owner to allow free claiming tokens
     * @param _tokenId The id of the token to update
     * @param _freeClaimActive If true tokens can be claimed for free
     */
    function setFreeClaimState(
        uint16 _tokenId,
        bool _freeClaimActive
    ) external onlyOwner {
        TokenConfig storage tokenCfg = HeyMintStorage.state().tokens[_tokenId];
        if (_freeClaimActive) {
            require(
                tokenCfg.freeClaimContractAddress != address(0),
                "NOT_CONFIGURED"
            );
            require(tokenCfg.mintsPerFreeClaim != 0, "NOT_CONFIGURED");
        }
        tokenCfg.freeClaimActive = _freeClaimActive;
    }

    /**
     * @notice Set the contract address of the NFT eligible for free claim
     * @param _tokenId The id of the token to update
     * @param _freeClaimContractAddress The new contract address
     */
    function setFreeClaimContractAddress(
        uint16 _tokenId,
        address _freeClaimContractAddress
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .tokens[_tokenId]
            .freeClaimContractAddress = _freeClaimContractAddress;
    }

    /**
     * @notice Update the number of free mints claimable per token redeemed from the external ERC721 contract
     * @param _tokenId The id of the token to update
     * @param _mintsPerFreeClaim The new number of free mints per token redeemed
     */
    function updateMintsPerFreeClaim(
        uint16 _tokenId,
        uint8 _mintsPerFreeClaim
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .tokens[_tokenId]
            .mintsPerFreeClaim = _mintsPerFreeClaim;
    }

    /**
     * @notice Check if an array of tokens is eligible for free claim
     * @param _tokenId The id of the token on this contract
     * @param _claimTokenIds The ids of the tokens to check
     */
    function checkFreeClaimEligibility(
        uint16 _tokenId,
        uint256[] calldata _claimTokenIds
    ) external view returns (bool[] memory) {
        Data storage data = HeyMintStorage.state().data;
        bool[] memory eligible = new bool[](_claimTokenIds.length);
        for (uint256 i = 0; i < _claimTokenIds.length; i++) {
            eligible[i] = !data.tokenFreeClaimUsed[_tokenId][_claimTokenIds[i]];
        }
        return eligible;
    }

    /**
     * @notice Free claim token when msg.sender owns the token in the external contract
     * @param _tokenId The id of the token to mint
     * @param _claimTokenIds The ids of the tokens to redeem
     */
    function freeClaim(
        uint16 _tokenId,
        uint256[] calldata _claimTokenIds
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint16 mintsPerFreeClaim = state.tokens[_tokenId].mintsPerFreeClaim;
        uint256 tokenIdsLength = _claimTokenIds.length;
        uint256 totalMints = tokenIdsLength * mintsPerFreeClaim;
        address freeClaimContractAddress = state
            .tokens[_tokenId]
            .freeClaimContractAddress;
        require(
            state.tokens[_tokenId].freeClaimContractAddress != address(0),
            "NOT_CONFIGURED"
        );
        require(mintsPerFreeClaim != 0, "NOT_CONFIGURED");
        require(state.tokens[_tokenId].freeClaimActive, "NOT_ACTIVE");
        uint16 newTotalSupply = state.data.totalSupply[_tokenId] +
            uint16(totalMints);
        require(
            newTotalSupply <= state.tokens[_tokenId].maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        if (state.cfg.heyMintFeeActive) {
            uint256 heymintFee = totalMints * heymintFeePerToken();
            require(msg.value == heymintFee, "PAYMENT_INCORRECT");
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        }
        IERC721 ExternalERC721FreeClaimContract = IERC721(
            freeClaimContractAddress
        );
        for (uint256 i = 0; i < tokenIdsLength; i++) {
            require(
                ExternalERC721FreeClaimContract.ownerOf(_claimTokenIds[i]) ==
                    msg.sender,
                "MUST_OWN_TOKEN"
            );
            require(
                !state.data.tokenFreeClaimUsed[_tokenId][_claimTokenIds[i]],
                "TOKEN_ALREADY_CLAIMED"
            );
            state.data.tokenFreeClaimUsed[_tokenId][_claimTokenIds[i]] = true;
        }

        state.data.totalSupply[_tokenId] = newTotalSupply;
        state.data.tokensMintedByAddress[msg.sender][_tokenId] += uint16(
            totalMints
        );
        _mint(msg.sender, _tokenId, totalMints, "");
    }
}