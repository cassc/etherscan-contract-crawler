// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./library/PancakeLibrary.sol";
import "./interface/IPancakeRouter01.sol";
import "./interface/IPancakePair.sol";
import "./interface/IPancakeFactory.sol";
import "./interface/IMOB.sol";
import "./interface/IMTN.sol";

contract MOBLock is Ownable {
    using SafeERC20 for IERC20;
    using BitMaps for BitMaps.BitMap;

    struct LockInfo {
        uint256 base;
        uint256 claimed;
    }

    struct LockInfo2 {
        uint256 base;
        uint256 addLocked;
        uint256 locked;
        uint256 claimed;
    }

    event locked(address indexed adr, uint256 amount);

    event treasuryLocked(address indexed adr, uint256 amount);

    event lpLocked(address indexed adr, uint256 amount, uint256 expired);

    event AddPList(address indexed adr);

    event RemovePList(address indexed adr);

    address public mobAddress;

    address public nftAddress;

    address public pairAddress;

    uint256 public addEndTime;

    mapping(address => LockInfo) public lockPerTreasury;

    mapping(address => LockInfo2) public lockPerAccount;

    mapping(address => uint256) public addPerAccount;

    mapping(address => uint256) public addedLpPerAccount;

    mapping(address => uint256) public lockedLpPerAccount;

    mapping(address => uint256) public lpExpiredPerAccount;

    BitMaps.BitMap private pList;

    constructor(address _mobAddress, address _nftAddress) {
        mobAddress = _mobAddress;
        nftAddress = _nftAddress;
        pairAddress = IMOB(mobAddress).pair();
    }

    function lockTreasury(address adr, uint256 amount) external {
        require(msg.sender == mobAddress, "not allowed call");
        LockInfo storage info = lockPerTreasury[adr];
        info.base += amount;
        emit treasuryLocked(adr, amount);
    }

    function treasuryAvailableClaim(address adr, uint256 percent)
        public
        view
        returns (uint256 avl, uint256 claimed)
    {
        require(percent >= 0 && percent <= 100, "percent error");
        LockInfo memory info = lockPerTreasury[adr];
        uint256 total = (percent * info.base) / 100;
        if (total > info.claimed) {
            avl = total - info.claimed;
        }
        claimed = info.claimed;
    }

    function releaseTreasury(address adr, uint256 percent)
        external
        returns (uint256)
    {
        require(msg.sender == mobAddress, "not allowed call");
        require(percent >= 1 && percent <= 100, "percent error");
        LockInfo memory info = lockPerTreasury[adr];
        uint256 total = (percent * info.base) / 100;
        require(total > info.claimed, "already claimed");
        lockPerTreasury[adr].claimed = total;
        return total - info.claimed;
    }

    function lockNFT(
        address adr,
        uint256 init,
        uint256 amount
    ) external {
        require(msg.sender == mobAddress, "not allowed call");
        LockInfo2 storage info = lockPerAccount[adr];
        info.base += init;
        info.locked += amount;
        emit locked(adr, amount);
    }

    function addLiq(
        address adr,
        uint256 amount,
        uint256 addedLp
    ) external {
        require(msg.sender == mobAddress, "not allowed call");
        addPerAccount[adr] += amount;
        addedLpPerAccount[adr] += addedLp;
    }

    function lockLP() external {
        IMOB ppa = IMOB(mobAddress);
        require(block.timestamp < ppa.startTradeTime(), "can't lock now");
        uint256 add = addPerAccount[msg.sender];
        uint256 addedLp = addedLpPerAccount[msg.sender];
        require(add > 0 && addedLp > 0, "no added lp");
        uint256 lpBalance = IPancakePair(pairAddress).balanceOf(msg.sender);
        require(lpBalance >= addedLp, "lp balance not enough");
        IERC20(pairAddress).safeTransferFrom(
            msg.sender,
            address(this),
            lpBalance
        );
        lockedLpPerAccount[msg.sender] += lpBalance;
        uint256 expired;
        if (getPlist(msg.sender)) {
            expired = block.timestamp + 3 days;
        } else {
            expired = block.timestamp + 365 days * 3;
        }
        lpExpiredPerAccount[msg.sender] = expired;
        lockPerAccount[msg.sender].addLocked += add;
        delete addPerAccount[msg.sender];
        delete addedLpPerAccount[msg.sender];
        emit lpLocked(msg.sender, lpBalance, expired);
        IMTN nft = IMTN(nftAddress);
        uint256 nftLen = nft.balanceOf(msg.sender);
        for (uint256 i = 0; i < nftLen; ++i) {
            uint256 tokenId = nft.tokenOfOwnerByIndex(msg.sender, i);
            if (!nft.getTokenActivate(tokenId)) {
                nft.activateNFT(tokenId);
            }
        }
        ppa.removeBlist(msg.sender);
    }

    function withdrawLP() external {
        uint256 expired = lpExpiredPerAccount[msg.sender];
        uint256 lockedLP = lockedLpPerAccount[msg.sender];
        require(expired > 0 && lockedLP > 0, "no locked");
        require(expired <= block.timestamp, "no expired");
        IERC20(pairAddress).safeTransfer(msg.sender, lockedLP);
        delete lockedLpPerAccount[msg.sender];
        delete lpExpiredPerAccount[msg.sender];
    }

    function releaseNFT(address adr, uint256 percent)
        external
        returns (uint256 released, uint256 blackhole)
    {
        require(msg.sender == mobAddress, "not allowed call");
        require(percent >= 1 && percent <= 100, "percent error");
        LockInfo2 memory info = lockPerAccount[adr];
        require(info.base > 0, "can't release");
        uint256 total = (info.addLocked * info.locked) / info.base;
        uint256 release = (percent * total) / 100;
        require(release > info.claimed, "already claimed");
        if (info.claimed == 0) {
            blackhole = info.locked - total;
        }
        lockPerAccount[adr].claimed = release;
        released = release - info.claimed;
    }

    function nftAvailableClaim(address adr, uint256 percent)
        public
        view
        returns (uint256 avl, uint256 claimed)
    {
        require(percent >= 0 && percent <= 100, "percent error");
        LockInfo2 memory info = lockPerAccount[adr];
        if (info.base > 0) {
            uint256 total = (info.addLocked * info.locked) / info.base;
            uint256 release = (percent * total) / 100;
            avl = release - info.claimed;
            claimed = info.claimed;
        }
    }

    function addPlist(address[] calldata adrs) public onlyOwner {
        for (uint256 i = 0; i < adrs.length; ++i) {
            pList.set(uint256(uint160(adrs[i])));
            emit AddPList(adrs[i]);
        }
    }

    function removePlist(address[] calldata adrs) public onlyOwner {
        for (uint256 i = 0; i < adrs.length; ++i) {
            pList.unset(uint256(uint160(adrs[i])));
            emit RemovePList(adrs[i]);
        }
    }

    function getPlist(address adr) public view returns (bool) {
        return pList.get(uint256(uint160(adr)));
    }
}