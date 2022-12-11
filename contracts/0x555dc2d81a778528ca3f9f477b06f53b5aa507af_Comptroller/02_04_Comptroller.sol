// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; 
import "../interfaces/IGnosisSafe.sol";

interface IWModule{
    function _whitelisted() external view returns (address whitelisted);
}

interface IDeFiModule{
    function name() external view returns (string memory);
    function getAccount() external view returns (address);
}

contract Comptroller {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /* ---          --- */

    // ClientId tracker
    uint256 public clientId;
    // AdvisorId tracker
    uint256 public advisorId;
    // BranchId tracker
    uint256 public branchId;
    // Relayers list
    EnumerableSet.AddressSet relayersSet;
    // ClientId to client data
    mapping(uint256 => ClientData) clients;
    // AdvisorId to advisor data
    mapping(uint256 => AdvisorData) advisors;
    // BranchId to branch data
    mapping(uint256 => BranchData) branches;
    // Get clients id from contract address
    mapping(address => uint) addressId;
    // Keeps track of registered advisors
    mapping(address => bool) public isRegisteredAdvisor;
    // Keeps track of registered branches
    mapping(address => bool) public isBranch;

    // Dao Admin
    address public owner;

    // Advisor data struct 
    struct AdvisorData {
        EnumerableSet.UintSet clientIds;
        uint256 id;
        uint256 branchId;
        address advisorAddress;
    }

    // Branch data struct 
    struct BranchData {
        EnumerableSet.UintSet advisorIds;
        uint256 id;
        address branchAddress;
    }

    // Client data struct 
    struct ClientData {
        EnumerableSet.AddressSet clientSet;
        address primaryAddress;
        uint256 advisorId;
    }


    /* --- Events --- */

    event RegisterClient(uint256 indexed clientId, uint256 advisorId, address[] clientAddresses);
    event RegisterAdvisor(uint256 indexed advisorId, address advisorAddress);
    event RegisterBranch(uint256 indexed branchId, address branchAddress);
    event RegisterRelayer(address relayerAddress);

    /* ---          --- */

    constructor(address daoAdmin) {
        owner = daoAdmin;
    }

    /// @dev Method called to register the Client addresses,
    /// and create and assign a new clientID.
    /// @param _clientSafes The set of client addresses to register.
    /// @param _primaryAddress The client primary address.
    /// @param _advisorId The advisorId of the advisor managing the client's assets.
    function registerClient(
        address[] memory _clientSafes,
        address _primaryAddress,
        uint256 _advisorId
    ) 
        external 
        returns (uint256)
    {
        require(advisors[_advisorId].advisorAddress == msg.sender || msg.sender == owner, "NOAUTH");
        clientId++;
        _registerClient(clientId,_clientSafes,_primaryAddress,_advisorId);
        emit RegisterClient(clientId,_advisorId,_clientSafes);

        return clientId;
    }

    /// @dev Method called by branch (or advisor) to register the Advisor address,
    /// and create and assign a new advisorID.
    /// @param advisorAddress The address of the advisor managing the client's assets.
    function registerAdvisor(
        address advisorAddress,
        uint256 branchId
    ) 
        external 
        returns (uint256)
    {
        require(isBranch[msg.sender] && branches[branchId].branchAddress == msg.sender, "NOAUTH");
        require(!isRegisteredAdvisor[advisorAddress],"DUPL");
        advisorId++;
        AdvisorData storage data = advisors[advisorId];
        data.id = advisorId;
        data.branchId = branchId;
        data.advisorAddress = advisorAddress;
        isRegisteredAdvisor[advisorAddress] = true;
        emit RegisterAdvisor(advisorId, advisorAddress);

        return advisorId;
    }

    /// @dev Method called to register the branch to DAA,
    /// and create and assign a new branchId.
    /// @param branchAddress The address of the advisor managing the client's assets.
    function registerBranch(
        address branchAddress
    )   
        external 
        onlyOwner
        returns (uint256)
    {
        require(!isBranch[msg.sender] , "DUPL");
        branchId++;
        BranchData storage data = branches[branchId];
        data.id = branchId;
        data.branchAddress = branchAddress;
        isBranch[branchAddress] = true;
        emit RegisterBranch(branchId, branchAddress);

        return branchId;
    }

    /// @dev Method called to register a relayer to DAA,
    /// allowing it to submit pre-singed transactions.
    /// @param newAddress The address of the relayer.
    function registerRelayer(address newAddress) external {
        require(isBranch[msg.sender], "NOAUTH");
        relayersSet.add(newAddress);

        emit RegisterRelayer(newAddress);
    }


    /// @dev Change the registered address of an advisor.
    /// @param _advisorId The id of the advisor record to modify.
    /// @param advisorAddress The new address to add to the record.
    function changeAdvisor(
        uint _advisorId,
        address advisorAddress
    ) external {
        AdvisorData storage data = advisors[_advisorId];
        require(branches[data.branchId].branchAddress == msg.sender,"NOAUTH");
        isRegisteredAdvisor[data.advisorAddress] = false;
        isRegisteredAdvisor[advisorAddress] = true;
        data.id = _advisorId;
        data.advisorAddress = advisorAddress;

        emit RegisterAdvisor(_advisorId, advisorAddress);
    }

    /// @dev Change the branch address record.
    /// @param _branchId The id of the branch to modify.
    /// @param branchAddress The new address to add to the record.
    function changeBranch(
        uint _branchId,
        address branchAddress
    ) external onlyOwner {
        require(_branchId <= branchId && _branchId != 0, "NREG");
        BranchData storage data = branches[_branchId];
        isBranch[data.branchAddress] = false;
        isBranch[branchAddress] = true;
        data.id = _branchId;
        data.branchAddress = branchAddress;
        
        emit RegisterBranch(branchId, branchAddress);
    }

    /// @dev Change client primary address to new address.
    /// @param clientId The client id to modify.
    /// @param _primaryAddress The new address to set as primary address.
    function changeClientPrimaryAddress(
        uint clientId,
        address _primaryAddress
    ) external {
        require(msg.sender == owner || clients[clientId].clientSet.contains(msg.sender), "NOAUTH");
        ClientData storage data = clients[clientId];
        address[] memory _clientSafes = clients[clientId].clientSet.values();
        _checkPrimaryAddress(_clientSafes,_primaryAddress);
        data.primaryAddress = _primaryAddress;
    }

    /// @dev Add an address to the client set.
    /// @param _clientId The client id to modify.
    /// @param newAddress The address to add to the existing set.
    function addClientAddress(
        uint _clientId,
        address newAddress
    ) external {
        require(advisors[clients[clientId].advisorId].advisorAddress == msg.sender, "NOAUTH");
        ClientData storage data = clients[_clientId];
        addressId[newAddress] = _clientId;
        data.clientSet.add(newAddress);
    }

    /// @dev Remove an address from the client set.
    /// @param _clientId The client id to modify.
    /// @param toRemove The address to remove from the existing set.
    function removeClientAddress(
        uint _clientId,
        address toRemove
    ) external {
        require(advisors[clients[_clientId].advisorId].advisorAddress == msg.sender, "NOAUTH");
        ClientData storage data = clients[_clientId];
        addressId[toRemove] = 0;
        data.clientSet.remove(toRemove);
    }

    /// @dev Returns the cliend Id for a given address
    /// @param _address The address to look up.
    function isClientAddress(address _address) external view returns (bool isClient) {
        if(addressId[_address]>0){
            isClient = true;
        }
    }

    /// @dev Returns if specific address is a registered relayer
    function isRelayer(address _address) public 
        view 
        returns (bool)
    {
        return relayersSet.contains(_address);
    }

    function getClientIdFromAddress(address _address) public view returns(uint){
        return addressId[_address];
    }

    /// @dev Getter of all registered addresses for given client.
    /// @param _clientId The registered id of the client.
    function getClientAddresses(uint _clientId) 
        external 
        view 
        returns (address[] memory)
    {
        return clients[_clientId].clientSet.values();
    }

    /// @dev Getter of the advisor registered for given client.
    /// @param _clientId The registered id of the client.
    function getClientAdvisor(uint _clientId) 
        external
        view
        returns (uint256)
    {
        return clients[_clientId].advisorId;
    }

    /// @dev Getter of the advisor address registered for given id.
    /// @param _advisorId The registred advisor Id to query.
    function getAdvisorAddress(uint _advisorId) 
        external
        view
        returns (address)
    {
        return advisors[_advisorId].advisorAddress;
    }

    /// @dev Getter of the registred branch id for a given advisor.
    /// @param _advisorId The registred id of the advisor.
    function getAdvisorBranch(
        uint256 _advisorId
    )
        external
        view
        returns (uint256)
    {
        return advisors[_advisorId].branchId;
    }

    /// @dev Getter of the registred branch address for given id.
    /// @param _branchId The registered branch Id.
    function getBranchAddress(uint _branchId) 
        external
        view
        returns (address)
    {
        return branches[_branchId].branchAddress;
    }

    /// @dev Getter of all client's data for UI purposes.
    /// It takes the client primary address as input, and returns:
    ///     - The addresses of the Safe registered for the given client 
    ///       and their type (i.e. Main Safe or DeFi Safe)
    ///     - The addresses of the Owners of each Safe and
    ///       their role (i.e., primary, backup/guardian, advisor, branch)
	///     - The addresses of the Module enabled on each Safe. 
    ///       If the safe is a Withdraw module, it will also return the withdraw whitelisted address,
    ///       if the module is a DeFi module, it will return the SmartWallet address).
    /// @param clientSafe The client primary address - the wallet connected to the app.
    function getAllClientData(
        address clientSafe
    ) 
        external
        view
        returns(address[] memory safes, string[] memory safeTypes, address[][] memory linkedAddresses, uint[][] memory roles)
    {  
        linkedAddresses = new address[][](10);
        roles = new uint[][](10);
        safes = getClientAddresses(clientSafe);
        uint len = safes.length;
        safeTypes = new string[](len);
        for (uint256 i = 0; i < len; i++){
            if(safes[i] != address(0)){
                (safeTypes[i], linkedAddresses[i], roles[i]) = getSafeRoles(safes[i]);
            }
        }
    }

    /// @dev Takes a Safe address as input and returns known DAA roles.
    /// Primary             role id: 1
    /// Backup/Guardian     role id: 2                
    /// Advisor             role id: 3      
    /// Branch              role id: 4
    /// Withdrawal Module   role id: 5
    /// Withdrawal Address  role id: 6
    /// DeFi Module         role id: 7
    /// DeFi SmartWallet    role id: 8
    function getSafeRoles(address safe) 
        public 
        view 
        returns(string memory safeType, address[] memory linkedAddresses, uint[] memory roles)
    {
        safeType = "MAIN";
        linkedAddresses = new address[](10);
        roles = new uint[](10);
        uint clientId = addressId[safe];
        address[] memory _owners = IGnosisSafe(safe).getOwners();
        uint256 len = _owners.length;
        for (uint256 i = 0; i < len; i++) {
            linkedAddresses[i] = _owners[i];
            if (clients[clientId].primaryAddress==_owners[i]){
                roles[i] = 1;
            } else if (isRegisteredAdvisor[_owners[i]]){
                roles[i] = 3;
            } else if (isBranch[_owners[i]]){
                roles[i] = 4;
            } else {
                roles[i] = 2; 
            }
        }
        address[] memory modules = IGnosisSafe(safe).getModules();
        len = modules.length;
        uint nModules = 0;
        for (uint256 i = 0; i < len; i++) {
            if(isWithdrawModule(modules[i])){
                linkedAddresses[4+nModules] = modules[i]; roles[4+nModules] = 5;
                linkedAddresses[5+nModules] = IWModule(linkedAddresses[4+nModules])._whitelisted();roles[5+nModules] = 6;
                nModules+=2;
            }
            if(isDeFiModule(modules[i])){
                linkedAddresses[4+nModules] = modules[i]; roles[4+nModules] = 7;
                linkedAddresses[5+nModules] = IDeFiModule(linkedAddresses[4+nModules]).getAccount();roles[5+nModules] = 8;
                safeType = "DEFI";
                nModules+=2;
            }
        }
    }

    function getClientAddresses(address clientAddr)
        public
        view
        returns (address[] memory)
    {
        uint clientId = addressId[clientAddr];
        return clients[clientId].clientSet.values();
    }

    function isWithdrawModule(address toCheck) public view returns (bool isWModule){
        try IWModule(toCheck)._whitelisted() {
            isWModule = true;
        } catch{
            isWModule = false;
        }
    }

    function isDeFiModule(address toCheck) public view returns (bool isDModule){
        if (keccak256(abi.encode(IDeFiModule(toCheck).name)) == keccak256(abi.encode("DAA DSP Module"))){
            isDModule = true;
        }
    }

    function _registerClient(
        uint clientId,
        address[] memory _clientSafes,
        address _primaryAddress,
        uint256 _advisorId
    ) 
        internal 
    {
        ClientData storage data = clients[clientId];
        uint len = _clientSafes.length;
        for(uint i=0; i < len; i++){
            require(_clientSafes[i] != address(0), "AZERO");
            if(data.clientSet.add(_clientSafes[i])){
                addressId[_clientSafes[i]] = clientId; 
            }
        }
        _checkPrimaryAddress(_clientSafes,_primaryAddress);
        data.primaryAddress = _primaryAddress;
        data.advisorId = _advisorId;
    }

    function _checkPrimaryAddress(
        address[] memory _clientSafes,
        address _clientAddress
    ) 
        internal returns (bool auth)
    {
        require(addressId[_clientAddress] == 0,"DUPL");
        uint len = _clientSafes.length;
        for (uint256 i = 0; i < len; i++){
            if(IGnosisSafe(_clientSafes[i]).isOwner(_clientAddress)){
                auth = true; // only 1 safe is enough for now, TBD if 2/2
            }
        }
        require(auth,"PAUTH");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NOAUTH"); 
        _;
    }

}