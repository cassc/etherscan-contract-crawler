/// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../helpers/STOBeaconProxy.sol";
import "../helpers/STOErrors.sol";

/// @title STOFactory
/// @custom:security-contact [email protected]
contract STOFactoryV1 is
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    STOErrors
{
    using AddressUpgradeable for address;

    address public bkn; // Brickken Token Address
    address public brickkenVault; // Brickken Vault Address
    address public stoBeaconToken; // Beacon Token Address
    address public stoBeaconEscrow; // Beacon Escrow Address

    uint256 public priceInBKN; // Price of STO in BKN
    uint256 public priceInUSD; // Price of STO in USD
    uint256 public idSTOs; // STO ID

    // Mapping of STOTokens and STOEscrows addresses to their respective STO IDs
    mapping(uint256 => address) public stoTokens;
    mapping(uint256 => address) public stoEscrows;
    mapping(address => bool) public whitelist;

    /// @dev Struct with tokenization config
    /// @param url URI for offchain records stored in IPFS referring to one specific tokenization
    /// @param name Name of the STOToken
    /// @param symbol Symbol of the STOToken
    /// @param maxSupply Max Supply of the STOToken, 0 if unlimited supply
    /// @param paymentToken Token used to denominate issuer's withdraw on succesfull tokenization
    /// @param router Uniswap v2 Router address
    /// @param preMints Amounts of the STOToken to be minted to each initial holder
    /// @param initialHolders Wallets of the initial holders of the STOToken
    struct TokenizationConfig {
        string url;
        string name;
        string symbol;
        uint256 maxSupply;
        address paymentToken;
        address router;
        uint256[] preMints;
        address[] initialHolders;
    }

    /// @dev Event emitted when a new STO is created
    /// @param id ID of the STO
    /// @param token smart contract address of the STOToken
    /// @param escrow smart contract address of the STOEscrow
    event NewTokenization(
        uint256 indexed id,
        address indexed token,
        address indexed escrow
    );

    /// @dev Event emitted when wallets are changed in the whitelist
    /// @param addresses Addresses of the wallet to modify in the whitelist
    /// @param owner Owner of the contract that changed the whitelist
    /// @param statuses statuses that indicate if the corresponding address has been either removed or added to the whitelist
    event ChangeWhitelist(
        address[] addresses,
        bool[] statuses,
        address indexed owner
    );

    /// @dev Event emitted when the owner changes the stored beacons addresses for STOToken and STOEscrow
    /// @param newBeaconSTOTokenAddress new beacon address for STOToken
    /// @param newBeaconSTOEscrowAddress new beacon address for STOEscrow
    event ChangeBeaconAddress(
        address indexed newBeaconSTOTokenAddress,
        address indexed newBeaconSTOEscrowAddress
    );

    /// @dev Event emitted when price in BKN and/or USDC changed
    /// @param newPriceInBKN New price in BKN
    /// @param newPriceInUSD New price in USDC
    event ChangeFee(
        uint256 indexed newPriceInBKN,
        uint256 indexed newPriceInUSD
    );

    /// @dev Event emitted when fees are charged for each new tokenization
    /// @param issuer wallet address of the issuer
    /// @param currency token used to pay the fee, usually BKN
    /// @param amount Amount of fees charged
    event ChargeFee(address indexed issuer, string currency, uint256 amount);

    /// @dev Modifier to check if the caller is whitelisted
    modifier onlyWhitelisted() {
        address issuer = _msgSender();
        if (!whitelist[issuer]) revert UserIsNotWhitelisted(issuer);
        _;
    }

    function initialize(
        address beaconToken,
        address beaconEscrow,
        address bknContract,
        address vault
    ) public reinitializer(1) {
        ///Prevent anyone from reinitializing the contract
        if (super.owner() != address(0) && _msgSender() != super.owner())
            revert UserIsNotOwner(_msgSender());
        
        if (owner() == address(0)) __Ownable_init();
        
        if (vault == address(0)) revert NotZeroAddress();
        if (!Address.isContract(bknContract)) revert NotContractAddress();
        if (!Address.isContract(IBeacon(beaconToken).implementation())) revert NotContractAddress();
        if (!Address.isContract(IBeacon(beaconEscrow).implementation())) revert NotContractAddress();

        bkn = bknContract;
        brickkenVault = vault;
        stoBeaconToken = beaconToken;
        stoBeaconEscrow = beaconEscrow;
        whitelist[owner()] = true;
        priceInBKN = 31250 ether;
    }

    /// @dev Function to paused The Factory Contract
    function pauseFactory() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @dev Function to unpaused The Factory Contract
    function unpauseFactory() external whenPaused onlyOwner {
        _unpause();
    }

    /// @dev Function to add or remove a wallet to the whitelist
    /// @param users Address of the wallet to add or remove to the whitelist
    /// @param statuses Status that indicate if add or remove to the whitelist
    function changeWhitelist(
        address[] calldata users,
        bool[] calldata statuses
    ) external whenNotPaused onlyOwner {
        if (users.length != statuses.length || users.length == 0)
            revert LengthsMismatch();
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = statuses[i];
        }
        emit ChangeWhitelist(users, statuses, _msgSender());
    }

    /// @dev Change the Beacon Smart Contract Address deployed
    /// @dev This Address must be a Smart Contract deployer based on Upgradable Proxy Plugins of OpenZeppelin (both Truffle and Hardhat)
    /// @dev And the Beacon will be upgradeable through JS/TS script (e.g. via Hardhat: `await upgrades.upgradeBeacon(beaconAddress, newImplementation);`)
    /// @param newToken Address of the Beacon Smart Contract for STOToken
    /// @param newEscrow Address of the Beacon Smart Contract for STOEscrow
    function changeBeacon(
        address newToken,
        address newEscrow
    ) external whenNotPaused onlyOwner {
        if (newToken == address(0) || newEscrow == address(0))
            revert NotZeroAddress();
        if (!newToken.isContract() || !newEscrow.isContract())
            revert NotContractAddress();
        stoBeaconToken = newToken;
        stoBeaconEscrow = newEscrow;
        emit ChangeBeaconAddress(newToken, newEscrow);
    }

    /// @dev Method to change the fee price in BKN and USDC
    /// @param newPriceInBKN New price in BKN
    /// @param newPriceInUSD New price in USDC
    function changeFee(
        uint256 newPriceInBKN,
        uint256 newPriceInUSD
    ) external whenNotPaused onlyOwner {
        priceInBKN = newPriceInBKN;
        priceInUSD = newPriceInUSD;
        emit ChangeFee(newPriceInBKN, newPriceInUSD);
    }

    /// @dev Method to deploy a new STO Token
    /// @param config Configuration of the STO Token to be deployed
    function newTokenization(
        TokenizationConfig memory config
    ) external whenNotPaused onlyWhitelisted {
        address issuer = msg.sender;
        _chargeFee(issuer);

        /// By default each new token and escrow is owned by Brickken. Ownership can be hand over at any moment.
        address _owner = owner();

        if (config.initialHolders.length != config.preMints.length)
            revert LengthsMismatch();

        uint256 length = config.preMints.length;

        uint256 totalPremint = 0;

        for (uint256 i = 0; i < length; i++) {
            totalPremint += config.preMints[i];
        }

        if (config.maxSupply != 0 && totalPremint > config.maxSupply)
            revert PremintGreaterThanMaxSupply();

        address stoToken = address(
            new BeaconProxy(
                stoBeaconToken,
                abi.encodeWithSignature(
                    "initialize(string,string,address,uint256,string,uint256[],address[],address)",
                    config.name,
                    config.symbol,
                    issuer,
                    config.maxSupply,
                    config.url,
                    config.preMints,
                    config.initialHolders,
                    config.paymentToken
                )
            )
        );

        address stoEscrow = address(
            new BeaconProxy(
                stoBeaconEscrow,
                abi.encodeWithSignature(
                    "initialize(address,address,address,address,address,address)",
                    stoToken,
                    issuer,
                    _owner,
                    config.paymentToken,
                    config.router,
                    brickkenVault
                )
            )
        );

        ++idSTOs;
        stoTokens[idSTOs] = stoToken;
        stoEscrows[idSTOs] = stoEscrow;

        //Setup the escrow as a valid minter and finally transferOwnership to _owner
        ISTOToken(stoToken).changeMinter(stoEscrow);
        ISTOToken(stoToken).transferOwnership(_owner);

        emit NewTokenization(idSTOs, stoToken, stoEscrow);
    }

    /// @dev Public method to calculate how many BKN are needed in fees
    /// @return amountToPay number of BKNs to be transferred
    function getFeesInBkn() public view returns(uint256 amountToPay) {
        /// by default it takes BKN fixed units of fee
        amountToPay = priceInBKN > 0 ? priceInBKN : 0;

        /// If a fixed fee in dollar is set, it then overwrites it with it
        if (priceInUSD > 0) {
            /// Take USD price of BKN by TWAP and divide priceInUSD for that price and round up to obtain amount of BKN to pay
            /// Change then amountToPay for this amount
        }

        return amountToPay;
    }

    /// @dev Internal method to charge the fee in BKN using a fixed USDC or BKN price.
    /// @param user address of the issuer
    function _chargeFee(address user) internal {
        /// by default it takes BKN fixed units of fee
        uint256 amountToPay = getFeesInBkn();

        /// Finally is there any positive amount of BKN to be transferred, transfer them
        if (amountToPay > 0) {
            SafeERC20Upgradeable.safeTransferFrom(
                IERC20Upgradeable(bkn),
                user,
                brickkenVault,
                amountToPay
            );
            emit ChargeFee(user, "BKN", amountToPay);
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
}