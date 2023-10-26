// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {HeyMintStorage, TokenConfig, AdvancedConfig} from "../libraries/HeyMintStorage.sol";

contract HeyMintERC1155ExtensionB is HeyMintERC1155Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    /**
     * @notice Returns how many of a given token have been minted
     */
    function totalSupply(uint16 _tokenId) external view returns (uint16) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return state.data.totalSupply[_tokenId];
    }

    // ============ PUBLIC SALE ============

    /**
     * @notice To be updated by contract owner to allow public sale minting for a given token
     */
    function setTokenPublicSaleState(
        uint16 _tokenId,
        bool _saleActiveState
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].publicSaleActive = _saleActiveState;
    }

    /**
     * @notice Update the public mint price for a given token
     */
    function setTokenPublicPrice(
        uint16 _tokenId,
        uint32 _publicPrice
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].publicPrice = _publicPrice;
    }

    function setTokenMaxSupply(
        uint16 _tokenId,
        uint16 _maxSupply
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _maxSupply >= state.data.totalSupply[_tokenId],
            "MAX_SUPPLY_LESS_THAN_TOTAL_SUPPLY"
        );
        state.tokens[_tokenId].maxSupply = _maxSupply;
    }

    /**
     * @notice Set the maximum public mints allowed per a given address for a given token
     */
    function setTokenPublicMintsAllowedPerAddress(
        uint16 _tokenId,
        uint8 _mintsAllowed
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].publicMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Update the start time for public mint for a given token
     */
    function setTokenPublicSaleStartTime(
        uint16 _tokenId,
        uint32 _publicSaleStartTime
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(_publicSaleStartTime > block.timestamp, "TIME_IN_PAST");
        state.tokens[_tokenId].publicSaleStartTime = _publicSaleStartTime;
    }

    /**
     * @notice Update the end time for public mint for a given token
     */
    function setTokenPublicSaleEndTime(
        uint16 _tokenId,
        uint32 _publicSaleEndTime
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(_publicSaleEndTime > block.timestamp, "TIME_IN_PAST");
        require(
            state.tokens[_tokenId].publicSaleStartTime < _publicSaleEndTime,
            "END_TIME_BEFORE_START_TIME"
        );
        state.tokens[_tokenId].publicSaleEndTime = _publicSaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic public sale times for a given token
     */
    function setTokenUsePublicSaleTimes(
        uint16 _tokenId,
        bool _usePublicSaleTimes
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.tokens[_tokenId].usePublicSaleTimes = _usePublicSaleTimes;
    }

    function mintToken(
        uint16 _tokenId,
        uint16 _numTokens
    ) external payable nonReentrant notPaused {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        uint16 totalSupply = state.data.totalSupply[_tokenId];
        uint256 heymintFee = _numTokens * heymintFeePerToken();
        uint256 publicPrice = publicPriceInWei(_tokenId);
        require(
            state.tokens[_tokenId].publicSaleActive,
            "PUBLIC_SALE_IS_NOT_ACTIVE"
        );
        require(
            tokenPublicSaleTimeIsActive(_tokenId),
            "PUBLIC_SALE_TIME_IS_NOT_ACTIVE"
        );
        uint16 newTokensMintedByAddress = state.data.tokensMintedByAddress[
            msg.sender
        ][_tokenId] + _numTokens;
        uint16 publicMintsAllowedPerAddress = state
            .tokens[_tokenId]
            .publicMintsAllowedPerAddress;
        require(
            publicMintsAllowedPerAddress == 0 ||
                newTokensMintedByAddress <= publicMintsAllowedPerAddress,
            "MAX_MINTS_FOR_ADDRESS_EXCEEDED"
        );
        uint16 newTotalSupply = totalSupply + _numTokens;
        uint16 _maxSupply = state.tokens[_tokenId].maxSupply;
        require(
            _maxSupply == 0 ||
                newTotalSupply <= state.tokens[_tokenId].maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        require(
            msg.value == publicPrice * _numTokens + heymintFee,
            "PAYMENT_INCORRECT"
        );
        require(
            !state.data.tokenMintingPermanentlyDisabled[_tokenId],
            "MINTING_PERMANENTLY_DISABLED"
        );
        if (heymintFee > 0) {
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "HeyMint fee transfer failed");
        }
        state.data.totalSupply[_tokenId] = newTotalSupply;
        state.data.tokensMintedByAddress[msg.sender][
            _tokenId
        ] = newTokensMintedByAddress;

        _mint(msg.sender, _tokenId, _numTokens, "");

        if (_maxSupply != 0 && newTotalSupply == _maxSupply) {
            state.tokens[_tokenId].publicSaleActive = false;
        }
    }

    /**
     * @notice Returns the number of tokens minted by a specific address
     */
    function tokensMintedByAddress(
        address _address,
        uint16 _tokenId
    ) external view returns (uint16) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return state.data.tokensMintedByAddress[_address][_tokenId];
    }

    // ============ HEYMINT FEE ============

    // Address of the HeyMint admin
    address public constant heymintAdminAddress =
        0x52EA5F96f004d174470901Ba3F1984D349f0D3eF;

    /**
     * @notice Allows the heymintAdminAddress to set the heymint fee per token
     * @param _heymintFeePerToken The new fee per token in wei
     */
    function setHeymintFeePerToken(uint256 _heymintFeePerToken) external {
        require(msg.sender == heymintAdminAddress, "MUST_BE_HEYMINT_ADMIN");
        HeyMintStorage.state().data.heymintFeePerToken = _heymintFeePerToken;
    }

    // ============ PAYOUT ============

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() external nonReentrant onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            !anyTokenRefundGuaranteeActive(),
            "REFUND_GUARANTEE_STILL_ACTIVE"
        );
        uint256 balance = address(this).balance;
        if (state.advCfg.payoutAddresses.length == 0) {
            (bool success, ) = payable(owner()).call{value: balance}("");
            require(success, "TRANSFER_FAILED");
        } else {
            for (uint256 i = 0; i < state.advCfg.payoutAddresses.length; i++) {
                uint256 amount = (balance * state.advCfg.payoutBasisPoints[i]) /
                    10000;
                (bool success, ) = HeyMintStorage
                    .state()
                    .advCfg
                    .payoutAddresses[i]
                    .call{value: amount}("");
                require(success, "TRANSFER_FAILED");
            }
        }
    }

    /**
     * @notice Freeze all payout addresses & basis points so they can never be changed again
     */
    function freezePayoutAddresses() external onlyOwner {
        HeyMintStorage.state().advCfg.payoutAddressesFrozen = true;
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
     * Will return true if any token refund is still active
     */
    function anyTokenRefundGuaranteeActive() public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        for (uint256 i = 0; i < state.data.tokenIds.length; i++) {
            if (refundGuaranteeActive(state.data.tokenIds[i])) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Update payout addresses and basis points for each addresses' respective share of contract funds
     * @param _payoutAddresses The new payout addresses to use
     * @param _payoutBasisPoints The amount to pay out to each address in _payoutAddresses (in basis points)
     */
    function updatePayoutAddressesAndBasisPoints(
        address[] calldata _payoutAddresses,
        uint16[] calldata _payoutBasisPoints
    ) external onlyOwner {
        AdvancedConfig storage advCfg = HeyMintStorage.state().advCfg;
        require(!advCfg.payoutAddressesFrozen, "PAYOUT_ADDRESSES_FROZEN");
        uint256 payoutBasisPointsLength = _payoutBasisPoints.length;
        require(
            _payoutAddresses.length == payoutBasisPointsLength,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < payoutBasisPointsLength; i++) {
            totalBasisPoints += _payoutBasisPoints[i];
        }
        require(totalBasisPoints == 10000, "BASIS_POINTS_MUST_EQUAL_10000");
        advCfg.payoutAddresses = _payoutAddresses;
        advCfg.payoutBasisPoints = _payoutBasisPoints;
    }
}