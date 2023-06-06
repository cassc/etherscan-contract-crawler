// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC721AUpgradeable} from "./HeyMintERC721AUpgradeable.sol";
import {BaseConfig, AdvancedConfig, BurnToken, HeyMintStorage} from "../libraries/HeyMintStorage.sol";

contract HeyMintERC721AExtensionA is HeyMintERC721AUpgradeable {
    using HeyMintStorage for HeyMintStorage.State;

    event Stake(uint256 indexed tokenId);
    event Unstake(uint256 indexed tokenId);
    event Loan(address from, address to, uint256 tokenId);
    event LoanRetrieved(address from, address to, uint256 tokenId);

    // ============ BASE FUNCTIONALITY ============

    /**
     * @notice Returns all storage variables for the contract
     */
    function getSettings()
        external
        view
        returns (
            BaseConfig memory,
            AdvancedConfig memory,
            BurnToken[] memory,
            bool,
            bool,
            bool,
            uint256
        )
    {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return (
            state.cfg,
            state.advCfg,
            state.burnTokens,
            state.data.advancedConfigInitialized,
            state.data.fundingTargetReached,
            state.data.fundingSuccessDetermined,
            state.data.currentLoanTotal
        );
    }

    /**
     * @notice Updates the address configuration for the contract
     */
    function updateBaseConfig(
        BaseConfig memory _baseConfig
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _baseConfig.maxSupply <= state.cfg.maxSupply,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
        require(
            _baseConfig.presaleMaxSupply <= state.cfg.presaleMaxSupply,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
        require(
            _baseConfig.fundingEndsAt == state.cfg.fundingEndsAt,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
        require(
            _baseConfig.fundingTarget == state.cfg.fundingTarget,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
        require(
            _baseConfig.heyMintFeeActive == state.cfg.heyMintFeeActive,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
        if (state.advCfg.metadataFrozen) {
            require(
                keccak256(abi.encode(_baseConfig.uriBase)) ==
                    keccak256(abi.encode(state.cfg.uriBase)),
                "CANNOT_UPDATE_CONSTANT_VARIABLE"
            );
        }
        state.cfg = _baseConfig;
    }

    /**
     * @notice Updates the advanced configuration for the contract
     */
    function updateAdvancedConfig(
        AdvancedConfig memory _advancedConfig
    ) external onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (state.advCfg.metadataFrozen) {
            require(
                _advancedConfig.metadataFrozen,
                "CANNOT_UPDATE_CONSTANT_VARIABLE"
            );
        }
        if (state.advCfg.soulbindAdminTransfersPermanentlyDisabled) {
            require(
                _advancedConfig.soulbindAdminTransfersPermanentlyDisabled,
                "CANNOT_UPDATE_CONSTANT_VARIABLE"
            );
        }
        if (state.advCfg.refundEndsAt > 0) {
            require(
                _advancedConfig.refundPrice == state.advCfg.refundPrice,
                "CANNOT_UPDATE_CONSTANT_VARIABLE"
            );
            require(
                _advancedConfig.refundEndsAt >= state.advCfg.refundEndsAt,
                "CANNOT_UPDATE_CONSTANT_VARIABLE"
            );
        } else if (
            _advancedConfig.refundEndsAt > 0 || _advancedConfig.refundPrice > 0
        ) {
            require(
                _advancedConfig.refundPrice > 0,
                "REFUND_PRICE_MUST_BE_SET"
            );
            require(
                _advancedConfig.refundEndsAt > 0,
                "REFUND_DURATION_MUST_BE_SET"
            );
        }
        if (!state.data.advancedConfigInitialized) {
            state.data.advancedConfigInitialized = true;
        }
        uint256 payoutAddressesLength = _advancedConfig.payoutAddresses.length;
        uint256 payoutBasisPointsLength = _advancedConfig
            .payoutBasisPoints
            .length;
        if (state.advCfg.payoutAddressesFrozen) {
            require(
                _advancedConfig.payoutAddressesFrozen,
                "CANNOT_UPDATE_CONSTANT_VARIABLE"
            );
            require(
                payoutAddressesLength == state.advCfg.payoutAddresses.length,
                "CANNOT_UPDATE_CONSTANT_VARIABLE"
            );
            require(
                payoutBasisPointsLength ==
                    state.advCfg.payoutBasisPoints.length,
                "CANNOT_UPDATE_CONSTANT_VARIABLE"
            );
            for (uint256 i = 0; i < payoutAddressesLength; i++) {
                require(
                    _advancedConfig.payoutAddresses[i] ==
                        state.advCfg.payoutAddresses[i],
                    "CANNOT_UPDATE_CONSTANT_VARIABLE"
                );
                require(
                    _advancedConfig.payoutBasisPoints[i] ==
                        state.advCfg.payoutBasisPoints[i],
                    "CANNOT_UPDATE_CONSTANT_VARIABLE"
                );
            }
        } else if (payoutAddressesLength > 0) {
            require(
                payoutAddressesLength == payoutBasisPointsLength,
                "ARRAY_LENGTHS_MUST_MATCH"
            );
            uint256 totalBasisPoints = 0;
            for (uint256 i = 0; i < payoutBasisPointsLength; i++) {
                totalBasisPoints += _advancedConfig.payoutBasisPoints[i];
            }
            require(totalBasisPoints == 10000, "BASIS_POINTS_MUST_EQUAL_10000");
        }
        state.advCfg = _advancedConfig;
    }

    /**
     * @notice Reduce the max supply of tokens
     * @param _newMaxSupply The new maximum supply of tokens available to mint
     */
    function reduceMaxSupply(uint16 _newMaxSupply) external onlyOwner {
        BaseConfig storage cfg = HeyMintStorage.state().cfg;
        require(_newMaxSupply < cfg.maxSupply, "NEW_MAX_SUPPLY_TOO_HIGH");
        require(
            _newMaxSupply >= totalSupply(),
            "SUPPLY_LOWER_THAN_MINTED_TOKENS"
        );
        cfg.maxSupply = _newMaxSupply;
    }

    // ============ PAYOUT ============

    /**
     * @notice Freeze all payout addresses so they can never be changed again
     */
    function freezePayoutAddresses() external onlyOwner {
        HeyMintStorage.state().advCfg.payoutAddressesFrozen = true;
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
        uint256 payoutBasisPointsLength = _payoutBasisPoints.length;
        require(
            !advCfg.payoutAddressesFrozen,
            "CANNOT_UPDATE_CONSTANT_VARIABLE"
        );
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

    // ============ ERC-2981 ROYALTY ============

    /**
     * @notice Updates royalty basis points
     * @param _royaltyBps The new royalty basis points to use
     */
    function setRoyaltyBasisPoints(uint16 _royaltyBps) external onlyOwner {
        HeyMintStorage.state().cfg.royaltyBps = _royaltyBps;
    }

    /**
     * @notice Updates royalty payout address
     * @param _royaltyPayoutAddress The new royalty payout address to use
     */
    function setRoyaltyPayoutAddress(
        address _royaltyPayoutAddress
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .advCfg
            .royaltyPayoutAddress = _royaltyPayoutAddress;
    }

    // ============ GIFT ============

    /**
     * @notice Allow owner to send 'mintNumber' tokens without cost to multiple addresses
     * @param _receivers The addresses to send the tokens to
     * @param _mintNumber The number of tokens to send to each address
     */
    function gift(
        address[] calldata _receivers,
        uint256[] calldata _mintNumber
    ) external payable onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        require(
            _receivers.length == _mintNumber.length,
            "ARRAY_LENGTHS_MUST_MATCH"
        );
        uint256 totalMints = 0;
        for (uint256 i = 0; i < _mintNumber.length; i++) {
            totalMints += _mintNumber[i];
        }
        require(
            totalSupply() + totalMints <= state.cfg.maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        if (state.cfg.heyMintFeeActive) {
            uint256 heymintFee = (totalMints * heymintFeePerToken()) / 10;
            require(msg.value == heymintFee, "PAYMENT_INCORRECT");
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        }
        for (uint256 i = 0; i < _receivers.length; i++) {
            _safeMint(_receivers[i], _mintNumber[i]);
        }
    }
}