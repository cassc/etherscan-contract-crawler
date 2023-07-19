/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPlatform {
    struct Bounty {
        address gauge;
        address manager;
        address rewardToken;
        uint8 numberOfPeriods;
        uint256 endTimestamp;
        uint256 maxRewardPerVote;
        uint256 totalRewardAmount;
    }
    struct Upgrade {
        uint8 numberOfPeriods;
        uint256 totalRewardAmount;
        uint256 maxRewardPerVote;
        uint256 endTimestamp;
    }
    function createBounty(
        address gauge,
        address manager,
        address rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 totalRewardAmount,
        address[] calldata blacklist,
        bool upgradeable
    ) external returns (uint256 bountyId);
    function increaseBountyDuration(
        uint256 bountyId,
        uint8 additionalPeriod,
        uint256 increasedAmount,
        uint256 newMaxPricePerVote
    ) external;
    function closeBounty(uint256 bountyId) external;
    function getActivePeriodPerBounty(uint256 bountyId) external returns(uint8);
    function bounties(uint256 bountyId) external returns(Bounty memory);
    function updateBountyPeriod(uint256 bountyId) external;
    function upgradeBountyQueue(uint256 bountyId) external returns(Upgrade memory);
}

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

contract VoteBountyManager is Owned {
    error ONGOING_BOUNTY();
    error NO_ONGOING_BOUNTY();
    error BOUNTY_NOT_CLOSED();
    error BOUNTY_NOT_UPGRADEABLE();
    error NO_UPDATE_TO_DO();

    struct BountyData {
        address gauge;
        address rewardToken;
        uint8 numberOfPeriods;
        uint8 targetDuration;
        uint256 maxRewardPerVote;
        address[] blacklist;
    }

    BountyData public bountyData;
    IPlatform public platform;
    uint256 public bountyId;

    event BountyCreated(uint256 bountyId);
    event BountyUpdated(uint256 bountyId, uint256 additionalPeriod, uint256 amountIncreased);
    event BountyClosed(uint256 bountyId);

    constructor(BountyData memory _bountyData, address _owner, address _platform) Owned(_owner) {
        bountyData = _bountyData;
        platform = IPlatform(_platform);
        ERC20(bountyData.rewardToken).approve(_platform, type(uint256).max);
    }

    /// @notice Creates a new bounty
    function createBounty() external {
        if (bountyId != 0) revert ONGOING_BOUNTY(); 
        bountyId = platform.createBounty(
            bountyData.gauge,
            address(this),
            bountyData.rewardToken,
            bountyData.numberOfPeriods,
            bountyData.maxRewardPerVote,
            ERC20(bountyData.rewardToken).balanceOf(address(this)),
            bountyData.blacklist,
            true
        );
        emit BountyCreated(bountyId);
    }

    /// @notice Update an ongoing bounty if not expired  
    function updateBounty() external {
        if (bountyId == 0) revert NO_ONGOING_BOUNTY();
        if (bountyData.targetDuration == 0) revert BOUNTY_NOT_UPGRADEABLE();
        // check if there is any upgrade in queue
        IPlatform.Upgrade memory upgrade = platform.upgradeBountyQueue(bountyId);
        uint8 bountyDuration;
        if (upgrade.numberOfPeriods == 0) {
            IPlatform.Bounty memory bounty = platform.bounties(bountyId);
            bountyDuration = bounty.numberOfPeriods;
        } else {
            bountyDuration = upgrade.numberOfPeriods;
        }
        // calculate additional period
        uint8 activePeriod = platform.getActivePeriodPerBounty(bountyId);
        if (bountyData.targetDuration < bountyDuration - activePeriod) revert NO_UPDATE_TO_DO();
        uint8 additionalPeriods = bountyData.targetDuration - (bountyDuration - activePeriod);
        uint256 amount = ERC20(bountyData.rewardToken).balanceOf(address(this));
        platform.increaseBountyDuration(
            bountyId,
            additionalPeriods,
            amount,
            bountyData.maxRewardPerVote
        );
        platform.updateBountyPeriod(bountyId);
        emit BountyUpdated(bountyId, additionalPeriods, amount);
    }

    /// @notice Close a bounty
    /// @notice After this action a new bounty can be opened.
    function closeBounty() external {
        if (bountyId == 0) revert NO_ONGOING_BOUNTY();
        IPlatform.Bounty memory bounty = platform.bounties(bountyId);
        // if manager is zero it has been closed directly via platform
        if (bounty.manager != address(0)) {
            // check if the bounty can be closed
            if ((block.timestamp / 1 weeks) * 1 weeks < bounty.endTimestamp) revert BOUNTY_NOT_CLOSED();
            platform.closeBounty(bountyId);
        }
        bountyId = 0;
        emit BountyClosed(bountyId);
    }

    /// @notice Rescue any ERC20
    /// @param _token Token to rescue.
    /// @param _recipient Address to send the token
    /// @param _amount Amount to rescue
    function rescueERC20(address _token, address _recipient, uint256 _amount) external onlyOwner {
        ERC20(_token).transfer(_recipient, _amount);
    }

    /// @notice Set a target duration 
    /// @param _targetDuration Target duration.
    function setTargetDuration(uint8 _targetDuration) external onlyOwner {
        bountyData.targetDuration = _targetDuration;
    }

    /// @notice Set a max reward per vote
    /// @param _maxRewardPerVote Max reward per vote.
    function setMaxRewardPerVote(uint256 _maxRewardPerVote) external onlyOwner {
        bountyData.maxRewardPerVote = _maxRewardPerVote;
    }
}