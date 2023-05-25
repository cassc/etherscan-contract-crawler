// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
   ,-,--.  .-._          _,.---._       _,.---._                  ,----.
 ,-.'-  _\/==/ \  .-._ ,-.' , -  `.   ,-.' , -  `.   ,--,----. ,-.--` , \
/==/_ ,_.'|==|, \/ /, /==/_,  ,  - \ /==/_,  ,  - \ /==/` - ./|==|-  _.-`
\==\  \   |==|-  \|  |==|   .=.     |==|   .=.     |`--`=/. / |==|   `.-.
 \==\ -\  |==| ,  | -|==|_ : ;=:  - |==|_ : ;=:  - | /==/- / /==/_ ,    /
 _\==\ ,\ |==| -   _ |==| , '='     |==| , '='     |/==/- /-.|==|    .-'
/==/\/ _ ||==|  /\ , |\==\ -    ,_ / \==\ -    ,_ //==/, `--`\==|_  ,`-._
\==\ - , //==/, | |- | '.='. -   .'   '.='. -   .' \==\-  -, /==/ ,     /
 `--`---' `--`./  `--`   `--`--''       `--`--''    `--`.-.--`--`-----``
*/

interface ILegacyToken {
    function balanceOf(address account) external view returns (uint256);

    function spend(uint256 amount) external;
}

interface IBoosterToken {
    function balanceOf(address account) external view returns (uint256);
}

