// SPDX-License-Identifier: MIT

pragma solidity ^ 0.8.18;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol";
import "./DefaultOperatorFilterer.sol";

/*
                                                         .-==++*****+=-:.                                                                             
                                                   .:+#%@@@@@@@@@@@@@@@@@%#=:.                                                                        
                                              .:+#%@@@##**+====----===++**%@@@%*-               ..:::----:::.                                         
                                           -*%@@@%#+------------------------=*%@@%+.      .-+#%%@@@@@@@@@@@@@@%%*=:.                                  
                                         :#@@@@#=:----------------------------:-%@@@+ .=*%@@@@@%##*+++++++**#%%@@@@@%*-.                              
                                      -+%@@#+=--------:::.:----------==----------+#@@%@@%#*+=-------------------=+*#%@@@%*=.                          
                                    .#@@@#-----------:.::-----::=*#@@@@+:--------%@@@%+-:-----------------------------*%@@@%=.                        
                                   =%@@*-:--------:-------:-=*#@@%@@#=:----------#@%+---------------::::---------------:=#@@@%+.                      
                                 =%@@#----------:::---=+*#%@@@%#*=--:-------------------------:...............:::----------*@@@%=                     
                                [email protected]@@+------------:-=*%@@@@%@*-::----------------------------------------:::.........:--------#@@@+.                   
                               [email protected]@#---------:-=+#%@@@%@*[email protected]#%:----------------------------------------------:::......:------:=%@@*:                  
                              *@@+:-----::=#@@@@%#+%@##:-:%[email protected]+:--------------------------------------------------:......-------:%@@*:                 
                             [email protected]@#:-----:*@@@%#*=-:*@#%-::=#[email protected]:------------------------------..:--------------------....:--------*@@@+                 
                            :%@@=-------:-=*%#=::[email protected]@%%:--%%@*:---------*#*=----------:....-:..-----------------------:--:[email protected]@@#:                
                            *@@@:-----------:[email protected]%:@@+%*-:*@@@-:-:::----%@@%%---------:.....-::--------------------------...:------%@@@-                
                        .:=+%@@@%%=:---------:[email protected]%@%#@=-:@@#%::-#%#=:-+%%@-#-:------:.....:-----------------------------....-----:#@@@=                
                  .:=*#%@@@%%%%###=:----------:[email protected]@=%@-:[email protected]##+=#@@#@*:-%@#-###*+:----.....--------------------------------...-----:#@@@=                
                -#@@@@#*+--:-------------------:#%[email protected]%::%@+#%*#%[email protected]@+.#@%*@+*@@#:----...:-------=-:[email protected]@@%-                
             -+%@@#*=--------------------------:%%#@*:[email protected]@+%%@+:#@@:[email protected]%@*-+%@%----------------%@@#:[email protected]@@*.                
           [email protected]@@@+:-----------------------------:@@@@=:%%##@@=::#@%:*@%::#@%*:[email protected]@@@+------------------------------:%@@#+                 
          #@@@*--------:..:--------------------:@#@@-:@%%#@+:-:#%#[email protected]*-%@@*:[email protected]%#@------------------------------:*@@%+.                 
       .+%@%+-------::[email protected]#@%:[email protected]@*#%:--:=%%#++#%%+=----------------:%@@@*:---------------==-----------:*@@@#*-                 
      -%@@*:------:......:[email protected][email protected]*:[email protected]@%@+----:%@@#:::--==-:------------:[email protected]%%%:------------:-:[email protected]@@------------=*@@@@%+:              
     :@@@%-------.....:-------------------.----:@%@+:-#@[email protected]=---:*@@@##%@@@@@@%-:----------:%@@@+:-:+#+----:*@#:*@@@@--------------:=*@@@@#-            
    .#@@+:------....:----------------:...-.----:#%@*:----:-=+*#@%@%%#*++==---+----------:[email protected]@*@:--%@@%%:--:@@*%@@#@@-:----------------=#@@@%=          
   :%@@=:------...:------------------:...--------:-----:=*@@@@@@@#::----------------:==-:%@@@+::##@%:%:-:[email protected]##@@+:+%@*-----------------:-#@@@#-        
  :%@@=:------...--------------------:..:------------=#@@%*+=%@%@-:---=*##*-:*#+=-:+%@@@#@@#@-:[email protected]@*=%*#*=#@%%@+:--:--------------:::------*@@%*-      
 .#@@#:------...:------------:::::----::------------:#@+-:-:*@@@#:--:[email protected]@@@#::*@@=:*@%@#:[email protected]@%#:[email protected]@%%%-#@@*%@%%#:-------------------:[email protected]@@%-     
 [email protected]@@+------:..:----------:=*%%%@%*+-:---------------:#%-:[email protected]@[email protected]*--:[email protected]%@%@*--::::[email protected]#*%:[email protected]@@%[email protected]%@*:[email protected]@#[email protected]@@@:[email protected]@@#:    
.#@@@-------:..---------:=%@%%*+=-=*@%=:------------:#%%@*:*@@@@=-:*@@@*:==--###:%@#@[email protected]@@%@-:#@%--#@#*:[email protected]@@+:-----------------------..:----:[email protected]@@*=   
=%@@@-------:.:--------:%@@%==*=---:[email protected]@+:--:-------:#@@[email protected][email protected]@@@@-:[email protected]@@=:---:#@#@:@#%@[email protected]@@@%%::*@*[email protected]@@+---::--------------------------:...:[email protected]@@*+  
[email protected]@@%:------:.--------:%@%#:*@@@+---:@@%:-=#*=:---:#@%@::%%@%#@*:--*#@%*=-:[email protected]%#%:@[email protected]##@@@@+#:-:*@@@@@+::::---:------------------------....----:[email protected]@%+= 
[email protected]@@%:-------:[email protected]@@#-*@@@#:---:%@@::%%@=:---%@@%+::[email protected]@#@@=----:--%@@*[email protected]%@+:#+%@@*[email protected]@%#:--:[email protected]%@@##%@@@@%%#=----------------------:...:----:%@@*+.
+%@@%----------------*@%#:[email protected]#@@:----:%@%:*%%%:[email protected]@@@#:--:@%[email protected]#:-----:#@@@#[email protected]@@-----+=:[email protected]@@*:-+#@%%@@%*+=--::::=-:+*+----:------------:....-----*@@%+-
=%@@@---------:.----:%@#::#@%@=:---:[email protected]@[email protected]@@=:--%%@@@#:--:%%%@+:---:-#@%@@=-=++--------:%@@%@@@@@@@#:------------:%@@=-:=%@%*---------:[email protected]@@*=
:*@@@=---------.:---:#@=:[email protected]%@*:----:@@#.*@@@-:[email protected]@-%@@+---:%%@@-:#**%@@*##-------------:[email protected]@@%[email protected]%@@-------------:[email protected]*#=:[email protected]%@[email protected]+:-------....:[email protected]@@*+
 +%@@*:---------:-----*+:+%%@-:---:#@@*.*@@%:*@@+:%@@+---:*@@%:[email protected]%@%*+-:------------:*@@#=+::*@@@*:------:-----:%@@%:[email protected]%@#[email protected]::[email protected]@@*+
 :*@@@------------------:@%@%:---:#@@*-:[email protected]@@%@%+-:+%@+----*@@@-:#@@@:-----------------:-*#=-:[email protected]@#@::@%#::*@*:[email protected]%@[email protected]@@*+#*@@%-----:...:------*@@%++
  -*@@@----------------:[email protected]@@*:---%@@@=----=+*=:----::----:%@@%::@**%:-------------:-==:-:[email protected]=:*@@@+::=*=:[email protected]@#:--:#@@#:[email protected]%@@#[email protected]@@#:----:.:-------:#@@#++
   =*@@%---------------:[email protected]@@+:-:#@@@=:------------------:[email protected]+%*[email protected]#@*:------------:*@%@@*-:*#:@@@@------:[email protected]%#:[email protected]*@-:*%@@=:%*@%:---------------:@@@*+=
    -#@@@*--------------:%@@*-+%%#@##%##+---------------:#@#@=:%@@@-:[email protected]@@@+=##::%*@@%%::[email protected]%-:[email protected]%#:--%@%=::#@#:=%@#+:----:.:--------:#@@#+*-
     -*@@@#:-------------:#@@@@@@%%#@=*@@@-------------:[email protected]@@%:[email protected]%%@:[email protected]@@*:---:%*@#:-----:#@@#@*:[email protected]@%::[email protected]%#[email protected]@@-:[email protected]**@%*:-------:--------:%@@#+**.
      :+#%@@*[email protected]@@%=::*@@*:------------:*@#@#.*@%@*:-=%@@+%:--:*@@+:[email protected]%[email protected]+:[email protected]%#:--%@@#@@@=-----=+++------------------=%@@%+*+: 
        .=#@@@@#------------:*@@@+:[email protected]@*:------:--::--:%@%@=:%@*@=::%%@-=%--:[email protected]@+:----:*[email protected]%@@-:[email protected]@*:--:=*##+:--------------------------:*@@@%**+.  
          -*%@@@@#+-:------:[email protected]@+*:----==:------:##@@#=:[email protected]@*@:[email protected]@@@-:[email protected]@=*@*@@+#@%:-----%@*:[email protected]%%@-:[email protected]@*----------------------------------:-#@@@#+*+.   
           .=*%@@%@@@[email protected]@*----------------%@#[email protected]%[email protected]@%%:[email protected]*%%:[email protected]@%%*-%@@[email protected]%#:[email protected]%=:[email protected]@@%:---------------------*+=-------------=*%@@%#***=     
            +%@@#:[email protected]@*:-----------:[email protected]@@%%::[email protected]%.*@+%*[email protected]%@*.*@@#:[email protected]#@[email protected]@*--:*@*:---:#@@%:[email protected]@%:-------:-=*%@@@@#***+:      
           -#@@@[email protected]@+:-------::[email protected]@@@%#::#@#.#@%@[email protected]@@+.%@#[email protected]@%-::*@*:*@@*:------=+*--------------------:#@@*:---==+*%@@@@@%*+**+:        
           [email protected]@@%----------*@%*-------+%%%:[email protected]%@%@#:#%++:#@%@-:[email protected]@@-:[email protected]##@%%-----=*#*+=----------------:::...--::----=#@@@@@@@@@@@@%%##*+**+-.          
          .#@%@+---------:####:-----:*@@%:#@@%:###@@#-:#@%@::[email protected]@@:---+*=:--------------------::::--:......:[email protected]@@@***#******++***=:.              
          .%@@@----------:%%@+:-----:%@@=:*@@@::#%@*:-:[email protected]@%:-:**#--------------------:::::.......---:--------=+*%@@%#*+:.::::::::..                   
          .%@@@:---------:%%@+:----:#@@*:[email protected]%@#%@*=:---:+**:-------::::....--------...........::--------:-=*@@@@@#*+*=                                
          .%@@@----------:%%@+:---:[email protected]@#:---=**##+:---------------......::----------:::::::---------::-+#%@@@@@%*****=                                 
           #@@@=---------:##@*:---*@@#:---------------::..:-------::--------------------------=++*#%@@@@%%##*+**+-:                                   
           [email protected]@@%[email protected]@%:[email protected]@@#------::...::----...:-----=---:::::::::::::-----=+**#%@@@@@@@@%%#*++*****+-                                      
           :#@@@=----------%@@*[email protected]@%=:----..........----:----:[email protected]@@@@@%%%%%%%%%%%%@@@@@@@@@@@@%%%#**++*******=:                                         
            -%@@#:---------:-=+++-:---:............-----------=#@@@%%%%%%%%%%%%%%######**************+=-:.                                            
             -#@@#:-------------------...........:----------:=%@@%*+********++*****************+=-:.                                                  
              :*@@%+------------------:......:::-----------*%@@@#+*=..:::---=========---:::..                                                         
                [email protected]@@@+:--------------------------------:=#@@@%*+*+.                                                                                   
                 +%@@@#=----------------------------:-#@@@@%*+**-                                                                                     
                  .-*%@@@#*=--------------------=+*#%@@%%#***=-.                                                                                      
                     :*#%@@@@@%#*+===--===+*#%%@@@@@%#*+**+:                                                                                          
                       .-=*%%@@@@@@@@@@@@@@@@@@@%#**+**+-.                                                                                            
                           .:-=+*##########****++==-:.     
*/
/// @author developer's website 🐸 https://www.halfsupershop.com/ 🐸
contract TheOutsiderCollective is ERC1155, Ownable, DefaultOperatorFilterer {
    string public name = "The Outsider Collective";
    string public symbol = "TOC";
    string private hiddenURI;
    uint256 public collectionEndID = 1000;
    uint256 private cost = 0.0444 ether;
    uint256 public maxMintAmount = 20;
    uint256 public maxBatchMintAmount = 20;
    mapping(uint256 => uint256) public batchLimit;
    mapping(address => mapping(uint256 => uint256)) public walletMinted;

    bool public paused = true;
    mapping(uint256 => bool) public pausedBatch;

    mapping(uint256 => uint) private batchMintDateStart;

    uint256 public randomCounter = 1;
    mapping(uint => string) private tokenToURI;
    mapping(uint256 => uint256) private currentSupply;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public maxSupplyForBatch;
    mapping(uint256 => bool) private createdToken;
    mapping(uint256 => bool) private mintInOrder;

    mapping(uint256 => bool) public rollInUse;
    mapping(uint256 => string) public roll;
    mapping(uint256 => uint256) public rollLimitMin; //excluded
    mapping(uint256 => uint256) public rollLimitMax; //included

    mapping(uint256 => uint256[]) public requirementTokens;
    mapping(uint256 => uint256[]) public requirementTokenAmounts;
    mapping(uint256 => uint256[]) public batchRequirementTokens;
    mapping(uint256 => uint256[]) public batchRequirementTokenAmounts;

    uint256[] public collectionBatchEndID;
    uint256[] public tokenNextToMintInBatch;
    string[] public ipfsCIDBatch;
    string[] public uriBatch;
    uint256[] public batchCost;
    mapping(uint256 => uint256) public batchTriggerPoint;
    mapping(uint256 => uint256) public batchCostNext;
    mapping(uint256 => bool) public revealedBatch;
    
    struct Tier {
        uint256 tLimit;
        uint256 tCost;
        bytes32 tRoot;
    }
    Tier[] public tiers;
    string public tierURI;
    mapping(address => mapping(uint256 => uint256)) public tierMinted;

    address payable public payments;
    address public projectLeader;
    address[] public admins;

    mapping(uint256 => bool) public bindOnMintBatch; //BOM or BOMB are the tokens that cannot be moved after being minted
    mapping(uint256 => bool) public flagged; //flagged tokens cannot be moved
    mapping(address => bool) public restricted; //restricted addresses cannot move tokens

    /* 
    address(0) = 0x0000000000000000000000000000000000000000

    ERROR KEY:
    !D = Not The Date
    BLE = Batch Limit Exceeded
    WLE = Wallet Limit Exceeded
    PWLE = Presale Wallet Limit Exceeded
    !WL = Not Whitelisted
    LE = Limit Exceeded
    $? = Insufficient Funds
    !Batch = Not A Batch
    !B = ID Not Found in Batch
    OOS = Out Of Stock
    !MINT = Cannot Mint
    !A = Amount Cannot Be 0
    MMA = Max Mint Amount Exceeded
    !ID = ID Does Not Exist Yet
    IDs> = IDs Cannot Exceed Max Mint Amount
    IDs != Amounts = IDs List Does Not Match Amounts List
    EID > PB? = End ID Parameter Must Be Greater Than Previous Batch End ID
    MIN <= MAX? = Min Must Be Less Than Or Equal To Max
    NOoPL = Not Owner Or Project Leader
    FID = Flagged ID
    */

    constructor() ERC1155(""){
        collectionBatchEndID.push(collectionEndID);
        ipfsCIDBatch.push("");
        uriBatch.push("");
        maxSupply[1] = 1;
        createdToken[1] = true;
        currentSupply[1] = 1;
        tokenNextToMintInBatch.push(2);
        _mint(msg.sender, 1, 1, "");

        mintInOrder[0] = true;
        batchCost.push(cost);
        batchCostNext[0] = cost;
    }

    /**
    @dev Admin can set the PAUSE state for all or just a batch.
    @param _pauseAll Whether to pause all batches.
    @param _fromBatch The ID of the batch to pause.
    @param _state Whether to set the batch or all batches as paused or unpaused.
    true = closed to Admin Only
    false = open for Presale or Public
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
    @dev Admin can set the state of an OPTION for a batch.
    @param _option The OPTION to set the state of:
    1 = Set the REVEALED state.
    2 = Set the USING ROLLS state allowing Mints to pick a roll randomly within a set range.
    3 = Set the MINT IN ORDER state.     
    4 = Set the BIND on mint state. Note: Bound tokens cannot be moved once minted.
    //5 = Set the PRESALE state.
    @param _state The new state of the option:
    true = revealed, on
    false = hidden, off
    @param _fromBatch The batch ID to update the state for.
    */
    function setStateOf(uint _option, bool _state, uint _fromBatch) public onlyAdmins {
        if(_option == 1){
            revealedBatch[_fromBatch] = _state;
            return;
        }
        if(_option == 2){
            rollInUse[_fromBatch] = _state;
            return;
        }
        if(_option == 3){
            mintInOrder[_fromBatch] = _state;
            return;
        }
        if(_option == 4){
            bindOnMintBatch[_fromBatch] = _state;
            return;
        }
        // if(_option == 5){
        //     presaleBatch[_fromBatch] = _state;
        //     return;
        // }
    }

    /**
    @dev Allows an admin to set a start date for minting tokens for a specific batch.
    Tokens can only be minted after this date has passed.
    @param _batch The ID of the batch to set the mint date for.
    @param _unixDate The Unix timestamp for the start date of minting.
    @notice The Unix timestamp must be in the future, otherwise the function will revert.
    */
    function setMintDate(uint256 _batch, uint _unixDate) public onlyAdmins {
        require(_unixDate > block.timestamp, "Date Already Past");
        batchMintDateStart[_batch] = _unixDate;
    }

    /**
    @dev Sets the ID of the end or next token to be minted in a batch by an Admin.
    @param _updateEndID flag to indicate if updating the collectionBatchEndID.
    @param _id uint ID of the end of batch or next token to be minted.
    @param _fromBatch uint Batch number of the batch in which to edit.
    Note:
    This will also set collectionEndID if _fromBatch is the last Batch in the collection.
    Requirements:
    Only accessible by admins.
    */
    function setNextOrEndID(bool _updateEndID, uint _id, uint _fromBatch) external onlyAdmins {
        if (_updateEndID) {
            require(_fromBatch < collectionBatchEndID.length, "!Batch");
            collectionBatchEndID[_fromBatch] = _id;
            if (_fromBatch == collectionBatchEndID.length - 1){
                collectionEndID = _id;
            }
            return;
        }
        tokenNextToMintInBatch[_fromBatch] = _id;
    }

    /**
    @dev Admin can set the new public or presale cost for a specific batch in WEI. The cost is denominated in wei,
    where 1 ETH = 10^18 WEI. To convert ETH to WEI and vice versa, use a tool such as https://etherscan.io/unitconverter.
    @param _newCost uint256 indicating the new cost for the batch in WEI.
    @param _fromBatch uint indicating the ID of the batch to which the new cost applies.
    Note:
    This also sets the batchCostNext to the new cost so if a setCostNextOnTrigger was set it will need to be reset again.
    Requirements:
    Only accessible by admins.
    */
    function setCost(uint256 _newCost, uint _fromBatch) public onlyAdmins {
        batchCost[_fromBatch] = _newCost;
        batchCostNext[_fromBatch] = _newCost;
    }

    /**
    @dev Sets the cost for the next mint after a specific token is minted in a batch.
    Only accessible by admins.
    */
    function setCostNextOnTrigger(uint256 _nextCost, uint _triggerPointID, uint _fromBatch) public onlyAdmins {
        batchTriggerPoint[_fromBatch] = _triggerPointID;
        batchCostNext[_fromBatch] = _nextCost;
    }

    /**
    @dev Returns the cost for minting a token from the specified batch ID.
    If the caller is not an Admin, the function will return the presale cost if the batch is a presale batch,
    otherwise it will return the regular batch cost. If the caller is an Admin, the function will return 0.
    */
    function _cost(uint _batchID, bool _onTierList, uint8 _tID) public view returns(uint256){
        if (!checkIfAdmin()) {
            if(_onTierList){
                return tiers[_tID].tCost;
            }
            
            return batchCost[_batchID];
        }
        return 0;
    }

    function checkOut(uint _amount, uint _batchID, bytes32[] calldata proof) private {
        if (!checkIfAdmin()) {
            if (batchMintDateStart[_batchID] > 0) {
                require(block.timestamp >= batchMintDateStart[_batchID], "!D");
            }

            if(batchLimit[_batchID] != 0){
                require(walletMinted[msg.sender][_batchID] + _amount <= batchLimit[_batchID], "BLE");
                walletMinted[msg.sender][_batchID] += _amount;
            }

            (bool _onTierList, uint8 _tID) = isValidTier(proof, keccak256(abi.encodePacked(msg.sender)));
            if(_onTierList){
                if(tiers[_tID].tLimit == 0){
                    //use selected tier ID
                }
                else{
                    if(tierMinted[msg.sender][_tID] + _amount <= tiers[_tID].tLimit){
                        tierMinted[msg.sender][_tID] += _amount;
                    }
                    else{
                        //move to next tier if next one is available
                        if(_tID < tiers.length - 1){
                            _tID++;
                        }
                    }
                }
            }
            
            require(msg.value >= (_amount * _cost(_batchID, _onTierList, _tID)), "$?");
        }
    }

    function checkOutScan(uint _id, uint _fromBatch) private{
        if (!exists(_id)) {
            createdToken[_id] = true;
            if(mintInOrder[_fromBatch]){
                currentSupply[_id] = 1;
            }
        }

        if(rollInUse[_fromBatch]){
            roll[_id] = randomRoll(_fromBatch);
        }

        if(batchCost[_fromBatch] != batchCostNext[_fromBatch] && tokenNextToMintInBatch[_fromBatch] >= batchTriggerPoint[_fromBatch]){
            batchCost[_fromBatch] = batchCostNext[_fromBatch];
        }
        randomCounter++;
    }

    /**
    @dev Checks if a token with the given ID belongs to the specified batch.
    @param _id The ID of the token to check.
    @param _fromBatch The batch to check for token membership.
    @return bool indicating whether the token belongs to the specified batch.
    */
    function checkInBatch(uint _id, uint _fromBatch) public view returns(bool){
        require(_fromBatch < collectionBatchEndID.length, "!Batch");
        if(_fromBatch != 0 && _id <= collectionBatchEndID[_fromBatch] && _id > collectionBatchEndID[_fromBatch - 1]){
            return true;
        }
        if(_fromBatch <= 0 && _id <= collectionBatchEndID[_fromBatch]){
            return true;
        }
        return false;
    }

    /**
    @dev Allows Admins, Whitelisters, and Public to mint NFTs in order from a collection batch.
    Admins can call this function even while the contract is paused.
    @param _to The address to mint the NFTs to.
    @param _numberOfTokensToMint The number of tokens to mint from the batch in order.
    @param _fromBatch The batch to mint the NFTs from.
    @param proof An array of Merkle tree proofs to validate the mint.
    */
    function _mintInOrder(address _to, uint _numberOfTokensToMint, uint _fromBatch, bytes32[] calldata proof) public payable {
        require(mintInOrder[_fromBatch], "mintInOrder");
        require(!exists(collectionBatchEndID[_fromBatch]), "OOS");
        require(_fromBatch >= 0, "!Batch");
        require(_numberOfTokensToMint + tokenNextToMintInBatch[_fromBatch] - 1 <= collectionBatchEndID[_fromBatch], "Please Lower Amount");
        if(!checkIfAdmin()){
            require(!paused, "Paused");
            require(!pausedBatch[_fromBatch], "Paused Batch");

            checkOut(_numberOfTokensToMint, _fromBatch, proof);
        }
        
        _mintBatchTo(_to, _numberOfTokensToMint, _fromBatch);
    }

    function _mintBatchTo(address _to, uint _numberOfTokensToMint, uint _fromBatch)private {
        uint256[] memory _ids = new uint256[](_numberOfTokensToMint);
        uint256[] memory _amounts = new uint256[](_numberOfTokensToMint);
        for (uint256 i = 0; i < _numberOfTokensToMint; i++) {
            uint256 _id = tokenNextToMintInBatch[_fromBatch];
            require(canMintChecker(_id, 1, _fromBatch), "!MINT");
            
            checkOutScan(_id, _fromBatch);

            _ids[i] = tokenNextToMintInBatch[_fromBatch];
            _amounts[i] = 1;
            tokenNextToMintInBatch[_fromBatch]++;
        }
        
        _mintBatch(_to, _ids, _amounts, "");
    }

    /**
    @dev Allows Owner, Whitelisters, and Public to mint a single NFT with the given _id, _amount, and _fromBatch parameters for the specified _to address.
    @param _to The address to mint the NFT to.
    @param _id The ID of the NFT to mint.
    @param _amount The amount of NFTs to mint.
    @param _fromBatch The batch end ID that the NFT belongs to.
    @param proof The Merkle proof verifying the ownership of the tokens being minted.
    Requirements:
    - mintInOrder[_fromBatch] must be false.
    - _id must be within the batch specified by _fromBatch.
    - The total number of NFTs being minted across all batches cannot exceed maxBatchMintAmount.
    - If the caller is not an admin, the contract must not be paused and the batch being minted from must not be paused.
    - The caller must have a valid Merkle proof for the tokens being minted.
    - The amount of tokens being minted must satisfy the canMintChecker function.
    - The ID being minted must not have reached its max supply.
    */
    function mint(address _to, uint _id, uint _amount, uint _fromBatch, bytes32[] calldata proof) public payable {
        require(!mintInOrder[_fromBatch], "Requires !mintInOrder");
        require(checkInBatch(_id, _fromBatch), "!B");
        require(canMintChecker(_id, _amount, _fromBatch), "!MINT");
        if(!checkIfAdmin()){
            require(!paused, "Paused");
            require(!pausedBatch[_fromBatch], "Paused Batch");

            checkOut(_amount, _fromBatch, proof);
        }

        checkOutScan(_id, _fromBatch);
        currentSupply[_id] += _amount;
        
        _mint(_to, _id, _amount, "");
    }

    function canMintChecker(uint _id, uint _amount, uint _fromBatch) private view returns(bool){
        require(_amount > 0, "!A");
        require(_amount <= maxMintAmount, "MMA");
        require(_id <= collectionEndID, "!ID");

        // checks if the id exceeded it's max supply
        if (maxSupply[_id] != 0 && currentSupply[_id] + _amount > maxSupply[_id]) {
            // CANNOT MINT 
            return false;
        }

        // checks if the id exceeded it's max supply limit that each id in the batch is assigned
        if(maxSupplyForBatch[_fromBatch] != 0 && currentSupply[_id] + _amount > maxSupplyForBatch[_fromBatch]){
            // CANNOT MINT 
            return false;
        }
        
        // checks if the id needs requirement token(s)
        if(requirementTokens[_id].length > 0) {
            for (uint256 i = 0; i < requirementTokens[_id].length; i++) {
                uint256 _userTokenBalance = balanceOf(msg.sender, requirementTokens[_id][i]);
                if(_userTokenBalance < requirementTokenAmounts[_id][i]){
                    //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S) AMOUNTS
                    return false;
                }
            }
        }

        // checks if the batch (other than the original) that the id resides in needs requirement token(s)
        if(batchRequirementTokens[_fromBatch].length > 0){
            for (uint256 j = 0; j < batchRequirementTokens[_fromBatch].length; j++) {
                uint256 _userBatchTokenBalance = balanceOf(msg.sender, batchRequirementTokens[_fromBatch][j]);
                if(_userBatchTokenBalance < batchRequirementTokenAmounts[_fromBatch][j]){
                    //CANNOT MINT: DOES NOT HAVE REQUIREMENT TOKEN(S) AMOUNTS
                    return false;
                }
            }
        }

        // CAN MINT
        return true;
    }

    /**
    @dev Allows Owner, Whitelisters, and Public to mint multiple NFTs at once, given a list of token IDs, their corresponding amounts,
    and the batch from which they are being minted. Checks if the caller has the required permissions and if the maximum allowed mint
    amount and maximum allowed batch mint amount are not exceeded. Also verifies that the specified token IDs are in the given batch,
    and that the caller has passed a valid proof of a transaction to checkOut.
    */
    function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts, uint _fromBatch, bytes32[] calldata proof) public payable {
        require(!mintInOrder[_fromBatch], "Requires !mintInOrder");
        require(_ids.length <= maxMintAmount, "IDs>");
        require(_ids.length == _amounts.length, "IDs != Amounts");
        require(canMintBatchChecker(_ids, _amounts, _fromBatch), "!MINT");

        uint256 _totalBatchAmount;
        for (uint256 i = 0; i < _amounts.length; i++) {
            require(checkInBatch(_ids[i], _fromBatch), "!B");
            _totalBatchAmount += _amounts[i];
        }
        require(_totalBatchAmount <= maxBatchMintAmount, "LE");

        if(!checkIfAdmin()){
            require(!paused, "Paused");
            require(!pausedBatch[_fromBatch], "Paused Batch");
            checkOut(_totalBatchAmount, _fromBatch, proof);
        }

        for (uint256 k = 0; k < _ids.length; k++) {
            uint256 _id = _ids[k];
            checkOutScan(_id, _fromBatch);
            currentSupply[_ids[k]] += _amounts[k];
        }

        _mintBatch(_to, _ids, _amounts, "");
    }

    function canMintBatchChecker(uint[] memory _ids, uint[] memory _amounts, uint _fromBatch)private view returns(bool){
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];
            if(!canMintChecker(_id, _amount, _fromBatch)){
                // CANNOT MINT
                return false;
            }
        }

        return true;
    }

    /**
    @dev Allows User to DESTROY multiple tokens they own.
    */
    function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 _id = _ids[i];
            currentSupply[_id] -= _amounts[i];
        }
        _burnBatch(msg.sender, _ids, _amounts);
    }

    /**
    @dev Allows the contract admin to set the requirement tokens and their corresponding amounts for a specific token ID or batch end ID.
    If `_isBatch` is true, the requirement tokens and amounts will be set for the entire batch. Otherwise, they will be set for a specific token ID.
    @param _id The ID of the token or batch end for which the requirement tokens and amounts will be set.
    @param _isBatch A boolean indicating whether the ID corresponds to a batch end or a specific token.
    @param _requiredIDS An array of token IDs that are required to be owned in order to own the specified token or batch.
    @param _amounts An array of amounts indicating how many of each token ID in `_requiredIDS` are required to be owned in order to own the specified token or batch.
    */
    function setRequirementTokens(uint _id, bool _isBatch, uint[] memory _requiredIDS, uint[] memory _amounts) external onlyAdmins {
        if(_isBatch){
            require(_id >= 0 && _id <= collectionBatchEndID[collectionBatchEndID.length - 1], "!B");
            // is confirmed a Batch, _id = batchID
            batchRequirementTokens[_id] = _requiredIDS;
            batchRequirementTokenAmounts[_id] = _amounts;
        }
        else{
            requirementTokens[_id] = _requiredIDS;
            requirementTokenAmounts[_id] = _amounts;
        }
    }

    /**
    @dev Sets the URI for a token or batch of tokens.
    @param _hidden Flag to determine if the URI should be set as the hidden URI.
    @param _tier Flag to determine if the URI should be set as the tier URI.
    @param _isBatch Flag to determine if a batch of tokens is being modified.
    @param _id ID of the token or batch of tokens being modified.
    @param _uri The new URI to be set.
    @param _isIpfsCID Flag to determine if the new URI is an IPFS CID.
    */
    function setURI(bool _hidden, bool _tier, bool _isBatch, uint _id, string calldata _uri, bool _isIpfsCID) external onlyAdmins {
        if (_hidden) {
            hiddenURI = _uri;
            return;
        }

        if (_tier) {
            tierURI = _uri;
            return;
        }

        if (!_isBatch) {
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
        else{
            if (_isIpfsCID) {
                //modify IPFS CID
                ipfsCIDBatch[_id] = _uri;
            }
            else{
                //modify URI
                uriBatch[_id] = _uri;
            }
        }
    }

    /**
    @dev Allows the contract Admin to create a new batch of tokens with a specified end ID, URI or CID, and cost in WEI.
    @param _endBatchID The ending token ID of the new batch. Must be greater than the previous batch end ID.
    @param _newCost The cost of each token in the new batch in WEI.
    @param _uri The base URI or CID for the new batch of tokens.
    @param _isIpfsCID Set to true if the URI is a CID only.
    @param _isMintInOrder Set to true if the new batch should be minted in order.
    Example URI structure if _endBatchID = 55 and _isIpfsCID = false and _uri = BASEURI.EXTENSION
    will output: BASEURI.EXTENSION/55.json for IDs 55 and below until it hits another batch end ID.
    Requirements:
    - The _endBatchID parameter must be greater than the previous batch end ID.
    */
    function createBatchAndSetURI(uint _endBatchID, uint256 _newCost, string memory _uri, bool _isIpfsCID, bool _isMintInOrder) external onlyAdmins {
        require(_endBatchID > collectionBatchEndID[collectionBatchEndID.length-1], "EID > PB?");
        
        tokenNextToMintInBatch.push(collectionBatchEndID[collectionBatchEndID.length-1] + 1); //set mint start ID for batch
                    
        collectionBatchEndID.push(_endBatchID);

        if (_isIpfsCID) {
            //set IPFS CID
            ipfsCIDBatch.push(_uri);
            uriBatch.push("");
        }
        else{
            //set URI
            uriBatch.push(_uri);
            ipfsCIDBatch.push("");
        }

        batchCost.push(_newCost);
        batchCostNext[collectionBatchEndID.length-1] = _newCost;
        if(_isMintInOrder){
            setStateOf(3, true, collectionBatchEndID.length-1);
        }
    }

    /**
    @dev Returns the URI for a given token ID. If the token is a collection,
    the URI may be batched. If the token batch has roll enabled, it will have
    a random roll id. If the token is not found, the URI defaults to a hidden URI.
    @param _id uint256 ID of the token to query the URI of
    @return string representing the URI for the given token ID
    */
    function uri(uint256 _id) override public view returns(string memory){
        bool _batched = true;
        uint256 _batchID;
        string memory _CIDorURI;

        if(createdToken[_id]){
            if (_id <= collectionEndID) {
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
                    if(keccak256(abi.encodePacked((roll[_id]))) == keccak256(abi.encodePacked(("")))){
                        //no roll
                        return (
                        string(abi.encodePacked(
                            _CIDorURI,
                            Strings.toString(_id),
                            ".json"
                        )));
                    }
                    else{
                        //has roll
                        return (
                        string(abi.encodePacked(
                            _CIDorURI,
                            roll[_id],
                            ".json"
                        )));
                    }
                }
            }
        }
        //not found default to hidden
        return hiddenURI;
    }

    /**
    @dev Returns a random number between rollLimitMin and rollLimitMax for a given batch _fromBatch.
    @param _fromBatch The ID of the batch to get the roll limit for.
    @return A string representing the randomly selected roll within the specified range.
    */
    function randomRoll(uint _fromBatch) internal view returns (string memory){
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            randomCounter,
            roll[randomCounter - 1])
            )) % rollLimitMax[_fromBatch];
        //return random;
        if(random < rollLimitMin[_fromBatch]){
            return Strings.toString(rollLimitMax[_fromBatch] - (random + 1));
        }
        else{
            return Strings.toString(random + 1);
        }
    }

    /**
    @dev Returns a randomly selected roll within the range specified for a given batch _fromBatch.
    @param _fromBatch The ID of the batch to get the roll limit for.
    @return _roll string representing the randomly selected roll within the specified range.
    */
    // function randomPick(uint _fromBatch) public view returns (string memory _roll){
    //     return randomRoll(_fromBatch);
    // }

    /**
    @dev Sets the minimum and maximum values for the roll limit for a given batch _fromBatch.
    @param _min The minimum value of the roll limit (excluded).
    @param _max The maximum value of the roll limit (included).
    @param _fromBatch The ID of the batch to set the roll limit for.
    */
    function rollLimitSet(uint _min, uint _max, uint _fromBatch) external onlyAdmins {
        require(_min <= _max, "MIN <= MAX?");
        rollLimitMin[_fromBatch] = _min;
        rollLimitMax[_fromBatch] = _max;
    }

    /**
    @dev Returns the total number of tokens with a given ID that have been minted.
    @param _id The ID of the token.
    @return total number of tokens with the given ID.
    */
    function totalSupply(uint256 _id) public view returns(uint256) {
        return currentSupply[_id];
    }

    /**
    @dev Returns true if a token with the given ID exists, otherwise returns false.
    @param _id The ID of the token.
    @return bool indicating whether the token with the given ID exists.
    */
    function exists(uint256 _id) public view returns(bool) {
        return createdToken[_id];
    }

    /**
    @dev Returns the maximum supply of a token with the given ID.
    @param _id The ID of the token.
    @param _isBatch A boolean indicating whether the ID is a batch ID or not.
    @return maximum supply of the token with the given ID. If it is 0, the supply is limitless.
    */
    function checkMaxSupply(uint256 _id, bool _isBatch) public view returns(uint256) {        
        if(_isBatch){
            return maxSupplyForBatch[_id];
        }
        else{
            return maxSupply[_id];
        }
    }

    /**
    @dev Allows the admin to set the maximum supply of tokens.
    @param _ids An array of token IDs to set the maximum supply for.
    @param _supplies An array of maximum supplies for the tokens in the corresponding position in _ids.
    @param _isBatchAllSameSupply A boolean indicating whether all tokens in _ids should have the same maximum supply or not.
    Note: If the maximum supply is set to 0, the supply is limitless.
    */
    function setMaxSupplies(uint[] memory _ids, uint[] memory _supplies, bool _isBatchAllSameSupply) external onlyAdmins {
        if(_isBatchAllSameSupply){
            maxSupplyForBatch[_ids[0]] = _supplies[0];          
        }
        else{
            for (uint256 i = 0; i < _ids.length; i++) {
                uint256 _id = _ids[i];
                maxSupply[_id] = _supplies[i];
            }
        }
    }

    /**
    @dev Allows admin to update the collectionEndID which is used to determine the end of the entire collection of NFTs.
    @param _newcollectionEndID The new collectionEndID to set.
    */
    function updatecollectionEndID(uint _newcollectionEndID) external onlyAdmins {
        collectionEndID = _newcollectionEndID;
    }

    /**
    @dev Allows admin to set the maximum amount of NFTs a user can mint in a single session.
    @param _newmaxMintAmount The new maximum amount of NFTs a user can mint in a single session.
    */
    function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyAdmins {
        maxMintAmount = _newmaxMintAmount;
    }

    /**
    @dev Allows admin to set the mint limit for a batch.
    @param _limit The new limit to set.
    @param _fromBatch The index of the batch to set the limit for.
    */
    function setMintLimit(uint256 _limit, uint256 _fromBatch) public onlyAdmins {
        batchLimit[_fromBatch] = _limit;
    }

    /**
    @dev Allows admin to set the payout address for the contract.
    @param _address The new payout address to set.
    Note: address can be a wallet or a payment splitter contract
    */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
    @dev Admin can withdraw the contract's balance to the specified payout address.
    The `payments` address must be set before calling this function.
    The function will revert if `payments` address is not set or the transaction fails.
    */
    function withdraw() public onlyAdmins {
        require(payments != address(0), "Payout address not set");

        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        // Splitter
        (bool success, ) = payable(payments).call{ value: balance }("");
        require(success, "Withdrawal failed");
    }

    /**
    @dev Auto send funds to the payout address.
    Triggers only if funds were sent directly to this address.
    */
    receive() external payable {
        require(payments != address(0), "Payment address not set");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

    /**
    @dev Throws if called by any account other than the owner or admin.
    */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
    @dev Internal function to check if the sender is an admin.
    */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "!A");
    }

    /**
    @dev Checks if the sender is an admin.
    @return bool indicating whether the sender is an admin or not.
    */
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
    @dev Owner and Project Leader can set the addresses as approved Admins.
    Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
    */
    function setAdmins(address[] calldata _users) public onlyAdmins {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        delete admins;
        admins = _users;
    }

    /**
    @dev Owner or Project Leader can set the address as new Project Leader.
    */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        projectLeader = _user;
    }

    /**
    * @dev Validates what tier a user is on for the Tierlist.
    */
    function isValidTier(bytes32[] calldata proof, bytes32 leaf) public view returns (bool, uint8) {
        if(tiers.length != 0){
            for (uint8 i = 0; i < tiers.length; i++) {
                if(MerkleProof.verify(proof, tiers[i].tRoot, leaf)){
                    return (true, i);
                }
            }
        }
        
        return (false, 0);
    }

    /**
    @dev Sets a new tier with the provided parameters or updates an existing tier.
    @param _create If true, creates a new tier with the provided parameters. If false, updates an existing tier.
    @param _tID The ID of the tier to be updated. Only applicable if _create is false.
    @param _tLimit The mint limit of the new tier or updated tier.
    @param _tCost The cost of the new tier or updated tier.
    @param _tRoot The Merkle root of the new tier or updated tier.
    Requirements:
    - Only admin addresses can call this function.
    - If _create is false, the ID provided must correspond to an existing tier.
    */
    function setTier(bool _create, uint8 _tID, uint256 _tLimit, uint256 _tCost, bytes32 _tRoot) external onlyAdmins {
        // Define a new Tier struct with the provided cost and Merkle root.
        Tier memory newTier = Tier(
            _tLimit,
            _tCost,
            _tRoot
        );
        
        if(_create){
            // If _create is true, add the new tier to the end of the tiers array.
            tiers.push(newTier);
        }
        else{
            // If _create is false, update the existing tier at the specified ID.
            require(tiers.length > 0 && _tID < tiers.length, "Invalid Tier ID");
            tiers[_tID] = newTier;
        }
    }

    /**
    * @dev Owner or Project Leader can set the restricted state of an address.
    * Note: Restricted addresses are banned from moving tokens.
    */
    function restrictAddress(address _user, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
        restricted[_user] = _state;
    }

    /**
    * @dev Owner or Project Leader can set the flag state of a token ID.
    * Note: Flagged tokens are locked and untransferable.
    */
    function flagID(uint256 _id, bool _state) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "NOoPL");
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
                revert("FID"); //reverts if a token has been flagged
            }
        }
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
            if(i <= 0 && _id <= collectionBatchEndID[i]){
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

    //OPENSEA ROYALTY REQUIREMENT CODE SNIPPET ************_START
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
    //OPENSEA ROYALTY REQUIREMENT CODE SNIPPET ************_END
}