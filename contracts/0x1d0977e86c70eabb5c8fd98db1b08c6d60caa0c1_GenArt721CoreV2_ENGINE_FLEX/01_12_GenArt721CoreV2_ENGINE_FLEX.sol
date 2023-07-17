// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

import "../interfaces/0.8.x/IRandomizer.sol";
import "../interfaces/0.8.x/IGenArt721CoreV2_PBAB.sol";
import "@openzeppelin-4.5/contracts/utils/Strings.sol";
import "@openzeppelin-4.5/contracts/token/ERC721/ERC721.sol";

pragma solidity 0.8.9;

/**
 * @title Art Blocks Engine ERC-721 core contract with FLEX integration.
 * Allows for projects to specify external asset dependencies from either IPFS or ARWEAVE.
 * @author Art Blocks Inc.
 */
contract GenArt721CoreV2_ENGINE_FLEX is ERC721, IGenArt721CoreV2_PBAB {
    /// randomizer contract
    IRandomizer public randomizerContract;

    /// version & type of this core contract
    string public constant coreVersion = "v2.0.0";
    string public constant coreType = "GenArt721CoreV2_ENGINE_FLEX";

    struct Project {
        string name;
        string artist;
        string description;
        string website;
        string license;
        string projectBaseURI;
        uint256 invocations;
        uint256 maxInvocations;
        string scriptJSON;
        mapping(uint256 => string) scripts;
        uint256 scriptCount;
        string ipfsHash;
        bool active;
        bool locked;
        bool paused;
        bool externalAssetDependenciesLocked;
        uint24 externalAssetDependencyCount;
        mapping(uint256 => ExternalAssetDependency) externalAssetDependencies;
    }

    event ExternalAssetDependencyUpdated(
        uint256 indexed _projectId,
        uint256 indexed _index,
        string _cid,
        ExternalAssetDependencyType _dependencyType,
        uint24 _externalAssetDependencyCount
    );

    event ExternalAssetDependencyRemoved(
        uint256 indexed _projectId,
        uint256 indexed _index
    );

    event GatewayUpdated(
        ExternalAssetDependencyType indexed _dependencyType,
        string _gatewayAddress
    );

    event ProjectExternalAssetDependenciesLocked(uint256 indexed _projectId);

    enum ExternalAssetDependencyType {
        IPFS,
        ARWEAVE
    }
    struct ExternalAssetDependency {
        string cid;
        ExternalAssetDependencyType dependencyType;
    }

    string public preferredIPFSGateway;
    string public preferredArweaveGateway;

    uint256 constant ONE_MILLION = 1_000_000;
    mapping(uint256 => Project) projects;

    //All financial functions are stripped from struct for visibility
    mapping(uint256 => address payable) public projectIdToArtistAddress;
    mapping(uint256 => string) public projectIdToCurrencySymbol;
    mapping(uint256 => address) public projectIdToCurrencyAddress;
    mapping(uint256 => uint256) public projectIdToPricePerTokenInWei;
    mapping(uint256 => address payable) public projectIdToAdditionalPayee;
    mapping(uint256 => uint256) public projectIdToAdditionalPayeePercentage;
    mapping(uint256 => uint256)
        public projectIdToSecondaryMarketRoyaltyPercentage;

    address payable public renderProviderAddress;
    /// Percentage of mint revenue allocated to render provider
    uint256 public renderProviderPercentage = 10;

    mapping(uint256 => uint256) public tokenIdToProjectId;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    /// admin for contract
    address public admin;
    /// true if address is whitelisted
    mapping(address => bool) public isWhitelisted;
    /// true if minter is whitelisted
    mapping(address => bool) public isMintWhitelisted;

    /// next project ID to be created
    uint256 public nextProjectId = 0;

    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID does not exist");
        _;
    }

    modifier onlyUnlockedProjectExternalAssetDependencies(uint256 _projectId) {
        require(
            !projects[_projectId].externalAssetDependenciesLocked,
            "Project external asset dependencies are locked"
        );
        _;
    }

    modifier onlyUnlocked(uint256 _projectId) {
        require(!projects[_projectId].locked, "Only if unlocked");
        _;
    }

    modifier onlyArtist(uint256 _projectId) {
        require(
            msg.sender == projectIdToArtistAddress[_projectId],
            "Only artist"
        );
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted[msg.sender], "Only whitelisted");
        _;
    }

    modifier onlyArtistOrWhitelisted(uint256 _projectId) {
        require(
            isWhitelisted[msg.sender] ||
                msg.sender == projectIdToArtistAddress[_projectId],
            "Only artist or whitelisted"
        );
        _;
    }

    /**
     * @notice Initializes contract.
     * @param _tokenName Name of token.
     * @param _tokenSymbol Token symbol.
     * @param _randomizerContract Randomizer contract.
     */
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _randomizerContract
    ) ERC721(_tokenName, _tokenSymbol) {
        admin = msg.sender;
        isWhitelisted[msg.sender] = true;
        renderProviderAddress = payable(msg.sender);
        randomizerContract = IRandomizer(_randomizerContract);
    }

    /**
     * @notice Mints a token from project `_projectId` and sets the
     * token's owner to `_to`.
     * @param _to Address to be the minted token's owner.
     * @param _projectId Project ID to mint a token on.
     * @param _by Purchaser of minted token.
     * @dev sender must be a whitelisted minter
     */
    function mint(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 _tokenId) {
        require(
            isMintWhitelisted[msg.sender],
            "Must mint from whitelisted minter contract."
        );
        require(
            projects[_projectId].invocations + 1 <=
                projects[_projectId].maxInvocations,
            "Must not exceed max invocations"
        );
        require(
            projects[_projectId].active ||
                _by == projectIdToArtistAddress[_projectId],
            "Project must exist and be active"
        );
        require(
            !projects[_projectId].paused ||
                _by == projectIdToArtistAddress[_projectId],
            "Purchases are paused."
        );

        uint256 tokenId = _mintToken(_to, _projectId);

        return tokenId;
    }

    function _mintToken(
        address _to,
        uint256 _projectId
    ) internal returns (uint256 _tokenId) {
        uint256 tokenIdToBe = (_projectId * ONE_MILLION) +
            projects[_projectId].invocations;

        projects[_projectId].invocations = projects[_projectId].invocations + 1;

        bytes32 hash = keccak256(
            abi.encodePacked(
                projects[_projectId].invocations,
                block.number,
                blockhash(block.number - 1),
                randomizerContract.returnValue()
            )
        );
        tokenIdToHash[tokenIdToBe] = hash;
        hashToTokenId[hash] = tokenIdToBe;

        _mint(_to, tokenIdToBe);

        tokenIdToProjectId[tokenIdToBe] = _projectId;

        emit Mint(_to, tokenIdToBe, _projectId);

        return tokenIdToBe;
    }

    /**
     * @notice Updates preferredIPFSGateway to `_gateway`.
     */
    function updateIPFSGateway(
        string calldata _gateway
    ) public onlyWhitelisted {
        preferredIPFSGateway = _gateway;
        emit GatewayUpdated(ExternalAssetDependencyType.IPFS, _gateway);
    }

    /**
     * @notice Updates preferredArweaveGateway to `_gateway`.
     */
    function updateArweaveGateway(
        string calldata _gateway
    ) public onlyWhitelisted {
        preferredArweaveGateway = _gateway;
        emit GatewayUpdated(ExternalAssetDependencyType.ARWEAVE, _gateway);
    }

    /**
     * @notice Updates contract admin to `_adminAddress`.
     */
    function updateAdmin(address _adminAddress) public onlyAdmin {
        admin = _adminAddress;
    }

    /**
     * @notice Updates render provider address to `_renderProviderAddress`.
     */
    function updateRenderProviderAddress(
        address payable _renderProviderAddress
    ) public onlyAdmin {
        renderProviderAddress = _renderProviderAddress;
    }

    /**
     * @notice Updates render provider mint revenue percentage to
     * `_renderProviderPercentage`.
     */
    function updateRenderProviderPercentage(
        uint256 _renderProviderPercentage
    ) public onlyAdmin {
        require(_renderProviderPercentage <= 25, "Max of 25%");
        renderProviderPercentage = _renderProviderPercentage;
    }

    /**
     * @notice Whitelists `_address`.
     */
    function addWhitelisted(address _address) public onlyAdmin {
        isWhitelisted[_address] = true;
    }

    /**
     * @notice Revokes whitelisting of `_address`.
     */
    function removeWhitelisted(address _address) public onlyAdmin {
        isWhitelisted[_address] = false;
    }

    /**
     * @notice Whitelists minter `_address`.
     */
    function addMintWhitelisted(address _address) public onlyAdmin {
        isMintWhitelisted[_address] = true;
    }

    /**
     * @notice Revokes whitelisting of minter `_address`.
     */
    function removeMintWhitelisted(address _address) public onlyAdmin {
        isMintWhitelisted[_address] = false;
    }

    /**
     * @notice Updates randomizer to `_randomizerAddress`.
     */
    function updateRandomizerAddress(
        address _randomizerAddress
    ) public onlyWhitelisted {
        randomizerContract = IRandomizer(_randomizerAddress);
    }

    /**
     * @notice Locks project `_projectId`.
     */
    function toggleProjectIsLocked(
        uint256 _projectId
    ) public onlyWhitelisted onlyUnlocked(_projectId) {
        projects[_projectId].locked = true;
    }

    /**
     * @notice Locks external asset dependencies for project `_projectId`.
     */
    function lockProjectExternalAssetDependencies(
        uint256 _projectId
    )
        external
        onlyArtistOrWhitelisted(_projectId)
        onlyUnlockedProjectExternalAssetDependencies(_projectId)
    {
        projects[_projectId].externalAssetDependenciesLocked = true;
        emit ProjectExternalAssetDependenciesLocked(_projectId);
    }

    /**
     * @notice Toggles project `_projectId` as active/inactive.
     */
    function toggleProjectIsActive(uint256 _projectId) public onlyWhitelisted {
        projects[_projectId].active = !projects[_projectId].active;
    }

    /**
     * @notice Updates artist of project `_projectId` to `_artistAddress`.
     */
    function updateProjectArtistAddress(
        uint256 _projectId,
        address payable _artistAddress
    ) public onlyArtistOrWhitelisted(_projectId) {
        projectIdToArtistAddress[_projectId] = _artistAddress;
    }

    /**
     * @notice Toggles paused state of project `_projectId`.
     */
    function toggleProjectIsPaused(
        uint256 _projectId
    ) public onlyArtist(_projectId) {
        projects[_projectId].paused = !projects[_projectId].paused;
    }

    /**
     * @notice Adds new project `_projectName` by `_artistAddress`.
     * @param _projectName Project name.
     * @param _artistAddress Artist's address.
     * @param _pricePerTokenInWei Price to mint a token, in Wei.
     */
    function addProject(
        string memory _projectName,
        address payable _artistAddress,
        uint256 _pricePerTokenInWei
    ) public onlyWhitelisted {
        uint256 projectId = nextProjectId;
        projectIdToArtistAddress[projectId] = _artistAddress;
        projects[projectId].name = _projectName;
        projectIdToCurrencySymbol[projectId] = "ETH";
        projectIdToPricePerTokenInWei[projectId] = _pricePerTokenInWei;
        projects[projectId].paused = true;
        projects[projectId].maxInvocations = ONE_MILLION;
        nextProjectId = nextProjectId + 1;
    }

    /**
     * @notice Updates payment currency of project `_projectId` to be
     * `_currencySymbol`.
     * @param _projectId Project ID to update.
     * @param _currencySymbol Currency symbol.
     * @param _currencyAddress Currency address.
     */
    function updateProjectCurrencyInfo(
        uint256 _projectId,
        string memory _currencySymbol,
        address _currencyAddress
    ) public onlyArtist(_projectId) {
        projectIdToCurrencySymbol[_projectId] = _currencySymbol;
        projectIdToCurrencyAddress[_projectId] = _currencyAddress;
    }

    /**
     * @notice Updates price per token of project `_projectId` to be
     * '_pricePerTokenInWei`, in Wei.
     */
    function updateProjectPricePerTokenInWei(
        uint256 _projectId,
        uint256 _pricePerTokenInWei
    ) public onlyArtist(_projectId) {
        projectIdToPricePerTokenInWei[_projectId] = _pricePerTokenInWei;
    }

    /**
     * @notice Updates name of project `_projectId` to be `_projectName`.
     */
    function updateProjectName(
        uint256 _projectId,
        string memory _projectName
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        projects[_projectId].name = _projectName;
    }

    /**
     * @notice Updates artist name for project `_projectId` to be
     * `_projectArtistName`.
     */
    function updateProjectArtistName(
        uint256 _projectId,
        string memory _projectArtistName
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        projects[_projectId].artist = _projectArtistName;
    }

    /**
     * @notice Updates additional payee for project `_projectId` to be
     * `_additionalPayee`, receiving `_additionalPayeePercentage` percent
     * of artist mint and royalty revenues.
     */
    function updateProjectAdditionalPayeeInfo(
        uint256 _projectId,
        address payable _additionalPayee,
        uint256 _additionalPayeePercentage
    ) public onlyArtist(_projectId) {
        require(_additionalPayeePercentage <= 100, "Max of 100%");
        projectIdToAdditionalPayee[_projectId] = _additionalPayee;
        projectIdToAdditionalPayeePercentage[
            _projectId
        ] = _additionalPayeePercentage;
    }

    /**
     * @notice Updates artist secondary market royalties for project
     * `_projectId` to be `_secondMarketRoyalty` percent.
     */
    function updateProjectSecondaryMarketRoyaltyPercentage(
        uint256 _projectId,
        uint256 _secondMarketRoyalty
    ) public onlyArtist(_projectId) {
        require(_secondMarketRoyalty <= 100, "Max of 100%");
        projectIdToSecondaryMarketRoyaltyPercentage[
            _projectId
        ] = _secondMarketRoyalty;
    }

    /**
     * @notice Updates description of project `_projectId`.
     */
    function updateProjectDescription(
        uint256 _projectId,
        string memory _projectDescription
    ) public onlyArtist(_projectId) {
        projects[_projectId].description = _projectDescription;
    }

    /**
     * @notice Updates website of project `_projectId` to be `_projectWebsite`.
     */
    function updateProjectWebsite(
        uint256 _projectId,
        string memory _projectWebsite
    ) public onlyArtist(_projectId) {
        projects[_projectId].website = _projectWebsite;
    }

    /**
     * @notice Updates license for project `_projectId`.
     */
    function updateProjectLicense(
        uint256 _projectId,
        string memory _projectLicense
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        projects[_projectId].license = _projectLicense;
    }

    /**
     * @notice Updates maximum invocations for project `_projectId` to
     * `_maxInvocations`.
     */
    function updateProjectMaxInvocations(
        uint256 _projectId,
        uint256 _maxInvocations
    ) public onlyArtist(_projectId) {
        require(
            (!projects[_projectId].locked ||
                _maxInvocations < projects[_projectId].maxInvocations),
            "Only if unlocked"
        );
        require(
            _maxInvocations > projects[_projectId].invocations,
            "You must set max invocations greater than current invocations"
        );
        require(_maxInvocations <= ONE_MILLION, "Cannot exceed 1000000");
        projects[_projectId].maxInvocations = _maxInvocations;
    }

    /**
     * @notice Adds a script to project `_projectId`.
     * @param _projectId Project to be updated.
     * @param _script Script to be added.
     */
    function addProjectScript(
        uint256 _projectId,
        string memory _script
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        projects[_projectId].scripts[
            projects[_projectId].scriptCount
        ] = _script;
        projects[_projectId].scriptCount = projects[_projectId].scriptCount + 1;
    }

    /**
     * @notice Updates script for project `_projectId` at script ID `_scriptId`.
     * @param _projectId Project to be updated.
     * @param _scriptId Script ID to be updated.
     * @param _script Script to be added.
     */
    function updateProjectScript(
        uint256 _projectId,
        uint256 _scriptId,
        string memory _script
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        require(
            _scriptId < projects[_projectId].scriptCount,
            "scriptId out of range"
        );
        projects[_projectId].scripts[_scriptId] = _script;
    }

    /**
     * @notice Updates external asset dependency for project `_projectId`.
     * @param _projectId Project to be updated.
     * @param _index Asset index.
     * @param _cid Asset cid (Content identifier).
     * @param _dependencyType Asset dependency type.
     *  0 - IPFS
     *  1 - ARWEAVE
     */
    function updateProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index,
        string calldata _cid,
        ExternalAssetDependencyType _dependencyType
    )
        external
        onlyUnlockedProjectExternalAssetDependencies(_projectId)
        onlyArtistOrWhitelisted(_projectId)
    {
        uint24 assetCount = projects[_projectId].externalAssetDependencyCount;
        require(_index < assetCount, "Asset index out of range");
        projects[_projectId].externalAssetDependencies[_index].cid = _cid;
        projects[_projectId]
            .externalAssetDependencies[_index]
            .dependencyType = _dependencyType;
        emit ExternalAssetDependencyUpdated(
            _projectId,
            _index,
            _cid,
            _dependencyType,
            assetCount
        );
    }

    /**
     * @notice Removes external asset dependency for project `_projectId` at index `_index`.
     * Removal is done by swapping the element to be removed with the last element in the array, then deleting this last element.
     * Assets with indices higher than `_index` can have their indices adjusted as a result of this operation.
     * @param _projectId Project to be updated.
     * @param _index Asset index
     */
    function removeProjectExternalAssetDependency(
        uint256 _projectId,
        uint256 _index
    )
        external
        onlyUnlockedProjectExternalAssetDependencies(_projectId)
        onlyArtistOrWhitelisted(_projectId)
    {
        uint24 assetCount = projects[_projectId].externalAssetDependencyCount;
        require(_index < assetCount, "Asset index out of range");

        uint24 lastElementIndex = assetCount - 1;

        projects[_projectId].externalAssetDependencies[_index] = projects[
            _projectId
        ].externalAssetDependencies[lastElementIndex];
        delete projects[_projectId].externalAssetDependencies[lastElementIndex];

        projects[_projectId].externalAssetDependencyCount = lastElementIndex;

        emit ExternalAssetDependencyRemoved(_projectId, _index);
    }

    /**
     * @notice Adds external asset dependency for project `_projectId`.
     * @param _projectId Project to be updated.
     * @param _cid Asset cid (Content identifier).
     * @param _dependencyType Asset dependency type.
     *  0 - IPFS
     *  1 - ARWEAVE
     */
    function addProjectExternalAssetDependency(
        uint256 _projectId,
        string calldata _cid,
        ExternalAssetDependencyType _dependencyType
    )
        external
        onlyUnlockedProjectExternalAssetDependencies(_projectId)
        onlyArtistOrWhitelisted(_projectId)
    {
        uint24 assetCount = projects[_projectId].externalAssetDependencyCount;
        ExternalAssetDependency memory asset = ExternalAssetDependency({
            cid: _cid,
            dependencyType: _dependencyType
        });
        projects[_projectId].externalAssetDependencies[assetCount] = asset;
        projects[_projectId].externalAssetDependencyCount = assetCount + 1;

        emit ExternalAssetDependencyUpdated(
            _projectId,
            assetCount,
            _cid,
            _dependencyType,
            assetCount + 1
        );
    }

    /**
     * @notice Removes last script from project `_projectId`.
     */
    function removeProjectLastScript(
        uint256 _projectId
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        require(
            projects[_projectId].scriptCount > 0,
            "there are no scripts to remove"
        );
        delete projects[_projectId].scripts[
            projects[_projectId].scriptCount - 1
        ];
        projects[_projectId].scriptCount = projects[_projectId].scriptCount - 1;
    }

    /**
     * @notice Updates script json for project `_projectId`.
     */
    function updateProjectScriptJSON(
        uint256 _projectId,
        string memory _projectScriptJSON
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        projects[_projectId].scriptJSON = _projectScriptJSON;
    }

    /**
     * @notice Updates ipfs hash for project `_projectId`.
     */
    function updateProjectIpfsHash(
        uint256 _projectId,
        string memory _ipfsHash
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        projects[_projectId].ipfsHash = _ipfsHash;
    }

    /**
     * @notice Updates base URI for project `_projectId` to `_newBaseURI`.
     */
    function updateProjectBaseURI(
        uint256 _projectId,
        string memory _newBaseURI
    ) public onlyArtist(_projectId) {
        projects[_projectId].projectBaseURI = _newBaseURI;
    }

    /**
     * @notice Returns project details for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return projectName Name of project
     * @return artist Artist of project
     * @return description Project description
     * @return website Project website
     * @return license Project license
     */
    function projectDetails(
        uint256 _projectId
    )
        public
        view
        returns (
            string memory projectName,
            string memory artist,
            string memory description,
            string memory website,
            string memory license
        )
    {
        projectName = projects[_projectId].name;
        artist = projects[_projectId].artist;
        description = projects[_projectId].description;
        website = projects[_projectId].website;
        license = projects[_projectId].license;
    }

    /**
     * @notice Returns project token information for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return artistAddress Project Artist's address
     * @return pricePerTokenInWei Price to mint a token, in Wei
     * @return invocations Current number of invocations
     * @return maxInvocations Maximum allowed invocations
     * @return active Boolean representing if project is currently active
     * @return additionalPayee Additional payee address
     * @return additionalPayeePercentage Percentage of artist revenue
     * to be sent to the additional payee's address
     * @return currency Symbol of project's currency
     * @return currencyAddress Address of project's currency
     */
    function projectTokenInfo(
        uint256 _projectId
    )
        public
        view
        returns (
            address artistAddress,
            uint256 pricePerTokenInWei,
            uint256 invocations,
            uint256 maxInvocations,
            bool active,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            string memory currency,
            address currencyAddress
        )
    {
        artistAddress = projectIdToArtistAddress[_projectId];
        pricePerTokenInWei = projectIdToPricePerTokenInWei[_projectId];
        invocations = projects[_projectId].invocations;
        maxInvocations = projects[_projectId].maxInvocations;
        active = projects[_projectId].active;
        additionalPayee = projectIdToAdditionalPayee[_projectId];
        additionalPayeePercentage = projectIdToAdditionalPayeePercentage[
            _projectId
        ];
        currency = projectIdToCurrencySymbol[_projectId];
        currencyAddress = projectIdToCurrencyAddress[_projectId];
    }

    /**
     * @notice Returns script information for project `_projectId`.
     * @param _projectId Project to be queried.
     * @return scriptJSON Project's script json
     * @return scriptCount Count of scripts for project
     * @return ipfsHash IPFS hash for project
     * @return locked Boolean representing if project is locked
     * @return paused Boolean representing if project is paused
     */
    function projectScriptInfo(
        uint256 _projectId
    )
        public
        view
        returns (
            string memory scriptJSON,
            uint256 scriptCount,
            string memory ipfsHash,
            bool locked,
            bool paused
        )
    {
        scriptJSON = projects[_projectId].scriptJSON;
        scriptCount = projects[_projectId].scriptCount;
        ipfsHash = projects[_projectId].ipfsHash;
        locked = projects[_projectId].locked;
        paused = projects[_projectId].paused;
    }

    /**
     * @notice Returns script for project `_projectId` at script index `_index`

     */
    function projectScriptByIndex(
        uint256 _projectId,
        uint256 _index
    ) public view returns (string memory) {
        return projects[_projectId].scripts[_index];
    }

    /**
     * @notice Returns external asset dependency for project `_projectId` at index `_index`.
     */
    function projectExternalAssetDependencyByIndex(
        uint256 _projectId,
        uint256 _index
    ) public view returns (ExternalAssetDependency memory) {
        return projects[_projectId].externalAssetDependencies[_index];
    }

    /**
     * @notice Returns external asset dependency count for project `_projectId` at index `_index`.
     */
    function projectExternalAssetDependencyCount(
        uint256 _projectId
    ) public view returns (uint256) {
        return uint256(projects[_projectId].externalAssetDependencyCount);
    }

    /**
     * @notice Returns base URI for project `_projectId`.
     */
    function projectURIInfo(
        uint256 _projectId
    ) public view returns (string memory projectBaseURI) {
        projectBaseURI = projects[_projectId].projectBaseURI;
    }

    /**
     * @notice Gets royalty data for token ID `_tokenId`.
     * @param _tokenId Token ID to be queried.
     * @return artistAddress Artist's payment address
     * @return additionalPayee Additional payee's payment address
     * @return additionalPayeePercentage Percentage of artist revenue
     * to be sent to the additional payee's address
     * @return royaltyFeeByID Total royalty percentage to be sent to
     * combination of artist and additional payee
     */
    function getRoyaltyData(
        uint256 _tokenId
    )
        public
        view
        returns (
            address artistAddress,
            address additionalPayee,
            uint256 additionalPayeePercentage,
            uint256 royaltyFeeByID
        )
    {
        artistAddress = projectIdToArtistAddress[tokenIdToProjectId[_tokenId]];
        additionalPayee = projectIdToAdditionalPayee[
            tokenIdToProjectId[_tokenId]
        ];
        additionalPayeePercentage = projectIdToAdditionalPayeePercentage[
            tokenIdToProjectId[_tokenId]
        ];
        royaltyFeeByID = projectIdToSecondaryMarketRoyaltyPercentage[
            tokenIdToProjectId[_tokenId]
        ];
    }

    /**
     * @notice Gets token URI for token ID `_tokenId`.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view override onlyValidTokenId(_tokenId) returns (string memory) {
        return
            string(
                abi.encodePacked(
                    projects[tokenIdToProjectId[_tokenId]].projectBaseURI,
                    Strings.toString(_tokenId)
                )
            );
    }
}