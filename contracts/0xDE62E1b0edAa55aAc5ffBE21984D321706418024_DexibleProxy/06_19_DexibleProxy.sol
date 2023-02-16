//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./DexibleStorage.sol";
import "./ProxyStorage.sol";

contract DexibleProxy {

    modifier onlyAdmin() {
        require(DexibleStorage.load().adminMultiSig == msg.sender, "Unauthorized");
        _;
    }

    event UpgradeProposed(address newLogic, uint upgradeAfter);
    event UpgradedLogic(address newLogic);

    constructor(address _logic, uint32 timelock, bytes memory initData) {
        if(initData.length > 0) {
            (bool s, ) = _logic.delegatecall(initData);
            if(!s) {
                revert("Failed to initialize implementation");
            }
        }
        ProxyStorage.ProxyData storage pd = ProxyStorage.load();
        pd.logic = _logic;
        pd.timelockSeconds = timelock;
    }

    function proposeUpgrade(address _logic, bytes calldata upgradeInit) public onlyAdmin {
        ProxyStorage.ProxyData storage pd = ProxyStorage.load();
        require(_logic != address(0), "Invalid logic");
        pd.pendingUpgrade = ProxyStorage.PendingUpgrade({
            newLogic: _logic,
            initData: upgradeInit,
            upgradeAfter:  block.timestamp + pd.timelockSeconds
        });
        emit UpgradeProposed(_logic, pd.pendingUpgrade.upgradeAfter);
    }

    function canUpgrade() public view returns (bool) {
        ProxyStorage.ProxyData storage pd = ProxyStorage.load();
        return pd.pendingUpgrade.newLogic != address(0) && pd.pendingUpgrade.upgradeAfter < block.timestamp;
    }

    function logic() public view returns (address) {
        return ProxyStorage.load().logic;
    }

    //anyone can call or it will be called when next call is made to the contract after upgrade
    //is allowed
    function upgradeLogic() public {
        require(canUpgrade(), "Cannot upgrade yet");
        ProxyStorage.ProxyData storage pd = ProxyStorage.load();
        pd.logic = pd.pendingUpgrade.newLogic;
        if(pd.pendingUpgrade.initData.length > 0) {
            (bool s, ) = pd.logic.delegatecall(pd.pendingUpgrade.initData);
            if(!s) {
                revert("Failed to initialize new implementation");
            }
        }
        delete pd.pendingUpgrade;
        emit UpgradedLogic(pd.logic);
    }

    //call impl using proxy's state data
    fallback() external {
        
        //if an upgrade can happen, upgrade
        if(canUpgrade()) {
            upgradeLogic();
        }

        //get the logic from storage
        address addr = ProxyStorage.load().logic;
        assembly {
            //and call it
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), addr, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }
}