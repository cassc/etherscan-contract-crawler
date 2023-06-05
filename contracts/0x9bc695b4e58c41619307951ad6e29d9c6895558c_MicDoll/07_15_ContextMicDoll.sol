//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../IConfig.sol";
import "../Registry.sol";

contract ContextMicDoll {
    
    IConfig public config;

    function _checkConfig(IConfig config_) internal {
        require(config_.version() > 0 || config_.supportsInterface(type(IConfig).interfaceId), "SN107: not a valid config contract");
        config = config_;
    }

    function _HotWalletContract() internal view returns (address) {
        bytes32 _key = Registry.HOTWALLET_KEY;
        address to = _getContractAddress(_key);
        require(to != address(0), "SN100: hotwallet contract not found");
        return to;
    }

    function _getContractAddress(bytes32 key) internal view returns (address) {
        (bytes32 typeID, bytes memory data) = config.getRawValue(key);
        return bytesToAddress(typeID, data);
    }

    function bytesToAddress(bytes32 typeID, bytes memory data) internal pure returns (address addr) {
        require(typeID == Registry.ADDRESS_HASH, "SN101: wrong typeID");
        addr = abi.decode(data, (address));
    }

    modifier onlyAdmin() {
        require(config.hasRole(Registry.ADMIN_ROLE, msg.sender), "SN102: caller is not the admin role");
        _;
    }

    modifier isMinter() {
        require(config.hasRole(Registry.MINTER_ROLE, msg.sender), "SN103: caller is not the minter role");
        _;
    }

    modifier isBurner() {
        require(config.hasRole(Registry.BURNER_ROLE, msg.sender), "SN104: caller is not the burner role");
        _;
    }

    modifier isTransferer() {
        require(config.hasRole(Registry.TRANSFER_ROLE, msg.sender), "SN105: caller is not the transferer role");
        _;
    }

    modifier isNotInTheBlacklist(address account) {
        require(config.hasRole(Registry.SUPER_ADMIN_ROLE, account) || config.hasRole(Registry.ADMIN_ROLE, account)  || !config.hasRole(Registry.BLACKLIST_ROLE, account), "SN106:  address is restricted at the moment");
        _;
    }

    modifier isPauser() {
        require(config.hasRole(Registry.PAUSER_ROLE, msg.sender), "SN107: caller is not the pauser role");
        _;
    }


    
}