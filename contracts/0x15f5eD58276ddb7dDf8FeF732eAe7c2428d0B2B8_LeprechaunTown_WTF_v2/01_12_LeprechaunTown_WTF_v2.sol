// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

/*
     .-. .-.
    (   |   )
  .-.:  |  ;,-.
 (_ __`.|.'_ __)
 (    ./Y\.    )
  `-.-' | `-.-'
        \ 🌈 ☘️ 2️⃣
*/

contract LeprechaunTown_WTF_v2 is ERC1155, Ownable {
    string public name = "LeprechaunTown_WTF_v2";
    string public symbol = "LTWTF2";
    string private ipfsCID = "QmUGH1et5D6aa67r4XUVuD2eVoVQZQCfBqDZsm1fh6SfKU";
    uint256 public collectionTotal = 7608;
    uint256 public cost = 0.03 ether;
    uint256 public maxMintAmount = 10;
    uint256 public maxBatchMintAmount = 10;

    bool public paused = true;
    bool public revealed = true;
    bool public mintInOrder = true;

    uint256 public ogCollectionTotal;
    uint256 public tokenNextToMint;
    mapping(uint => string) private tokenToURI;
    mapping(uint256 => uint256) private currentSupply;
    mapping(uint256 => bool) private hasMaxSupply;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => bool) private hasMaxSupplyForBatch;
    mapping(uint256 => uint256) public maxSupplyForBatch;
    mapping(uint256 => bool) private createdToken;

    bool public roleInUse = false;
    mapping(uint256 => string) public role;
    uint256 public roleLimit = 20;

    mapping(uint256 => uint256[]) public requirementTokens;
    mapping(uint256 => uint256[]) public batchRequirementTokens;

    mapping(uint256 => bool) public flagged;
    mapping(address => bool) public restricted;

    uint256[] public collectionBatchEndID;
    string[] public ipfsCIDBatch;
    string[] public uriBatch;

    mapping(address => uint256) public holdersAmount;
    mapping(address => uint256) public claimBalance;

    address payable public payments;
    address public projectLeader;
    address[] public admins;
    uint256 public devpayCount = 1;
    uint256 private devpayCountMax = 0;
    
    address public LeprechaunTown_WTF = 0xDA0bab807633f07f013f94DD0E6A4F96F8742B53;//0x360C8A7C01fd75b00814D6282E95eafF93837F27;
    

    constructor() ERC1155(""){
        ogCollectionTotal = collectionTotal;
        collectionBatchEndID.push(collectionTotal);
        ipfsCIDBatch.push(ipfsCID);
        uriBatch.push("");
        maxSupply[1] = 1;
        hasMaxSupply[1] = true;
        createdToken[1] = true;
        currentSupply[1] = 1;
        tokenNextToMint = 2;
        _mint(msg.sender, 1, 1, "");

        projectLeader = 0x522ee4130B819355e10218E40d6Ab0c495219690;
    }

    /**
     * @dev The contract developer's website.
     */
    function contractDev() public pure returns(string memory){
        string memory dev = unicode"🐸 https://www.halfsupershop.com/ 🐸";
        return dev;
    }   

    /**
     * @dev Admin can set the PAUSE state.
     * true = closed to Admin Only
     * false = open for Presale or Public
     */
    function pause(bool _state) public onlyAdmins {
        paused = _state;
    }

    /**
     * @dev Admin can set the roleInUse state allowing Mints to pick a role randomly.
     */
    function setRoleInUse(bool _state) public onlyAdmins {
        roleInUse = _state;
    }

    /**
     * @dev Admin can set the mintInOrder state.
     */
    function setMintInOrder(bool _state) public onlyAdmins {
        mintInOrder = _state;
    }

    /**
     * @dev Admin can set the tokenNextToMint.
     */
    function setTokenNextToMint(uint _id) public onlyAdmins {
        tokenNextToMint = _id;
    }

    function _cost() public view returns(uint256){
        if (!checkIfAdmin()) {
            return cost;
        }
        else{
            return 0;
        }
    }

    function checkOut(uint _amount) private {
        uint256 _freeAmount = holdersAmount[msg.sender] - claimBalance[msg.sender];
        if(_freeAmount >= _amount){
            _freeAmount = _amount;
        }

        if (!checkIfAdmin()) {
            //Public Phase
            require(msg.value >= ((_amount - _freeAmount) * _cost()), "!Funds");

            if(msg.value > 0 && devpayCount <= devpayCountMax){
                devpayCount += msg.value;
            }
        }
    }

    function checkOutScan(uint _id) private{
        if (!exists(_id)) {
            createdToken[_id] = true;
            flagged[_id] = false;
            if(mintInOrder){
                maxSupply[_id] = 1;
                hasMaxSupply[_id] = true;
                currentSupply[_id] = 1;
            }
        }

        if(roleInUse){
            role[_id] = randomRole();
        }
    }

    /**
     * @dev Allows Admins, Whitelisters, and Public to Mint NFTs in Order from 1-collectionTotal.
     */
    function _mintInOrder(uint _numberOfTokensToMint) public payable {
        require(mintInOrder, "mintInOrder");
        require(!paused, "P");
        require(!exists(collectionTotal), "S/O");
        require(_numberOfTokensToMint + tokenNextToMint - 1 <= collectionTotal, ">Amount");

        checkOut(_numberOfTokensToMint);
        _mintBatchTo(msg.sender, _numberOfTokensToMint);
    }

    /**
     * @dev Allows Admins to Mint NFTs in Order from 1-collectionTotal to an address.
     * Can only be called by Admins even while paused.
     */
    function _mintInOrderTo(address _to, uint _numberOfTokensToMint) external onlyAdmins {
        require(mintInOrder, "mintInOrder");
        require(!exists(collectionTotal), "S/O");
        require(_numberOfTokensToMint + tokenNextToMint -1 <= collectionTotal, ">Amount");

        _mintBatchTo(_to, _numberOfTokensToMint);
    }

    function _mintBatchTo(address _to, uint _numberOfTokensToMint) private {
        uint256[] memory _ids = new uint256[](_numberOfTokensToMint);
        uint256[] memory _amounts = new uint256[](_numberOfTokensToMint);
        for (uint256 i = 0; i < _numberOfTokensToMint; i++) {
            uint256 _id = tokenNextToMint;
            
            checkOutScan(_id);

            _ids[i] = tokenNextToMint;
            _amounts[i] = 1;
            tokenNextToMint++;
        }
        claimBalance[msg.sender] += _numberOfTokensToMint;

        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
     * @dev Allows Owner, Whitelisters, and Public to Mint a single NFT.
     */
    function mint(address _to, uint _id, uint _amount) public payable {
        require(!mintInOrder, "!mintInOrder");
        require(!paused, "P");
        require(canMintChecker(_id, _amount), "CANNOT MINT");

        checkOut(_amount);
        checkOutScan(_id);
        currentSupply[_id] += _amount;
        
        _mint(_to, _id, _amount, "");
    }

    function canMintChecker(uint _id, uint _amount) private view returns(bool){
        if (hasMaxSupply[_id]) {
            if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal && currentSupply[_id] + _amount <= maxSupply[_id]) {
                // CAN MINT
            }
            else {
                // CANNOT MINT 
                return false;
            }
        }
        else {
            if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal) {
                // CAN MINT
            }
            else {
                // CANNOT MINT 
                return false;
            }
        }

        // checks if the id needs requirement token(s)
        if(requirementTokens[_id].length > 0) {
            for (uint256 i = 0; i < requirementTokens[_id].length; i++) {
                if(balanceOf(msg.sender, requirementTokens[_id][i]) <= 0){
                    //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S)
                    return false;
                }
                else{
                    continue;
                }
            }
        }

        // checks if the batch (other than the original) that the id resides in needs requirement token(s)
        for (uint256 i = 0; i < collectionBatchEndID.length; i++) {
            if(i != 0 && _id <= collectionBatchEndID[i] && _id > collectionBatchEndID[i - 1]){
                uint256 batchToCheck = collectionBatchEndID[i];
                if(batchRequirementTokens[batchToCheck].length > 0){
                    for (uint256 j = 0; j < batchRequirementTokens[batchToCheck].length; j++) {
                        if(balanceOf(msg.sender, batchRequirementTokens[batchToCheck][j]) <= 0){
                            //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S)
                            return false;
                        }
                        else{
                            continue;
                        }
                    }
                }
                // checks if the batch the id resides in has a supply limit for each id in the batch
                if(hasMaxSupplyForBatch[batchToCheck]){
                    if (_amount > 0 && _amount <= maxMintAmount && _id > 0 && _id <= collectionTotal && currentSupply[_id] + _amount <= maxSupplyForBatch[batchToCheck]) {
                        // CAN MINT
                    }
                    else {
                        // CANNOT MINT 
                        return false;
                    }
                }
                else {
                    continue;
                }
            }
        }

        return true;
    }

    /**
     * @dev Allows Owner, Whitelisters, and Public to Mint multiple NFTs.
     */
    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) public payable {
        require(!mintInOrder, "Requires mintInOrder False");
        require(!paused, "Paused");
        require(_ids.length <= maxMintAmount, "Too Many IDs");
        require(_ids.length == _amounts.length, "IDs and Amounts Not Equal");
        require(canMintBatchChecker(_ids, _amounts), "CANNOT MINT BATCH");

        uint256 _totalBatchAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            _totalBatchAmount += _amounts[i];
        }
        require(_totalBatchAmount <= maxBatchMintAmount, "Batch Amount Limit Exceeded");

        checkOut(_totalBatchAmount);
        
        for (uint256 k = 0; k < _ids.length; k++) {
            uint256 _id = _ids[k];
            checkOutScan(_id);
            currentSupply[_ids[k]] += _amounts[k];
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    function canMintBatchChecker(uint[] memory _ids, uint[] memory _amounts)private view returns(bool){
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            if(canMintChecker(_id, _amount)){
                //CAN MINT
            }
            else{
                // CANNOT MINT
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Allows Admin to Mint a single NEW NFT.
     */
    function adminMint(address _to, uint _id, uint _amount) external onlyAdmins {
        require(_id > ogCollectionTotal, "ID Must Be New");
        checkOutScan(_id);
        currentSupply[_id] += _amount;
        _mint(_to, _id, _amount, "");
    }

    /**
     * @dev Allows Admin to Mint multiple NEW NFTs.
     */
    function adminMintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external onlyAdmins {
        require(!checkIfOriginal(_ids), "ID Must Be New");
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            checkOutScan(_id);
            currentSupply[_id] += _amounts[i];
        }
        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
    * @dev Allows User to DESTROY a single token they own.
    */
    function burn(uint _id, uint _amount) external {
        currentSupply[_id] -= _amount;
        _burn(msg.sender, _id, _amount);
    }

    /**
    * @dev Allows User to DESTROY multiple tokens they own.
    */
    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            currentSupply[_id] -= _amounts[i];
        }
        _burnBatch(msg.sender, _ids, _amounts);
    }

    /**
    * @dev Allows Admin to REVEAL the original collection.
    * Can only be called by the current owner once.
    * WARNING: Please ensure the CID is 100% correct before execution.
    */
    function reveal(string memory _CID) external onlyAdmins {
        require(!revealed, "Revealed");
        ipfsCID = _CID;
        ipfsCIDBatch[0] = _CID;
        revealed = true;
    }

    /**
     * @dev Allows Admin to set the requirementTokens for a specified token ID or Batch end ID
     */
    function setRequirementTokens(uint _endID, bool _isBatch, uint[] memory _requiredIDS) external onlyAdmins {
        if(_isBatch){
            for (uint256 i = 0; i < collectionBatchEndID.length; i++) {
                if(collectionBatchEndID[i] == _endID){
                    // is confirmed a Batch
                    break;
                }
                if(collectionBatchEndID[i] == collectionBatchEndID[collectionBatchEndID.length - 1] && _endID != collectionBatchEndID[i]){
                    // is not a Batch
                    revert("_endID is not a Batch");
                }
            }
            batchRequirementTokens[_endID] = _requiredIDS;
        }
        else{
            requirementTokens[_endID] = _requiredIDS;
        }
    }

    /**
    * @dev Allows Admin to modify the URI or CID of a Batch.
    * Note: Original Collection Batch URIs and or CIDs cannot be modified.
    */
    function modifyURICID(uint _batchIndex, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        require(_batchIndex != 0, "Batch Index Cannot Be Original Collection");
        if (_isIpfsCID) {
            //modify IPFS CID
            ipfsCIDBatch[_batchIndex] = _uri;
        }
        else{
            //modify URI
            uriBatch[_batchIndex] = _uri;
        }
    }

    /**
    * @dev Allows Admin to set the URI of a single token.
    * Note: Original Token URIs cannot be changed.
    *       Set _isIpfsCID to true if using only IPFS CID for the _uri.
    */
    function setURI(uint _id, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        require(_id > ogCollectionTotal, "ID Must Not Be From Original Collection");
        if (_isIpfsCID) {
            string memory _uriIPFS = string(abi.encodePacked(
                "ipfs://",
                _uri,
                "/",
                Strings.toString(_id),
                ".json"
            ));

            tokenToURI[_id] = _uriIPFS;
            emit URI(_uriIPFS, _id);
        }
        else {
            tokenToURI[_id] = _uri;
            emit URI(_uri, _id);
        }
    }

    /**
    * @dev Allows Admin to create a new Batch and set the URI or CID of a single or batch of tokens.
    * Note: Previous Token URIs and or CIDs cannot be changed.
    *       Set _isIpfsCID to true if using only IPFS CID for the _uri.
    *       Example URI structure if _endBatchID = 55 and if _isIpfsCID = false and if _uri = BASEURI.EXTENSION
    *       will output: BASEURI.EXTENSION/55.json for IDs 55 and below until it hits another batch end ID
    */
    function createBatchAndSetURI(uint _endBatchID, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        require(_endBatchID > collectionBatchEndID[collectionBatchEndID.length-1], "Last Batch ID must be > previous batch total");
        
        if (_isIpfsCID) {
            //set IPFS CID
            collectionBatchEndID.push(_endBatchID);
            ipfsCIDBatch.push(_uri);
            uriBatch.push("");
        }
        else{
            //set URI
            collectionBatchEndID.push(_endBatchID);
            uriBatch.push(_uri);
            ipfsCIDBatch.push("");
        }
        
    }

    function uri(uint256 _id) override public view returns(string memory){
       string memory _CIDorURI = string(abi.encodePacked(
            "ipfs://",
            ipfsCID,
            "/"
        ));
        if(createdToken[_id]){
            if (_id > 0 && _id <= ogCollectionTotal) {
                //hidden
                if(!revealed){
                    return (
                    string(abi.encodePacked(
                        _CIDorURI,
                        "hidden",
                        ".json"
                    )));
                }
                else{
                    if(keccak256(abi.encodePacked((tokenToURI[_id]))) != keccak256(abi.encodePacked(("")))){
                        return tokenToURI[_id];
                    }
                    for (uint256 i = 0; i < collectionBatchEndID.length; ++i) {
                        if(i == 0){
                            //first iteration is for OG collection
                            continue;
                        }
                        else{
                            if(_id <= collectionBatchEndID[i]){
                                if(keccak256(abi.encodePacked((ipfsCIDBatch[i]))) != keccak256(abi.encodePacked(("")))){
                                    _CIDorURI = string(abi.encodePacked(
                                        "ipfs://",
                                        ipfsCIDBatch[i],
                                        "/"
                                    ));
                                }
                                if(keccak256(abi.encodePacked((uriBatch[i]))) != keccak256(abi.encodePacked(("")))){
                                    _CIDorURI = string(abi.encodePacked(
                                        uriBatch[i],
                                        "/"
                                    ));
                                }
                                
                                continue;
                            }
                            else{
                                //_id was not found in a batch
                                continue;
                            }
                        }
                    
                    }
                    //no role
                    if(keccak256(abi.encodePacked((role[_id]))) == keccak256(abi.encodePacked(("")))){
                        return (
                        string(abi.encodePacked(
                            _CIDorURI,
                            Strings.toString(_id),
                            ".json"
                        )));
                    }
                    else{
                        //has role
                        return (
                        string(abi.encodePacked(
                            _CIDorURI,
                            role[_id],
                            ".json"
                        )));
                    }
                }
            }
            //no URI
            return "URI Does Not Exist";
        }
        else{
            return "Token Does Not Exist";
        }
    }

    function checkIfOriginal(uint[] memory _ids) private view returns(bool){
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            if (_id <= ogCollectionTotal) {
                // original
            }
            else {
                // new
                return false;
            }
        }
        return true;
    }

    //"Randomly" returns a number >= 0 and <= roleLimit.
    function randomNumber() internal view returns (uint256){
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            tokenNextToMint,
            role[tokenNextToMint - 1])
            )) % roleLimit;
        //return random;
        return (random + 1);
    }

    //"Randomly" returns a number string >= 0 and <= roleLimit.
    function randomRole() internal view returns (string memory){
        uint random = randomNumber();
        //return random;
        return Strings.toString(random + 1);
    }

    function randomPick() public view returns (string memory _role){
        return randomRole();
    }

    function roleLimitSet(uint _limit) external onlyAdmins {
        roleLimit = _limit;
    }

    /**
    * @dev Total amount of tokens in with a given id.
    */
    function totalSupply(uint256 _id) public view returns(uint256) {
        return currentSupply[_id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 _id) public view returns(bool) {
        return createdToken[_id];
    }

    /**
    * @dev Checks max supply of token with the given id.
    * Note: If 0 then supply is limitless.
    */
    function checkMaxSupply(uint256 _id) public view returns(uint256) {
        if(maxSupply[_id] != 0){
            return maxSupply[_id];
        }
        
        for (uint256 i = 0; i < collectionBatchEndID.length; i++) {
            if(_id != 0 && _id <= collectionBatchEndID[i] && _id > collectionBatchEndID[i - 1]){
                uint256 batchToCheck = collectionBatchEndID[i];
                if(maxSupplyForBatch[batchToCheck] != 0){
                    return maxSupplyForBatch[batchToCheck];
                }
                else{
                    break;
                }
            }
        }
        
        // no Max Supply found ID has infinite supply
        return 0;
    }

    /**
     * @dev Admin can set a supply limit.
     * Note: If 0 then supply is limitless.
     */
    function setMaxSupplies(uint[] memory _ids, uint[] memory _supplies, bool _isBatchAllSameSupply) external onlyAdmins {
        if(_isBatchAllSameSupply){
            uint256 _endBatchID = _ids[_ids.length - 1];
            for (uint256 i = 0; i < collectionBatchEndID.length; ++i) {
                if(_endBatchID == collectionBatchEndID[i]){
                    maxSupplyForBatch[_endBatchID] = _supplies[_supplies.length - 1];
                    if(_supplies[_supplies.length - 1] > 0){
                        // has a max limit
                        hasMaxSupplyForBatch[_endBatchID] = true;
                    }
                    else {
                        // infinite supply
                        hasMaxSupplyForBatch[_endBatchID] = false;
                    }                 
                }
            }
        }
        else{
            for (uint256 i = 0; i < _ids.length; i++) {
                uint256 _id = _ids[i];
                maxSupply[_id] += _supplies[i];
                if (_supplies[i] > 0) {
                    // has a max limit
                    hasMaxSupply[_id] = true;
                }
                else {
                    // infinite supply
                    hasMaxSupply[_id] = false;
                }
            }
        }
        
    }

    /**
     * @dev Admin can update the collection total to allow minting the newly added NFTs.
     * Note: This only adds to the current collections total
     */
    function updateCollectionTotal(uint _amountToAdd) external onlyAdmins {
        collectionTotal += _amountToAdd;
    }

    /**
     * @dev Admin can set the amount of NFTs a user can mint in one session.
     */
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyAdmins {
        maxMintAmount = _newmaxMintAmount;
    }

    function setHolderAmount(address[] calldata _holders, uint[] memory _heldAmount) public onlyAdmins {
        if(_heldAmount.length == 0){
            //all users are automatically set to tier 0 by default
        }
        else{
            if(_heldAmount.length == 1){
                for (uint256 i = 0; i < _holders.length; i++) {
                    holdersAmount[_holders[i]] = _heldAmount[0];
                }
            }
            else{
                require(_holders.length == _heldAmount.length, "Holders Array Not Equal To Held Array");

                for (uint256 g = 0; g < _holders.length; g++) {
                    holdersAmount[_holders[g]] = _heldAmount[g];
                }
            }
        }
    }


    /**
     * @dev Admin can set the new cost in WEI.
     * 1 ETH = 10^18 WEI
     * Use http://etherscan.io/unitconverter for conversions.
     */
    function setCost(uint256 _newCost) public onlyAdmins {
        cost = _newCost;
    }

    /**
     * @dev Admin can set the payout address.
     */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
     * @dev Admin can pull funds to the payout address.
     */
    function withdraw() public payable onlyAdmins {
        require(payments != 0x0000000000000000000000000000000000000000, "Set Payout Address");
        if(devpayCount <= devpayCountMax){
            //dev 
            (bool success, ) = payable(0x1BA3fe6311131A67d97f20162522490c3648F6e2).call{ value: address(this).balance } ("");
            require(success);
        }
        else{
            //splitter
            (bool success, ) = payable(payments).call{ value: address(this).balance } ("");
            require(success);
        }
        
    }

    /**
     * @dev Auto send funds to the payout address.
        Triggers only if funds were sent directly to this address.
     */
    receive() payable external {
        require(payments != 0x0000000000000000000000000000000000000000, "Set Payout Address");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

     /**
     * @dev Throws if called by any account other than the owner or admin.
     */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
     * @dev Throws if the sender is not the owner or admin.
     */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "Not an admin");
    }

    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == projectLeader){
            return true;
        }
        if(admins.length > 0){
            for (uint256 i = 0; i < admins.length; i++) {
                if(msg.sender == admins[i]){
                    return true;
                }
            }
        }
        
        // Not an Admin
        return false;
    }

    /**
     * @dev Owner and Project Leader can set the addresses as approved Admins.
     * Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
     */
    function setAdmins(address[] calldata _users) public onlyAdmins {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        delete admins;
        admins = _users;
    }

    /**
     * @dev Owner or Project Leader can set the address as new Project Leader.
     */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        projectLeader = _user;
    }

    /**
     * @dev Throws if the sender is not the dev.
     * Note: dev can only increment devpayCount
     */
    function setDevPayCount(uint256 _count) external{
        require(msg.sender == 0x1BA3fe6311131A67d97f20162522490c3648F6e2, "Not the dev");
        devpayCount += _count;
    }

    /**
     * @dev Throws if the sender is not the dev.
     * Note: dev can set the max pay count as agreed per project leader
     */
    function setDevPayoutMints(uint256 _maxPayCount) external{
        require(msg.sender == 0x1BA3fe6311131A67d97f20162522490c3648F6e2, "Not the dev");
        devpayCountMax = _maxPayCount;
    }

    /**
     * @dev Owner or Project Leader can set the restricted state of an address.
     * Note: Restricted addresses are banned from moving tokens.
     */
    function restrictAddress(address _user, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        restricted[_user] = _state;
    }

    /**
     * @dev Owner or Project Leader can set the flag state of a token ID.
     * Note: Flagged tokens are locked and untransferable.
     */
    function flagID(uint256 _id, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        flagged[_id] = _state;
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override{
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data); // Call parent hook
        require(restricted[operator] == false && restricted[from] == false && restricted[to] == false, "Operator, From, or To Address is RESTRICTED"); //checks if the any address in use is restricted

        for (uint256 i = 0; i < ids.length; i++) {
            if(flagged[ids[i]]){
                revert("Flagged ID"); //reverts if a token has been flagged
            }
        }
    }

}