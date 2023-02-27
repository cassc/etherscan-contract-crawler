// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IReserve.sol";
import "./IFrankencoin.sol";
import "./Ownable.sol";
import "./IPosition.sol";

/**
 * A hub for creating collateralized minting positions for a given collateral.
 */
contract MintingHub {

    uint256 public constant OPENING_FEE = 1000 * 10**18;

    uint32 public constant BASE = 1000_000;
    uint32 public constant CHALLENGER_REWARD = 20000; // 2%

    IPositionFactory private immutable POSITION_FACTORY; // position contract to clone

    IFrankencoin public immutable zchf; // currency
    Challenge[] public challenges;
    mapping (address => mapping (address => uint256)) public pendingReturns;

    struct Challenge {
        address challenger;
        IPosition position;
        uint256 size;
        uint256 end;
        address bidder;
        uint256 bid;
    }

    event ChallengeStarted(address indexed challenger, address indexed position, uint256 size, uint256 number);
    event ChallengeAverted(address indexed position, uint256 number);
    event ChallengeSucceeded(address indexed position, uint256 bid, uint256 number);
    event NewBid(uint256 challengedId, uint256 bidAmount, address bidder);

    constructor(address _zchf, address factory) {
        zchf = IFrankencoin(_zchf);
        POSITION_FACTORY = IPositionFactory(factory);
    }

    /**
     * @notice open a collateralized loan position
     * @param _collateralAddress        address of collateral token
     * @param _minCollateral     minimum collateral required to prevent dust amounts
     * @param _initialCollateral amount of initial collateral to be deposited
     * @param _mintingMaximum    maximal amount of ZCHF that can be minted by the position owner
     * @param _expirationSeconds position tenor in unit of timestamp (seconds) from 'now'
     * @param _challengeSeconds  challenge period. Longer for less liquid collateral.
     * @param _mintingFeePPM     percentage minting fee that will be added to reserve,
     *                           basis 1000_000
     * @param _liqPrice          Liquidation price with (36 - token decimals) decimals,
     *                           e.g. 18 decimals for an 18 decimal token, 36 decimals for a 0 decimal token.
     * @param _reservePPM        percentage reserve amount that is added as the
     *                           borrower's stake into reserve, basis 1000_000
     * @return address of resulting position
     */
    function openPosition(
        address _collateralAddress, uint256 _minCollateral, uint256 _initialCollateral,
        uint256 _mintingMaximum, uint256 _expirationSeconds, uint256 _challengeSeconds,
        uint32 _mintingFeePPM, uint256 _liqPrice, uint32 _reservePPM) public returns (address) {
        IPosition pos = IPosition(
            POSITION_FACTORY.createNewPosition(
                msg.sender,
                address(zchf),
                _collateralAddress,
                _minCollateral,
                _initialCollateral,
                _mintingMaximum,
                _expirationSeconds,
                _challengeSeconds,
                _mintingFeePPM,
                _liqPrice,
                _reservePPM
            )
        );
        zchf.registerPosition(address(pos));
        zchf.transferFrom(msg.sender, address(zchf.reserve()), OPENING_FEE);
        IERC20(_collateralAddress).transferFrom(msg.sender, address(pos), _initialCollateral);

        return address(pos);
    }

    modifier validPos(address position) {
        require(zchf.isPosition(position) == address(this), "not our pos");
        _;
    }


    function clonePosition(address position, uint256 _initialCollateral, uint256 _initialMint) public validPos(position) returns (address) {
        IPosition existing = IPosition(position);
        uint256 limit = existing.reduceLimitForClone(_initialMint);
        address pos = POSITION_FACTORY.clonePosition(position);
        zchf.registerPosition(pos);
        existing.collateral().transferFrom(msg.sender, address(pos), _initialCollateral);
        IPosition(pos).initializeClone(msg.sender, existing.price(), limit, _initialCollateral, _initialMint);
        return address(pos);
    }

    function reserve() external view returns (IReserve) {
        return IReserve(zchf.reserve());
    }

    /**
     * @notice Launch a challenge on a position
     * @param _positionAddr      address of the position we want to challenge
     * @param _collateralAmount  size of the collateral we want to challenge (dec 18)
     * @return index of the challenge in challenge-array
     */
    function launchChallenge(address _positionAddr, uint256 _collateralAmount) external validPos(_positionAddr) returns (uint256) {
        IPosition position = IPosition(_positionAddr);
        IERC20(position.collateral()).transferFrom(msg.sender, address(this), _collateralAmount);
        uint256 pos = challenges.length;
        /*
        struct Challenge {address challenger;IPosition position;uint256 size;uint256 end;address bidder;uint256 bid;
        */
        challenges.push(Challenge(msg.sender, position, _collateralAmount, block.timestamp + position.challengePeriod(), address(0x0), 0));
        position.notifyChallengeStarted(_collateralAmount);
        emit ChallengeStarted(msg.sender, address(position), _collateralAmount, pos);
        return pos;
    }

    function splitChallenge(uint256 _challengeNumber, uint256 splitOffAmount) external returns (uint256) {
        Challenge storage challenge = challenges[_challengeNumber];
        require(challenge.challenger != address(0x0));
        Challenge memory copy = Challenge(
            challenge.challenger,
            challenge.position,
            splitOffAmount,
            challenge.end,
            challenge.bidder,
            (challenge.bid * splitOffAmount) / challenge.size
        );
        challenge.bid -= copy.bid;
        challenge.size -= copy.size;

        uint256 min = IPosition(challenge.position).minimumCollateral();
        require(challenge.size >= min);
        require(copy.size >= min);

        uint256 pos = challenges.length;
        challenges.push(copy);
        emit ChallengeStarted(challenge.challenger, address(challenge.position), challenge.size, _challengeNumber);
        emit ChallengeStarted(copy.challenger, address(copy.position), copy.size, pos);
        return pos;
    }

    function minBid(uint256 challenge) public view returns (uint256) {
        return minBid(challenges[challenge]);
    }

    function minBid(Challenge storage challenge) internal view returns (uint256) {
        return (challenge.bid * 1005) / 1000; // should be at least 0.5% higher
    }

    /**
     * @notice Post a bid (ZCHF amount) for an existing challenge (given collateral amount)
     * @param _challengeNumber   index of the challenge in the challenges array
     * @param _bidAmountZCHF     how much to bid for the collateral of this challenge (dec 18)
     */
    function bid(uint256 _challengeNumber, uint256 _bidAmountZCHF, uint256 expectedSize) external {
        Challenge storage challenge = challenges[_challengeNumber];
        if (block.timestamp >= challenge.end) {
            // if bid is too late, the transaction ends the challenge
            end(_challengeNumber, false);
        } else {
            require(expectedSize == challenge.size, "s");
            if (challenge.bid > 0) {
                zchf.transfer(challenge.bidder, challenge.bid); // return old bid
            }
            emit NewBid(_challengeNumber, _bidAmountZCHF, msg.sender);
            if (challenge.position.tryAvertChallenge(challenge.size, _bidAmountZCHF)) {
                // bid above Z_B/C_C >= (1+h)Z_M/C_M, challenge averted, end immediately by selling challenger collateral to bidder
                zchf.transferFrom(msg.sender, challenge.challenger, _bidAmountZCHF);
                challenge.position.collateral().transfer(msg.sender, challenge.size);
                emit ChallengeAverted(address(challenge.position), _challengeNumber);
                delete challenges[_challengeNumber];
            } else {
                require(_bidAmountZCHF >= minBid(challenge), "below min bid");
                uint256 earliestEnd = block.timestamp + 30 minutes;
                if (earliestEnd >= challenge.end) {
                    // bump remaining time to 10 minutes if we are near the end of the challenge
                    challenge.end = earliestEnd;
                }
                require(challenge.size * challenge.position.price() > _bidAmountZCHF * 10**18, "whot");
                zchf.transferFrom(msg.sender, address(this), _bidAmountZCHF);
                challenge.bid = _bidAmountZCHF;
                challenge.bidder = msg.sender;
            }
        }
    }

    /**
     * @notice
     * Ends a challenge successfully after the auction period ended.
     *
     * Example: A challenged position had 1000 ABC tokens as collateral with a minting limit of 200,000 ZCHF, out
     * of which 60,000 have been minted and thereof 15,000 used to buy reserve tokens. The challenger auctioned off
     * 400 ABC tokens, challenging 40% of the position. The highest bid was 75,000 ZCHF, below the
     * 40% * 200,000 = 80,000 ZCHF needed to avert the challenge. The reserve ratio of the position is 25%.
     *
     * Now, the following happens when calling this method:
     * - 400 ABC from the position owner are transferred to the bidder
     * - The challenger's 400 ABC are returned to the challenger
     * - 40% of the reserve bought with the 15,000 ZCHF is sold off (approximately), yielding e.g. 5,600 ZCHF
     * - 40% * 60,000 = 24,000 ZCHF are burned
     * - 80,000 * 2% = 1600 ZCHF are given to the challenger as a reward
     * - 40% * (100%-25%) * (200,000 - 60,000) = 42,000 are given to the position owner for selling off unused collateral
     * - The remaining 75,000 + 5,600 - 1,600 - 24,000 - 42,000 = 13,000 ZCHF are sent to the reserve pool
     *
     * If the highest bid was only 60,000 ZCHF, then we would have had a shortfall of 2,000 ZCHF that would in the
     * first priority be covered by the reserve and in the second priority by minting unbacked ZCHF, triggering a
     * balance alert.
     * @param _challengeNumber  number of the challenge in challenge-array
     */
    function end(uint256 _challengeNumber) external {
        end(_challengeNumber, false);
    }

    function isChallengeOpen(uint256 _challengeNumber) external view returns (bool) {
        return challenges[_challengeNumber].end > block.timestamp;
    }

    /**
     * @dev internal end function
     * @param _challengeNumber  number of the challenge in challenge-array
     */
    function end(uint256 _challengeNumber, bool postponeCollateralReturn) public {
        Challenge storage challenge = challenges[_challengeNumber];
        require(block.timestamp >= challenge.end, "period has not ended");
        // challenge must have been successful, because otherwise it would have immediately ended on placing the winning bid
        returnCollateral(challenge, postponeCollateralReturn);
        // notify the position that will send the collateral to the bidder. If there is no bid, send the collateral to msg.sender
        address recipient = challenge.bidder == address(0x0) ? msg.sender : challenge.bidder;
        (address owner, uint256 effectiveBid, uint256 volume, uint256 repayment, uint32 reservePPM) = challenge.position.notifyChallengeSucceeded(recipient, challenge.bid, challenge.size);
        if (effectiveBid < challenge.bid) {
            // overbid, return excess amount
            IERC20(zchf).transfer(challenge.bidder, challenge.bid - effectiveBid);
        }
        uint256 reward = (volume * CHALLENGER_REWARD) / BASE;
        uint256 fundsNeeded = reward + repayment;
        if (effectiveBid > fundsNeeded){
            zchf.transfer(owner, effectiveBid - fundsNeeded);
        } else if (effectiveBid < fundsNeeded){
            zchf.notifyLoss(fundsNeeded - effectiveBid); // ensure we have enough to pay everything
        }
        zchf.transfer(challenge.challenger, reward); // pay out the challenger reward
        zchf.burn(repayment, reservePPM); // Repay the challenged part
        emit ChallengeSucceeded(address(challenge.position), challenge.bid, _challengeNumber);
        delete challenges[_challengeNumber];
    }

    function returnPostponedCollateral(address collateral, address target) external {
        uint256 amount = pendingReturns[collateral][msg.sender];
        delete pendingReturns[collateral][msg.sender];
        IERC20(collateral).transfer(target, amount);
    }

    function returnCollateral(Challenge storage challenge, bool postpone) internal {
        if (postpone){
            // Postponing helps in case the challenger was blacklisted on the collateral token or otherwise cannot receive it at the moment.
            pendingReturns[address(challenge.position.collateral())][challenge.challenger] += challenge.size;
        } else {
            challenge.position.collateral().transfer(challenge.challenger, challenge.size); // return the challenger's collateral
        }
    }
}

interface IPositionFactory {
    function createNewPosition(
        address _owner,
        address _zchf,
        address _collateral,
        uint256 _minCollateral,
        uint256 _initialCollateral,
        uint256 _initialLimit,
        uint256 _duration,
        uint256 _challengePeriod,
        uint32 _mintingFeePPM,
        uint256 _liqPrice,
        uint32 _reserve
    ) external returns (address);

    function clonePosition(address _existing) external returns (address);
}