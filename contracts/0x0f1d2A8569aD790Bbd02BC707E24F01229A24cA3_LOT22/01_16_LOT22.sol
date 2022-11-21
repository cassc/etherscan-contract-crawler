// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";

/*

LLLLLLLLLLL                  OOOOOOOOO     TTTTTTTTTTTTTTTTTTTTTTT      222222222222222     222222222222222    
L:::::::::L                OO:::::::::OO   T:::::::::::::::::::::T     2:::::::::::::::22  2:::::::::::::::22  
L:::::::::L              OO:::::::::::::OO T:::::::::::::::::::::T     2::::::222222:::::2 2::::::222222:::::2 
LL:::::::LL             O:::::::OOO:::::::OT:::::TT:::::::TT:::::T     2222222     2:::::2 2222222     2:::::2 
  L:::::L               O::::::O   O::::::OTTTTTT  T:::::T  TTTTTT                 2:::::2             2:::::2 
  L:::::L               O:::::O     O:::::O        T:::::T                         2:::::2             2:::::2 
  L:::::L               O:::::O     O:::::O        T:::::T                      2222::::2           2222::::2  
  L:::::L               O:::::O     O:::::O        T:::::T                 22222::::::22       22222::::::22   
  L:::::L               O:::::O     O:::::O        T:::::T               22::::::::222       22::::::::222     
  L:::::L               O:::::O     O:::::O        T:::::T              2:::::22222         2:::::22222        
  L:::::L               O:::::O     O:::::O        T:::::T             2:::::2             2:::::2             
  L:::::L         LLLLLLO::::::O   O::::::O        T:::::T             2:::::2             2:::::2             
LL:::::::LLLLLLLLL:::::LO:::::::OOO:::::::O      TT:::::::TT           2:::::2       2222222:::::2       222222
L::::::::::::::::::::::L OO:::::::::::::OO       T:::::::::T           2::::::2222222:::::22::::::2222222:::::2
L::::::::::::::::::::::L   OO:::::::::OO         T:::::::::T           2::::::::::::::::::22::::::::::::::::::2
LLLLLLLLLLLLLLLLLLLLLLLL     OOOOOOOOO           TTTTTTTTTTT           2222222222222222222222222222222222222222

*/

