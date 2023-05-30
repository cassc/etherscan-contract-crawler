// SPDX-License-Identifier: MIT

/*

  by             .__________                 ___ ___
  __  _  __ ____ |__\_____  \  ___________  /   |   \_____    ______ ____
  \ \/ \/ // __ \|  | _(__  <_/ __ \_  __ \/    ~    \__  \  /  ___// __ \
   \     /\  ___/|  |/       \  ___/|  | \/\    Y    // __ \_\___ \\  ___/
    \/\_/  \___  >__/______  /\___  >__|    \___|_  /(____  /____  >\___  >
               \/          \/     \/              \/      \/     \/     \/*/

pragma solidity >=0.8.4 <0.9.0;

import {GameSchema} from './GameSchema.sol';
import {AddressRegistry} from './AddressRegistry.sol';

import {IButtPlug, IChess} from 'interfaces/IGame.sol';
import {IKeep3r, IKeep3rHelper, IPairManager} from 'interfaces/IKeep3r.sol';
import {LSSVMPair, LSSVMPairETH, ILSSVMPairFactory, ICurve, IERC721} from 'interfaces/ISudoswap.sol';
import {ISwapRouter} from 'interfaces/IUniswap.sol';

import {WETH} from 'solmate/tokens/WETH.sol';
import {ERC20} from 'solmate/tokens/ERC20.sol';
import {ERC721} from 'solmate/tokens/ERC721.sol';
import {SafeTransferLib} from 'solmate/utils/SafeTransferLib.sol';
import {FixedPointMathLib} from 'solmate/utils/FixedPointMathLib.sol';

