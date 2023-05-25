// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITulipArt.sol";
import "./interfaces/ITulipToken.sol";
import "./libraries/SortitionSumTreeFactory.sol";
import "./libraries/UniformRandomNumber.sol";

contract TulipArt is ITulipArt, Ownable {
    using SortitionSumTreeFactory for SortitionSumTreeFactory.SortitionSumTrees;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice We use this enum to identify and enforce the
    /// states that this contract will go through.
    enum RoundState {
        OPEN,
        DRAWING,
        CLOSED
    }

    /// @notice `roundId` is the current round identifier, incremented each round.
    /// `roundState` is the current state this round is in, progression goes
    /// from OPEN to DRAWING to CLOSED.
    struct RoundInfo {
        uint256 roundId;
        RoundState roundState;
    }

    /// @notice `implementation` is the next lottery contract to be implemented.
    /// `proposedTime` is the time at which this upgrade can happen.
    struct LotteryCandidate {
        address implementation;
        uint256 proposedTime;
    }

    bytes32 private constant TREE_KEY = keccak256("TulipArt/Staking");
    uint256 private constant MAX_TREE_LEAVES = 5;

    SortitionSumTreeFactory.SortitionSumTrees internal sortitionSumTrees;

    address public immutable landToken;
    address public immutable tulipNFTToken;
    address public lotteryContract;

    /// The minimum time it has to pass before a lottery candidate can be approved.
    uint256 public immutable approvalDelay;

    /// The last proposed lottery to switch to.
    LotteryCandidate public lotteryCandidate;

    /// Store the round info
    RoundInfo public roundInfo;

    event NewLotteryCandidate(address implementation);
    event UpgradeLottery(address implementation);
    event RoundUpdated(uint256 roundId, RoundState roundState);
    event WinnerSet(address winner, uint256 id);

    /// @notice On contract deployment a new round (1) is created and users can
    /// deposit tokens from the start.
    /// @param _landToken: address of the LAND ERC20 token used for staking.
    /// @param _tulipNFTToken: address of the NFT reward to be minted.
    /// @param _approvalDelay: time it takes to upgrade a lottery contract.
    constructor(
        address _landToken,
        address _tulipNFTToken,
        uint256 _approvalDelay
    ) public {
        landToken = _landToken;
        tulipNFTToken = _tulipNFTToken;
        approvalDelay = _approvalDelay;
        sortitionSumTrees.createTree(TREE_KEY, MAX_TREE_LEAVES);

        _createNextRound(1);
    }

    /// @notice A user can only enter staking during the open phase of a round.
    /// The tokens are first transfered to this contract and afterwards
    /// the sortitionSumTree is updated.
    /// @param _amount: Is the amount of tokens a user wants to stake.
    function enterStaking(uint256 _amount) external override {
        require(_amount > 0, "TulipArt/amounts-0-or-less-not-allowed");
        require(
            roundInfo.roundState == RoundState.OPEN,
            "TulipArt/round-not-open"
        );

        IERC20(landToken).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        sortitionSumTrees.set(
            TREE_KEY,
            userStake(msg.sender).add(_amount),
            bytes32(uint256(msg.sender))
        );
    }

    /// @notice A user can only leave staking during the open phase of a round.
    /// Firstly the sortitionSumTree is updated and then the tokens are
    /// transfered out of this contract.
    /// @param _amount: Is the amount of tokens a user wants to unstake.
    function leaveStaking(uint256 _amount) external override {
        require(_amount > 0, "TulipArt/amounts-0-or-less-not-allowed");
        require(
            _amount <= userStake(msg.sender),
            "TulipArt/insufficient-amount-staked"
        );
        require(
            roundInfo.roundState == RoundState.OPEN,
            "TulipArt/round-not-open"
        );

        sortitionSumTrees.set(
            TREE_KEY,
            userStake(msg.sender).sub(_amount),
            bytes32(uint256(msg.sender))
        );

        IERC20(landToken).safeTransfer(address(msg.sender), _amount);
    }

    /// @notice The lottery can set the state of this contract to DRAW
    /// which will disable all functions except `finishDraw()`.
    /// It will also enable the function `setWinner()` as we are now in
    /// draw phase.
    function startDraw() external override onlyLottery {
        require(totalStaked() > 0, "TulipArt/no-users");
        require(
            roundInfo.roundState == RoundState.OPEN,
            "TulipArt/round-is-not-open"
        );

        roundInfo.roundState = RoundState.DRAWING;

        emit RoundUpdated(roundInfo.roundId, RoundState.DRAWING);
    }

    /// @notice The lottery can set the state of this contract to CLOSED
    /// to state that this round has finished. This function will
    /// also create a new round which will enable deposits and
    /// withdrawals.
    function finishDraw() external override onlyLottery {
        require(
            roundInfo.roundState == RoundState.DRAWING,
            "TulipArt/round-is-not-drawing"
        );

        roundInfo.roundState = RoundState.CLOSED;

        _createNextRound(totalRounds().add(1));

        emit RoundUpdated(roundInfo.roundId, RoundState.CLOSED);
    }

    /// @notice We set communicate to the NFT the winner.
    /// The user can then go and mint the token from the NFT contract.
    /// @param _winner: address of the winner.
    function setWinner(address _winner)
        external
        override
        onlyLottery
    {
        require(
            roundInfo.roundState == RoundState.DRAWING,
            "TulipArt/round-is-not-drawing"
        );
        uint256 _id = ITulipToken(tulipNFTToken).setTokenWinner(_winner);
        emit WinnerSet(_winner, _id);
    }

    /// @notice This function removes tokens sent to this contract. It cannot remove
    /// the LAND token from this contract.
    /// @param _token: address of the token to remove from this contract.
    /// @param _to: address of the location to send this token.
    /// @param _amount: amount of tokens to remove from this contract.
    function recoverTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_token != landToken, "TulipArt/cannot-drain-land-tokens");
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice Returns the user's chance of winning with 6 decimal places or more.
    /// If a user's chance of winning are 25.3212315673% this function will return
    /// 25.321231%.
    /// @param _user: address of a staker.
    /// @return returns the % chance of victory for this user.
    function chanceOf(address _user) external view override returns (uint256) {
        return
            sortitionSumTrees
                .stakeOf(TREE_KEY, bytes32(uint256(_user)))
                .mul(100000000)
                .div(totalStaked());
    }

    /// @notice Selects a user using a random number. The random number will
    /// be uniformly bounded to the total Stake.
    /// @param randomNumber The random number to use to select a user.
    /// @return The winner.
    function draw(uint256 randomNumber)
        external
        view
        override
        returns (address)
    {
        address selected;
        if (totalStaked() == 0) {
            selected = address(0);
        } else {
            uint256 token = UniformRandomNumber.uniform(
                randomNumber,
                totalStaked()
            );
            selected = address(
                uint256(sortitionSumTrees.draw(TREE_KEY, token))
            );
        }
        return selected;
    }

    /// @notice Sets the candidate for the new lottery to use with this staking
    /// contract.
    /// @param _implementation The address of the candidate lottery.
    function proposeLottery(address _implementation) public onlyOwner {
        lotteryCandidate = LotteryCandidate({
            implementation: _implementation,
            proposedTime: block.timestamp
        });

        emit NewLotteryCandidate(_implementation);
    }

    /// @notice It switches the active lottery for the lottery candidate.
    /// After upgrading, the candidate implementation is set to the 0x00 address,
    /// and proposedTime to a time happening in +100 years for safety.
    function upgradeLottery() public onlyOwner {
        require(
            roundInfo.roundState == RoundState.OPEN,
            "TulipArt/round-not-open"
        );
        require(
            lotteryCandidate.implementation != address(0),
            "TulipArt/there-is-no-candidate"
        );

        if (lotteryContract != address(0)) {
            require(
                lotteryCandidate.proposedTime.add(approvalDelay) <
                    block.timestamp,
                "TulipArt/delay-has-not-passed"
            );
        }

        emit UpgradeLottery(lotteryCandidate.implementation);

        lotteryContract = lotteryCandidate.implementation;
        lotteryCandidate.implementation = address(0);
        lotteryCandidate.proposedTime = 0;
    }

    /// @return the total rounds that have been played till now.
    function totalRounds() public view returns (uint256) {
        return roundInfo.roundId;
    }

    /// @param _user: address of an account.
    /// @return returns the total tokens deposited by the user.
    function userStake(address _user) public view override returns (uint256) {
        return sortitionSumTrees.stakeOf(TREE_KEY, bytes32(uint256(_user)));
    }

    /// @return total amount of tokens currently staked in this contract.
    function totalStaked() public view returns (uint256) {
        return sortitionSumTrees.total(TREE_KEY);
    }

    /// @notice internal function to help with the creation of new rounds.
    /// @param _id: the number of the round that is to be created.
    function _createNextRound(uint256 _id) internal {
        roundInfo = RoundInfo({roundId: _id, roundState: RoundState.OPEN});
        emit RoundUpdated(_id, RoundState.OPEN);
    }

    /// @notice ensure only a lottery can execute functions with this modifier
    modifier onlyLottery() {
        require(msg.sender == lotteryContract, "TulipArt/error-not-lottery");
        _;
    }
}