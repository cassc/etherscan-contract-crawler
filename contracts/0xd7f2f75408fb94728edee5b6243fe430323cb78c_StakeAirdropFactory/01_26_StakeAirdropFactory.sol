// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IStakeAirdropFactory} from "../src/interfaces/IStakeAirdropFactory.sol";
import {AirdropAccessControl} from "../src/utils/AirdropAccessControl.sol";
import {StakeAirdrop} from "src/StakeAirdrop.sol";
import {StakeAirdropProxy} from "src/StakeAirdropProxy.sol";

/**
 * @title FireCat's StakeAirdropFactory contract
 * @notice main: addressOf, createCycle
 * @author FireCat Finance
 */
contract StakeAirdropFactory is IStakeAirdropFactory, AirdropAccessControl{
    StakeAirdropProxy proxy;
    StakeAirdrop stakeAirdrop;

    event SetProxyAdmin(address proxyAdmin_);
    event Reset(uint256 cycleId_, address stakeAirdrop_);
    event CreateCycle(uint256 cycleId_, address owner_, address cycleAddress);

    string public name;
    uint256 public cycleId;
    address public proxyAdmin;
    mapping(uint256 => address) public _stakeAirdrop;

    function initialize(string memory name_) initializer public {
        name = name_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @inheritdoc IStakeAirdropFactory
    function totalCycle() public view returns (uint256) {
        return cycleId;
    }

    /// @inheritdoc IStakeAirdropFactory
    function addressOf(uint256 _cycleId) public view returns (address) {
        return _stakeAirdrop[_cycleId];
    }
    
    /// @inheritdoc IStakeAirdropFactory
    function setProxyAdmin(address proxyAdmin_) external onlyRole(DATA_ADMIN)  {
        proxyAdmin = proxyAdmin_;
        emit SetProxyAdmin(proxyAdmin_);
    }

    /// @inheritdoc IStakeAirdropFactory
    function reset(uint256 cycleId_, address stakeAirdrop_) external onlyRole(DATA_ADMIN)  {
        require(cycleId_ <= cycleId, "FTY:E02");
        _stakeAirdrop[cycleId_] = stakeAirdrop_;
        emit Reset(cycleId_, stakeAirdrop_);
    }

    /// @inheritdoc IStakeAirdropFactory
    function createCycle(
        address airdropToken_, 
        address stakeToken_ 
    ) external onlyRole(DATA_ADMIN) returns(address) {
        require(airdropToken_ != address(0), "FTY:E00");
        require(stakeToken_ != address(0), "FTY:E01");
        stakeAirdrop = new StakeAirdrop();
        proxy = new StakeAirdropProxy(address(stakeAirdrop), proxyAdmin, '');

        cycleId += 1;
        _stakeAirdrop[cycleId] = address(proxy);
        StakeAirdrop(address(proxy)).initialize(msg.sender, cycleId, airdropToken_, stakeToken_);
        emit CreateCycle(cycleId, msg.sender, address(proxy));
        return address(proxy);
    }
    
}