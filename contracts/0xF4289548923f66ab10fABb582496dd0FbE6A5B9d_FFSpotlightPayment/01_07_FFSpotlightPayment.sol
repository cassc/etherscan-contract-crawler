// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title Interface of ERC721Drop
 * @dev https://github.com/ourzora/zora-drops-contracts/blob/6e99143ec7b952deab7ce652fa0c45a7d950c4c3/src/interfaces/IERC721Drop.sol#L232
 */
interface IERC721Drop {
    /// @notice External purchase function (payable in eth)
    /// @param quantity to purchase
    /// @return first minted token ID
    function purchase(uint256 quantity) external payable returns (uint256);

    /// @notice Mint a quantity of tokens with a comment that will pay out rewards
    /// @param recipient recipient of the tokens
    /// @param quantity quantity to purchase
    /// @param comment comment to include in the IERC721Drop.Sale event
    /// @param mintReferral The finder of the mint
    /// @return tokenId of the first token minted
    function mintWithRewards(
        address recipient,
        uint256 quantity,
        string calldata comment,
        address mintReferral
    ) external payable returns (uint256);
}

/**
 * @title Interface of ZoraCreator1155
 * @dev https://github.com/ourzora/zora-drops-contracts/blob/6e99143ec7b952deab7ce652fa0c45a7d950c4c3/src/interfaces/IERC721Drop.sol#L232
 */
interface IZoraCreator1155 {
    /// @notice Only allow minting one token id at time
    /// @dev Mint contract function that calls the underlying sales function for commands
    /// @param minter Address for the minter
    /// @param tokenId tokenId to mint, set to 0 for new tokenId
    /// @param quantity to mint
    /// @param minterArguments calldata for the minter contracts
    function mint(
        address minter,
        uint256 tokenId,
        uint256 quantity,
        bytes calldata minterArguments
    ) external payable;

    /// @notice Mint tokens and payout rewards given a minter contract, minter arguments, a finder, and a origin
    /// @param minter The minter contract to use
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param minterArguments The arguments to pass to the minter
    /// @param mintReferral The referrer of the mint
    function mintWithRewards(
        address minter,
        uint256 tokenId,
        uint256 quantity,
        bytes calldata minterArguments,
        address mintReferral
    ) external payable;
}

interface IMirrorWritingEditions {
    function purchase(
        address tokenRecipient,
        string memory message
    ) external payable returns (uint256 tokenId);
}

/**
 * @title FFSpotlightPayment
 * @dev Handles SpotlightPayment for ForeFront
 */
contract FFSpotlightPayment is Ownable, ReentrancyGuard {
    address public immutable FF_TREASURY_ADDRESS;
    uint256 public spotlightFee = 0.00055 ether;

    constructor(address _treasuryAddress) {
        FF_TREASURY_ADDRESS = _treasuryAddress;
    }

    /**
     * @dev Pays Spotlight Fee to FF treasury, and then purchase ERC721 NFTs on Zora.
     * @return First minted token id
     */
    function purchase(
        address zoraDropAddress,
        uint256 quantity
    ) external payable nonReentrant returns (uint256) {
        require(msg.value >= spotlightFee, "error: SPOTLIGHT_FEE > amount");

        if (spotlightFee > 0) {
            (bool sent, bytes memory data) = FF_TREASURY_ADDRESS.call{
                value: spotlightFee
            }("");
            require(sent, "Failed to send Ether");
        }

        uint256 zoraAmount = msg.value - spotlightFee;
        uint256 firstMintedTokenId = IERC721Drop(zoraDropAddress).purchase{
            value: zoraAmount
        }(quantity);

        uint256 tokenId = firstMintedTokenId + 1;
        for (uint256 index = 0; index < quantity; index++) {
            IERC721Upgradeable(zoraDropAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                tokenId
            );
            tokenId++;
        }

        return firstMintedTokenId;
    }

    /**
     * @dev Pays Spotlight Fee to FF treasury, and then purchase with rewards ERC721 NFTs on Zora.
     * @return First minted token id
     */
    function purchaseWithRewards(
        address zoraDropAddress,
        address recipient,
        uint256 quantity,
        string calldata comment,
        address mintReferral
    ) external payable nonReentrant returns (uint256) {
        require(msg.value >= spotlightFee, "error: SPOTLIGHT_FEE > amount");

        if (spotlightFee > 0) {
            (bool sent, bytes memory data) = FF_TREASURY_ADDRESS.call{
                value: spotlightFee
            }("");
            require(sent, "Failed to send Ether");
        }

        uint256 zoraAmount = msg.value - spotlightFee;
        uint256 firstMintedTokenId = IERC721Drop(zoraDropAddress)
            .mintWithRewards{value: zoraAmount}(
            recipient,
            quantity,
            comment,
            mintReferral
        );

        return firstMintedTokenId;
    }

    /**
     * @dev Pays Spotlight Fee to FF treasury, and then purchase the NFT on Mirror.
     */
    function purchaseOnMirror(
        address mirrorAddress
    ) external payable nonReentrant {
        require(msg.value >= spotlightFee, "error: SPOTLIGHT_FEE > amount");

        if (spotlightFee > 0) {
            (bool sent, bytes memory data) = FF_TREASURY_ADDRESS.call{
                value: spotlightFee
            }("");
            require(sent, "Failed to send Ether");
        }

        uint256 mirrorAmount = msg.value - spotlightFee;

        IMirrorWritingEditions(mirrorAddress).purchase{value: mirrorAmount}(
            _msgSender(),
            ""
        );
    }

    /**
     * @dev Pays Spotlight Fee to FF treasury, and then mint ERC1155 NFTs on Zora.
     */
    function mint(
        address zoraDropAddress,
        address minter,
        uint256 tokenId,
        uint256 quantity,
        bytes calldata minterArguments
    ) external payable nonReentrant {
        require(msg.value >= spotlightFee, "error: SPOTLIGHT_FEE > amount");

        if (spotlightFee > 0) {
            (bool sent, bytes memory data) = FF_TREASURY_ADDRESS.call{
                value: spotlightFee
            }("");
            require(sent, "Failed to send Ether");
        }

        uint256 zoraAmount = msg.value - spotlightFee;

        IZoraCreator1155(zoraDropAddress).mint{value: zoraAmount}(
            minter,
            tokenId,
            quantity,
            minterArguments
        );
    }

    /**
     * @dev Pays Spotlight Fee to FF treasury, and then mint with rewards ERC1155 NFTs on Zora.
     */
    function mintWithRewards(
        address zoraDropAddress,
        address minter,
        uint256 tokenId,
        uint256 quantity,
        bytes calldata minterArguments,
        address mintReferral
    ) external payable nonReentrant {
        require(msg.value >= spotlightFee, "error: SPOTLIGHT_FEE > amount");

        if (spotlightFee > 0) {
            (bool sent, bytes memory data) = FF_TREASURY_ADDRESS.call{
                value: spotlightFee
            }("");
            require(sent, "Failed to send Ether");
        }

        uint256 zoraAmount = msg.value - spotlightFee;

        IZoraCreator1155(zoraDropAddress).mintWithRewards{value: zoraAmount}(
            minter,
            tokenId,
            quantity,
            minterArguments,
            mintReferral
        );
    }

    function setFee(uint256 _fee) external onlyOwner {
        spotlightFee = _fee;
    }
}