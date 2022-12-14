// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {ERC721Holder} from "@openzeppelin/token/ERC721/utils/ERC721Holder.sol";

import {toWadUnsafe, toDaysWadUnsafe} from "solmate/utils/SignedWadMath.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {LibGOO} from "goo-issuance/LibGOO.sol";

import {LVRGDA} from "./LVRGDA.sol";
import {KnifeNFT, SpyNFT, GooBalanceUpdateType} from "./NFT.sol";

/// @title Knife Game Logic
/// @author Libevm <[email protected]>
/// @notice A funny game
contract KnifeGame is ERC721Holder {
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the SPY NFT contract
    SpyNFT public immutable spyNFT;

    /// @notice The address of the Knives NFT contract
    KnifeNFT public immutable knifeNFT;

    /// @notice Prices curves for the NFTs
    LVRGDA public spyLVRGDA;
    LVRGDA public knifeLVRGDA;

    /*//////////////////////////////////////////////////////////////
                            CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Safe multisig knifegamexyz.eth
    address public constant MULTISIG = 0x503C42470951B7c163730fD8b67EA66FECd8c774;

    /// @notice knife-game-treasury
    address public constant SHOUTS_FUNDS_RECIPIENT = 0xDb42214E11bF1d49df83D311c3d88AaCDE666243;

    /// @notice Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /// @notice How much $$ per user
    uint256 public constant INITIAL_PURCHASE_SPY_ETH_PRICE = 0.1 ether;

    /*//////////////////////////////////////////////////////////////
                            GAME VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Timestamp for the start of minting.
    uint256 public immutable gameStart;

    /// @notice Number of spies minted from moo.
    uint128 public spiesMintedFromMoo;

    /// @notice Number of knives minted from moo.
    uint128 public knivesMintedFromMoo;

    /// @notice Number of purchases per day (after game)
    mapping(address => mapping(uint256 => uint256)) public userPurchasesOnDay;

    /// @notice Have the users purchased pre-game
    mapping(address => bool) public hasUserPrepurchased;

    /// @notice Have the users claimed free MOO tokens pre-game
    mapping(address => bool) public hasUserClaimedFreeMooTokens;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error TooEarly();
    error TooLate();
    error TooPoor();
    error DumbMove();

    error NotOwner();
    error NoWhales();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Shouted(address indexed sender, string message);

    event SpyMinted(address indexed recipient, uint256 indexed id);
    event SpyPurchased(address indexed recipient, uint256 indexed id, uint256 price);
    event SpyKilled(address indexed hitman, address indexed victim, uint256 knifeId, uint256 spyId);

    event KnifePurchased(address indexed recipient, uint256 indexed id, uint256 price);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(uint256 _gameStart, address _spyNft, address _knifeNFT) {
        // Time
        gameStart = _gameStart;

        // NFTs
        spyNFT = SpyNFT(_spyNft);
        knifeNFT = KnifeNFT(_knifeNFT);

        // Price curves
        spyLVRGDA = new LVRGDA(
            6.9e18, // Target price
            0.5e18, // Price decay percent
            toWadUnsafe(19000),
            0.3e18 // Time scale.
        );
        knifeLVRGDA = new LVRGDA(
            8.0085e18, // Target price
            0.6e18, // Price decay percent
            toWadUnsafe(40000),
            0.22e18 // Time scale.
        );
    }

    /*//////////////////////////////////////////////////////////////
                          Permissioned
    //////////////////////////////////////////////////////////////*/

    function updateSpyVRGDA(int256 _targetPrice, int256 _priceDecayPercent, uint256 _maxAmount, int256 _timeScale)
        public
    {
        // Only multisig can change
        if (msg.sender != MULTISIG) revert NotOwner();

        // Can't change after game starts
        if (block.timestamp >= gameStart) revert TooLate();

        spyLVRGDA = new LVRGDA(
            _targetPrice,
            _priceDecayPercent,
            toWadUnsafe(_maxAmount),
            _timeScale
        );
    }

    function updateKnifeVRGDA(int256 _targetPrice, int256 _priceDecayPercent, uint256 _maxAmount, int256 _timeScale)
        public
    {
        // Only multisig can change
        if (msg.sender != MULTISIG) revert NotOwner();

        // Can't change after game starts
        if (block.timestamp > gameStart) revert TooLate();

        knifeLVRGDA = new LVRGDA(
            _targetPrice,
            _priceDecayPercent,
            toWadUnsafe(_maxAmount),
            _timeScale
        );
    }

    /*//////////////////////////////////////////////////////////////
                          Minting Logic
    //////////////////////////////////////////////////////////////*/

    function claimFreeMoo() external {
        // Only claimable after game starts
        if (block.timestamp < gameStart) revert TooEarly();

        // Only users who have pre purchased can claim
        if (!hasUserPrepurchased[msg.sender]) revert DumbMove();

        // Cannot claim twice
        if (hasUserClaimedFreeMooTokens[msg.sender]) revert DumbMove();

        hasUserClaimedFreeMooTokens[msg.sender] = true;

        // 10 free moo!
        spyNFT.updateUserGooBalance(msg.sender, 10e18, GooBalanceUpdateType.INCREASE);
    }

    /// @notice Buys a spy with ETH, pricing exponentially increases once game starts
    function purchaseSpy() external payable returns (uint256 spyId) {
        // Don't be cheap
        if (msg.value < spyPriceETH(msg.sender)) revert TooPoor();

        // Only can purchase 1 spy pre game start
        if (block.timestamp < gameStart) {
            // Revert if user has purchased
            if (hasUserPrepurchased[msg.sender]) revert NoWhales();

            // Set purchased
            hasUserPrepurchased[msg.sender] = true;
        } else if (block.timestamp >= gameStart) {
            // Add purchase count
            userPurchasesOnDay[msg.sender][uint256(toDaysWadUnsafe(block.timestamp - gameStart) / 1e18)]++;
        }

        MULTISIG.call{value: msg.value}("");

        spyId = spyNFT.mint(msg.sender, block.timestamp > gameStart ? block.timestamp : gameStart);

        unchecked {
            emit SpyMinted(msg.sender, spyId);
        }
    }

    /// @notice Mints a Spy using Moolah
    function mintSpyFromMoolah(uint256 _maxPrice) external returns (uint256 spyId) {
        // If game has not begun, revert
        if (block.timestamp < gameStart) revert TooEarly();

        // No need to check if we're at MAX_MINTABLE
        // spyPrice() will revert once we reach it due to its
        // logistic nature. It will also revert prior to the mint start
        uint256 currentPrice = spyPrice();

        // If the current price is above the user's specified max, revert
        if (currentPrice > _maxPrice) revert TooPoor();

        // Decrement the user's goo by the ERC20 balance
        spyNFT.updateUserGooBalance(msg.sender, currentPrice, GooBalanceUpdateType.DECREASE);

        spyId = spyNFT.mint(msg.sender, block.timestamp > gameStart ? block.timestamp : gameStart);

        unchecked {
            ++spiesMintedFromMoo; // Overflow should be impossible due to the supply cap
            emit SpyPurchased(msg.sender, spyId, currentPrice);
        }
    }

    /// @notice Mints a Knife using Moolah
    function mintKnifeFromMoolah(uint256 _maxPrice) external returns (uint256 knifeId) {
        // If game has not begun, revert
        if (block.timestamp < gameStart) revert TooEarly();

        // No need to check if we're at MAX_MINTABLE
        // spyPrice() will revert once we reach it due to its
        // logistic nature. It will also revert prior to the mint start
        uint256 currentPrice = knifePrice();

        // If the current price is above the user's specified max, revert
        if (currentPrice > _maxPrice) revert TooPoor();

        // Decrement the user's goo by the virtual balance or ERC20 balance
        spyNFT.updateUserGooBalance(msg.sender, currentPrice, GooBalanceUpdateType.DECREASE);

        knifeId = knifeNFT.mint(msg.sender);

        unchecked {
            ++knivesMintedFromMoo; // Overflow should be impossible due to the supply cap
            emit KnifePurchased(msg.sender, knifeId, currentPrice);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          Pricing Logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Spy pricing in terms of ETH
    /// @dev Allows people to buy Spies after the game has started
    ///      but disincentivies them to do so as it gets exponentially more expensive once the game starts
    /// @return Current price of a spy in terms of ETH for a particular user
    function spyPriceETH(address _user) public view returns (uint256) {
        // If the game hasn't started, its a flat rate
        if (block.timestamp < gameStart) return INITIAL_PURCHASE_SPY_ETH_PRICE;

        // How many days since game started, and how many spies have user *purchased* on this day
        uint256 daysSinceGameStarted = uint256(toDaysWadUnsafe(block.timestamp - gameStart) / 1e18);
        uint256 userPurchased = userPurchasesOnDay[_user][daysSinceGameStarted];

        // Magic algorithm
        uint256 priceIncrease = 0;
        for (uint256 i = 0; i < userPurchased; i++) {
            if (priceIncrease == 0) {
                priceIncrease = INITIAL_PURCHASE_SPY_ETH_PRICE;
            }

            priceIncrease = priceIncrease * 2;
        }

        return INITIAL_PURCHASE_SPY_ETH_PRICE + priceIncrease;
    }

    /// @notice Spy pricing in terms of moolah.
    /// @dev Will revert if called before minting starts
    /// or after all gobblers have been minted via VRGDA.
    /// @return Current price of a gobbler in terms of goo.
    function spyPrice() public view returns (uint256) {
        // We need checked math here to cause underflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - gameStart;
        return spyLVRGDA.getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), spiesMintedFromMoo);
    }

    /// @notice Knife pricing in terms of moolah.
    /// @dev Will revert if called before minting starts
    /// or after all gobblers have been minted via VRGDA.
    /// @return Current price of a gobbler in terms of goo.
    function knifePrice() public view returns (uint256) {
        // We need checked math here to cause underflow
        // before minting has begun, preventing mints.
        uint256 timeSinceStart = block.timestamp - (gameStart + 12 hours);
        return knifeLVRGDA.getVRGDAPrice(toDaysWadUnsafe(timeSinceStart), knivesMintedFromMoo);
    }

    /*//////////////////////////////////////////////////////////////
                          Add/Remove GOO Logic
    //////////////////////////////////////////////////////////////*/

    // /// @notice Add goo to your emission balance,
    // /// burning the corresponding ERC20 balance.
    // /// @param _mooAmount The amount of moo to add.
    // function addMoo(uint256 _mooAmount) external {
    //     // Burn goo being added to gobbler.
    //     moo.burn(msg.sender, _mooAmount);

    //     // Increase msg.sender's virtual goo balance.
    //     spyNFT.updateUserGooBalance(msg.sender, _mooAmount, GooBalanceUpdateType.INCREASE);
    // }

    // /// @notice Remove goo from your emission balance, and
    // /// add the corresponding amount to your ERC20 balance.
    // /// @param _mooAmount The amount of moo to remove.
    // function removeMoo(uint256 _mooAmount) external {
    //     // Decrease msg.sender's virtual goo balance.
    //     spyNFT.updateUserGooBalance(msg.sender, _mooAmount, GooBalanceUpdateType.DECREASE);

    //     // Mint the corresponding amount of ERC20 goo.
    //     moo.mint(msg.sender, _mooAmount);
    // }

    /*//////////////////////////////////////////////////////////////
                          Game Logic
    //////////////////////////////////////////////////////////////*/

    function killSpy(uint256 _knifeId, uint256 _spyId) public {
        // Make sure user owns the knife
        if (knifeNFT.ownerOf(_knifeId) != msg.sender) revert NotOwner();

        // Cannot kill burn address
        if (spyNFT.ownerOf(_spyId) == BURN_ADDRESS) revert DumbMove();

        // Literally retarded
        if (knifeNFT.ownerOf(_knifeId) == spyNFT.ownerOf(_spyId)) {
            revert DumbMove();
        }

        knifeNFT.sudoTransferFrom(msg.sender, BURN_ADDRESS, _knifeId);

        address victim = spyNFT.ownerOf(_spyId);
        spyNFT.sudoTransferFrom(victim, BURN_ADDRESS, _spyId);

        emit SpyKilled(msg.sender, victim, _knifeId, _spyId);
    }

    // For world chat functionality
    function shout(string calldata message) external payable {
        if (msg.value < 0.05e18) revert TooPoor();

        SHOUTS_FUNDS_RECIPIENT.call{value: msg.value}("");

        if (bytes(message).length > 256) {
            emit Shouted(msg.sender, string(message[:256]));
        } else {
            emit Shouted(msg.sender, message);
        }
    }
}