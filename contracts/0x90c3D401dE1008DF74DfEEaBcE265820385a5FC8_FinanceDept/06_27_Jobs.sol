// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/*          _       _         
 *         (_)     | |        
 *          _  ___ | |__  ___ 
 *         | |/ _ \| '_ \/ __|
 *         | | (_) | |_) \__ \
 *         | |\___/|_.__/|___/
 *        _/ |                
 *       |__/                       
 */     
 
import "./JobTransferFunction.sol";
import "./Companies.sol";
import "./Seniority.sol";
import "./Titles.sol";
import "./FinanceDept.sol";
import "./Salaries.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Jobs is ERC721, ERC721Royalty, AccessControl {
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private baseURI = "https://jobs.regular.world/cards/id/"; 
    bool public mintOpen = false;

    mapping(uint => bool) public minted;                // Regular Ids that have already claimed
    mapping(uint => uint) public timestamps;            // timestamps for claiming salary
    mapping(uint => uint) public companyIds;            // companyIds              
    mapping(uint => uint) public regIds;                // Each job NFT has an assigned RegId
    mapping(uint => uint) public jobByRegId;            // JobID by RegID

    JobTransferFunction jobTransferFunction;
    Companies companies;
    FinanceDept financeDept;
    Salaries salaries;
    Seniority seniority;
    Titles titles;
    ERC721Enumerable regularsNFT;       

    event Mint(uint jobId, uint indexed companyId, uint regularId);
    event Update(uint jobId, uint indexed companyId, uint regularId, string name);
    event RegularIdChange (uint256 indexed jobId, uint regId);
    event ResetJob (uint256 indexed jobId);

    constructor() ERC721("Regular Jobs", "JOBS") {
        _setDefaultRoyalty(msg.sender, 500);
        regularsNFT = ERC721Enumerable(0x6d0de90CDc47047982238fcF69944555D27Ecb25);
        salaries = new Salaries(address(this));
        financeDept = new FinanceDept();
        jobTransferFunction = new JobTransferFunction();
        companies = new Companies();
        seniority = new Seniority();
        titles = new Titles(address(seniority));
        financeDept.setJobsByAddr(address(this));
        financeDept.setSalariesByAddr(address(salaries));
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, address(financeDept));
        _grantRole(MINTER_ROLE, address(jobTransferFunction)); 
    }

// Primary Functions

    function safeMint(address _to, uint _regId) public {  
        require(regularsNFT.ownerOf(_regId) == _to, "Not your Regular");  
        require(!minted[_regId], "Already claimed");
        require(mintOpen, "Not minting");
        require(!hasJob(_regId),"Reg is working another job");
        minted[_regId] = true;
        (uint _jobId, uint _companyId) = companies.makeNewJob(_regId);
        timestamps[_jobId] = block.timestamp;
        companyIds[_jobId] = _companyId;
        regIds[_jobId] = _regId;
        jobByRegId[_regId] = _jobId;            
        if (companies.isManager(_regId)){ // set Managers as seniority 2
            if (seniority.level(_jobId) == 0) 
                seniority.setLevel(_jobId,2);
            else 
                seniority.incrementLevel(_jobId);
        }
        _safeMint(_to, _jobId);
        emit Mint(_jobId, _companyId, _regId);
    }

    function setRegularId(uint _jobId, uint _regId) public {
        require(ownerOf(_jobId) == msg.sender, "Not owner of this job.");
        require(regularsNFT.ownerOf(_regId) == msg.sender, "Not owner of Regular");
        require(regIds[_jobId] != _regId, "This reg already assigned to this job");
        require(hasJob(_regId) == false, "This reg already assigned to another job");
        uint _prevRegId = regIds[_jobId];
        regIds[_jobId] = _regId;   
        jobByRegId[_prevRegId] = 0;             
        jobByRegId[_regId] = _jobId;                 
        timestamps[_jobId] = block.timestamp;                             
        emit RegularIdChange(_jobId, _regId);
    }

    function unassignRegularId(uint _jobId) public {
        require(ownerOf(_jobId) == msg.sender, "Not owner of this job.");
        uint _oldRegId = regIds[_jobId];
        regIds[_jobId] = 10000;   
        jobByRegId[_oldRegId] = 0;              // SAVE REG -> JOB 
        timestamps[_jobId] = block.timestamp;                            
        emit ResetJob(_jobId);
    }

    function safeMintMany(address _to, uint[] memory _regIds) public { 
        for (uint i; i< _regIds.length;i++){
            safeMint(_to, _regIds[i]);
        }
    }

