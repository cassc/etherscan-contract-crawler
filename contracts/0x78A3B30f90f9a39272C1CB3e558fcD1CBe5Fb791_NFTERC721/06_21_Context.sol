//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../Registry.sol"; 
import "../IConfig.sol";


contract Context {

    // keccak256("address");
    bytes32 public constant ADDRESS_HASH = 0x421683f821a0574472445355be6d2b769119e8515f8376a1d7878523dfdecf7b;
    // keccak256("uint256");
    bytes32 public constant UINT256_HASH = 0xec13d6d12b88433319b64e1065a96ea19cd330ef6603f5f6fb685dde3959a320;

    IConfig public config;

    function _getPlatformAssetContract() internal view returns (address) {
        bytes32 _key = Registry.PLATFORM_ASSETS_CONTRACT_KEY;
        address to = _getContractAddress(_key);
        require(to != address(0), "SN100: platform asset contract not found");
        return to;
    }

    function _getContractAddress(bytes32 key) internal view returns (address) {
        (bytes32 typeID, bytes memory data) = config.getRawValue(key);
        return bytesToAddress(typeID, data);
    }

    function bytesToAddress(bytes32 typeID, bytes memory data) public pure returns (address addr) {
        require(typeID == ADDRESS_HASH, "SN101: wrong typeID");
        addr = abi.decode(data, (address));
    }

    modifier onlyAdmin() {
        require(config.hasRole(Registry.ADMIN_ROLE, msg.sender), "SN102: caller is not the admin role");
        _;
    }

    modifier allowFreemint() {
        require(config.hasRole(Registry.NFT_FREE_MINT_ROLE, msg.sender), "SN103: caller is not the freemint role");
        _;
    }

    modifier isMinter() {
        require(config.hasRole(Registry.NFT_GROUP_MINTER_ROLE, msg.sender), "SN103: caller is not the minter role");
        _;
    }

    modifier isBurner() {
        require(config.hasRole(Registry.NFT_GROUP_BURNER_ROLE, msg.sender), "SN104: caller is not the burner role");
        _;
    }

    modifier isTransferer() {
        require(config.hasRole(Registry.NFT_GROUP_TRANSFER_ROLE, msg.sender), "SN105: caller is not the transferer role");
        _;
    }

    modifier isNotInTheFromBlacklist(address from) {
        require(!config.hasRole(Registry.BLACKLIST_RESTRICTIONS_FROM_ROLE, from), "SN118: the from address is restricted at the moment");
        _;
    }
    
    modifier isNotInTheToBlacklist(address to) {
        require(!config.hasRole(Registry.BLACKLIST_RESTRICTIONS_TO_ROLE, to), "SN119: the to address is restricted at the moment");
        _;
    }

    modifier selfBurn() {
        (bytes32 typeID, bytes memory data) = config.getRawValue(Registry.SELF_BURN_KEY);
        require(typeID == UINT256_HASH, "ERC20: wrong typeID");
        require(abi.decode(data, (uint256)) == 1, "ERC20: not allowed to self-burning");
        _;
    }

    function _checkConfig(IConfig config_) internal {
        require(config_.version() > 0 || config_.supportsInterface(type(IConfig).interfaceId), "SN107: not a valid config contract");
        config = config_;
    }
    
}