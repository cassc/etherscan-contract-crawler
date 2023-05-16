// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/util/IERC20.sol";
import "contracts/util/SafeMath.sol";
import "contracts/util/IERC721.sol";
import "./interfaces/ILock.sol";
import "./interfaces/IERC721TokenReceiver.sol";

contract STARNFTPOOL is ERC721TokenReceiver {
    using SafeMath for uint;
    enum opreate {
        stake,
        upStake,
        claim
    }
    struct StakedInfo {
        uint index;
        uint stakedAmount;
        uint updateTime;
        uint available;
        uint accruedReward;
    }
    StakedInfo public globalStakedInfo;
    mapping(address => StakedInfo) public userStakedInfos;

    uint public startTime;

    mapping(address => uint[]) public ownerTokens;

    mapping(uint => address) public tokenToAddress;

    address public owner;
    address public starNft;
    address public asdic;
    address public lock;

    uint public yearHalfCount;
    uint public yearHalfAmount = 4000000e18;
    uint public subHalfTime = 365 days;

    constructor(address _asdic, address _lock, address _starNft) {
        owner = msg.sender;
        asdic = _asdic;
        lock = _lock;
        starNft = _starNft;
        IERC20(asdic).approve(lock, type(uint).max);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOwnerTokens(
        address account
    ) external view returns (uint[] memory) {
        return ownerTokens[account];
    }

    function setSubHalfTime(uint _time) external {
        require(msg.sender == owner, "No owner to set the time");
        subHalfTime = _time;
    }

    function setOwner(address _address) external onlyOwner returns (bool) {
        require(_address != address(0), "Pool Owner address can not zero");
        owner = _address;
        return true;
    }

    function updateIndex(opreate _oprea) internal {
        StakedInfo storage info = globalStakedInfo;
        if (info.updateTime == 0 || info.stakedAmount == 0) {
            info.updateTime = block.timestamp;
            info.stakedAmount += 1;
            halfYear();
            return;
        }

        uint release = halfYear();
        release = release.mul(block.timestamp - info.updateTime);
        release = release.div(info.stakedAmount);
        info.index += release;

        if (_oprea == opreate.stake) {
            info.stakedAmount += 1;
        }
        if (_oprea == opreate.upStake) {
            info.stakedAmount -= 1;
        }
        info.updateTime = block.timestamp;
    }

    function updateUserIndex(address user, opreate _oprea) internal {
        StakedInfo storage info = userStakedInfos[user];

        info.updateTime = block.timestamp;

        uint value = info.stakedAmount.mul(globalStakedInfo.index - info.index);

        info.available += value;

        if (_oprea == opreate.stake) {
            info.stakedAmount += 1;
        }
        if (_oprea == opreate.upStake) {
            info.stakedAmount -= 1;
        }

        info.index = globalStakedInfo.index;
    }

    function claim() public {
        address sender = msg.sender;
        updateIndex(opreate.claim);
        updateUserIndex(sender, opreate.claim);

        StakedInfo storage userStakedInfo = userStakedInfos[sender];

        if (userStakedInfo.available > 0) {
            uint temp = userStakedInfo.available;
            IERC20(asdic).transfer(sender, temp.mul(30).div(100));
            ILock(lock).locking(sender, temp.mul(70).div(100));
            userStakedInfo.accruedReward += temp;
            userStakedInfo.available = 0;
        }
    }

    function halfYear() internal returns (uint) {
        require(subHalfTime > 0, "SubHalf time error");
        startTime = startTime == 0 ? block.timestamp : startTime;
        uint yearCount = (block.timestamp - startTime).div(subHalfTime);

        if (yearHalfCount <= yearCount) {
            yearHalfCount = yearCount + 1;

            yearHalfAmount = yearHalfAmount.div(2);
        }

        return yearHalfAmount.div(subHalfTime);
    }

    function getHalfYear() internal view returns (uint) {
        if (yearHalfAmount == 0) {
            return 0;
        }
        return yearHalfAmount.div(subHalfTime);
    }

    function awaitGetAmount(address user) external view returns (uint) {
        StakedInfo memory infoGlo = globalStakedInfo;
        StakedInfo memory infoUser = userStakedInfos[user];
        uint secRelease = getHalfYear();

        if (infoGlo.stakedAmount == 0) return 0;

        uint _time = block.timestamp.sub(infoGlo.updateTime);

        uint _amount = _time.mul(secRelease);

        _amount = _amount.div(infoGlo.stakedAmount);

        uint _gloIndex = infoGlo.index.add(_amount);

        uint value = _gloIndex.sub(infoUser.index);

        value = value.mul(infoUser.stakedAmount);

        value = value.add(infoUser.available);

        return value;
    }

    function pledgeNft(uint[] memory _tokenIds) external returns (bool) {
        address _sender = msg.sender;
        for (uint i = 0; i < _tokenIds.length; i++) {
            _pledgeNft(_sender, _tokenIds[i]);
        }
        return true;
    }

    function _pledgeNft(address _sender, uint _tokenid) internal {
        updateIndex(opreate.stake);
        updateUserIndex(_sender, opreate.stake);

        ownerTokens[_sender].push(_tokenid);
        tokenToAddress[_tokenid] = _sender;

        IERC721(starNft).transferFrom(_sender, address(this), _tokenid);
    }

    function unpack(uint[] memory _tokenIds) external {
        address sender = msg.sender;
        for (uint i = 0; i < _tokenIds.length; i++) {
            _unpack(sender, _tokenIds[i]);
        }
    }

    function _unpack(address sender, uint _tokenid) private {
        require(tokenToAddress[_tokenid] == sender, "Pool: unpack error");
        uint[] storage list = ownerTokens[sender];

        updateIndex(opreate.upStake);
        updateUserIndex(sender, opreate.upStake);

        IERC721(starNft).safeTransferFrom(address(this), sender, _tokenid);

        for (uint i = 0; i < list.length; i++) {
            if (list[i] == _tokenid) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
    }

    function onERC721Received(
        address,
        address,
        uint,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}