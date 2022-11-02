// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IGasToken {
    function mint(address _token, uint256 _amount) external;
}

struct Deposit {
    uint256 amount;
    uint256 preAmount;
    uint256 finalAmount;
    uint256 withdrawAmount;
    uint8 ratePercent;
    uint32 createTimestamp;
    uint32 startFinalPayTimestamp;
    uint32 endFinalPayTimestamp;
    uint32 drawableTimestamp;
    uint8 status;
}

interface IBankLink {
    function depositList(address addr,uint256 offset, uint256 size) external view returns (Deposit[] memory results, uint256 total);
    function followList(address addr) external view returns (address[] memory addrs, uint256[] memory levels);
    function accountInfo(address addr) external view returns (address parent, uint8 level, uint256 id);
    function accountFlowIns(address addr) external view returns(uint256);
}

contract INONFT is Context, AccessControl, ERC721Enumerable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private baseTokenURI = "";

    address usdt = 0xD83ba15A1e3e9ff17E817C57e550465414D5b887;
    address gas = 0x11Fde929C835fB7aC499ab8a42563cEcFA550867;
    address blc = 0x3F48700b2C17f1CF5fB3C15FF1f882c5DC5527eB;
    address bank = 0x3ed2bB2B90A68aB7b4882c3591A0F62c30163268;

    struct Stage {
        uint32 count;
        uint32 period;
        uint32 releaseTimes;
        uint32 firstReleaseTime;
        bool status;
        uint256 price;
        uint256 amount;
    }
    struct Reward {
        uint8 stageId;
        uint32 remainHarvestTimes;
        uint32 nextHarvestTime;
    }
    mapping(uint8 => Stage) public stages;
    mapping(uint256 => Reward) public rewards;
    mapping(address => mapping(uint8 => bool)) public assets;

    constructor() ERC721("INO-NFT", "INO") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OPERATOR_ROLE, _msgSender());
    }

    function init(address _usdt, address _gas, address _blc, address _bank) external onlyRole(OPERATOR_ROLE) {
        usdt = _usdt;
        gas = _gas;
        blc = _blc;
        bank = _bank;
    }

    function settle(address _token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(_token).safeTransfer(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "INONFT: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenURI, Strings.toString(rewards[tokenId].stageId), ".json"));
    }

    function setBaseTokenURI(string calldata uri) external onlyRole(OPERATOR_ROLE) {
        baseTokenURI = uri;
    }

    function setStage(
        uint8 stageId,
        uint32 _count,
        uint32 _period,
        uint32 _releaseTimes,
        uint32 _firstReleaseTime,
        bool _status,
        uint256 _amount,
        uint256 _price
    ) external onlyRole(OPERATOR_ROLE) {
        require(stageId != 0, "INONFT: stageId not allow zero.");
        stages[stageId] = Stage({
            count: _count, //
            period: _period,
            releaseTimes: _releaseTimes,
            firstReleaseTime: _firstReleaseTime,
            status: _status,
            amount: _amount,
            price: _price
        });
    }

    function setStageStatus(uint8 stageId, bool _status) external onlyRole(OPERATOR_ROLE) {
        stages[stageId].status = _status;
    }

    function mint(uint8 stageId) external {
        Stage memory stage = stages[stageId];
        require(stage.status, "INONFT: this stage is closed.");
        require(stage.count > 0, "INONFT: this stage is sell out.");

        require(checkLevel(msg.sender, stageId), "INONFT:flowIn or level too low");

        IERC20(usdt).safeTransferFrom(msg.sender, address(this), stage.price);
        IERC20(usdt).safeApprove(gas, stage.price);
        IGasToken(gas).mint(usdt, stage.price);

        IERC20(gas).safeTransfer(msg.sender, stage.price);
        Reward storage reward = rewards[_tokenIdTracker.current()];
        reward.stageId = stageId;
        reward.remainHarvestTimes = stage.releaseTimes;
        reward.nextHarvestTime = (stageId == 4) ? stage.firstReleaseTime : uint32(block.timestamp);

        stages[stageId].count -= 1;
        assets[msg.sender][stageId] = true;
        _mint(msg.sender, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function tokenIdList(address addr, uint256 offset, uint256 size) external view returns (uint256[] memory tokenIds, Reward[] memory results) {
        if(offset + size > balanceOf(addr)){
            size = balanceOf(addr) - offset;
        }
        tokenIds = new uint256[](size);
        results = new Reward[](size);
        for (uint256 i = 0; i < size; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(addr, i + offset);
            tokenIds[i] = tokenId;
            results[i] = rewards[tokenId];
        }
    }

    function harvest(uint256[] calldata tokenIds) external {
        uint256 drawable = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            Reward storage reward = rewards[tokenId];
            Stage memory stage = stages[reward.stageId];
            if (ownerOf(tokenId) == msg.sender && reward.remainHarvestTimes > 0 && block.timestamp >= reward.nextHarvestTime) {
                if (rewards[tokenId].remainHarvestTimes == stage.releaseTimes) {
                    drawable += stage.amount / 5;
                } else {
                    drawable += ((stage.amount / 5) * 4) / (stage.releaseTimes - 1);
                }
                reward.remainHarvestTimes -= 1;
                reward.nextHarvestTime = uint32(block.timestamp + stage.period);
            }
        }
        if (drawable > 0) {
            IERC20(blc).safeTransfer(msg.sender, drawable);
        }
    }

    function checkLevel(address addr, uint8 stageId) public view returns (bool result) {
        if (assets[addr][stageId]) {
            return false;
        }
        if(stageId == 1) {
            uint256 flowIn = IBankLink(bank).accountFlowIns(addr);
            if(flowIn >= 4000e18) {
                return true;
            }
        }else if(stageId == 2){
            (, uint8 level, ) = IBankLink(bank).accountInfo(addr);
            if(level >= 2) {
                return true;
            }
        }else if(stageId == 3){
            (, uint8 level, ) = IBankLink(bank).accountInfo(addr);
            if (level >= 5) {
                return true;
            }
        }
        
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}