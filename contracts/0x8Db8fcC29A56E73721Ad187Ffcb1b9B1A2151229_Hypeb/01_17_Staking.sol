// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./IHypebItems.sol";
import "./HypeBears.sol";


contract Hypeb {

    address public operator;

    uint256 public totalSupply;

    bool public paused;

    IERC721 public hypebearsWalking;
    IERC721 public hypebears;
    IHypebItems public itemsContract;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => Hypebear[]) internal stakers;
    mapping(address => Hypebear[]) internal stakersWalking;

    uint256[] public bonusLevels;
    //      levels  => percent bonus
    mapping(uint256 => uint256) public levelPercent;


    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    uint256 public rewardAmount = 1;
    uint256 public rewardPeriod = 1 days;

    struct Hypebear {
        uint256 stakedTimestamp;
        uint256 tokenId;
    }

    struct Item {
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 price;
    }

    uint256 public totalItemIdAmount;
    //          id    =>  amounts
    mapping(uint256 => Item) public items;

    mapping(address => uint256) public lastClaim;

    mapping(address => bool) public blackList;

    function name() external pure returns (string memory) {
        return "HYPEB";
    }

    function symbol() external pure returns (string memory) {
        return "HYPEB";
    }

    function decimals() external pure returns (uint8) {
        return 0;
    }


    constructor(address _hypebears, address _hypebearsWalking) {
        operator = msg.sender;
        hypebears = IERC721(_hypebears);
        hypebearsWalking = IERC721(_hypebearsWalking);
        _status = _NOT_ENTERED;
        bonusLevels.push(3);
        bonusLevels.push(5);
        bonusLevels.push(10);
        levelPercent[1] = 5;
        levelPercent[2] = 10;
        levelPercent[3] = 22;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        require(!blackList[msg.sender], "Address Blocked");
        _transfer(msg.sender, to, value);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external whenNotPaused returns (bool) {
        require(!blackList[msg.sender], "Address Blocked");
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= value;
        }

        _transfer(from, to, value);

        return true;
    }

    //
    //    Staking
    //

    function totalStakedBy(address _staker) public view returns(uint256) {
        return (stakers[_staker].length + stakersWalking[_staker].length);
    }

    function hypebearsOfStaker(address _staker, bool _walking) public view returns (uint256[] memory) {
        Hypebear[] memory st = _walking ? stakersWalking[_staker] : stakers[_staker];
        uint256[] memory tokenIds = new uint256[](st.length);
        for (uint256 i = 0; i < st.length; i++) {
            tokenIds[i] = st[i].tokenId;
        }
        return tokenIds;
    }

    function stake(uint256[] memory _hypebears, bool _walking) public nonReentrant whenNotPaused {
        if (totalStakedBy(msg.sender) > 0) {
            withdrawTo(msg.sender);
        }
        IERC721 hb = _walking ? IERC721(hypebearsWalking) : IERC721(hypebears);
        Hypebear[] storage st = _walking ? stakersWalking[msg.sender] : stakers[msg.sender];

        for (uint256 i = 0; i < _hypebears.length; i++) {
            require(hb.ownerOf(_hypebears[i]) == msg.sender, "Not owner");

            hb.transferFrom(msg.sender, address(this), _hypebears[i]);

            st.push(Hypebear(block.timestamp, _hypebears[i]));
        }
    }

    function removeIdsFromStaker(Hypebear[] storage st, uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            for (uint256 j = 0; j < st.length; j++) {
                if (_tokenIds[i] == st[j].tokenId) {
                    st[j] = st[st.length - 1];
                    st.pop();
                }
            }
        }
    }

    function unstake(uint256[] calldata _tokenIds, bool _walking) external nonReentrant whenNotPaused {
        require(!blackList[msg.sender], "Address Blocked");
        IERC721 hb = _walking ? IERC721(hypebearsWalking) : IERC721(hypebears);
        Hypebear[] storage st = _walking ? stakersWalking[msg.sender] : stakers[msg.sender];
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            bool owned;
            for (uint256 j = 0; j < st.length; j++) {
                if (st[j].tokenId == _tokenIds[i]) {
                    owned = true;
                }
            }
            require(owned, "NOT OWNED");
            hb.transferFrom(address(this), msg.sender, _tokenIds[i]);
        }
        withdrawTo(msg.sender);
        removeIdsFromStaker(st, _tokenIds);
    }

    function emergencyWithdrawNFT() external nonReentrant whenNotPaused {
        require(!blackList[msg.sender], "Address Blocked");
        IERC721 hbw = IERC721(hypebearsWalking);
        Hypebear[] storage stw = stakersWalking[msg.sender];
        for (uint256 j = 0; j < stw.length; j++) {
            hbw.transferFrom(address(this), msg.sender, stw[j].tokenId);
        }
        delete stakersWalking[msg.sender];

        IERC721 hb = IERC721(hypebears);
        Hypebear[] storage st = stakers[msg.sender];
        for (uint256 j = 0; j < st.length; j++) {
            hb.transferFrom(address(this), msg.sender, st[j].tokenId);
        }
        delete stakers[msg.sender];
    }


    function claim() external nonReentrant whenNotPaused {
        require(!blackList[msg.sender], "Address Blocked");
        withdrawTo(msg.sender);
    }

    function withdrawTo(address to) internal {
        uint256 reward = calculateRewards(to);
        if (reward > 0) {
            lastClaim[msg.sender] = block.timestamp;
            _mint(to, reward);
        }
    }

    function calculateRewards(address _staker) public view returns(uint256) {
        uint256 HypebAmount;
        HypebAmount += _calculateRewards(stakers[_staker], lastClaim[_staker]);
        HypebAmount += _calculateRewards(stakersWalking[_staker], lastClaim[_staker]);
        HypebAmount += HypebAmount * calculateBalanceBonus(totalStakedBy(_staker)) / 100;
        return HypebAmount;
    }

    function _calculateRewards(Hypebear[] memory st, uint256 _lastClaim) internal view returns(uint256) {
        uint256 result;
        uint256 stakerBalance = st.length;
        for (uint256 i = 0; i < stakerBalance; i++) {
            result +=
            calculateHypeb(
                _lastClaim,
                st[i].stakedTimestamp,
                block.timestamp
            );
        }
        return result;
    }

    function calculateBalanceBonus(uint256 balance) public view returns(uint256) {
        for (uint256 i = 0; i < bonusLevels.length; i++) {
            if (balance < bonusLevels[i]) return levelPercent[i];
        }
        return levelPercent[bonusLevels.length];
    }

    function getAllBonusesByTokenAmount() external view returns(uint256[] memory) {
        uint256[] memory percents = new uint256[](bonusLevels[bonusLevels.length - 1]);
        for (uint256 i = 0; i < percents.length; i++) {
            percents[i] = calculateBalanceBonus(i+1);
        }
        return percents;
    }

    function calculateHypeb(
        uint256 _lastClaimedTimestamp,
        uint256 _stakedTimestamp,
        uint256 _currentTimestamp
    ) internal view returns (uint256 hypeb) {

        _lastClaimedTimestamp = _lastClaimedTimestamp < _stakedTimestamp ? _stakedTimestamp : _lastClaimedTimestamp;
        uint256 unclaimedTime = _currentTimestamp - _lastClaimedTimestamp;
        hypeb = unclaimedTime * rewardAmount/ rewardPeriod;

    }
    //
    //    Items
    //
    function createItem(uint256 maxSupply, string calldata uri, uint256 _price) external onlyOperator {
        uint256 id = itemsContract.create(maxSupply, uri);
        items[id].maxSupply = maxSupply;
        items[id].price = _price;
        totalItemIdAmount = id;
    }

    function updateItem(uint256 id, uint256 maxSupply, uint256 _price, string calldata uri) external onlyOperator {
        items[id].maxSupply = maxSupply;
        items[id].price = _price;
        if (bytes(uri).length > 0) {
            itemsContract.setURI(uri, id);
        }
    }

    function mintItem(uint256 id, uint256 amount) external {
        require(balanceOf[msg.sender] >= items[id].price * amount, "Insufficient balance");
        _burn(msg.sender, items[id].price * amount);
        itemsContract.mintItem(id, msg.sender, amount);
        items[id].totalSupply += amount;
    }

    function allItemsAmounts() external view returns (Item[] memory) {
        Item[] memory itemsList = new Item[](totalItemIdAmount);
        for (uint256 i = 0; i < itemsList.length; i++) {
            itemsList[i] = items[i + 1];
        }
        return itemsList;
    }

    function staker(address staker_) public view returns (Hypebear[] memory) {
        return stakers[staker_];
    }

    function stakerWalking(address staker_) public view returns (Hypebear[] memory) {
        return stakersWalking[staker_];
    }

    function updateItemsContract(address newAddress) external onlyOperator {
        itemsContract = IHypebItems(newAddress);
    }

    function updateBonusLevels(uint256[] memory levels, uint256[] memory percents) external onlyOperator {
        require(levels.length == percents.length,"Different lengths");
        delete bonusLevels;
        for (uint256 i = 0; i < levels.length; i++) {
            bonusLevels.push(levels[i]);
            levelPercent[i + 1] = percents[i];
        }
    }

    function updateRewardPeriod(uint256 newPeriod) external onlyOperator {
        rewardPeriod = newPeriod;
    }

    function updateRewardAmount(uint256 newAmount) external onlyOperator {
        rewardAmount = newAmount;
    }

    function setOperator(address _newOperator) external onlyOperator {
        operator = _newOperator;
    }

    function setPaused(bool _paused) external onlyOperator {
        paused = _paused;
    }

    function setHypebearsAddress(address _newAddress) external onlyOperator {
        hypebears = IERC721(_newAddress);
    }

    function setHypebearsWalkingAddress(address _newAddress) external onlyOperator {
        hypebearsWalking = IERC721(_newAddress);
    }

    function multipleBlacklist(address[] calldata addresses_, bool[] calldata statuses_) external onlyOperator {
        for (uint256 i = 0; i < addresses_.length; i++) {
            blackList[addresses_[i]] = statuses_[i];
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(balanceOf[from] >= value, "ERC20: transfer amount exceeds balance");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;

        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;

        emit Transfer(from, address(0), value);
    }


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    modifier onlyOperator() {
        require(msg.sender == operator, "NOT ALLOWED");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }


    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}