// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./AllowList.sol";
import "./interfaces/IFeeSettings.sol";

/**
@title tokenize.it Token
@notice This contract implements the token used to tokenize companies, which follows the ERC20 standard and adds the following features:
    - pausing
    - access control with dedicated roles
    - burning (burner role can burn any token from any address)
    - requirements for sending and receiving tokens
    - allow list (documents which address satisfies which requirement)
    Decimals is inherited as 18 from ERC20. This should be the standard to adhere by for all deployments of this token.

    The contract inherits from ERC2771Context in order to be usable with Gas Station Network (GSN) https://docs.opengsn.org/faq/troubleshooting.html#my-contract-is-using-openzeppelin-how-do-i-add-gsn-support and meta-transactions.

 */
contract Token is ERC2771Context, ERC20Permit, Pausable, AccessControl {
    /// @notice The role that has the ability to define which requirements an address must satisfy to receive tokens
    bytes32 public constant REQUIREMENT_ROLE = keccak256("REQUIREMENT_ROLE");
    /// @notice The role that has the ability to grant minting allowances
    bytes32 public constant MINTALLOWER_ROLE = keccak256("MINTALLOWER_ROLE");
    /// @notice The role that has the ability to burn tokens from anywhere. Usage is planned for legal purposes and error recovery.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    /// @notice The role that has the ability to grant transfer rights to other addresses
    bytes32 public constant TRANSFERERADMIN_ROLE =
        keccak256("TRANSFERERADMIN_ROLE");
    /// @notice Addresses with this role do not need to satisfy any requirements to send or receive tokens
    bytes32 public constant TRANSFERER_ROLE = keccak256("TRANSFERER_ROLE");
    /// @notice The role that has the ability to pause the token. Transferring, burning and minting will not be possible while the contract is paused.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Map managed by tokenize.it, which assigns addresses requirements which they fulfill
    AllowList public allowList;

    // Fee settings of tokenize.it
    IFeeSettingsV1 public feeSettings;

    // Suggested new fee settings, which will be applied after admin approval
    IFeeSettingsV1 public suggestedFeeSettings;
    /**
    @notice  defines requirements to send or receive tokens for non-TRANSFERER_ROLE. If zero, everbody can transfer the token. If non-zero, then only those who have met the requirements can send or receive tokens. 
        Requirements can be defined by the REQUIREMENT_ROLE, and are validated against the allowList. They can include things like "must have a verified email address", "must have a verified phone number", "must have a verified identity", etc. 
        Also, tiers from 0 to four can be used.
    @dev Requirements are defined as bit mask, with the bit position encoding it's meaning and the bit's value whether this requirement will be enforced. 
        Example:
        - position 0: 1 = must be KYCed (0 = no KYC required)
        - position 1: 1 = must be american citizen (0 = american citizenship not required)
        - position 2: 1 = must be a penguin (0 = penguin status not required)
        These meanings are not defined within code, neither in the token contract nor the allowList. Nevertheless, the definition used by the people responsible for both contracts MUST match, 
        or the token contract will not work as expected. E.g. if the allowList defines position 2 as "is a penguin", while the token contract uses position 2 as "is a hedgehog", then the tokens 
        might be sold to hedgehogs, which was never the intention.
        Here some examples of how requirements can be used in practice:
        With requirements 0b0000000000000000000000000000000000000000000000000000000000000101, only KYCed penguins will be allowed to send or receive tokens.
        With requirements 0b0000000000000000000000000000000000000000000000000000000000000111, only KYCed american penguins will be allowed to send or receive tokens.
        With requirements 0b0000000000000000000000000000000000000000000000000000000000000000, even french hedgehogs will be allowed to send or receive tokens.

        The highest four bits are defined as tiers as follows:
        - 0b0000000000000000000000000000000000000000000000000000000000000000 = tier 0 is required
        - 0b0001000000000000000000000000000000000000000000000000000000000000 = tier 1 is required
        - 0b0010000000000000000000000000000000000000000000000000000000000000 = tier 2 is required
        - 0b0100000000000000000000000000000000000000000000000000000000000000 = tier 3 is required
        - 0b1000000000000000000000000000000000000000000000000000000000000000 = tier 4 is required
        This very simple definition allows for a maximum of 5 tiers, even though 4 bits are used for encoding. By sacrificing some space it can be implemented without code changes.

        Keep in mind that addresses with the TRANSFERER_ROLE do not need to satisfy any requirements to send or receive tokens.
    */
    uint256 public requirements;

    /**
    @notice defines the maximum amount of tokens that can be minted by a specific address. If zero, no tokens can be minted.
        Tokens paid as fees, as specified in the `feeSettings` contract, do not require an allowance.
        Example: Fee is set to 1% and mintingAllowance is 100. When executing the `mint` function with 100 as `amount`,
        100 tokens will be minted to the `to` address, and 1 token to the feeCollector.
    */
    mapping(address => uint256) public mintingAllowance; // used for token generating events such as vesting or new financing rounds

    event RequirementsChanged(uint newRequirements);
    event AllowListChanged(AllowList indexed newAllowList);
    event NewFeeSettingsSuggested(IFeeSettingsV1 indexed _feeSettings);
    event FeeSettingsChanged(IFeeSettingsV1 indexed newFeeSettings);
    event MintingAllowanceChanged(address indexed minter, uint256 newAllowance);

    /**
    @notice Constructor for the token 
    @param _trustedForwarder trusted forwarder for the ERC2771Context constructor - used for meta-transactions. OpenGSN v2 Forwarder should be used.
    @param _feeSettings fee settings contract that determines the fee for minting tokens
    @param _admin address of the admin. Admin will initially have all roles and can grant roles to other addresses.
    @param _name name of the specific token, e.g. "MyGmbH Token"
    @param _symbol symbol of the token, e.g. "MGT"
    @param _allowList allowList contract that defines which addresses satisfy which requirements
    @param _requirements requirements an address has to meet for sending or receiving tokens
    */
    constructor(
        address _trustedForwarder,
        IFeeSettingsV1 _feeSettings,
        address _admin,
        AllowList _allowList,
        uint256 _requirements,
        string memory _name,
        string memory _symbol
    )
        ERC2771Context(_trustedForwarder)
        ERC20Permit(_name)
        ERC20(_name, _symbol)
    {
        // Grant admin roles
        _grantRole(DEFAULT_ADMIN_ROLE, _admin); // except for the Transferer role, the _admin is the roles admin for all other roles
        _setRoleAdmin(TRANSFERER_ROLE, TRANSFERERADMIN_ROLE);

        // grant all roles to admin for now. Can be changed later, see https://docs.openzeppelin.com/contracts/2.x/api/access#Roles
        _grantRole(REQUIREMENT_ROLE, _admin);
        _grantRole(MINTALLOWER_ROLE, _admin);
        _grantRole(BURNER_ROLE, _admin);
        _grantRole(TRANSFERERADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);

        // set up fee collection
        _checkIfFeeSettingsImplementsInterface(_feeSettings);
        feeSettings = _feeSettings;

        // set up allowList
        require(
            address(_allowList) != address(0),
            "AllowList must not be zero address"
        );
        allowList = _allowList;

        // set requirements (can be 0 to allow everyone to send and receive tokens)
        requirements = _requirements;
    }

    function setAllowList(
        AllowList _allowList
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            address(_allowList) != address(0),
            "AllowList must not be zero address"
        );
        allowList = _allowList;
        emit AllowListChanged(_allowList);
    }

    function setRequirements(
        uint256 _requirements
    ) external onlyRole(REQUIREMENT_ROLE) {
        requirements = _requirements;
        emit RequirementsChanged(_requirements);
    }

    /**
     * @notice This function can only be used by the feeSettings owner to suggest switching to a new feeSettings contract.
     *      The new feeSettings contract will be applied immediately after admin approval.
     * @dev This is a possibility to change fees without honoring the delay enforced in the feeSettings contract. Therefore, approval of the admin is required.
     * @param _feeSettings the new feeSettings contract
     */
    function suggestNewFeeSettings(IFeeSettingsV1 _feeSettings) external {
        require(
            _msgSender() == feeSettings.owner(),
            "Only fee settings owner can suggest fee settings update"
        );
        _checkIfFeeSettingsImplementsInterface(_feeSettings);
        suggestedFeeSettings = _feeSettings;
        emit NewFeeSettingsSuggested(_feeSettings);
    }

    /**
     * @notice This function can only be used by the admin to approve switching to the new feeSettings contract.
     *     The new feeSettings contract will be applied immediately.
     * @dev Enforcing the suggested and accepted new contract to be the same is not necessary, prevents frontrunning.
     *      Requiring not 0 prevent bricking the token.
     * @param _feeSettings the new feeSettings contract
     */
    function acceptNewFeeSettings(
        IFeeSettingsV1 _feeSettings
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // after deployment, suggestedFeeSettings is 0x0. Therefore, this check is necessary, otherwise the admin could accept 0x0 as new feeSettings.
        // Checking that the suggestedFeeSettings is not 0x0 would work, too, but this check is used in other places, too.
        _checkIfFeeSettingsImplementsInterface(_feeSettings);

        require(
            _feeSettings == suggestedFeeSettings,
            "Only suggested fee settings can be accepted"
        );
        feeSettings = suggestedFeeSettings;
        emit FeeSettingsChanged(_feeSettings);
    }

    /** 
        @notice minting contracts such as personal investment invite, vesting, crowdfunding must be granted a minting allowance.
        @notice the contract does not keep track of how many tokens a minter has minted over time
        @param _minter address of the minter
        @param _allowance how many tokens can be minted by this minter, in addition to their current allowance (excluding the tokens minted as a fee)
    */
    function increaseMintingAllowance(
        address _minter,
        uint256 _allowance
    ) external onlyRole(MINTALLOWER_ROLE) {
        mintingAllowance[_minter] += _allowance;
        emit MintingAllowanceChanged(_minter, mintingAllowance[_minter]);
    }

    /** 
        @dev underflow is cast to 0 in order to be able to use decreaseMintingAllowance(minter, UINT256_MAX) to reset the allowance to 0
        @param _minter address of the minter
        @param _allowance how many tokens should be deducted from the current minting allowance (excluding the tokens minted as a fee)
    */
    function decreaseMintingAllowance(
        address _minter,
        uint256 _allowance
    ) external onlyRole(MINTALLOWER_ROLE) {
        if (mintingAllowance[_minter] > _allowance) {
            mintingAllowance[_minter] -= _allowance;
            emit MintingAllowanceChanged(_minter, mintingAllowance[_minter]);
        } else {
            mintingAllowance[_minter] = 0;
            emit MintingAllowanceChanged(_minter, 0);
        }
    }

    function mint(address _to, uint256 _amount) external {
        require(
            mintingAllowance[_msgSender()] >= _amount,
            "MintingAllowance too low"
        );
        mintingAllowance[_msgSender()] -= _amount;
        // this check is executed here, because later minting of the buy amount can not be differentiated from minting of the fee amount
        _checkIfAllowedToTransact(_to);
        _mint(_to, _amount);
        // collect fees
        uint256 fee = feeSettings.tokenFee(_amount);
        if (fee != 0) {
            // the fee collector is always allowed to receive tokens
            _mint(feeSettings.feeCollector(), fee);
        }
    }

    function burn(
        address _from,
        uint256 _amount
    ) external onlyRole(BURNER_ROLE) {
        _burn(_from, _amount);
    }

    /**
    @notice There are 3 types of transfers:
        1. minting: transfers from the zero address to another address. Only minters can do this, which is checked in the mint function. The recipient must be allowed to transact.
        2. burning: transfers from an address to the zero address. Only burners can do this, which is checked in the burn function.
        3. transfers from one address to another. The sender and recipient must be allowed to transact.
    @dev this hook is executed before the transfer function itself 
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _amount);
        _requireNotPaused();
        if (_from != address(0) && _to != address(0)) {
            // token transfer
            _checkIfAllowedToTransact(_from);
            _checkIfAllowedToTransact(_to);
        }
        /*  if _from is 0x0, tokens are minted:
                - receiver's properties are checked in the mint function
                - the minter's allowance is checked in the mint function
                - extra tokens can be minted for feeCollector in the mint function
            if _to is 0x0, tokens are burned: 
                - only burner is allowed to do this, which is checked in the burn function
        */
    }

    /**
     * @notice checks if _address is a) a transferer or b) satisfies the requirements
     */
    function _checkIfAllowedToTransact(address _address) internal view {
        require(
            hasRole(TRANSFERER_ROLE, _address) ||
                allowList.map(_address) & requirements == requirements,
            "Sender or Receiver is not allowed to transact. Either locally issue the role as a TRANSFERER or they must meet requirements as defined in the allowList"
        );
    }

    /**
     * @notice Make sure the address posing as FeeSettings actually implements the interfaces that are needed.
     *          This is a sanity check to make sure that the FeeSettings contract is actually compatible with this token.
     * @dev  This check uses EIP165, see https://eips.ethereum.org/EIPS/eip-165
     */
    function _checkIfFeeSettingsImplementsInterface(
        IFeeSettingsV1 _feeSettings
    ) internal view {
        // step 1: needs to return true if EIP165 is supported
        require(
            _feeSettings.supportsInterface(0x01ffc9a7) == true,
            "FeeSettings must implement IFeeSettingsV1"
        );
        // step 2: needs to return false if EIP165 is supported
        require(
            _feeSettings.supportsInterface(0xffffffff) == false,
            "FeeSettings must implement IFeeSettingsV1"
        );
        // now we know EIP165 is supported
        // step 3: needs to return true if IFeeSettingsV1 is supported
        require(
            _feeSettings.supportsInterface(type(IFeeSettingsV1).interfaceId),
            "FeeSettings must implement IFeeSettingsV1"
        );
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev both ERC20Pausable and ERC2771Context have a _msgSender() function, so we need to override and select which one to use.
     */
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    /**
     * @dev both ERC20Pausable and ERC2771Context have a _msgData() function, so we need to override and select which one to use.
     */
    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}