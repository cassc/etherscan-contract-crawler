//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../IConfig.sol";
import "../Registry.sol";

contract ContextMess  {
    
    IConfig public config;

    function _checkConfig(IConfig config_) internal {
        require(config_.version() > 0 || config_.supportsInterface(type(IConfig).interfaceId), "ERC20: not a valid config contract");
        config = config_;
    }

    function _TreasuryWalletContract() internal view returns (address) {
        bytes32 _key = Registry.TREASURYWALLET_KEY;
        address to = _getContractAddress(_key);
        require(to != address(0), "ERC20: treasurywallet contract not found");
        return to;
    }

    function _getContractAddress(bytes32 key) internal view returns (address) {
        (bytes32 typeID, bytes memory data) = config.getRawValue(key);
        return bytesToAddress(typeID, data);
    }

    function bytesToAddress(bytes32 typeID, bytes memory data) internal pure returns (address addr) {
        require(typeID == Registry.ADDRESS_HASH, "ERC20: wrong typeID");
        addr = abi.decode(data, (address));
    }

    modifier onlyAdmin() {
        require(config.hasRole(Registry.ADMIN_ROLE, msg.sender), "ERC20: caller is not the admin role");
        _;
    }

    modifier isMinter() {
        require(config.hasRole(Registry.MINTER_ROLE, msg.sender), "ERC20: caller is not the minter role");
        _;
    }

    modifier isBurner() {
        require(config.hasRole(Registry.BURNER_ROLE, msg.sender), "ERC20: caller is not the burner role");
        _;
    }

    modifier isTransferer() {
        require(config.hasRole(Registry.TRANSFER_ROLE, msg.sender), "ERC20: caller is not the transferer role");
        _;
    }

    modifier isNotInTheBlacklist(address account) {
        require(config.hasRole(Registry.SUPER_ADMIN_ROLE, account) || config.hasRole(Registry.ADMIN_ROLE, account)  || !config.hasRole(Registry.BLACKLIST_ROLE, account), "SN119:  address is restricted at the moment");
        _;
    }

    modifier isPauser() {
        require(config.hasRole(Registry.PAUSER_ROLE, msg.sender), "ERC20: caller is not the pauser role");
        _;
    }
}