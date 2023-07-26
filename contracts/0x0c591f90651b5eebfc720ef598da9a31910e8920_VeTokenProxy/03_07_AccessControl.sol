// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "./Sig.sol";

contract AccessControl is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // event ContractUpgrade(address newContract);
    event SetProxy(address proxy);
    event AdminTransferred(address oldAdmin, address newAdmin);
    event FlipStakableState(bool stakeIsActive);
    event FlipClaimableState(bool claimIsActive);
    event TransferAdmin(address oldAdmin, address newAdmin);

    address private _admin;
    address public proxy;
    bool public stakeIsActive = true;
    bool public claimIsActive = true;

    address public constant ZERO_ADDRESS = address(0);

    constructor() {
        _setAdmin(_msgSender());
    }

    // function verified(bytes32 hash, bytes memory signature) public view returns (bool){
    //     return admin() == Sig.recover(hash, signature);
    // }

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admin() == _msgSender(), "Invalid Admin: caller is not the admin");
        _;
    }

    function _setAdmin(address newAdmin) private {
        address oldAdmin = _admin;
        _admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }

    function setProxy(address _proxy) external onlyOwner {
        require(_proxy != address(0), "Invalid Address");
        proxy = _proxy;

        emit SetProxy(_proxy);
    }

    modifier onlyProxy() {
        require(proxy == _msgSender(), "Not Permit: caller is not the proxy"); 
        _;
    }

    // modifier sigVerified(bytes memory signature) {
    //     require(verified(Sig.ethSignedHash(msg.sender), signature), "Not verified");
    //     _;
    // }

    modifier activeStake() {
        require(stakeIsActive, "Unstakable");
        _;
    } 

    modifier activeClaim() {
        require(claimIsActive, "Unclaimable");
        _;
    } 
    
    modifier notZeroAddr(address addr_) {
        require(addr_ != ZERO_ADDRESS, "Zero address");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Invalid Admin: new admin is the zero address");
        address oldAdmin = admin();
        _setAdmin(newAdmin);

        emit TransferAdmin(oldAdmin, newAdmin);
    }

    /*
    * Pause sale if active, make active if paused
    */
    function flipStakableState() external onlyOwner {
        stakeIsActive = !stakeIsActive;

        emit FlipStakableState(stakeIsActive);
    }

    function flipClaimableState() external onlyOwner {
        claimIsActive = !claimIsActive;

        emit FlipClaimableState(claimIsActive);
    }
}