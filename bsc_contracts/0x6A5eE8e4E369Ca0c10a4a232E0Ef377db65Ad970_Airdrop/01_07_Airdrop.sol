// contracts/Airdrop.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev Interface of the MintableIERC20.
 */
interface MintableIERC20 {
    function mint(address to, uint256 amount) external returns (bool);
}

/**
 * @dev Interface of the ISmartNode.
 */
interface ISmartNode {
    function proxyJoin(address node, address referer) external returns (bool);
}

contract Airdrop is AccessControl {
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    uint256 private _claimPrice = 2 * 10 ** 17;
    uint256 private _claimers = 0;
    uint[] private _dbankXTiers = new uint[](3);
    uint[] private _dbankXTierClaimers = new uint[](3);
    uint public constant TIERS = 3;
    MintableIERC20 private _token;
    ISmartNode private _smartnode;

    event ClaimPriceUpdated(uint256 amount);
    event DbankXTiersUpdated(address indexed account);
    event DbankXClaimed(address indexed account, uint256 token, uint256 bnb);
    event WithdrawBnb(address indexed account, uint256 indexed amount);

    constructor(MintableIERC20 token, ISmartNode smartnode) {
        _token = token;
        _smartnode = smartnode;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        initialize();
    }

    /**
     * @notice Function to claim airdrop
     * @param referer Address of referer
     */
    function claim(
        address referer
    ) external payable {
        require (msg.value == _claimPrice, "!amount");
        uint256 dbankXAmount = dbankClaimAmount();
        require(_smartnode.proxyJoin(_msgSender(), referer), "!proxyJoin");
        if (dbankXAmount > 0) {
            require(_token.mint(_msgSender(), dbankXAmount), "!mint");
        }
        _claimers++;
        emit DbankXClaimed(_msgSender(), dbankXAmount, msg.value);
    }

    /**
     * @notice Function to setClaimPrice
     * @param claimPriceAmount Amount of claimPrice
     */
    function setClaimPrice(
        uint256 claimPriceAmount
    ) external onlyRole(GOVERNOR_ROLE) {
        require (_claimPrice != claimPriceAmount, "No change");
        _claimPrice = claimPriceAmount;
        emit ClaimPriceUpdated(claimPriceAmount);
    }

    /**
     * @notice Function to set dbankXTiers
     * @param dbankXTiers Tiers of dbankx
     * @param dbankXTierClaimers Claimers of dbankx
     * Caller is assumed to be governance
     */
    function setDbankXTiers(
        uint256[] calldata dbankXTiers, 
        uint256[] calldata dbankXTierClaimers
    ) external onlyRole(GOVERNOR_ROLE) {
        require (dbankXTiers.length == TIERS && dbankXTierClaimers.length == TIERS, "invalid length");
        for (uint256 i = 0; i < TIERS; i++) {
            _dbankXTiers[i] = dbankXTiers[i];
            _dbankXTierClaimers[i] = dbankXTierClaimers[i];
        }

        emit DbankXTiersUpdated(_msgSender());
    }

    /**
     * @notice Function to withdraw BNB
     * Caller is assumed to be governance
     */
    function withdrawBnb() external onlyRole(GOVERNOR_ROLE) {
        uint256 bnbBalance = address(this).balance;
        require(bnbBalance > 0, "!zero");
        require(payable(_msgSender()).send(bnbBalance), "!sent");
        emit WithdrawBnb(_msgSender(), bnbBalance);
    }

    function dbankClaimAmount() public view returns (uint256 amount) {
        return _dbankClaimAmount();
    }

    function dbankXTier(uint tier) public view returns(uint amount) {
        return _dbankXTiers[tier];
    }

    function dbankXTierClaimer(uint tier) public view returns(uint amount) {
        return _dbankXTierClaimers[tier];
    }

    function claimPrice() public view returns (uint256 amount) {
        return _claimPrice;
    }

    function claimers() public view returns (uint256 nodes) {
        return _claimers;
    }

    function _dbankClaimAmount() internal view returns (uint256) {
        uint256 i;
        uint256 claimerCount = _claimers;

        for (i = 0; i < TIERS; i++) {
            if (claimerCount < _dbankXTierClaimers[i] ) {
                break;
            }
        }

        if (i == TIERS) {
            return 0;
        }

        return _dbankXTiers[i];
    }


    function initialize() internal {
        _dbankXTiers[0] = 100000 * 10 **18;
        _dbankXTiers[1] = 50000 * 10 **18;
        _dbankXTiers[2] = 25000 * 10 **18;

        _dbankXTierClaimers[0] = 1000;
        _dbankXTierClaimers[1] = 1000;
        _dbankXTierClaimers[2] = 1000;

    }
}