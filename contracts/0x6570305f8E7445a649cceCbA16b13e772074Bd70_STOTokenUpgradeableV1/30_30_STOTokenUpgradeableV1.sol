/// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./STOTokenConfiscateUpgradeable.sol";

/// @title STOTokenUpgradeable ERC20 Template for STO Offering Process
/// @custom:security-contact [email protected]
contract STOTokenUpgradeableV1 is Initializable, STOTokenConfiscateUpgradeable {
    string public url;
    uint256 public maxSupply;
    address public issuer;
    address public minter;
    uint256 public totalHolders;

    /// @dev Mapping to store whether an address is already a holder or not
    mapping(address => bool) private holders;

    /// @dev Mapping storing whether addresses are whitelisted or not
    mapping(address => bool) public whitelist;

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

    modifier onlyMinter() {
        if (
            _msgSender() != issuer &&
            _msgSender() != minter &&
            _msgSender() != owner()
        ) revert NotMinter(_msgSender());
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory newName,
        string memory newSymbol,
        address newIssuer,
        uint256 supplyCap,
        string memory recordsURL,
        uint256[] memory preMints,
        address[] memory initialHolders,
        address newPaymentToken
    ) public initializer {
        ///Prevent anyone from reinitializing the contract, only the owner
        if (owner() != address(0) && _msgSender() != owner())
            revert UserIsNotOwner(_msgSender());
        /// Prevent to initialize the contract with a zero address
        if (newIssuer == address(0) || newPaymentToken == address(0))
            revert NotZeroAddress();
        /// Prevent to initialize the new Payment Tokin without Contract Address
        if (!AddressUpgradeable.isContract(newPaymentToken))
            revert NotContractAddress();

        __STOTokenConfiscate_init(
            address(this),
            newPaymentToken,
            newName,
            newSymbol
        );

        url = recordsURL;
        maxSupply = supplyCap;
        issuer = newIssuer;
        minter = owner();
        whitelist[minter] = true;

        if (maxSupply > 0) {
            for (uint256 i = 0; i < initialHolders.length; i++) {
                if (initialHolders[i] == address(0)) revert NotZeroAddress();
                if (totalSupply() + preMints[i] > maxSupply)
                    revert MaxSupplyExceeded();
                _mint(initialHolders[i], preMints[i]);
                whitelist[initialHolders[i]] = true;
            }
        } else {
            for (uint256 i = 0; i < initialHolders.length; i++) {
                if (initialHolders[i] == address(0)) revert NotZeroAddress();
                _mint(initialHolders[i], preMints[i]);
                whitelist[initialHolders[i]] = true;
            }
        }
    }

    /// @dev Method to setup the address of a valid issuer
    /// @param newIssuer is the Contract's new issuer address 
    function changeIssuer(address newIssuer) external onlyOwner {
        issuer = newIssuer;
        emit ChangeIssuer(issuer);
    }

    /// @dev add or remove address from whilelist.
    /// @dev This method is only available to the owner of the contract
    /// @param users array of addresses to be set in the whitelist
    /// @param statuses array of boolean status to define if add or remove the wallet to the whitelist
    function changeWhitelist(
        address[] calldata users,
        bool[] calldata statuses
    ) external onlyMinter {
        if (users.length != statuses.length || users.length == 0)
            revert LengthsMismatch();
        for (uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = statuses[i];
        }
        emit ChangeWhitelist(users, statuses, _msgSender());
    }

    /// @dev Method to setup or update the max supply of STOToken
    /// @dev This method is only available to the owner of the contract
    function changeMaxSupply(uint256 supplyCap) external onlyOwner {
        if (totalSupply() > supplyCap) revert MaxSupplyExceeded();
        maxSupply = supplyCap;
        emit ChangeMaxSupply(maxSupply);
    }

    /// @dev Method to setup or update the IPFS URI where the all documents of the tokenization are stored
    /// @dev This method is only available to the owner of the contract
    function changeUrl(string memory newURL) external onlyOwner {
        url = newURL;
        emit ChangeURL(url);
    }

    /// @dev Method to setup the address of a valid minter
    /// @dev This method is only available to the owner of the contract
    /// @param newMinter is the new minter address
    function changeMinter(address newMinter) external onlyOwner {
        minter = newMinter;
        emit ChangeMinter(minter);
    }

    /// @dev This method is only available to the owner of the contract
    function mint(address _to, uint256 _amount) external onlyMinter {
        if (maxSupply > 0 && totalSupply() + _amount > maxSupply)
            revert MaxSupplyExceeded();
        _mint(_to, _amount);
    }

    /// @dev Expose burn method where only the caller can burn their own STOTokens
    /// @param _amount is the amount of STO Token to burn
    function burn(uint256 _amount) public override(ERC20BurnableUpgradeable) {
        _burn(_msgSender(), _amount);
    }

    /// @dev Hook that is called after any transfer of tokens. This includes minting and burning.
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(STOTokenCheckpointsUpgradeable) {
        uint256 balanceFrom = balanceOf(from);

        // If it's minting, the from is address(0) so no need to account for that
        // If it's burning, the balanceFrom will account if now the original user has no tokens
        if(from != address(0) && balanceFrom == 0 && amount > 0) {
            totalHolders = totalHolders - 1;
            holders[from] = false;
        }

        // If it's minting, the `to` is checked to already exist as holder or not
        // If it's burning, the `to` is the zero address so no need to account for it
        if (amount > 0 && !holders[to] && to != address(0)) {
            totalHolders = totalHolders + 1;
            holders[to] = true;
        }

        super._afterTokenTransfer(from, to, amount);
    }

    /// @dev Hook that is called before any transfer of tokens. This includes minting and burning.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Upgradeable) {
        if (
            (from != address(0)) &&
            (to != address(0)) &&
            (!whitelist[from]) &&
            (to != owner())
        ) revert UserIsNotWhitelisted(from);

        // Start tracking the user if it's not tracked yet
        if (trackings(to) == address(0)) {
            lastClaimedBlock[to] = block.number;
            startTracking(to);
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}