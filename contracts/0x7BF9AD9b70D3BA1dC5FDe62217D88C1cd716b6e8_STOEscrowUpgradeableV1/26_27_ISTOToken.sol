/// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// Import all OZ interfaces from which it extends
/// Add custom functions
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

/// @title ISTOToken
/// @custom:security-contact [email protected]
interface ISTOToken is IERC20MetadataUpgradeable {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 balance;
    }

    /// @dev Struct to store the Dividend of STO Token
    struct DividendDistribution {
        /// @dev Total Amount of Dividend
        uint256 totalAmount;
        /// @dev Block number
        uint256 blockNumber;
    }

    /// Events

    event NewDividendDistribution(address indexed token, uint256 totalAmount);

    event DividendClaimed(
        address indexed claimer,
        address indexed token,
        uint256 amountClaimed
    );

    event NewPaymentToken(
        address indexed OldPaymentToken,
        address indexed NewPaymentToken
    );

    /// @dev Event to signal that the issuer changed
    /// @param issuer New issuer address
    event ChangeIssuer(address indexed issuer);

    /// @dev Event to signal that the minter changed
    /// @param newMinter New minter address
    event ChangeMinter(address indexed newMinter);

    /// @dev Event to signal that the url changed
    /// @param newURL New url
    event ChangeURL(string newURL);

    /// @dev Event to signal that the max supply changed
    /// @param newMaxSupply New max supply
    event ChangeMaxSupply(uint256 newMaxSupply);

    /// @dev Event emitted when any group of wallet is added or remove to the whitelist
    /// @param addresses Array of addresses of the wallets changed in the whitelist
    /// @param statuses Array of boolean status to define if add or remove the wallet to the whitelist
    /// @param owner Address of the owner of the contract
    event ChangeWhitelist(address[] addresses, bool[] statuses, address owner);

    event TrackingChanged(
        address indexed from,
        address indexed oldValue,
        address indexed newValue
    );
    event CheckpointBalanceChanged(
        address indexed from,
        uint256 oldValue,
        uint256 newValue
    );

    /// @dev Method to query past holder balance
    /// @param account address to query
    /// @param blockNumber which block in the past to query
    function getPastBalance(address account, uint256 blockNumber)
        external
        returns (uint256);

    /// @dev Method to query past total supply
    /// @param blockNumber which block in the past to query
    function getPastTotalSupply(uint256 blockNumber) external returns (uint256);

    /// @dev Method to query a specific checkpoint
    /// @param account address to query
    /// @param pos index in the array
    function checkpoints(address account, uint32 pos)
        external
        returns (Checkpoint memory);

    /// @dev Method to query the number of checkpoints
    /// @param account address to query
    function numCheckpoints(address account) external returns (uint32);

    /// @dev Method to check if account is tracked. If it returns address(0), user is not tracked
    /// @param account address to query
    function trackings(address account) external returns (address);

    /// @dev Method to get account balance, it should give same as balanceOf()
    /// @param account address to query
    function getBalance(address account) external returns (uint256);

    /// @dev Method to add a new dividend distribution
    /// @param totalAmount Total Amount of Dividend
    function addDistDividend(uint256 totalAmount) external;

    /// @dev Method to claim dividends of STO Token
    function claimDividend() external;

    /// @dev Method to check how much amount of dividends the user can claim
    /// @param claimer Address of claimer of STO Token
    /// @return amount of dividends to claim
    function getMaxAmountToClaim(address claimer)
        external
        view
        returns (uint256 amount);

    /// @dev Method to check the index of where to start claiming dividends
    /// @param claimer Address of claimer of STO Token
    /// @return index after the lastClaimedBlock
    function getIndexToClaim(address claimer) external view returns (uint256);

    /// @dev Verify last claimed block for user
    /// @param _address Address to verify
    function lastClaimedBlock(address _address) external view returns (bool);

    /// @dev Method to confiscate STO tokens
    /// @dev This method is only available to the owner of the contract
    /// @param from Array of Addresses of where STO tokens are lost
    /// @param amount Array of Amounts of STO tokens to be confiscated
    /// @param to Address of where STO tokens to be sent
    function confiscate(
        address[] memory from,
        uint[] memory amount,
        address to
    ) external;

    /// @dev Method to enable/disable confiscation feature
    /// @dev This method is only available to the owner of the contract
    function changeConfiscation(bool status) external;

    /// @dev Method to disable confiscation feature forever
    /// @dev This method is only available to the owner of the contract
    function disableConfiscationFeature() external;

    /// @dev Returns the address of the current owner.
    function owner() external returns (address);

    /// @dev Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner.
    function renounceOwnership() external;

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// @notice Can only be called by the current owner.
    function transferOwnership(address newOwner) external;

    /// @dev Maximal amount of STO Tokens that can be minted
    function maxSupply() external view returns (uint256);

    /// @dev address of the minter
    function minter() external view returns (address);

    /// @dev address of the issuer
    function issuer() external view returns (address);

    /// @dev url for offchain records
    function url() external view returns (string memory);

    /// @dev Verify if the address is in the Whitelist
    /// @param adr Address to verify
    function whitelist(address adr) external view returns (bool);

    /// @dev Method to change the issuer address
    /// @dev This method is only available to the owner of the contract
    function changeIssuer(address newIssuer) external;

    /// @dev Method to change the minter address
    /// @dev This method is only available to the owner of the contract
    function changeMinter(address newMinter) external;

    /// @dev Set addresses in whitelist.
    /// @dev This method is only available to the owner of the contract
    /// @param users addresses to be whitelisted
    /// @param statuses statuses to be whitelisted
    function changeWhitelist(address[] calldata users, bool[] calldata statuses)
        external;

    /// @dev Method to setup or update the max supply of the token
    /// @dev This method is only available to the owner of the contract
    function changeMaxSupply(uint supplyCap) external;

    /// @dev Method to mint STO tokens
    /// @dev This method is only available to the owner of the contract
    function mint(address to, uint256 amount) external;

    /// @dev Method to setup or update the URI where the documents of the tokenization are stored
    /// @dev This method is only available to the owner of the contract
    function changeUrl(string memory newURL) external;

    /// @dev Expose the burn method, only the msg.sender can burn his own token
    function burn(uint256 amount) external;
}