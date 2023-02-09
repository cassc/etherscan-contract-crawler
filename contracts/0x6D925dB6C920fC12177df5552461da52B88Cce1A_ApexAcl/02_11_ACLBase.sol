// 61f5a666f1e2638ad41e1350907deced9dabdb64
pragma solidity ^0.8.0;

import "UUPSUpgradeable.sol";
import "OwnableUpgradeable.sol";

abstract contract ACLBase is OwnableUpgradeable, UUPSUpgradeable {
	address public safeAddress;
    address public safeModule;
    bytes32 internal _checkedRole = hex"01";
    uint256 internal _checkedValue = 1;
    
    
     modifier onlySelf() {
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    modifier onlySafe() {
        require(safeAddress == msg.sender, "Caller is not the safe");
        _;
    }

    function initialize(address _safeAddress, address _safeModule) initializer public {
        __ACL_init(_safeAddress, _safeModule);
    }

    function __ACL_init(address _safeAddress, address _safeModule) internal onlyInitializing {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ACL_init_unchained(_safeAddress, _safeModule);
    }

    function __ACL_init_unchained(address _safeAddress, address _safeModule) internal onlyInitializing {
        require(_safeAddress != address(0), "Invalid safe address");
        require(_safeModule!= address(0), "Invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;


        // make the given safe the owner of the current acl.
        _transferOwnership(_safeAddress);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function check(
        bytes32 _role,
        uint256 _value,
        bytes calldata data
    ) external onlyModule returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        (bool success, ) = address(this).staticcall(data);
        _checkedRole = hex"01";
        _checkedValue = 1;
        return success;
    }

    uint256[50] private __gap;
}