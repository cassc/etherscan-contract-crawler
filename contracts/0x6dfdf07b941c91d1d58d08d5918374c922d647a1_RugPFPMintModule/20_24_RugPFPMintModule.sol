// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {RugUtilityProperties} from "./RugUtilityProperties.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Collective} from "src/contracts/ERC721Collective/IERC721Collective.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TokenOwnerChecker} from "src/contracts/utils/TokenOwnerChecker.sol";

/// This mint module allows for 1 or more "mint passes" or required token, which can be marked as used
/// Requirements can be found at: https://twitter.com/farokh/status/1601627199446319104
/// Based on RequiredTokensMintModule
contract RugPFPMintModule is ReentrancyGuard, TokenOwnerChecker {
    // Price per NFT (can be 0)
    uint256 public constant RUG_PFP_PRICE = 690 * 10**18;
    // solhint-disable-next-line var-name-mixedcase
    address public immutable RUG_PFP_ADDRESS;
    address public constant RUG_TOKEN_ADDRESS =
        0xD2d8D78087D0E43BC4804B6F946674b2Ee406b80;
    address public constant GENESIS_NFT_ADDRESS =
        0x8ff1523091c9517BC328223D50b52Ef450200339;
    address public constant GENESIS_RENDERER_ADDRESS =
        0x1aCc3a26FCB9751D5E3b698D009b9C944eb98F9e;

    IERC20 public constant RUG_TOKEN = IERC20(RUG_TOKEN_ADDRESS);
    // solhint-disable-next-line var-name-mixedcase
    IERC721Collective public immutable RUG_PFP;
    IERC721Collective public constant GENESIS_NFT =
        IERC721Collective(GENESIS_NFT_ADDRESS);
    RugUtilityProperties public constant GENESIS_RENDERER =
        RugUtilityProperties(GENESIS_RENDERER_ADDRESS);

    // Genesis token ID => tokens redeemed
    mapping(uint256 => uint256) public pfpsRedeemedPerGenesisNFT;

    event Redeemed(
        address indexed collective,
        address indexed account,
        uint256 indexed tokenId
    );

    // solhint-disable-next-line var-name-mixedcase
    constructor(address RUG_PFP_ADDRESS_) {
        RUG_PFP_ADDRESS = RUG_PFP_ADDRESS_;
        RUG_PFP = IERC721Collective(RUG_PFP_ADDRESS);
    }

    function redeem(uint256 tokenId, uint256 amountToMint) public payable {
        // Follows the Checks-Effects-Interactions pattern
        // Checks and Effect
        _redeemCommon(tokenId, amountToMint);

        // Interactions
        // Mint PFPs
        RUG_PFP.bulkMintToOneAddress(msg.sender, amountToMint);
        // Transfer the required token to the contract
        SafeERC20.safeTransferFrom(
            RUG_TOKEN,
            msg.sender,
            RUG_PFP.owner(),
            amountToMint * RUG_PFP_PRICE
        );
    }

    function redeemMany(
        uint256[] calldata tokenIds,
        uint256[] calldata amountsToMint
    ) public payable {
        require(
            tokenIds.length == amountsToMint.length,
            "Arrays must be same length"
        );
        uint256 length = tokenIds.length;
        uint256 totalToMint;

        for (uint256 i = 0; i < length; ) {
            // Checks and Effects
            _redeemCommon(tokenIds[i], amountsToMint[i]);
            totalToMint += amountsToMint[i];

            unchecked {
                ++i;
            }
        }

        // Interactions
        // Mint PFPs
        RUG_PFP.bulkMintToOneAddress(msg.sender, totalToMint);
        // Transfer the required token to the contract
        SafeERC20.safeTransferFrom(
            RUG_TOKEN,
            msg.sender,
            RUG_PFP.owner(),
            totalToMint * RUG_PFP_PRICE
        );
    }

    function getMintsPerNFT(uint256 tokenId) public view returns (uint256) {
        uint256 tokenIdRole = GENESIS_RENDERER.getRole(tokenId);

        // Order from least scarce to most for the most gas savings
        if (tokenIdRole == 2 || tokenIdRole == 3 || tokenIdRole == 4) {
            // Scarce 1, Scarce 2, and Standard have 1 mint per NFT
            return 1;
        } else if (tokenIdRole == 1) {
            // Rare 2 has 2 mints per NFT
            return 2;
        } else if (tokenIdRole == 0) {
            // Rare 1 has 5 mints per NFT
            return 5;
        } else {
            return 0;
        }
    }

    function getMintsRemainingPerNFT(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256 mintsPerNFT = getMintsPerNFT(tokenId);
        // Return mints remaining. If a user tries to mint more than their mints
        // remaining, this will revert to avoid overflow
        return mintsPerNFT - pfpsRedeemedPerGenesisNFT[tokenId];
    }

    function getMintsRemainingPerNFTs(uint256[] calldata tokenIds)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory mintsRemaining = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; ) {
            mintsRemaining[i] = getMintsRemainingPerNFT(tokenIds[i]);

            unchecked {
                ++i;
            }
        }

        return mintsRemaining;
    }

    function _redeemCommon(uint256 tokenId, uint256 amountToMint) internal {
        // Common checks
        require(
            getMintsRemainingPerNFT(tokenId) >= amountToMint,
            "RugPFPMintModule: Remaining mints exceeded"
        );
        require(
            msg.sender == GENESIS_NFT.ownerOf(tokenId),
            "RugPFPMintModule: Must be owner of tokenId attempting to redeem"
        );

        // Common effects
        // Mark token as redeemed
        pfpsRedeemedPerGenesisNFT[tokenId] += amountToMint;
        // Emit Event per tokenId
        emit Redeemed(RUG_PFP_ADDRESS, msg.sender, tokenId);
    }

    /// This function is called for all messages sent to this contract (there
    /// are no other functions). Sending Ether to this contract will cause an
    /// exception, because the fallback function does not have the `payable`
    /// modifier.
    /// Source: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=fallback#fallback-function
    fallback() external {
        revert("RugPFPMintModule: non-existent function");
    }
}