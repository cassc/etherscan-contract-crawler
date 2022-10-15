// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRefTreeStorage, ITicketsCounter} from './Interfaces.sol';
import {RefProgramBase} from './RefProgramBase.sol';
import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

abstract contract RefProgram is RefProgramBase {
    using SafeERC20 for IERC20;
    struct RefUserInfo {
        uint256[3] refCumulativeRewards;
        uint256[3] refCumulativeParticipants;
    }

    uint256[3] public refererShares = [10, 5, 3];
    mapping(address => RefUserInfo) _refUserInfo;

    event RefRewardDistributed(
        address indexed referer,
        address indexed staker,
        uint8 indexed level,
        uint256 amount,
        uint256 timestamp
    );

    constructor(IRefTreeStorage refTreeStorage_) RefProgramBase(refTreeStorage_) {}

    // SETTERS

    function setRefShares(uint256[3] calldata shares) public onlyOwner {
        refererShares = shares;
    }

    // INTERNAL OPERATIONS

    function _refDistributeParticipants(address staker) internal {
        address referer = staker;
        for (uint8 i = 0; i < 3; i++) {
            referer = refTreeStorage.refererOf(referer);
            if (referer == address(0)) {
                break;
            }
            _refUserInfo[referer].refCumulativeParticipants[i]++;
        }
    }

    function _refDistributeRewards(
        IERC20 rewardToken,
        uint256 amount,
        address staker
    ) internal {
        address referer = staker;
        for (uint8 i = 0; i < 3; i++) {
            referer = refTreeStorage.refererOf(referer);
            if (referer == address(0)) {
                break;
            }
            uint256 refReward = (amount * refererShares[i]) / 100;
            rewardToken.safeTransfer(referer, refReward);
            emit RefRewardDistributed(referer, staker, i, refReward, block.timestamp);
            _refUserInfo[referer].refCumulativeRewards[i] += refReward;
        }
    }

    // EXTERNAL GETTERS

    function refUserInfo(address user)
        external
        view
        returns (
            RefUserInfo memory info,
            address referer,
            address[] memory referrals
        )
    {
        info = _refUserInfo[user];
        referer = refTreeStorage.refererOf(user);
        referrals = refTreeStorage.referralsOf(user);
    }
}

