//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../library/EGoldUtils.sol";

contract EGoldCashback is AccessControl, ERC20Snapshot, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");

    bytes32 public constant SNAPSHOT_ROLE = keccak256("SNAPSHOT_ROLE");

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");

    mapping(address => bool) private frozen;

    mapping(address => uint256) private cashback;

    event CashbackAdded( address indexed _addr , uint256 _cashback );

    constructor() AccessControl() ERC20Snapshot() ERC20("EGoldCashback", "EGLD-CBK") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

    }

    // ERC20 Functions
    function createSnapshot() external onlyRole(SNAPSHOT_ROLE) returns (uint256) {
        return _snapshot();
    }

    function pauseToken() external onlyRole(PAUSE_ROLE) returns (bool) {
        _pause();
        return true;
    }

    function unpauseToken() external onlyRole(PAUSE_ROLE) returns (bool) {
        _unpause();
        return true;
    }

    function burn(address _to, uint256 _value) external onlyRole(BURNER_ROLE) returns (bool) {
        _burn(_to, _value);
        return true;
    }

    function freeze(address _to) external virtual onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        frozen[_to] = true;
        return true;
    }

    function unfreeze(address _to) external virtual onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        frozen[_to] = false;
        return true;
    }

    function isFrozen(address _to) external view virtual returns (bool) {
        return frozen[_to];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
        require(frozen[from] == false, "ERC20Blockable: Token is frozen by admin"); // Blacklist

    }
    // ERC20 Functions

    // Cashback Functions
    function addCashback( address _addr , uint256 _cashback ) external onlyRole(TREASURY_ROLE) {
        cashback[_addr] = cashback[_addr]  + _cashback;
        emit CashbackAdded( _addr , _cashback);
    }

    function fetchCashback( address _addr ) external view returns ( uint256 ) {
        return cashback[_addr];
    }

    function claim( ) external nonReentrant {
        uint256 _mintTokens = cashback[msg.sender];
        _mint( msg.sender , _mintTokens);
        cashback[msg.sender] = 0;
    }
    // Cashback Functions

}