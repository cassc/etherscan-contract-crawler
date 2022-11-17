pragma solidity ^0.8.0;

import "./interface/AclProtector.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract BaseCoboSafeModuleAcl is AclProtector, Ownable {

    address public safeAddress;
    address public safeModule;

    modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    function onlySafeAddress(address to) internal view {
        require(to == safeAddress, "to is not allowed");
    }

    fallback() external {
        // 出于安全考虑，当调用到本合约中没有出现的 ACL Method 都会被拒绝
        revert("Unauthorized access");
    }

    function check(
        bytes32 _role,
        uint256 _value,
        bytes calldata data
    ) external onlyModule returns (bool) {
        // 调用 ACL methods
        (bool success, ) = address(this).staticcall(data);
        return success;
    }

    function _setSafeAddressAndSafeModule(address _safeAddress, address _safeModule) internal {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule != address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
        _transferOwnership(_safeAddress);
    }

    function setSafeAddressAndSafeModule(address _safeAddress, address _safeModule) external onlyOwner {
       _setSafeAddressAndSafeModule(_safeAddress, _safeModule);
    }
}