contract GammaIDO is RefProgram {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public immutable CHAIN_ID;

    ITicketsCounter public ticketsCounter;
    IERC20 public BUSD;
    address public backend;

    enum WinState {
        NULL,
        WON,
        LOST
    }

    struct VestingParams {
        uint32[] startPeriods;
        uint256[] startAmounts;
        uint32 mainPeriod;
        uint32 mainStepTime;
        uint256 mainAmount;
        uint32[] finalPeriods;
        uint256[] finalAmounts;
    }

    struct ProgramParams {
        uint16 places;
        uint256 busdAmount;
        uint256 tokenAmount;
        IERC20 token;
        uint32 registrationStart;
        uint32 registrationEnd;
        uint32 draw;
    }

    struct Program {
        VestingParams vesting; // static param
        ProgramParams params; // static param
        uint256 claimed; // To count how much tokens users have claimed
        bool refProgramActive; // Distribute referral program rewards or not
        bool cancelled; // Admin can cancel and let every user get all their busd back (unless user claimed tokens already)
        uint256 drawSeed;
        uint32 _filledDate; // calculated during adding
    }

    struct UserInfo {
        uint16 index;
        WinState winState;
        uint256 claimed;
    }

    /**
     * Just to track tokens that are involved in (not cancelled) IDO's
     * @notice SHALL USE ONLY add(), remove(), contains() - NOT RELY ON INDEXES
     */
    EnumerableSet.AddressSet _tokensInvolved;
    mapping(uint256 => EnumerableSet.AddressSet) _participantsOf;
    mapping(uint256 => uint16[]) _tickets;
    Program[] _programs;
    mapping(uint256 => mapping(address => UserInfo)) _userInfos;
    mapping(uint256 => mapping(address => ITicketsCounter.StakingLockDetails[])) _stakingLockDetails;

    event ProgramAdded(uint256 indexed index, IERC20 indexed token);
    event ProgramCancelled(uint256 indexed index, string reason);
    event ProgramEdited(uint256 indexed index);
    event ProgramParamsEdited(uint256 indexed index);
    event ProgramVestingEdited(uint256 indexed index);
    event RefProgramStatusSet(uint256 indexed index, bool value);
    event IdoDrawn(uint256 indexed index, uint256 indexed seed);
    event UserRegistered(uint256 indexed index, address indexed user, uint256 tickets);
    event UserClaimed(uint256 indexed index, address indexed user, uint256 amount, bool finished);
    event TokensTaken(IERC20 indexed token, uint256 amount);
    event ResultVerified(uint256 indexed index, address indexed user, bool win);

    constructor(
        IERC20 BUSD_,
        IRefTreeStorage refTreeStorage_,
        ITicketsCounter ticketsCounter_,
        address backend_,
        VestingParams[] memory vesting_,
        ProgramParams[] memory params_,
        bool[] memory cancelled
    ) RefProgram(refTreeStorage_) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        CHAIN_ID = chainId;
        BUSD = BUSD_;
        ticketsCounter = ticketsCounter_;
        backend = backend_;

        uint256 length = vesting_.length;
        for (uint256 i; i < length; ) {
            addProgram(vesting_[i], params_[i], false);
            if (cancelled[i]) {
                cancelProgram(i, "");
            }
            unchecked {
                ++i;
            }
        }
    }

    //------------------------------------------------
    // Participant functions
    //------------------------------------------------

    function register(uint256 index, uint256 tickets) public {
        Program storage program = _programs[index];
        require(!program.cancelled, 'cancelled');
        require(tickets > 0, 'no tickets amount');
        require(block.timestamp >= program.params.registrationStart, 'registration not open yet');
        require(block.timestamp < program.params.registrationEnd, 'registration is closed already');
        require(!_participantsOf[index].contains(msg.sender), 'already registered');
        uint256 participantsLength = _participantsOf[index].length();
        // Practically impossible to reach 2^16 participants but it would cause catastrophe if anyone did
        require(participantsLength < type(uint16).max, 'participants limit');
        require(tickets < type(uint16).max);

        ITicketsCounter.StakingLockDetails[] memory shouldLock = ticketsCounter.smartLockTickets(
            msg.sender,
            program.params.draw,
            tickets
        );
        for (uint256 i = 0; i < shouldLock.length; i++) {
            ITicketsCounter.StakingLockDetails memory lockCase = shouldLock[i];
            if (lockCase.amount > 0) {
                lockCase.target.createLock(msg.sender, index, program.params.draw, lockCase.amount);
                _stakingLockDetails[index][msg.sender].push(lockCase);
            }
        }

        BUSD.safeTransferFrom(msg.sender, address(this), program.params.busdAmount);

        _participantsOf[index].add(msg.sender);
        _tickets[index].push(uint16(tickets));
        _userInfos[index][msg.sender] = UserInfo({
            index: uint16(participantsLength),
            winState: WinState.NULL,
            claimed: 0
        });
        _refDistributeParticipants(msg.sender);
        emit UserRegistered(index, msg.sender, tickets);
    }

    function submitResult(
        uint256 index,
        bool win,
        bytes memory sig_
    ) external {
        Program storage program = _programs[index];
        require(!program.cancelled, 'program cancelled');
        require(_participantsOf[index].contains(msg.sender), 'not registered');
        require(_userInfos[index][msg.sender].winState == WinState.NULL, 'already submitted');
        require(program.drawSeed != 0, 'not drawn');
        require(_verifySignature(msg.sender, address(this), index, CHAIN_ID, win, sig_), 'wrong signature');
        _userInfos[index][msg.sender].winState = win ? WinState.WON : WinState.LOST;
        if (win && program.refProgramActive) {
            _refDistributeRewards(BUSD, program.params.busdAmount, msg.sender);
        }

        _deleteExpiredLocks(index, msg.sender);
        ticketsCounter.unlockTickets(msg.sender, _tickets[index][_userInfos[index][msg.sender].index]);
        emit ResultVerified(index, msg.sender, win);

        if (!win || getClaimable(index, msg.sender) > 0) {
            claim(index);
        }
    }

    function _deleteExpiredLocks(uint256 index, address user) internal {
        ITicketsCounter.StakingLockDetails[] storage lockedStakes = _stakingLockDetails[index][user];
        for (uint256 i = 0; i < lockedStakes.length; i++) {
            lockedStakes[i].target.deleteExpiredLock(user, index);
        }
        delete _stakingLockDetails[index][user];
    }

    function claim(uint256 index) public {
        require(_participantsOf[index].contains(msg.sender), 'not registered');
        if (_programs[index].cancelled) {
            _retrieveBusd(index, msg.sender);
            _deleteExpiredLocks(index, msg.sender);
            ticketsCounter.unlockTickets(msg.sender, _tickets[index][_userInfos[index][msg.sender].index]);
            return;
        }
        UserInfo storage info = _userInfos[index][msg.sender];
        require(info.winState != WinState.NULL, 'not submitted');
        if (info.winState == WinState.LOST) {
            _retrieveBusd(index, msg.sender);
            return;
        }
        ProgramParams storage params = _programs[index].params;
        uint256 claimable = getClaimable(index, msg.sender);
        require(claimable > 0, 'nothing to claim');
        params.token.safeTransfer(msg.sender, claimable);
        info.claimed += claimable;
        _programs[index].claimed += claimable;
        emit UserClaimed(index, msg.sender, claimable, info.claimed == params.tokenAmount);
    }

    function _retrieveBusd(uint256 index, address user) internal {
        UserInfo storage info = _userInfos[index][user];
        require(info.claimed == 0, 'already retrieved');
        BUSD.safeTransfer(user, _programs[index].params.busdAmount);
        info.claimed = type(uint256).max; // Unique value to distinct users that has claimed their BUSD back
        emit UserClaimed(index, user, 0, true);
    }

    //------------------------------------------------
    // Admin functions
    //------------------------------------------------

    function addProgram(
        VestingParams memory vesting,
        ProgramParams memory params,
        bool refProgramActive
    ) public onlyOwner returns (uint256 index) {
        uint32 _filledDate = _validateParams(vesting, params);
        index = _programs.length;
        _programs.push(
            Program({
                vesting: vesting,
                params: params,
                claimed: 0,
                refProgramActive: refProgramActive,
                cancelled: false,
                drawSeed: 0,
                _filledDate: _filledDate
            })
        );
        _tokensInvolved.add(address(params.token));
        emit ProgramAdded(index, params.token);
    }

    function editProgram(
        uint256 index,
        VestingParams memory vesting,
        ProgramParams memory params,
        bool refProgramActive
    ) external onlyOwner {
        _tokensInvolved.remove(address(_programs[index].params.token));
        require(!_programs[index].cancelled, 'cancelled');
        uint32 _filledDate = _validateParams(vesting, params);
        _programs[index].params = params;
        _programs[index].vesting = vesting;
        _programs[index]._filledDate = _filledDate;
        setRefProgramActive(index, refProgramActive);
        _tokensInvolved.add(address(params.token));
        emit ProgramEdited(index);
    }

    function editProgramParams(uint256 index, ProgramParams memory params) public onlyOwner {
        require(!_programs[index].cancelled, 'cancelled');
        uint32 _filledDate = _validateParams(_programs[index].vesting, params);
        _programs[index].params = params;
        _programs[index]._filledDate = _filledDate;
        emit ProgramParamsEdited(index);
    }

    function editProgramVesting(uint256 index, VestingParams memory vesting) public onlyOwner {
        require(!_programs[index].cancelled, 'cancelled');
        uint32 _filledDate = _validateParams(vesting, _programs[index].params);
        _programs[index].vesting = vesting;
        _programs[index]._filledDate = _filledDate;
        emit ProgramVestingEdited(index);
    }

    function cancelProgram(uint256 index, string memory reason) public onlyOwner {
        require(!_programs[index].cancelled);
        require(_programs[index].drawSeed == 0, 'seed drawn already');
        _programs[index].cancelled = true;
        _tokensInvolved.remove(address(_programs[index].params.token));
        emit ProgramCancelled(index, reason);
    }

    function setRefProgramActive(uint256 index, bool value) public onlyOwner {
        _programs[index].refProgramActive = value;
        emit RefProgramStatusSet(index, value);
    }

    function draw(uint256 index) external onlyOwner {
        Program storage program = _programs[index];
        require(!_programs[index].cancelled);
        require(program.drawSeed == 0, 'drawn already');
        require(block.timestamp >= program.params.draw, 'too early');
        program.drawSeed = uint256(keccak256(abi.encodePacked(block.timestamp)));
        emit IdoDrawn(index, program.drawSeed);
    }

    function returnBusd(uint256 amount_, address receiver_) external onlyOwner {
        BUSD.transfer(receiver_, amount_);
    }

    function takeByAddress(IERC20 token, uint256 amount) public onlyOwner {
        require(!_tokensInvolved.contains(address(token)), 'involved');
        if (amount == 0) amount = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, amount);
        emit TokensTaken(token, amount);
    }

    function takeByIndex(uint256 index, uint256 amount) public onlyOwner {
        Program storage program = _programs[index];
        require(block.timestamp > program._filledDate + 7 days || program.cancelled, 'forbidden');
        IERC20 token = program.params.token;
        if (amount == 0) amount = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, amount);
        emit TokensTaken(token, amount);
    }

    function setBackend(address backend_) external onlyOwner {
        backend = backend_;
    }

    function setTicketsCounter(ITicketsCounter ticketsCounter_) public onlyOwner {
        ticketsCounter = ticketsCounter_;
    }

    //------------------------------------------------
    // External view functions
    //------------------------------------------------

    function getInfoForDraw(uint256 index)
        external
        view
        returns (
            address[] memory participants,
            uint16[] memory tickets,
            uint256 seed,
            uint16 places
        )
    {
        return (
            _participantsOf[index].values(),
            _tickets[index],
            _programs[index].drawSeed,
            _programs[index].params.places
        );
    }

    function getBUSDCollected(uint256 index) external view returns (uint256 amount) {
        return _programs[index].params.busdAmount * _participantsOf[index].length();
    }

    function getClaimable(uint256 index, address user) public view returns (uint256 amount) {
        if (_userInfos[index][user].winState != WinState.WON) return 0;
        return _getCumulativeClaimable(index) - _userInfos[index][user].claimed;
    }

    function infoBundle(uint256 index, address user)
        external
        view
        returns (
            Program memory p,
            UserInfo memory u,
            TokenMetadata memory token,
            uint256 currentTotalTickets,
            uint256 currentUsableTickets,
            uint256 tickets
        )
    {
        p = _programs[index];
        token = infoBundleToken(IERC20Metadata(address(p.params.token)));
        if (user != address(0)) {
            u = _userInfos[index][user];
            (currentTotalTickets, currentUsableTickets) = ticketsCounter.countTickets(user, p.params.draw);
            if (_participantsOf[index].contains(user)) {
                tickets = _tickets[index][u.index];
            }
        }
    }

    struct TokenMetadata {
        uint8 decimals;
        string name;
        string symbol;
        uint256 totalSupply;
    }

    function infoBundleToken(IERC20Metadata token) public view returns (TokenMetadata memory) {
        return
            TokenMetadata({
                decimals: token.decimals(),
                name: token.name(),
                symbol: token.symbol(),
                totalSupply: token.totalSupply()
            });
    }

    function programs(uint256 from, uint256 to) public view returns (Program[] memory p) {
        uint256 length = to - from + 1;
        p = new Program[](length);
        for (uint256 i = 0; i < length; i++) {
            p[i] = _programs[i + from];
        }
    }

    function programs(uint256 last) external view returns (Program[] memory p, uint256 from) {
        uint256 pl = _programs.length;
        if (last > pl) last = pl;
        from = pl - last;
        p = programs(from, pl - 1);
    }

    function programs() external view returns (Program[] memory) {
        return _programs;
    }

    function programsLength() external view returns (uint256) {
        return _programs.length;
    }

    function participantsOf(uint256 index) external view returns (address[] memory) {
        return _participantsOf[index].values();
    }

    function participantsOf(uint256 index, address user) external view returns (bool) {
        return _participantsOf[index].contains(user);
    }

    function isTokensInvolved(address value) public view returns (bool) {
        return _tokensInvolved.contains(value);
    }

    //------------------------------------------------
    // Internal view functions
    //------------------------------------------------

    function _validateParams(VestingParams memory vesting, ProgramParams memory params)
        internal
        view
        returns (uint32 filledDate)
    {
        require(!_tokensInvolved.contains(address(params.token)), '!REPEAT');
        // Amount consistency check
        uint256 totalAmount;
        filledDate = params.draw;
        for (uint256 i = 0; i < vesting.startPeriods.length; i++) {
            filledDate += vesting.startPeriods[i];
            totalAmount += vesting.startAmounts[i];
        }
        filledDate += vesting.mainPeriod;
        totalAmount += vesting.mainAmount;
        for (uint256 i = 0; i < vesting.finalPeriods.length; i++) {
            filledDate += vesting.finalPeriods[i];
            totalAmount += vesting.finalAmounts[i];
        }
        require(totalAmount == params.tokenAmount, '!AMOUNT');
        require(params.draw > params.registrationEnd && params.registrationEnd > params.registrationStart, '!DATES');
        require(
            params.busdAmount > 0 && params.tokenAmount > 0 && params.places > 0 && address(params.token) != address(0),
            '!ZERO'
        );
    }

    function _getCumulativeClaimable(uint256 index) internal view returns (uint256 amount) {
        ProgramParams storage params = _programs[index].params;
        VestingParams storage vesting = _programs[index].vesting;
        // If whole period passed already then return total
        uint256 _now = block.timestamp;
        if (_now >= _programs[index]._filledDate) return params.tokenAmount;
        uint256 _then = params.draw;
        // Periods before main (if any)
        for (uint256 i = 0; i < vesting.startPeriods.length; i++) {
            if (_now < _then) return amount;
            amount += vesting.startAmounts[i];
            _then += vesting.startPeriods[i];
        }
        // Main period
        if (_now < _then) return amount;
        uint256 timePassed = _now - _then;
        if (timePassed >= vesting.mainPeriod) {
            amount += vesting.mainAmount;
        } else {
            timePassed = (timePassed / vesting.mainStepTime) * vesting.mainStepTime;
            amount += (vesting.mainAmount * timePassed) / vesting.mainPeriod;
            return amount;
        }
        _then += vesting.mainPeriod;
        // Periods before main (if any)
        for (uint256 i = 0; i < vesting.finalPeriods.length; i++) {
            if (_now < _then) return amount;
            amount += vesting.finalAmounts[i];
            _then += vesting.finalPeriods[i];
        }
    }

    //------------------------------------------------
    // Draw/Signature verification
    //------------------------------------------------

    function _verifySignature(
        address user,
        address ido,
        uint256 index,
        uint256 chainId,
        bool win,
        bytes memory sig_
    ) internal view returns (bool) {
        bytes32 hashedMessage;
        hashedMessage = _ethMessageHash(user, ido, index, chainId, win);
        return _recover(hashedMessage, sig_) == backend;
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash_ bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig_ bytes signature, the signature is generated using web3.eth.sign()
     */
    function _recover(bytes32 hash_, bytes memory sig_) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig_.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(sig_, 32))
            s := mload(add(sig_, 64))
            v := byte(0, mload(add(sig_, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(hash_, v, r, s);
        }
    }

    /**
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:" and hash the result
     */
    function _ethMessageHash(
        address user,
        address ido,
        uint256 index,
        uint256 chainId,
        bool win
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    '\x19Ethereum Signed Message:\n32',
                    keccak256(abi.encodePacked(user, ido, index, chainId, win))
                )
            );
    }
}