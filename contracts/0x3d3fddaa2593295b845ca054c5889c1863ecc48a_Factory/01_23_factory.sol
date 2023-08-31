// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/Itreasury.sol";
import "./interfaces/IIndexStruct.sol";
import "./interfaces/IIndex.sol";

/// @title A Factory Contract
/// @notice This is the main factory contract which deploys and control index contracts
/// @dev This is the admin for the deployed index contracts and can call their functions
contract Factory is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IndexStruct,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    ///@notice stores maximum number of tokens allowed in the index contract
    uint private maxNumberofTokens;

    /// @notice stores the addresses of the created index fund contracts
    address[] public indexAddressArray;

    /// @dev stores the address of dex contract
    address private dex;

    /// @dev stores the address of the index implmementation contract
    address private indexImplementation;

    /// @dev stores the address for treasury Implementation contract
    address private treasuryImplementation;

    /// @notice stores the id of index address by id
    mapping(address => uint) public indexIdByAddress;

    /// @notice Event for creation of index fund contract
    event CreateIndexFund(
        uint indexed id,
        address indexed indexAddress,
        IndexData indexData,
        FeeData feesData
    );

    /// @notice Event for updation of index fund contract
    event UpdateIndexFund(
        uint indexed id,
        uint16[] percentages,
        uint16[] previouspercentages
    );

    /// @notice Event for Purchase in the index fund contract
    event Purchased(uint indexed id, uint amount, uint[] slippageAllowed);

    /// @notice Event for updation of index fund contract owner
    event UpdateIndexOwner(uint indexed id, address newOwner);

    /// @notice Event for selling of index fund contract
    event Sold(uint indexed id, uint[] amounts, uint[] slippageAllowed);

    /// @notice Event for Deposit in the index fund contract
    event Deposit(uint indexed id, uint amount, address ptoken);

    /// @notice Event for Rebalance Purchase of  index fund contract
    event RebalancePurchase(
        uint indexed id,
        uint amount,
        uint[] slippageAllowed
    );

    /// @notice Event for Rebalance Sell of the index fund contract
    event RebalanceSell(
        uint indexed id,
        uint[] amounts,
        uint[] slippageAllowed
    );

    /// @notice Event for distribution in the index fund contract
    event DistributeAmountEvent(uint indexed id, uint numberOfWithdrawers);

    /// @notice Event for distribution  of user in the index fund contract before purchase
    event DistributeAmountBeforePurchaseEvent(
        uint indexed id,
        uint numberOfWithdrawers
    );

    ///@notice Event for performance fee transfer
    event PerformanceFeeTransfer(uint indexed id);

    /// @notice Error for zero address
    error ZeroAddress();

    /// @notice Error for zero amount
    error ZeroAmount();

    /// @notice Error for Wrong Percentage Sum
    error PercentageSum();

    /// @notice Error For Wrong Fee Percentage
    error WrongFee();

    /// @notice Error for Wrong Id
    error WrongId();

    /// @notice Error for Wrong Array Length
    error ArrayLength(uint);

    /// @notice Error for Wrong Array Element
    error WrongArray();

    /// @notice modifier for checking if the id is within the created ids
    modifier idCheck(uint id) {
        if (id >= indexAddressArray.length) revert WrongId();

        _;
    }

    /// @notice modifier to check if the amount is greater than 0 or not
    modifier zeroAmountCheck(uint amount) {
        if (!(amount > 0)) revert ZeroAmount();
        _;
    }

    /// @notice modifier to check the zero address
    modifier zeroAddressCheck(address addr) {
        if (addr == address(0)) revert ZeroAddress();

        _;
    }

    /// @notice modifier to check the zero amount in array
    modifier zeroAmountArrayCheck(uint[] calldata amount) {
        for (uint i = 0; i < amount.length; i++) {
            if (amount[i] == 0) revert ZeroAmount();
        }
        _;
    }

    /// @notice modifier to check percentage sum equals 10000
    modifier percentageSumCheck(uint id, uint16[] calldata percentages) {
        if (
            percentages.length !=
            IndexInterface(indexAddressArray[id]).tokensLength()
        ) revert ArrayLength(percentages.length);

        uint16 percentagesum;

        for (uint i = 0; i < percentages.length; i++) {
            percentagesum += percentages[i];
        }
        if (percentagesum != 10000) revert PercentageSum();

        _;
    }

    /// @notice modifier to check the zero address
    modifier indexDataCheck(IndexData memory indexData) {
        if (
            indexData._percentages.length != indexData._tokens.length ||
            indexData._tokens.length > maxNumberofTokens
        ) revert ArrayLength(indexData._percentages.length);

        if (
            indexData._thresholdamount == 0 ||
            indexData._indexendingtime == 0 ||
            indexData._depositendingtime == 0
        ) revert ZeroAmount();

        uint percentagesum;

        for (uint i = 0; i < indexData._percentages.length; i++) {
            if (indexData._tokens[i] == address(0)) revert ZeroAddress();

            percentagesum += indexData._percentages[i];
        }

        if (percentagesum != 10000) revert WrongFee();

        _;
    }

    /// @notice modifier to check the zero address
    modifier feeCheck(uint managementFee, uint peformanceFee) {
        if (managementFee > 9000 || peformanceFee > 9000) revert WrongFee();
        _;
    }

    /// @notice modifier to check the zero address
    modifier arrayCheck(uint id, uint[] memory arrCheck) {
        if (
            arrCheck.length !=
            IndexInterface(indexAddressArray[id]).tokensLength()
        ) revert ArrayLength(arrCheck.length);
        _;
    }

    ///@notice function to initialze the factory contract.
    ///@param indexImplementationAddress the implementation address of the index contract.
    ///@param dexAddress the  address of the dex contract.
    ///@param treasury the implementation address of the treasury contract.
    ///@param maxTokensAllowed the maximum number of tokens allowed in the index contract
    function initialize(
        address indexImplementationAddress,
        address dexAddress,
        address treasury,
        uint maxTokensAllowed
    )
        public
        initializer
        zeroAddressCheck(indexImplementationAddress)
        zeroAddressCheck(dexAddress)
        zeroAddressCheck(treasury)
        zeroAmountCheck(maxTokensAllowed)
    {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        indexImplementation = indexImplementationAddress;
        dex = dexAddress;
        treasuryImplementation = treasury;
        maxNumberofTokens = maxTokensAllowed;
    }

    ///@notice function to pause the functions
    function pause() public onlyOwner {
        _pause();
    }

    ///@notice function to unpause the functions
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice function to set the implementation contract address for the minimal proxy index contract
    /// @param implementation The address for the implementation address
    function setImplementation(
        address implementation
    ) external onlyOwner whenNotPaused zeroAddressCheck(implementation) {
        indexImplementation = implementation;
    }

    /// @notice This function is used to update the implementation contract address for the treasury minimal proxy
    /// @param treasuryAddress The address for the new dex aggregator
    function setTreasuryInFactory(
        address treasuryAddress
    ) external onlyOwner whenNotPaused zeroAddressCheck(treasuryAddress) {
        treasuryImplementation = treasuryAddress;
    }

    /// @notice This function is used to update the address of the dex Aggreagator in the Factory Contract
    /// @param dexAggregatorAddress The address for the new dex aggregator
    function setDexInFactory(
        address dexAggregatorAddress
    ) external onlyOwner whenNotPaused zeroAddressCheck(dexAggregatorAddress) {
        dex = dexAggregatorAddress;
    }

    ///@notice This function will check the supplied inputs, creates a new index fund contract
    /// and stores the its address inside the indexInstanceArray
    ///@param indexData The structure containing data for the index fund contract
    ///@param managmentFeeBasisPoint The management fee percent in basis point
    ///@param performanceFeeBasisPoint The perfromance fee percent in basis point
    ///@param minimumPtokenforPurchase The minimum amount of ptoken left that will make the purchase state to be true
    function createIndexFund(
        IndexData calldata indexData,
        uint managmentFeeBasisPoint,
        uint performanceFeeBasisPoint,
        uint minimumPtokenforPurchase
    )
        external
        onlyOwner
        whenNotPaused
        indexDataCheck(indexData)
        feeCheck(managmentFeeBasisPoint, performanceFeeBasisPoint)
        zeroAmountCheck(minimumPtokenforPurchase)
    {
        uint id = indexAddressArray.length;
        FeeData memory _feedata;
        _feedata.managementFeeBasisPoint = managmentFeeBasisPoint;
        _feedata.performanceFeeBasisPoint = performanceFeeBasisPoint;

        _feedata.managementFeeAddress = Clones.cloneDeterministic(
            treasuryImplementation,
            keccak256(abi.encodePacked(id, "management"))
        );
        Itreasury(_feedata.managementFeeAddress).initialize(msg.sender);

        _feedata.performanceFeeAddress = Clones.cloneDeterministic(
            treasuryImplementation,
            keccak256(abi.encodePacked(id, "performance"))
        );
        Itreasury(_feedata.performanceFeeAddress).initialize(msg.sender);

        address indexAddress = Clones.cloneDeterministic(
            indexImplementation,
            keccak256(abi.encodePacked(id, "imp"))
        );

        IndexInterface(indexAddress).initialize(
            indexData,
            dex,
            _feedata,
            minimumPtokenforPurchase
        );
        indexIdByAddress[indexAddress] = id;
        indexAddressArray.push(indexAddress);
        emit CreateIndexFund(id, indexAddress, indexData, _feedata);
    }

    ///@notice the Function to update the Index percentages
    ///@param id The id of the index contract
    ///@param newPercentages The new percentages for the index contract
    function updateIndexFund(
        uint id,
        uint16[] calldata newPercentages
    )
        external
        onlyOwner
        whenNotPaused
        idCheck(id)
        percentageSumCheck(id, newPercentages)
    {
        IndexInterface(indexAddressArray[id]).udpateIndex(newPercentages);

        emit UpdateIndexFund(
            id,
            newPercentages,
            getIndexPreviousPercentages(id)
        );
    }

    /// @notice Returns the current index percentages
    /// @param id The id of the index contract
    function getIndexCurrentPercentages(
        uint id
    ) external view idCheck(id) returns (uint16[] memory) {
        return IndexInterface(indexAddressArray[id]).currentPercentageArray();
    }

    ///@notice Returns the previous index percentages
    ///@param id The id of the index contract
    function getIndexPreviousPercentages(
        uint id
    ) public view idCheck(id) returns (uint16[] memory) {
        return IndexInterface(indexAddressArray[id]).previousPercentageArray();
    }

    /// @notice Returns the number of index contracts created
    function getNumberofindex() external view returns (uint) {
        return indexAddressArray.length;
    }

    ///@notice Will be used to authorize the upgrade
    ///@param newImplementation The address of the new implementation for the factory contract
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    ///@notice Will update the owner of the index contract
    ///@param id The id of the index contrac
    ///@param newOwner The address of the new Owner
    function updateIndexOwner(
        uint id,
        address newOwner
    ) external onlyOwner idCheck(id) zeroAddressCheck(newOwner) whenNotPaused {
        IndexInterface(indexAddressArray[id]).transferOwnership(newOwner);
        emit UpdateIndexOwner(id, newOwner);
    }

    ///@notice Will purchase/swap the index tokens in place of ptokens for the index contract
    ///@param id The id of the index contrac
    ///@param amount The amount of p token that we want to use for purchase/swap index tokens
    ///@param slippageAllowed The array of slippage percentages
    function purchase(
        uint id,
        uint amount,
        uint[] calldata slippageAllowed
    )
        external
        onlyOwner
        idCheck(id)
        zeroAmountCheck(amount)
        arrayCheck(id, slippageAllowed)
        whenNotPaused
    {
        IndexInterface(indexAddressArray[id]).purchase(amount, slippageAllowed);
        emit Purchased(id, amount, slippageAllowed);
    }

    ///@notice Will sell/swap the index tokens to get ptokens for the index contract
    ///@param id The id of the index contrac
    ///@param amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    ///@param slippageAllowed The array of slippage percentages
    function sell(
        uint id,
        uint[] calldata amounts,
        uint[] calldata slippageAllowed
    )
        external
        onlyOwner
        whenNotPaused
        idCheck(id)
        arrayCheck(id, slippageAllowed)
        arrayCheck(id, amounts)
        nonReentrant
    {
        IndexInterface(indexAddressArray[id]).sell(amounts, slippageAllowed);
        emit Sold(id, amounts, slippageAllowed);
    }

    ///@notice Will purchase/swap the updated index tokens in place of ptokens for the index contract
    ///@param id The id of the index contrac
    ///@param amount The amount of p token that we want to use for purchase/swap index tokens
    ///@param slippageAllowed The array of slippage percentages
    function rebalancePurchase(
        uint id,
        uint amount,
        uint[] calldata slippageAllowed
    )
        external
        onlyOwner
        whenNotPaused
        idCheck(id)
        zeroAmountCheck(amount)
        arrayCheck(id, slippageAllowed)
    {
        IndexInterface(indexAddressArray[id]).rebalancePurchase(
            amount,
            slippageAllowed
        );
        emit RebalancePurchase(id, amount, slippageAllowed);
    }

    /// @notice Will sell/swap the previous index tokens for ptokens for the index contract
    /// @param id The id of the index contrac
    /// @param amounts The array of amounts of index tokens that we want to use for sell/swap for p tokens
    /// @param slippageAllowed The array of slippage percentages
    function rebalanceSell(
        uint id,
        uint[] calldata amounts,
        uint[] calldata slippageAllowed
    )
        external
        onlyOwner
        idCheck(id)
        arrayCheck(id, slippageAllowed)
        arrayCheck(id, amounts)
        whenNotPaused
    {
        IndexInterface(indexAddressArray[id]).rebalanceSell(
            amounts,
            slippageAllowed
        );
        emit RebalanceSell(id, amounts, slippageAllowed);
    }

    ///@notice Will deposit the ptokens in the index contract
    ///@param id The id of the index contract
    ///@param amount the amount of ptoken
    function deposit(
        uint id,
        uint amount
    ) external idCheck(id) zeroAmountCheck(amount) whenNotPaused nonReentrant {
        address ptoken = IndexInterface(indexAddressArray[id])
            .getPurchaseToken();

        IERC20Upgradeable(ptoken).safeTransferFrom(
            msg.sender,
            indexAddressArray[id],
            amount
        );

        IndexInterface(indexAddressArray[id]).deposit(amount, msg.sender);
        emit Deposit(id, amount, ptoken);
    }

    ///@notice will return the token balance of current tokens of the index
    /// @param id The id of the index contract
    function tokenBalances(
        uint id
    ) external view idCheck(id) returns (uint[] memory) {
        return IndexInterface(indexAddressArray[id]).tokensBalances();
    }

    ///@notice will return the Index Tokens
    /// @param id The id of the index contract
    function getIndexTokens(
        uint id
    ) external view idCheck(id) returns (address[] memory) {
        return IndexInterface(indexAddressArray[id]).indexTokens();
    }

    ///@notice will return the token balance of ptokens tokens of the index
    /// @param id The id of the index contract
    function pTokenBalance(uint id) external view idCheck(id) returns (uint) {
        return IndexInterface(indexAddressArray[id]).pTokenBalance();
    }

    ///@notice will distribute the ptokens after sell
    /// @param id The id of the index contract
    /// @param numberOfWithdrawers The first n number of withdrawers
    function distributeAmount(
        uint id,
        uint numberOfWithdrawers
    )
        external
        onlyOwner
        whenNotPaused
        idCheck(id)
        zeroAmountCheck(numberOfWithdrawers)
    {
        IndexInterface(indexAddressArray[id]).distributeAmount(
            numberOfWithdrawers
        );
        emit DistributeAmountEvent(id, numberOfWithdrawers);
    }

    ///@notice will return the states of the index contract
    ///@param id The id of the index contract that wwant state of
    function returnStates(
        uint id
    ) external view idCheck(id) returns (State memory) {
        return IndexInterface(indexAddressArray[id]).state();
    }

    ///@notice will return the states of the index contract
    ///@param id The id of the index contract that wwant state of
    function returnFeeData(
        uint id
    ) external view idCheck(id) returns (FeeData memory) {
        return IndexInterface(indexAddressArray[id]).feeData();
    }

    ///@notice will return the total deposit of ptokens in the index contract
    /// @param id The id of the index contract
    function getTotalDeposit(uint id) public view returns (uint) {
        return IndexInterface(indexAddressArray[id]).totalDeposit();
    }

    ///@notice will return the  deposit of ptokens by the user in the index contract
    ///@param id The id of the index contract
    ///@param user The address of the user that we want to get deposit for
    function getDepositByUser(
        uint id,
        address user
    ) public view returns (uint) {
        return IndexInterface(indexAddressArray[id]).getDepositByUser(user);
    }

    ///@notice will return the deposit of ptokens by the user to the first n number of Depositors
    ///@param id The id of the index contract
    ///@param numberOfWithdrawers The first n number of depositors that we want to withdraw for
    function distributeBeforePurchase(
        uint id,
        uint numberOfWithdrawers
    )
        external
        onlyOwner
        whenNotPaused
        idCheck(id)
        zeroAmountCheck(numberOfWithdrawers)
    {
        IndexInterface(indexAddressArray[id]).distributeBeforePurchase(
            numberOfWithdrawers
        );
        emit DistributeAmountBeforePurchaseEvent(id, numberOfWithdrawers);
    }

    ///@notice will udpate the number of max tokens that can be added in the index
    ///@param numberOfTokens the number of tokens that we want max tokens to be
    function updateMaxTokens(
        uint numberOfTokens
    ) external zeroAmountCheck(numberOfTokens) onlyOwner {
        maxNumberofTokens = numberOfTokens;
    }

    ///@notice will return the number of users left to withdraw in that particular index
    ///@param id The id of the index contract
    function usersLefttoWithdraw(
        uint id
    ) external view idCheck(id) returns (uint users) {
        return IndexInterface(indexAddressArray[id]).userLeftToWithdraw();
    }

    ///@notice will update the purchase state in the particular index
    ///@param id The id of the index contract
    function updatePurchase(uint id) external onlyOwner idCheck(id) {
        IndexInterface(indexAddressArray[id]).updatePurchaseState();
    }

    ///@notice will update the sell state in the particular index
    ///@param id The id of the index contract
    function updateSell(uint id) external onlyOwner idCheck(id) {
        IndexInterface(indexAddressArray[id]).updateSellState();
    }

    ///@notice will update the purchase state in the particular index
    ///@param id The id of the index contract
    function updateRebalancePurchase(uint id) external onlyOwner idCheck(id) {
        IndexInterface(indexAddressArray[id]).updateRebalancePurchaseState();
    }

    ///@notice will update the rebalance sell state in the particular index
    ///@param id The id of the index contract
    function updateRebalanceSell(uint id) external onlyOwner idCheck(id) {
        IndexInterface(indexAddressArray[id]).updateRebalanceSellState();
    }

    ///@notice will update the rebalance sell state in the particular index
    ///@param id The id of the index contract
    function updateIndexUpdateState(uint id) external onlyOwner idCheck(id) {
        IndexInterface(indexAddressArray[id]).updateTokenUpdateState();
    }

    ///@notice will update the dex for the particular index
    ///@param id The id of the index contract
    function updateDex(
        uint id,
        address dexAddress
    ) external onlyOwner zeroAddressCheck(dexAddress) idCheck(id) {
        IndexInterface(indexAddressArray[id]).updateDex(dexAddress);
    }

    ///@notice will transfer the performance fee to the treasury contract
    ///@param id The id of the index contract
    function performanceFeesTransfer(uint id) external onlyOwner idCheck(id) {
        IndexInterface(indexAddressArray[id]).performaneFeesTransfer();
        emit PerformanceFeeTransfer(id);
    }
}