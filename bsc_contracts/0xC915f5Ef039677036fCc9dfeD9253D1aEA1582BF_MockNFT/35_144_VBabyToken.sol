// SPDX-License-Identifier: MIT

pragma solidity =0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/DecimalMath.sol";

contract vBABYToken is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ============ Storage(ERC20) ============

    string public name = "vBABY Membership Token";
    string public symbol = "vBABY";
    uint8 public decimals = 18;

    mapping(address => mapping(address => uint256)) internal _allowed;

    // ============ Storage ============

    address public _babyToken;
    address public _babyTeam;
    address public _babyReserve;
    address public _babyTreasury;
    bool public _canTransfer;
    address public constant hole = 0x000000000000000000000000000000000000dEaD;

    // staking reward parameters
    uint256 public _babyPerBlock;
    uint256 public constant _superiorRatio = 10**17; // 0.1
    uint256 public constant _babyRatio = 100; // 100
    uint256 public _babyFeeBurnRatio = 30 * 10**16; //30%
    uint256 public _babyFeeReserveRatio = 20 * 10**16; //20%
    uint256 public _feeRatio = 10 * 10**16; //10%;
    // accounting
    uint112 public alpha = 10**18; // 1
    uint112 public _totalBlockDistribution;
    uint32 public _lastRewardBlock;

    uint256 public _totalBlockReward;
    uint256 public _totalStakingPower;
    mapping(address => UserInfo) public userInfo;

    uint256 public _superiorMinBABY = 100e18; //The superior must obtain the min BABY that should be pledged for invitation rewards

    struct UserInfo {
        uint128 stakingPower;
        uint128 superiorSP;
        address superior;
        uint256 credit;
        uint256 creditDebt;
    }

    // ============ Events ============

    event MintVBABY(
        address user,
        address superior,
        uint256 mintBABY,
        uint256 totalStakingPower
    );
    event RedeemVBABY(
        address user,
        uint256 receiveBABY,
        uint256 burnBABY,
        uint256 feeBABY,
        uint256 reserveBABY,
        uint256 totalStakingPower
    );
    event DonateBABY(address user, uint256 donateBABY);
    event SetCanTransfer(bool allowed);

    event PreDeposit(uint256 babyAmount);
    event ChangePerReward(uint256 babyPerBlock);
    event UpdateBABYFeeBurnRatio(uint256 babyFeeBurnRatio);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    // ============ Modifiers ============

    modifier canTransfer() {
        require(_canTransfer, "vBABYToken: not the allowed transfer");
        _;
    }

    modifier balanceEnough(address account, uint256 amount) {
        require(
            availableBalanceOf(account) >= amount,
            "vBABYToken: available amount not enough"
        );
        _;
    }

    event TokenInfo(uint256 babyTokenSupply, uint256 babyBalanceInVBaby);
    event CurrentUserInfo(
        address user,
        uint128 stakingPower,
        uint128 superiorSP,
        address superior,
        uint256 credit,
        uint256 creditDebt
    );

    function logTokenInfo(IERC20 token) internal {
        emit TokenInfo(token.totalSupply(), token.balanceOf(address(this)));
    }

    function logCurrentUserInfo(address user) internal {
        UserInfo storage currentUser = userInfo[user];
        emit CurrentUserInfo(
            user,
            currentUser.stakingPower,
            currentUser.superiorSP,
            currentUser.superior,
            currentUser.credit,
            currentUser.creditDebt
        );
    }

    // ============ Constructor ============

    constructor(
        address babyToken,
        address babyTeam,
        address babyReserve,
        address babyTreasury
    ) {
        _babyToken = babyToken;
        _babyTeam = babyTeam;
        _babyReserve = babyReserve;
        _babyTreasury = babyTreasury;
        changePerReward(2 * 10**18);
    }

    // ============ Ownable Functions ============`

    function setCanTransfer(bool allowed) public onlyOwner {
        _canTransfer = allowed;
        emit SetCanTransfer(allowed);
    }

    function changePerReward(uint256 babyPerBlock) public onlyOwner {
        _updateAlpha();
        _babyPerBlock = babyPerBlock;
        logTokenInfo(IERC20(_babyToken));
        emit ChangePerReward(babyPerBlock);
    }

    function updateBABYFeeBurnRatio(uint256 babyFeeBurnRatio) public onlyOwner {
        _babyFeeBurnRatio = babyFeeBurnRatio;
        emit UpdateBABYFeeBurnRatio(_babyFeeBurnRatio);
    }

    function updateBABYFeeReserveRatio(uint256 babyFeeReserve)
        public
        onlyOwner
    {
        _babyFeeReserveRatio = babyFeeReserve;
    }

    function updateTeamAddress(address team) public onlyOwner {
        _babyTeam = team;
    }

    function updateTreasuryAddress(address treasury) public onlyOwner {
        _babyTreasury = treasury;
    }

    function updateReserveAddress(address newAddress) public onlyOwner {
        _babyReserve = newAddress;
    }

    function setSuperiorMinBABY(uint256 val) public onlyOwner {
        _superiorMinBABY = val;
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 babyBalance = IERC20(_babyToken).balanceOf(address(this));
        IERC20(_babyToken).safeTransfer(owner(), babyBalance);
    }

    // ============ Mint & Redeem & Donate ============

    function mint(uint256 babyAmount, address superiorAddress) public {
        require(
            superiorAddress != address(0) && superiorAddress != msg.sender,
            "vBABYToken: Superior INVALID"
        );
        require(babyAmount >= 1e18, "vBABYToken: must mint greater than 1");

        UserInfo storage user = userInfo[msg.sender];

        if (user.superior == address(0)) {
            require(
                superiorAddress == _babyTeam ||
                    userInfo[superiorAddress].superior != address(0),
                "vBABYToken: INVALID_SUPERIOR_ADDRESS"
            );
            user.superior = superiorAddress;
        }

        if (_superiorMinBABY > 0) {
            uint256 curBABY = babyBalanceOf(user.superior);
            if (curBABY < _superiorMinBABY) {
                user.superior = _babyTeam;
            }
        }

        _updateAlpha();

        IERC20(_babyToken).safeTransferFrom(
            msg.sender,
            address(this),
            babyAmount
        );

        uint256 newStakingPower = DecimalMath.divFloor(babyAmount, alpha);

        _mint(user, newStakingPower);

        logTokenInfo(IERC20(_babyToken));
        logCurrentUserInfo(msg.sender);
        logCurrentUserInfo(user.superior);
        emit MintVBABY(
            msg.sender,
            superiorAddress,
            babyAmount,
            _totalStakingPower
        );
    }

    function redeem(uint256 vBabyAmount, bool all)
        public
        balanceEnough(msg.sender, vBabyAmount)
    {
        _updateAlpha();
        UserInfo storage user = userInfo[msg.sender];

        uint256 babyAmount;
        uint256 stakingPower;

        if (all) {
            stakingPower = uint256(user.stakingPower).sub(
                DecimalMath.divFloor(user.credit, alpha)
            );
            babyAmount = DecimalMath.mulFloor(stakingPower, alpha);
        } else {
            babyAmount = vBabyAmount.mul(_babyRatio);
            stakingPower = DecimalMath.divFloor(babyAmount, alpha);
        }

        _redeem(user, stakingPower);

        (
            uint256 babyReceive,
            uint256 burnBabyAmount,
            uint256 withdrawFeeAmount,
            uint256 reserveAmount
        ) = getWithdrawResult(babyAmount);

        IERC20(_babyToken).safeTransfer(msg.sender, babyReceive);

        if (burnBabyAmount > 0) {
            IERC20(_babyToken).safeTransfer(hole, burnBabyAmount);
        }
        if (reserveAmount > 0) {
            IERC20(_babyToken).safeTransfer(_babyReserve, reserveAmount);
        }

        if (withdrawFeeAmount > 0) {
            alpha = uint112(
                uint256(alpha).add(
                    DecimalMath.divFloor(withdrawFeeAmount, _totalStakingPower)
                )
            );
        }

        logTokenInfo(IERC20(_babyToken));
        logCurrentUserInfo(msg.sender);
        logCurrentUserInfo(user.superior);
        emit RedeemVBABY(
            msg.sender,
            babyReceive,
            burnBabyAmount,
            withdrawFeeAmount,
            reserveAmount,
            _totalStakingPower
        );
    }

    function donate(uint256 babyAmount) public {
        IERC20(_babyToken).safeTransferFrom(
            msg.sender,
            address(this),
            babyAmount
        );

        alpha = uint112(
            uint256(alpha).add(
                DecimalMath.divFloor(babyAmount, _totalStakingPower)
            )
        );
        logTokenInfo(IERC20(_babyToken));
        emit DonateBABY(msg.sender, babyAmount);
    }

    function totalSupply() public view returns (uint256 vBabySupply) {
        uint256 totalBaby = IERC20(_babyToken).balanceOf(address(this));
        (, uint256 curDistribution) = getLatestAlpha();

        uint256 actualBaby = totalBaby.add(curDistribution);
        vBabySupply = actualBaby / _babyRatio;
    }

    function balanceOf(address account)
        public
        view
        returns (uint256 vBabyAmount)
    {
        vBabyAmount = babyBalanceOf(account) / _babyRatio;
    }

    function transfer(address to, uint256 vBabyAmount) public returns (bool) {
        _updateAlpha();
        _transfer(msg.sender, to, vBabyAmount);
        return true;
    }

    function approve(address spender, uint256 vBabyAmount)
        public
        canTransfer
        returns (bool)
    {
        _allowed[msg.sender][spender] = vBabyAmount;
        emit Approval(msg.sender, spender, vBabyAmount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 vBabyAmount
    ) public returns (bool) {
        require(
            vBabyAmount <= _allowed[from][msg.sender],
            "ALLOWANCE_NOT_ENOUGH"
        );
        _updateAlpha();
        _transfer(from, to, vBabyAmount);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(
            vBabyAmount
        );
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    // ============ Helper Functions ============

    function getLatestAlpha()
        public
        view
        returns (uint256 newAlpha, uint256 curDistribution)
    {
        if (_lastRewardBlock == 0) {
            curDistribution = 0;
        } else {
            curDistribution = _babyPerBlock * (block.number - _lastRewardBlock);
        }
        if (_totalStakingPower > 0) {
            newAlpha = uint256(alpha).add(
                DecimalMath.divFloor(curDistribution, _totalStakingPower)
            );
        } else {
            newAlpha = alpha;
        }
    }

    function availableBalanceOf(address account)
        public
        view
        returns (uint256 vBabyAmount)
    {
        vBabyAmount = balanceOf(account);
    }

    function babyBalanceOf(address account)
        public
        view
        returns (uint256 babyAmount)
    {
        UserInfo memory user = userInfo[account];
        (uint256 newAlpha, ) = getLatestAlpha();
        uint256 nominalBaby = DecimalMath.mulFloor(
            uint256(user.stakingPower),
            newAlpha
        );
        if (nominalBaby > user.credit) {
            babyAmount = nominalBaby - user.credit;
        } else {
            babyAmount = 0;
        }
    }

    function getWithdrawResult(uint256 babyAmount)
        public
        view
        returns (
            uint256 babyReceive,
            uint256 burnBabyAmount,
            uint256 withdrawFeeBabyAmount,
            uint256 reserveBabyAmount
        )
    {
        uint256 feeRatio = _feeRatio;

        withdrawFeeBabyAmount = DecimalMath.mulFloor(babyAmount, feeRatio);
        babyReceive = babyAmount.sub(withdrawFeeBabyAmount);

        burnBabyAmount = DecimalMath.mulFloor(
            withdrawFeeBabyAmount,
            _babyFeeBurnRatio
        );
        reserveBabyAmount = DecimalMath.mulFloor(
            withdrawFeeBabyAmount,
            _babyFeeReserveRatio
        );

        withdrawFeeBabyAmount = withdrawFeeBabyAmount.sub(burnBabyAmount);
        withdrawFeeBabyAmount = withdrawFeeBabyAmount.sub(reserveBabyAmount);
    }

    function setRatioValue(uint256 ratioFee) public onlyOwner {
        _feeRatio = ratioFee;
    }

    function getSuperior(address account)
        public
        view
        returns (address superior)
    {
        return userInfo[account].superior;
    }

    // ============ Internal Functions ============

    function _updateAlpha() internal {
        (uint256 newAlpha, uint256 curDistribution) = getLatestAlpha();
        uint256 newTotalDistribution = curDistribution.add(
            _totalBlockDistribution
        );
        require(
            newAlpha <= uint112(-1) && newTotalDistribution <= uint112(-1),
            "OVERFLOW"
        );
        alpha = uint112(newAlpha);
        _totalBlockDistribution = uint112(newTotalDistribution);
        _lastRewardBlock = uint32(block.number);

        if (curDistribution > 0) {
            IERC20(_babyToken).safeTransferFrom(
                _babyTreasury,
                address(this),
                curDistribution
            );

            _totalBlockReward = _totalBlockReward.add(curDistribution);
            logTokenInfo(IERC20(_babyToken));
            emit PreDeposit(curDistribution);
        }
    }

    function _mint(UserInfo storage to, uint256 stakingPower) internal {
        require(stakingPower <= uint128(-1), "OVERFLOW");
        UserInfo storage superior = userInfo[to.superior];
        uint256 superiorIncreSP = DecimalMath.mulFloor(
            stakingPower,
            _superiorRatio
        );
        uint256 superiorIncreCredit = DecimalMath.mulFloor(
            superiorIncreSP,
            alpha
        );

        to.stakingPower = uint128(uint256(to.stakingPower).add(stakingPower));
        to.superiorSP = uint128(uint256(to.superiorSP).add(superiorIncreSP));

        superior.stakingPower = uint128(
            uint256(superior.stakingPower).add(superiorIncreSP)
        );
        superior.credit = uint128(
            uint256(superior.credit).add(superiorIncreCredit)
        );

        _totalStakingPower = _totalStakingPower.add(stakingPower).add(
            superiorIncreSP
        );
    }

    function _redeem(UserInfo storage from, uint256 stakingPower) internal {
        from.stakingPower = uint128(
            uint256(from.stakingPower).sub(stakingPower)
        );

        uint256 userCreditSP = DecimalMath.divFloor(from.credit, alpha);
        if (from.stakingPower > userCreditSP) {
            from.stakingPower = uint128(
                uint256(from.stakingPower).sub(userCreditSP)
            );
        } else {
            userCreditSP = from.stakingPower;
            from.stakingPower = 0;
        }
        from.creditDebt = from.creditDebt.add(from.credit);
        from.credit = 0;

        // superior decrease sp = min(stakingPower*0.1, from.superiorSP)
        uint256 superiorDecreSP = DecimalMath.mulFloor(
            stakingPower,
            _superiorRatio
        );
        superiorDecreSP = from.superiorSP <= superiorDecreSP
            ? from.superiorSP
            : superiorDecreSP;
        from.superiorSP = uint128(
            uint256(from.superiorSP).sub(superiorDecreSP)
        );
        uint256 superiorDecreCredit = DecimalMath.mulFloor(
            superiorDecreSP,
            alpha
        );

        UserInfo storage superior = userInfo[from.superior];
        if (superiorDecreCredit > superior.creditDebt) {
            uint256 dec = DecimalMath.divFloor(superior.creditDebt, alpha);
            superiorDecreSP = dec >= superiorDecreSP
                ? 0
                : superiorDecreSP.sub(dec);
            superiorDecreCredit = superiorDecreCredit.sub(superior.creditDebt);
            superior.creditDebt = 0;
        } else {
            superior.creditDebt = superior.creditDebt.sub(superiorDecreCredit);
            superiorDecreCredit = 0;
            superiorDecreSP = 0;
        }
        uint256 creditSP = DecimalMath.divFloor(superior.credit, alpha);

        if (superiorDecreSP >= creditSP) {
            superior.credit = 0;
            superior.stakingPower = uint128(
                uint256(superior.stakingPower).sub(creditSP)
            );
        } else {
            superior.credit = uint128(
                uint256(superior.credit).sub(superiorDecreCredit)
            );
            superior.stakingPower = uint128(
                uint256(superior.stakingPower).sub(superiorDecreSP)
            );
        }

        _totalStakingPower = _totalStakingPower
            .sub(stakingPower)
            .sub(superiorDecreSP)
            .sub(userCreditSP);
    }

    function _transfer(
        address from,
        address to,
        uint256 vBabyAmount
    ) internal canTransfer balanceEnough(from, vBabyAmount) {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(from != to, "transfer from same with to");

        uint256 stakingPower = DecimalMath.divFloor(
            vBabyAmount * _babyRatio,
            alpha
        );

        UserInfo storage fromUser = userInfo[from];
        UserInfo storage toUser = userInfo[to];

        _redeem(fromUser, stakingPower);
        _mint(toUser, stakingPower);

        logTokenInfo(IERC20(_babyToken));
        logCurrentUserInfo(from);
        logCurrentUserInfo(fromUser.superior);
        logCurrentUserInfo(to);
        logCurrentUserInfo(toUser.superior);
        emit Transfer(from, to, vBabyAmount);
    }
}