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
        
        console.log(zoraAmount);
        console.log(zoraDropAddress);
        console.log(minter);
        console.log(tokenId);
        console.log(quantity);
        console.logBytes(minterArguments);

        IZoraCreator1155(zoraDropAddress).mint{value: zoraAmount}(
            minter,
            tokenId,
            quantity,
            minterArguments
        );
    }

    function setFee(uint256 _fee) external onlyOwner {
        spotlightFee = _fee;
    }
}