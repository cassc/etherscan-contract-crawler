// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ITokenERC20 {
    function mintAdminContract(address account, uint256 amount) external;
}

contract Fox1155 is ERC1155BurnableUpgradeable, OwnableUpgradeable {
    // individual uri per type
    mapping (uint256 => string) public typeToUri;
    // whether main uri is freezed
    bool public isUriFreezed;
    // whether each individual uri is freezed
    mapping (uint256 => bool) public typeIsUriFreezed;

    // addresses auto-approved by owner
    mapping (address => bool) public isAutoApproved;
    // triggered when an address is set for auto-approve
    event SetAutoApproved(address indexed addr);

    // address of ERC20 token
    ITokenERC20 public token;
    // rate of return for each type
    mapping (uint256 => uint256) public typeToRate;
    // whether each type is in use already
    mapping (uint256 => bool) public isTypeInUse;
    // triggered when a rate is added
    event SetRateForType(uint256 indexed typeId, uint256 rate);
    // maps each wallet to their claimable amounts
    mapping (address => uint256) public addressToLockedInClaimable;
    // maps each wallet to current total daily rate
    mapping (address => uint256) public addressToTotalDailyRate;
    // maps each wallet to timestamp of last action
    mapping (address => uint256) public addressToLastActionTimestamp;
    // starting timestamp of accrual
    uint256 public startTimestamp;
    // rolling expiry period
    uint256 public constant ROLLING_EXPIRY_PERIOD = 30*24*3600;
    // seconds in a day
    uint256 public constant SECONDS_PER_DAY = 24*3600;

    /**
     * @dev Initializes the contract
     */
    function initialize(address _erc20Address) initializer public {
        __ERC1155_init("");
        __Ownable_init();
        token = ITokenERC20(_erc20Address);
    }

    /**
     * @dev Before token transfer - update daily rate and lock in claimable amount
     */
    function _beforeTokenTransfer(
        address /*operator*/,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory /*data*/
    ) internal override {
        uint256 totalRateChange=0;

        for (uint256 i=0; i<ids.length; i++) {
            totalRateChange += typeToRate[ids[i]] * amounts[i];
        }

        if (from != address(0)) { 
            // compute total accrued so far
            uint256 totalAccrued = computeCurrentlyAccrued(from);

            // update last action timestamp and lock in the amount
            addressToLockedInClaimable[from] += totalAccrued;
            addressToLastActionTimestamp[from] = block.timestamp;

            // update total rate
            addressToTotalDailyRate[from] -= totalRateChange;
        }

        if (to != address(0)) {
            // compute total accrued so far
            uint256 totalAccrued = computeCurrentlyAccrued(to);

            // update last action timestamp and lock in the amount
            addressToLockedInClaimable[to] += totalAccrued;
            addressToLastActionTimestamp[to] = block.timestamp;

            // update total rate
            addressToTotalDailyRate[to] += totalRateChange;
        }
    }

    /**
     * @dev Compute current total accrued by wallet
     */
    function computeCurrentlyAccrued(address wallet) public view returns (uint256){
        require(startTimestamp > 0, "Not started");

        uint256 lastAction = addressToLastActionTimestamp[wallet];
        uint256 timediff = block.timestamp - (lastAction > 0 ? lastAction : startTimestamp);
        timediff = timediff > ROLLING_EXPIRY_PERIOD ? ROLLING_EXPIRY_PERIOD : timediff;
        return timediff * addressToTotalDailyRate[wallet] / SECONDS_PER_DAY;
    }

    /**
     * @dev Get accrued claimable balance
     */
    function getAccruedClaimableBalance(address wallet) public view returns (uint256){
        return computeCurrentlyAccrued(wallet) + addressToLockedInClaimable[wallet];
    }

    /**
     * @dev Claim accrued balance
     */
    function claimAccruedBalance() public {
        uint256 claimableBalance = getAccruedClaimableBalance(msg.sender);

        addressToLockedInClaimable[msg.sender] = 0;
        addressToLastActionTimestamp[msg.sender] = block.timestamp;

        token.mintAdminContract(msg.sender, claimableBalance);
    }

    /**
     * @dev Start accruing
     */
    function startTokenAccruing() public onlyOwner {
        startTimestamp = block.timestamp;
    }

    /**
     * @dev Set rate for type
     */
    function setDailyRateForType(uint256 typeId, uint256 rate) public onlyOwner {
        require(!isTypeInUse[typeId], "Already in use");
        typeToRate[typeId] = rate;
        emit SetRateForType(typeId, rate);
    }

    /**
     * @dev Set auto-approved address
     */
    function setAutoApproved(address addr, bool value) public onlyOwner {
        isAutoApproved[addr] = value;
        emit SetAutoApproved(addr);
    }
            
    /**
     * @dev Airdrop tokens to owners
     */
    function mintOwner(address[] calldata owners, uint256[] calldata types, uint256[] calldata counts) external onlyOwner {
      require(owners.length == types.length && types.length == counts.length, "Bad array lengths");
         
      for (uint256 i = 0; i < owners.length; i++) {
        if (!isTypeInUse[types[i]]) {
            isTypeInUse[types[i]] = true;
        }
        _mint(owners[i], types[i], counts[i], "");
      }
    }

    /**
     * @dev Airdrop single tokens to owners
     */
    function mintOwnerOneToken(address[] calldata owners, uint256 typeId) external onlyOwner {
        if (!isTypeInUse[typeId]) {
            isTypeInUse[typeId] = true;
        }
        for (uint256 i = 0; i < owners.length; i++) {
            _mint(owners[i], typeId, 1, "");
        }
    }

    /**
     * @dev Type uri
     */
    function uri(uint256 typeId) public view override returns (string memory) {
        string memory typeUri = typeToUri[typeId];
        if (bytes(typeUri).length == 0) {
            return super.uri(typeId);
        } else {
            return typeUri;
        }
    }
   
    /**
     * @dev Updates the metadata URI
     */
    function updateUri(string calldata newUri) public onlyOwner {
        require(!isUriFreezed, "Freezed");
        _setURI(newUri);
    }

    /**
     * @dev Freezes the metadata URI
     */
    function freezeUri() public onlyOwner {
        isUriFreezed = true;
    }

    /**
     * @dev Updates and freezes the metadata URI
     */
    function permanentSetUri(string calldata newUri) public onlyOwner {
        updateUri(newUri);
        freezeUri();
    }

    /**
     * @dev Updates the metadata URI for a specific type
     */
    function updateUriForType(string calldata newUri, uint256 typeId) public onlyOwner {
        require(!typeIsUriFreezed[typeId], "Freezed");
        typeToUri[typeId] = newUri;
    }

    /**
     * @dev Freezes the metadata URI
     */
    function freezeUriForType(uint256 typeId) public onlyOwner {
        typeIsUriFreezed[typeId] = true;
    }

    /**
     * @dev Updates and freezes the metadata URI
     */
    function permanentSetUriForType(string calldata newUri, uint256 typeId) public onlyOwner {
        updateUriForType(newUri, typeId);
        freezeUriForType(typeId);
    }

    /**
     * @dev isApprovedForAll override
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return isAutoApproved[operator] || super.isApprovedForAll(account, operator);
    }
}