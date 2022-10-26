import "./SafeMath.sol";

pragma solidity >=0.8.0;

// 
//           ██╗   ██╗██████╗  █████╗ ███╗   ██╗██╗██╗   ██╗███╗   ███╗
//           ██║   ██║██╔══██╗██╔══██╗████╗  ██║██║██║   ██║████╗ ████║
//           ██║   ██║██████╔╝███████║██╔██╗ ██║██║██║   ██║██╔████╔██║
//           ██║   ██║██╔══██╗██╔══██║██║╚██╗██║██║██║   ██║██║╚██╔╝██║
//           ╚██████╔╝██║  ██║██║  ██║██║ ╚████║██║╚██████╔╝██║ ╚═╝ ██║
//            ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝ ╚═════╝ ╚═╝     ╚═╝
//           ███╗   ███╗██╗███╗   ██╗███████╗██████╗ 
//           ████╗ ████║██║████╗  ██║██╔════╝██╔══██╗
//           ██╔████╔██║██║██╔██╗ ██║█████╗  ██████╔╝
//           ██║╚██╔╝██║██║██║╚██╗██║██╔══╝  ██╔══██╗
//           ██║ ╚═╝ ██║██║██║ ╚████║███████╗██║  ██║
//           ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
//           ██████╗ ███████╗ ██████╗
//           ██╔══██╗██╔════╝██╔════╝
//           ██████╔╝███████╗██║     
//           ██╔══██╗╚════██║██║     
//           ██████╔╝███████║╚██████╗
//           ╚═════╝ ╚══════╝ ╚═════╝
// 
//          https://t.me/uraniumminer
// 

struct User {
    uint256 minerCount;
    uint256 oreCount;
    uint256 lastAction;
    uint256 storageType;
}

struct StorageInfo {
    uint256 price; // to upgrade from the below option
    uint256 limit;
}

struct ReferralData {
    uint256 earnings;
    uint256 createdAt;
}

contract UraniumMiner {

    using SafeMath for uint256;

    address private owner;

    uint256 public BEGIN_TIMESTAMP = 1667664000; // Saturday 5th Nov 2022 @ 16:00 GMT

    uint256 public MINER_COST = 1e16; // = 0.01 BNB
    uint256 public URANIUM_VALUE = 1e12; // = 0.000001 BNB

    uint256 public MINER_URANIUM_PER_DAY = 7e2; // = 0.0007 BNB
    
    uint256 public MINIMUM_MINER_PURCHASE = 1;

    uint256 public REF_FEE_PERCENT = 5;
    uint256 public DEV_FEE_PERCENT = 10;

    uint256 public REF_LINK_COST = 1e16;

    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDevFees;
    uint256 public totalRefFees;
    uint256 public totalMiners;

    mapping(uint256 => StorageInfo) public storageInfo;
    mapping(address => User) public users;
    mapping(address => ReferralData) public referralData;

    constructor() {
        owner = msg.sender;
        referralData[msg.sender] = ReferralData({ earnings: 0, createdAt: block.timestamp });
        storageInfo[0] = StorageInfo({ price: 0, limit: 10000 });
        storageInfo[1] = StorageInfo({ price: 1e16, limit: 100000 });
        storageInfo[2] = StorageInfo({ price: 1e18, limit: 1000000 });
    }

    function buyMiners(address _ref) public payable returns (bool success) {
        require(block.timestamp >= BEGIN_TIMESTAMP, "too early");
        require(msg.value.div(MINER_COST) >= MINIMUM_MINER_PURCHASE, "below MINIMUM_MINER_PURCHASE");
        require(_ref != msg.sender, "cannot refer yourself");
        uint256 _minerCount = msg.value.div(MINER_COST);
        updateOreCount(msg.sender);
        totalInvested = totalInvested.add(msg.value);
        totalMiners = totalMiners.add(_minerCount);
        users[msg.sender].minerCount = users[msg.sender].minerCount.add(_minerCount);
        require(payFees(_ref, msg.value), "fee payment failed");
        return true;
    }

    function getOreCount(address _user) public view returns (uint256 oreCount) {
        uint256 _timeDiff = block.timestamp - users[_user].lastAction;
        uint256 _uncapped = users[_user].oreCount.add(users[_user].minerCount.mul(_timeDiff).mul(MINER_URANIUM_PER_DAY).div(86400));
        if (_uncapped > storageInfo[users[_user].storageType].limit) {
            return storageInfo[users[_user].storageType].limit;
        } else {
            return _uncapped;
        }
    }

    function updateOreCount(address _user) private returns (uint256 oreCount) {
        users[_user].oreCount = getOreCount(_user);
        users[_user].lastAction = block.timestamp;
        return users[_user].oreCount;
    }

    function upgradeStorage() public payable returns (bool success) {
        updateOreCount(msg.sender);
        uint256 _newStorageType = users[msg.sender].storageType.add(1);
        require(storageInfo[_newStorageType].limit != 0, "cannot upgrade");
        require(msg.value == storageInfo[_newStorageType].price, "incorrect msg.value");
        totalInvested = totalInvested.add(msg.value);
        users[msg.sender].storageType = _newStorageType;
        return true;
    }

    function becomeUplink() public payable returns (bool success) {
        require(referralData[msg.sender].createdAt == 0, "ref already exists");
        require(msg.value == REF_LINK_COST, "incorrect msg.value");
        referralData[msg.sender] = ReferralData({
            earnings: 0,
            createdAt: block.timestamp 
        });
        return true;
    }

    function payFees(address _ref, uint256 _value) private returns (bool success) {
        uint256 _devFee = _value.mul(DEV_FEE_PERCENT).div(100);
        (bool _sentDev, bytes memory _dataDev) = owner.call{value: _devFee}("");
        require(_sentDev, "dev transfer failed");
        totalDevFees = totalDevFees.add(_devFee);
        if (referralData[_ref].createdAt != 0) {
            uint256 _refFee = _value.mul(REF_FEE_PERCENT).div(100);
            (bool _sentRef, bytes memory _dataRef) = _ref.call{value: _refFee}("");
            require(_sentRef, "ref transfer failed");
            totalRefFees = totalRefFees.add(_refFee);
            referralData[_ref].earnings = referralData[_ref].earnings.add(_refFee);
        }
        return true;
    }

    function sellOres() public returns (bool success) {
        uint256 _oreCount = updateOreCount(msg.sender);
        users[msg.sender].oreCount = 0;
        (bool _sent, bytes memory _data) = msg.sender.call{value: _oreCount.mul(URANIUM_VALUE)}("");
        require(_sent, "transfer failed");
        return true;
    }

}