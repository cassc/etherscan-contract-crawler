// SPDX-License-Identifier: MIT
// Votium

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Votium is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // relevant time constraints
    uint256 epochDuration = 86400 * 14; // 2 weeks
    uint256 roundDuration = 86400 * 5; // 5 days
    uint256 deadlineDuration = 60 * 60 * 6; // 6 hours

    mapping(address => bool) public tokenAllowed; // token allow list
    mapping(address => bool) public approvedTeam; // for team functions that do not require multi-sig security

    address public feeAddress; // address to receive platform fees
    uint256 public platformFee = 400; // 4%
    uint256 public constant DENOMINATOR = 10000; // denominates weights 10000 = 100%
    address public distributor; // address of distributor contract

    bool public requireAllowlist = true; // begin with erc20 allow list in effect
    bool public allowExclusions = false; // enable ability to exclude addresses

    struct Incentive {
        address token;
        uint256 amount;
        uint256 maxPerVote;
        uint256 distributed;
        uint256 recycled;
        address depositor;
        address[] excluded; // list of addresses that cannot receive this incentive
    }

    mapping(uint256 => address[]) public roundGauges; // round => gauge array
    mapping(uint256 => mapping(address => bool)) public inRoundGauges; // round => gauge => bool
    mapping(uint256 => mapping(address => Incentive[])) public incentives; // round => gauge => incentive array
    mapping(uint256 => mapping(address => uint256)) public votesReceived; // round => gauge => votes

    mapping(address => mapping(uint256 => mapping(address => uint256[]))) public userDeposits; // user => round => gauge => incentive indecies
    mapping(address => uint256[]) public userRounds; // user => round array
    mapping(address => address[]) public userGauges; // user => gauge array
    mapping(address => mapping(uint256 => bool)) public inUserRounds; // user => round => bool
    mapping(address => mapping(address => bool)) public inUserGauges; // user => gauge => bool

    mapping(address => uint256) public virtualBalance; // token => amount

    uint256 public lastRoundProcessed; // last round that was processed by multi-sig

    mapping(address => uint256) public toTransfer; // token => amount
    address[] public toTransferList; // list of tokens to transfer

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _approved,
        address _approved2,
        address _feeAddress,
        address _distributor,
        address _initialOwner
    ) {
        approvedTeam[_approved] = true;
        approvedTeam[_approved2] = true;
        feeAddress = _feeAddress;
        distributor = _distributor;
        lastRoundProcessed = (block.timestamp / epochDuration) - 1349;
        transferOwnership(_initialOwner);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    function gaugesLength(uint256 _round) public view returns (uint256) {
        return roundGauges[_round].length;
    }

    function incentivesLength(
        uint256 _round,
        address _gauge
    ) public view returns (uint256) {
        return incentives[_round][_gauge].length;
    }

    function userRoundsLength(address _user) public view returns (uint256) {
        return userRounds[_user].length;
    }

    function userGaugesLength(address _user) public view returns (uint256) {
        return userGauges[_user].length;
    }

    function userDepositsLength(
        address _user,
        uint256 _round,
        address _gauge
    ) public view returns (uint256) {
        return userDeposits[_user][_round][_gauge].length;
    }

    function currentEpoch() public view returns (uint256) {
        return (block.timestamp / epochDuration) * epochDuration;
    }

    // Display current or next active round
    function activeRound() public view returns (uint256) {
        if (
            block.timestamp < currentEpoch() + roundDuration - deadlineDuration
        ) {
            return currentEpoch() / epochDuration - 1348; // 1348 is the votium genesis round
        } else {
            return currentEpoch() / epochDuration - 1347;
        }
    }

    // Include excluded addresses in incentive
    function viewIncentive(
        uint256 _round,
        address _gauge,
        uint256 _incentive
    ) public view returns (Incentive memory) {
        return incentives[_round][_gauge][_incentive];
    }

    // Deposit vote incentive for a single gauge in a active round with no max and no exclusions -- for gas efficiency
    function depositIncentiveSimple(
        address _token,
        uint256 _amount,
        address _gauge
    ) public {
        _takeDeposit(_token, _amount);
        uint256 _round = activeRound();
        uint256 rewardTotal = _amount - ((_amount * platformFee) / DENOMINATOR);
        virtualBalance[_token] += rewardTotal;
        incentives[_round][_gauge].push(Incentive({
            token: _token,
            amount: rewardTotal,
            maxPerVote: 0,
            distributed: 0,
            recycled: 0,
            depositor: msg.sender,
            excluded: new address[](0)
        }));
        userDeposits[msg.sender][_round][_gauge].push(
            incentives[_round][_gauge].length - 1
        );
        _maintainUserRounds(_round);
        _maintainGaugeArrays(_round, _gauge);
        emit NewIncentive(
            _token,
            rewardTotal,
            _round,
            _gauge,
            0,
            false
        );
    }

    function depositIncentive(
        address _token,
        uint256 _amount,
        uint256 _round,
        address _gauge,
        uint256 _maxPerVote,
        address[] memory _excluded
    ) public {
        require(_round >= activeRound(), "!roundEnded");
        require(_round <= activeRound() + 6, "!farFuture");
        if(!allowExclusions) { require(_excluded.length == 0, "!excluded"); }
        _takeDeposit(_token, _amount);
        uint256 rewardTotal = _amount - ((_amount * platformFee) / DENOMINATOR);
        virtualBalance[_token] += rewardTotal;
        Incentive memory incentive = Incentive({
            token: _token,
            amount: rewardTotal,
            maxPerVote: _maxPerVote,
            distributed: 0,
            recycled: 0,
            depositor: msg.sender,
            excluded: _excluded
        });
        incentives[_round][_gauge].push(incentive);
        userDeposits[msg.sender][_round][_gauge].push(
            incentives[_round][_gauge].length - 1
        );
        _maintainUserRounds(_round);
        _maintainGaugeArrays(_round, _gauge);
        emit NewIncentive(
            _token,
            rewardTotal,
            _round,
            _gauge,
            _maxPerVote,
            false
        );
    }

    // evenly split deposit across a single gauge in multiple rounds
    function depositSplitRounds(
        address _token,
        uint256 _amount,
        uint256 _numRounds,
        address _gauge,
        uint256 _maxPerVote,
        address[] memory _excluded
    ) public {
        require(_numRounds < 8, "!farFuture");
        require(_numRounds > 1, "!numRounds");
        if(!allowExclusions) { require(_excluded.length == 0, "!excluded"); }

        uint256 totalDeposit = _amount * _numRounds;
        _takeDeposit(_token, totalDeposit);
        uint256 rewardTotal = _amount - ((_amount * platformFee) / DENOMINATOR);
        virtualBalance[_token] += rewardTotal * _numRounds;
        uint256 round = activeRound();
        Incentive memory incentive = Incentive({
            token: _token,
            amount: rewardTotal,
            maxPerVote: _maxPerVote,
            distributed: 0,
            recycled: 0,
            depositor: msg.sender,
            excluded: _excluded
        });
        for (uint256 i = 0; i < _numRounds; i++) {
            incentives[round + i][_gauge].push(incentive);
            userDeposits[msg.sender][round + i][_gauge].push(
                incentives[round + i][_gauge].length - 1
            );
            _maintainUserRounds(round + i);
            _maintainGaugeArrays(round + i, _gauge);
            emit NewIncentive(
                _token,
                rewardTotal,
                round + i,
                _gauge,
                _maxPerVote,
                false
            );
        }
    }

    // evenly split deposit across multiple gauges in a single round
    function depositSplitGauges(
        address _token,
        uint256 _amount,
        uint256 _round,
        address[] memory _gauges,
        uint256 _maxPerVote,
        address[] memory _excluded
    ) public {
        require(_round >= activeRound(), "!roundEnded");
        require(_round <= activeRound() + 6, "!farFuture");
        require(_gauges.length > 1, "!gauges");
        if(!allowExclusions) { require(_excluded.length == 0, "!excluded"); }

        uint256 totalDeposit = _amount * _gauges.length;
        _takeDeposit(_token, totalDeposit);
        uint256 rewardTotal = _amount - ((_amount * platformFee) / DENOMINATOR);
        virtualBalance[_token] += rewardTotal * _gauges.length;
        _maintainUserRounds(_round);
        Incentive memory incentive = Incentive({
            token: _token,
            amount: rewardTotal,
            maxPerVote: _maxPerVote,
            distributed: 0,
            recycled: 0,
            depositor: msg.sender,
            excluded: _excluded
        });
        for (uint256 i = 0; i < _gauges.length; i++) {
            incentives[_round][_gauges[i]].push(incentive);
            userDeposits[msg.sender][_round][_gauges[i]].push(
                incentives[_round][_gauges[i]].length - 1
            );
            _maintainGaugeArrays(_round, _gauges[i]);
            emit NewIncentive(
                _token,
                rewardTotal,
                _round,
                _gauges[i],
                _maxPerVote,
                false
            );
        }
    }

    // evenly split deposit across multiple gauges in multiple rounds
    function depositSplitGaugesRounds(
        address _token,
        uint256 _amount,
        uint256 _numRounds,
        address[] memory _gauges,
        uint256 _maxPerVote,
        address[] memory _excluded
    ) public {
        require(_numRounds < 8, "!farFuture");
        require(_numRounds > 1, "!numRounds");
        require(_gauges.length > 1, "!gauges");
        if(!allowExclusions) { require(_excluded.length == 0, "!excluded"); }

        uint256 totalDeposit = _amount * _numRounds * _gauges.length;
        _takeDeposit(_token, totalDeposit);
        uint256 rewardTotal = _amount - ((_amount * platformFee) / DENOMINATOR);
        virtualBalance[_token] += rewardTotal * _numRounds * _gauges.length;
        uint256 round = activeRound();
        Incentive memory incentive = Incentive({
            token: _token,
            amount: rewardTotal,
            maxPerVote: _maxPerVote,
            distributed: 0,
            recycled: 0,
            depositor: msg.sender,
            excluded: _excluded
        });
        for (uint256 i = 0; i < _numRounds; i++) {
            _maintainUserRounds(round + i);
            for (uint256 j = 0; j < _gauges.length; j++) {
                incentives[round + i][_gauges[j]].push(incentive);
                userDeposits[msg.sender][round + i][_gauges[j]].push(
                    incentives[round + i][_gauges[j]].length - 1
                );
                _maintainGaugeArrays(round + i, _gauges[j]);
                emit NewIncentive(
                    _token,
                    rewardTotal,
                    round + i,
                    _gauges[j],
                    _maxPerVote,
                    false
                );
            }
        }
    }

    // deposit same token to multiple gauges with different amounts in a single round
    function depositUnevenSplitGauges(
        address _token,
        uint256 _round,
        address[] memory _gauges,
        uint256[] memory _amounts,
        uint256 _maxPerVote,
        address[] memory _excluded
    ) public {
        require(_gauges.length == _amounts.length, "!length");
        require(_round >= activeRound(), "!roundEnded");
        require(_round <= activeRound() + 6, "!farFuture");
        if(!allowExclusions) { require(_excluded.length == 0, "!excluded"); }
        _maintainUserRounds(_round);
        uint256 totalDeposit;
        uint256 rewardsTotal;
        Incentive memory incentive = Incentive({
            token: _token,
            amount: 0,
            maxPerVote: _maxPerVote,
            distributed: 0,
            recycled: 0,
            depositor: msg.sender,
            excluded: _excluded
        });
        for (uint256 i = 0; i < _gauges.length; i++) {
            require(_amounts[i] > 0, "!amount");
            totalDeposit += _amounts[i];
            uint256 rewardTotal = _amounts[i] - (_amounts[i] * platformFee) / DENOMINATOR;
            incentive.amount = rewardTotal;
            rewardsTotal += rewardTotal;
            incentives[_round][_gauges[i]].push(incentive);
            userDeposits[msg.sender][_round][_gauges[i]].push(
                incentives[_round][_gauges[i]].length - 1
            );
            _maintainGaugeArrays(_round, _gauges[i]);
            emit NewIncentive(
                _token,
                rewardTotal,
                _round,
                _gauges[i],
                _maxPerVote,
                false
            );
        }
        _takeDeposit(_token, totalDeposit);
        virtualBalance[_token] += rewardsTotal;
    }

    // deposit same token to multiple gauges with different amounts in active round with no max and no exclusions
    function depositUnevenSplitGaugesSimple(
        address _token,
        address[] memory _gauges,
        uint256[] memory _amounts
    ) public {
        require(_gauges.length == _amounts.length, "!length");
        uint256 _round = activeRound();
        _maintainUserRounds(_round);
        uint256 totalDeposit;
        uint256 rewardsTotal;
        Incentive memory incentive = Incentive({
            token: _token,
            amount: 0,
            maxPerVote: 0,
            distributed: 0,
            recycled: 0,
            depositor: msg.sender,
            excluded: new address[](0)
        });
        for (uint256 i = 0; i < _gauges.length; i++) {
            require(_amounts[i] > 0, "!amount");
            totalDeposit += _amounts[i];
            uint256 rewardTotal = _amounts[i] - (_amounts[i] * platformFee) / DENOMINATOR;
            incentive.amount = rewardTotal;
            rewardsTotal += rewardTotal;
            incentives[_round][_gauges[i]].push(incentive);
            userDeposits[msg.sender][_round][_gauges[i]].push(
                incentives[_round][_gauges[i]].length - 1
            );
            _maintainGaugeArrays(_round, _gauges[i]);
            emit NewIncentive(
                _token,
                rewardTotal,
                _round,
                _gauges[i],
                0,
                false
            );
        }
        _takeDeposit(_token, totalDeposit);
        virtualBalance[_token] += rewardsTotal;
    }

    // deposit same token to multiple gauges with different amounts in a single round
    function depositUnevenSplitGaugesRounds(
        address _token,
        uint256 _numRounds,
        address[] memory _gauges,
        uint256[] memory _amounts,
        uint256 _maxPerVote,
        address[] memory _excluded
    ) public {
        require(_gauges.length == _amounts.length, "!length");
        require(_numRounds < 8, "!farFuture");
        require(_numRounds > 1, "!numRounds");
        if(!allowExclusions) { require(_excluded.length == 0, "!excluded"); }
        uint256 totalDeposit;
        uint256 rewardsTotal;
        Incentive memory incentive = Incentive({
            token: _token,
            amount: 0,
            maxPerVote: _maxPerVote,
            distributed: 0,
            recycled: 0,
            depositor: msg.sender,
            excluded: _excluded
        });
        for (uint256 i = 0; i < _gauges.length; i++) {
            require(_amounts[i] > 0, "!amount");
            totalDeposit += _amounts[i];
            uint256 round = activeRound();
            // to prevent rounding issues and potentially failed txs, virtual balance should directly reflect Inventive amount sums
            uint256 rewardTotal = _amounts[i] - (_amounts[i] * platformFee) / DENOMINATOR;
            incentive.amount = rewardTotal;
            rewardsTotal += rewardTotal * _numRounds;
            for (uint256 j = 0; j < _numRounds; j++) {
                incentives[round + j][_gauges[i]].push(incentive);
                userDeposits[msg.sender][round + j][_gauges[i]].push(
                    incentives[round + j][_gauges[i]].length - 1
                );
                _maintainUserRounds(round + j);
                _maintainGaugeArrays(round + j, _gauges[i]);
                emit NewIncentive(
                    incentive.token,
                    rewardTotal,
                    round + j,
                    _gauges[i],
                    _maxPerVote,
                    false
                );
            }
        }
        totalDeposit = totalDeposit * _numRounds;
        _takeDeposit(_token, totalDeposit);
        virtualBalance[_token] += rewardsTotal;
    }

    function increaseIncentive(
        uint256 _round,
        address _gauge,
        uint256 _incentive,
        uint256 _increase,
        uint256 _maxPerVote
    ) public {
        require(
            _maxPerVote != incentives[_round][_gauge][_incentive].maxPerVote ||
                _increase > 0,
            "!change"
        );
        require(_round >= activeRound(), "!deadline");
        require(
            incentives[_round][_gauge][_incentive].depositor == msg.sender,
            "!depositor"
        );
        if (_maxPerVote > 0) {
            require(
                _maxPerVote >=
                    incentives[_round][_gauge][_incentive].maxPerVote,
                "!increaseOnly"
            );
            require(
                incentives[_round][_gauge][_incentive].maxPerVote != 0,
                "!increaseOnly"
            );
        }
        if (_maxPerVote != incentives[_round][_gauge][_incentive].maxPerVote) {
            incentives[_round][_gauge][_incentive].maxPerVote = _maxPerVote;
        }
        uint256 rewardIncrease;
        if (_increase > 0) {
            _takeDeposit(
                incentives[_round][_gauge][_incentive].token,
                _increase
            );
            rewardIncrease =
                _increase -
                ((_increase * platformFee) / DENOMINATOR);
            incentives[_round][_gauge][_incentive].amount += rewardIncrease;
            virtualBalance[
                incentives[_round][_gauge][_incentive].token
            ] += rewardIncrease;
        }
        emit IncreasedIncentive(
            incentives[_round][_gauge][_incentive].token,
            incentives[_round][_gauge][_incentive].amount,
            rewardIncrease,
            _round,
            _gauge,
            _maxPerVote
        );
    }

    // function for depositor to withdraw unprocessed incentives
    // this should only happen if a gauge does not exist or is killed before the round ends
    // fees are not returned
    function withdrawUnprocessed(
        uint256 _round,
        address _gauge,
        uint256 _incentive
    ) public nonReentrant {
        require(
            _round <= lastRoundProcessed || _round + 3 < activeRound(),
            "!roundNotProcessed"
        ); // allow 3 rounds for processing before withdraw can be forced
        require(
            incentives[_round][_gauge][_incentive].depositor == msg.sender,
            "!depositor"
        );
        require(
            incentives[_round][_gauge][_incentive].distributed == 0,
            "!distributed"
        );
        require(
            incentives[_round][_gauge][_incentive].recycled == 0,
            "!recycled"
        );
        require(
            incentives[_round][_gauge][_incentive].amount > 0,
            "!withdrawn"
        );
        uint256 amount = incentives[_round][_gauge][_incentive].amount;
        incentives[_round][_gauge][_incentive].amount = 0;
        uint256 adjustedAmount = (amount *
            IERC20(incentives[_round][_gauge][_incentive].token).balanceOf(
                address(this)
            )) / virtualBalance[incentives[_round][_gauge][_incentive].token];
        amount = amount > adjustedAmount ? adjustedAmount : amount; // use lower amount to avoid over-withdrawal for negative rebase tokens, honeypotting, etc
        IERC20(incentives[_round][_gauge][_incentive].token).safeTransfer(
            msg.sender,
            amount
        );
        virtualBalance[incentives[_round][_gauge][_incentive].token] -= amount;
        emit WithdrawUnprocessed(_round, _gauge, _incentive, amount);
    }

    // function for depositor to recycle unprocessed incentives instead of withdrawing (maybe gauge was not active yet or was killed and revived)
    function recycleUnprocessed(
        uint256 _round,
        address _gauge,
        uint256 _incentive
    ) public {
        require(_round <= lastRoundProcessed, "!roundNotProcessed");
        require(
            incentives[_round][_gauge][_incentive].depositor == msg.sender ||
                msg.sender == owner(),
            "!auth"
        );
        require(
            incentives[_round][_gauge][_incentive].distributed == 0,
            "!distributed"
        );
        require(
            incentives[_round][_gauge][_incentive].recycled == 0,
            "!recycled"
        );
        Incentive memory original = incentives[_round][_gauge][_incentive];
        uint256 currentRound = activeRound();
        incentives[currentRound][_gauge].push(original);
        incentives[_round][_gauge][_incentive].recycled = original.amount;
        emit NewIncentive(original.token, original.amount, currentRound, _gauge, original.maxPerVote, true);


    }

    /* ========== APPROVED TEAM FUNCTIONS ========== */

    // allow/deny token
    function allowToken(address _token, bool _allow) public onlyTeam {
        tokenAllowed[_token] = _allow;
        emit TokenAllow(_token, _allow);
    }

    // allow/deny multiple tokens
    function allowTokens(
        address[] memory _tokens,
        bool _allow
    ) public onlyTeam {
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenAllowed[_tokens[i]] = _allow;
            emit TokenAllow(_tokens[i], _allow);
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    // take deposit and send fees to feeAddress, return rewardTotal
    function _takeDeposit(address _token, uint256 _amount) internal {
        if (requireAllowlist == true) {
            require(tokenAllowed[_token] == true, "!allowlist");
        }
        uint256 fee = (_amount * platformFee) / DENOMINATOR;
        require(fee > 0, "!amount");
        uint256 rewardTotal = _amount - fee;
        IERC20(_token).safeTransferFrom(msg.sender, feeAddress, fee);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), rewardTotal);
    }

    function _maintainUserRounds(uint256 _round) internal {
        if (!inUserRounds[msg.sender][_round]) {
            userRounds[msg.sender].push(_round);
            inUserRounds[msg.sender][_round] = true;
        }
    }
    function _maintainGaugeArrays(uint256 _round, address _gauge) internal {
        if (!inUserGauges[msg.sender][_gauge]) {
            userGauges[msg.sender].push(_gauge);
            inUserGauges[msg.sender][_gauge] = true;
        }
        if (!inRoundGauges[_round][_gauge]) {
            roundGauges[_round].push(_gauge);
            inRoundGauges[_round][_gauge] = true;
        }
    }

    /* ========== MUTLI-SIG FUNCTIONS ========== */

    // submit vote totals and transfer rewards to distributor
    function endRound(
        uint256 _round,
        address[] memory _gauges,
        uint256[] memory _totals
    ) public onlyOwner {
        require(_gauges.length == _totals.length, "!gauges/totals");
        require(_round < activeRound(), "!activeRound");
        require(_round - 1 == lastRoundProcessed, "!lastRoundProcessed");
        for (uint256 i = 0; i < _gauges.length; i++) {
            require(votesReceived[_round][_gauges[i]] == 0, "!duplicate");
            votesReceived[_round][_gauges[i]] = _totals[i];
            for (
                uint256 n = 0;
                n < incentives[_round][_gauges[i]].length;
                n++
            ) {
                Incentive memory incentive = incentives[_round][_gauges[i]][n];
                uint256 reward;
                if (incentive.maxPerVote > 0) {
                    reward = incentive.maxPerVote * _totals[i];
                    if (reward >= incentive.amount) {
                        reward = incentive.amount;
                    } else {
                        // recycle unused reward
                        incentive.amount -= reward;
                        incentives[_round+1][_gauges[i]].push(incentive);
                        incentives[_round][_gauges[i]][n].recycled = incentive.amount - reward;
                        emit NewIncentive(incentive.token, incentive.amount, _round+1, _gauges[i], incentive.maxPerVote, true);
                    }
                    incentives[_round][_gauges[i]][n].distributed = reward;
                } else {
                    reward = incentive.amount;
                    incentives[_round][_gauges[i]][n].distributed = reward;
                }
                toTransfer[incentive.token] += reward;
                toTransferList.push(incentive.token);
            }
        }
        lastRoundProcessed = _round;
        for (uint256 i = 0; i < toTransferList.length; i++) {
            if (toTransfer[toTransferList[i]] == 0) continue; // skip if already transferred
            IERC20(toTransferList[i]).safeTransfer(
                distributor,
                (toTransfer[toTransferList[i]] *
                    IERC20(toTransferList[i]).balanceOf(address(this))) /
                    virtualBalance[toTransferList[i]] // account for rebasing tokens
            );
            virtualBalance[toTransferList[i]] -= toTransfer[toTransferList[i]];
            toTransfer[toTransferList[i]] = 0;
        }
        delete toTransferList;
    }

    // toggle allowlist requirement
    function setAllowlistRequired(bool _requireAllowlist) public onlyOwner {
        requireAllowlist = _requireAllowlist;
        emit AllowlistRequirement(_requireAllowlist);
    }

    // toggle allowExclusions
    function setAllowExclusions(bool _allowExclusions) public onlyOwner {
        allowExclusions = _allowExclusions;
        emit AllowExclusions(_allowExclusions);
    }

    // update fee address
    function updateFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    // update fee amount
    function updateFeeAmount(uint256 _feeAmount) public onlyOwner {
        require(_feeAmount < 400, "max fee"); // Max fee 4%
        platformFee = _feeAmount;
        emit UpdatedFee(_feeAmount);
    }

    // add or remove address from team functions
    function modifyTeam(address _member, bool _approval) public onlyOwner {
        approvedTeam[_member] = _approval;
        emit ModifiedTeam(_member, _approval);
    }

    // update token distributor address
    function updateDistributor(address _distributor) public onlyOwner {
        distributor = _distributor;
        emit UpdatedDistributor(distributor);
    }

    // Fallback executable function
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        return (success, result);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyTeam() {
        require(approvedTeam[msg.sender] == true, "Team only");
        _;
    }

    /* ========== EVENTS ========== */

    event NewIncentive(
        address _token,
        uint256 _amount,
        uint256 _round,
        address _gauge,
        uint256 _maxPerVote,
        bool _recycled
    );
    event TokenAllow(address _token, bool _allow);
    event AllowlistRequirement(bool _requireAllowlist);
    event AllowExclusions(bool _allowExclusions);
    event UpdatedFee(uint256 _feeAmount);
    event ModifiedTeam(address _member, bool _approval);
    event UpdatedDistributor(address _distributor);
    event WithdrawUnprocessed(
        uint256 _round,
        address _gauge,
        uint256 _incentive,
        uint256 _amount
    );
    event IncreasedIncentive(
        address _token,
        uint256 _total,
        uint256 _increase,
        uint256 _round,
        address _gauge,
        uint256 _maxPerVote
    );
}