contract LOT22 is ERC1155, Ownable, DefaultOperatorFilterer {
    string public name = "LOT 22";
    string public symbol = "LOT22";
    string private ipfsCID = "CID";
    string private hiddenCIDorURI = "ipfs://QmVeDNugK48LQGvTggJvAMTHrCT83L6f1adTqcPqcuYUEU/";
    uint256 public collectionTotal = 5555;
    uint256 private cost = 0.012 ether;
    uint256 public maxMintAmount = 20;
    uint256 public maxBatchMintAmount = 20;
    string private storefront = "ipfs://QmV4X4ZNq4yP8L2ftjR3uHq784zXD32k94x67Y1QyyexhT/storefront.json";


    bool public paused = true;
    mapping(uint256 => bool) private mintInOrder;

    bool private useMintOnDate = false;
    uint public mintDateStart;

    uint256 public randomCounter = 1;
    mapping(uint => string) private tokenToURI;
    mapping(uint256 => uint256) private currentSupply;
    mapping(uint256 => bool) private hasMaxSupply;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => bool) private hasMaxSupplyForBatch;
    mapping(uint256 => uint256) public maxSupplyForBatch;
    mapping(uint256 => bool) private createdToken;

    bool public roleInUse = false;
    mapping(uint256 => string) public role;
    uint256 public roleLimitMin;
    uint256 public roleLimitMax;

    mapping(uint256 => uint256[]) public requirementTokens;
    mapping(uint256 => uint256[]) public batchRequirementTokens;

    uint256[] public collectionBatchEndID;
    uint256[] public tokenNextToMintInBatch;
    string[] public ipfsCIDBatch;
    string[] public uriBatch;
    uint256[] public batchCost;
    mapping(uint256 => uint256) public batchTriggerPoint;
    mapping(uint256 => uint256) public batchCostNext;
    mapping(uint256 => bool) public pausedBatch;
    mapping(uint256 => bool) public revealedBatch;

    address payable public payments;
    address public projectLeader;
    address[] public admins;

    mapping(uint256 => bool) public bindOnMintBatch; //BOM or BOMB are the tokens that cannot be moved after being minted
    mapping(uint256 => bool) public flagged; //flagged tokens cannot be moved
    mapping(address => bool) public restricted; //restricted addresses cannot move tokens

    constructor() ERC1155(""){
        collectionBatchEndID.push(55);
        ipfsCIDBatch.push(ipfsCID);
        uriBatch.push("");
        maxSupply[1] = 1;
        hasMaxSupply[1] = true;
        createdToken[1] = true;
        currentSupply[1] = 1;
        tokenNextToMintInBatch.push(2);
        _mint(msg.sender, 1, 1, "");

        mintInOrder[0] = true;
        batchCost.push(cost);
    }

    /**
     * @dev The contract developer's website.
     */
    function contractDev() public pure returns(string memory){
        string memory dev = unicode"🐸 https://www.halfsupershop.com/ 🐸";
        return dev;
    }

    /**
     * @dev Admin can set the PAUSE state for all or just a batch.
     * true = closed to Admin Only
     * false = open for Presale or Public
     */
    function pause(bool _pauseAll, uint _fromBatch, bool _state) public onlyAdmins {
        if(_pauseAll){
            paused = _state;
        }
        else{
            pausedBatch[_fromBatch] = _state;
        }
        
    }

    /**
     * @dev Admin can set the REVEALED state for a batch.
     * true = revealed
     * false = hidden
     */
    function reveal(uint _fromBatch, bool _state) public onlyAdmins {
        revealedBatch[_fromBatch] = _state;
    }

    /**
     * @dev Admin can set the DATE to mint.
     * true = use date
     * false = don't use date
     * _unixDate = unix date used if true
     */
    function setMintDate(bool _state, uint _unixDate) public onlyAdmins {
        useMintOnDate = _state;
        if(_state){
            //future start date
            mintDateStart = _unixDate;
        }
    }

    /**
     * @dev Admin can set the roleInUse state allowing Mints to pick a role randomly.
     */
    function setRoleInUse(bool _state) public onlyAdmins {
        roleInUse = _state;
    }

    /**
     * @dev Admin can set the mintInOrder state for a batch.
     */
    function setMintInOrder(bool _state, uint _fromBatch) public onlyAdmins {
        mintInOrder[_fromBatch] = _state;
    }

    /**
     * @dev Admin can set the tokenNextToMintInBatch.
     */
    function setTokenNextToMintInBatch(uint _id, uint _fromBatch) public onlyAdmins {
        tokenNextToMintInBatch[_fromBatch] = _id;
    }

    /**
     * @dev Admin can set the new cost for the batch in WEI.
     * 1 ETH = 10^18 WEI
     * Use http://etherscan.io/unitconverter for conversions.
     */
    function setCost(uint256 _newCost, uint _fromBatch) public onlyAdmins {
        batchCost[_fromBatch] = _newCost;
    }

    /**
     * @dev Admin can set the cost to change to for a batch after a specific token is minted.
     */
    function setCostNextOnTrigger(uint256 _nextCost, uint _triggerPointID, uint _fromBatch) public onlyAdmins {
        batchTriggerPoint[_fromBatch] = _triggerPointID;
        batchCostNext[_fromBatch] = _nextCost;
    }

    function _cost(uint _batchID) public view returns(uint256){
        if (!checkIfAdmin()) {
            return batchCost[_batchID];
        }
        else{
            return 0;
        }
    }

    function checkOut(uint _amount, uint _batchID) private {
        if (!checkIfAdmin()) {
            if(useMintOnDate){
                require(block.timestamp >= mintDateStart, "Not Mint Date Yet");
            }
            //Required Funds
            require(msg.value >= (_amount * _cost(_batchID)), "Insufficient Funds");
        }
    }

    function checkOutScan(uint _id, uint _fromBatch) private{
        if (!exists(_id)) {
            createdToken[_id] = true;
            flagged[_id] = false;
            if(mintInOrder[_fromBatch]){
                maxSupply[_id] = 1;
                hasMaxSupply[_id] = true;
                currentSupply[_id] = 1;
            }
        }

        if(roleInUse){
            role[_id] = randomRole();
        }

        if(batchCost[_fromBatch] != batchCostNext[_fromBatch] && tokenNextToMintInBatch[_fromBatch] >= batchTriggerPoint[_fromBatch]){
            batchCost[_fromBatch] = batchCostNext[_fromBatch];
        }
        randomCounter++;
    }

    function checkInBatch(uint _id, uint _fromBatch) public view returns(bool){
        if(_fromBatch != 0 && _id <= collectionBatchEndID[_fromBatch] && _id > collectionBatchEndID[_fromBatch - 1]){
            return true;
        }
        if(_fromBatch <= 0 && _id > 0 && _id <= collectionBatchEndID[_fromBatch]){
            return true;
        }
        return false;
    }

    /**
     * @dev Allows Admins, Whitelisters, and Public to Mint NFTs in Order from a collection batch.
     */
    function _mintInOrder(uint _numberOfTokensToMint, uint _fromBatch) public payable {
        require(mintInOrder[_fromBatch], "Requires mintInOrder");
        require(!paused, "Paused");
        require(!pausedBatch[_fromBatch], "Paused Batch");
        require(!exists(collectionBatchEndID[_fromBatch]), "Sold Out");
        require(_fromBatch >= 0, "From Batch Required");
        require(_numberOfTokensToMint + tokenNextToMintInBatch[_fromBatch] - 1 <= collectionBatchEndID[_fromBatch], "Please Lower Amount");

        checkOut(_numberOfTokensToMint, _fromBatch);
        _mintBatchTo(msg.sender, _numberOfTokensToMint, _fromBatch);
    }

    /**
     * @dev Allows Admins to Mint NFTs in Order from 1-collectionTotal to an address.
     * Can only be called by Admins even while paused.
     */
    function _mintInOrderTo(address _to, uint _numberOfTokensToMint, uint _fromBatch) external onlyAdmins {
        require(mintInOrder[_fromBatch], "Requires mintInOrder");
        require(!exists(collectionBatchEndID[_fromBatch]), "Sold Out");
        require(_numberOfTokensToMint + tokenNextToMintInBatch[_fromBatch] - 1 <= collectionBatchEndID[_fromBatch], "Please Lower Amount");

        _mintBatchTo(_to, _numberOfTokensToMint, _fromBatch);
    }

    function _mintBatchTo(address _to, uint _numberOfTokensToMint, uint _fromBatch)private {
        uint256[] memory _ids = new uint256[](_numberOfTokensToMint);
        uint256[] memory _amounts = new uint256[](_numberOfTokensToMint);
        for (uint256 i = 0; i < _numberOfTokensToMint; i++) {
            uint256 _id = tokenNextToMintInBatch[_fromBatch];
            
            checkOutScan(_id, _fromBatch);

            _ids[i] = tokenNextToMintInBatch[_fromBatch];
            _amounts[i] = 1;
            tokenNextToMintInBatch[_fromBatch]++;
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
    * @dev Allows Owner, Whitelisters, and Public to Mint a single NFT.
    */
    function mint(address _to, uint _id, uint _amount, uint _fromBatch) public payable {
        require(!mintInOrder[_fromBatch], "Requires mintInOrder False");
        require(checkInBatch(_id, _fromBatch), "ID Must Be From Batch");
        require(!paused, "Paused");
        require(!pausedBatch[_fromBatch], "Paused Batch");
        require(canMintChecker(_id, _amount), "CANNOT MINT");

        checkOut(_amount, _fromBatch);
        checkOutScan(_id, _fromBatch);
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
    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts, uint _fromBatch) public payable {
        require(!mintInOrder[_fromBatch], "Requires mintInOrder False");
        require(!paused, "Paused");
        require(!pausedBatch[_fromBatch], "Paused Batch");
        require(_ids.length <= maxMintAmount, "Too Many IDs");
        require(_ids.length == _amounts.length, "IDs and Amounts Not Equal");
        require(canMintBatchChecker(_ids, _amounts), "CANNOT MINT BATCH");

        uint256 _totalBatchAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(checkInBatch(_ids[i], _fromBatch), "IDs Must Be From Same Batch");
            _totalBatchAmount += _amounts[i];
        }
        require(_totalBatchAmount <= maxBatchMintAmount, "Batch Amount Limit Exceeded");

        checkOut(_totalBatchAmount, _fromBatch);
        
        for (uint256 k = 0; k < _ids.length; k++) {
            uint256 _id = _ids[k];
            checkOutScan(_id, _fromBatch);
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
    function adminMint(address _to, uint _id, uint _amount, uint _fromBatch) external onlyAdmins {
        require(!mintInOrder[_fromBatch], "Requires mintInOrder False");
        checkOutScan(_id, _fromBatch);
        currentSupply[_id] += _amount;
        _mint(_to, _id, _amount, "");
    }

    /**
     * @dev Allows Admin to Mint multiple NEW NFTs.
     */
    function adminMintBatch(address _to, uint[] memory _ids, uint[] memory _amounts, uint _fromBatch) external onlyAdmins {
        require(!mintInOrder[_fromBatch], "Requires mintInOrder False");
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            checkOutScan(_id, _fromBatch);
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
    */
    function modifyURICID(uint _batchIndex, string memory _uri, bool _isIpfsCID) external onlyAdmins {
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
    *      Set _isIpfsCID to true if using only IPFS CID for the _uri.    
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
            emit URI(_uriIPFS, _id);
        }
        else {
            tokenToURI[_id] = _uri;
            emit URI(_uri, _id);
        }
    }

    /**
    * @dev Allows Admin to create a new Batch and set the URI or CID of that batch of tokens.
    * Note: Set _isIpfsCID to true if using only IPFS CID for the _uri.
    *       Set _isMintInOrder if the batch should be minted in order.
    *       Example URI structure if _endBatchID = 55 and if _isIpfsCID = false and if _uri = BASEURI.EXTENSION
    *       will output: BASEURI.EXTENSION/55.json for IDs 55 and below until it hits another batch end ID
    */
    function createBatchAndSetURI(uint _endBatchID, string memory _uri, bool _isIpfsCID, bool _isMintInOrder) external onlyAdmins {
        require(_endBatchID > collectionBatchEndID[collectionBatchEndID.length-1], "Last Batch ID must be greater than previous batch total");
        
        tokenNextToMintInBatch.push(collectionBatchEndID[collectionBatchEndID.length-1] + 1); //set mint start ID for batch

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

        batchCost.push(cost);
        if(_isMintInOrder){
            setMintInOrder(true, collectionBatchEndID.length-1);
        }
    }

    function uri(uint256 _id) override public view returns(string memory){
        bool _batched = true;
        uint256 _batchID;
        string memory _CIDorURI = string(abi.encodePacked(
            "ipfs://",
            ipfsCID,
            "/"
        ));
        string memory _HIDDEN = string(abi.encodePacked(
            hiddenCIDorURI,
            "hidden",
            ".json"
        ));

        if(createdToken[_id]){
            if (_id > 0 && _id <= collectionTotal) {
                if(keccak256(abi.encodePacked((tokenToURI[_id]))) != keccak256(abi.encodePacked(("")))){
                    return tokenToURI[_id];
                }

                for (uint256 i = 0; i < collectionBatchEndID.length; ++i) {
                    if(_id <= collectionBatchEndID[i]){
                        if(keccak256(abi.encodePacked((ipfsCIDBatch[i]))) != keccak256(abi.encodePacked(("")))){
                            _CIDorURI = string(abi.encodePacked(
                                "ipfs://",
                                ipfsCIDBatch[i],
                                "/"
                            ));
                            _batchID = i;
                            break;
                        }
                        if(keccak256(abi.encodePacked((uriBatch[i]))) != keccak256(abi.encodePacked(("")))){
                            _CIDorURI = string(abi.encodePacked(
                                uriBatch[i],
                                "/"
                            ));
                            _batchID = i;
                            break;
                        }
                        continue;
                    }
                    else{
                        //_id was not found in a batch
                        continue;
                    }
                }

                if(_id > collectionBatchEndID[collectionBatchEndID.length - 1]){
                    _batched = false;
                }

                if(_batched && revealedBatch[_batchID]){
                    if(keccak256(abi.encodePacked((role[_id]))) == keccak256(abi.encodePacked(("")))){
                        //no role
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
                else{
                    //no URI set default to hidden
                    return _HIDDEN;
                }
            }
            //no URI set default to hidden
            return _HIDDEN;
        }
        else{
            //hidden
            return _HIDDEN;
        }
    }

    //"Randomly" returns a number >= roleLimitMin and <= roleLimitMax.
    function randomRole() internal view returns (string memory){
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            msg.sender,
            randomCounter,
            role[randomCounter - 1])
            )) % roleLimitMax;
        //return random;
        if(random < roleLimitMin){
            return Strings.toString(roleLimitMax - (random + 1));
        }
        else{
            return Strings.toString(random + 1);
        }
    }

    function randomPick() public view returns (string memory _role){
        return randomRole();
    }

    /**
    * @dev Admin can set the min and max of the role limit. 
    * Note: min value is excluded while max is included.
    */
    function roleLimitSet(uint _min, uint _max) external onlyAdmins {
        roleLimitMin = _min;
        roleLimitMax = _max;
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
     */
    function updateCollectionTotal(uint _newCollectionTotal) external onlyAdmins {
        collectionTotal = _newCollectionTotal;
    }

    /**
     * @dev Admin can set the amount of NFTs a user can mint in one session.
     */
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyAdmins {
        maxMintAmount = _newmaxMintAmount;
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
        //splitter
        (bool success, ) = payable(payments).call{ value: address(this).balance } ("");
        require(success);
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

    /**
     * @dev Admin can set the bind on mint state for a batch.
     * Note: Bound tokens cannot be moved once minted.
     */
    function setBindOnMintBatch(bool _state, uint _batchID) public onlyAdmins {
        bindOnMintBatch[_batchID] = _state;
    }

    /**
     * @dev Check if an ID is in a bind on mint batch.
     */
    function bindOnMint(uint _id) public view returns(bool){
        uint256 _batchID;
        for (uint256 i = 0; i < collectionBatchEndID.length; i++) {
            if(i != 0 && _id <= collectionBatchEndID[i] && _id > collectionBatchEndID[i - 1]){
                _batchID = i;
                break;
            }
            if(i <= 0 && _id > 0 && _id <= collectionBatchEndID[i]){
                _batchID = i;
                break;
            }
        }
        return bindOnMintBatch[_batchID];
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     */
    function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override{
        super._afterTokenTransfer(operator, from, to, ids, amounts, data); // Call parent hook

        for (uint256 i = 0; i < ids.length; i++) {
            if(bindOnMint(ids[i])){
                flagged[ids[i]] = true;
            }
        }
    }

    /**
    * @dev Allows Admin to set the storefront URI or CID.
    */
    function setStoreFrontURIorCID(string memory _URIorCID) external onlyAdmins {
        storefront = _URIorCID;
    }

    function contractURI() public view returns (string memory) {
        return storefront;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator()
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator() {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

}