// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact [email protected]
contract CrtrToken is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {

    event WithDrawToken(address _addr, uint _amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("Creator", "CRTR");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(address(this), 2000000000 * 10 ** decimals());

        _seed(address(0xc5cDAf6Fb0250177E6cd00D4049897Ef97a11C5c));
        _private(address(0xd1cf1a6019F90878F7f60e7877C476e78488eF68));
        _preSales(address(0x21C19ca41f191153bc592B20BE183CE89b42ed38));
        _foundation(address(0x2E99BFcCD94d226b6a3E799A4f41DD6fEC1c2493));
        _tech(address(0x4a0ab5C1CeE71Acb65833022a20B2A6f68E9B277));
        _partners(address(0x5daF087b8783Da1cCa8431c02907e1Cbe3336BF8));
        _ecosystem(address(0x90E35b1Fd3f0fC693AA86B26C1ebAD589EE6fcd1));
        _marketing(address(0xdD1F1026b40235fd7F36c4413549480780E6154C));
        _liquidity(address(0x446A3074893138225eAe7ce7e54EDC537b688Bc9));
    }

    struct ReleaseRecord {
        uint amount;
        uint time;
    }

    mapping(address => ReleaseRecord[]) public releaseRecords;
    mapping(address => ReleaseRecord) public lockRecord;

    function withDrawToken() external {
        require(releaseRecords[msg.sender].length > 0, "no coins to claim");
        ReleaseRecord memory record = releaseRecords[msg.sender][0];
        require(block.timestamp >= record.time, "pickup time not yet");
        _transfer(address(this), msg.sender, record.amount);
        for (uint i = 0; i < releaseRecords[msg.sender].length - 1; i++) {
            releaseRecords[msg.sender][i] = releaseRecords[msg.sender][i + 1];
        }
        releaseRecords[msg.sender].pop();
        emit WithDrawToken(msg.sender, record.amount);
    }

    function lockToAddress(address lockAddr, uint lockAmount, uint lockTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ReleaseRecord storage record = lockRecord[lockAddr];
        record.amount = lockAmount;
        record.time = lockTime;
    }

    function unLockToAddress(address lockAddr) public onlyRole(DEFAULT_ADMIN_ROLE) {
        delete lockRecord[lockAddr];
    }

    function _seed(address addr) internal {
        uint8 cliff = 6;
        uint8 length = 15;
        uint token = 80000000 * 10 ** decimals();
        uint initRelease = 4000000 * 10 ** decimals();
        uint lock = token - initRelease;
        releaseRecords[addr].push(ReleaseRecord({amount : initRelease, time : block.timestamp}));
        for (uint32 i = 0; i < length; i++) {
            uint addTime = (cliff + i) * 30 days;
            releaseRecords[addr].push(ReleaseRecord({amount : lock / length, time : block.timestamp + addTime}));
        }
    }

    function _private(address addr) internal {
        uint8 cliff = 6;
        uint8 length = 15;
        uint token = 280000000 * 10 ** decimals();
        uint initRelease = 14000000 * 10 ** decimals();
        uint lock = token - initRelease;
        releaseRecords[addr].push(ReleaseRecord({amount : initRelease, time : block.timestamp}));
        for (uint32 i = 0; i < length; i++) {
            uint addTime = (cliff + i) * 30 days;
            releaseRecords[addr].push(ReleaseRecord({amount : lock / length, time : block.timestamp + addTime}));
        }
    }

    function _preSales(address addr) internal {
        uint initRelease = 40000000 * 10 ** decimals();
        releaseRecords[addr].push(ReleaseRecord({amount : initRelease, time : block.timestamp}));
    }

    function _foundation(address addr) internal {
        uint8 cliff = 12;
        uint8 length = 48;
        uint lock = 300000000 * 10 ** decimals();

        for (uint32 i = 0; i < length; i++) {
            uint addTime = (cliff + i) * 30 days;
            releaseRecords[addr].push(ReleaseRecord({amount : lock / length, time : block.timestamp + addTime}));
        }
    }

    function _tech(address addr) internal {
        uint8 cliff = 10;
        uint8 length = 48;
        uint lock = 200000000 * 10 ** decimals();

        for (uint32 i = 0; i < length; i++) {
            uint addTime = (cliff + i) * 30 days;
            releaseRecords[addr].push(ReleaseRecord({amount : lock / length, time : block.timestamp + addTime}));
        }
    }

    function _partners(address addr) internal {
        uint8 cliff = 6;
        uint8 length = 54;
        uint lock = 200000000 * 10 ** decimals();

        for (uint32 i = 0; i < length; i++) {
            uint addTime = (cliff + i) * 30 days;
            releaseRecords[addr].push(ReleaseRecord({amount : lock / length, time : block.timestamp + addTime}));
        }
    }

    function _ecosystem(address addr) internal {
        uint8 length = 59;
        uint lock = 760000000 * 10 ** decimals();

        for (uint32 i = 0; i < length; i++) {
            uint addTime = i * 30 days;
            releaseRecords[addr].push(ReleaseRecord({amount : lock / length, time : block.timestamp + addTime}));
        }
    }

    function _marketing(address addr) internal {
        uint8 length = 59;
        uint lock = 100000000 * 10 ** decimals();

        for (uint32 i = 0; i < length; i++) {
            uint addTime = i * 30 days;
            releaseRecords[addr].push(ReleaseRecord({amount : lock / length, time : block.timestamp + addTime}));
        }
    }

    function _liquidity(address addr) internal {
        uint8 length = 8;
        uint lock = 40000000 * 10 ** decimals();

        for (uint32 i = 0; i < length; i++) {
            uint addTime = i * 90 days;
            releaseRecords[addr].push(ReleaseRecord({amount : lock / length, time : block.timestamp + addTime}));
        }
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    whenNotPaused
    override
    {
        if (block.timestamp < lockRecord[from].time && (balanceOf(from) - lockRecord[from].amount) < amount) {
            require(false, "Insufficient available balance");
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override
    {}
}