// Admin Functions

    function toggleMinting() public onlyRole(MINTER_ROLE) {
        mintOpen = !mintOpen;
    }

    function setBaseURI(string memory _newPath) public onlyRole(MINTER_ROLE) {
        baseURI = _newPath;
    }

// Other MINTER_ROLE Functions

    function resetJob(uint _jobId) public onlyRole(MINTER_ROLE) {
        uint _oldRegId = regIds[_jobId];
        regIds[_jobId] = 10000;                 // There is no #10,000
        jobByRegId[_oldRegId] = 0;              
        timestamps[_jobId] = block.timestamp;   // Reset timestamp                         
        emit ResetJob(_jobId);
    }

    function setTimestamp(uint _jobId, uint _timestamp) public onlyRole(MINTER_ROLE) {
        timestamps[_jobId] = _timestamp;
    }

    function setCompany(uint _jobId, uint _companyId) external onlyRole(MINTER_ROLE){
        companyIds[_jobId] = _companyId;
    }

    function setRegId(uint _jobId, uint _regId) external onlyRole(MINTER_ROLE){
        regIds[_jobId] = _regId;
    }

    function setJobByRegId(uint _regId, uint _jobId) public onlyRole(MINTER_ROLE) {
        jobByRegId[_regId] = _jobId;
    }

// View Functions

    function sameOwner(uint _jobId) public view returns (bool) {
        return ownerOf(_jobId) == ownerOfReg(regIds[_jobId]);
    }

    function getTimestamp(uint _jobId) public view returns (uint) {
        require(_exists(_jobId), "Query for nonexistent token");
        return timestamps[_jobId];
    }

    function getCompanyId(uint _jobId) public view returns (uint) {
        require(_exists(_jobId), "Query for nonexistent token");
        return companyIds[_jobId];
    }

    function getRegId(uint _jobId) public view returns (uint) {
        require(_exists(_jobId), "Query for nonexistent token");
        return regIds[_jobId];
    }

    function isUnassigned(uint _jobId) public view returns (bool) {
        require(_exists(_jobId), "Query for nonexistent token");
        return regIds[_jobId] == 10000; 
    }

    function getJobByRegId(uint _regId) public view returns (uint) {
        return jobByRegId[_regId];
    }

    function hasJob(uint _regId) public view returns (bool) {
        return jobByRegId[_regId] != 0;
    }

    function getJobFullDetails(uint _jobId) public view returns (uint, uint, uint, string memory, uint, string memory){
        require(_exists(_jobId), "Query for nonexistent token");
        uint _salary = salaries.salary(_jobId);
        uint _regId = regIds[_jobId];
        uint _companyId = companyIds[_jobId];
        string memory _companyName = companies.getName(_companyId);
        uint _seniority = seniority.level(_jobId);
        string memory _title = titles.title(_jobId);
        return (_salary, _regId, _companyId, _companyName, _seniority, _title);
    }

