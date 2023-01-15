/* SPDX-License-Identifier: MIT OR Apache-2.0 */
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Structs.sol";
// import "hardhat/console.sol";

contract EOG_Competition is Context, Ownable {
    using SafeMath for uint256;

    Token[] public tokens;

    uint256 public startCompetitionId = 0;
    uint256 public startPresetId = 0;
    address public operator;

    mapping(uint256 => Preset) public presetList;
    mapping(uint256 => Competition) public competitionList;

    mapping(uint256 => mapping(uint8 => Competitor)) teamACompetitors;
    mapping(uint256 => mapping(uint8 => Competitor)) teamBCompetitors;

    event NewPresetCreated(
        uint256 presetId,
        uint256 entryFeeInUSD,
        uint256 numberOfTeamMemebr,
        uint256 rakeAmountInUSD
    );
    event NewCompetitionCreated(
        uint256 competitionId,
        uint8 teamSize,
        uint256 presetId,
        uint256 createAt
    );
    event PoolLocked(
        uint256 tokenIndex,
        uint256 lockAmount,
        uint256 newTotalLock
    );
    event PoolUnlocked(
        uint256 tokenIndex,
        uint256 unlockAmount,
        uint256 newTotalLock
    );

    constructor() {
        operator = _msgSender();
    }

    // ============================================== MODIFIER ==============================================

    modifier operatorOrOwner() {
        require(
            _msgSender() == operator || _msgSender() == owner(),
            "EOG_Competition: caller is not the operator or owner"
        );
        _;
    }

    function updateOperator(address _newOperator) external onlyOwner {
        operator = _newOperator;
    }

    // ============================================== TOKEN MANAGEMENT ==============================================

    function addToken(
        IERC20 _tokenAddress,
        uint256 _stablePrice
    ) external onlyOwner {
        tokens.push(Token(_tokenAddress, _stablePrice, 0, 0, true));
    }

    function removeToken(uint256 _index) external onlyOwner {
        isTokenExists(_index);
        delete tokens[_index];
    }

    function depositToken(uint256 _index, uint256 _amount) external onlyOwner {
        isTokenExists(_index);
        tokens[_index].tokenAddress.transferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        tokens[_index].totalBalance = tokens[_index].tokenAddress.balanceOf(
            address(this)
        );
    }

    function withdrawToken(uint256 _index, uint256 _amount) external onlyOwner {
        isTokenExists(_index);
        uint256 totalBalance = tokens[_index].tokenAddress.balanceOf(
            address(this)
        );
        uint256 unlockedBalance = totalBalance.sub(
            tokens[_index].lockedBalance
        );
        require(unlockedBalance >= _amount, "Not enough unlocked balance");
        tokens[_index].tokenAddress.transfer(owner(), _amount);
        tokens[_index].totalBalance = tokens[_index].tokenAddress.balanceOf(
            address(this)
        );
    }

    function isTokenExists(uint256 tokenIndex) internal view {
        require(tokenIndex < tokens.length, "token Index is out of range");
    }

    function updateTokenStablePrice(
        uint256 tokenIndex,
        uint256 newRate
    ) external onlyOwner {
        isTokenExists(tokenIndex);
        tokens[tokenIndex].stablePrice = newRate;
    }

    function updateTokenActivate(
        uint256 tokenIndex,
        bool isActive
    ) external onlyOwner {
        isTokenExists(tokenIndex);
        tokens[tokenIndex].isActive = isActive;
    }

    function getAllTokens() external view returns (Token[] memory) {
        return tokens;
    }

    function getActiveTokens() external view returns (Token[] memory) {
        uint256 activeTokenCount = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].isActive) {
                activeTokenCount++;
            }
        }
        Token[] memory activeTokens = new Token[](activeTokenCount);
        uint256 index = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i].isActive) {
                activeTokens[index] = tokens[i];
                index++;
            }
        }
        return activeTokens;
    }

    // ============================================== Competition management ==============================================

    function addNewCompetition(
        uint256 _presetId,
        Team[] memory _teams,
        uint256 _createAt
    ) external operatorOrOwner {
        require(isPresetExists(_presetId), "can't find preset with this id!");

        require(isPresetActive(_presetId), "this preset is not active!");

        require(_teams.length == 2, "teams length need to be 2");

        uint256 teamMemberLength = _teams[0].competitors.length;
        for (uint8 i = 1; i < _teams.length; i++) {
            require(
                _teams[i].competitors.length == teamMemberLength,
                "Teams length must be same"
            );
        }

        (uint256 entryFeeInUSD, uint256 playerNumber, ) = getPreset(_presetId);

        require(
            teamMemberLength == playerNumber,
            "team member need to be equal with preset team number!"
        );

        // Store teams
        for (uint8 i = 0; i < _teams[0].competitors.length; i++) {
            teamACompetitors[startCompetitionId][i] = _teams[0].competitors[i];
            teamBCompetitors[startCompetitionId][i] = _teams[1].competitors[i];
        }

        // Store new competition
        competitionList[startCompetitionId] = Competition({
            teamSize: uint8(teamMemberLength),
            presetId: _presetId,
            status: CompetitionStatus.PENDING,
            winnerTeam: CompetitionWinner.OPEN,
            createAt: _createAt
        });

        for (uint8 i = 0; i < _teams.length; i++) {
            for (uint8 j = 0; j < teamMemberLength; j++) {
                uint256 payableInUSD = _teams[i].competitors[j].payableInUSD;
                address competitorAddress = _teams[i].competitors[j].account;
                if (competitorAddress == address(this)) {
                    continue;
                }

                require(
                    payableInUSD <= entryFeeInUSD,
                    "Payable amount should be less or equal than entry fee"
                );

                uint256 tokenIndex = _teams[i].competitors[j].tokenIndex;
                isTokenExists(tokenIndex);
                isTokenActive(tokenIndex);

                transferDesiredTokenFromCompetitor(
                    tokenIndex,
                    competitorAddress,
                    payableInUSD,
                    entryFeeInUSD
                );
            }
        }

        emit NewCompetitionCreated(
            startCompetitionId,
            uint8(teamMemberLength),
            _presetId,
            _createAt
        );

        startCompetitionId += 1;
    }

    function transferDesiredTokenFromCompetitor(
        uint256 _tokenIndex,
        address _competitorAddress,
        uint256 payableInUSD,
        uint256 entryFeeInUSD
    ) internal returns (bool) {
        Token memory DesiredToken = tokens[_tokenIndex];
        uint256 stablePrice = DesiredToken.stablePrice;
        IERC20 token = IERC20(DesiredToken.tokenAddress);

        // Since other users may pay in other tokens but we still have to pay this player in this token if they win
        // So we have to lock double
        uint256 tokenPoolTotalBalance = token.balanceOf(address(this));
        uint256 tokenPoolRemaining = tokenPoolTotalBalance.sub(
            DesiredToken.lockedBalance
        );

        uint256 entryFeeInToken = entryFeeInUSD.mul(1e18).div(stablePrice);

        require(
            tokenPoolRemaining >= entryFeeInToken * 2,
            "Not enough unlocked balance"
        );

        uint256 lockedAmount = entryFeeInToken * 2;
        tokens[_tokenIndex].lockedBalance = DesiredToken.lockedBalance.add(
            lockedAmount
        );

        emit PoolLocked(
            _tokenIndex,
            lockedAmount,
            tokens[_tokenIndex].lockedBalance
        );

        tokens[_tokenIndex].totalBalance = tokenPoolTotalBalance;

        // Transfer payable tokens
        uint256 payableInToken = payableInUSD.mul(1e18).div(stablePrice);
        uint256 competitorBalance = token.balanceOf(_competitorAddress);

        require(
            competitorBalance >= payableInToken,
            "Competitor balance is not enough"
        );
        if (payableInToken > 0) {
            token.transferFrom(
                _competitorAddress,
                address(this),
                payableInToken
            );
        }

        return true;
    }

    function setCompetitionWinner(
        uint256 _competitionId,
        CompetitionWinner _winnerTeam
    ) external operatorOrOwner returns (bool) {
        (
            Competitor[] memory teamA,
            Competitor[] memory teamB,
            CompetitionStatus _competitionStatus,
            CompetitionWinner _competitionWinner,
            uint256 rakeAmountInUSD,
            uint256 entryFeeInUSD
        ) = getCompetition(_competitionId);

        require(
            _competitionStatus == CompetitionStatus.PENDING,
            "this Competition is not pending!"
        );
        require(
            _competitionWinner == CompetitionWinner.OPEN,
            "this Competition already have a winner!"
        );

        competitionList[_competitionId].winnerTeam = _winnerTeam;
        competitionList[_competitionId].status = CompetitionStatus.DONE;

        //    Competitor[] memory _winnerCompetitors = Competition.teams[_winnerTeam].competitors;

        if (_winnerTeam == CompetitionWinner.TEAMA) {
            pay(teamA, rakeAmountInUSD, entryFeeInUSD, PaymentType.EARNING);
            handleUnlockTokenForLooserTeam(teamB, entryFeeInUSD);
        } else if (_winnerTeam == CompetitionWinner.TEAMB) {
            pay(teamB, rakeAmountInUSD, entryFeeInUSD, PaymentType.EARNING);
            handleUnlockTokenForLooserTeam(teamA, entryFeeInUSD);
        } else if (_winnerTeam == CompetitionWinner.DRAW) {
            pay(teamA, rakeAmountInUSD, entryFeeInUSD, PaymentType.PAYBACK);
            pay(teamB, rakeAmountInUSD, entryFeeInUSD, PaymentType.PAYBACK);
        }
        return true;
    }

    function pay(
        Competitor[] memory winnerCompetitors,
        uint256 rakeAmountInUSD,
        uint256 entryFeeInUSD,
        PaymentType paymentType
    ) internal {
        for (uint8 i = 0; i < winnerCompetitors.length; i++) {
            address competitorAddress = winnerCompetitors[i].account;
            if (competitorAddress == address(this)) {
                continue;
            }

            uint256 tokenIndex = winnerCompetitors[i].tokenIndex;

            Token memory desiredToken = tokens[tokenIndex];
            uint256 stablePrice = desiredToken.stablePrice;
            uint256 paidByCompetitorInTokens = winnerCompetitors[i]
                .payableInUSD
                .mul(stablePrice)
                .div(1e18);

            IERC20 token = IERC20(desiredToken.tokenAddress);
            uint256 entryFeeInToken = entryFeeInUSD.mul(1e18).div(stablePrice);
            uint256 rakeAmountInToken = rakeAmountInUSD.mul(1e18).div(
                stablePrice
            );
            uint256 payableInToken;

            if (paymentType == PaymentType.PAYBACK) {
                if (paidByCompetitorInTokens > rakeAmountInToken) {
                    payableInToken =
                        paidByCompetitorInTokens -
                        rakeAmountInToken;
                } else {
                    payableInToken = 0;
                }
            }
            if (paymentType == PaymentType.EARNING) {
                payableInToken =
                    (entryFeeInToken * 2) -
                    (rakeAmountInToken * 2);
            }

            // Transfer
            if (competitorAddress != address(this) && payableInToken > 0) {
                token.transfer(competitorAddress, payableInToken);
            }

            uint256 unlockedAmount = entryFeeInToken * 2;
            unchecked {
                tokens[tokenIndex].lockedBalance = desiredToken
                    .lockedBalance
                    .sub(unlockedAmount);
            }
            unchecked {
                tokens[tokenIndex].totalBalance = token.balanceOf(
                    address(this)
                );
            }

            emit PoolUnlocked(
                tokenIndex,
                unlockedAmount,
                tokens[tokenIndex].lockedBalance
            );
        }
    }

    function handleUnlockTokenForLooserTeam(
        Competitor[] memory looserCompetitors,
        uint256 entryFeeInUSD
    ) internal {
        for (uint8 i = 0; i < looserCompetitors.length; i++) {
            if (looserCompetitors[i].account == address(this)) {
                continue;
            }
            uint256 tokenIndex = looserCompetitors[i].tokenIndex;
            Token memory desiredToken = tokens[tokenIndex];
            uint256 stablePrice = desiredToken.stablePrice;
            uint256 entryFeeInToken = entryFeeInUSD.mul(1e18).div(stablePrice);
            unchecked {
                tokens[tokenIndex].lockedBalance = desiredToken
                    .lockedBalance
                    .sub(entryFeeInToken * 2);
            }
        }
    }

    // ============================================== Preset management ==============================================

    function addNewPreset(
        uint256 _entryFeeInUSD,
        uint256 _numberOfTeamMemebr,
        uint256 _createAt,
        uint256 _rakeAmountInUSD
    ) external onlyOwner returns (uint256 presetId) {
        require(
            _entryFeeInUSD > _rakeAmountInUSD,
            "rake amount can't be bigger than entry fee!"
        );

        require(
            _entryFeeInUSD <= 5000 * 1e18,
            "entry fee can't be bigger than 5000 USD!"
        );

        require(_entryFeeInUSD > 0, "preset entry fee must be greater than 0!");

        uint256 _lastPresetId = startPresetId;
        Preset memory currentPreset = Preset(
            _entryFeeInUSD,
            _numberOfTeamMemebr,
            block.timestamp,
            _createAt,
            _rakeAmountInUSD,
            true
        );
        presetList[_lastPresetId] = currentPreset;

        emit NewPresetCreated(
            _lastPresetId,
            _entryFeeInUSD,
            _numberOfTeamMemebr,
            _rakeAmountInUSD
        );

        startPresetId += 1;
        return _lastPresetId;
    }

    function updatePreset(
        uint256 _presetId,
        uint256 _entryFeeInUSD,
        uint256 _numberOfTeamMemebr,
        uint256 _createAt,
        uint256 _rakeAmountInUSD,
        bool _isActive
    ) external onlyOwner {
        require(isPresetExists(_presetId), "can't find preset with this id!");

        Preset storage preset = presetList[_presetId];
        preset.entryFeeInUSD = _entryFeeInUSD;
        preset.numberOfTeamMemebr = _numberOfTeamMemebr;
        preset.createAt = _createAt;
        preset.rakeAmountInUSD = _rakeAmountInUSD;
        preset.isActive = _isActive;
    }

    // ============================================== utils ==============================================

    function getPreset(
        uint256 _presetId
    ) internal view returns (uint256, uint256, uint256) {
        return (
            presetList[_presetId].entryFeeInUSD,
            presetList[_presetId].numberOfTeamMemebr,
            presetList[_presetId].rakeAmountInUSD
        );
    }

    function getCompetition(
        uint256 _competitionId
    )
        internal
        view
        returns (
            Competitor[] memory teamA,
            Competitor[] memory teamB,
            CompetitionStatus _competitionStatus,
            CompetitionWinner _competitionWinner,
            uint256 rakeAmountInUSD,
            uint256 entryFeeInUSD
        )
    {
        require(
            isCompetitionExists(_competitionId),
            "can't find competition with this competitionId!"
        );
        Preset memory competitionPreset = presetList[
            competitionList[_competitionId].presetId
        ];
        uint8 teamSize = competitionList[_competitionId].teamSize;
        teamA = new Competitor[](teamSize);
        teamB = new Competitor[](teamSize);
        for (uint8 i = 0; i < teamSize; i++) {
            teamA[i] = teamACompetitors[_competitionId][i];
            teamB[i] = teamBCompetitors[_competitionId][i];
        }
        rakeAmountInUSD = competitionPreset.rakeAmountInUSD;
        entryFeeInUSD = competitionPreset.entryFeeInUSD;
        _competitionStatus = competitionList[_competitionId].status;
        _competitionWinner = competitionList[_competitionId].winnerTeam;
    }

    // utils methods

    function isCompetitionExists(uint256 key) internal view returns (bool) {
        if (competitionList[key].createAt == 0) {
            return false;
        }
        return true;
    }

    function isPresetExists(uint256 key) internal view returns (bool) {
        if (presetList[key].date != 0) {
            return true;
        }
        return false;
    }

    function isPresetActive(uint256 key) internal view returns (bool) {
        if (presetList[key].isActive) {
            return true;
        }
        return false;
    }

    function isTokenActive(uint256 key) internal view {
        require(tokens[key].isActive == true, "token is not active");
    }
}