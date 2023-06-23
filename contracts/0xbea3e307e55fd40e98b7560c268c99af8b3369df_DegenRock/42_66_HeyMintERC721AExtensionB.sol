// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC721AUpgradeable} from "./HeyMintERC721AUpgradeable.sol";
import {HeyMintStorage, BaseConfig, BurnToken} from "../libraries/HeyMintStorage.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract HeyMintERC721AExtensionB is HeyMintERC721AUpgradeable {
    using HeyMintStorage for HeyMintStorage.State;
    using ECDSAUpgradeable for bytes32;

    // Address where burnt tokens are sent.
    address public constant burnAddress =
        0x000000000000000000000000000000000000dEaD;

    // ============ PRESALE ============

    /**
     * @notice Returns the presale price in wei. Presale price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     */
    function presalePriceInWei() public view returns (uint256) {
        return uint256(HeyMintStorage.state().cfg.presalePrice) * 10 ** 13;
    }

    /**
     * @notice To be updated by contract owner to allow presale minting
     * @param _saleActiveState The new presale activ
     .e state
     */
    function setPresaleState(bool _saleActiveState) external onlyOwner {
        HeyMintStorage.state().cfg.presaleActive = _saleActiveState;
    }

    /**
     * @notice Update the presale mint price
     * @param _presalePrice The new presale mint price to use
     */
    function setPresalePrice(uint32 _presalePrice) external onlyOwner {
        HeyMintStorage.state().cfg.presalePrice = _presalePrice;
    }

    /**
     * @notice Reduce the max supply of tokens available to mint in the presale
     * @param _newPresaleMaxSupply The new maximum supply of presale tokens available to mint
     */
    function reducePresaleMaxSupply(
        uint16 _newPresaleMaxSupply
    ) external onlyOwner {
        BaseConfig storage cfg = HeyMintStorage.state().cfg;
        require(
            _newPresaleMaxSupply < cfg.presaleMaxSupply,
            "NEW_MAX_SUPPLY_TOO_HIGH"
        );
        cfg.presaleMaxSupply = _newPresaleMaxSupply;
    }

    /**
     * @notice Set the maximum mints allowed per a given address in the presale
     * @param _mintsAllowed The new maximum mints allowed per address in the presale
     */
    function setPresaleMintsAllowedPerAddress(
        uint8 _mintsAllowed
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .cfg
            .presaleMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Set the maximum mints allowed per a given transaction in the presale
     * @param _mintsAllowed The new maximum mints allowed per transaction in the presale
     */
    function setPresaleMintsAllowedPerTransaction(
        uint8 _mintsAllowed
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .cfg
            .presaleMintsAllowedPerTransaction = _mintsAllowed;
    }

    /**
     * @notice Set the signer address used to verify presale minting
     * @param _presaleSignerAddress The new signer address to use
     */
    function setPresaleSignerAddress(
        address _presaleSignerAddress
    ) external onlyOwner {
        HeyMintStorage.state().cfg.presaleSignerAddress = _presaleSignerAddress;
    }

    /**
     * @notice Update the start time for presale mint
     */
    function setPresaleStartTime(uint32 _presaleStartTime) external onlyOwner {
        HeyMintStorage.state().cfg.presaleStartTime = _presaleStartTime;
    }

    /**
     * @notice Update the end time for presale mint
     */
    function setPresaleEndTime(uint32 _presaleEndTime) external onlyOwner {
        require(_presaleEndTime > block.timestamp, "TIME_IN_PAST");
        HeyMintStorage.state().cfg.presaleEndTime = _presaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic presale times
     */
    function setUsePresaleTimes(bool _usePresaleTimes) external onlyOwner {
        HeyMintStorage.state().cfg.usePresaleTimes = _usePresaleTimes;
    }

    /**
     * @notice Returns if presale times are active. If required config settings are not set, returns true.
     */
    function presaleTimeIsActive() public view returns (bool) {
        BaseConfig storage cfg = HeyMintStorage.state().cfg;
        if (
            cfg.usePresaleTimes == false ||
            cfg.presaleStartTime == 0 ||
            cfg.presaleEndTime == 0
        ) {
            return true;
        }
        return
            block.timestamp >= cfg.presaleStartTime &&
            block.timestamp <= cfg.presaleEndTime;
    }

    /**
     * @notice Verify that a signed message is validly signed by the presaleSignerAddress
     * @param _messageHash The hash of the message to verify
     * @param _signature The signature of the messageHash to verify
     */
    function verifySignerAddress(
        bytes32 _messageHash,
        bytes calldata _signature
    ) private view returns (bool) {
        return
            HeyMintStorage.state().cfg.presaleSignerAddress ==
            _messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @notice Allow for allowlist minting of tokens
     * @param _messageHash The hash of the message containing msg.sender & _maximumAllowedMints to verify
     * @param _signature The signature of the messageHash to verify
     * @param _numTokens The number of tokens to mint
     * @param _maximumAllowedMints The maximum number of tokens that can be minted by the caller
     */
    function presaleMint(
        bytes32 _messageHash,
        bytes calldata _signature,
        uint256 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable nonReentrant {
        BaseConfig storage cfg = HeyMintStorage.state().cfg;
        require(cfg.presaleActive, "NOT_ACTIVE");
        require(presaleTimeIsActive(), "NOT_ACTIVE");
        require(
            cfg.presaleMintsAllowedPerAddress == 0 ||
                _numberMinted(msg.sender) + _numTokens <=
                cfg.presaleMintsAllowedPerAddress,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            cfg.presaleMintsAllowedPerTransaction == 0 ||
                _numTokens <= cfg.presaleMintsAllowedPerTransaction,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + _numTokens <= _maximumAllowedMints,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            cfg.presaleMaxSupply == 0 ||
                totalSupply() + _numTokens <= cfg.presaleMaxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            totalSupply() + _numTokens <= cfg.maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        uint256 presalePrice = presalePriceInWei();
        if (cfg.heyMintFeeActive) {
            uint256 heymintFee = _numTokens * heymintFeePerToken();
            require(
                msg.value == presalePrice * _numTokens + heymintFee,
                "INVALID_PRICE_PAID"
            );
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        } else {
            require(
                msg.value == presalePrice * _numTokens,
                "INVALID_PRICE_PAID"
            );
        }
        require(
            keccak256(abi.encode(msg.sender, _maximumAllowedMints)) ==
                _messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifySignerAddress(_messageHash, _signature),
            "INVALID_SIGNATURE"
        );

        if (cfg.fundingEndsAt > 0) {
            uint256 firstTokenIdToMint = _nextTokenId();
            for (uint256 i = 0; i < _numTokens; i++) {
                HeyMintStorage.state().data.pricePaid[
                    firstTokenIdToMint + i
                ] = presalePrice;
            }
        }

        _safeMint(msg.sender, _numTokens);
    }

    // ============ BURN TO MINT ============

    /**
     * @notice Returns the burn payment in wei. Price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     */
    function burnPaymentInWei() public view returns (uint256) {
        return uint256(HeyMintStorage.state().advCfg.burnPayment) * 10 ** 13;
    }

    /**
     * @notice To be updated by contract owner to allow burning to claim a token
     * @param _burnClaimActive If true tokens can be burned in order to mint
     */
    function setBurnClaimState(bool _burnClaimActive) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (_burnClaimActive) {
            require(state.burnTokens.length != 0, "NOT_CONFIGURED");
            require(state.advCfg.mintsPerBurn != 0, "NOT_CONFIGURED");
        }
        state.advCfg.burnClaimActive = _burnClaimActive;
    }

    /**
     * @notice Set the contract address of the NFT to be burned in order to mint
     * @param _burnTokens An array of all tokens required for burning
     */
    function updateBurnTokens(
        BurnToken[] calldata _burnTokens
    ) external onlyOwner {
        BurnToken[] storage burnTokens = HeyMintStorage.state().burnTokens;
        uint256 oldBurnTokensLength = burnTokens.length;
        uint256 newBurnTokensLength = _burnTokens.length;

        // Update the existing BurnTokens and push any new BurnTokens
        for (uint256 i = 0; i < newBurnTokensLength; i++) {
            if (i < oldBurnTokensLength) {
                burnTokens[i] = _burnTokens[i];
            } else {
                burnTokens.push(_burnTokens[i]);
            }
        }

        // Pop any extra BurnTokens if the new array is shorter
        for (uint256 i = oldBurnTokensLength; i > newBurnTokensLength; i--) {
            burnTokens.pop();
        }
    }

    /**
     * @notice Update the number of free mints claimable per token burned
     * @param _mintsPerBurn The new number of tokens that can be minted per burn transaction
     */
    function updateMintsPerBurn(uint8 _mintsPerBurn) external onlyOwner {
        HeyMintStorage.state().advCfg.mintsPerBurn = _mintsPerBurn;
    }

    /**
     * @notice Update the price required to be paid alongside a burn tx to mint (payment is per tx, not per token in the case of >1 mintsPerBurn)
     * @param _burnPayment The new amount of payment required per burn transaction
     */
    function updatePaymentPerBurn(uint32 _burnPayment) external onlyOwner {
        HeyMintStorage.state().advCfg.burnPayment = _burnPayment;
    }

    /**
     * @notice If true, real token ids are used for metadata. If false, burn token ids are used for metadata if they exist.
     * @param _useBurnTokenIdForMetadata If true, burn token ids are used for metadata if they exist. If false, real token ids are used.
     */
    function setUseBurnTokenIdForMetadata(
        bool _useBurnTokenIdForMetadata
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .advCfg
            .useBurnTokenIdForMetadata = _useBurnTokenIdForMetadata;
    }

    /**
     * @notice Burn tokens from other contracts in order to mint tokens on this contract
     * @dev This contract must be approved by the caller to transfer the tokens being burned
     * @param _contracts The contracts of the tokens to burn in the same order as the array burnTokens
     * @param _tokenIds Nested array of token ids to burn for 721 and amounts to burn for 1155 corresponding to _contracts
     * @param _tokensToMint The number of tokens to mint
     */
    function burnToMint(
        address[] calldata _contracts,
        uint256[][] calldata _tokenIds,
        uint256 _tokensToMint
    ) external payable nonReentrant {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint256 contractsLength = _contracts.length;
        uint256 burnTokenLength = state.burnTokens.length;
        require(burnTokenLength > 0, "NOT_CONFIGURED");
        require(state.advCfg.mintsPerBurn != 0, "NOT_CONFIGURED");
        require(state.advCfg.burnClaimActive, "NOT_ACTIVE");
        require(
            contractsLength == _tokenIds.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        require(contractsLength == burnTokenLength, "ARRAY_LENGTHS_MUST_MATCH");
        require(
            totalSupply() + _tokensToMint <= state.cfg.maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        uint256 burnPayment = burnPaymentInWei();
        uint256 burnPaymentTotal = burnPayment *
            (_tokensToMint / state.advCfg.mintsPerBurn);
        if (state.cfg.heyMintFeeActive) {
            uint256 heymintFee = _tokensToMint * heymintFeePerToken();
            require(
                msg.value == burnPaymentTotal + heymintFee,
                "INVALID_PRICE_PAID"
            );
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        } else {
            require(msg.value == burnPaymentTotal, "INVALID_PRICE_PAID");
        }
        for (uint256 i = 0; i < burnTokenLength; i++) {
            BurnToken memory burnToken = state.burnTokens[i];
            require(
                burnToken.contractAddress == _contracts[i],
                "INCORRECT_CONTRACT"
            );
            if (burnToken.tokenType == 1) {
                uint256 _tokenIdsLength = _tokenIds[i].length;
                require(
                    (_tokenIdsLength / burnToken.tokensPerBurn) *
                        state.advCfg.mintsPerBurn ==
                        _tokensToMint,
                    "INCORRECT_NO_OF_TOKENS_TO_BURN"
                );
                for (uint256 j = 0; j < _tokenIdsLength; j++) {
                    IERC721 burnContract = IERC721(_contracts[i]);
                    uint256 tokenId = _tokenIds[i][j];
                    require(
                        burnContract.ownerOf(tokenId) == msg.sender,
                        "MUST_OWN_TOKEN"
                    );
                    burnContract.transferFrom(msg.sender, burnAddress, tokenId);
                }
            } else if (burnToken.tokenType == 2) {
                uint256 amountToBurn = _tokenIds[i][0];
                require(
                    (amountToBurn / burnToken.tokensPerBurn) *
                        state.advCfg.mintsPerBurn ==
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
        if (state.advCfg.useBurnTokenIdForMetadata) {
            require(
                _tokenIds[0].length == _tokensToMint,
                "BURN_TOKENS_MUST_MATCH_MINT_NO"
            );
            uint256 firstNewTokenId = _nextTokenId();
            for (uint256 i = 0; i < _tokensToMint; i++) {
                state.data.tokenIdToBurnTokenId[
                    firstNewTokenId + i
                ] = _tokenIds[0][i];
            }
        }
        _safeMint(msg.sender, _tokensToMint);
    }
}