contract SnoozeToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    address public alwaysTired;

    ILegacyToken public legacyToken;
    IBoosterToken public boosterToken;

    uint256 public mintReward = 1000;
    uint256 public interval = 864;
    uint256 public intervalReward = 1;

    uint256 public boosterBalance = 1;
    uint256 public boosterMultiplier = 3000;
    uint256 public boosterDenominator = 2000;

    mapping(address => uint256) public transfers;
    mapping(address => uint256) public counts;
    mapping(address => uint256) public stashs;

    mapping(address => bool) public exchanges;
    address[] public exchangers;

    modifier onlyAlwaysTired() {
        require(
            msg.sender != address(0) && msg.sender == alwaysTired,
            "Must be AlwaysTired"
        );
        _;
    }

    constructor(
        address _alwaysTired,
        address _legacyToken,
        address _boosterToken
    ) ERC20("SnoozeToken", "$SNOOZE") {
        alwaysTired = _alwaysTired;
        legacyToken = ILegacyToken(_legacyToken);
        boosterToken = IBoosterToken(_boosterToken);
        _pause();
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setAlwaysTired(address _alwaysTired) external onlyOwner {
        alwaysTired = _alwaysTired;
    }

    function setLegacyToken(address _legacyToken) external onlyOwner {
        legacyToken = ILegacyToken(_legacyToken);
    }

    function setBoosterToken(address _boosterToken) external onlyOwner {
        boosterToken = IBoosterToken(_boosterToken);
    }

    function setMintReward(uint256 _mintReward) external onlyOwner {
        mintReward = _mintReward;
    }

    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
    }

    function setIntervalReward(uint256 _intervalReward) external onlyOwner {
        intervalReward = _intervalReward;
    }

    function setBoosterBalance(uint256 _boosterBalance) external onlyOwner {
        boosterBalance = _boosterBalance;
    }

    function setBoosterMultiplier(
        uint256 _boosterMultiplier
    ) external onlyOwner {
        boosterMultiplier = _boosterMultiplier;
    }

    function setBoosterDenominator(
        uint256 _boosterDenominator
    ) external onlyOwner {
        boosterDenominator = _boosterDenominator;
    }

    function setTransfers(
        address[] calldata _addresses,
        uint256[] calldata _timestamps
    ) external onlyOwner {
        require(_addresses.length == _timestamps.length, "Invalid length");
        unchecked {
            for (uint256 i = 0; i < _addresses.length; i++) {
                transfers[_addresses[i]] = _timestamps[i];
            }
        }
    }

    function setCounts(
        address[] calldata _addresses,
        uint256[] calldata _counts
    ) external onlyOwner {
        require(_addresses.length == _counts.length, "Invalid length");
        unchecked {
            for (uint256 i = 0; i < _addresses.length; i++) {
                counts[_addresses[i]] = _counts[i];
            }
        }
    }

    function setStashs(
        address[] calldata _addresses,
        uint256[] calldata _stashs
    ) external onlyOwner {
        require(_addresses.length == _stashs.length, "Invalid length");
        unchecked {
            for (uint256 i = 0; i < _addresses.length; i++) {
                stashs[_addresses[i]] = _stashs[i];
            }
        }
    }

    function getExchangers() public view returns (address[] memory) {
        return exchangers;
    }

    function deleteExchanges() external onlyOwner {
        unchecked {
            for (uint256 i = 0; i < exchangers.length; i++) {
                delete exchanges[exchangers[i]];
            }
            delete exchangers;
        }
    }

    function exchangeable() external view returns (uint256) {
        uint256 count_ = counts[msg.sender];
        if (count_ < 1) {
            // Must be Holder
            return 0;
        }
        bool exchanged = exchanges[msg.sender];
        if (exchanged) {
            // Already exchanged
            return 0;
        }
        uint256 balance = legacyToken.balanceOf(msg.sender);
        return balance;
    }

    function exchange() external whenNotPaused nonReentrant {
        uint256 count_ = counts[msg.sender];
        require(count_ > 0, "Must be Holder");
        bool exchanged = exchanges[msg.sender];
        require(!exchanged, "Already exchanged");
        uint256 balance = legacyToken.balanceOf(msg.sender);
        require(balance > 0, "Insufficient balance");
        _mint(msg.sender, balance);
        exchanges[msg.sender] = true;
        exchangers.push(msg.sender);
    }

    function updateRewards(
        address _from,
        address _to,
        uint256 _quantity
    ) external onlyAlwaysTired nonReentrant {
        unchecked {
            uint256 timestamp = block.timestamp;
            bool isMint = _from == address(0);
            // transfer from
            if (_from != address(0)) {
                uint256 countFrom = counts[_from];
                _updateStash(_from, countFrom, timestamp, isMint, _quantity);
                counts[_from] = countFrom - _quantity;
                transfers[_from] = timestamp;
            }
            // mint to / transfer to
            uint256 countTo = counts[_to];
            _updateStash(_to, countTo, timestamp, isMint, _quantity);
            counts[_to] = countTo + _quantity;
            transfers[_to] = timestamp;
        }
    }

    function _updateStash(
        address _address,
        uint256 _count,
        uint256 _timestamp,
        bool isMint,
        uint256 _quantity
    ) internal {
        unchecked {
            uint256 stash = 0;
            if (isMint) {
                stash += mintReward * _quantity;
            }
            uint256 transfer = transfers[_address];
            if (_count > 0 && transfer > 0) {
                uint256 factor = (_timestamp - transfer) / interval;
                stash += _count * intervalReward * factor;
            }
            stashs[_address] += stash;
        }
    }

    function airdrop(
        address[] calldata _addresses,
        uint256 _amount
    ) external onlyOwner nonReentrant {
        require(_amount > 0, "Invalid amount");
        for (uint16 i = 0; i < _addresses.length; ) {
            require(_addresses[i] != address(0), "Invalid address");
            _mint(_addresses[i], _amount);
            unchecked {
                i++;
            }
        }
    }

    function available() external view returns (uint256) {
        uint256 count_ = counts[msg.sender];
        if (count_ < 1) {
            // Must be Holder
            return 0;
        }
        uint256 timestamp = block.timestamp;
        uint256 transfer = transfers[msg.sender];
        uint256 amount = 0;
        unchecked {
            uint256 factor = (timestamp - transfer) / interval;
            amount = count_ * intervalReward * factor;
            if (
                address(boosterToken) != address(0) &&
                boosterToken.balanceOf(msg.sender) >= boosterBalance
            ) {
                amount = (amount * boosterMultiplier) / boosterDenominator;
            }
            amount = amount + stashs[msg.sender];
        }
        return amount;
    }

    function claim() external whenNotPaused nonReentrant {
        uint256 count_ = counts[msg.sender];
        require(count_ > 0, "Must be Holder");
        uint256 timestamp = block.timestamp;
        uint256 transfer = transfers[msg.sender];
        uint256 amount = 0;
        unchecked {
            uint256 factor = (timestamp - transfer) / interval;
            amount = count_ * intervalReward * factor;
            if (
                address(boosterToken) != address(0) &&
                boosterToken.balanceOf(msg.sender) >= boosterBalance
            ) {
                amount = (amount * boosterMultiplier) / boosterDenominator;
            }
            amount = amount + stashs[msg.sender];
        }
        require(amount > 0, "No Snooze to claim");
        _mint(msg.sender, amount);
        transfers[msg.sender] = timestamp;
        delete stashs[msg.sender];
    }

    function spend(uint256 _amount) external whenNotPaused nonReentrant {
        uint256 count_ = counts[msg.sender];
        require(count_ > 0, "Must be Holder");
        _burn(msg.sender, _amount);
    }
}