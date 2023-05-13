// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "contracts/util/IERC20.sol";
import "contracts/util/SafeMath.sol";
import "contracts/util/IERC721.sol";
import "./interfaces/ILock.sol";
import "./interfaces/IERC721TokenReceiver.sol";

contract BOLENFTPOOL {
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

    mapping(address => uint[]) public ownerTokens;

    mapping(uint => address) public tokenToAddress;

    uint public startTime;
    uint public yearHalfCount;
    uint public yearHalfAmount;
    uint public subHalfTime;

    address public owner;
    address public asdic;
    address public lock;
    address public mosLpPool;

    IERC721 public boleNft;

    constructor(address _asdic, address _lock, address _boleNft) {
        startTime = block.timestamp;
        asdic = _asdic;
        lock = _lock;
        owner = msg.sender;
        boleNft = IERC721(_boleNft);

        IERC20(asdic).approve(lock, type(uint).max);
    }

    function setSubHalfTime(uint _time) external {
        require(msg.sender == owner, "No owner to set the time");
        subHalfTime = _time;
    }

    function setToken(address _token) external {
        require(msg.sender == owner, "No owner and set the token");
        asdic = _token;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "No owner and set the owner");
        owner = _owner;
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

        IERC721(boleNft).transferFrom(_sender, address(this), _tokenid);
    }

    function getOwnerTokens(
        address account
    ) external view returns (uint[] memory) {
        return ownerTokens[account];
    }

    function getInfo(
        address account
    ) external view returns (StakedInfo memory) {
        return (userStakedInfos[account]);
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
        IERC721(boleNft).safeTransferFrom(address(this), msg.sender, _tokenid);

        for (uint i = 0; i < list.length; i++) {
            if (list[i] == _tokenid) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
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
            ILock(lock).locking(sender, temp.mul(70).div(100));
            IERC20(asdic).transfer(sender, temp.mul(30).div(100));

            userStakedInfo.available = 0;
            userStakedInfo.accruedReward += temp;
        }
    }

    function halfYear() public returns (uint) {
        require(subHalfTime > 0, "SubHalf time error");
        uint yearCount = (block.timestamp - startTime).div(subHalfTime);

        uint temp = IERC20(asdic).balanceOf(address(this));

        if (temp == 0) return 0;

        if (yearHalfCount <= yearCount) {
            yearHalfCount = yearCount + 1;

            yearHalfAmount = temp.div(2);
        }

        return yearHalfAmount.div(365 days);
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

    function onERC721Received(
        address,
        address,
        uint,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}