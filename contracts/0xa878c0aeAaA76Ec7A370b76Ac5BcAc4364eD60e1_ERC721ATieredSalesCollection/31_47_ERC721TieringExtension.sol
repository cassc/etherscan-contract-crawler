// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ERC721AutoIdMinterExtension.sol";

interface IERC721TieringExtension {
    struct Tier {
        uint256 start;
        uint256 end;
        address currency;
        uint256 price;
        uint256 maxPerWallet;
        bytes32 merkleRoot;
        uint256 reserved;
        uint256 maxAllocation;
    }

    function onTierAllowlist(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external view returns (bool);

    function eligibleForTier(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external view returns (uint256);

    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable;
}

/**
 * @dev Extension to allow multiple tiers for minting,
 *      you can configure, different minting window, price, currency, max per wallet, and allowlist per tier.
 */
abstract contract ERC721TieringExtension is
    IERC721TieringExtension,
    Initializable,
    Ownable,
    ERC721AutoIdMinterExtension,
    ReentrancyGuard
{
    mapping(uint256 => Tier) public tiers;

    uint256 public totalReserved;

    mapping(uint256 => uint256) public tierMints;

    mapping(uint256 => mapping(address => uint256)) public walletMinted;

    uint256 public reservedMints;

    function __ERC721TieringExtension_init(Tier[] memory _tiers)
        internal
        onlyInitializing
    {
        __ERC721TieringExtension_init_unchained(_tiers);
    }

    function __ERC721TieringExtension_init_unchained(Tier[] memory _tiers)
        internal
        onlyInitializing
    {
        _registerInterface(type(IERC721TieringExtension).interfaceId);

        for (uint256 i = 0; i < _tiers.length; i++) {
            tiers[i] = _tiers[i];
            totalReserved += _tiers[i].reserved;
        }
    }

    /* ADMIN */

    function configureTiering(uint256 tierId, Tier calldata tier)
        public
        onlyOwner
    {
        require(tier.maxAllocation >= tierMints[tierId], "LOWER_THAN_MINTED");

        if (tiers[tierId].reserved > 0) {
            require(tier.reserved >= tierMints[tierId], "LOW_RESERVE_AMOUNT");
        }

        if (tierMints[tierId] > 0) {
            require(
                tier.maxPerWallet >= tiers[tierId].maxPerWallet,
                "LOW_MAX_PER_WALLET"
            );
        }

        totalReserved -= tiers[tierId].reserved;
        tiers[tierId] = tier;
        totalReserved += tier.reserved;

        require(totalReserved <= maxSupply, "MAX_SUPPLY_EXCEEDED");
    }

    function configureTiering(
        uint256[] calldata _tierIds,
        Tier[] calldata _tiers
    ) public onlyOwner {
        for (uint256 i = 0; i < _tierIds.length; i++) {
            configureTiering(_tierIds[i], _tiers[i]);
        }
    }

    /* PUBLIC */

    function setMaxSupply(uint256 newValue)
        public
        virtual
        override(ERC721AutoIdMinterExtension)
        onlyOwner
    {
        ERC721AutoIdMinterExtension.setMaxSupply(newValue);
        require(
            newValue - totalSupply() >= totalReserved - reservedMints,
            "LOWER_THAN_RESERVED"
        );
    }

    function onTierAllowlist(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) public view returns (bool) {
        return
            MerkleProof.verify(
                proof,
                tiers[tierId].merkleRoot,
                _generateMerkleLeaf(minter, maxAllowance)
            );
    }

    function eligibleForTier(
        uint256 tierId,
        address minter,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) public view returns (uint256 maxMintable) {
        require(tiers[tierId].maxPerWallet > 0, "NOT_EXISTS");
        require(block.timestamp >= tiers[tierId].start, "NOT_STARTED");
        require(block.timestamp <= tiers[tierId].end, "ALREADY_ENDED");

        maxMintable = tiers[tierId].maxPerWallet - walletMinted[tierId][minter];

        if (tiers[tierId].merkleRoot != bytes32(0)) {
            require(
                walletMinted[tierId][minter] < maxAllowance,
                "MAXED_ALLOWANCE"
            );
            require(
                onTierAllowlist(tierId, minter, maxAllowance, proof),
                "NOT_ALLOWLISTED"
            );

            uint256 remainingAllowance = maxAllowance -
                walletMinted[tierId][minter];

            if (maxMintable > remainingAllowance) {
                maxMintable = remainingAllowance;
            }
        }
    }

    function mintByTier(
        uint256 tierId,
        uint256 count,
        uint256 maxAllowance,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        address minter = _msgSender();

        uint256 maxMintable = eligibleForTier(
            tierId,
            minter,
            maxAllowance,
            proof
        );

        require(count <= maxMintable, "EXCEEDS_MAX");
        require(count <= remainingForTier(tierId), "EXCEEDS_ALLOCATION");
        require(
            count + tierMints[tierId] <= tiers[tierId].maxAllocation,
            "EXCEEDS_ALLOCATION"
        );

        if (tiers[tierId].currency == address(0)) {
            require(
                tiers[tierId].price * count <= msg.value,
                "INSUFFICIENT_AMOUNT"
            );
        } else {
            IERC20(tiers[tierId].currency).transferFrom(
                minter,
                address(this),
                tiers[tierId].price * count
            );
        }

        walletMinted[tierId][minter] += count;
        tierMints[tierId] += count;

        if (tiers[tierId].reserved > 0) {
            reservedMints += count;
        }

        _mintTo(minter, count);
    }

    function remainingForTier(uint256 tierId)
        public
        view
        returns (uint256 tierRemaining)
    {
        // Substract all the remaining reserved spots from the total remaining supply...
        tierRemaining =
            (maxSupply - totalSupply()) -
            (totalReserved - reservedMints);

        // If this tier has reserved spots, add remaining spots back to result...
        if (tiers[tierId].reserved > 0) {
            tierRemaining += (tiers[tierId].reserved - tierMints[tierId]);
        }
    }

    function walletMintedByTier(uint256 tierId, address wallet)
        public
        view
        returns (uint256)
    {
        return walletMinted[tierId][wallet];
    }

    /* PRIVATE */

    function _generateMerkleLeaf(address account, uint256 maxAllowance)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, maxAllowance));
    }
}