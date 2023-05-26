// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {IERC20Upgradeable, SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {IERC721Mintable} from "./interfaces/IERC721Mintable.sol";
import {OwnablePausable} from "./OwnablePausable.sol";
import {ICrowdsale} from "./interfaces/ICrowdsale.sol";

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with proper currency.
 */
contract Crowdsale is OwnablePausable, ICrowdsale {
    using SafeCastUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public whitelistPhaseDuration;
    uint256 public publicPhaseDuration;
    uint256 public durationBetweenTranches;

    uint256 public constant TRANCHE_SUPPLY = 999;
    uint256 public constant PUBLIC_PRICE = 99e6; // 99 USDC

    uint256 public constant KOL_LIMIT_PER_ACCOUNT = TRANCHE_SUPPLY;
    uint256 public constant FREE_MINT_LIMIT_PER_ACCOUNT = 1;

    /**
     * @notice The token being sold
     */
    address public token;

    /**
     * @notice The token received for sold token
     */
    IERC20Upgradeable public currency;

    /**
     * @notice Address which collects raised funds
     */
    address public wallet;

    /**
     * @notice List of tranches
     */
    mapping(uint256 => Tranche) public tranches;
    uint256 public tranchesCounter;

    mapping(address => Whitelist) private _kolWhitelist;
    mapping(address => Whitelist) private _freeMintsWhitelist;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param owner_ Address of crowdsale contract owner
     * @param wallet_ Address where collected funds will be forwarded to
     * @param currency_ Address of the token received for NFT
     * @param token_ Address of the token being sold
     * @param start_ Start block number for whole sale
     */
    function initialize(
        address owner_,
        address wallet_,
        IERC20Upgradeable currency_,
        address token_,
        uint256 start_,
        uint256 tranchesCount_,
        uint256 whitelistPhaseDuration_,
        uint256 publicPhaseDuration_,
        uint256 durationBetweenTranches_
    ) public initializer {
        __Context_init();
        __OwnablePausable_init(owner_);

        require(wallet_ != address(0), "Wallet is the zero address");
        require(token_ != address(0), "Token is the zero address");

        wallet = wallet_;
        currency = currency_;
        token = token_;

        require(
            durationBetweenTranches_ >= whitelistPhaseDuration_ + publicPhaseDuration_,
            "Duration between tranches is too small"
        );
        whitelistPhaseDuration = whitelistPhaseDuration_;
        publicPhaseDuration = publicPhaseDuration_;
        durationBetweenTranches = durationBetweenTranches_;

        for (uint256 i = 0; i < tranchesCount_; i++) {
            uint256 trancheStart = start_ + i * durationBetweenTranches;
            uint256 kolPrice = PUBLIC_PRICE;
            _setupTranche(trancheStart, kolPrice);
        }

        _pause();
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function setWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Wallet is the zero address");
        wallet = newWallet;
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function setCurrency(address newCurrency) external onlyOwner {
        require(newCurrency != address(0), "Currency is the zero address");
        currency = IERC20Upgradeable(newCurrency);
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function setToken(address newToken) external onlyOwner {
        require(newToken != address(0), "Token is the zero address");
        token = newToken;
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function fundsRaised() external view returns (uint256) {
        uint256 raised = 0;
        for (uint256 i = 0; i < tranchesCounter; i++) {
            Tranche memory tranche = tranches[i];
            raised += (tranche.publicSold * PUBLIC_PRICE + tranche.kolSold * tranche.kolPrice);
        }
        return raised;
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function buyTokens(uint256 amount) external whenNotPaused {
        require(amount > 0, "Invalid token amount claimed");
        require(amount <= available(_msgSender()), "Too many tokens claimed");

        _processPurchase(_msgSender(), amount);
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function getTranchesCount() external view returns (uint256) {
        return tranchesCounter;
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function addTranche(uint256 start, uint256 kolPrice) external onlyOwner {
        uint256 counter = tranchesCounter;
        if (counter > 0) {
            require(
                start > tranches[counter].start + whitelistPhaseDuration + publicPhaseDuration,
                "Tranche start cannot overlap another ones"
            );
        }
        _setupTranche(start, kolPrice);
    }

    function _setupTranche(uint256 start, uint256 kolPrice) private {
        uint256 newCounter = tranchesCounter + 1;
        tranches[newCounter] = Tranche(start, TRANCHE_SUPPLY, kolPrice, PUBLIC_PRICE, 0, 0, 0);
        tranchesCounter = newCounter;
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function addToKolWhitelist(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _kolWhitelist[accounts[i]].cap = KOL_LIMIT_PER_ACCOUNT;
        }
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function addToFreeMintsWhitelist(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _freeMintsWhitelist[accounts[i]].cap += FREE_MINT_LIMIT_PER_ACCOUNT;
        }
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function removeFromKolWhitelist(address[] calldata accounts) external onlyOwner {
        _removeFromWhitelist(_kolWhitelist, accounts);
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function removeFromFreeMintsWhitelist(address[] calldata accounts) external onlyOwner {
        _removeFromWhitelist(_freeMintsWhitelist, accounts);
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function getCurrentTrancheDetails() external view returns (TrancheStatus memory) {
        (uint256 index, Phase phase) = _getCurrentTranche();
        return TrancheStatus(tranches[index], phase, index);
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function isAccountFreeMintsWhitelisted(address account) external view returns (bool) {
        return _isAccountWhitelisted(_freeMintsWhitelist, account);
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function isAccountKolWhitelisted(address account) external view returns (bool) {
        return _isAccountWhitelisted(_kolWhitelist, account);
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function supply() external view returns (uint256) {
        (, Phase phase) = _getCurrentTranche();
        return (phase != Phase.Inactive) ? TRANCHE_SUPPLY : 0;
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function sold() external view returns (uint256) {
        (uint256 index, ) = _getCurrentTranche();
        return _getTotalSoldInTranche(index);
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function available(address account) public view returns (uint256) {
        (uint256 index, Phase phase) = _getCurrentTranche();

        if (phase == Phase.Whitelisted) {
            return
                _freeMintsWhitelist[account].cap -
                _freeMintsWhitelist[account].contribution +
                _kolWhitelist[account].cap -
                _kolWhitelist[account].contribution;
        } else if (phase == Phase.Public) {
            return TRANCHE_SUPPLY - _getTotalSoldInTranche(index);
        } else {
            return 0;
        }
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function boughtCountKol(address account) external view returns (uint256) {
        return _kolWhitelist[account].contribution;
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function boughtCountFreeMint(address account) external view returns (uint256) {
        return _freeMintsWhitelist[account].contribution;
    }

    /**
     * @inheritdoc ICrowdsale
     */
    function updateTrancheStartBlock(uint256 trancheNumber, uint256 newStartBlock) external onlyOwner {
        require(newStartBlock >= block.number, "Cannot update start block to one in the past");

        tranches[trancheNumber].start = newStartBlock;
    }

    function _getCurrentTranche() private view returns (uint256, Phase) {
        if (tranchesCounter > 0) {
            for (uint256 i = tranchesCounter; i > 0; i--) {
                if (block.number >= tranches[i].start + whitelistPhaseDuration + publicPhaseDuration) {
                    return (i, Phase.Inactive);
                } else if (block.number >= tranches[i].start + whitelistPhaseDuration) {
                    return (i, Phase.Public);
                } else if (block.number >= tranches[i].start) {
                    return (i, Phase.Whitelisted);
                }
            }
        }
        return (0, Phase.Inactive);
    }

    function _removeFromWhitelist(
        mapping(address => Whitelist) storage whitelist,
        address[] memory accounts
    ) private onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = Whitelist(0, 0);
        }
    }

    function _isAccountWhitelisted(
        mapping(address => Whitelist) storage whitelist,
        address account
    ) private view returns (bool) {
        return whitelist[account].cap > 0;
    }

    function _getAvailableWhitelistedTokensForAccount(
        mapping(address => Whitelist) storage whitelist,
        address account
    ) private view returns (uint256) {
        Whitelist memory whitelistInfo = whitelist[account];
        return whitelistInfo.cap - whitelistInfo.contribution;
    }

    function _getTotalSoldInTranche(uint256 index) private view returns (uint256) {
        Tranche memory sale = tranches[index];
        return sale.freeMintsSold + sale.kolSold + sale.publicSold;
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal virtual {
        (uint256 index, Phase phase) = _getCurrentTranche();
        require(phase != Phase.Inactive, "No active sale");
        require(tokenAmount + _getTotalSoldInTranche(index) <= TRANCHE_SUPPLY, "Insufficient tokens available");

        uint256 value = 0;
        if (phase == Phase.Whitelisted) {
            uint256 freeMintsAvailable = _getAvailableWhitelistedTokensForAccount(_freeMintsWhitelist, beneficiary);
            uint256 kolAvailable = _getAvailableWhitelistedTokensForAccount(_kolWhitelist, beneficiary);
            require(tokenAmount <= freeMintsAvailable + kolAvailable, "Insufficient tokens available in current phase");

            uint256 remainingTokensToBePaidOut = tokenAmount;
            uint256 fromFreeMints = MathUpgradeable.min(freeMintsAvailable, tokenAmount);
            if (fromFreeMints > 0) {
                _freeMintsWhitelist[beneficiary].contribution += fromFreeMints.toUint128();
                tranches[index].freeMintsSold += fromFreeMints;
                remainingTokensToBePaidOut -= fromFreeMints;
            }

            if (remainingTokensToBePaidOut > 0) {
                _kolWhitelist[beneficiary].contribution += remainingTokensToBePaidOut.toUint128();
                tranches[index].kolSold += remainingTokensToBePaidOut;
                value += tranches[index].kolPrice * remainingTokensToBePaidOut;
            }
        } else {
            // Phase.Public
            tranches[index].publicSold += tokenAmount;
            value += PUBLIC_PRICE * tokenAmount;
        }

        emit TokensPurchased(beneficiary, value, tokenAmount);

        if (value > 0) {
            currency.safeTransferFrom(beneficiary, wallet, value);
        }
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal virtual {
        IERC721Mintable(token).mint(beneficiary, tokenAmount);
    }

    uint256[44] private __gap;
}