// 69bd48272bb24e102f2731d5744899879b44ae79
pragma solidity ^0.8.0;

import "UUPSUpgradeable.sol";
import "OwnableUpgradeable.sol";

abstract contract ACLBase is OwnableUpgradeable, UUPSUpgradeable {
    address public safeAddress;
    address public safeModule;
    bytes32 internal _checkedRole = hex"01";
    uint256 internal _checkedValue = 1;
    bool internal isPreCheck  = true;

    // Override NAME and VERSION in sub-instance.
    // eg:
    //   string public override constant NAME = "PancakeACL";
    //   uint256 public override constant VERSION = 1;
    function NAME() external view virtual returns (string memory name);
    function VERSION() external view virtual returns (uint256 version);

    // Modifiers.
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

    // Initializer
    function initialize(address _safeAddress, address _safeModule)
        public
        initializer
    {
        __ACL_init(_safeAddress, _safeModule);
    }

    function __ACL_init(address _safeAddress, address _safeModule)
        internal
        onlyInitializing
    {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ACL_init_unchained(_safeAddress, _safeModule);
    }

    function __ACL_init_unchained(address _safeAddress, address _safeModule)
        internal
        onlyInitializing
    {
        require(_safeAddress != address(0), "Invalid safe address");
        require(_safeModule != address(0), "Invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;

        // make the given safe the owner of the current acl.
        _transferOwnership(_safeAddress);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    // Override this with `address(this).call(data);` if changing states.
    function check(
        bytes32 _role,
        uint256 _value,
        bytes calldata data
    ) external virtual onlyModule returns (bool) {
        _checkedRole = _role;
        _checkedValue = _value;
        isPreCheck = true;
        (bool success, ) = address(this).staticcall(data);
        _checkedRole = hex"01";
        _checkedValue = 1;
        return success;
    }

    function postCheck(bytes32 _role, uint256 _value, bytes calldata data) external virtual onlyModule returns (bool){
       
        _checkedRole = _role;
        _checkedValue = _value;
        isPreCheck = false;
        (bool success,) = address(this).staticcall(data);
        isPreCheck = true;
        _checkedRole = hex"01";
        _checkedValue = 1;

        return success;
    }

    function checkRecipient(address _recipient) internal view {
        require(_recipient == safeAddress, "Not safe address");
    }

    // Gap.
    uint256[50] private __gap;
}