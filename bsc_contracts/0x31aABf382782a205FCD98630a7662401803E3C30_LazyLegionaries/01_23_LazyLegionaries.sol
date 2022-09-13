// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "./EmergencyWithdrawable.sol";
import "./IExperienceTracker.sol";
import "./TrainerLib.sol";


contract LazyLegionaries is KeeperCompatibleInterface, EmergencyWithdrawable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using TrainerLib for address;

    event LazyLegionariesAdded(address indexed owner, uint256 indexed tokenId);
    event LazyLegionariesRemoved(address indexed owner, uint256 indexed tokenId);
    event PerformedAction(address indexed owner, uint256 indexed tokenId, uint256 creditSpend);
    event CreditDeposited(address indexed owner, uint256 deposited, uint256 newBalance);
    event CreditWithdrawn(address indexed owner, uint256 withdrawn);
    event LazyTrainFeeUpdated(uint256 newFee);
    event LazyLevelUpFeeUpdated(uint256 newFee);

    struct ActionItem {
        uint16 tokenId;
        uint160 xp;
        uint16 level;
        bool initialize;
        bool preTrainLevelUp;
        bool train;
        bool postTrainLevelUp;
    }


    IExperienceTracker private constant _xp = IExperienceTracker(0x61300Fb6b6eF8482430ecceb116221ec835f4F91);
    address private constant _trainer = 0x8b8E25CCf29b70ed1D69E5DE5DB4489356EB3559;
    IERC721Enumerable private constant _chainLegion = IERC721Enumerable(0x820B46240bcFCd95ecfE31692a811A2e561598EA);

    uint256 public constant trainFee = 0.0005 ether;
    uint256 private constant _maxLevel = 100;
    uint256 private constant _xpGains = 150;

    uint256 public lazyTrainFee = 0.0003 ether;
    uint256 public lazyLevelUpFee = 0.0002 ether;
    uint256 public totalLazyLegionaries;

    uint256[_maxLevel] private _xpForLevel;
    mapping(address => uint256) private _credits;
    mapping(address => EnumerableSet.UintSet) private _lazyLegionaries;
    EnumerableSet.AddressSet private _lazyOwners;
    

    constructor() {
        for (uint256 level = 1; level < _maxLevel; ++level) {
            _xpForLevel[level] = _calculateXpForLevel(level);
        }
    }


    function batchLevelUp(uint256[] memory tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _xp.levelUp(tokenIds[i]);
        }
    }

    function batchInitialize(uint256[] memory tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _xp.initialize(tokenIds[i]);
        }
    }

    function batchTrain(uint256[] memory tokenIds) external whenNotPaused payable {
        require(msg.value == tokenIds.length * trainFee, "Traning fees do not match");
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            _trainer.train(tokenIds[i]);
        }
    }

    function setLazyTrainFee(uint256 _lazyTrainFee) external onlyOwner {
        lazyTrainFee = _lazyTrainFee;
        emit LazyTrainFeeUpdated(_lazyTrainFee);
    }

    function setLazyLevelUpFee(uint256 _lazyLevelUpFee) external onlyOwner {
        lazyLevelUpFee = _lazyLevelUpFee;
        emit LazyLevelUpFeeUpdated(_lazyLevelUpFee);
    }

    function pause() external onlyOwner() {
        _pause();
    }

    function unpause() external onlyOwner() {
        _unpause();
    }

    function getActions() public view returns(ActionItem[] memory actions, uint256 validActions) {
        actions = new ActionItem[](totalLazyLegionaries);
        uint256 actionIndex;

        for (uint256 ownerId = 0; ownerId < _lazyOwners.length(); ++ownerId) {
            address owner = _lazyOwners.at(ownerId);
            uint256 balance = _lazyLegionaries[owner].length();

            uint256 credits = _credits[owner];

            for (uint256 i = 0; i < balance; ++i) {
                uint256 tokenId = _lazyLegionaries[owner].at(i);
                
                if (_chainLegion.ownerOf(tokenId) != owner) {
                    continue;
                }

                uint256 level = _xp.getLevel(tokenId);
                uint256 xp = _xp.getXp(tokenId);
                if (level == 0 && credits >= lazyLevelUpFee) {
                    actions[actionIndex].initialize = true;
                    level += 1;
                    credits -= lazyLevelUpFee;
                } 
                
                if (xp >= _xpForLevel[level+1] && credits >= lazyLevelUpFee) {
                    actions[actionIndex].preTrainLevelUp = true;
                    level += 1;
                    credits -= lazyLevelUpFee;
                }

                if (credits >= (lazyTrainFee + trainFee) && _trainer.canTrain(tokenId)) {
                    actions[actionIndex].train = true;
                    credits -= (lazyTrainFee + trainFee);

                    if (credits >= lazyLevelUpFee && (xp + _xpGains) >= _xpForLevel[level+1]) {
                        actions[actionIndex].postTrainLevelUp = true;
                        credits -= lazyLevelUpFee;
                    }
                }

                if (actions[actionIndex].train || actions[actionIndex].preTrainLevelUp || actions[actionIndex].initialize) {
                    actions[actionIndex].tokenId = uint16(tokenId);
                    actions[actionIndex].xp = uint160(xp);
                    actions[actionIndex].level = uint16(level);
                    actionIndex++;
                }
            }
        }
        validActions = actionIndex;
    }

    function performActions(ActionItem[] memory actions) public whenNotPaused {
        for (uint256 i = 0; i < actions.length; ++i) {
            ActionItem memory action = actions[i];
            uint256 tokenId = uint256(action.tokenId);
            address tokenOwner = _chainLegion.ownerOf(tokenId);

            // check if the current owner added them or if it was done by previous owner
            if (!_lazyLegionaries[tokenOwner].contains(tokenId)) {
                continue;
            }

            uint256 lazyFees = 
                (action.initialize ? lazyLevelUpFee : 0)
                + (action.preTrainLevelUp ? lazyLevelUpFee : 0)
                + (action.train ? lazyTrainFee : 0)
                + (action.postTrainLevelUp ? lazyLevelUpFee : 0);
            uint256 totalFees = lazyFees + (action.train ? trainFee : 0);

            if (totalFees == 0 || _credits[tokenOwner] < totalFees) {
                continue;
            }

            _credits[tokenOwner] -= totalFees;
            _credits[owner()] += lazyFees;

            if (action.initialize) {
                _xp.initialize(tokenId);
            }

            if (action.preTrainLevelUp) {
                _xp.levelUp(tokenId);
            }

            if (action.train) {
                _trainer.train(tokenId);

                if (action.postTrainLevelUp) {
                    _xp.levelUp(tokenId);                    
                }
            }

            emit PerformedAction(tokenOwner, tokenId, totalFees);
        }
    }

    function addLazyLegionaries(uint256[] memory tokenIds) external whenNotPaused {
        uint256 added = 0;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(_chainLegion.ownerOf(tokenIds[i]) == msg.sender, "Need to own the token");
            if (_lazyLegionaries[msg.sender].add(tokenIds[i])) { 
                emit LazyLegionariesAdded(msg.sender, tokenIds[i]);
                added++; 
            }
        }
        if (added > 0) {
            _lazyOwners.add(msg.sender);
        }
        totalLazyLegionaries += added;
    }

    function removeLazyLegionaries(uint256[] memory tokenIds) external {
        uint256 removed = 0;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (_lazyLegionaries[msg.sender].remove(tokenIds[i])) {
                emit LazyLegionariesRemoved(msg.sender, tokenIds[i]);
                removed++;
            }
        }
        totalLazyLegionaries -= removed;
        if (_lazyLegionaries[msg.sender].length() == 0) {
            _lazyOwners.remove(msg.sender);
        }
    }

    function removeTransferedLazyLegionaries(address[] memory previousOwners, uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            require(_chainLegion.ownerOf(tokenIds[i]) != previousOwners[i], "Still owns the token");
            require(_lazyLegionaries[previousOwners[i]].remove(tokenIds[i]), "Token not registered");
            emit LazyLegionariesRemoved(previousOwners[i], tokenIds[i]);

            if (_lazyLegionaries[previousOwners[i]].length() == 0) {
                _lazyOwners.remove(previousOwners[i]);
            }
        }
        totalLazyLegionaries -= tokenIds.length;
    }

    function withdrawCredits() external {
        uint256 credits = _credits[msg.sender];
        _credits[msg.sender] = 0;
        emit CreditWithdrawn(msg.sender, credits);
        if (credits > 0) {
            payable(msg.sender).transfer(credits);
        }
    }

    function depositCredits() external whenNotPaused payable {
        _credits[msg.sender] += msg.value;
        _lazyOwners.add(msg.sender);
        emit CreditDeposited(msg.sender, msg.value, _credits[msg.sender]);
    }

    function getCredits(address owner) external view returns (uint256) {
        return _credits[owner];
    }

    function getLazyLegionair(address owner) external view returns (uint256[] memory) {
        return _lazyLegionaries[owner].values();
    }

    function getLazyOwners() external view returns (address[] memory) {
        return _lazyOwners.values();
    }

    function _calculateXpForLevel(uint256 level_) private pure returns(uint256) {
        return (5 * (2*level_**3 + 3*level_**2 + 37*level_ - 42)) / 3;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        (ActionItem[] memory actions, uint256 validActions) = getActions();
        upkeepNeeded = !paused() && (validActions > 0);

        if (upkeepNeeded) {
            if (validActions != actions.length) {
                ActionItem[] memory actions_ = new ActionItem[](validActions);
                for (uint256 i = 0; i < validActions; ++i) {
                    actions_[i] = actions[i];
                }
                performData = abi.encode(actions_);
            } else {
                performData = abi.encode(actions);
            }
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        ActionItem[] memory actions = abi.decode(performData, (ActionItem[]));
        performActions(actions);
    }
}