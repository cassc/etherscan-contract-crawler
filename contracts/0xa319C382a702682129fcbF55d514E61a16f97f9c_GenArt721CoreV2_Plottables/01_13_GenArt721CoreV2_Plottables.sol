pragma solidity ^0.5.0;

import "../../libs/CustomERC721Metadata.sol";
import "../../libs/SafeMath.sol";
import "../../libs/Strings.sol";

interface IRandomizer {
    function returnValue() external view returns (bytes32);
}

contract GenArt721CoreV2_Plottables is CustomERC721Metadata {
    using SafeMath for uint256;

    event Mint(
        address indexed _to,
        uint256 indexed _tokenId,
        uint256 indexed _projectId
    );

    IRandomizer public randomizerContract;

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
    }

    uint256 constant ONE_MILLION = 1_000_000;
    mapping(uint256 => Project) projects;

    //All financial functions are stripped from struct for visibility
    mapping(uint256 => address) public projectIdToArtistAddress;
    mapping(uint256 => string) public projectIdToCurrencySymbol;
    mapping(uint256 => address) public projectIdToCurrencyAddress;
    mapping(uint256 => uint256) public projectIdToPricePerTokenInWei;
    mapping(uint256 => address) public projectIdToAdditionalPayee;
    mapping(uint256 => uint256) public projectIdToAdditionalPayeePercentage;
    mapping(uint256 => uint256)
        public projectIdToSecondaryMarketRoyaltyPercentage;

    address public renderProviderAddress;
    uint256 public renderProviderPercentage = 10;

    mapping(uint256 => uint256) public tokenIdToProjectId;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    address public admin;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isMintWhitelisted;

    uint256 public nextProjectId = 0;

    modifier onlyValidTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "Token ID does not exist");
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

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _randomizerContract
    ) public CustomERC721Metadata(_tokenName, _tokenSymbol) {
        admin = msg.sender;
        isWhitelisted[msg.sender] = true;
        renderProviderAddress = msg.sender;
        randomizerContract = IRandomizer(_randomizerContract);
    }

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
            projects[_projectId].invocations.add(1) <=
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

    function _mintToken(address _to, uint256 _projectId)
        internal
        returns (uint256 _tokenId)
    {
        uint256 tokenIdToBe = (_projectId * ONE_MILLION) +
            projects[_projectId].invocations;

        projects[_projectId].invocations = projects[_projectId].invocations.add(
            1
        );

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

    function updateAdmin(address _adminAddress) public onlyAdmin {
        admin = _adminAddress;
    }

    function updateRenderProviderAddress(address _renderProviderAddress)
        public
        onlyAdmin
    {
        renderProviderAddress = _renderProviderAddress;
    }

    function updateRenderProviderPercentage(uint256 _renderProviderPercentage)
        public
        onlyAdmin
    {
        require(_renderProviderPercentage <= 25, "Max of 25%");
        renderProviderPercentage = _renderProviderPercentage;
    }

    function addWhitelisted(address _address) public onlyAdmin {
        isWhitelisted[_address] = true;
    }

    function removeWhitelisted(address _address) public onlyAdmin {
        isWhitelisted[_address] = false;
    }

    function addMintWhitelisted(address _address) public onlyAdmin {
        isMintWhitelisted[_address] = true;
    }

    function removeMintWhitelisted(address _address) public onlyAdmin {
        isMintWhitelisted[_address] = false;
    }

    function updateRandomizerAddress(address _randomizerAddress)
        public
        onlyWhitelisted
    {
        randomizerContract = IRandomizer(_randomizerAddress);
    }

    function toggleProjectIsLocked(uint256 _projectId)
        public
        onlyWhitelisted
        onlyUnlocked(_projectId)
    {
        projects[_projectId].locked = true;
    }

    function toggleProjectIsActive(uint256 _projectId) public onlyWhitelisted {
        projects[_projectId].active = !projects[_projectId].active;
    }

    function updateProjectArtistAddress(
        uint256 _projectId,
        address _artistAddress
    ) public onlyArtistOrWhitelisted(_projectId) {
        projectIdToArtistAddress[_projectId] = _artistAddress;
    }

    function toggleProjectIsPaused(uint256 _projectId)
        public
        onlyArtist(_projectId)
    {
        projects[_projectId].paused = !projects[_projectId].paused;
    }

    function addProject(
        string memory _projectName,
        address _artistAddress,
        uint256 _pricePerTokenInWei
    ) public onlyWhitelisted {
        uint256 projectId = nextProjectId;
        projectIdToArtistAddress[projectId] = _artistAddress;
        projects[projectId].name = _projectName;
        projectIdToCurrencySymbol[projectId] = "ETH";
        projectIdToPricePerTokenInWei[projectId] = _pricePerTokenInWei;
        projects[projectId].paused = true;
        projects[projectId].maxInvocations = ONE_MILLION;
        nextProjectId = nextProjectId.add(1);
    }

    function updateProjectCurrencyInfo(
        uint256 _projectId,
        string memory _currencySymbol,
        address _currencyAddress
    ) public onlyArtist(_projectId) {
        projectIdToCurrencySymbol[_projectId] = _currencySymbol;
        projectIdToCurrencyAddress[_projectId] = _currencyAddress;
    }

    function updateProjectPricePerTokenInWei(
        uint256 _projectId,
        uint256 _pricePerTokenInWei
    ) public onlyArtist(_projectId) {
        projectIdToPricePerTokenInWei[_projectId] = _pricePerTokenInWei;
    }

    function updateProjectName(uint256 _projectId, string memory _projectName)
        public
        onlyUnlocked(_projectId)
        onlyArtistOrWhitelisted(_projectId)
    {
        projects[_projectId].name = _projectName;
    }

    function updateProjectArtistName(
        uint256 _projectId,
        string memory _projectArtistName
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        projects[_projectId].artist = _projectArtistName;
    }

    function updateProjectAdditionalPayeeInfo(
        uint256 _projectId,
        address _additionalPayee,
        uint256 _additionalPayeePercentage
    ) public onlyArtist(_projectId) {
        require(_additionalPayeePercentage <= 100, "Max of 100%");
        projectIdToAdditionalPayee[_projectId] = _additionalPayee;
        projectIdToAdditionalPayeePercentage[
            _projectId
        ] = _additionalPayeePercentage;
    }

    function updateProjectSecondaryMarketRoyaltyPercentage(
        uint256 _projectId,
        uint256 _secondMarketRoyalty
    ) public onlyArtist(_projectId) {
        require(_secondMarketRoyalty <= 100, "Max of 100%");
        projectIdToSecondaryMarketRoyaltyPercentage[
            _projectId
        ] = _secondMarketRoyalty;
    }

    function updateProjectDescription(
        uint256 _projectId,
        string memory _projectDescription
    ) public onlyArtist(_projectId) {
        projects[_projectId].description = _projectDescription;
    }

    function updateProjectWebsite(
        uint256 _projectId,
        string memory _projectWebsite
    ) public onlyArtist(_projectId) {
        projects[_projectId].website = _projectWebsite;
    }

    function updateProjectLicense(
        uint256 _projectId,
        string memory _projectLicense
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        projects[_projectId].license = _projectLicense;
    }

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

    function addProjectScript(uint256 _projectId, string memory _script)
        public
        onlyUnlocked(_projectId)
        onlyArtistOrWhitelisted(_projectId)
    {
        projects[_projectId].scripts[
            projects[_projectId].scriptCount
        ] = _script;
        projects[_projectId].scriptCount = projects[_projectId].scriptCount.add(
            1
        );
    }

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

    function removeProjectLastScript(uint256 _projectId)
        public
        onlyUnlocked(_projectId)
        onlyArtistOrWhitelisted(_projectId)
    {
        require(
            projects[_projectId].scriptCount > 0,
            "there are no scripts to remove"
        );
        delete projects[_projectId].scripts[
            projects[_projectId].scriptCount - 1
        ];
        projects[_projectId].scriptCount = projects[_projectId].scriptCount.sub(
            1
        );
    }

    function updateProjectScriptJSON(
        uint256 _projectId,
        string memory _projectScriptJSON
    ) public onlyUnlocked(_projectId) onlyArtistOrWhitelisted(_projectId) {
        projects[_projectId].scriptJSON = _projectScriptJSON;
    }

    function updateProjectIpfsHash(uint256 _projectId, string memory _ipfsHash)
        public
        onlyUnlocked(_projectId)
        onlyArtistOrWhitelisted(_projectId)
    {
        projects[_projectId].ipfsHash = _ipfsHash;
    }

    function updateProjectBaseURI(uint256 _projectId, string memory _newBaseURI)
        public
        onlyArtist(_projectId)
    {
        projects[_projectId].projectBaseURI = _newBaseURI;
    }

    function projectDetails(uint256 _projectId)
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

    function projectTokenInfo(uint256 _projectId)
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

    function projectScriptInfo(uint256 _projectId)
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

    function projectScriptByIndex(uint256 _projectId, uint256 _index)
        public
        view
        returns (string memory)
    {
        return projects[_projectId].scripts[_index];
    }

    function projectURIInfo(uint256 _projectId)
        public
        view
        returns (string memory projectBaseURI)
    {
        projectBaseURI = projects[_projectId].projectBaseURI;
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return _tokensOfOwner(owner);
    }

    function getRoyaltyData(uint256 _tokenId)
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

    function tokenURI(uint256 _tokenId)
        external
        view
        onlyValidTokenId(_tokenId)
        returns (string memory)
    {
        return
            Strings.strConcat(
                projects[tokenIdToProjectId[_tokenId]].projectBaseURI,
                Strings.uint2str(_tokenId)
            );
    }
}