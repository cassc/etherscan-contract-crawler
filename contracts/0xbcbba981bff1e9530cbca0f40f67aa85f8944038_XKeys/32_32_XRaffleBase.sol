// #region Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
// #endregion

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../utils/DelegateUtils.sol";
import "./XKeyVRFInterface.sol";
import "../base/XNFTRoyaltyBase.sol";
import "./XCrates.sol";

// #region Errors
error AlreadyMinted();
error RoundMustBeClosed();
error NFTOwnershipMissing(address nftContract);
error InsufficientBalance();
error NotAnNFTContract(address nftContract);
error ExceedsMaxSupply();
error CannotResetReward();
error RewardExpired();
error RewardNotExpired();
error YouDidNotWin();
error InvalidRaffleStage();
error NoWinningToken();
error CrateMustBeLocked();
error CrateAlreadyOpened();
error SupplyTooSmall();
error RoundPoolTooSmall();
error InvalidRound();
error RoundTokenPoolEmpty();
error MintRequestStateMismatch();
error CannotRedrawUnwonCrate();

// #endregion

contract XRaffleBase is XCrates, XKeyVRFInterface, XNFTRoyaltyBase, DelegateUtils {
    using SafeCast for uint256;

    struct Raffle {
        address requiredOwnership; // 20 bytes
        uint16 id; // 2 bytes
        uint16 supply; // 2 bytes
        uint16 supplyLeft; // 2 bytes
        uint16 startTokenId; // 2 bytes
        RaffleStage stage; // 1 byte
    }

    enum MintStatus {
        None,
        Pending,
        Fulfilled,
        Rejected,
        SupplyExceeded,
        UsedAsVault,
        UsedAsDelegate
    }

    enum RaffleStage {
        None,
        Open,
        Closed,
        WinnerDrawn,
        RewardClaimed
    }

    // the number of seconds after which the reward can be claimed
    uint64 private immutable CLAIM_DEADLINE;

    // the timestamp beyond which the reward can not be claimed
    uint64 public nextClaimDeadline;

    // the current raffle round
    uint8 public roundId;

    mapping(uint8 roundId => address) public roundWinners;

    mapping(uint8 roundId => uint16 tokenId) private _roundWinningToken;

    mapping(uint8 roundId => Raffle) public raffles;

    // the status of a minter address in each raffle round
    mapping(uint8 roundId => mapping(address minter => MintStatus)) public raffleMinters;

    // the pool of tokens for each round
    mapping(uint8 roundId => uint16[] tokenId) public roundTokenPool;

    // #region Events
    event RoundCreated(
        uint16 indexed roundId,
        address indexed requiredOwnership,
        uint16 supply
    );
    event RoundClosed(uint16 indexed roundId);
    event WinnerDrawn(RequestType indexed _type, uint16 indexed id);
    event RewardClaimed(
        uint16 indexed roundId,
        uint16 indexed tokenId,
        address indexed winner
    );

    event MintRequested(uint16 indexed roundId, address indexed minter);
    event MintDecision(uint16 indexed roundId, address indexed minter, bool isApproved);
    event CrateUnlocked(uint16 indexed crateId, address indexed winner);
    event WinningToken(uint256 tokenId);

    // #endregion

    // #region Modifiers
    modifier notMintedInRound(uint8 _roundId, address minter) {
        // must mint once per round
        _checkNotMintedInRound(_roundId, minter);
        _;
    }

    // #endregion

    constructor(
        string memory name,
        string memory symbol,
        uint96 royalty,
        address receiver,
        address vrfCoordinator,
        uint64 vrfSubscriptionId,
        bytes32 vrfKeyHash,
        address delegateRegistryAddress,
        uint64 claimDeadline
    )
        payable
        XKeyVRFInterface(vrfCoordinator, vrfSubscriptionId, vrfKeyHash)
        XNFTRoyaltyBase(name, symbol, royalty, receiver)
        DelegateUtils(delegateRegistryAddress)
    {
        CLAIM_DEADLINE = claimDeadline;
    }

    // #region External functions

    // function hasMintedInThisRound(address minter) external view returns (bool) {
    //     return _hasMintedInRound(minter, roundId);
    // }

    // function currentRaffle() external view returns (Raffle memory) {
    //     return raffles[roundId];
    // }

    function checkCanOpenCrate(
        uint16 _crateId,
        address minter
    ) external view returns (bool) {
        uint16 tokenId = crateWinningToken[_crateId];
        bool canOpen = _exists(tokenId) && ownerOf(crateWinningToken[_crateId]) == minter;
        if (canOpen) {
            address _mustOwn = crates[_crateId].requiredOwnership;
            if (_mustOwn != address(0)) {
                // check that the claimant owns the required token
                if (IERC721(_mustOwn).balanceOf(minter) < 1) {
                    canOpen = false;
                }
            }
        }

        return canOpen;
    }

    // function balancesOf(
    //     address[] calldata addresses
    // ) external view returns (uint256[] memory) {
    //     uint256[] memory balances = new uint256[](addresses.length);

    //     for (uint256 i = 0; i < addresses.length; i++) {
    //         balances[i] = balanceOf(addresses[i]);
    //     }
    //     return balances;
    // }

    function claimReward(uint8 _roundId) external {
        _claimRewardInternal(_roundId, msg.sender);
    }

    function openCrate(uint16 _crateId) external {
        _openCrateInternal(_crateId, msg.sender);
    }

    function drawWinner(RequestType _type, uint16 id) external payable onlyOwner {
        _drawWinnerInternal(_type, id);
    }

    function resetWinnerWhenRewardExpires() external payable onlyOwner {
        // the reward must have a winner selected
        uint8 _roundId = roundId;
        if (raffles[_roundId].stage != RaffleStage.WinnerDrawn) {
            revert CannotResetReward();
        }

        // the time for claiming the reward must have passed
        if (!isRewardExpired()) {
            revert RewardNotExpired();
        }

        // reset the winner
        _roundWinningToken[_roundId] = 0;

        // draw a random winner
        requestWinningTokenForRound(_roundId);
    }

    /**
     * @notice Release a new X-Crate, which can be opened by holders of a specific NFT and/or an X-Key from a specific round
     * @param forRound The round for which the crate is released (0 - for all rounds)
     * @param requiredOwnership The address of the NFT contract which must be owned to open the crate (address(0) - removes the requirement)
     */
    function releaseCrate(
        uint8 forRound,
        address requiredOwnership
    ) external payable onlyOwner {
        if (requiredOwnership != address(0)) {
            // the contract must be an ERC721 contract
            if (!_isNFTContract(requiredOwnership)) {
                revert NotAnNFTContract(requiredOwnership);
            }
        }

        // if the crate is only for a specific round
        if (forRound > 0) {
            // no crates can be created for a round in the future
            if (forRound > roundId) {
                revert InvalidRound();
            }

            // revert if there are no tokens in the round pool
            if (roundTokenPool[forRound].length == 0) {
                revert RoundTokenPoolEmpty();
            }

            // prevent creating a crate for a round
            // if so many keys have been burned, that less than 2 are left
            if (!_checkEnoughTokensInRoundPool(forRound)) {
                revert RoundPoolTooSmall();
            }
        } else {
            // ensure that enough supply is left for a crate
            if (totalSupply() < 2) {
                revert SupplyTooSmall();
            }
        }

        _setupCrate(forRound, requiredOwnership);
    }

    function tokenPoolOfRound(uint8 _roundId) external view returns (uint16[] memory) {
        return roundTokenPool[_roundId];
    }

    function checkWin(uint8 _roundId, address minter) external view returns (bool) {
        return _checkWinInternal(_roundId, minter);
    }

    // #endregion

    // #region Public functions

    function isRewardExpired() public view returns (bool) {
        // when nextClaimDeadline is 0 initially or when reward is claimed
        // the timestamp will always be greater than nextClaimDeadline
        // therefore the reward is always expired except when after the draw
        return block.timestamp > nextClaimDeadline;
    }

    // #endregion

    // #region Internal functions

    function _isNFTContract(address contractAddress) internal view returns (bool) {
        // check if the contract supports the ERC721 interface
        return IERC721(contractAddress).supportsInterface(0x80ac58cd);
    }

    function _checkNotMintedInRound(uint8 _roundId, address minter) internal view {
        if (raffleMinters[_roundId][minter] != MintStatus.None) {
            revert AlreadyMinted();
        }
    }

    function _checkWinInternal(
        uint8 _roundId,
        address winner
    ) internal view returns (bool) {
        uint16 tokenId = _roundWinningToken[_roundId];
        return _exists(tokenId) && ownerOf(tokenId) == winner;
    }

    function _adjustWinnerForBurnedTokens(
        uint256 tokenId,
        uint256 rangeLimit
    ) internal view returns (uint256) {
        // if the token selected has been burned,
        // select the previous token and wrap around if necessary
        while (!_exists(tokenId)) {
            unchecked {
                if (tokenId > 1) {
                    --tokenId;
                } else {
                    // loop back to the end of the range
                    tokenId = rangeLimit;
                }
            }
        }

        return tokenId;
    }

    /**
     * @dev iterate over the supply to find an unburned winning token based on the Chainlink VRF random number
     * @param vrfWord the random number returned by Chainlink
     */
    function _getWinningTokenFromSupply(uint256 vrfWord) internal view returns (uint256) {
        // @dev randomWord % _totalMinted() will give a number between 0 and _totalMinted().
        // However, startTokenId is 1 and the modulus will give (totalMinted - 1) as the maximum value selected,
        // therefore adding 1 to the result will give a number between 1 and _totalMinted() inclusive
        uint256 mintCount = _totalMinted();

        uint256 winningToken = _adjustWinnerForBurnedTokens(
            (vrfWord % mintCount) + 1,
            mintCount
        );

        return winningToken;
    }

    function _mintInRaffle(
        uint8 _roundId
    ) internal notMintedInRound(_roundId, msg.sender) {
        // minting this token must not exceed the max supply for the round
        if (raffles[_roundId].supplyLeft == 0) {
            revert ExceedsMaxSupply();
        }

        // must own the required NFT
        _checkOwnsNFT(raffles[_roundId].requiredOwnership, msg.sender);

        // add the minter to the round minters
        raffleMinters[_roundId][msg.sender] = MintStatus.Pending;

        emit MintRequested(_roundId, msg.sender);
    }

    function _mintInRaffleDelegated(
        address vault,
        address to,
        uint8 _roundId
    ) internal notMintedInRound(_roundId, vault) {
        // add the receiver to the round minters
        raffleMinters[_roundId][to] = MintStatus.Pending;
        // mark the vault as used
        if (vault != to) {
            raffleMinters[_roundId][vault] = MintStatus.UsedAsVault;
        }
        if (msg.sender != to) {
            raffleMinters[_roundId][msg.sender] = MintStatus.UsedAsDelegate;
        }

        // minting this token must not exceed the max supply for the round
        // if (raffleTokenPool[_roundId].length + 1 > raffle.supply) {
        if (raffles[_roundId].supplyLeft == 0) {
            revert ExceedsMaxSupply();
        }

        // check the delegation registry to see if the msg.sender is delegated by the vault
        address requiredOwnership = raffles[_roundId].requiredOwnership;
        _checkDelegation(vault, requiredOwnership);

        // must own the required NFT
        _checkOwnsNFT(requiredOwnership, vault);

        emit MintRequested(_roundId, to);
    }

    /**
     * @dev This is the function that Chainlink VRF node calls
     */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        RequestType _type = vrfRequests[requestId];
        if (_type == RequestType.Raffle) {
            // handle winner being picked for a raffle

            // select a winner from the existing tokens in supply
            uint256 winningToken = _getWinningTokenFromSupply(randomWords[0]);

            // set the winning token for the round
            _recordRoundWinner(roundId, uint16(winningToken));
        } else if (_type == RequestType.XCrate) {
            // read crate in memory

            // XCrate memory crate = crates[vrfIdToCrateId[requestId]];
            uint16 _crateId = vrfIdToCrateId[requestId];
            uint8 forRound = crates[_crateId].forRound;

            uint256 winningToken;

            // if the crate is only openable by keys in a given round
            if (forRound > 0) {
                // read the token pool size
                uint16[] memory pool = roundTokenPool[forRound];
                uint256 poolSize = pool.length;

                uint256 indexOfWinToken = randomWords[0] % poolSize;

                // in case of any burned tokens, search for the previous token
                // and wrap around if necessary
                while (!_exists(pool[indexOfWinToken])) {
                    unchecked {
                        if (indexOfWinToken > 0) {
                            --indexOfWinToken;
                        } else {
                            // loop back to the end of the array
                            indexOfWinToken = poolSize - 1;
                        }
                    }
                }
                // set the winning token
                winningToken = pool[indexOfWinToken];
            } else {
                // pick a random token from the entire supply
                winningToken = _getWinningTokenFromSupply(randomWords[0]);
            }

            // set the winning token for the crate
            _recordCrateWinner(_crateId, uint16(winningToken));
        } else {
            revert InvalidVRFRequestType();
        }
    }

    function _drawWinnerInternal(RequestType _type, uint16 id) internal {
        if (_type == RequestType.Raffle) {
            uint8 raffleId = SafeCast.toUint8(id);
            if (raffles[raffleId].stage != RaffleStage.Closed) {
                revert RoundMustBeClosed();
            }

            if (roundTokenPool[raffleId].length == 0) {
                revert NoWinningToken();
            }

            // draw a random winner
            requestWinningTokenForRound(raffleId);
        } else if (_type == RequestType.XCrate) {
            // @dev crates winners can be drawn, after which the winner has a certain amount of time
            // to open the crate, otherwise the crate expires and a new winner can be drawn

            // check for an expired crate
            uint256 expires = crates[id].expires;
            if (expires > 0 && expires > block.timestamp) {
                // the crate has expired
                // check that the crate is in a state where a new winner can be drawn
                if (crates[id].state != CrateState.WinnerDrawn) {
                    revert CannotRedrawUnwonCrate();
                }
                // continue to draw a new winner
            } else {
                // crate has no expiration or has not expired
                // check that the crate is locked
                if (crates[id].state != CrateState.Locked) {
                    revert CrateMustBeLocked();
                }
            }

            requestWinnerForCrate(id);
        }
    }

    function _recordRoundWinner(uint8 _roundId, uint16 tokenId) internal {
        awaitingWinnerForRound = 0;

        // set the winning token
        _roundWinningToken[_roundId] = tokenId;

        // set the raffle stage
        raffles[_roundId].stage = RaffleStage.WinnerDrawn;

        // set the deadline for claiming the reward
        nextClaimDeadline = SafeCast.toUint64(block.timestamp + CLAIM_DEADLINE);

        emit WinningToken(tokenId);

        // the omission of the winning token is intentional
        emit WinnerDrawn(RequestType.Raffle, _roundId);
    }

    function _recordCrateWinner(uint16 _crateId, uint16 tokenId) internal {
        // reset the crate state
        awaitingWinnerForCrate = 0;

        // store the winning token
        crateWinningToken[_crateId] = tokenId;

        // set the crate state
        if (crates[_crateId].state != CrateState.WinnerDrawn) {
            // set the crate state
            crates[_crateId].state = CrateState.WinnerDrawn;
        }

        // set the deadline for claiming the reward
        crates[_crateId].expires = SafeCast.toUint64(block.timestamp + CLAIM_DEADLINE);

        emit WinningToken(tokenId);

        // emit the event
        emit WinnerDrawn(RequestType.XCrate, _crateId);
    }

    function _claimRewardInternal(uint8 _roundId, address claimant) internal {
        uint16 winningToken = _roundWinningToken[_roundId];
        if (winningToken == 0) {
            revert NoWinningToken();
        }

        if (ownerOf(winningToken) != claimant) {
            revert YouDidNotWin();
        }

        if (isRewardExpired()) {
            revert RewardExpired();
        }

        // set reward as claimed and reset the deadline
        raffles[_roundId].stage = RaffleStage.RewardClaimed;
        nextClaimDeadline = 0;

        // record the winner
        roundWinners[_roundId] = claimant;

        // burn the winning token
        _burn(winningToken);

        // // set the token as burned
        // burnedTokens.set(winningToken);

        emit RewardClaimed(_roundId, winningToken, claimant);
    }

    function _openCrateInternal(uint16 _crateId, address claimant) internal {
        if (balanceOf(claimant) < 1) {
            revert InsufficientBalance();
        }

        uint16 winningToken = crateWinningToken[_crateId];
        if (winningToken == 0) {
            revert NoWinningToken();
        }

        // @dev no need to check if the crate is locked, because the winning token
        // would have been burned and an earlier check would have reverted
        // CrateState state = crates[_crateId].state;
        // if (state == CrateState.Unlocked) {
        //     revert CrateAlreadyOpened();
        // }

        if (ownerOf(winningToken) != claimant) {
            revert YouDidNotWin();
        }

        // check that the opening hasn't expired
        if (block.timestamp > crates[_crateId].expires) {
            revert RewardExpired();
        }

        address _mustOwn = crates[_crateId].requiredOwnership;
        if (_mustOwn != address(0)) {
            // check that the claimant owns the required token
            _checkOwnsNFT(_mustOwn, claimant);
        }

        // burn the winning token
        _burn(winningToken);

        // set crate as unlocked and record the winner
        crates[_crateId].state = CrateState.Unlocked;
        crateWinners[_crateId] = claimant;

        emit CrateUnlocked(_crateId, claimant);
    }

    function _checkEnoughTokensInRoundPool(uint8 _roundId) internal view returns (bool) {
        uint16[] memory pool = roundTokenPool[_roundId];
        uint256 unburned;
        uint256 poolIdx = pool.length - 1;

        // does not overflow
        unchecked {
            do {
                if (_exists(pool[poolIdx])) {
                    ++unburned;
                }

                // at least 2 tokens must be unburned
                if (unburned > 1) {
                    return true;
                }

                --poolIdx;
            } while (poolIdx > 0);
        }
        return false;
    }

    function _checkOwnsNFT(address _erc721, address _owner) internal view {
        if (IERC721(_erc721).balanceOf(_owner) < 1) {
            revert NFTOwnershipMissing(_erc721);
        }
    }

    function _validateMintRequest(
        uint8 _roundId,
        address minter,
        bool approved
    ) internal returns (uint256) {
        if (raffleMinters[_roundId][minter] != MintStatus.Pending) {
            revert MintRequestStateMismatch();
        }

        // total supply for this round
        uint16 _supplyLeft = raffles[_roundId].supplyLeft;

        // update the mint status
        raffleMinters[_roundId][minter] = _supplyLeft < 1
            ? MintStatus.SupplyExceeded
            : approved
            ? MintStatus.Fulfilled
            : MintStatus.Rejected;

        bool _willMint = approved && _supplyLeft > 0;
        if (_willMint) {
            // update the supply left
            unchecked {
                // @dev does not wrap around, because _supplyLeft > 0 in the if statement above
                --_supplyLeft;
                raffles[_roundId].supplyLeft = _supplyLeft;
            }

            // mint an XKey to the minter
            _mint(minter, 1);

            // add the last minted token to the pool
            roundTokenPool[_roundId].push(uint16(_totalMinted()));
        }

        emit MintDecision(_roundId, minter, _willMint);

        return _supplyLeft;
    }

    // #endregion

    // #region Private functions

    // #endregion
}