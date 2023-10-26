// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "../interfaces/IArcadeToken.sol";

import {
    AT_ZeroAddress,
    AT_InvalidMintStart,
    AT_MinterNotCaller,
    AT_MintingNotStarted,
    AT_ZeroMintAmount,
    AT_MintingCapExceeded
} from "../errors/Token.sol";

/**
 *                                   _
 *                                  | |
 *    _____   ____  ____  _____   __| | _____     _   _  _   _  _____
 *   (____ | / ___)/ ___)(____ | / _  || ___ |   ( \ / )| | | |(___  )
 *   / ___ || |   ( (___ / ___ |( (_| || ____| _  ) X ( | |_| | / __/
 *   \_____||_|    \____)\_____| \____||_____)(_)(_/ \_) \__  |(_____)
 *                                                      (____/
 *
 *                                                 :--====-::
 *                                            :=*%%%%%%%%%%%%%*=.
 *                                        .=#%%#*+=-----=+*%%%%%%*.
 *                              :=**=:   :=-.               -#%%%%%:
 *                          .=*%%%%%%%%*=.                    #%%%%#
 *                      .-+#%%%%%%%%%%%%%%#+-.                :%%%%%=
 *                  .-+#%%%%%%%%%%%%%%%%%%%%%%#+-.             %%%%%*
 *              .-+#%%%%%%%%%%%%#+::=*%%%%%%%%%%%%#+-.        .%%%%%*
 *           :+#%%%%%%%%%%%%#+-        :=*%%%%%%%%%%%%#+:     -%%%%%+
 *           *%%%%%%%%%%#*-.               :=*%%%%%%%%%%*     #%%%%%:
 *           *%%%%%%%%%%#+:                 -*%%%%%%%%%%*    =%%%%%#
 *           *%%%%%%%%%%%%%%+-          :=*%%%%%%%%%%%%%*   :%%%%%%=
 *           *%%%%%%%%%%%%%%%%%*=:  .-*%%%%%%%%%%%%%%%%%*  :%%%%%%#
 *           *%%%%%%=-*%%%%%%%%%%%##%%%%%%%%%%%*-:%%%%%%* .#%%%%%#.
 *           *%%%%%%-   :+#%%%%%%%%%%%%%%%%#+:   .%%%%%%*:%%%%%%#.
 *           *%%%%%%-      .=*%%%%%%%%%%*-.      .%%%%%%%%%%%%%%:
 *           *%%%%%%-          *%%%%%%+          .%%%%%%%%%%%%%:
 *           *%%%%%%-          +%%%%%%=          .%%%%%%%%%%%#:
 *           *%%%%%%-          +%%%%%%=          .%%%%%%%%%%*
 *        -  *%%%%%%*:         +%%%%%%=         -+%%%%%%%%%-
 *      .##  *%%%%%%%%%*-.     +%%%%%%=     .-*%%%%%%%%%%*.
 *     .#%-  :*%%%%%%%%%%%#=.  +%%%%%%=  .=#%%%%%%%%%%%%=
 *     #%#      -+%%%%%%%%%%%#=*%%%%%%++#%%%%%%%%%%%%%*.
 *    +%%+         :+#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#:
 *   .%%%-            :=#%%%%%%%%%%%%%%%%%%%%%%%%%#-
 *   =%%%:               .-*%%%%%%%%%%%%%%%%%%%%*-
 *   +%%%:                   -+%%%%%%%%%%%%%%%*:
 *   +%%%=                      +%%%%%%%%%%%+.
 *   :%%%%:                 .-+%%%%%%%%%%*-
 *    +%%%%+.          .:=+#%%%%%%%%%%*-
 *     +%%%%%#*+===+*#%%%%%%%%%%%%#+-
 *      :*%%%%%%%%%%%%%%%%%%%%#+-.
 *         -+#%%%%%%%%%%#*+-:
 *              ......
 *
 * @title Arcade Token
 * @author Non-Fungible Technologies, Inc.
 *
 * An ERC20 token implementation for the Arcade token. The token is only able to be minted
 * by the minter address. The minter address can be changed by the minter role in the
 * contract.
 *
 * An inflationary cap of 2% per year is enforced on each mint. Every time the mint function
 * is called, the minter must wait at least 1 year before calling it again.
 */
contract ArcadeToken is ERC20, ERC20Burnable, IArcadeToken, ERC20Permit {
    // ============================================ STATE ===============================================

    // ===================== Constants =======================

    /// @notice The minimum time to wait between mints
    uint48 public constant MIN_TIME_BETWEEN_MINTS = 365 days;

    /// @notice Cap on the percentage of totalSupply that can be minted at each mint
    uint256 public constant MINT_CAP = 2;

    /// @notice The denominator for the percentage calculations
    uint256 public constant PERCENT_DENOMINATOR = 100;

    /// @notice the initial token mint amount for distribution.
    uint256 public constant INITIAL_MINT_AMOUNT = 100_000_000 ether;

    // ======================== State =========================

    /// @notice Minter contract address responsible for minting future tokens
    address public minter;

    /// @notice The timestamp after which minting may occur
    uint256 public mintingAllowedAfter;

    // ============================================ EVENTS ==============================================

    /// @dev An event thats emitted when the minter address is changed
    event MinterUpdated(address newMinter);

    // ========================================= CONSTRUCTOR ============================================

    /**
     * @notice Deploy the token contract with a set minter (for future minting) and a
     *         distribution address for the initial circulating amount.
     *
     * @param _minter               The address responsible for minting future tokens.
     * @param _initialDistribution  The address to receive the initial distribution of tokens.
     */
    constructor(address _minter, address _initialDistribution) ERC20("Arcade", "ARCD") ERC20Permit("Arcade") {
        if (_minter == address(0)) revert AT_ZeroAddress("minter");
        if (_initialDistribution == address(0)) revert AT_ZeroAddress("initialDistribution");

        minter = _minter;

        mintingAllowedAfter = block.timestamp + MIN_TIME_BETWEEN_MINTS;

        // mint the initial amount of tokens for distribution
        _mint(_initialDistribution, INITIAL_MINT_AMOUNT);
    }

    // =========================================== MINTER OPS ===========================================

    /**
     * @notice Function to change the minter address. Can only be called by the minter.
     *
     * @param _newMinter            The address of the new minter.
     */
    function setMinter(address _newMinter) external onlyMinter {
        if (_newMinter == address(0)) revert AT_ZeroAddress("newMinter");

        minter = _newMinter;
        emit MinterUpdated(minter);
    }

    /**
     * @notice Mint Arcade tokens. Can only be called by the minter.
     *
     * @param _to                 The address to mint tokens to.
     * @param _amount             The amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external onlyMinter {
        if (block.timestamp < mintingAllowedAfter) revert AT_MintingNotStarted(mintingAllowedAfter, block.timestamp);
        if (_to == address(0)) revert AT_ZeroAddress("to");
        if (_amount == 0) revert AT_ZeroMintAmount();

        // record the mint
        mintingAllowedAfter = block.timestamp + MIN_TIME_BETWEEN_MINTS;

        // inflation cap enforcement - 2% of total supply
        uint256 mintCapAmount = (totalSupply() * MINT_CAP) / PERCENT_DENOMINATOR;
        if (_amount > mintCapAmount) {
            revert AT_MintingCapExceeded(totalSupply(), mintCapAmount, _amount);
        }

        _mint(_to, _amount);
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice Modifier to check that the caller is the minter.
     */
    modifier onlyMinter() {
        if (msg.sender != minter) revert AT_MinterNotCaller(minter);
        _;
    }
}