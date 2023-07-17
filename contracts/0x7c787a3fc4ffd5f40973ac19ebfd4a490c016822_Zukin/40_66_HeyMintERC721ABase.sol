// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC721AUpgradeable} from "./HeyMintERC721AUpgradeable.sol";
import {BaseConfig, HeyMintStorage} from "../libraries/HeyMintStorage.sol";
import {ERC721AUpgradeable, IERC721AUpgradeable} from "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract HeyMintERC721ABase is HeyMintERC721AUpgradeable, IERC2981Upgradeable {
    using HeyMintStorage for HeyMintStorage.State;
    using ECDSAUpgradeable for bytes32;

    // Default subscription address to use to enable royalty enforcement on certain exchanges like OpenSea
    address public constant CORI_SUBSCRIPTION_ADDRESS =
        0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    // Default subscription address to use as a placeholder for no royalty enforcement
    address public constant EMPTY_SUBSCRIPTION_ADDRESS =
        0x511af84166215d528ABf8bA6437ec4BEcF31934B;

    /**
     * @notice Initializes a new child deposit contract
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     * @param _config Base configuration settings
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        BaseConfig memory _config
    ) public initializerERC721A initializer {
        __ERC721A_init(_name, _symbol);
        __Ownable_init();
        __ReentrancyGuard_init();
        __OperatorFilterer_init(
            _config.enforceRoyalties == true
                ? CORI_SUBSCRIPTION_ADDRESS
                : EMPTY_SUBSCRIPTION_ADDRESS,
            true
        );

        HeyMintStorage.state().cfg = _config;

        // If public sale start time is set but end time is not, set default end time
        if (_config.publicSaleStartTime > 0 && _config.publicSaleEndTime == 0) {
            HeyMintStorage.state().cfg.publicSaleEndTime =
                _config.publicSaleStartTime +
                520 weeks;
        }

        // If public sale end time is set but not start time, set default start time
        if (_config.publicSaleEndTime > 0 && _config.publicSaleStartTime == 0) {
            HeyMintStorage.state().cfg.publicSaleStartTime = uint32(
                block.timestamp
            );
        }

        // If presale start time is set but end time is not, set default end time
        if (_config.presaleStartTime > 0 && _config.presaleEndTime == 0) {
            HeyMintStorage.state().cfg.presaleEndTime =
                _config.presaleStartTime +
                520 weeks;
        }

        // If presale end time is set but not start time, set default start time
        if (_config.presaleEndTime > 0 && _config.presaleStartTime == 0) {
            HeyMintStorage.state().cfg.presaleStartTime = uint32(
                block.timestamp
            );
        }
    }

    // ============ BASE FUNCTIONALITY ============

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Returns true if the contract implements the interface defined by interfaceId
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(HeyMintERC721AUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return HeyMintERC721AUpgradeable.supportsInterface(interfaceId);
    }

    // ============ METADATA ============

    /**
     * @notice Returns the base URI for all tokens. If the base URI is not set, it will be generated based on the project ID
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return HeyMintStorage.state().cfg.uriBase;
    }

    /**
     * @notice Overrides the default ERC721 tokenURI function to look for specific token URIs when present
     * @param tokenId The token ID to query
     */
    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        HeyMintStorage.State storage state = HeyMintStorage.state();
        string memory specificTokenURI = state.data.tokenURIs[tokenId];
        if (bytes(specificTokenURI).length != 0) return specificTokenURI;
        string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) return "";
        uint256 burnTokenId = state.data.tokenIdToBurnTokenId[tokenId];
        uint256 tokenURITokenId = state.advCfg.useBurnTokenIdForMetadata &&
            burnTokenId != 0
            ? burnTokenId
            : tokenId;
        return string(abi.encodePacked(baseURI, _toString(tokenURITokenId)));
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI The new base URI to use
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!HeyMintStorage.state().advCfg.metadataFrozen, "NOT_ACTIVE");
        HeyMintStorage.state().cfg.uriBase = _newBaseURI;
    }

    /**
     * @notice Freeze metadata so it can never be changed again
     */
    function freezeMetadata() external onlyOwner {
        HeyMintStorage.state().advCfg.metadataFrozen = true;
    }

    // ============ ERC-2981 ROYALTY ============

    /**
     * @notice Basic gas saving implementation of ERC-2981 royaltyInfo function with receiver set to the contract owner
     * @param _salePrice The sale price used to determine the royalty amount
     */
    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view override returns (address, uint256) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        address payoutAddress = state.advCfg.royaltyPayoutAddress !=
            address(0x0)
            ? state.advCfg.royaltyPayoutAddress
            : owner();
        if (payoutAddress == address(0x0)) {
            return (payoutAddress, 0);
        }
        return (payoutAddress, (_salePrice * state.cfg.royaltyBps) / 10000);
    }

    // ============ PAYOUT ============

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() external nonReentrant onlyOwner {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (state.cfg.fundingEndsAt > 0) {
            require(
                state.data.fundingTargetReached,
                "FUNDING_TARGET_NOT_REACHED"
            );
        }
        if (state.advCfg.refundEndsAt > 0) {
            require(!refundGuaranteeActive(), "REFUND_GUARANTEE_STILL_ACTIVE");
        }
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

    // ============ PUBLIC SALE ============

    /**
     * @notice Returns the public price in wei. Public price is stored with 5 decimals (1 = 0.00001 ETH), so total 5 + 13 == 18 decimals
     */
    function publicPriceInWei() public view returns (uint256) {
        return uint256(HeyMintStorage.state().cfg.publicPrice) * 10 ** 13;
    }

    /**
     * @notice To be updated by contract owner to allow public sale minting
     */
    function setPublicSaleState(bool _saleActiveState) external onlyOwner {
        HeyMintStorage.state().cfg.publicSaleActive = _saleActiveState;
    }

    /**
     * @notice Update the public mint price
     * @param _publicPrice The new public mint price to use
     */
    function setPublicPrice(uint32 _publicPrice) external onlyOwner {
        HeyMintStorage.state().cfg.publicPrice = _publicPrice;
    }

    /**
     * @notice Set the maximum mints allowed per a given address in the public sale
     * @param _mintsAllowed The new maximum mints allowed per address
     */
    function setPublicMintsAllowedPerAddress(
        uint8 _mintsAllowed
    ) external onlyOwner {
        HeyMintStorage.state().cfg.publicMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Set the maximum mints allowed per a given transaction in the public sale
     * @param _mintsAllowed The new maximum mints allowed per transaction
     */
    function setPublicMintsAllowedPerTransaction(
        uint8 _mintsAllowed
    ) external onlyOwner {
        HeyMintStorage
            .state()
            .cfg
            .publicMintsAllowedPerTransaction = _mintsAllowed;
    }

    /**
     * @notice Update the start time for public mint
     * @param _publicSaleStartTime The new start time for public mint
     */
    function setPublicSaleStartTime(
        uint32 _publicSaleStartTime
    ) external onlyOwner {
        HeyMintStorage.state().cfg.publicSaleStartTime = _publicSaleStartTime;
    }

    /**
     * @notice Update the end time for public mint
     * @param _publicSaleEndTime The new end time for public mint
     */
    function setPublicSaleEndTime(
        uint32 _publicSaleEndTime
    ) external onlyOwner {
        require(_publicSaleEndTime > block.timestamp, "TIME_IN_PAST");
        HeyMintStorage.state().cfg.publicSaleEndTime = _publicSaleEndTime;
    }

    /**
     * @notice Update whether or not to use the automatic public sale times
     * @param _usePublicSaleTimes Whether or not to use the automatic public sale times
     */
    function setUsePublicSaleTimes(
        bool _usePublicSaleTimes
    ) external onlyOwner {
        HeyMintStorage.state().cfg.usePublicSaleTimes = _usePublicSaleTimes;
    }

    /**
     * @notice Returns if public sale times are active. If required config settings are not set, returns true.
     */
    function publicSaleTimeIsActive() public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        if (
            state.cfg.usePublicSaleTimes == false ||
            state.cfg.publicSaleStartTime == 0 ||
            state.cfg.publicSaleEndTime == 0
        ) {
            return true;
        }
        return
            block.timestamp >= state.cfg.publicSaleStartTime &&
            block.timestamp <= state.cfg.publicSaleEndTime;
    }

    /**
     * @notice Allow for public minting of tokens
     * @param _numTokens The number of tokens to mint
     */
    function publicMint(uint256 _numTokens) external payable nonReentrant {
        BaseConfig storage cfg = HeyMintStorage.state().cfg;
        require(cfg.publicSaleActive, "NOT_ACTIVE");
        require(publicSaleTimeIsActive(), "NOT_ACTIVE");
        require(
            cfg.publicMintsAllowedPerAddress == 0 ||
                _numberMinted(msg.sender) + _numTokens <=
                cfg.publicMintsAllowedPerAddress,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            cfg.publicMintsAllowedPerTransaction == 0 ||
                _numTokens <= cfg.publicMintsAllowedPerTransaction,
            "MAX_MINTS_EXCEEDED"
        );
        require(
            totalSupply() + _numTokens <= cfg.maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );
        uint256 publicPrice = publicPriceInWei();
        if (cfg.heyMintFeeActive) {
            uint256 heymintFee = _numTokens * heymintFeePerToken();
            require(
                msg.value == publicPrice * _numTokens + heymintFee,
                "INVALID_PRICE_PAID"
            );
            (bool success, ) = heymintPayoutAddress.call{value: heymintFee}("");
            require(success, "TRANSFER_FAILED");
        } else {
            require(
                msg.value == publicPrice * _numTokens,
                "INVALID_PRICE_PAID"
            );
        }

        if (cfg.fundingEndsAt > 0) {
            uint256 firstTokenIdToMint = _nextTokenId();
            for (uint256 i = 0; i < _numTokens; i++) {
                HeyMintStorage.state().data.pricePaid[
                    firstTokenIdToMint + i
                ] = publicPrice;
            }
        }

        _safeMint(msg.sender, _numTokens);
    }

    // ============ REFUND ============

    /**
     * Will return true if token holders can still return their tokens for a refund
     */
    function refundGuaranteeActive() public view returns (bool) {
        HeyMintStorage.State storage state = HeyMintStorage.state();
        return block.timestamp < state.advCfg.refundEndsAt;
    }
}