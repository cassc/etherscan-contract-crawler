// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface MEME721 {
    function totalSupply(uint256 _id) external view returns (uint256);

    function maxSupply(uint256 _id) external view returns (uint256);

    function mint(address _to, uint256 _baseTokenID) external returns (uint256);

    function create(uint256 _maxSupply) external returns (uint256 tokenId);
}

contract MemeTokenWrapper {
    using SafeMath for uint256;
    IERC20 public meme;

    constructor(IERC20 _memeAddress) {
        meme = IERC20(_memeAddress);
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        meme.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        meme.transfer(msg.sender, amount);
    }
}

contract GenesisPool is MemeTokenWrapper, Ownable, AccessControlEnumerable {
    using SafeMath for uint256;

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    uint256 public maxStake = 5;
    uint256 public stakeStartTime;

    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) public points;
    mapping(uint256 => uint256) public cards;
    mapping(uint256 => address) public nftAddresses;

    event CardAdded(uint256 card, uint256 points);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Redeemed(address indexed user, uint256 amount);
    event WithdrawPoint(address indexed user, uint256 amount);

    modifier updateReward(address account) {
        if (account != address(0)) {
            points[account] = earned(account);
            lastUpdateTime[account] = block.timestamp;
        }
        _;
    }

    constructor(IERC20 _memeToken) MemeTokenWrapper(_memeToken) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setMaxStake(uint256 _maxStake) public onlyOwner {
        maxStake = _maxStake;
    }

    function setStakeStartTime(uint256 _stakeStartTime) public onlyOwner {
        stakeStartTime = _stakeStartTime;
    }

    function addCard(
        uint256 amount,
        uint256 pointsNeed,
        address nftAddress
    ) public onlyOwner {
        uint256 cardId = MEME721(nftAddress).create(amount);
        cards[cardId] = pointsNeed * 1e18;
        nftAddresses[cardId] = nftAddress;
        emit CardAdded(cardId, pointsNeed);
    }

    function earned(address account) public view returns (uint256) {
        uint256 blockTime = block.timestamp;
        if (stakeStartTime >= blockTime) return 0;
        uint256 updateTime = lastUpdateTime[account] > stakeStartTime
            ? lastUpdateTime[account]
            : stakeStartTime;
        return
            points[account].add(
                blockTime.sub(updateTime).mul(balanceOf(account)).div(86400)
            );
    }

    // stake visibility is public as overriding MemeTokenWrapper's stake() function
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(block.timestamp >= stakeStartTime, "stake not open");
        if (maxStake > 0)
            require(
                amount.add(balanceOf(msg.sender)) <= maxStake * 1e18,
                "Cannot stake more meme"
            );

        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");

        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
    }

    function redeem(uint256 cardID) public updateReward(msg.sender) {
        require(cards[cardID] != 0, "Card not found");
        require(
            points[msg.sender] >= cards[cardID],
            "Not enough points to redeem for card"
        );
        require(
            MEME721(nftAddresses[cardID]).totalSupply(cardID) <
                MEME721(nftAddresses[cardID]).maxSupply(cardID),
            "Max cards minted"
        );

        points[msg.sender] = points[msg.sender].sub(cards[cardID]);
        uint256 tokenID = MEME721(nftAddresses[cardID]).mint(msg.sender, cardID);
        emit Redeemed(msg.sender, tokenID);
    }

    function withdrawPoint(address account)
        external
        updateReward(account)
        onlyRole(WITHDRAW_ROLE)
        returns (uint256)
    {
        uint256 point = points[account];
        points[account] = 0;

        emit WithdrawPoint(account, point);

        return point;
    }
}