// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Address.sol";
abstract contract MintableNFT {
    using Address for address;
    uint256 public constant DAY_LIMIT = 10;
    uint256 public currentId;
    uint256 public phase1time;
    uint256 public phase2time;
    uint256 public phase3time;
    uint256 public phase4time;
    uint256 public nMintPass; // current mintpass supply
    mapping(address => uint256) private _whitelisted;
    mapping(address => uint256) private _purchased;
    mapping(address => uint256) private mintpass;

    constructor(uint256 phase1) {
        phase1time = phase1;
    }



    // override with the mint function
    function _safeMint(address, uint256) internal virtual;

    // override with the supply limit
    function _supplyLimit() internal pure virtual returns (uint256);

    /**
     * @dev mintpass balance of user
     */
    function mintpasses(address user) public view returns (uint256) {
        return mintpass[user];
    }

    /**
     * @dev whitelist balance of user (how many can be minted during phase1)
     */
    function whitelisted(address user) public view returns (uint256) {
        return _whitelisted[user];
    }

    /**
     * @dev number of nfts purchased by user
     */
    function purchased(address user) public view returns (uint256) {
        return _purchased[user];
    }

    /**
     * @dev 1: whitelisted 10, 2: whitelisted unlimited, 3: public 10, 4: public unlimited
     */
    function phase() public view returns (uint256) {
        uint256 time = block.timestamp;
        if (time < phase1time || phase1time == 0) {
            return 0; // not started yet
        }
        if (time > (phase4time) && currentId == _supplyLimit() + 1) {
            return 5; // over
        } else if (phase4time != 0 && time >= phase4time) {
            return 4;
        } else if (phase3time != 0 && time >= phase3time) {
            return 3;
        } else if (phase2time != 0 && time >= phase2time) {
            return 2;
        }
        return 1;
    }

    /**
     * @dev phase shift time schedule
     */
    function getPhaseTime(uint256 phaseNumber)
        public
        view
        returns (uint256 timestamp)
    {
        if (phaseNumber == 1) {
            timestamp = phase1time;
        } else if (phaseNumber == 2) {
            timestamp = phase2time;
        } else if (phaseNumber == 3) {
            timestamp = phase3time;
        } else if (phaseNumber == 4) {
            timestamp = phase4time;
        } else {
            revert("invalid phase request");
        }
        return timestamp;
    }

    function _setPhase1(uint256 unixTimestamp) internal {
        phase1time = unixTimestamp;
    }

    function _setPhase2(uint256 unixTimestamp) internal {
        phase2time = unixTimestamp;
    }

    function _setPhase3(uint256 unixTimestamp) internal {
        phase3time = unixTimestamp;
    }

    function _setPhase4(uint256 unixTimestamp) internal {
        phase4time = unixTimestamp;
    }

    // owner can whitelist users. they can enter presale before public sale.
    // expose this behind onlyOwner modifier
    function _newwhitelist(address[] memory addresses) internal {
        require(addresses.length != 0, "empty list");
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelisted[addresses[i]] = DAY_LIMIT + 1; // X on day 1, an extra as marker
        }
    }

    // owner can gift mintpasses. they redeem, only paying for gas.
    // expose this behind onlyOwner modifier
    function _newmintpass(address[] memory to, uint256[] memory amount)
        internal
    {
        require(to.length == amount.length, "length mismatch");
        for (uint256 i = 0; i < amount.length; i++) {
            uint256 amt = amount[i];
            address dest_ = to[i];
            nMintPass += amt;
            _whitelisted[dest_] = DAY_LIMIT + 1; // auto whitelist, X on day 1
            mintpass[dest_] += amt;
        }
    }

    /**
     * @dev redeem nft for mintpass (check phase)
     */
    function _redeemNFT(address destination, uint256 amount) internal {
        require(mintpass[msg.sender] >= amount, "no mintpass");
        mintpass[msg.sender] -= amount;
        nMintPass -= amount;
        _coolMint(destination, amount);
    }

    uint256 public price = 0.05 ether;

    /**
     * @dev amount of wei needed per nft
     */
    function coinAmount() public view returns (uint256) {
        return price;
    }

    /**
     * @dev buy nft (check phase)
     */
    function createNFT(address destination, uint256 amount) public payable {
        require(!destination.isContract(), "is contract");
        require(msg.sender == tx.origin, "msg sender != tx origin");
        if (mintpass[msg.sender] >= amount) {
            _redeemNFT(destination, amount);
            return;
        }
        require(msg.value == amount * price, "incorrect coin amount");
        _coolMint(destination, amount);
    }

    // mint according to current phase (if valid)
    function _coolMint(address destination, uint256 amount) private {
        require(amount != 0, "amount is zero");
        require(currentId + amount < _supplyLimit() + 2, "too late to mint!");
        uint256 phase_ = phase();

        // switch phase
        if (phase_ == 1) {
            uint256 wlval = _whitelisted[msg.sender];
            require(wlval != 0, "not whitelisted");
            require(wlval != 1, "you reached phase limit");
            require(amount < wlval, "would be over phase limit");
            _whitelisted[msg.sender] -= amount; // will go to 1
        } else if (phase_ == 2) {
            // requires 1 whitelist unit
            require(_whitelisted[msg.sender] != 0, "not whitelisted");
        } else if (phase_ == 3) {
            // anyone up to 4
            require(
                _purchased[msg.sender] + amount <= DAY_LIMIT,
                "reached phase limit of 10"
            );
            _purchased[msg.sender] += amount;
        } else if (phase_ != 4) {
            // 0 or 5+
            revert("invalid phase");
        }
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(destination, currentId);
            currentId += 1;
        }
    }
}