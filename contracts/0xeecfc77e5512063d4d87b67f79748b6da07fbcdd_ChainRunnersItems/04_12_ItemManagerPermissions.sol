import "@openzeppelin/contracts/access/Ownable.sol";

contract ItemManagerPermissions is Ownable {
    mapping(address => bool) private _allowlistedAddresses;

    event ItemManagerAllowlistUpdated(address indexed itemManager, bool allowlisted);

    error NotAllowedToManageItem();

    // MODIFIERS
    modifier onlyItemManager() {
        if (!isAddressAllowlisted(_msgSender())) revert NotAllowedToManageItem();
        _;
    }

    // ADMIN FUNCTIONS
    function allowlistAddress(address addr) external onlyOwner {
        _allowlistedAddresses[addr] = true;
        emit ItemManagerAllowlistUpdated(addr, true);
    }

    function removeAllowlistedAddress(address addr) external onlyOwner {
        delete _allowlistedAddresses[addr];
        emit ItemManagerAllowlistUpdated(addr, false);
    }

    // READ FUNCTIONS
    function isAddressAllowlisted(address addr) public view returns (bool) {
        return _allowlistedAddresses[addr] == true;
    }
}