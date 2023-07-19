// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IMasterWhitelist } from "../interfaces/IMasterWhitelist.sol";

// the user types represented in this contract
enum UserType { User, MarketMaker, Vault, Lawyer, SwapManager }

interface IQuadPassport {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

interface IQuadReader {
    struct Attribute {
        bytes32 value;
        uint256 epoch;
        address issuer;
    }

    function queryFee(address _account, bytes32 _attribute)
        external
        view
        returns (uint256);

    function getAttributes(address _account, bytes32 _attribute)
        external
        payable
        returns (Attribute[] memory attributes);

    function balanceOf(address _account, bytes32 _attribute)
        external
        view 
        returns(uint256);
}

interface IVerificationRegistry {
    function isVerified(address subject) external view returns (bool);
}

/// @title Master Whitelist
/// @dev See [Quadrata docs](https://docs.quadrata.com/) for information on magic values: CODE_AML, CODE_COUNTRY,
/// information on AML scores, etc.
/// @notice Contract that manages the whitelists for: Lawyers, Market Makers, Swap Managers, Users, Vaults, and Assets.
contract MasterWhitelist is OwnableUpgradeable, IMasterWhitelist {
    
    // year 3000 in UNIX time
    uint256 constant public INF_TIME = 32503680000;

    // bytes32 code for Manual provider
    bytes32 constant public PROV_CODE_MANUAL = keccak256("Manual");

    // bytes32 code for Quadrata provider
    bytes32 constant public PROV_CODE_QUADRATA = keccak256("Quadrata");

    // bytes32 code for Verite provider
    bytes32 constant public PROV_CODE_VERITE = keccak256("Verite");

    // keccak256 of the "AML" attribute for use in Quadrata
    bytes32 constant internal CODE_AML =
        0xaf192d67680c4285e52cd2a94216ce249fb4e0227d267dcc01ea88f1b020a119;

    // keccak256 of the "COUNTRY" attribute for use in Quadrata
    bytes32 constant internal CODE_COUNTRY =
        0xc4713d2897c0d675d85b414a1974570a575e5032b6f7be9545631a1f922b26ef;

    // the AML risk score for use in Quadrata
    uint256 constant internal AML_RISK_SCORE = 5;

    // the length of the investigation period in seconds for a blacklisted user
    /// @custom:oz-renamed-from investigation_period
    uint256 public investigationPeriod;

    /// @notice Whitelist for lawyers, who are in charge of managing the other whitelists.
    /// @dev The lawyer whitelist is separate to the users whitelist and is used to keep track of addresses with the lawyer role.
    mapping(address => bool) public lawyers;

    /// @notice Whitelist for market makers.
    /// @dev The market makers whitelist is separate to the users whitelist and is used to keep track of addresses with the market maker role.
    /// It is up to the creators of the integrating contract to decide what privileges the different roles have.
    mapping(address => bool) public whitelistedMMs;

    /// @notice Maps market maker addresses to their id.
    /// @dev This is useful for integrating contracts storing labels for whitelisted market makers on-chain.
    /// @custom:oz-renamed-from idMM
    mapping(address => bytes32) public whitelistedMMIds;

    /// @notice Whitelist for users.
    mapping(address => bool) public whitelistedUsers;

    /// @notice Blacklist for users.
    mapping(address => uint256) public blacklistedUsers;

    /// @notice Blacklist for countries.
    mapping(bytes32 => bool) public blacklistedCountries;

    /// @notice Whitelist for vaults.
    /// @dev The vaults whitelist is separate to the users whitelist and is used to keep track of addresses with the vault role.
    /// It is up to the creators of the integrating contract to decide what privileges the different roles have.
    mapping(address => bool) public whitelistedVaults;

    /// @notice Whitelist for assets.
    /// @dev The assets whitelist is separate to the users whitelist and is used to keep track of addresses with the assets role.
    /// It is up to the creators of the integrating contract to decide what privileges the different roles have.
    /// @dev For example, it can be all the assets that a lending protocol can accept as collateral. Or all the assets that are
    /// used as underlying for options strategies users can invest in.
    mapping(address => bool) public whitelistedAssets;

    /// @notice Mapping of users to the KYC provider used for verification.
    mapping(address => bytes32) public kycProviders;

    /// @notice Whitelist for swap managers (in charge of initiating swaps).
    /// @dev The swap manager whitelist is separate to the users whitelist and is used to keep track of addresses with the swap manager role.
    /// It is up to the creators of the integrating contract to decide what privileges the different roles have.
    mapping(address => bool) public whitelistedSwapManagers;

    /// @notice KYC Passport contract - deprecated and unused, but necessary for storage.
    /// @custom:oz-renamed-from KYCPassport
    IQuadPassport public kycPassport;

    /// @notice KYC Reader contract.
    /// @custom:oz-renamed-from KYCReader
    IQuadReader public kycReader;

    /// @notice KYC Registry contract.
    /// @custom:oz-renamed-from KYCRegistry
    IVerificationRegistry public kycRegistry;

    // No storage variables should be removed or modified since this is an upgradeable contract.
    // It is safe to add new ones as long as they are declared after the existing ones.

    /// @notice Emits an event when an address is added to a whitelist.
    /// @param user is the address added to whitelist.
    /// @param userType is an enum of either User, MarketMaker, Lawyer, Vault, SwapManager.
    /// @param kycProvider is the provider that was used to verify the user's whitelist status.
    event AddedToWhitelist(address indexed user, UserType indexed userType, bytes32 indexed kycProvider);

    /// @notice Emits an event when an address is removed from the whitelist.
    /// @param user is the address removed from the whitelist.
    /// @param userType is an enum of either User, MarketMaker, Lawyer, Vault, SwapManager.
    event RemovedFromWhitelist(address indexed user, UserType indexed userType);

    /// @notice Emits an event when a market maker is added to the whitelist.
    /// @param user is the address added to the whitelist.
    /// @param mmId is the market maker id.
    event MMAddedToWhitelist(address indexed user, bytes32 indexed mmId);

    /// @notice Emits an event when an address is added to the blacklist.
    /// @param user is the address added to the blacklist.
    /// @param investigationTime is the time investigation period will end.
    event AddedToBlacklist(address indexed user, uint256 indexed investigationTime);

    /// @notice Emits an event when an address is removed from the blacklist.
    /// @param user is the address removed from the blacklist.
    event RemovedFromBlacklist(address indexed user);

    /// @notice Emits an event when a country is added to the blacklist.
    /// @param country is the name of the country added to the blacklist.
    event CountryAddedToBlacklist(bytes32 indexed country);

    /// @notice Emits an event when a country is removed from the blacklist.
    /// @param country is the name of the country removed from the blacklist.
    event CountryRemovedFromBlacklist(bytes32 indexed country);

    /// @notice Emits an event when an asset is added to the whitelist.
    /// @param asset is the address of the asset added to the whitelist.
    event AssetAddedToWhitelist(address indexed asset);

    /// @notice Emits an event when an asset is removed from the whitelist.
    /// @param asset is the address of the asset removed from the whitelist.
    event AssetRemovedFromWhitelist(address indexed asset);

    /// @notice Emits an event when a market maker is assigned an id.
    /// @param mm is the address of the market maker.
    /// @param id is the assigned id.
    event IdAssignedToMM(address indexed mm, bytes32 indexed id);

    /// @notice Emits an event when a new kycReader is set.
    /// @param oldReader is the address of the old kycReader.
    /// @param newReader is the address of the new kycReader.
    event SetKYCReader(address indexed oldReader, address indexed newReader);

    /// @notice Emits an event when a new kycRegistry is set.
    /// @param oldRegistry is the address of the old kycRegistry.
    /// @param newRegistry is the address of the new kycRegistry.
    event SetKYCRegistry(address indexed oldRegistry, address indexed newRegistry);

    /// @notice Emits an event when a new investigation period is set.
    /// @param oldPeriod is how long the old investigation period was.
    /// @param newPeriod is how long the new investigation period is.
    event NewInvestigationPeriod(uint256 indexed oldPeriod, uint256 indexed newPeriod);

    /// @notice Emits an event after the first attributes Quadrata KYC request.
    /// @param _userToBeWhitelisted is the user to be whitelisted.
    /// @param _userRisk is the risk status of the user to be added to the whitelist.
    /// @param _requester is the message sender.
    event AttributesRequestedFromKYC(
        address indexed _userToBeWhitelisted,
        uint256 indexed _userRisk,
        address indexed _requester
    );

    /// @notice Emits an event if the user has an AML risk score greater or equal to 5.
    /// @param _userToBeWhitelisted is the user to be whitelisted.
    /// @param _userRisk is the risk status of the user to be added to the whitelist.
    event HighRiskAMLUserRejected(
        address indexed _userToBeWhitelisted,
        uint256 indexed _userRisk
    );

    /// @notice Emits an event if the user to be whitelisted is from a blacklisted country.
    /// @param _userToBeWhitelisted is the user to be whitelisted.
    /// @param _userCountry is the country of the user to be added to the whitelist.
    event BlacklistedCountryUserRejected(
        address indexed _userToBeWhitelisted, 
        bytes32 indexed _userCountry
    );

    ///@notice Error thrown when a user cannot be whitelisted.
    error CouldNotBeWhitelisted();

    /// @notice Error thrown when msg.value is lower than risk fee + country fee.
    error MsgValueTooLow();

    /// @notice Requires that the transaction sender is a lawyer or owner (owner is automatically lawyer).
    modifier onlyLawyer() {
        require(
            msg.sender == owner() || lawyers[msg.sender],
            "Lawyer: caller is not a lawyer"
        );
        _;
    }

    /// @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer for the whitelist.
    /// @param _reader is the KYC reader address.
    /// @param _registry is the KYC registry address.
    /// @param _countryBlacklist is an array of the keccak256-hashed 2-letter country codes of blacklisted countries.
    function initialize(
        address _reader,
        address _registry,
        bytes32[] calldata _countryBlacklist
    ) external initializer {
        __Ownable_init();
        investigationPeriod = 60 * 60 * 24 * 7; //7 days
        kycReader = IQuadReader(_reader);
        kycRegistry = IVerificationRegistry(_registry);
        for (uint256 i; i < _countryBlacklist.length; ) {
            blacklistedCountries[_countryBlacklist[i]] = true;
            emit CountryAddedToBlacklist(_countryBlacklist[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Adds a swap manager to the whitelist.
    /// @param _sm is the swap manager address.
    function addSwapManagerToWhitelist(address _sm) external onlyLawyer {
        whitelistedSwapManagers[_sm] = true;

        emit AddedToWhitelist(_sm, UserType.SwapManager, PROV_CODE_MANUAL);
    }

    /// @notice Removes a swap manager from the whitelist.
    /// @param _sm is the swap manager address.
    function removeSwapManagerFromWhitelist(address _sm) external onlyLawyer {
        delete whitelistedSwapManagers[_sm];

        emit RemovedFromWhitelist(_sm, UserType.SwapManager);
    }

    /// @notice Checks if a swap manager is in the whitelist.
    /// @param _sm is the swap manager address.
    function isSwapManagerWhitelisted(address _sm)
        external
        view
        returns (bool)
    {
        return whitelistedSwapManagers[_sm];
    }

    /// @notice Modify the investigation period.
    /// @param _time is the investigation period.
    function setInvestigationPeriod(uint256 _time) external onlyLawyer {
        emit NewInvestigationPeriod(investigationPeriod, _time);

        investigationPeriod = _time;
    }

    /// @notice Gets the investigation period.
    function getInvestigationPeriod() external view returns (uint256) {
        return investigationPeriod;
    }

    /// @notice Adds a lawyer to the lawyer whitelist.
    /// @param _lawyer is the lawyer address.
    function addLawyer(address _lawyer) external onlyLawyer {
        lawyers[_lawyer] = true;

        emit AddedToWhitelist(_lawyer, UserType.Lawyer, PROV_CODE_MANUAL);
    }

    /// @notice Removes a lawyer from the lawyer whitelist.
    /// @param _lawyer is the lawyer address.
    function removeLawyer(address _lawyer) external onlyLawyer {
        delete lawyers[_lawyer];

        emit RemovedFromWhitelist(_lawyer, UserType.Lawyer);
    }

    /// @notice Verifies that the lawyer is whitelisted.
    /// @param _lawyer is the lawyer address.
    function isLawyer(address _lawyer) external view returns (bool) {
        return lawyers[_lawyer];
    }

    /// @notice Adds a user to the whitelist.
    /// @param _user is the user address.
    function addUserToWhitelist(address _user) external onlyLawyer {
        whitelistedUsers[_user] = true;
        kycProviders[_user] = PROV_CODE_MANUAL;

        if(blacklistedUsers[_user] != 0){
            delete blacklistedUsers[_user];

            emit RemovedFromBlacklist(_user);
        }

        emit AddedToWhitelist(_user, UserType.User, PROV_CODE_MANUAL);
    }

    /// @notice Adds a user to the whitelist specifying the provider.
    /// @param _user is the user address.
    /// @param _provider is the keccak256 hash of the provider name.
    function addUserToWhitelistWithProvider(address _user, bytes32 _provider)
        external
        onlyLawyer
    {
        whitelistedUsers[_user] = true;
        kycProviders[_user] = _provider;

        if(blacklistedUsers[_user] != 0){
            delete blacklistedUsers[_user];

            emit RemovedFromBlacklist(_user);
        }       

        emit AddedToWhitelist(_user, UserType.User, _provider);
    }

    /// @notice Removes a user from the whitelist.
    /// @param _user is the user address.
    function removeUserFromWhitelist(address _user) external onlyLawyer {
        delete whitelistedUsers[_user];
        delete kycProviders[_user];

        emit RemovedFromWhitelist(_user, UserType.User);
    }

    /// @notice Checks if a user is in the whitelist.
    /// @param _user is the user address.
    function isUserWhitelisted(address _user) external view returns (bool) {
        if (kycProviders[_user] == PROV_CODE_VERITE) {
            return whitelistedUsers[_user] && kycRegistry.isVerified(_user);
        }
        return whitelistedUsers[_user];
    }

    /// @notice Blacklists user pending investigation.
    /// @param _user is the user address.
    function addUserToBlacklist(address _user) external onlyLawyer {
        blacklistedUsers[_user] = block.timestamp + investigationPeriod;

        if(whitelistedUsers[_user]){
            delete whitelistedUsers[_user];

            emit RemovedFromWhitelist(_user, UserType.User);
        }

        delete kycProviders[_user];
        emit AddedToBlacklist(_user, blacklistedUsers[_user]);
    }

    /// @notice Blacklists user indefinitely after investigation.
    /// @param _user is the user address.
    function addUserToBlacklistIndefinitely(address _user) external onlyLawyer {
        blacklistedUsers[_user] = INF_TIME;

        if(whitelistedUsers[_user]){
            delete whitelistedUsers[_user];

            emit RemovedFromWhitelist(_user, UserType.User);
        }

        delete kycProviders[_user];
        emit AddedToBlacklist(_user, blacklistedUsers[_user]);
    }

    /// @notice Removes user from the blacklist after investigation.
    /// @param _user is the user address.
    function removeUserFromBlacklist(address _user) external onlyLawyer {
        delete blacklistedUsers[_user];

        emit RemovedFromBlacklist(_user);
    }

    /// @notice Checks if a user is blacklisted.
    /// @param _user is the user address.
    function isUserBlacklisted(address _user) public view returns (bool) {
        //slither-disable-next-line timestamp
        return block.timestamp < blacklistedUsers[_user];
    }

    /// @notice Adds a market maker to the whitelist.
    /// @param _mm is the market maker address.
    function addMMToWhitelist(address _mm) external onlyLawyer {
        whitelistedMMs[_mm] = true;

       emit AddedToWhitelist(_mm, UserType.MarketMaker, PROV_CODE_MANUAL);
    }

    /// @notice Adds a market maker to the whitelist.
    /// @param _mm is the market maker address.
    /// @param _id is the market maker id.
    function addMMToWhitelistWithId(address _mm, bytes32 _id)
        external
        onlyLawyer
    {
        whitelistedMMIds[_mm] = _id;
        whitelistedMMs[_mm] = true;

        emit AddedToWhitelist(_mm, UserType.MarketMaker, PROV_CODE_MANUAL);
        emit MMAddedToWhitelist(_mm, _id);
    }

    /// @notice Removes a market maker from the whitelist.
    /// @param _mm is the market maker address.
    function removeMMFromWhitelist(address _mm) external onlyLawyer {
        delete whitelistedMMs[_mm];
        delete whitelistedMMIds[_mm];

        emit RemovedFromWhitelist(_mm, UserType.MarketMaker);
    }

    /// @notice Checks if a market maker is in the whitelist.
    /// @param _mm is the market maker address.
    function isMMWhitelisted(address _mm) external view returns (bool) {
        return whitelistedMMs[_mm];
    }

    /// @notice Adds a vault to the whitelist.
    /// @param _vault is the vault address.
    function addVaultToWhitelist(address _vault) external onlyLawyer {
        whitelistedVaults[_vault] = true;

        emit AddedToWhitelist(_vault, UserType.Vault, PROV_CODE_MANUAL);
    }

    /// @notice Removes a vault from the whitelist.
    /// @param _vault is the vault address.
    function removeVaultFromWhitelist(address _vault) external onlyLawyer {
        delete whitelistedVaults[_vault];

        emit RemovedFromWhitelist(_vault, UserType.Vault);
    }

    /// @notice Checks if a vault is in the whitelist.
    /// @param _vault is the vault address.
    function isVaultWhitelisted(address _vault) external view returns (bool) {
        return whitelistedVaults[_vault];
    }

    /// @notice Adds an asset to the whitelist.
    /// @param _asset is the asset address.
    function addAssetToWhitelist(address _asset) external onlyLawyer {
        whitelistedAssets[_asset] = true;

        emit AssetAddedToWhitelist(_asset);
    }

    /// @notice Removes an asset from the whitelist.
    /// @param _asset is the asset address.
    function removeAssetFromWhitelist(address _asset) external onlyLawyer {
        delete whitelistedAssets[_asset];

        emit AssetRemovedFromWhitelist(_asset);
    }

    /// @notice Checks if an asset is in the whitelist.
    /// @param _asset is the asset address.
    function isAssetWhitelisted(address _asset) external view returns (bool) {
        return whitelistedAssets[_asset];
    }

    /// @notice Adds an id to a market maker address to identify a market maker by its address.
    /// @param _mm is the market maker address.
    /// @param _id is the unique identifier of the market maker.
    function setWhitelistedMMId(address _mm, bytes32 _id) external onlyLawyer {
        whitelistedMMIds[_mm] = _id;

        emit IdAssignedToMM(_mm, _id);
    }

    /// @notice Returns the id of a market maker address.
    /// @param _mm is the market maker address.
    function getWhitelistedMMId(address _mm) external view returns (bytes32) {
        return whitelistedMMIds[_mm];
    }

    /// @notice Adds a Country to the Blacklist.
    /// @param _name is the 2 letter country code hashed with keccak256.
    function addCountryToBlacklist(bytes32 _name) external onlyLawyer {
        blacklistedCountries[_name] = true;

        emit CountryAddedToBlacklist(_name);
    }

    /// @notice Removes a Country from the blacklist.
    /// @param _name is the 2 letter country code hashed with keccak256.
    function removeCountryFromBlacklist(bytes32 _name) external onlyLawyer {
        delete blacklistedCountries[_name];

        emit CountryRemovedFromBlacklist(_name);
    }

    /// @notice Checks if a Country is in the blacklist.
    /// @param _name is the 2 letter country code hashed with keccak256.
    function isCountryBlacklisted(bytes32 _name) public view returns (bool) {
        return blacklistedCountries[_name];
    }

    /// @notice Checks the KYC Provider a user signed up with.
    /// @param _user is the user address.
    function checkKYCProvider(address _user) external view returns (bytes32) {
        return kycProviders[_user];
    }

    /// @notice Checks if a user has a KYC passport.
    /// @param _user is the asset address.
    function hasPassport(address _user) public view returns (bool) {
        return kycReader.balanceOf(_user, CODE_AML) >= 1;
    }

    /// @notice Users add themselves to whitelist using the passport.
    /// @param _user is the user address.
    function addUserToWhitelistUsingPassport(address _user)
        external
        payable
        returns (string memory)
    {
        require(!isUserBlacklisted(_user), "user is blacklisted");
        require(hasPassport(_user), "user has no KYC passport");

        uint256 feeRisk = checkFeeRisk();
        uint256 feeCountry = checkFeeCountry();

        if (msg.value < (feeRisk + feeCountry)) {
            revert MsgValueTooLow();
        }
        
        uint256 risk = uint256(kycReader.getAttributes{value: feeRisk}(_user, CODE_AML)[0].value);

        emit AttributesRequestedFromKYC(_user, risk, msg.sender);

        if (risk >= AML_RISK_SCORE) {
            emit HighRiskAMLUserRejected(_user, risk);

            revert CouldNotBeWhitelisted();
        }

        bytes32 country = kycReader
        .getAttributes{value: feeCountry}(_user, CODE_COUNTRY)[0].value;

        if (isCountryBlacklisted(country)) {
            emit BlacklistedCountryUserRejected(_user, country);
            
            revert CouldNotBeWhitelisted();
        }

        whitelistedUsers[_user] = true;
        kycProviders[_user] = PROV_CODE_QUADRATA;

        emit AddedToWhitelist(_user, UserType.User, PROV_CODE_QUADRATA);

        return
            "By accessing and continuing to access the protocol you are agreeing to be bound by the terms and conditions shown in detail at www.trufin.io/policies";
    }

    /// @notice User adds themselves to whitelist using the registry.
    /// @param _user is the user address.
    function addUserToWhitelistUsingRegistry(address _user)
        external
        returns (string memory)
    {
        require(!isUserBlacklisted(_user), "user is blacklisted");
        require(kycRegistry.isVerified(_user), "user not verified in registry");

        whitelistedUsers[_user] = true;
        kycProviders[_user] = PROV_CODE_VERITE;

        emit AddedToWhitelist(_user, UserType.User, PROV_CODE_VERITE);
        
        return
            "By accessing and continuing to access the protocol you are agreeing to be bound by the terms and conditions shown in detail at www.trufin.io/policies";
    }

    /// @notice Sets the address of the KYC reader.
    /// @param _kyc is the KYC reader address.
    function setKYCReader(address _kyc) external onlyLawyer {
        emit SetKYCReader(address(kycReader), _kyc);

        kycReader = IQuadReader(_kyc);
    }

    /// @notice Sets the address of the KYC registry.
    /// @param _kyc is the KYC registry address.
    function setKYCRegistry(address _kyc) external onlyLawyer {
        emit SetKYCRegistry(address(kycRegistry), _kyc);
        
        kycRegistry = IVerificationRegistry(_kyc);
    }

    /// @notice Returns the passport checking fee for Risk score.
    function checkFeeRisk() public view returns (uint256) {
        return kycReader.queryFee(address(0), CODE_AML);
    }

    /// @notice Returns the passport checking fee for Country.
    function checkFeeCountry() public view returns (uint256) {
        return kycReader.queryFee(address(0), CODE_COUNTRY);
    }

    /// @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is.
    /// @param _user is the user address.
    function isAllowed(
        address _user,
        uint256,
        bytes calldata
    ) external view returns (bytes4) {
        if (whitelistedMMs[_user]) {
            return 0x19a05a7e;
        } else {
            return bytes4(0);
        }
    }
}