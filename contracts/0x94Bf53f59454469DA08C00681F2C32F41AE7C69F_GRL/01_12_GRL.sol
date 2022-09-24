// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

/*                                                                                                                                                  
           .......................................................................................................................            
          .,;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;.            
          ';;;,................................';;;;;;;;;..................................,;;;;;;;;,.......................,;;;,.            
         .,;;,.                                ';;;;;;;;'                                 .,;;;;;;;,.                      .,;;;.             
         ';;;.                                .,;;;;;;;,.                                 ';;;;;;;;'                       .;;;'              
        .;;;,.                                ';;;;;;;;.                                 .;;;;;;;;,.                      .,;;,.              
       .,;;;.                                .;;;;;;;;,.                                 ';;;;;;;;.                       ';;;'               
       .;;;'                                .,;;;;;;;;.            .......              .;;;;;;;;,.                      .;;;,.               
      .,;;;.                                .;;;;;;;;'          .',;;;;;;;.            .,;;;;;;;;.                       ';;;.                
      ';;;'                                .,;;;;;;;;.        .';;;;;;;;;;,.           .;;;;;;;;'                       .;;;;'........        
     .,;;,.                                ';;;;;;;;'         .;;;;;;;;;;;.           .,;;;;;;;;.                      .,;;;;;;;;;;;;'        
     ';;;.              ..................';;;;;;;;,.         .';;;;;;;,'.            ';;;;;;;;'                        ........,;;;,.        
    .;;;,.             .;;;;;;;;,........';;;;;;;;;.            .......              .;;;;;;;;,.                                ';;;'         
   .,;;;.             .,;;;;;;;'.        .;;;;;;;;,.                                .';;;;;;;;.                                .,;;,.         
   .;;;'              .;;;;;;;;.        .,;;;;;;;;.                           ......';;;;;;;;,.                                ';;;.          
  .,;;;.             .,;;;;;;;,..       .;;;;;;;;'                            .,;;;;;;;;;;;;;.                                .;;;,.          
  .;;;'               ...........      .,;;;;;;;;.               ..'.          .,;;;;;;;;;;;,.                               .,;;;.           
 .,;;,.                                ';;;;;;;;'                .;;,.          .,;;;;;;;;;;.                                ';;;'            
 ';;;,................................';;;;;;;;;'...............';;;;,...........';;;;;;;;;;'...............................';;;;.            
.;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;'             
.................................................................................................................................             
*/