// function with external calls

   function getBaseSalary(uint _companyId) public view returns (uint) { 
        return companies.getBaseSalary(_companyId);
    }
    
    function getCompanyName(uint _companyId) public view returns (string memory) {
        return companies.getName(_companyId);
    }
    
    function getSpread(uint _companyId) public view returns (uint) {
        return companies.getSpread(_companyId);
    }
    
    function getCapacity(uint _companyId) public view returns (uint) {
        return companies.getCapacity(_companyId);
    }

    function getSalary(uint _jobId) public view returns (uint) {
        require(_exists(_jobId), "Query for nonexistent token");
        return salaries.salary(_jobId);
    }

    function getSeniorityLevel(uint _jobId) public view returns (uint) {
        // require(_exists(_jobId), "Query for nonexistent token");
        return seniority.level(_jobId);
    }

    function title(uint _jobId) public view returns (string memory) {
        require(_exists(_jobId), "Query for nonexistent token");
        return titles.title(_jobId);
    }

    function ownerOfReg(uint _regId) public view returns (address) {
        return regularsNFT.ownerOf(_regId);
    }

// Setting and getting contract addresses

    // setting

    function setContractAddr(string memory _contractName, address _addr) public onlyRole(MINTER_ROLE){
        bytes memory _contract = bytes(_contractName);
        if (keccak256(_contract) == keccak256(bytes("JobTransferFunction"))) {
            jobTransferFunction = JobTransferFunction(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("Companies"))) {
            companies = Companies(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("FinanceDept"))) {
            financeDept = FinanceDept(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("Seniority"))) {
            seniority = Seniority(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("Titles"))) {
            titles = Titles(_addr);
        } else if (keccak256(_contract) == keccak256(bytes("Salaries"))) {
            salaries = Salaries(_addr);
        } else
            revert("No match found");
    }

    // getting

    function getContractAddr(string memory _contractName) public view returns (address) {
        bytes memory _contract = bytes(_contractName);
        if (keccak256(_contract) == keccak256(bytes("JobTransferFunction"))) {
            return address(jobTransferFunction);
        } else if (keccak256(_contract) == keccak256(bytes("Companies"))) {
            return address(companies);
        } else if (keccak256(_contract) == keccak256(bytes("FinanceDept"))) {
            return address(financeDept);
        } else if (keccak256(_contract) == keccak256(bytes("Seniority"))) {
            return address(seniority);
        } else if (keccak256(_contract) == keccak256(bytes("Titles"))) {
            return address(titles);
        } else if (keccak256(_contract) == keccak256(bytes("Salaries"))) {
            return address(salaries);
        } else
            revert("None found");
    }

    function setDefaultRoyalty(address _receiver, uint96 feeNumerator) public onlyRole(MINTER_ROLE){
        super._setDefaultRoyalty(_receiver, feeNumerator);
    }

// Overrides

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Query for nonexistent token");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721) {
        if (from != address(0)){ // if not minting, then reset on transfer
            jobTransferFunction.jobTransfer(from,to,tokenId); 
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

// Proxy Methods

    function allRegularsByAddress(address _wallet) public view returns(uint[] memory){
        uint[] memory nfts = new uint[](regularsNFT.balanceOf(_wallet));
        for (uint i = 0; i < nfts.length;i++){
            nfts[i] = regularsNFT.tokenOfOwnerByIndex(_wallet, i);
        }
        return nfts;
    }

    // Should we set a limit here?
    function unmintedByAddress(address _wallet) public view returns(uint[] memory){
        uint unmintedCount = 0;
        // scan through all regs and count the unminted ones
        for (uint i = 0; i < regularsNFT.balanceOf(_wallet);i++){
            uint _regId = regularsNFT.tokenOfOwnerByIndex(_wallet, i);
            if (!minted[_regId])
                unmintedCount++;
        }
        // add unminted to the array
        uint[] memory nfts = new uint[](unmintedCount);
        for (uint i = 0; i < nfts.length;i++){
            uint _regId = regularsNFT.tokenOfOwnerByIndex(_wallet, i);
            if (!minted[_regId])
                nfts[i] = _regId;
        }
        return nfts;
    }

}