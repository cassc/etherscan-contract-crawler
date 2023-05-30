// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FxBaseRootTunnel} from "../../tunnel/FxBaseRootTunnel.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title FxStateRootTunnel
 */


interface IWorldOfFreight {
    function mintedcount() external view returns (uint256);
    function balanceOG(address _address) external view returns (uint256);
}

contract FxStateRootTunnel is FxBaseRootTunnel {
    using SafeMath for uint256;
    bytes public latestData;
    address private owner;
   
    IWorldOfFreight public nftContract;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;
    event ClaimOnPoly(address indexed _from, uint256 _amount);
    uint256 public BASE_RATE = 25 ether;
    uint256 public maxSupply = 912500000 ether;
    uint256 public ENDTIME = 1948579200;
    uint256 public snapshotTime;


    constructor(
        address _checkpointManager,
        address _fxRoot,
        address _address
    ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
        owner = msg.sender;
        snapshotTime = block.timestamp;
        nftContract = IWorldOfFreight(_address);

    }

    function _processMessageFromChild(bytes memory data) internal override {
        latestData = data;
    }

    function sendClaimable(bytes memory data) public {
        (address childToken, address _address, uint256 _amount) = abi.decode(data, (address, address, uint256));
        address _ownerAddress = _address;
        uint256 totalClaimable = getClaimable(_ownerAddress);
        require(totalClaimable >= _amount, "Not enough claimable tokens");
        bytes memory message =  abi.encode( _address, _amount);
        _sendMessageToChild(message);
        removeClaimableTokens(_ownerAddress, _amount);
    }

    function removeClaimableTokens(address _user, uint256 _amount) internal {
        uint256 time = block.timestamp;
        rewards[_user] = getClaimable(_user).sub(_amount);
        lastUpdate[_user] = time;
        emit ClaimOnPoly(_user, _amount);
    }

    function transferTokens(address _from, address _to) external {
        require(msg.sender == address(nftContract));
        uint256 time = block.timestamp;
        rewards[_from] = getClaimable(_from);
        lastUpdate[_from] = time;
        rewards[_to] = getClaimable(_to);
        lastUpdate[_to] = time;
    }

    function rewardOnMint(address _user, uint256 _amount) external {
        require(msg.sender == address(nftContract), "Can't call this");
        uint256 tokenId = nftContract.mintedcount();
        uint256 time = block.timestamp;
        if (lastUpdate[_user] == 0) {
            lastUpdate[_user] = time;
        }
        if (tokenId < 2501) {
            rewards[_user] = getClaimable(_user).add(500 ether);
        } else {
            rewards[_user] = getClaimable(_user);
        }
        lastUpdate[_user] = time;
    }

    //GET BALANCE FOR SINGLE TOKEN
    function getClaimable(address _owner) public view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 lastUpdateTime = lastUpdate[_owner];
        //snapshotTime
        if (lastUpdate[_owner] == 0 && nftContract.balanceOG(_owner) > 0) {
            lastUpdateTime = snapshotTime;
        }
        if (lastUpdateTime == 0 && nftContract.balanceOG(_owner) == 0) {
            return 0;
        } else if (time < ENDTIME) {
            uint256 pending = nftContract.balanceOG(_owner).mul(BASE_RATE.mul((time.sub(lastUpdateTime)))).div(86400);
            uint256 total = rewards[_owner].add(pending);
            return total;
        } else {
            return rewards[_owner];
        }
    }

    function setNftContract(address _address) public {
        require(msg.sender == owner, "Sorry, no luck for you");
        nftContract = IWorldOfFreight(_address);
    }

    struct Claimable {
        address _address;
        uint256 _amount;
    }
    function setClaimable(Claimable[] memory _array ) public {
        require(msg.sender == owner, "Sorry, no luck for you");
        for (uint256 i = 0; i < _array.length; i++) {
            rewards[_array[i]._address] = _array[i]._amount;
        }
    }
}