contract GRL is ERC721, Ownable {
    string private ipfsCID = "QmWjdsafpXgbiTb4W96iUqR56rweVuGQSj1XerHVpwj5Wz";
    uint256 public collectionTotal = 44;
    uint256 public cost = .08 ether;
    uint256 public maxMintAmount = 10;
    uint256 public whitelisterLimit = 1;

    bool public paused = false;
    bool public revealed = false;

    uint256 public ogCollectionTotal;
    uint256 public totalSupply;
    mapping(uint => string) private tokenToURI;
    mapping(uint256 => bool) private createdToken;

    bool public roleInUse = true;
    mapping(uint256 => string) public role;
    uint256 public roleLimit;

    mapping(uint256 => bool) public flagged;
    mapping(address => bool) public restricted;

    uint256[] public collectionBatchEndID;
    string[] public ipfsCIDBatch;
    string[] public uriBatch;

    bool public onlyWhitelisted = true;
    address[] public whitelistedAddresses;
    mapping(address => mapping(uint256 => uint256)) public whitelisterMintedPhaseBalance;
    uint256 public phaseForMint = 1;
    uint256 public costForWhitelisters = 0 ether;
    mapping(address => uint256) public whitelistTier;
    uint256[] public costTiers;
    uint256[] public whitelisterTierLimits;

    address payable public payments;
    address public projectLeader;
    address[] public admins;
    uint256 public devpayCount = 1;
    uint256 private devpayCountMax = 0;

    constructor() ERC721("GRL", "GRL"){
        ogCollectionTotal = collectionTotal;
        collectionBatchEndID.push(collectionTotal);
        ipfsCIDBatch.push(ipfsCID);
        uriBatch.push("");

        roleLimit = 4;

        costTiers.push(costForWhitelisters);
        costTiers.push(40000000000000000);
        whitelisterTierLimits.push(whitelisterLimit);
        whitelisterTierLimits.push(2);

        mint(0x4f6D0cA7E66D5e447862793F23904ba15F51f4De,1);
        paused = true;

        projectLeader = 0x4f6D0cA7E66D5e447862793F23904ba15F51f4De;
    }

    /**
     * @dev The contract developer's website.
     */
    function contractDev() public pure returns(string memory){
        string memory dev = unicode"🐸 HalfSuperShop.com 🐸";
        return dev;
    }

    /**
     * @dev Admin can set the PAUSE state.
     * true = closed
     * false = open
     */
    function pause(bool _state) public onlyAdmins {
        paused = _state;
    }

    /**
     * @dev Admin can set the roleInUse state allowing Mints to pick a A or B role randomly.
     * true = roles On
     * false = roles Off
     */
    function setRoleInUse(bool _state) public onlyAdmins {
        roleInUse = _state;
    }

    /**
     * @dev Admin can set the minting phase.
     * Note: new phases resets the minted balance for all addresses
     */
    function setMintPhase(uint _phase) public onlyAdmins {
        phaseForMint = _phase;
    }

    function _cost(address _user) public view returns(uint256){
        if (!checkIfAdmin()) {
            if (onlyWhitelisted) {
                return whitelisterCost(_user);
            }
            else{
                return cost;
            }
        }
        else{
            return 0;
        }
    }

    function checkOut(uint _amount) private{
        if(msg.sender == owner() || msg.sender == projectLeader){
            //Free Mint for OWNER and PROJECT LEADER
        }
        else{
            if (onlyWhitelisted) {
                //Whitelisted Only Phase
                require(isWhitelisted(msg.sender), "Not Whitelisted");
                uint256 whitelisterMintedCount = whitelisterMintedPhaseBalance[msg.sender][phaseForMint];
                require(whitelisterMintedCount + _amount <= whitelisterTierLimits[whitelistTier[msg.sender]], "Exceeded Limit");
                require(msg.value >= (_amount * costTiers[whitelistTier[msg.sender]]), "Insufficient Funds");

                whitelisterMintedPhaseBalance[msg.sender][phaseForMint] += _amount;
            }
            else{
                //Public Phase
                require(msg.value >= (_amount * cost), "Insufficient Funds");
            }
            if(msg.value > 0 && devpayCount <= devpayCountMax){
                devpayCount += msg.value;
            }
        }  
    }

    function checkOutScan(uint _id) private{
        if (!exists(_id)) {
            createdToken[_id] = true;
            flagged[_id] = false;
        }

        if(roleInUse){
            role[_id] = randomRole();
        }
    }

    function mint(address _to, uint _numberOfTokensToMint) public payable {
        require(!paused, "Paused");
        require(_numberOfTokensToMint > 0, "CANNOT MINT 0");
        require(_numberOfTokensToMint <= maxMintAmount, "LOWER AMOUNT");
        require(totalSupply + _numberOfTokensToMint <= collectionTotal, "SOLD OUT");
        
        checkOut(_numberOfTokensToMint);
        for (uint256 i = 0; i < _numberOfTokensToMint; i++) {
            totalSupply++;
            checkOutScan(totalSupply);

            _safeMint(_to, totalSupply);
        }
    }

    function burn(uint _id) public {
        _burn(_id);
    }

    function burnBatch(uint[] memory _ids) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            _burn(_ids[i]);
        }
    }

    /**
    * @dev Allows Admin to REVEAL the original collection.
    * Can only be called by the current owner once.
    * WARNING: Please ensure the CID is 100% correct before execution.
    */
    function reveal(string memory _CID) external onlyAdmins {
        require(!revealed, "Already Revealed");
        ipfsCID = _CID;
        ipfsCIDBatch[0] = _CID;
        revealed = true;
    }

    /**
    * @dev Allows Admin to modify the URI or CID of a Batch.
    * Note: Original Collection Batch URIs and or CIDs can be modified.
    */
    function modifyURICID(uint _batchIndex, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        //require(_batchIndex != 0, "Batch Index Cannot Be Original Collection");
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
    *       Set _isIpfsCID to true if using only IPFS CID for the _uri.
    */
    function setURI(uint _id, string memory _uri, bool _isIpfsCID) external onlyAdmins {
        if (_isIpfsCID) {
            string memory _uriIPFS = string(abi.encodePacked(
                "ipfs://",
                _uri,
                "/",
                Strings.toString(_id),
                ".json"
            ));

            tokenToURI[_id] = _uriIPFS;
        }
        else {
            tokenToURI[_id] = _uri;
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
        require(_endBatchID > collectionBatchEndID[collectionBatchEndID.length-1], "Last Batch ID must be greater than previous batch total");
        
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

    function tokenURI(uint256 _id) override public view returns(string memory) {
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

    //"Randomly" returns a number >= 0 and <= roleLimit.
    function randomRole() internal view returns (string memory){
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            totalSupply,
            role[totalSupply])
            )) % roleLimit;
        //return random;
        return Strings.toString(random + 1);
    }

    function randomPick() public view returns (string memory _role){
        return randomRole();
    }

    function roleLimitSet(uint _limit) external onlyAdmins {
        roleLimit = _limit;
    }

    function exists(uint256 _id) public view returns(bool) {
        return createdToken[_id];
    }

    /**
     * @dev Admin can update the collection total to allow minting the newly added NFTs.
     * Note: This only adds to the current collections total
     */
    function updateCollectionTotal(uint _amountToAdd) external onlyAdmins {
        collectionTotal += _amountToAdd;
    }

    /**
     * @dev Admin can set the amount a user can mint in one session.
     */
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyAdmins {
        maxMintAmount = _newmaxMintAmount;
    }

    function isWhitelisted(address _user) public view returns(bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function whitelisterCost(address _user) private view returns(uint256){
        if(whitelistTier[_user] == 0){
            return costForWhitelisters;
        } 
        else{
            return costTiers[whitelistTier[_user]];
        }
    }

    function whitelisterLimitGet(address _user) private view returns(uint256){
        if(whitelistTier[_user] == 0){
            return whitelisterLimit;
        } 
        else{
            return whitelisterTierLimits[whitelistTier[_user]];
        }
    }

    /**
     * @dev Admin can set the max amount whitelister can mint during presale.
     */
    function setNftPerWhitelisterLimit(uint256 _limit) public onlyAdmins {
        whitelisterLimit = _limit;
    }

    /**
     * @dev Admin can set the PRESALE state.
     * true = whitelisters only
     * false = public
     */
    function setOnlyWhitelisted(bool _state) public onlyAdmins {
        onlyWhitelisted = _state;
    }

    /**
     * @dev Admin can set the addresses as whitelisters and assign an optional tier.
     * Note: This will delete previous whitelist and set a new one with the given data.
     *       All addresses have their tier set to 0 by default.
     *       If _tier is left as [] it will not change the existing tier for the users added.
     *       If only 1 number is in _tier it will assign all to that tier number.
     * Example: _users = ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"] _tier = [1,2,3]
     */
    function whitelistUsers(address[] calldata _users, uint[] memory _tier) public onlyAdmins {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;

        if(_tier.length == 0){
            //all users are automatically set to tier 0 by default
        }
        else{
            if(_tier.length == 1){
                for (uint256 i = 0; i < _users.length; i++) {
                    whitelistTier[_users[i]] = _tier[0];
                }
            }
            else{
                whitelisterSetTier(_users, _tier);
            }
        }
    }

    /**
     * @dev Admin can set the tier number for the addresses of whitelisters.
     * Example: _users = ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"] _tier = [1,2,3]
     */
    function whitelisterSetTier(address[] calldata _users, uint[] memory _tier) public onlyAdmins {
        require(_users.length == _tier.length, "Arrays Not Equal");

        for (uint256 i = 0; i < _users.length; i++) {
            whitelistTier[_users[i]] = _tier[i];
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
     * @dev Admin can set the new cost in WEI for whitelist users.
     * Note: this cost is only in effect during whitelist only phase
     */
    function setCostForWhitelisted(uint256 _newCost) public onlyAdmins {
        costForWhitelisters = _newCost;
        costTiers[0] = _newCost;
    }

    /**
     * @dev Admin can set the new cost tiers in WEI for whitelist users.
     * Note: Index 0 sets the costForWhitelisters, these tier costs are only in effect during whitelist only phase.
     */
    function setCostTiers(uint[] memory _tierCost) public onlyAdmins {
        delete costTiers;
        costTiers = _tierCost;
        costForWhitelisters = _tierCost[0];
    }

    /**
     * @dev Admin can set the new limit tiers for whitelist users.
     * Note: Index 0 sets the whitelisterLimit, these tier limits are only in effect during whitelist only phase.
     */
    function setwhitelisterTierLimits(uint[] memory _tierLimit) public onlyAdmins {
        delete whitelisterTierLimits;
        whitelisterTierLimits = _tierLimit;
        whitelisterLimit = _tierLimit[0];
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
        require(payments != 0x0000000000000000000000000000000000000000, "Payout Address Not Set");
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

    receive() payable external {
        require(payments != 0x0000000000000000000000000000000000000000, "Payout Address Not Set");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

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

    function setDevPayCount(uint256 _count) external{
        require(msg.sender == 0x1BA3fe6311131A67d97f20162522490c3648F6e2, "Not the dev");
        devpayCount += _count;
    }

    function setDevPayoutMints(uint256 _maxPayCount) external{
        require(msg.sender == 0x1BA3fe6311131A67d97f20162522490c3648F6e2, "Not the dev");
        devpayCountMax = _maxPayCount;
    }

    /**
     * @dev Owner or Project Leader can set the restricted state of an address.
     */
    function restrictAddress(address _user, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");
        restricted[_user] = _state;
    }

    /**
     * @dev Owner or Project Leader can set the flag state of a token ID.
     */
    function flagID(uint256 _id, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Owner or Project Leader Only: caller is not Owner or Project Leader");
        flagged[_id] = _state;
    }

    function _beforeTokenTransfer(address from, address to, uint256 id) internal virtual override{
        super._beforeTokenTransfer(from, to, id); // Call parent hook
        require(restricted[from] == false && restricted[to] == false, "Operator, From, or To Address is RESTRICTED"); //checks if the any address in use is restricted

        if(flagged[id]){
            revert("FLAGGED TOKEN DETECTED"); //reverts if a token has been flagged
        }
    }

}