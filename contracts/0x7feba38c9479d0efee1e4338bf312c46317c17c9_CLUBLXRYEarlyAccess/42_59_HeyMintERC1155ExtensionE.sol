// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, BaseConfig, AdvancedConfig} from "../libraries/HeyMintStorage.sol";

contract HeyMintERC1155ExtensionE is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    // ============ FREEZING ============
    /**
     * @notice Freeze metadata for a specific token id so it can never be changed again
     */
    function freezeTokenMetadata(uint16 _tokenId) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (
            !state.data.tokenMetadataFrozen[_tokenId] &&
            bytes(state.tokens[_tokenId].tokenUri).length == 0
        ) {
            state.tokens[_tokenId].tokenUri = state.cfg.uriBase;
        }
        state.data.tokenMetadataFrozen[_tokenId] = true;
    }

    /**
     * @notice Freeze all metadata so it can never be changed again
     */
    function freezeAllMetadata() external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.data.allMetadataFrozen = true;
    }

    // ============ GIFT ============

    /**
     * @notice Allow owner to send tokens without cost to multiple addresses
     */
    function giftTokens(
        uint16 _tokenId,
        address[] calldata _receivers,
        uint256[] calldata _mintNumber
    ) external payable onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            !state.data.tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        require(
            _receivers.length == _mintNumber.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalMints = 0;
        for (uint256 i = 0; i < _mintNumber.length; i++) {
            totalMints += _mintNumber[i];
        }
        // require either no tokenMaxSupply set or tokenMaxSupply not maxed out
        uint16 newtotalSupply = state.data.totalSupply[_tokenId] +
            uint16(totalMints);
        uint16 maxSupply = state.tokens[_tokenId].maxSupply;
        require(
            maxSupply == 0 || newtotalSupply <= maxSupply,
            "MINT_TOO_LARGE"
        );
        uint256 heymintFee = (totalMints * heymintFeePerToken()) / 10;
        require(msg.value == heymintFee, "PAYMENT_INCORRECT");
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "HeyMint fee transfer failed");
        }
        state.data.totalSupply[_tokenId] = newtotalSupply;
        for (uint256 i = 0; i < _receivers.length; i++) {
            _mint(_receivers[i], _tokenId, _mintNumber[i], "");
        }
    }

    // ============ CREDIT CARD PAYMENT ============

    /**
     * @notice Returns an array of default addresses authorized to call creditCardMint
     */
    function getDefaultCreditCardMintAddresses()
        public
        pure
        returns (address[5] memory)
    {
        return [
            0xf3DB642663231887E2Ff3501da6E3247D8634A6D,
            0x5e01a33C75931aD0A91A12Ee016Be8D61b24ADEB,
            0x9E733848061e4966c4a920d5b99a123459670aEe,
            0x7754B94345BCE520f8dd4F6a5642567603e90E10,
            0xdAb1a1854214684acE522439684a145E62505233
        ];
    }

    /**
     * @notice Set addresses authorized to call creditCardMint
     * @param _creditCardMintAddresses The custom addresses to authorize
     */
    function setCreditCardMintAddresses(
        address[] memory _creditCardMintAddresses
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .advCfg
            .creditCardMintAddresses = _creditCardMintAddresses;
    }

    function creditCardMint(
        uint16 _tokenId,
        uint16 _numTokens,
        address _to
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        address[5]
            memory defaultAddresses = getDefaultCreditCardMintAddresses();
        bool authorized = false;
        for (uint256 i = 0; i < defaultAddresses.length; i++) {
            if (msg.sender == defaultAddresses[i]) {
                authorized = true;
                break;
            }
        }
        if (!authorized) {
            for (
                uint256 i = 0;
                i < state.advCfg.creditCardMintAddresses.length;
                i++
            ) {
                if (msg.sender == state.advCfg.creditCardMintAddresses[i]) {
                    authorized = true;
                    break;
                }
            }
        }
        require(authorized, "NOT_AUTHORIZED_ADDRESS");
        require(state.tokens[_tokenId].publicSaleActive, "NOT_ACTIVE");
        require(tokenPublicSaleTimeIsActive(_tokenId), "NOT_ACTIVE");
        uint16 publicMintsAllowedPerAddress = state
            .tokens[_tokenId]
            .publicMintsAllowedPerAddress;
        uint16 newTokensMintedByAddress = state.data.tokensMintedByAddress[_to][
            _tokenId
        ] + _numTokens;
        require(
            publicMintsAllowedPerAddress == 0 ||
                newTokensMintedByAddress <= publicMintsAllowedPerAddress,
            "MAX_MINTS_EXCEEDED"
        );
        uint16 newTotalSupply = state.data.totalSupply[_tokenId] + _numTokens;
        uint16 maxSupply = state.tokens[_tokenId].maxSupply;
        require(newTotalSupply <= maxSupply, "MAX_SUPPLY_EXCEEDED");
        uint256 publicPrice = publicPriceInWei(_tokenId);
        uint256 heymintFee = _numTokens * heymintFeePerToken();
        require(
            msg.value == publicPrice * _numTokens + heymintFee,
            "INVALID_PRICE_PAID"
        );
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        }

        state.data.totalSupply[_tokenId] = newTotalSupply;
        state.data.tokensMintedByAddress[msg.sender][
            _tokenId
        ] = newTokensMintedByAddress;
        _mint(_to, _tokenId, _numTokens, "");

        if (maxSupply != 0 && newTotalSupply == maxSupply) {
            state.tokens[_tokenId].publicSaleActive = false;
        }
    }
}