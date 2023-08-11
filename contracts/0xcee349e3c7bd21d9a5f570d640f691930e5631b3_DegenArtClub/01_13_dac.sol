// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Parent {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
    function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract DegenArtClub is ReentrancyGuard, ERC721, Ownable {
    using Strings for uint256;

    Parent private parent;

    struct Project {
        string name;
        string description;
        uint256 pricePerTokenInWei;
        uint256 invocations;
        uint256 maxInvocations;
        mapping(uint256 => string) scripts;
        uint256 scriptCount;
        bool isSaleActive;
        bool isClaimActive;
        string communityHash;
        string traitScript;
        string provenance;
        bytes32 merkleRoot;
        bool isAllowListActive;
        string projectBaseURI;
        mapping(address => uint) _allowListNumMinted;
    }

    mapping(uint256 => string) libraryScripts;
    uint256 public libraryScriptCount;

    mapping(uint256 => bytes32[]) internal tokenSeeds;

    string private _baseURIextended;
    uint256 constant ONE_MILLION = 1_000_000;
    mapping(uint256 => Project) projects;
    mapping(uint256 => uint256) public tokenIdToProjectId;
    uint256 public nextProjectId = 1;
    uint public constant MAX_PUBLIC_MINT = 3;
    uint public constant MAX_ALLOWLIST_MINT = 1;
    uint256 public immutable PARENT_SUPPLY;

    constructor(address parentAddress, uint _parentSupply) ERC721('DegenArtClub', 'DAC') {
        parent = Parent(parentAddress);
        PARENT_SUPPLY = _parentSupply;
    }

    function _claim(uint256 _projectId, uint256 startingIndex, uint256 numberOfTokens) internal {
        require(projects[_projectId].isClaimActive, 'Claim must be active to mint tokens');
        require(numberOfTokens > 0, "Must claim at least one token.");
        uint balance = parent.balanceOf(msg.sender);
        require(balance >= numberOfTokens, "Insufficient parent tokens.");
        require(balance >= startingIndex + numberOfTokens, "Insufficient parent tokens.");

        for (uint i = 0; i < balance && i < numberOfTokens; i++) {
            uint parentTokenId = parent.tokenOfOwnerByIndex(msg.sender, i + startingIndex);
            uint256 tokenId = (_projectId * ONE_MILLION) + parentTokenId;
            if (!_exists(tokenId)) {
                _mintToken(msg.sender, tokenId, _projectId);
                tokenIdToProjectId[tokenId] = _projectId;
            }
        }
    }

    function claim(uint256 _projectId, uint256 startingIndex, uint256 numberOfTokens) external nonReentrant callerIsUser{
        _claim(_projectId, startingIndex, numberOfTokens);
    }

    function claimAll(uint256 _projectId) external nonReentrant callerIsUser{
        _claim(_projectId, 0, parent.balanceOf(msg.sender));
    }

    function claimByTokenIds(uint256 _projectId, uint256[] calldata _parentTokenIds) external nonReentrant callerIsUser{
        require(projects[_projectId].isClaimActive, 'Claim must be active to mint tokens');
        require(_parentTokenIds.length > 0, "Must claim at least one token.");
        for (uint i = 0; i < _parentTokenIds.length; i++) {
            require(parent.ownerOf(_parentTokenIds[i]) == msg.sender, "Must own all parent tokens.");
            if (!_exists(_parentTokenIds[i])) {
                uint256 tokenId = (_projectId * ONE_MILLION) + _parentTokenIds[i];
                _mintToken(msg.sender, tokenId, _projectId);
                tokenIdToProjectId[tokenId] = _projectId;
            }
        }
    }

    function mintAllowList(uint256 _projectId, uint numberOfTokens, bytes32[] memory merkleProof) external payable nonReentrant callerIsUser{
        require(projects[_projectId].isAllowListActive, "Allow list is not active");
        require(onProjectAllowList(_projectId, msg.sender, merkleProof), "Not on allow list");
        require(numberOfTokens <= MAX_ALLOWLIST_MINT - projects[_projectId]._allowListNumMinted[msg.sender], "Exceeded max available to purchase");
        require(projects[_projectId].invocations + numberOfTokens <= projects[_projectId].maxInvocations, "Purchase would exceed max tokens");
        require(projects[_projectId].pricePerTokenInWei * numberOfTokens <= msg.value, "Ether value sent is not correct");

        projects[_projectId]._allowListNumMinted[msg.sender] += numberOfTokens;
        for (uint i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = (_projectId * ONE_MILLION) + projects[_projectId].invocations;
            projects[_projectId].invocations = projects[_projectId].invocations + 1;
            _mintToken(msg.sender, tokenId, _projectId);
            tokenIdToProjectId[tokenId] = _projectId;
        }
    }

    function mint(uint256 _projectId, uint256 numberOfTokens) external payable nonReentrant callerIsUser{
        require(projects[_projectId].isSaleActive, 'Sale must be active to mint tokens');
        require(numberOfTokens <= MAX_PUBLIC_MINT, 'Exceeded max token purchase');
        require(
            projects[_projectId].invocations + numberOfTokens <= projects[_projectId].maxInvocations,
            'Purchase would exceed max tokens'
        );
        require(
            projects[_projectId].pricePerTokenInWei * numberOfTokens <= msg.value,
            'Ether value sent is not correct'
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = (_projectId * ONE_MILLION) + projects[_projectId].invocations;
            projects[_projectId].invocations = projects[_projectId].invocations + 1;
            _mintToken(msg.sender, tokenId, _projectId);
            tokenIdToProjectId[tokenId] = _projectId;
        }
    }

    function _mintToken(address _to, uint256 _tokenId, uint256 _projectId) internal {
        bytes32 seed = keccak256(abi.encodePacked(_tokenId, projects[_projectId].provenance, projects[_projectId].communityHash));
        tokenSeeds[_tokenId].push(seed);
        _safeMint(_to, _tokenId);
    }

    function addProject(
        uint256 _pricePerTokenInWei,
        uint256 _mintVolume,
        string memory _name,
        string memory _description
    ) external onlyOwner {
        uint256 projectId = nextProjectId;
        projects[projectId].pricePerTokenInWei = _pricePerTokenInWei;
        projects[projectId].isSaleActive = false;
        projects[projectId].isClaimActive = false;
        projects[projectId].isAllowListActive = false;
        projects[projectId].invocations = PARENT_SUPPLY;
        projects[projectId].maxInvocations = _mintVolume;
        projects[projectId].name = _name;
        projects[projectId].description = _description;
        nextProjectId = nextProjectId + 1;
    }

    function setProjectSaleActive(uint256 _projectId, bool newState) external onlyOwner {
        projects[_projectId].isSaleActive = newState;
    }

    function setProjectClaimActive(uint256 _projectId, bool newState) external onlyOwner {
        projects[_projectId].isClaimActive = newState;
    }

    function setProjectAllowListActive(uint256 _projectId, bool newState) external onlyOwner {
        projects[_projectId].isAllowListActive = newState;
    }

    function setProjectAllowList(uint256 _projectId, bytes32 _merkleRoot) external onlyOwner {
        projects[_projectId].merkleRoot = _merkleRoot;
    }

    function setProjectPricePerTokenInWei(uint256 _projectId, uint256 _pricePerTokenInWei) external onlyOwner {
        projects[_projectId].pricePerTokenInWei = _pricePerTokenInWei;
    }

    function setProjectName(uint256 _projectId, string memory _projectName) external onlyOwner {
        projects[_projectId].name = _projectName;
    }

    function onProjectAllowList(uint256 _projectId, address claimer, bytes32[] memory proof) public view returns(bool){
        bytes32 leaf = keccak256(abi.encodePacked(claimer));
        return MerkleProof.verify(proof, projects[_projectId].merkleRoot, leaf);
    }

    function numAvailableToMint(uint256 _projectId, address claimer, bytes32[] memory proof) public view returns (uint) {
        if (onProjectAllowList(_projectId, claimer, proof)) {
            return MAX_ALLOWLIST_MINT - projects[_projectId]._allowListNumMinted[claimer];
        } else {
            return 0;
        }
    }

    function setProjectMaxInvocations(uint256 _projectId, uint256 _maxInvocations) external onlyOwner {
        require(
            _maxInvocations > projects[_projectId].invocations,
            'You must set max invocations greater than current invocations'
        );
        projects[_projectId].maxInvocations = _maxInvocations;
    }

    function addLibraryScript(string memory _script) external onlyOwner {
        libraryScripts[libraryScriptCount] = _script;
        libraryScriptCount = libraryScriptCount + 1;
    }

    function setLibraryScript(uint256 _scriptId, string memory _script) external onlyOwner {
        require(_scriptId < libraryScriptCount, "scriptId out of range");
        libraryScripts[_scriptId] = _script;
    }

    function removeLibraryLastScript() external onlyOwner {
        require(libraryScriptCount > 0, "there are no scripts to remove");
        delete libraryScripts[libraryScriptCount - 1];
        libraryScriptCount = libraryScriptCount -1;
    }

    function libraryScriptByIndex(uint256 _index) public view returns (string memory) {
        return libraryScripts[_index];
    }

    function addProjectScript(uint256 _projectId, string memory _script) external onlyOwner {
        projects[_projectId].scripts[projects[_projectId].scriptCount] = _script;
        projects[_projectId].scriptCount = projects[_projectId].scriptCount + 1;
    }

    function setProjectScript(
        uint256 _projectId,
        uint256 _scriptId,
        string memory _script
    ) external onlyOwner {
        require(_scriptId < projects[_projectId].scriptCount, 'scriptId out of range');
        projects[_projectId].scripts[_scriptId] = _script;
    }

    function setProjectCommunityHash(uint256 _projectId, string memory _projectCommunityHash) external onlyOwner {
        projects[_projectId].communityHash = _projectCommunityHash;
    }

    function projectCommunityHash(uint256 _projectId) public view returns (string memory) {
        return projects[_projectId].communityHash;
    }

    function setProjectProvenanceHash(uint256 _projectId, string memory _provenance) public onlyOwner {
        projects[_projectId].provenance = _provenance;
    }

    function projectProvenanceHash(uint256 _projectId) public view returns (string memory) {
        return projects[_projectId].provenance;
    }

    function setProjectTraitScript(uint256 _projectId, string memory _projectTraitScript) external onlyOwner {
        projects[_projectId].traitScript = _projectTraitScript;
    }

    function projectTraitScript(uint256 _projectId) public view returns (string memory) {
        return projects[_projectId].traitScript;
    }

    function removeProjectLastScript(uint256 _projectId) external onlyOwner {
        require(projects[_projectId].scriptCount > 0, 'there are no scripts to remove');
        delete projects[_projectId].scripts[projects[_projectId].scriptCount - 1];
        projects[_projectId].scriptCount = projects[_projectId].scriptCount - 1;
    }

    function projectScriptByIndex(uint256 _projectId, uint256 _index) public view returns (string memory) {
        return projects[_projectId].scripts[_index];
    }

    function setProjectBaseURI(uint256 _projectId, string memory _newBaseURI) external onlyOwner {
        projects[_projectId].projectBaseURI = _newBaseURI;
    }

    function projectBaseURI(uint256 _projectId) public view returns (string memory) {
        if(bytes(projects[_projectId].projectBaseURI).length > 0) {
            return projects[_projectId].projectBaseURI;
        }
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? baseURI: "";
    }

    function projectDetails(uint256 _projectId)
        public
        view
        returns (
            string memory projectName,
            string memory projectDescription,
            uint256 pricePerTokenInWei,
            uint256 invocations,
            uint256 maxInvocations,
            bool isSaleActive,
            bool isClaimActive,
            bool isAllowListActive,
            uint256 scriptCount
        )
    {
        projectName = projects[_projectId].name;
        projectDescription = projects[_projectId].description;
        pricePerTokenInWei = projects[_projectId].pricePerTokenInWei;
        invocations = projects[_projectId].invocations;
        maxInvocations = projects[_projectId].maxInvocations;
        isSaleActive = projects[_projectId].isSaleActive;
        isClaimActive = projects[_projectId].isClaimActive;
        isAllowListActive = projects[_projectId].isAllowListActive;
        scriptCount = projects[_projectId].scriptCount;
    }

    function showTokenSeeds(uint256 _tokenId) public view returns (bytes32[] memory) {
        return tokenSeeds[_tokenId];
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory)  {
        require(_exists(_tokenId), "Token ID does not exist");
        if(bytes(projects[tokenIdToProjectId[_tokenId]].projectBaseURI).length > 0) {
            return string(abi.encodePacked(projects[tokenIdToProjectId[_tokenId]].projectBaseURI, _tokenId.toString()));
        }
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
    }    

    function withdraw() external onlyOwner nonReentrant{
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
}