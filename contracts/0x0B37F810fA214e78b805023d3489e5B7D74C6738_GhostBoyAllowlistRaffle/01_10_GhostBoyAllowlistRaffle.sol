// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../Augminted/OpenAllowlistRaffleBase.sol";

error GhostBoyAllowlistRaffle_MustBeAKing();

interface IRWaste { function burn(address, uint256) external; }
interface IScales { function spend(address, uint256) external; }

contract GhostBoyAllowlistRaffle is OpenAllowlistRaffleBase {
    IERC721 public immutable KAIJUS;
    IERC721 public immutable MUTANTS;
    IERC721 public immutable SCIENTISTS;
    IRWaste public immutable RWASTE;
    IScales public immutable SCALES;
    uint256 public constant RWASTE_FEE = 1 ether;
    uint256 public constant SCALES_FEE = 5 ether;
    uint256 public constant RWASTE_MULTIPLIER = 2;
    uint256 public constant KOK_MULTIPLIER = 2;

    constructor(
        IERC721 kaijus,
        IERC721 mutants,
        IERC721 scientists,
        IRWaste rwaste,
        IScales scales,
        uint256 numberOfWinners,
        address vrfCoordinator
    )
        OpenAllowlistRaffleBase(numberOfWinners, vrfCoordinator)
    {
        KAIJUS = kaijus;
        MUTANTS = mutants;
        SCIENTISTS = scientists;
        RWASTE = rwaste;
        SCALES = scales;
    }

    /**
     * @notice Modifier that requires a sender to be part of the KaijuKingz ecosystem
     */
    modifier onlyKingz() {
        if (
            KAIJUS.balanceOf(msg.sender) == 0
            && MUTANTS.balanceOf(msg.sender) == 0
            && SCIENTISTS.balanceOf(msg.sender) == 0
        ) revert GhostBoyAllowlistRaffle_MustBeAKing();
        _;
    }

    /**
     * @notice Returns whether or not a specified address holds as least 10 genesis or baby kaijus
     * @param entrant Address to check King of Kingz status
     * @return bool King of Kingz status of entrant
     */
    function _isKingOfKingz(address entrant) private view returns (bool) {
        return KAIJUS.balanceOf(entrant) > 9;
    }

    /**
     * @notice Purchase entries into the raffle with $RWASTE
     * @param amount Amount of entries to purchase
     */
    function enterWithRWaste(uint256 amount) public payable onlyKingz {
        RWASTE.burn(msg.sender, amount * RWASTE_FEE);

        _enter(msg.sender, amount * RWASTE_MULTIPLIER);
    }

    /**
     * @notice Purchase entries into the raffle with $SCALES
     * @param amount Amount of entries to purchase
     */
    function enterWithScales(uint256 amount) public payable onlyKingz {
        SCALES.spend(msg.sender, amount * SCALES_FEE);

        _enter(msg.sender, amount);
    }

    /**
     * @notice Add specified amount of entries into the raffle
     * @param entrant Address entering the raffle
     * @param amount Amount of entries to add
     */
    function _enter(address entrant, uint256 amount) internal override {
        OpenAllowlistRaffleBase._enter(
            entrant,
            _isKingOfKingz(entrant) ? amount * KOK_MULTIPLIER : amount
        );
    }
}