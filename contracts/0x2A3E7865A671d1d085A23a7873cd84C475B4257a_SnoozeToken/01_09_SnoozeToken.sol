//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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

contract SnoozeToken is ERC20, Ownable, Pausable, ReentrancyGuard {
    address public alwaysTired = address(0);

    uint256 public booster = 1;
    uint256 public mintReward = 1000;
    uint256 public interval = 864;
    uint256 public intervalReward = 1;
    uint256 public listPrice = 0;
    uint256 public whitelistReward = 0;

    address[] public list;

    bytes32 public whitelistRoot;

    mapping(address => uint256) public discord;
    mapping(address => uint256) public transfer;
    mapping(address => uint256) public count;
    mapping(address => uint256) public stash;
    mapping(address => bool) public whitelist;

    modifier onlyAlwaysTired() {
        require(
            msg.sender != address(0) && msg.sender == alwaysTired,
            "Must be AlwaysTired"
        );
        _;
    }

    constructor(address _alwaysTired) ERC20("SnoozeToken", "$SNOOZE") {
        alwaysTired = _alwaysTired;
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
        require(_alwaysTired != address(0), "Invalid address");
        alwaysTired = _alwaysTired;
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

    function setBooster(uint256 _booster) external onlyOwner {
        booster = _booster;
    }

    function setDiscord(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external onlyOwner {
        require(_addresses.length == _amounts.length, "Invalid length");
        unchecked {
            for (uint256 i = 0; i < _addresses.length; i++) {
                discord[_addresses[i]] = _amounts[i];
            }
        }
    }

    function setListPrice(uint256 _listPrice) external onlyOwner {
        listPrice = _listPrice;
    }

    function getListLength() public view returns (uint256) {
        return list.length;
    }

    function setWhitelistRoot(bytes32 _whitelistRoot) external onlyOwner {
        whitelistRoot = _whitelistRoot;
    }

    function setWhitelistReward(uint256 _whitelistReward) external onlyOwner {
        whitelistReward = _whitelistReward;
    }

    function setWhitelist(address[] calldata _addresses, bool _claimed)
        external
        onlyOwner
    {
        unchecked {
            for (uint256 i = 0; i < _addresses.length; i++) {
                whitelist[_addresses[i]] = _claimed;
            }
        }
    }

    function clearList() external onlyOwner {
        delete list;
    }

    function updateRewards(
        address _from,
        address _to,
        uint256 _quantity
    ) external onlyAlwaysTired {
        unchecked {
            uint256 timestamp = block.timestamp;
            bool isMint = _from == address(0);
            // transfer from
            if (_from != address(0)) {
                uint256 countFrom = count[_from];
                _updateStash(_from, countFrom, timestamp, isMint, _quantity);
                count[_from] = countFrom - _quantity;
                transfer[_from] = timestamp;
            }
            // mint to / transfer to
            uint256 countTo = count[_to];
            _updateStash(_to, countTo, timestamp, isMint, _quantity);
            count[_to] = countTo + _quantity;
            transfer[_to] = timestamp;
        }
    }

    function _updateStash(
        address _address,
        uint256 _count,
        uint256 _timestamp,
        bool _isMint,
        uint256 _quantity
    ) internal {
        unchecked {
            uint256 stash_ = 0;
            if (_isMint) {
                stash_ += mintReward * _quantity;
            }
            uint256 transfer_ = transfer[_address];
            if (_count > 0 && transfer_ > 0) {
                uint256 factor = (_timestamp - transfer_) / interval;
                stash_ += _count * intervalReward * booster * factor;
            }
            stash[_address] += stash_;
        }
    }

    function airdrop(address[] calldata _addresses, uint256 _amount)
        external
        onlyOwner
        nonReentrant
    {
        require(_amount > 0, "Invalid amount");
        for (uint16 i = 0; i < _addresses.length; ) {
            require(_addresses[i] != address(0), "Invalid address");
            _mint(_addresses[i], _amount);
            unchecked {
                i++;
            }
        }
    }

    function available() external view whenNotPaused returns (uint256) {
        uint256 count_ = count[msg.sender];
        require(count_ > 0, "Must be Holder");
        uint256 timestamp = block.timestamp;
        uint256 transfer_ = transfer[msg.sender];
        uint256 amount = 0;
        unchecked {
            uint256 factor = (timestamp - transfer_) / interval;
            amount =
                count_ *
                intervalReward *
                booster *
                factor +
                stash[msg.sender];
        }
        return amount;
    }

    function claim() external whenNotPaused nonReentrant {
        uint256 count_ = count[msg.sender];
        require(count_ > 0, "Must be Holder");
        uint256 timestamp = block.timestamp;
        uint256 transfer_ = transfer[msg.sender];
        uint256 amount = 0;
        unchecked {
            uint256 factor = (timestamp - transfer_) / interval;
            amount =
                count_ *
                intervalReward *
                booster *
                factor +
                stash[msg.sender];
        }
        require(amount > 0, "No Snooze to claim");
        _mint(msg.sender, amount);
        transfer[msg.sender] = timestamp;
        delete stash[msg.sender];
    }

    function exchange() external whenNotPaused nonReentrant {
        uint256 count_ = count[msg.sender];
        require(count_ > 0, "Must be Holder");
        uint256 amount = discord[msg.sender];
        require(amount > 0, "No Snooze to exchange");
        _mint(msg.sender, amount);
        delete discord[msg.sender];
    }

    function spend(uint256 _amount) external whenNotPaused nonReentrant {
        uint256 count_ = count[msg.sender];
        require(count_ > 0, "Must be Holder");
        _burn(msg.sender, _amount);
    }

    function joinList(uint256 _amount) external whenNotPaused nonReentrant {
        uint256 count_ = count[msg.sender];
        require(count_ > 0, "Must be Holder");
        require(_amount >= listPrice, "Insufficient amount to join list");
        _burn(msg.sender, _amount);
        list.push(msg.sender);
    }

    function claimWhitelist(bytes32[] calldata _whitelistProof)
        external
        whenNotPaused
        nonReentrant
    {
        uint256 count_ = count[msg.sender];
        require(count_ > 0, "Must be Holder");
        require(
            MerkleProof.verify(
                _whitelistProof,
                whitelistRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not on whitelist"
        );
        require(!whitelist[msg.sender], "No Snooze to claim");
        _mint(msg.sender, whitelistReward);
        whitelist[msg.sender] = true;
    }
}