/// @notice Contract will not be audited, proceed at your own risk
/// @dev THE_RABBIT will not be responsible for any loss of funds
contract ButtPlugWars is GameSchema, AddressRegistry, ERC721 {
    using SafeTransferLib for address payable;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            ADDRESS REGISTRY
    //////////////////////////////////////////////////////////////*/

    address public THE_RABBIT;
    address public nftDescriptor;
    address public immutable SUDOSWAP_POOL;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /* IERC721 */
    address public immutable owner;

    /* NFT whitelisting mechanics */
    uint256 public immutable genesis;
    mapping(uint256 => bool) whitelistedToken;

    /*///////////////////////////////////////////////////////////////
                                  SETUP
    //////////////////////////////////////////////////////////////*/

    bool bunnySaysSo;

    uint32 immutable PERIOD;
    uint32 immutable COOLDOWN;

    constructor(
        string memory _name,
        address _masterOfCeremony,
        address _fiveOutOfNine,
        uint32 _period,
        uint32 _cooldown
    ) GameSchema(_fiveOutOfNine) ERC721(_name, unicode'{♙}') {
        THE_RABBIT = _masterOfCeremony;

        PERIOD = _period;
        COOLDOWN = _cooldown;

        // emit token aprovals
        ERC20(WETH_9).approve(SWAP_ROUTER, MAX_UINT);
        ERC20(KP3R_V1).approve(KP3R_LP, MAX_UINT);
        ERC20(WETH_9).approve(KP3R_LP, MAX_UINT);
        ERC20(KP3R_LP).approve(KEEP3R, MAX_UINT);

        // create Keep3r job
        IKeep3r(KEEP3R).addJob(address(this));

        // create Sudoswap pool
        SUDOSWAP_POOL = address(
            ILSSVMPairFactory(SUDOSWAP_FACTORY).createPairETH({
                _nft: IERC721(FIVE_OUT_OF_NINE),
                _bondingCurve: ICurve(SUDOSWAP_CURVE),
                _assetRecipient: payable(address(this)),
                _poolType: LSSVMPair.PoolType.NFT,
                _spotPrice: 59000000000000000, // 0.059 ETH
                _delta: 1,
                _fee: 0,
                _initialNFTIDs: new uint256[](0)
            })
        );

        // set the owner of the ERC721 for royalties
        owner = THE_RABBIT;
        canStartSales = block.timestamp + 2 * PERIOD;

        // mint scoreboard token to itself
        _mint(address(this), 0);
        // records supply of fiveOutOfNine to whitelist pre-genesis tokens
        genesis = ERC20(FIVE_OUT_OF_NINE).totalSupply();
    }

    /// @notice Permissioned method, allows rabbit to cancel or early-finish the event
    function saySo() external onlyRabbit {
        if (state == STATE.ANNOUNCEMENT) state = STATE.CANCELLED;
        else bunnySaysSo = true;
    }

    /// @notice Permissioned method, allows rabbit to revoke all permissions
    function suicideRabbit() external onlyRabbit {
        delete THE_RABBIT;
    }

    /// @notice Handles rabbit authorized methods
    modifier onlyRabbit() {
        if (msg.sender != THE_RABBIT) revert WrongMethod();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            BADGE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the signer to mint a Player NFT, bonding a 5/9 and paying ETH price
    /// @param _tokenId Token ID of the FiveOutOfNine to bond
    /// @return _badgeId Token ID of the minted player badge
    function mintPlayerBadge(uint256 _tokenId) external payable returns (uint256 _badgeId) {
        if (state < STATE.TICKET_SALE || state >= STATE.GAME_OVER) revert WrongTiming();

        if (!isWhitelistedToken(_tokenId)) revert WrongNFT(); // token must be pre-genesis or whitelisted

        uint256 _value = msg.value;
        if (_value < 0.05 ether || _value > 1 ether) revert WrongValue();
        uint256 _weight = _value.sqrt(); // weight is defined by sqrt(msg.value)

        // players can only mint badges from the non-playing team
        TEAM _team = TEAM(((_roundT(block.timestamp, PERIOD) / PERIOD) + 1) % 2);
        // a player cannot be minted for a soon-to-win team
        if (matchesWon[_team] == 4) revert WrongTeam();

        _badgeId = _calcPlayerBadge(_tokenId, _team, _weight);

        // msg.sender must approve the FiveOutOfNine transfer
        ERC721(FIVE_OUT_OF_NINE).safeTransferFrom(msg.sender, address(this), _tokenId);
        _mint(msg.sender, _badgeId); // msg.sender supports ERC721, as it had a 5/9
    }

    /// @notice Allows the signer to register a ButtPlug NFT
    /// @param _buttPlug Address of the buttPlug to register
    /// @return _badgeId Token ID of the minted buttPlug badge
    function mintButtPlugBadge(address _buttPlug) external returns (uint256 _badgeId) {
        if ((state < STATE.TICKET_SALE) || (state >= STATE.GAME_OVER)) revert WrongTiming();

        // buttPlug contract must have an owner view method
        address _owner = IButtPlug(_buttPlug).owner();

        _badgeId = _calcButtPlugBadge(_buttPlug, TEAM.BUTTPLUG);
        _safeMint(_owner, _badgeId);
    }

    /// @notice Allows player to melt badges weight and score into a Medal NFT
    /// @param _badgeIds Array of token IDs of badges to submit
    /// @return _badgeId Token ID of the minted medal badge
    function mintMedal(uint256[] memory _badgeIds) external returns (uint256 _badgeId) {
        if (state != STATE.PREPARATIONS) revert WrongTiming();
        uint256 _totalWeight;
        uint256 _totalScore;

        uint256 _weight;
        uint256 _score;
        bytes32 _salt;
        for (uint256 _i; _i < _badgeIds.length; _i++) {
            _badgeId = _badgeIds[_i];
            (_weight, _score) = _processBadge(_badgeId);
            _totalWeight += _weight;
            _totalScore += _score;
            _salt = keccak256(abi.encodePacked(_salt, _badgeId));
        }

        // adds weight and score to state vars
        totalScore += _totalScore;
        totalWeight += _totalWeight;

        _badgeId = _calcMedalBadge(_totalWeight, _totalScore, _salt);

        emit MedalMinted(_badgeId, _salt, _badgeIds, _totalScore);
        _mint(msg.sender, _badgeId); // msg.sender supports ERC721, as it had a badge
    }

    function _processBadge(uint256 _badgeId) internal returns (uint256 _weight, uint256 _score) {
        TEAM _team = _getBadgeType(_badgeId);
        if (_team > TEAM.BUTTPLUG) revert WrongTeam();

        // if bunny says so, all badges are winners
        if (matchesWon[_team] >= 5 || bunnySaysSo) _weight = _getBadgeWeight(_badgeId);

        // only positive score is accounted
        int256 _badgeScore = _calcScore(_badgeId);
        _score = _badgeScore >= 0 ? uint256(_badgeScore) : 1;

        // msg.sender should be the owner
        transferFrom(msg.sender, address(this), _badgeId);
        _returnNftIfStaked(_badgeId);
    }

    /// @notice Allow players who claimed prize to withdraw their rewards
    /// @param _badgeId Token ID of the medal badge to claim rewards from
    function withdrawRewards(uint256 _badgeId) external onlyBadgeAllowed(_badgeId) {
        if (state != STATE.PRIZE_CEREMONY) revert WrongTiming();
        if (_getBadgeType(_badgeId) != TEAM.MEDAL) revert WrongTeam();

        uint256 _claimableSales = totalSales.mulDivDown(_getMedalScore(_badgeId), totalScore);
        uint256 _claimed = claimedSales[_badgeId];
        uint256 _claimable = _claimableSales - _claimed;

        // liquidity prize should be withdrawn only once per medal
        if (_claimed == 0) {
            ERC20(KP3R_LP).transfer(msg.sender, totalPrize.mulDivDown(_getBadgeWeight(_badgeId), totalWeight));
            claimedSales[_badgeId]++;
        }

        // sales prize can be re-claimed as pool sales increase
        claimedSales[_badgeId] += _claimable;
        payable(msg.sender).safeTransferETH(_claimable);
    }

    /// @notice Allows players who didn't mint a medal to withdraw their staked NFTs
    /// @param _badgeId Token ID of the player badge to withdraw the staked NFT from
    function withdrawStakedNft(uint256 _badgeId) external onlyBadgeAllowed(_badgeId) {
        if (state != STATE.PRIZE_CEREMONY) revert WrongTiming();
        _returnNftIfStaked(_badgeId);
    }

    function _returnNftIfStaked(uint256 _badgeId) internal {
        if (_getBadgeType(_badgeId) < TEAM.BUTTPLUG) {
            uint256 _tokenId = _getStakedToken(_badgeId);
            ERC721(FIVE_OUT_OF_NINE).safeTransferFrom(address(this), msg.sender, _tokenId);
        }
    }

    /// @notice Handles badge authorized methods
    modifier onlyBadgeAllowed(uint256 _badgeId) {
        address _sender = msg.sender;
        address _owner = _ownerOf[_badgeId];
        if (_owner != _sender && !isApprovedForAll[_owner][_sender] && _sender != getApproved[_badgeId]) {
            revert WrongBadge();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            ROADMAP MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice Open method, allows signer to start ticket sale
    function startEvent() external {
        uint256 _timestamp = block.timestamp;
        if ((state != STATE.ANNOUNCEMENT) || (_timestamp < canStartSales)) revert WrongTiming();

        canPushLiquidity = _timestamp + 2 * PERIOD;
        state = STATE.TICKET_SALE;
    }

    /// @notice Open method, allows signer to swap ETH => KP3R, mints kLP and adds to job
    function pushLiquidity() external {
        uint256 _timestamp = block.timestamp;
        if (state >= STATE.GAME_OVER || _timestamp < canPushLiquidity) revert WrongTiming();
        if (state == STATE.TICKET_SALE) {
            state = STATE.GAME_RUNNING;
            canPlayNext = _timestamp + COOLDOWN;
            ++matchNumber;
        }

        uint256 _eth = address(this).balance - totalSales;
        if (_eth < 0.05 ether) revert WrongTiming();
        WETH(WETH_9).deposit{value: _eth}();

        address _keep3rHelper = IKeep3r(KEEP3R).keep3rHelper();
        uint256 _quote = IKeep3rHelper(_keep3rHelper).quote(_eth / 2);

        ISwapRouter.ExactInputSingleParams memory _params = ISwapRouter.ExactInputSingleParams({
            tokenIn: WETH_9,
            tokenOut: KP3R_V1,
            fee: 10_000,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _eth / 2,
            amountOutMinimum: _quote.mulDivDown(95, 100),
            sqrtPriceLimitX96: 0
        });
        ISwapRouter(SWAP_ROUTER).exactInputSingle(_params);

        uint256 wethBalance = ERC20(WETH_9).balanceOf(address(this));
        uint256 kp3rBalance = ERC20(KP3R_V1).balanceOf(address(this));

        uint256 kLPBalance = IPairManager(KP3R_LP).mint(kp3rBalance, wethBalance, 0, 0, address(this));
        IKeep3r(KEEP3R).addLiquidityToJob(address(this), KP3R_LP, kLPBalance);

        totalPrize += kLPBalance;
        canPushLiquidity = _timestamp + PERIOD;
    }

    /// @notice Open method, allows signer (after game ended) to start unbond period
    function unbondLiquidity() external {
        if (state != STATE.GAME_OVER) revert WrongTiming();
        totalPrize = IKeep3r(KEEP3R).liquidityAmount(address(this), KP3R_LP);
        IKeep3r(KEEP3R).unbondLiquidityFromJob(address(this), KP3R_LP, totalPrize);
        state = STATE.PREPARATIONS;
    }

    /// @notice Open method, allows signer (after unbonding) to withdraw all staked kLPs
    function withdrawLiquidity() external {
        if (state != STATE.PREPARATIONS) revert WrongTiming();
        // Method reverts unless 2w cooldown since unbond tx
        IKeep3r(KEEP3R).withdrawLiquidityFromJob(address(this), KP3R_LP, address(this));
        state = STATE.PRIZE_CEREMONY;
    }

    /// @notice Open method, allows signer (after game is over) to reduce pool spotPrice
    function updateSpotPrice() external {
        uint256 _timestamp = block.timestamp;
        if (state <= STATE.GAME_OVER || _timestamp < canUpdateSpotPriceNext) revert WrongTiming();

        canUpdateSpotPriceNext = _timestamp + PERIOD;
        _increaseSudoswapDelta();
    }

    /// @notice Handles Keep3r mechanism and payment
    modifier upkeep(address _keeper) {
        if (!IKeep3r(KEEP3R).isKeeper(_keeper) || ERC20(FIVE_OUT_OF_NINE).balanceOf(_keeper) < matchNumber) {
            revert WrongKeeper();
        }
        _;
        IKeep3r(KEEP3R).worked(_keeper);
    }

    /*///////////////////////////////////////////////////////////////
                            GAME MECHANICS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether the executeMove method could be called
    /// @dev The view function can return true, but still not be workable because of credits
    function workable() external view returns (bool) {
        uint256 _timestamp = block.timestamp;
        if ((state != STATE.GAME_RUNNING) || (_timestamp < canPlayNext)) return false;
        return true;
    }

    /// @notice Called by keepers to execute the next move
    function executeMove() external upkeep(msg.sender) {
        uint256 _timestamp = block.timestamp;
        uint256 _periodStart = _roundT(_timestamp, PERIOD);
        if ((state != STATE.GAME_RUNNING) || (_timestamp < canPlayNext)) revert WrongTiming();

        TEAM _team = TEAM((_periodStart / PERIOD) % 2);
        address _buttPlug = buttPlug[_team];

        if (_buttPlug == address(0)) {
            // if team does not have a buttplug, skip turn
            canPlayNext = _periodStart + PERIOD;
            return;
        }

        uint256 _votes = votes[_team][_buttPlug];
        uint256 _buttPlugBadgeId = _calcButtPlugBadge(_buttPlug, _team);

        int8 _score;
        bool _isCheckmate;

        uint256 _board = IChess(FIVE_OUT_OF_NINE).board();
        // gameplay is wrapped in a try/catch block to punish reverts
        try ButtPlugWars(this).playMove(_board, _buttPlug) {
            uint256 _newBoard = IChess(FIVE_OUT_OF_NINE).board();
            _isCheckmate = _newBoard == CHECKMATE;
            if (_isCheckmate) {
                _score = 3;
                canPlayNext = _periodStart + PERIOD;
            } else {
                _score = _calcMoveScore(_board, _newBoard);
                canPlayNext = _timestamp + COOLDOWN;
            }
        } catch {
            // if buttplug or move reverts
            _score = -2;
            canPlayNext = _periodStart + PERIOD;
        }

        matchScore[_team] += _score;
        score[_buttPlugBadgeId] += _score * int256(_votes);

        // each match is limited to 69 moves
        emit MoveExecuted(_team, _buttPlug, _score, uint64(_votes));
        if (_isCheckmate || ++matchMoves >= 69 || bunnySaysSo) _checkMateRoutine();
    }

    /// @notice Externally called to try catch
    function playMove(uint256 _board, address _buttPlug) external {
        if (msg.sender != address(this)) revert WrongMethod();

        uint256 _move = IButtPlug(_buttPlug).readMove{gas: _getGas()}(_board);
        uint256 _depth = _getDepth(_board, msg.sender);
        IChess(FIVE_OUT_OF_NINE).mintMove(_move, _depth);
    }

    function _checkMateRoutine() internal {
        if (matchScore[TEAM.ZERO] >= matchScore[TEAM.ONE]) matchesWon[TEAM.ZERO]++;
        if (matchScore[TEAM.ONE] >= matchScore[TEAM.ZERO]) matchesWon[TEAM.ONE]++;

        delete matchMoves;
        delete matchScore[TEAM.ZERO];
        delete matchScore[TEAM.ONE];

        // verifies if game has ended
        if (_isGameOver()) {
            state = STATE.GAME_OVER;
            // all remaining ETH will be considered to distribute as sales
            totalSales = address(this).balance;
            canPlayNext = MAX_UINT;
            return;
        }
    }

    function _isGameOver() internal view returns (bool) {
        // if bunny says so, current match was the last one
        return matchesWon[TEAM.ZERO] == 5 || matchesWon[TEAM.ONE] == 5 || bunnySaysSo;
    }

    function _roundT(uint256 _timestamp, uint256 _period) internal pure returns (uint256 _roundTimestamp) {
        _roundTimestamp = _timestamp - (_timestamp % _period);
    }

    /// @notice Adds +2 when eating a black piece, and substracts 1 when a white piece is eaten
    /// @dev Supports having more pieces than before, situation that should not be possible in production
    function _calcMoveScore(uint256 _previousBoard, uint256 _newBoard) internal pure returns (int8 _score) {
        (int8 _whitePiecesBefore, int8 _blackPiecesBefore) = _countPieces(_previousBoard);
        (int8 _whitePiecesAfter, int8 _blackPiecesAfter) = _countPieces(_newBoard);

        _score += 2 * (_blackPiecesBefore - _blackPiecesAfter);
        _score -= _whitePiecesBefore - _whitePiecesAfter;
    }

    /// @dev Efficiently loops through the board uint256 to search for pieces and count each color
    function _countPieces(uint256 _board) internal pure returns (int8 _whitePieces, int8 _blackPieces) {
        uint256 _space;
        for (uint256 i = MAGIC_NUMBER; i != 0; i >>= 6) {
            _space = (_board >> ((i & 0x3F) << 2)) & 0xF;
            if (_space == 0) continue;
            _space >> 3 == 1 ? _whitePieces++ : _blackPieces++;
        }
    }

    function _getGas() internal view returns (uint256 _gas) {
        return BUTT_PLUG_GAS_LIMIT - matchNumber * BUTT_PLUG_GAS_DELTA;
    }

    function _getDepth(uint256 _salt, address _keeper) internal view virtual returns (uint256 _depth) {
        uint256 _timeVariable = _roundT(block.timestamp, COOLDOWN);
        _depth = 3 + uint256(keccak256(abi.encode(_salt, _keeper, _timeVariable))) % 8;
    }

    /*///////////////////////////////////////////////////////////////
                            VOTE MECHANICS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows players to vote for their preferred ButtPlug
    /// @param _buttPlug Address of the buttPlug to vote for
    /// @param _badgeId Token ID of the player badge to vote with
    function voteButtPlug(address _buttPlug, uint256 _badgeId) external {
        if (_buttPlug == address(0)) revert WrongValue();
        _voteButtPlug(_buttPlug, _badgeId);
    }

    /// @notice Allows players to batch vote for their preferred ButtPlug
    /// @param _buttPlug Address of the buttPlug to vote for
    /// @param _badgeIds Array of token IDs of the player badges to vote with
    function voteButtPlug(address _buttPlug, uint256[] memory _badgeIds) external {
        if (_buttPlug == address(0)) revert WrongValue();
        for (uint256 _i; _i < _badgeIds.length; _i++) {
            _voteButtPlug(_buttPlug, _badgeIds[_i]);
        }
    }

    function _voteButtPlug(address _buttPlug, uint256 _badgeId) internal onlyBadgeAllowed(_badgeId) {
        TEAM _team = _getBadgeType(_badgeId);
        if (_team >= TEAM.BUTTPLUG) revert WrongTeam();

        uint256 _weight = _getBadgeWeight(_badgeId);
        uint256 _previousVote = voteData[_badgeId];
        if (_previousVote != 0) {
            votes[_team][_getVoteAddress(_previousVote)] -= _weight;
            score[_badgeId] = _calcScore(_badgeId);
        }

        votes[_team][_buttPlug] += _weight;
        uint256 _voteParticipation = _weight.sqrt().mulDivDown(BASE, votes[_team][_buttPlug].sqrt());
        voteData[_badgeId] = _calcVoteData(_buttPlug, _voteParticipation);

        uint256 _buttPlugBadgeId = _calcButtPlugBadge(_buttPlug, _team);
        lastUpdatedScore[_badgeId][_buttPlugBadgeId] = score[_buttPlugBadgeId];

        emit VoteSubmitted(_team, _badgeId, _buttPlug);
        if (votes[_team][_buttPlug] > votes[_team][buttPlug[_team]]) buttPlug[_team] = _buttPlug;
    }

    /*///////////////////////////////////////////////////////////////
                                ERC721
    //////////////////////////////////////////////////////////////*/

    function onERC721Received(address, address _from, uint256 _id, bytes calldata) external returns (bytes4) {
        // only FiveOutOfNine tokens should be safeTransferred to contract
        if (msg.sender != FIVE_OUT_OF_NINE) revert WrongNFT();
        // if token is newly minted transfer to sudoswap pool
        if (_from == address(0)) {
            whitelistedToken[_id] = true;
            ERC721(FIVE_OUT_OF_NINE).safeTransferFrom(address(this), SUDOSWAP_POOL, _id);
            _increaseSudoswapDelta();
        }

        return 0x150b7a02;
    }

    /// @notice Calculates if the FiveOutOfNine token is whitelisted to play
    /// @param _id Token ID of the enquired FiveOutOfNine
    /// @return _isWhitelisted Whether the token is whitelisted or not
    function isWhitelistedToken(uint256 _id) public view returns (bool _isWhitelisted) {
        return _id < genesis || whitelistedToken[_id];
    }

    function _increaseSudoswapDelta() internal {
        uint128 _currentDelta = LSSVMPair(SUDOSWAP_POOL).delta();
        LSSVMPair(SUDOSWAP_POOL).changeDelta(++_currentDelta);
    }

    /*///////////////////////////////////////////////////////////////
                          DELEGATE TOKEN URI
    //////////////////////////////////////////////////////////////*/

    /// @notice Routes tokenURI calculation through a static-delegatecall
    function tokenURI(uint256 _badgeId) public view virtual override returns (string memory) {
        if (_ownerOf[_badgeId] == address(0)) revert WrongNFT();
        (bool _success, bytes memory _data) =
            address(this).staticcall(abi.encodeWithSignature('_tokenURI(uint256)', _badgeId));

        assembly {
            switch _success
            // delegatecall returns 0 on error.
            case 0 { revert(add(_data, 32), returndatasize()) }
            default { return(add(_data, 32), returndatasize()) }
        }
    }

    function _tokenURI(uint256) external {
        if (msg.sender != address(this)) revert WrongMethod();

        (bool _success, bytes memory _data) = address(nftDescriptor).delegatecall(msg.data);
        assembly {
            switch _success
            // delegatecall returns 0 on error.
            case 0 { revert(add(_data, 32), returndatasize()) }
            default { return(add(_data, 32), returndatasize()) }
        }
    }

    /// @notice Permissioned method, allows rabbit to change the nftDescriptor address
    function setNftDescriptor(address _nftDescriptor) external onlyRabbit {
        nftDescriptor = _nftDescriptor;
    }

    /*///////////////////////////////////////////////////////////////
                                RECEIVE
    //////////////////////////////////////////////////////////////*/

    /// @notice Method called by sudoswap pool on each sale
    receive() external payable {
        if (msg.sender == SUDOSWAP_POOL) totalSales += msg.value;
        return;
    }
}