// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {HeyMintERC1155Upgradeable} from "./HeyMintERC1155Upgradeable.sol";
import {BaseConfig, TokenConfig, HeyMintStorage} from "../libraries/HeyMintStorage.sol";
import {ERC1155UDS} from "./ERC1155UDS.sol";

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {RevokableOperatorFiltererUpgradeable} from "operator-filter-registry/src/upgradeable/RevokableOperatorFiltererUpgradeable.sol";

contract HeyMintERC1155ExtensionA is
    HeyMintERC1155Upgradeable,
    IERC2981Upgradeable
{
    using HeyMintStorage for HeyMintStorage.State;

    // Default subscription address to use to enable royalty enforcement on certain exchanges like OpenSea
    address public constant CORI_SUBSCRIPTION_ADDRESS =
        0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;
    // Default subscription address to use as a placeholder for no royalty enforcement
    address public constant EMPTY_SUBSCRIPTION_ADDRESS =
        0x511af84166215d528ABf8bA6437ec4BEcF31934B;

    /**
     * @notice Initializes a new child deposit contract
     * @param _name The name of the collection
     * @param _symbol The symbol of the collection
     * @param _config Base configuration settings
     * @param _tokenConfig Array of token configuration settings
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        BaseConfig memory _config,
        TokenConfig[] memory _tokenConfig
    ) public initializer {
        __Ownable_init();
        __OperatorFilterer_init(
            _config.enforceRoyalties == true
                ? CORI_SUBSCRIPTION_ADDRESS
                : EMPTY_SUBSCRIPTION_ADDRESS,
            true
        );

        HeyMintStorage.State storage state = HeyMintStorage.state();
        state.cfg = _config;
        state.name = _name;
        state.symbol = _symbol;
        for (uint i = 0; i < _tokenConfig.length; i++) {
            state.tokens[_tokenConfig[i].tokenId] = _tokenConfig[i];
            state.data.tokenIds.push(_tokenConfig[i].tokenId);
        }
    }

    // ============ BASE FUNCTIONALITY ============

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
        override(HeyMintERC1155Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function name() public view returns (string memory) {
        return HeyMintStorage.state().name;
    }

    function symbol() public view returns (string memory) {
        return HeyMintStorage.state().symbol;
    }

    /**
     * @notice Lock a token id so that it can never be minted again
     */
    function permanentlyDisableTokenMinting(
        uint16 _tokenId
    ) external onlyOwner {
        HeyMintStorage.state().data.tokenMintingPermanentlyDisabled[
            _tokenId
        ] = true;
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

    // ============ OPERATOR FILTER REGISTRY ============

    /**
     * @notice Override default ERC-1155 setApprovalForAll to require that the operator is not from a blocklisted exchange
     * @param operator Address to add to the set of authorized operators
     * @param approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC1155UDS) onlyAllowedOperatorApproval(operator) {
        return super.setApprovalForAll(operator, approved);
    }
}