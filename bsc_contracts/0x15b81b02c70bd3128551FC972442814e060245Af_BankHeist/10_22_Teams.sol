import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.7;

abstract contract ManageableUpgradeable is OwnableUpgradeable {
    mapping(address => bool) private _managers;
    event ManagerAdded(address indexed manager_);
    event ManagerRemoved(address indexed manager_);

    function managers(address manager_) public view virtual returns (bool) {
        return _managers[manager_];
    }

    modifier onlyManager() {
        require(_managers[_msgSender()], "Manageable: caller is not the owner");
        _;
    }

    function removeManager(address manager_) public virtual onlyOwner {
        _managers[manager_] = false;
        emit ManagerRemoved(manager_);
    }

    function addManager(address manager_) public virtual onlyOwner {
        require(
            manager_ != address(0),
            "Manageable: new owner is the zero address"
        );
        _managers[manager_] = true;
        emit ManagerAdded(manager_);
    }
}

interface IManager {
    function compoundHelper(
        uint256 id,
        uint256 externalRewards,
        address user
    ) external;

    function getNetDeposit(address user) external returns (int256);
}

interface ITeams {
    function getReferrer(address user) external view returns (address);

    function getReferred(address user) external view returns (address[] memory);
}

interface IBank {
    function addRewards(address token, uint256 amount) external;
}

interface IWETH {
    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    receive() external payable;

    function balanceOf(address) external view returns (uint256);
}

contract Teams is Initializable, OwnableUpgradeable, ManageableUpgradeable {
    address payable public BANK;
    address public MARKETING_WALLET;
    IERC20 public TOKEN;
    address public POOL;
    IManager public MANAGER;
    ITeams public TEAMS_V1;

    uint256 public changeTeamCost;
    uint256 public claimFee;
    uint256 public compoundFee;

    mapping(address => address) public referrers;
    mapping(address => address[]) public referred;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public claimedRewards;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public hasMerged;

    function initialize(
        address payable bank,
        address marketing,
        address token,
        address pool,
        address manager,
        address teamsv1
    ) public initializer {
        __Ownable_init();
        BANK = bank;
        MARKETING_WALLET = marketing;
        TOKEN = IERC20(token);
        POOL = pool;
        MANAGER = IManager(manager);
        TEAMS_V1 = ITeams(teamsv1);
        isExcludedFromFee[manager] = true;
        changeTeamCost = 0.25 ether;
        claimFee = 3000;
        compoundFee = 0;
    }

    function merge() public {
        referred[_msgSender()] = TEAMS_V1.getReferred(_msgSender());
        referrers[_msgSender()] = TEAMS_V1.getReferrer(_msgSender());
        hasMerged[_msgSender()] = true;
    }

    function getReferrer(address user) public view returns (address) {
        return
            referrers[user] == address(0) ? MARKETING_WALLET : referrers[user];
    }

    function getReferred(address user) public view returns (address[] memory) {
        return referred[user];
    }

    function availableRewards(address user) public view returns (uint256) {
        return rewards[user] - claimedRewards[user];
    }

    function joinTeam(address referrer) public payable {
        require(
            hasMerged[_msgSender()] && hasMerged[referrer],
            "JOIN: You and your boss must merge first."
        );
        require(referrer != _msgSender(), "JOIN: Can't join yourself...");
        if (getReferrer(_msgSender()) != MARKETING_WALLET) {
            require(
                msg.value == changeTeamCost,
                "JOIN: You must pay the change fee."
            );
        }

        if (address(this).balance > 0) {
            IWETH weth = IWETH(
                payable(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c)
            );
            weth.deposit{value: address(this).balance}();
            uint256 bal = weth.balanceOf(address(this));
            weth.transfer(BANK, bal);
            IBank(BANK).addRewards(
                0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c,
                bal
            );
        }

        address temp = referrers[_msgSender()];

        if (temp != address(0)) {
            address[] memory tempReferred = referred[temp];
            for (uint256 i = 0; i < tempReferred.length; i++) {
                if (tempReferred[i] == _msgSender()) {
                    tempReferred[i] = tempReferred[tempReferred.length - 1];
                    delete tempReferred[tempReferred.length - 1];
                    referred[temp] = tempReferred;
                    break;
                }
            }
        }

        referrers[_msgSender()] = referrer;
        referred[referrer].push(_msgSender());
    }

    function claimRewards() public {
        require(hasMerged[_msgSender()], "CLAIM: You must merge first.");
        uint256 availableRewards_ = availableRewards(_msgSender());
        require(availableRewards_ > 0, "CLAIM: No rewards");
        claimedRewards[_msgSender()] += availableRewards_;
        uint256 fee = (availableRewards_ * claimFee) / 10000;
        if (isExcludedFromFee[_msgSender()]) fee = 0;
        availableRewards_ -= fee;
        TOKEN.transferFrom(POOL, _msgSender(), availableRewards_);
    }

    function compoundRewards(uint256[] memory ids) public {
        require(hasMerged[_msgSender()], "COMPOUND: You must merge first.");
        uint256 availableRewards_ = availableRewards(_msgSender());
        require(availableRewards_ > 0, "CLAIM: No rewards");
        claimedRewards[_msgSender()] += availableRewards_;
        uint256 rewardsPerNode = availableRewards_ / ids.length;
        for (uint256 i = 0; i < ids.length; i++) {
            MANAGER.compoundHelper(ids[i], rewardsPerNode, _msgSender());
        }
    }

    function addRewardsToReferrer(address user, uint256 amount)
        public
        onlyManager
    {
        address who = getReferrer(user);
        if (MANAGER.getNetDeposit(user) <= 0) who = MARKETING_WALLET;
        rewards[who] += amount;
    }

    function addRewards(address user, uint256 amount) public onlyManager {
        if (MANAGER.getNetDeposit(user) <= 0) user = MARKETING_WALLET;
        rewards[user] += amount;
    }

    function setRewards(address user, uint256 amount) public onlyOwner {
        rewards[user] = amount;
    }

    function setBank(address payable bank) public onlyOwner {
        BANK = bank;
    }

    function setToken(address token) public onlyOwner {
        TOKEN = IERC20(token);
    }

    function setPool(address pool) public onlyOwner {
        POOL = pool;
    }

    function setMarketing(address marketing) public onlyOwner {
        MARKETING_WALLET = marketing;
    }

    function setManager(address manager) public onlyOwner {
        MANAGER = IManager(manager);
    }

    function setTeam(address user, address referrer) public onlyOwner {
        referrers[user] = referrer;
        referred[referrer].push(user);
    }

    function setChangeTeamCost(uint256 amount) public onlyOwner {
        changeTeamCost = amount;
    }

    function setIsExcludedFromFee(address user, bool value) public onlyOwner {
        isExcludedFromFee[user] = value;
    }

    function setClaimFee(uint256 amount) public onlyOwner {
        claimFee = amount;
    }

    function setCompoundFee(uint256 amount) public onlyOwner {
        compoundFee = amount;
    }
}