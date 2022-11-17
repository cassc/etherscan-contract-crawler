// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./PausableByOwner.sol";
import "./RecoverableByOwner.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/INmxSupplier.sol";

contract SingleStakerStakingService is PausableByOwner, RecoverableByOwner {
    /**
     * @param totalStaked amount of NMXLP currently staked in the service
     * @param historicalRewardRate how many NMX minted per one NMXLP (<< 40). Never decreases.
     */
    struct State {
        uint128 totalStaked;
        uint128 historicalRewardRate;
    }
    /**
     * @param amount of NMXLP currently staked by the staker
     * @param initialRewardRate value of historicalRewardRate before last update of the staker's data
     * @param reward total amount of Nmx accrued to the staker
     * @param claimedReward total amount of Nmx the staker transferred from the service already
     */
    struct Staker {
        uint256 amount;
        uint128 initialRewardRate;
        uint128 reward;
        uint256 claimedReward;
    }

    bytes32 immutable public DOMAIN_SEPARATOR;

    string private constant CLAIM_TYPE =
    "Claim(address owner,address spender,uint128 value,uint256 nonce,uint256 deadline)";
    bytes32 public constant CLAIM_TYPEHASH =
    keccak256(abi.encodePacked(CLAIM_TYPE));

    string private constant UNSTAKE_TYPE =
    "Unstake(address owner,address spender,uint128 value,uint256 nonce,uint256 deadline)";
    bytes32 public constant UNSTAKE_TYPEHASH =
    keccak256(abi.encodePacked(UNSTAKE_TYPE));

    mapping(address => uint256) public nonces;

    address immutable public nmx; /// @dev Nmx contract
    address immutable public stakingToken; /// @dev NmxLp contract of uniswap
    address public nmxSupplier;
    address public staker; /// @dev The only one who can stake
    State public state; /// @dev internal service state
    mapping(address => Staker) public stakers; /// @dev mapping of staker's address to its state
    bool public claimRewardPaused = false;

    event Staked(address indexed owner, uint128 amount); /// @dev someone is staked NMXLP
    event Unstaked(address indexed from, address indexed to, uint128 amount); /// @dev someone unstaked NMXLP
    event Rewarded(address indexed from, address indexed to, uint128 amount); /// @dev someone transferred Nmx from the service
    event StakingBonusAccrued(address indexed staker, uint128 amount); /// @dev Nmx accrued to the staker

    constructor(
        address _nmx,
        address _stakingToken,
        address _nmxSupplier
    ) {
        nmx = _nmx;
        stakingToken = _stakingToken;
        nmxSupplier = _nmxSupplier;
        staker = address(0);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("StakingService")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /**
     @dev Throws if called by any account other than the staker.
     */
    modifier onlyStaker() {
        require(staker == _msgSender(), "StakingService: caller is not the staker");
        _;
    }

    /**
     @dev function to stake permitted amount of LP tokens from uniswap contract
     @param amount of NMXLP to be staked in the service
     */
    function stake(uint128 amount) external {
        _stakeFrom(_msgSender(), _msgSender(), amount);
    }

    function stakeWithPermit(
        uint128 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IUniswapV2ERC20(stakingToken).permit(
            _msgSender(),
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        _stakeFrom(_msgSender(), _msgSender(), amount);
    }

    function stakeFor(address owner, uint128 amount) external {
        _stakeFrom(_msgSender(), owner, amount);
    }

    function stakeFrom(address owner, uint128 amount) external {
        _stakeFrom(owner, owner, amount);
    }

    function _stakeFrom(address sourceOfFunds, address owner, uint128 amount) private whenNotPaused onlyStaker {
        bool transferred =
        IERC20(stakingToken).transferFrom(
            sourceOfFunds,
            address(this),
            uint256(amount)
        );
        require(transferred, "NmxStakingService: LP_FAILED_TRANSFER");

        Staker storage staker = updateStateAndStaker(owner);

        emit Staked(owner, amount);
        state.totalStaked += amount;
        staker.amount += amount;
    }

    /**
     @dev function to unstake LP tokens from the service and transfer to uniswap contract
     @param amount of NMXLP to be unstaked from the service
     */
    function unstake(uint128 amount) external {
        _unstake(_msgSender(), _msgSender(), amount);
    }

    function unstakeTo(address to, uint128 amount) external {
        _unstake(_msgSender(), to, amount);
    }

    function unstakeWithAuthorization(
        address owner,
        uint128 amount,
        uint128 signedAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(amount <= signedAmount, "NmxStakingService: INVALID_AMOUNT");
        verifySignature(
            UNSTAKE_TYPEHASH,
            owner,
            _msgSender(),
            signedAmount,
            deadline,
            v,
            r,
            s
        );
        _unstake(owner, _msgSender(), amount);
    }

    function _unstake(
        address from,
        address to,
        uint128 amount
    ) private {
        Staker storage staker = updateStateAndStaker(from);
        require(staker.amount >= amount, "NmxStakingService: NOT_ENOUGH_STAKED");

        emit Unstaked(from, to, amount);
        state.totalStaked -= amount;
        staker.amount -= amount;

        bool transferred = IERC20(stakingToken).transfer(to, amount);
        require(transferred, "NmxStakingService: LP_FAILED_TRANSFER");
    }

    /**
     * @dev updates current reward and transfers it to the caller's address
     */
    function claimReward() external returns (uint256) {
        Staker storage staker = updateStateAndStaker(_msgSender());
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        _claimReward(staker, _msgSender(), _msgSender(), unclaimedReward);
        return unclaimedReward;
    }

    function claimRewardTo(address to) external returns (uint256) {
        Staker storage staker = updateStateAndStaker(_msgSender());
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        _claimReward(staker, _msgSender(), to, unclaimedReward);
        return unclaimedReward;
    }

    function claimRewardToWithoutUpdate(address to) external returns (uint256) {
        Staker storage staker = stakers[_msgSender()];
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        _claimReward(staker, _msgSender(), to, unclaimedReward);
        return unclaimedReward;
    }

    function claimWithAuthorization(
        address owner,
        uint128 nmxAmount,
        uint128 signedAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(nmxAmount <= signedAmount, "NmxStakingService: INVALID_NMX_AMOUNT");
        verifySignature(
            CLAIM_TYPEHASH,
            owner,
            _msgSender(),
            signedAmount,
            deadline,
            v,
            r,
            s
        );

        Staker storage staker = updateStateAndStaker(owner);
        _claimReward(staker, owner, _msgSender(), nmxAmount);
    }

    function updateStateAndStaker(address stakerAddress)
    private
    returns (Staker storage staker)
    {
        updateHistoricalRewardRate();
        staker = stakers[stakerAddress];

        uint128 unrewarded = uint128(((state.historicalRewardRate - staker.initialRewardRate) * staker.amount) >> 40);
        emit StakingBonusAccrued(stakerAddress, unrewarded);

        staker.initialRewardRate = state.historicalRewardRate;
        staker.reward += unrewarded;
    }

    function _claimReward(
        Staker storage staker,
        address from,
        address to,
        uint128 amount
    ) private {
        require(!claimRewardPaused, "NmxStakingService: CLAIM_REWARD_PAUSED");
        assert(staker.reward >= staker.claimedReward);
        uint128 unclaimedReward = staker.reward - uint128(staker.claimedReward);
        require(amount <= unclaimedReward, "NmxStakingService: NOT_ENOUGH_BALANCE");
        emit Rewarded(from, to, amount);
        staker.claimedReward += amount;
        bool transferred = IERC20(nmx).transfer(to, amount);
        require(transferred, "NmxStakingService: NMX_FAILED_TRANSFER");
    }

    function verifySignature(
        bytes32 typehash,
        address owner,
        address spender,
        uint128 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        require(deadline >= block.timestamp, "NmxStakingService: EXPIRED");
        bytes32 digest =
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        typehash,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "NmxStakingService: INVALID_SIGNATURE"
        );
    }

    /**
     * @dev updates state and returns unclaimed reward amount. Is supposed to be invoked as call from metamask to display current amount of Nmx available
     */
    function getReward() external returns (uint256 unclaimedReward) {
        Staker memory staker = updateStateAndStaker(_msgSender());
        assert(staker.reward >= staker.claimedReward);
        unclaimedReward = staker.reward - staker.claimedReward;
    }

    function updateHistoricalRewardRate() public {
        uint256 currentNmxSupply = INmxSupplier(nmxSupplier).supplyNmx(uint40(block.timestamp));
        if (currentNmxSupply == 0) return;
        if (state.totalStaked != 0) {
            uint128 additionalRewardRate = uint128((currentNmxSupply << 40) / state.totalStaked);
            state.historicalRewardRate += additionalRewardRate;
        } else {
            bool transferred = ERC20(nmx).transfer(owner(), currentNmxSupply);
            require(transferred, "NmxStakingService: NMX_FAILED_TRANSFER");
        }
    }

    function changeNmxSupplier(address newNmxSupplier) external onlyOwner {
        nmxSupplier = newNmxSupplier;
    }

    function setStaker(address newStaker) external onlyOwner {
        staker = newStaker;
    }

    function totalStaked() external view returns (uint128) {
        return state.totalStaked;
    }

    function getRecoverableAmount(address tokenAddress) override internal view returns (uint256) {
        // there is no way to know exact amount of nmx service owns to the stakers
        require(tokenAddress != nmx, 'NmxStakingService: INVALID_RECOVERABLE_TOKEN');
        if (tokenAddress == stakingToken) {
            uint256 _totalStaked = state.totalStaked;
            uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
            assert(balance >= _totalStaked);
            return balance - _totalStaked;
        }
        return RecoverableByOwner.getRecoverableAmount(tokenAddress);
    }

    function setClaimRewardPaused(bool _claimRewardPaused) external onlyOwner {
        claimRewardPaused = _claimRewardPaused;
    }
}