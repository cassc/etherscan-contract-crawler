// SPDX-License-Identifier: MIT
//slither-disable-next-line solc-version
pragma solidity =0.8.14;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { SignatureChecker } from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import { IQuadPassport } from "../interfaces/IQuadPassport.sol";
import { IQuadReader } from "../interfaces/IQuadReader.sol";
import { IVerificationRegistry } from "../interfaces/IVerificationRegistry.sol";

/**
 * @title Master Whitelist
 * @notice Contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
contract MasterWhitelist is OwnableUpgradeable {
    uint256 investigation_period;
    uint256 constant INF_TIME = 32503680000; //year 3000

    /**
     * @notice Whitelist for lawyers, who are in charge of managing the other whitelists
     */
    mapping(address => bool) lawyers;

    /**
     * @notice Whitelist for Market Makers
     */
    mapping(address => bool) whitelistedMMs;

    /**
     * @notice maps Market Maker addresses to the MM they belong to
     */
    mapping(address => bytes32) idMM;

    /**
     * @notice Whitelist for Users
     */
    mapping(address => bool) whitelistedUsers;

    /**
     * @notice Blacklist for Users
     */
    mapping(address => uint256) blacklistedUsers;

    /**
     * @notice Blacklist for Countries
     */
    mapping(bytes32 => bool) blacklistedCountries;

    /**
     * @notice Whitelist for Vaults
     */
    mapping(address => bool) whitelistedVaults;

    /**
     * @notice Whitelist for Assets
     */
    mapping(address => bool) whitelistedAssets;

    /**
     * @notice Mapping of users to the kycProvider that whitelisted them
     */
    mapping(address => bytes32) kycProviders;

    /**
     * @notice whitelist for swap managers (in charge of initiating swaps)
     */
    mapping(address => bool) whitelistedSwapManagers;

    /**
     * @notice KYCPassport contract
     */
    IQuadPassport public KYCPassport;

    /**
     * @notice KYCReader contract
     */
    IQuadReader public KYCReader;

    /**
     * @notice KYCRegistry contract
     */
    IVerificationRegistry public KYCRegistry;

    //bytes32 code for Manual provider
    bytes32 constant PROV_CODE_MANUAL = keccak256("Manual");

    //bytes32 code for Quadrata provider
    bytes32 constant PROV_CODE_QUADRATA = keccak256("Quadrata");

    //bytes32 code for Verite provider
    bytes32 constant PROV_CODE_VERITE = keccak256("Verite");

    //bytes32 code for Risk
    bytes32 constant CODE_RISK =
        0xaf192d67680c4285e52cd2a94216ce249fb4e0227d267dcc01ea88f1b020a119;

    //bytes32 code for Country
    bytes32 constant CODE_COUNTRY =
        0xc4713d2897c0d675d85b414a1974570a575e5032b6f7be9545631a1f922b26ef;

    //No storage variables should be removed or modified since this is an upgradeable contract.
    //It is safe to add new ones as long as they are declared after the existing ones.

    /**
     * @notice emits an event when an address is added to a whitelist
     * @param user is the address added to whitelist
     * @param userType can take values 0,1,2,3 if the address is a user, market maker, vault or lawyer respectively
     */
    event UserAddedToWhitelist(address indexed user, uint256 indexed userType);

    /**
     * @notice emits an event when an address is removed from the whitelist
     * @param user is the address removed from the whitelist
     * @param userType can take values 0,1,2,3,4 if the address is a user, market maker, vault, lawyer, or swapManager respectively
     */
    event userRemovedFromWhitelist(
        address indexed user,
        uint256 indexed userType
    );

    /**
     * @notice emits an event when add mm  to the whitelist
     * @param user is the address added to the whitelist
     */
    event mmAddedToWhitelist(address indexed user, bytes32 indexed mmid);

    /**
     * @notice emits an event when an address is added to a blacklist
     * @param user is the address added to blacklisted
     * @param investigation_time is the time investigation period will end
     */
    event userAddedToBlacklist(
        address indexed user,
        uint256 investigation_time
    );

    /**
     * @notice emits an event when an address is removed from the blacklist
     * @param user is the address removed from the blacklist
     */
    event userRemovedFromBlacklist(address indexed user);

    event newInvestigationPeriod(uint256 indexed _oldPeriod, uint256 indexed _newPeriod);

    event KYCPassportChanged(address indexed _passport);

    event KYCReaderChanged(address indexed _reader);

    event KYCRegistryChanged(address indexed _registry);

    event CountryToBlacklistAdded(bytes32 indexed _country);

    event RemovedCountryFromBlacklist(bytes32 indexed _country);

    event IdMMChanged(address indexed _mm, bytes32 indexed _id);

    event AddedAssetToWhitelist(address indexed _asset);

    event RemovedAssetFromWhitelist(address indexed _asset);

    /**
     * @notice Requires that the transaction sender is a lawyer or owner (owner is automatically lawyer)
     */
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

    /**
     * @notice Initializer for the whitelist
     * @param _passport is kyc passport address
     * @param _reader is kyc reader address
     * @param _registry is kyc registry address
     * @param _countryBlacklist is an array of the 2 letter country code hashed with keccak256 of blacklisted countries
     */
    function initialize(
        address _passport,
        address _reader,
        address _registry,
        bytes32[] memory _countryBlacklist
    ) external initializer {
        __Ownable_init();
        investigation_period = 60 * 60 * 24 * 7; //7 days
        KYCPassport = IQuadPassport(_passport);
        KYCReader = IQuadReader(_reader);
        KYCRegistry = IVerificationRegistry(_registry);
        for (uint256 i = 0; i < _countryBlacklist.length; ) {
            blacklistedCountries[_countryBlacklist[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Adds a Swap Manager to the Whitelist
     * @param _sm is the Swap Manager address
     */
    function addSwapManagerToWhitelist(address _sm) external onlyLawyer {
        whitelistedSwapManagers[_sm] = true;
        emit UserAddedToWhitelist(_sm, 4);
    }

    /**
     * @notice Removes a Swap Manager from the Whitelist
     * @param _sm is the Swap Manager address
     */
    function removeSwapManagerFromWhitelist(address _sm) external onlyLawyer {
        whitelistedSwapManagers[_sm] = false;
        emit userRemovedFromWhitelist(_sm, 4);
    }

    /**
     * @notice Checks if a Swap Manager is in the Whitelist
     * @param _sm is the Swap Manager address
     */
    function isSwapManagerWhitelisted(address _sm)
        external
        view
        returns (bool)
    {
        return whitelistedSwapManagers[_sm];
    }

    /**
     * @notice modify investigation duration
     * @param _time is the investigation duration
     */
    function setInvestigationPeriod(uint256 _time) external onlyLawyer {
        emit newInvestigationPeriod(investigation_period, _time);
        investigation_period = _time;
    }

    /**
     * @notice gets the investigation duration
     */
    function getInvestigationPeriod() external view returns (uint256) {
        return investigation_period;
    }

    /**
     * @notice adds a lawyer to the lawyer whitelist
     * @param _lawyer is the lawyer address
     */
    function addLawyer(address _lawyer) external onlyLawyer {
        lawyers[_lawyer] = true;
        emit UserAddedToWhitelist(_lawyer, 3);
    }

    /**
     * @notice removes a lawyer from the lawyer whitelist
     * @param _lawyer is the lawyer address
     */
    function removeLawyer(address _lawyer) external onlyLawyer {
        delete lawyers[_lawyer];
        emit userRemovedFromWhitelist(_lawyer, 3);
    }

    /**
     * @notice verifies that the lawyer is whitelisted
     * @param _lawyer is the lawyer address
     */
    function isLawyer(address _lawyer) external view returns (bool) {
        return lawyers[_lawyer];
    }

    /**
     * @notice Adds a User to the Whitelist
     * @param _user is the User address
     */
    function addUserToWhitelist(address _user) external onlyLawyer {
        whitelistedUsers[_user] = true;
        kycProviders[_user] = PROV_CODE_MANUAL;
        delete blacklistedUsers[_user];
        emit UserAddedToWhitelist(_user, 0);
    }

    /**
     * @notice Adds a User to the Whitelist specifying the provider
     * @param _user is the User address
     * @param _provider is the keccak256 hash of the provider name
     */
    function addUserToWhitelistWithProvider(address _user, bytes32 _provider)
        external
        onlyLawyer
    {
        whitelistedUsers[_user] = true;
        kycProviders[_user] = _provider;
        delete blacklistedUsers[_user];
        emit UserAddedToWhitelist(_user, 0);
    }

    /**
     * @notice Removes a User from the Whitelist
     * @param _user is the User address
     */
    function removeUserFromWhitelist(address _user) external onlyLawyer {
        delete whitelistedUsers[_user];
        delete kycProviders[_user];
        emit userRemovedFromWhitelist(_user, 0);
    }

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool) {
        if (kycProviders[_user] == PROV_CODE_VERITE) {
            return whitelistedUsers[_user] && KYCRegistry.isVerified(_user);
        }
        return whitelistedUsers[_user];
    }

    /**
     * @notice Blacklists user pending investigation
     * @param _user is the User address
     */
    function addUserToBlacklist(address _user) external onlyLawyer {
        blacklistedUsers[_user] = block.timestamp + investigation_period;
        delete whitelistedUsers[_user];
        delete kycProviders[_user];
        emit userAddedToBlacklist(_user, blacklistedUsers[_user]);
    }

    /**
     * @notice Blacklists user indefinitely after investigation
     * @param _user is the User address
     */
    function addUserToBlacklistIndefinitely(address _user) external onlyLawyer {
        blacklistedUsers[_user] = INF_TIME;
        delete whitelistedUsers[_user];
        delete kycProviders[_user];
        emit userAddedToBlacklist(_user, blacklistedUsers[_user]);
    }

    /**
     * @notice Removes user from Blacklist after investigation
     * @param _user is the User address
     */
    function removeUserFromBlacklist(address _user) external onlyLawyer {
        blacklistedUsers[_user] = 0;
        emit userRemovedFromBlacklist(_user);
    }

    /**
     * @notice Checks if user is blacklisted
     * @param _user is the User address
     */
    function isUserBlacklisted(address _user) public view returns (bool) {
        //slither-disable-next-line timestamp
        return block.timestamp < blacklistedUsers[_user];
    }

    /**
     * @notice Adds a Market Maker to the Whitelist
     * @param _mm is the Market Maker address
     */
    function addMMToWhitelist(address _mm) external onlyLawyer {
        whitelistedMMs[_mm] = true;
        emit UserAddedToWhitelist(_mm, 1);
    }

    /**
     * @notice Adds a Market Maker to the Whitelist
     * @param _mm is the Market Maker address
     */
    function addMMToWhitelistWithId(address _mm, bytes32 _id)
        external
        onlyLawyer
    {
        idMM[_mm] = _id;
        whitelistedMMs[_mm] = true;
        emit UserAddedToWhitelist(_mm, 1);
        emit mmAddedToWhitelist(_mm, _id);
    }

    /**
     * @notice Removes a Market Maker from the Whitelist
     * @param _mm is the Market Maker address
     */
    function removeMMFromWhitelist(address _mm) external onlyLawyer {
        delete whitelistedMMs[_mm];
        emit userRemovedFromWhitelist(_mm, 1);
    }

    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool) {
        return whitelistedMMs[_mm];
    }

    /**
     * @notice Adds a Vault to the Whitelist
     * @param _vault is the Vault address
     */
    function addVaultToWhitelist(address _vault) external onlyLawyer {
        whitelistedVaults[_vault] = true;
        emit UserAddedToWhitelist(_vault, 2);
    }

    /**
     * @notice Removes a Vault from the Whitelist
     * @param _vault is the Vault address
     */
    function removeVaultFromWhitelist(address _vault) external onlyLawyer {
        delete whitelistedVaults[_vault];
        emit userRemovedFromWhitelist(_vault, 2);
    }

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool) {
        return whitelistedVaults[_vault];
    }

    /**
     * @notice Adds an Asset to the Whitelist
     * @param _asset is the Asset address
     */
    function addAssetToWhitelist(address _asset) external onlyLawyer {
        whitelistedAssets[_asset] = true;
        emit AddedAssetToWhitelist(_asset);
    }

    /**
     * @notice Removes an Asset from the Whitelist
     * @param _asset is the Asset address
     */
    function removeAssetFromWhitelist(address _asset) external onlyLawyer {
        delete whitelistedAssets[_asset];
        emit RemovedAssetFromWhitelist(_asset);
    }

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool) {
        return whitelistedAssets[_asset];
    }

    /**
     * @notice Adds an id to a Market Maker address to identify a Market Maker by its address
     * @param _mm is the mm address
     * @param _id is the unique identifier of the market maker
     */
    function setIdMM(address _mm, bytes32 _id) external onlyLawyer {
        idMM[_mm] = _id;
        emit IdMMChanged(_mm, _id);
    }

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (bytes32) {
        return idMM[_mm];
    }

    /**
     * @notice Adds a Country to the Blacklist
     * @param _name is the 2 letter country code hashed with keccak256
     */
    function addCountryToBlacklist(bytes32 _name) external onlyLawyer {
        blacklistedCountries[_name] = true;
        emit CountryToBlacklistAdded(_name);
    }

    /**
     * @notice Removes a Country from the Blacklist
     * @param _name is the 2 letter country code hashed with keccak256
     */
    function removeCountryFromBlacklist(bytes32 _name) external onlyLawyer {
        delete blacklistedCountries[_name];
        emit RemovedCountryFromBlacklist(_name);
    }

    /**
     * @notice Checks if a Country is in the Blacklist
     * @param _name is the 2 letter country code hashed with keccak256
     */
    function isCountryBlacklisted(bytes32 _name) public view returns (bool) {
        return blacklistedCountries[_name];
    }

    /**
     * @notice Checks the kyc Provider a user signed up with
     * @param _user is the User address
     */
    function checkKYCProvider(address _user) external view returns (bytes32) {
        return kycProviders[_user];
    }

    /**
     * @notice Checks if a user has a kyc passport
     * @param _user is the Asset address
     */
    function hasPassport(address _user) public view returns (bool) {
        return KYCReader.balanceOf(_user, CODE_RISK) >= 1;
    }

    /**
     * @notice users adds themselves to whitelist using the passport
     * @param _user is the user address
     */
    function addUserToWhitelistUsingPassport(address _user, bytes calldata _signature)
        external
        payable
    {
        require(_policiesSigned(_user, _signature), "user has not signed terms & conditions");
        require(hasPassport(_user), "user has no KYC passport");
        require(!isUserBlacklisted(_user), "user is blacklisted");

        uint256 feeRisk = checkFeeRisk();
        uint256 feeCountry = checkFeeCountry();
        require(msg.value == feeRisk + feeCountry, "fee is not correct");

        uint256 risk = uint256(
            KYCReader.getAttributes{value: feeRisk}(_user, CODE_RISK)[0].value
        );
        require(risk < 5, "Could not be whitelisted: 1");

        bytes32 country = KYCReader
        .getAttributes{value: feeCountry}(_user, CODE_COUNTRY)[0].value;
        require(!isCountryBlacklisted(country), "Could not be whitelisted: 2");

        whitelistedUsers[_user] = true;
        kycProviders[_user] = PROV_CODE_QUADRATA;
        emit UserAddedToWhitelist(_user, 0);
    }

    /**
     * @notice users adds themselves to whitelist using the registry
     * @param _user is the user address
     */
    function addUserToWhitelistUsingRegistry(address _user, bytes calldata _signature)
        external
    {
        require(_policiesSigned(_user, _signature), "user has not signed terms & conditions");
        require(!isUserBlacklisted(_user), "user is blacklisted");
        require(KYCRegistry.isVerified(_user), "user not verified in registry");

        whitelistedUsers[_user] = true;
        kycProviders[_user] = PROV_CODE_VERITE;
        emit UserAddedToWhitelist(_user, 0);
    }

    function _policiesSigned(address _user, bytes calldata _signature) private view returns (bool) {
        bytes32 hashedPolicies = keccak256(
            "By accessing and continuing to access the protocol you are agreeing to be bound by the terms and conditions shown in detail at www.trufin.io/policies"
        );
        bytes32 prefixedHashedPolicies = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedPolicies)
        );
        return SignatureChecker.isValidSignatureNow(
            _user,
            prefixedHashedPolicies,
            _signature
        );
    }

    /**
     * @notice Sets the address of the kyc passport
     * @param _kyc is the kyc passport address
     */
    function setKYCPassport(address _kyc) external onlyLawyer {
        KYCPassport = IQuadPassport(_kyc);
        emit KYCPassportChanged(_kyc);
    }

    /**
     * @notice Sets the address of the kyc reader
     * @param _kyc is the kyc reader address
     */
    function setKYCReader(address _kyc) external onlyLawyer {
        KYCReader = IQuadReader(_kyc);
        emit KYCReaderChanged(_kyc);
    }

    /**
     * @notice Sets the address of the kyc registry
     * @param _kyc is the kyc registry address
     */
    function setKYCRegistry(address _kyc) external onlyLawyer {
        KYCRegistry = IVerificationRegistry(_kyc);
        emit KYCRegistryChanged(_kyc);
    }

    /**
     * @notice Returns the passport checking fee for Risk score
     */
    function checkFeeRisk() public view returns (uint256) {
        return KYCReader.queryFee(address(0), CODE_RISK);
    }

    /**
     * @notice Returns the passport checking fee for Country
     */
    function checkFeeCountry() public view returns (uint256) {
        return KYCReader.queryFee(address(0), CODE_COUNTRY);
    }

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     */
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