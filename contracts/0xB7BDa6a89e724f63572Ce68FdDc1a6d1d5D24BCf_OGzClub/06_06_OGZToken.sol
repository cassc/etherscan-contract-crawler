// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract OGzClub is ERC20, Ownable{
    uint256 public totalInitializated;
    uint256 private constant POOL_NUMBER = 7;
    uint256 private constant INITIALIZE_SUPPLY = 118_000_000_000 ether;
    uint256 public constant MAX_BUY_TAX_RATE = 800;
    uint256 public constant MAX_SELL_TAX_RATE = 800;
    uint256 public totalBuyTaxRate;
    uint256 public totalSellTaxRate;
    uint256 private toggleReferenceFees = 0;
    uint256 public togglePreferredNicknames;
    uint256 public referenceRate;
    uint256 public isTradeOpen;
    address public taxManager;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable PairAddress;
    Factory public constant FACTORY = Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    struct Pools {
        address poolAddress;
        uint256 taxRate;
    }

    struct Referrers {
        address referrer;
        uint256 timestamp;
    }

    struct Referrals {
        address referral;
        string nickname;
        uint256 timestamp;
        Referrers[] referees;
    }

    /// @dev mapping for all buying fee pools
    mapping(uint256 => Pools) public buyPools;
    mapping(uint256 => Pools) public sellPools;
    mapping(address => address) internal _referrals;
    mapping(address => string) internal _referralNickname;
    mapping(uint256 => uint256) internal _toggledOffBuyPools;
    mapping(uint256 => uint256) internal _toggledOffSellPools;
    mapping(string => address) internal _nickNames;
    /// @dev mapping for accounts that allow nicknames
    mapping(address => uint256) internal _preferredNicknames;
    /// @dev mapping for tax-frees accounts
    mapping(address => uint256) public _taxFrees;

    event RegisteredReferrence(address referral, string nickname, address referrer, uint256 timestamp);

    event CreatedLink(address owner, string nickName, uint256 timestamp);

    event BuyFeesUpdated(uint256 indexed poolId, uint256 newRate);

    event SellFeesUpdated(uint256 indexed poolId, uint256 newRate);

    event ReferenceFeeUpdated(uint256 oldRate, uint256 newFee);

    event ChangedPoolAddress(uint256 indexed poolId, address newAddress);

    event TransferWithTaxFee(string referralNickName, address referralAddress, address from, uint256 amount, uint256 referralEarnedAmount, uint256 timestamp);

    event ChangedTaxManager(address oldTaxManager, address newTaxManager);

    event TradingEnabled(uint256 timestamp);


    constructor(
        address _multisigOwner,
        address _taxManager,
        uint256 _referenceRate,
        Pools[] memory _poolsData)
    ERC20("OGzClub", "OGz") {
        require(_poolsData.length == POOL_NUMBER, "Pools datas length must be equal to 7");
        require(_multisigOwner != address(0) && _taxManager != address(0), "Owner and tax manager address cannot equal to address 0");
        require(_referenceRate > 0, "Reference tax rate must be greater than zero");
        referenceRate = _referenceRate;
        PairAddress = FACTORY.createPair(address(this), WETH);
        taxManager = _taxManager;
        _taxFrees[_multisigOwner] = 1;
        _transferOwnership(_multisigOwner);
        togglePreferredNicknames = 1;
        for (uint256 i = 0; i < _poolsData.length; i++) {
            require(_poolsData[i].poolAddress != address(0), "Pool address cannot equal to 0 address");
            require(_poolsData[i].taxRate > 0, "Pool rate must be greater than 0");
            buyPools[i] = _poolsData[i];
            sellPools[i] = _poolsData[i];
            totalBuyTaxRate += _poolsData[i].taxRate;
            totalSellTaxRate += _poolsData[i].taxRate;
        }
        require(
            totalBuyTaxRate == MAX_BUY_TAX_RATE &&
            totalSellTaxRate == MAX_SELL_TAX_RATE,
            "Total tax rate must be equal to maximum tax rate"
        );
        _mint(owner(), INITIALIZE_SUPPLY);
    }

    /** @dev Modifier to make a function callable only by the Tax Manager.
    * Throws if called by any account other than the Tax Manager.
    * @notice You must be the Tax Manager to call this.
    */
    modifier onlyTaxManager() {
        require(msg.sender == taxManager, "You are not tax manager.");
        _;
    }

    modifier initializationControl() {
        require(totalInitializated <= 62, "Initialization is done");
        _;
    }

    /**
    * @dev Modifier to restrict function access to preferred accounts for nickname creation.
    * @notice This modifier ensures that the function can only be accessed by preferred accounts,
    * or if the togglePreferredNicknames feature is turned off (equals to 0).
    */
    modifier onlyPreferredAccountCreateNickname() {
        require(
            togglePreferredNicknames == 0 ||
            _preferredNicknames[msg.sender] == 1,
            "You are not preferred");
        _;
    }

    /**
    * @dev Allows the current Tax Manager to relinquish control of the contract.
    * It sets the tax manager address to zero, hence no more tax related actions can be performed.
    * @notice Only the current Tax Manager can renounce tax management.
    */
    function renounceTaxManager() external onlyTaxManager {
        address oldTaxManager = taxManager;
        taxManager = address(0);
        emit ChangedTaxManager(oldTaxManager, taxManager);
    }

    /**
    * @dev Initializes referral data for the new token contract, pulling from the previously deployed token contract.
    * The referrals array provided should contain referral data from the previous contract to be transferred to the new one.
    * Emits a {CreatedLink} event for each referral that is successfully initialized.
    * Emits a {RegisteredReferrence} event for each referee that is successfully registered under a referrer.
    * @notice Only the contract owner can initialize the referral data.
    * @param referrals An array of Referral structs from the previous contract.
    * Each `Referral` struct should include the referrer's Ethereum address, nickname, and timestamp,
    * as well as an array of `Referee` structs, each of which should include the referred account's Ethereum address and timestamp.
    * @return true if the function succeeds.
    */
    function initializeReferralDatas(Referrals[] memory referrals) external onlyOwner initializationControl returns(bool) {
        require(referrals.length > 0, "Referrals array length must be greater than zero");
        totalInitializated += referrals.length;
        for (uint256 i = 0; i < referrals.length;) {
            _preferredNicknames[referrals[i].referral] = 1;
            require(bytes(_referralNickname[referrals[i].referral]).length == 0, "You already have a nickname");
            require(bytes(referrals[i].nickname).length != 0 && bytes(referrals[i].nickname).length <= 64, "Nickname must be between 1 and 64 characters");
            require(_nickNames[referrals[i].nickname] == address(0), "Nickname is already taken");
            _nickNames[referrals[i].nickname] = referrals[i].referral;
            _referralNickname[referrals[i].referral] = referrals[i].nickname;
            emit CreatedLink(referrals[i].referral, referrals[i].nickname, referrals[i].timestamp);
            if (referrals[i].referees.length > 0) {
                bytes32 referrerNicknameHash = keccak256(abi.encodePacked(_referralNickname[referrals[i].referral]));
                for (uint256 k = 0; k < referrals[i].referees.length;) {
                    require(
                        _referrals[referrals[i].referral] != referrals[i].referees[k].referrer &&
                        _referrals[referrals[i].referees[k].referrer] == address(0) &&
                        referrerNicknameHash != keccak256(abi.encodePacked("")) &&
                        referrals[i].referral != address(0) &&
                        referrals[i].referral != referrals[i].referees[k].referrer,
                        "Invalid referral"
                    );
                    _referrals[referrals[i].referees[k].referrer] = referrals[i].referral;
                    emit RegisteredReferrence(referrals[i].referral, referrals[i].nickname, referrals[i].referees[k].referrer, referrals[i].referees[k].timestamp);
                unchecked {
                    k ++;
                }
                }
            }
        unchecked {
            i ++;
        }
        }
        return true;
    }

    /**
    * @dev Transfers the tax management to a new address.
    * It sets the provided address as the new tax manager.
    * @notice Only the current Tax Manager can transfer tax management to a new address.
    * @param newTaxManager The address of the new Tax Manager.
    */
    function transferTaxManager(address newTaxManager) external onlyTaxManager {
        require(newTaxManager != address(0), "New address cannot be 0 address");
        address oldTaxManager = taxManager;
        taxManager = newTaxManager;
        emit ChangedTaxManager(oldTaxManager, taxManager);
    }


    /**
    * @dev Adds a list of addresses to the tax-free list.
    * These addresses will be exempt from taxes imposed by the contract.
    * @notice Only the current Tax Manager can add addresses to the tax-free list.
    * A maximum of 50 addresses can be added at a time.
    * @param taxFrees An array of addresses to be added to the tax-free list.
    * @return A boolean value indicating whether the operation was successful.
    */
    function addTaxFrees(address[] memory taxFrees) external onlyTaxManager returns(bool) {
        require(taxFrees.length <= 50, "Maximum 50 address can be added");
        for (uint256 i = 0; i < taxFrees.length;) {
            if (_taxFrees[taxFrees[i]] == 0 && taxFrees[i] != address(0)) {
                _taxFrees[taxFrees[i]] = 1;
            }
        unchecked {
            i++;
        }
        }
        return true;
    }

    /**
    * @dev Removes a list of addresses from the tax-free list.
    * These addresses will no longer be exempt from taxes imposed by the contract.
    * @notice Only the current Tax Manager can remove addresses from the tax-free list.
    * A maximum of 50 addresses can be removed at a time.
    * @param taxFrees An array of addresses to be removed from the tax-free list.
    * @return A boolean value indicating whether the operation was successful.
    */
    function removeTaxFrees(address[] memory taxFrees) external onlyTaxManager returns(bool) {
        require(taxFrees.length <= 50, "Maximum 50 address can be added");
        for (uint256 i = 0; i < taxFrees.length;) {
            if (_taxFrees[taxFrees[i]] == 1) {
                delete _taxFrees[taxFrees[i]];
            }
        unchecked {
            i++;
        }
        }
        return true;
    }

    /**
    * @dev Changes the address of a specific pool.
    * @notice This function can only be called by the current Tax Manager. It changes the
    * address of both the buy and sell pools at the specified pool ID.
    * @param poolId The ID of the pool whose address is to be changed.
    * @param newAddress The new address to set for the specified pool.
    */
    function changePoolAddress(
        uint256 poolId,
        address newAddress
    ) external onlyTaxManager {
        require(newAddress != address(0), "New address cannot equal to 0 address");
        require(poolId < POOL_NUMBER, "Pool id is not found.");
        buyPools[poolId].poolAddress = newAddress;
        sellPools[poolId].poolAddress = newAddress;
        emit ChangedPoolAddress(poolId, newAddress);
    }

    /**
    * @dev Function to add a list of preferred accounts for nickname creation.
    * @notice This function is used to add a list of accounts as preferred for creating nicknames.
    * The maximum limit is 50 accounts per transaction. Only contract owner can call this function.
    * @param account An array of account addresses to be marked as preferred.
    * @return Returns true if the operation is successful.
    */
    function addPreferredNicknames(address[] memory account) external onlyOwner returns(bool) {
        require(account.length <= 50, "Maximum 50 account can be added");
        for (uint256 i = 0; i < account.length; i++) {
            if (_preferredNicknames[account[i]] == 0 && account[i] != address(0)) {
                _preferredNicknames[account[i]] = 1;
            }
        }
        return true;
    }

    /**
    * @dev Function to remove a list of preferred accounts for nickname creation.
    * @notice This function is used to remove a list of accounts from the preferred accounts for creating nicknames.
    * The maximum limit is 50 accounts per transaction. Only contract owner can call this function.
    * @param account An array of account addresses to be removed from the list of preferred accounts.
    * @return Returns true if the operation is successful.
    */
    function removePreferredNicknames(address[] memory account) external onlyOwner returns(bool) {
        require(account.length <= 50, "Maximum 50 account can be removed");
        for (uint256 i = 0; i < account.length; i++) {
            if (_preferredNicknames[account[i]] == 1) {
                delete _preferredNicknames[account[i]];
            }
        }
        return true;
    }

    /**
    * @dev Function to disable the preferred nickname creation feature.
    * @notice This function allows the contract owner to disable the preferred nickname creation feature.
    * Once this function is called, only the contract owner will be able to re-enable it.
    * @return Returns true if the operation is successful.
    */
    function toggleOffPreferredNicknames() external onlyOwner returns(bool) {
        togglePreferredNicknames = 0;
        return true;
    }

    /**
    * @dev Function to check whether a specific account has the permission to create a nickname.
    * @notice This function checks whether the passed account has the permission to create a nickname.
    * If the preferred nickname feature is turned off (togglePreferredNicknames == 0), this function will return true for any account.
    * If the preferred nickname feature is turned on (togglePreferredNicknames != 0), only accounts in the preferred nicknames list (_preferredNicknames[account] == 1) will return true.
    * @param account The address of the account to check for the create nickname permission.
    * @return Returns true if the account has the permission to create a nickname.
    */
    function checkCreateNicknamePermission(address account) external view returns(bool) {
        return togglePreferredNicknames == 0 || _preferredNicknames[account] == 1;
    }


    /**
    * @dev Function to disable the buy tax fee for a specific pool.
    * @notice This function will disable the buy tax fee for a specific pool by setting the corresponding _toggledOffBuyPools value to 1.
    * If the pool is already toggled off, the function will revert. After disabling, the total buy tax rate will be updated and the pool will be deleted.
    * @param poolId The id of the pool to disable the buy tax fee.
    * @return Returns true if the operation is successful.
    */
    /*
    PoolIds:
    0: Future Plan
    1: Team1
    2: Team2
    3: Team3
    4: Liquidity Pool
    5: Staking
    6: Future Plan or Referral
    */
    function toggleOffBuyTaxFee(uint256 poolId) external onlyTaxManager returns(bool){
        require(poolId <= POOL_NUMBER, "Pool id not found");
        require(_toggledOffBuyPools[poolId] == 0, "The pool is already toggled off");
        _toggledOffBuyPools[poolId] = 1;
        totalBuyTaxRate = totalBuyTaxRate - buyPools[poolId].taxRate;
        delete buyPools[poolId];
        emit BuyFeesUpdated(poolId, 0);
        return true;
    }

    /**
    * @dev Function to disable the sell tax fee for a specific pool.
    * @notice This function will disable the sell tax fee for a specific pool by setting the corresponding _toggledOffSellPools value to 1.
    * If the pool is already toggled off, the function will revert. After disabling, the total sell tax rate will be updated and the pool will be deleted.
    * @param poolId The id of the pool to disable the sell tax fee.
    * @return Returns true if the operation is successful.
    */
    function toggleOffSellTaxFee(uint256 poolId) external onlyTaxManager returns(bool){
        require(poolId <= POOL_NUMBER, "Pool id not found");
        require(_toggledOffSellPools[poolId] == 0, "The pool is already toggled off");
        _toggledOffSellPools[poolId] = 1;
        totalSellTaxRate = totalSellTaxRate - sellPools[poolId].taxRate;
        delete sellPools[poolId];
        emit SellFeesUpdated(poolId, 0);
        return true;
    }

    /**
    * @dev Function to disable the reference fee.
    * @notice This function will disable the reference fee by setting the toggleReferenceFees value to 1. If the reference fee is already toggled off, the function will revert.
    * After disabling, the reference rate will be updated to 0.
    * @return Returns true if the operation is successful.
    */
    function toggleOffReferenceFee() external onlyTaxManager returns(bool) {
        require(toggleReferenceFees == 0, "Reference pool is already toggled off");
        toggleReferenceFees = 1;
        uint256 oldRate = referenceRate;
        referenceRate = 0;
        emit ReferenceFeeUpdated(oldRate, 0);
        return true;
    }

    /**
    * @dev Function to decrease the buy tax fee of a specific pool.
    * @notice This function allows the tax manager to reduce the buy tax fee for a given pool. The new fee should be greater than 0 and less than the current tax fee, otherwise, the function will revert. This function will not work if the pool is toggled off.
    * @param poolId The identifier of the pool that the tax fee will be decreased for.
    * @param newFee The new fee that will replace the old tax fee for the given pool.
    * @return Returns true if the operation is successful.
    */
    function decreaseBuyTaxFee(
        uint256 poolId,
        uint256 newFee
    ) external onlyTaxManager returns(bool){
        require(poolId <= POOL_NUMBER, "Pool id not found");
        require(_toggledOffBuyPools[poolId] == 0, "The pool is already toggled off");
        require(
            newFee > 0 &&
            newFee < buyPools[poolId].taxRate,
            "New fee rate must be between 0 and current tax fee"
        );
        totalBuyTaxRate = totalBuyTaxRate - (buyPools[poolId].taxRate - newFee);
        buyPools[poolId].taxRate = newFee;
        emit BuyFeesUpdated(poolId, newFee);
        return true;
    }

    /**
    * @dev Function to decrease the sell tax fee of a specific pool.
    * @notice This function allows the tax manager to reduce the sell tax fee for a given pool. The new fee should be greater than 0 and less than the current tax fee, otherwise, the function will revert. This function will not work if the pool is toggled off.
    * @param poolId The identifier of the pool that the tax fee will be decreased for.
    * @param newFee The new fee that will replace the old tax fee for the given pool.
    * @return Returns true if the operation is successful.
    */
    function decreaseSellTaxFee(
        uint256 poolId,
        uint256 newFee
    ) external onlyTaxManager returns(bool){
        require(poolId <= POOL_NUMBER, "Pool id not found");
        require(_toggledOffSellPools[poolId] == 0, "The pool is already toggled off");
        require(
            newFee > 0 &&
            newFee < sellPools[poolId].taxRate,
            "New fee rate must be between 0 and current tax fee"
        );
        totalSellTaxRate = totalSellTaxRate - (sellPools[poolId].taxRate - newFee);
        sellPools[poolId].taxRate = newFee;
        emit SellFeesUpdated(poolId, newFee);
        return true;
    }

    /**
    * @dev Function to decrease the reference fee.
    * @notice This function allows the tax manager to reduce the reference fee. The new fee should be greater than 0 and less than the current fee, otherwise, the function will revert.
    * @param newFee The new fee that will replace the old reference fee.
    * @return Returns true if the operation is successful.
    */
    function decreaseReferenceFee(uint256 newFee) external onlyTaxManager returns(bool) {
        require(
            newFee > 0 &&
            newFee < referenceRate,
            "New fee rate must be between 0 and current fee"
        );
        uint256 oldRate = referenceRate;
        referenceRate = newFee;
        emit ReferenceFeeUpdated(oldRate, newFee);
        return true;
    }

    /**
    * @dev Calculates the fee amount for a given transaction amount and fee rate.
    * @notice This is a private function used to calculate the fee amount based on a specific transaction amount and a fee rate.
    * The fee rate is a percentage value multiplied by 100 to handle it as an integer.
    * Therefore, it needs to be divided by 10,000 during calculation to reflect the correct fee amount.
    * @param amount The transaction amount for which the fee should be computed.
    * @param fee The fee rate used for the computation. The fee is represented as a percentage out of 10,000 (equivalent to a basis point representation).
    * @return Returns the calculated fee amount.
    */
    function computeFee(uint256 amount, uint256 fee) private pure returns(uint256) {
        return amount * fee / 10000;
    }

    /**
    * @notice Enables trading. This function can only be called by the contract owner.
    * @dev Checks whether trading is already enabled. If not, it enables trading and triggers the TradingEnabled event.
    * @return Returns a boolean value. If the operation is successful, it returns true; otherwise, false.
    */
    function enableTrading() external onlyOwner returns(bool) {
        require(isTradeOpen == 0, "Trade is already enabled");
        isTradeOpen = 1;
        emit TradingEnabled(block.timestamp);
        return true;
    }

    /**
    * @notice This private function is used to send buy fees to different pools and referral addresses.
    * @dev It calculates and transfers fees for each buy pool unless the pool is toggled off.
    * It also computes and transfers the reference fee if reference fees are toggled on and there exists a referral for the owner.
    * If there's no referral or reference fees are toggled off, it computes and sends the fee to the last pool if it is not toggled off.
    * The function subtracts the total fee from the amount and returns the difference.
    * @param owner The address of the owner initiating the buy action.
    * @param from The address of the pair.
    * @param amount The amount of tokens being purchased.
    * @return Returns the amount after subtracting the total fee.
    */
    function sendBuyFees(
        address owner,
        address from,
        uint256 amount
    ) private returns(uint256) {
        uint256 totalFee = 0;
        for (uint256 i = 0; i < POOL_NUMBER - 1; i++) {
            uint256 poolTaxRate = buyPools[i].taxRate;
            if (_toggledOffBuyPools[i] == 0) {
                uint256 fee = computeFee(amount, poolTaxRate);
                totalFee += fee;
                address poolAddress = buyPools[i].poolAddress;
                _transfer(from, poolAddress, fee);
            }
        }
        address referral = _referrals[owner];
        if (toggleReferenceFees == 0 && referral != address(0)) {
            uint256 referenceFee = computeFee(amount, referenceRate);
            totalFee += referenceFee;
            _transfer(from, referral, referenceFee);
            emit TransferWithTaxFee(_referralNickname[referral], referral, owner, amount, referenceFee, block.timestamp);
        } else if (_toggledOffBuyPools[POOL_NUMBER - 1] == 0){
            uint256 lastPoolFee = computeFee(amount, buyPools[POOL_NUMBER - 1].taxRate);
            totalFee += lastPoolFee;
            address lastPoolAddress = buyPools[POOL_NUMBER - 1].poolAddress;
            _transfer(from, lastPoolAddress, lastPoolFee);
        }
        return amount - totalFee;
    }

    /**
    * @notice This private function is used to send sell fees to different pools and referral addresses.
    * @dev It calculates and transfers fees for each sell pool unless the pool is toggled off.
    * It also computes and transfers the reference fee if reference fees are toggled on and there exists a referral for the owner.
    * If there's no referral or reference fees are toggled off, it computes and sends the fee to the last pool if it is not toggled off.
    * The function subtracts the total fee from the amount and returns the difference.
    * @param owner The address of the owner initiating the sell action.
    * @param amount The amount of tokens being sold.
    * @return Returns the amount after subtracting the total fee.
    */
    function sendSellFees(address owner, uint256 amount) private returns(uint256) {
        uint256 totalFee = 0;
        for (uint256 i = 0; i < POOL_NUMBER - 1; i++) {
            uint256 poolTaxRate = sellPools[i].taxRate;
            if (_toggledOffSellPools[i] == 0) {
                uint256 fee = computeFee(amount, poolTaxRate);
                totalFee += fee;
                address poolAddress = sellPools[i].poolAddress;
                _transfer(owner, poolAddress, fee);
            }
        }
        address referral = _referrals[owner];
        if (toggleReferenceFees == 0 && referral != address(0)) {
            uint256 referenceFee = computeFee(amount, referenceRate);
            totalFee += referenceFee;
            _transfer(owner, referral, referenceFee);
            emit TransferWithTaxFee(_referralNickname[referral], referral, owner, amount, referenceFee, block.timestamp);
        } else if(_toggledOffSellPools[POOL_NUMBER - 1] == 0){
            uint256 lastPoolFee = computeFee(amount, sellPools[POOL_NUMBER - 1].taxRate);
            totalFee += lastPoolFee;
            address lastPoolAddress = sellPools[POOL_NUMBER - 1].poolAddress;
            _transfer(owner, lastPoolAddress, lastPoolFee);
        }
        return amount - totalFee;
    }


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        if (to == PairAddress && _taxFrees[from] == 0) {
            require(isTradeOpen == 1, "Trading is not open");
            amount = sendSellFees(from, amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        if (owner == PairAddress && _taxFrees[to] == 0) {
            require(isTradeOpen == 1, "Trading is not open");
            amount = sendBuyFees(to, owner, amount);
        }
        _transfer(owner, to, amount);
        return true;
    }

    /**
    * @notice This function allows eligible accounts to create a nickname.
    * @dev Function is restricted to accounts that satisfy the 'onlyPreferredAccountCreateNickname' modifier.
    * A nickname should be unique, not empty, and at most 64 characters long.
    * Emits a 'CreatedLink' event upon successful execution.
    * @param nickName The chosen nickname string.
    * @return Returns 'true' upon successful execution.
    */
    function createNickname(string memory nickName) external onlyPreferredAccountCreateNickname returns(bool) {
        require(bytes(_referralNickname[msg.sender]).length == 0, "You already have a nickname");
        require(bytes(nickName).length != 0 && bytes(nickName).length <= 64, "Nickname must be between 1 and 64 characters");
        require(_nickNames[nickName] == address(0), "Nickname is already taken");
        _nickNames[nickName] = msg.sender;
        _referralNickname[msg.sender] = nickName;
        emit CreatedLink(msg.sender, nickName, block.timestamp);
        return true;
    }

    /**
    * @notice This function returns the nickname of a given account.
    * @param account The address of the account for which the nickname is queried.
    * @return Returns the nickname string associated with the given account.
    */
    function getNickname(address account) external view returns(string memory) {
        return _referralNickname[account];
    }

    /**
    * @notice This function returns the referrer information for a given referee.
    * @param referee The address of the referee for which the referrer information is queried.
    * @return Returns a tuple containing the nickname string and address of the referrer.
    */
    function getReferrer(address referee) external view returns(string memory, address) {
        address referrer = _referrals[referee];
        return (_referralNickname[referrer], referrer);
    }

    /**
    * @notice This function returns the address associated with a given nickname.
    * @param nickname The nickname for which the associated address is queried.
    * @return Returns the address associated with the given nickname.
    */
    function getAddressWithNickname(string memory nickname) external view returns(address) {
        return _nickNames[nickname];
    }

    /**
    * @notice This function allows a user to add a referral using a nickname.
    * @param nickname The nickname of the referrer.
    * @return Returns true if the referral was successfully added.
    */
    function addReferral(string memory nickname) external returns(bool) {
        address referrer = _nickNames[nickname];
        bytes32 referrerNicknameHash = keccak256(abi.encodePacked(_referralNickname[referrer]));
        require(
            _referrals[referrer] != msg.sender &&
            _referrals[msg.sender] == address(0) &&
            referrerNicknameHash != keccak256(abi.encodePacked("")) &&
            referrer != address(0) &&
            referrer != msg.sender,
            "Invalid referral"
        );
        _referrals[msg.sender] = referrer;
        emit RegisteredReferrence(referrer, nickname, msg.sender, block.timestamp);
        return true;
    }
}