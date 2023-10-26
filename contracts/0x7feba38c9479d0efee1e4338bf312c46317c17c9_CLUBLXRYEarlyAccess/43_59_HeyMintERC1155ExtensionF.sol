// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, BaseConfig, AdvancedConfig, BurnToken} from "../libraries/HeyMintStorage.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {s} from "./ERC1155UDS.sol";

contract HeyMintERC1155ExtensionF is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    // ============ SOULBINDING ============

    /**
     * @notice Change the admin address used to transfer tokens if needed.
     * @param _adminAddress The new soulbound admin address
     */
    function setSoulboundAdminAddress(
        address _adminAddress
    ) external onlyOwner {
        AdvancedConfig storage advCfg = HeyMintStorage.state().advCfg;
        require(!advCfg.soulbindAdminTransfersPermanentlyDisabled);
        advCfg.soulboundAdminAddress = _adminAddress;
    }

    /**
     * @notice Disallow admin transfers of soulbound tokens permanently.
     */
    function disableSoulbindAdminTransfersPermanently() external onlyOwner {
        AdvancedConfig storage advCfg = HeyMintStorage.state().advCfg;
        advCfg.soulboundAdminAddress = address(0);
        advCfg.soulbindAdminTransfersPermanentlyDisabled = true;
    }

    /**
     * @notice Turn soulbinding on or off
     * @param _tokenId The token to modify soulbinding for
     * @param _soulbindingActive If true soulbinding is active
     */
    function setSoulbindingState(
        uint16 _tokenId,
        bool _soulbindingActive
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .tokens[_tokenId]
            .soulbindingActive = _soulbindingActive;
    }

    /**
     * @notice Allows an admin address to initiate token transfers if user wallets get hacked or lost
     * This function can only be used on soulbound tokens to prevent arbitrary transfers of normal tokens
     * @param _from The address to transfer from
     * @param _to The address to transfer to
     * @param _tokenId The token id to transfer
     * @param _amount The number of tokens to transfer
     */
    function soulboundAdminTransfer(
        address _from,
        address _to,
        uint16 _tokenId,
        uint256 _amount
    ) external {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            !state.advCfg.soulbindAdminTransfersPermanentlyDisabled,
            "NOT_ACTIVE"
        );
        require(state.tokens[_tokenId].soulbindingActive, "NOT_ACTIVE");
        address adminAddress = state.advCfg.soulboundAdminAddress == address(0)
            ? owner()
            : state.advCfg.soulboundAdminAddress;
        require(msg.sender == adminAddress, "NOT_ADMIN");
        state.data.soulboundAdminTransferInProgress = true;
        s().isApprovedForAll[_from][adminAddress] = true;
        safeTransferFrom(_from, _to, _tokenId, _amount, "");
        state.data.soulboundAdminTransferInProgress = false;
        s().isApprovedForAll[_from][adminAddress] = false;
    }

    // ============ REFUND ============

    /**
     * @notice Returns the refund price in wei. Refund price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     * @param _tokenId The token id
     */
    function refundPriceInWei(uint16 _tokenId) public view returns (uint256) {
        return
            uint256(HeyMintStorage.state().tokens[_tokenId].refundPrice) *
            10 ** 13;
    }

    /**
     * @notice Will return true if token holders can still return their tokens for a refund
     * @param _tokenId The token id
     */
    function refundGuaranteeActive(uint16 _tokenId) public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return block.timestamp < state.tokens[_tokenId].refundEndsAt;
    }

    /**
     * @notice Set the address where tokens are sent when refunded
     * @param _refundAddress The new refund address
     */
    function setRefundAddress(address _refundAddress) external onlyOwner {
        require(_refundAddress != address(0), "CANNOT_SEND_TO_ZERO_ADDRESS");
        HeyMintStorage.state().advCfg.refundAddress = _refundAddress;
    }

    /**
     * @notice Increase the period of time where token holders can still return their tokens for a refund
     * @param _tokenId The token id
     * @param _newRefundEndsAt The new timestamp when the refund period ends. Must be greater than the current timestamp
     */
    function increaseRefundEndsAt(
        uint16 _tokenId,
        uint32 _newRefundEndsAt
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _newRefundEndsAt > state.tokens[_tokenId].refundEndsAt,
            "MUST_INCREASE_DURATION"
        );
        HeyMintStorage.state().tokens[_tokenId].refundEndsAt = _newRefundEndsAt;
    }

    /**
     * @notice Refund token and return the refund price to the token owner.
     * @param _tokenId The id of the token to refund
     */
    function refund(uint16 _tokenId, uint256 _numTokens) external nonReentrant {
        require(refundGuaranteeActive(_tokenId), "REFUND_GUARANTEE_EXPIRED");
        require(
            balanceOf(msg.sender, _tokenId) >= _numTokens,
            "NOT_ENOUGH_TOKENS_OWNED"
        );
        HeyMintStorage.State storage state = HeyMintStorage.state();

        address addressToSendToken = state.advCfg.refundAddress != address(0)
            ? state.advCfg.refundAddress
            : owner();

        safeTransferFrom(
            msg.sender,
            addressToSendToken,
            _tokenId,
            _numTokens,
            ""
        );

        uint256 refundPrice = refundPriceInWei(_tokenId);
        uint256 totalRefundAmount = refundPrice * _numTokens;

        (bool success, ) = payable(msg.sender).call{value: totalRefundAmount}(
            ""
        );
        require(success, "TRANSFER_FAILED");
    }

    // ============ BURN TO MINT ============

    // Address where burnt tokens are sent.
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;

    /**
     * @notice Returns the burn payment in wei. Price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     * @param _tokenId The id of the token on the contract
     */
    function burnPaymentInWei(uint16 _tokenId) public view returns (uint256) {
        return
            uint256(HeyMintStorage.state().tokens[_tokenId].burnPayment) *
            10 ** 13;
    }

    /**
     * @notice To be updated by contract owner to allow burning to claim a token
     * @param _tokenId The id of the token on the contract
     * @param _burnClaimActive If true tokens can be burned in order to mint
     */
    function setBurnClaimState(
        uint16 _tokenId,
        bool _burnClaimActive
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        TokenConfig storage tokenCfg = state.tokens[_tokenId];
        if (_burnClaimActive) {
            require(state.burnTokens[_tokenId].length != 0, "NOT_CONFIGURED");
            require(tokenCfg.mintsPerBurn != 0, "NOT_CONFIGURED");
        }
        tokenCfg.burnClaimActive = _burnClaimActive;
    }

    /**
     * @notice Update the number of mints claimable per token burned
     * @param _tokenId The id of the token on the contract
     * @param _mintsPerBurn The new number of tokens that can be minted per burn transaction
     */
    function updateMintsPerBurn(
        uint16 _tokenId,
        uint8 _mintsPerBurn
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (state.tokens[_tokenId].burnClaimActive) {
            require(_mintsPerBurn > 0, "MUST_BE_AT_LEAST_1_IF_ACTIVE");
        }
        HeyMintStorage.state().tokens[_tokenId].mintsPerBurn = _mintsPerBurn;
    }

    /**
     * @notice Update the price required to be paid alongside a burn tx to mint (payment is per tx, not per token in the case of >1 mintsPerBurn)
     * @param _tokenId The id of the token on the contract
     * @param _burnPayment The new amount of payment required per burn transaction
     */
    function updatePaymentPerBurn(
        uint16 _tokenId,
        uint32 _burnPayment
    ) external onlyOwner {
        HeyMintStorage.state().tokens[_tokenId].burnPayment = _burnPayment;
    }

    /**
     * @notice Burn tokens from other contracts in order to mint tokens on this contract
     * @dev This contract must be approved by the caller to transfer the tokens being burned
     * @param _tokenId The id of the token to mint
     * @param _contracts The contracts of the tokens to burn in the same order as the array burnTokens
     * @param _tokenIdsToBurn Nested array of token ids to burn for 721 and amounts to burn for 1155 corresponding to _contracts
     * @param _tokensToMint The number of tokens to mint
     */
    function burnToMint(
        uint16 _tokenId,
        address[] calldata _contracts,
        uint256[][] calldata _tokenIdsToBurn,
        uint16 _tokensToMint
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint256 burnTokensLen = state.burnTokens[_tokenId].length;
        require(burnTokensLen > 0, "NOT_CONFIGURED");
        uint16 mintsPerBurn = state.tokens[_tokenId].mintsPerBurn;
        require(mintsPerBurn != 0, "NOT_CONFIGURED");
        require(state.tokens[_tokenId].burnClaimActive, "NOT_ACTIVE");
        require(
            _contracts.length == _tokenIdsToBurn.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        require(_contracts.length == burnTokensLen, "ARRAY_LENGTHS_MUST_MATCH");
        //uint16 newTotalSupply = state.data.totalSupply[_tokenId] + _tokensToMint;
        require(
            state.data.totalSupply[_tokenId] + _tokensToMint <=
                state.tokens[_tokenId].maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        uint256 burnPayment = burnPaymentInWei(_tokenId);
        uint256 burnPaymentTotal = burnPayment * (_tokensToMint / mintsPerBurn);
        uint256 heymintFee = _tokensToMint * heymintFeePerToken();
        require(
            msg.value == burnPaymentTotal + heymintFee,
            "INVALID_PRICE_PAID"
        );
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        }
        for (uint256 i = 0; i < burnTokensLen; i++) {
            BurnToken memory burnToken = state.burnTokens[_tokenId][i];
            require(
                burnToken.contractAddress == _contracts[i],
                "INCORRECT_CONTRACT"
            );
            if (burnToken.tokenType == 1) {
                uint256 _tokenIdsToBurnLength = _tokenIdsToBurn[i].length;
                require(
                    (_tokenIdsToBurnLength / burnToken.tokensPerBurn) *
                        mintsPerBurn ==
                        _tokensToMint,
                    "INCORRECT_NO_OF_TOKENS_TO_BURN"
                );
                for (uint256 j = 0; j < _tokenIdsToBurnLength; j++) {
                    IERC721 burnContract = IERC721(_contracts[i]);
                    uint256 tokenId = _tokenIdsToBurn[i][j];
                    require(
                        burnContract.ownerOf(tokenId) == msg.sender,
                        "MUST_OWN_TOKEN"
                    );
                    burnContract.transferFrom(msg.sender, burnAddress, tokenId);
                }
            } else if (burnToken.tokenType == 2) {
                uint256 amountToBurn = _tokenIdsToBurn[i][0];
                require(
                    (amountToBurn / burnToken.tokensPerBurn) * mintsPerBurn ==
                        _tokensToMint,
                    "INCORRECT_NO_OF_TOKENS_TO_BURN"
                );
                IERC1155 burnContract = IERC1155(_contracts[i]);
                require(
                    burnContract.balanceOf(msg.sender, burnToken.tokenId) >=
                        amountToBurn,
                    "MUST_OWN_TOKEN"
                );
                burnContract.safeTransferFrom(
                    msg.sender,
                    burnAddress,
                    burnToken.tokenId,
                    amountToBurn,
                    ""
                );
            }
        }

        state.data.totalSupply[_tokenId] += _tokensToMint;
        state.data.tokensMintedByAddress[msg.sender][_tokenId] += uint16(
            _tokensToMint
        );
        _mint(msg.sender, _tokenId, _tokensToMint, "");
    }
}