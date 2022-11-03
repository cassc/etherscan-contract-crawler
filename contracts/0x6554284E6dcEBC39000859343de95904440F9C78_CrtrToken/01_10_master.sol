// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact [email protected]
contract CrtrToken is ERC20, AccessControl {

    event WithDrawToken(address _addr, uint _amount);

    constructor() ERC20("Creator", "CRTR"){

        _grantRole(DEFAULT_ADMIN_ROLE, address(0x33e1c9107c6a69664a570E2080e1612A8D35c4cc));
        _mint(address(this), 2000000000 * 10 ** decimals());
        //preSales
        _preSales(address(0x7397779c77BB5331B01FFE27BC7eFEaAD03FAF20), 40000000);
        //seed
        _seed_private(address(0x3EcA7aBC7f24F9314ffecE135C7eBD9F7b40Dc7a), 80000000, 4000000);
        //private
        _seed_private(address(0xc4B11186A30BB4FD9FaeE17f43A4bCD15c5aD07a), 280000000, 14000000);
        //foundation
        _lockTokens(address(0x95695d3941445862485cA92a13cCe67C5ba8BA4a), 12, 48, 300000000, 30 days);
        //tech
        _lockTokens(address(0xF1FCd8A0203eD5d8907Ba2ae6510a7f812F29Bc6), 10, 48, 200000000, 30 days);
        //partners
        _lockTokens(address(0xD355d7539ef89Fe86aFFCd9A7bEcF09086783577), 6, 54, 200000000, 30 days);
        //ecosystem TGE
        _preSales(address(0x2A8700F5f360F6FD0D2432Cc6A88310e196C534A), 200000000);
        //ecosystem
        _lockTokens(address(0x2A8700F5f360F6FD0D2432Cc6A88310e196C534A), 0, 59, 560000000, 30 days);
        //marketing
        _lockTokens(address(0x951E553Eb3479b66e9f2ae80D68f8e01b36ca744), 0, 59, 100000000, 30 days);
        //liquidity
        _lockTokens(address(0x1b4b5415a7C33170A5D414b27BDa2630FffE9720), 0, 8, 40000000, 90 days);
    }

    struct ReleaseRecord {
        uint amount;
        uint time;
    }

    mapping(address => ReleaseRecord[]) public releaseRecords;

    function withDrawToken() external {
        uint _length = releaseRecords[msg.sender].length;
        require(_length > 0, "no coins to claim");
        ReleaseRecord memory record = releaseRecords[msg.sender][0];
        require(block.timestamp >= record.time, "pickup time not yet");
        _transfer(address(this), msg.sender, record.amount);
        for (uint i = 0; i < _length - 1; i++) {
            releaseRecords[msg.sender][i] = releaseRecords[msg.sender][i + 1];
        }
        releaseRecords[msg.sender].pop();
        emit WithDrawToken(msg.sender, record.amount);
    }

    function lockToAddress(address lockAddr, uint lockAmount, uint lockTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _transfer(msg.sender, address(this), lockAmount);
        releaseRecords[lockAddr].push(ReleaseRecord({amount : lockAmount, time : lockTime}));
    }

    function _preSales(address addr, uint _token) internal {
        uint initRelease = _token * 10 ** decimals();
        releaseRecords[addr].push(ReleaseRecord({amount : initRelease, time : block.timestamp}));
    }

    function _seed_private(address addr, uint _token, uint _initRelease) internal {
        uint8 cliff = 6;
        uint8 length = 15;
        uint token = _token * 10 ** decimals();
        uint initRelease = _initRelease * 10 ** decimals();
        uint lock = token - initRelease;
        releaseRecords[addr].push(ReleaseRecord({amount : initRelease, time : block.timestamp}));
        for (uint32 i = 0; i < length; i++) {
            uint addTime = (cliff + i) * 30 days;
            releaseRecords[addr].push(ReleaseRecord({amount : lock / length, time : block.timestamp + addTime}));
        }
    }

    function _lockTokens(address _addr, uint8 _cliff, uint32 _length, uint _lock, uint _days) internal {
        uint lock = _lock * 10 ** decimals();
        for (uint32 i = 0; i < _length; i++) {
            uint addTime = (_cliff + i) * _days;
            releaseRecords[_addr].push(ReleaseRecord({amount : lock / _length, time : block.timestamp + addTime}));
        }
    }
}