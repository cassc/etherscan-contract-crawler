// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Pulsedoge is ERC20, ERC20Burnable {
    uint256 public totalClaimedAmount;
    uint256 public burnUnclaimedAmountDate;

    address public managerAddress;
    address public owner;
    bool public whitelistEnabled;

    mapping(address => uint256) private oldTokenHoldersAmounts;

    uint256 private constant CONTRACT_MINT_AMOUNT = 985000000; 
    uint256 private constant DEPLOYER_MINT_AMOUNT = 15000000; 
    // List of whitelisted contracts
    mapping(address => bool) private _whitelisted;

    modifier onlyManager() {
        require(msg.sender == managerAddress, "caller is not the manager");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    event Claimed(address indexed holder, uint256 amount);
    event ManagerTransferred(
        address indexed previousManager,
        address indexed newManager
    ); // 09/12/2022 audit

    // CONSTRUCTOR ------------------------------------------------------------------------------------------
    constructor(address _managerAddress) ERC20("Pulsedoge", "PLD") {
        require(_managerAddress != address(0), "Manager: address is zero");
        _mint(address(this), CONTRACT_MINT_AMOUNT);
        _mint(msg.sender, DEPLOYER_MINT_AMOUNT);
        whitelistEnabled = true;
        totalClaimedAmount = 0;
        burnUnclaimedAmountDate = block.timestamp + 30 days;
        managerAddress = _managerAddress;
        owner = msg.sender;
    }

    function gm() public pure returns (string memory) {
        return unicode"GM 🤝";
    }

    // OVERRIDED FUNCTIONS -----------------------------------------------------------------------------------
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    // CONTRACT FUNCTIONS -----------------------------------------------------------------------------------
    /**
     * @notice Set address manager
     * @param _managerAddress is the public address of the manager who can add holders
     */
    function setManagerAddress(address _managerAddress) public onlyOwner {
        require(managerAddress != _managerAddress, "Manager: address is same");
        require(_managerAddress != address(0), "Manager: address is zero");
        address oldManager = managerAddress;
        managerAddress = _managerAddress;
        emit ManagerTransferred(oldManager, _managerAddress);
    }

    /**
     * @notice Return claimable amount
     * @param account is the public address of the user that we want to consult
     */
    function getClaimableAmount(address account)
        public
        view
        virtual
        returns (uint256)
    {
        return oldTokenHoldersAmounts[account];
    }

    /**
     * @notice Burn unclaimed amount
     */
    function burnUnclaimedTokens() public onlyOwner {
        require(block.timestamp > burnUnclaimedAmountDate, "Cant burn yet");
        uint256 burnAmount = CONTRACT_MINT_AMOUNT - totalClaimedAmount;
        require(
            balanceOf(address(this)) > 0 && burnAmount > 0,
            "All tokens claimed"
        );
        super._burn(address(this), burnAmount);
    }

    /**
     * @notice add token holders and amount to list
     * @param accounts is the public address of the user we will add
     * @param amounts amount from old token holder
     */
    function addTokenHolders(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) public onlyManager {
        require(accounts.length < 201, "Maxlimit of requests");
        require(
            accounts.length == amounts.length,
            "Invalid number of requests"
        );
        uint256 i = 0;
        for (i; i < accounts.length; i++) {
            oldTokenHoldersAmounts[accounts[i]] += amounts[i];
        }
    }

    function claim() public {
        require(
            block.timestamp < burnUnclaimedAmountDate,
            "Claiming period ended"
        );
        uint256 claimedAmount = oldTokenHoldersAmounts[msg.sender];
        require(claimedAmount > 0, "No burn registered from BSC");
        super._transfer(address(this), msg.sender, claimedAmount);
        totalClaimedAmount += claimedAmount;
        oldTokenHoldersAmounts[msg.sender] = 0;
        emit Claimed(msg.sender, claimedAmount);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * whitelist smart contracts
     */
    function enableWhitelist(bool val) external onlyOwner {
        whitelistEnabled = val;
    }

    /**
     * add to whitelist
     */
    function whitelistSmartContract(address account) external onlyOwner {
        require(
            isContract(account) == true,
            "Address is not a contract address. Whitelisting is only on contracts"
        );
        _whitelisted[account] = true;
    }

    /**
     * Remove added smart contract from whitelist
     */
    function unWhitelistSmartContract(address account) external onlyOwner {
        require(
            isContract(account) == true,
            "Address is not a contract address. UnWhitelisting is only on contracts"
        );
        delete _whitelisted[account];
    }

    /**
     * returns true if smart contract is whitelisted
     */
    function isWhitelisted(address account) external view returns (bool) {
        require(
            isContract(account) == true,
            "Address is not a contract address."
        );
        return _whitelisted[account];
    }

    /**
     * return true when either of from or to is in whitelist
     */
    function isTransferAllowed(address from, address to)
        external
        view
        returns (bool)
    {
        if ((isContract(from) == true) && (_whitelisted[from] != true)) {
            return false;
        }

        if ((isContract(to) == true) && (_whitelisted[to] != true)) {
            return false;
        }
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (whitelistEnabled) {
            require(
                this.isTransferAllowed(sender, recipient),
                "Transfer not allowed due to bot protection"
            );
        }
        super._transfer(sender, recipient, amount);
    }
}