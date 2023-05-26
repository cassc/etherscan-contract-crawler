// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Enumerable.sol";
import "./interfaces/IERC721Metadata.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC165.sol";

import "./IGBATrapsPartial.sol";
import "./Ownable.sol";

import "./GBAWhitelist.sol";

/// @author Andrew Parker
/// @title Ghost Busters: Afterlife Mini Stay Puft NFT contract
contract MiniStayPuft is IERC721, IERC721Metadata, IERC165, Ownable{

    enum Phase{Init,PreReserve,Reserve,Final} // Launch phase
    struct Reservation{
        uint24 block;       // Using uint24 to store block number is fine for the next 2.2 years
        uint16[] tokens;    // TokenIDs reserved by person
    }
    bool paused = true;                 // Sale pause state
    bool unpausable;                    // Unpausable
    uint startTime;                     // Timestamp of when preReserve phase started (adjusts when paused/unpaused)
    uint pauseTime;                     // Timestamp of pause
    uint16 tokenCount;                  // Total tokens minted and reserved. (not including caught mobs)

    uint16 tokensGiven;                     // Total number of giveaway token's minted
    uint16 constant TOKENS_GIVEAWAY = 200;  // Max number of giveaway tokens

    uint constant PRICE_MINT = 0.08 ether;    // Mint cost

    string __uriBase;       // Metadata URI base
    string __uriSuffix;     // Metadata URI suffix

    uint constant COOLDOWN = 10;            // Min interval in blocks to reserve
    uint16 constant TRANSACTION_LIMIT = 10; // Max tokens reservable in one transaction

    mapping(address => Reservation) reservations;       // Mapping of buyer to reservations
    mapping(address => uint8) whitelistReserveCount;    // Mapping of how many times listees have preReserved
    uint8 constant WHITELIST_RESERVE_LIMIT = 2;         // Limit of how many tokens a listee can preReserve
    uint constant PRESALE_LIMIT = 2000;                 // Max number of tokens that can be preReserved
    uint presaleCount;                                  // Number of tokens that have been preReserved


    event Pause(bool _pause,uint _startTime,uint _pauseTime);
    event Reserve(address indexed reservist, uint indexed tokenId);
    event Claim(address indexed reservist, uint indexed tokenId);

    //MOB VARS
    address trapContract;   // Address of Traps contract
    address whitelist;      // Address of Whitelist contract

    uint16 constant SALE_MAX = 10000;       // Max number of tokens that can be sold
    uint16[4] mobTokenIds;                  // Partial IDs of current mobs. 4th slot is highest id (used to detect mob end)
    uint16 constant TOTAL_MOB_COUNT = 500;  // Total number of mobs that will exist

    uint constant MOB_OFFSET = 100000;      // TokenId offset for mobs

    bool mobReleased = false;               // Has mob been released
    bytes32 mobHash;                        // Current mob data


    mapping(address => uint256) internal balances;                      // Mapping of balances (not including active mobs)
    mapping (uint256 => address) internal allowance;                    // Mapping of allowances
    mapping (address => mapping (address => bool)) internal authorised; // Mapping of token allowances

    mapping(uint256 => address) owners;  // Mapping of owners (not including active mobs)

    uint[] tokens;      // Array of tokenIds (not including active mobs)

    mapping (bytes4 => bool) internal supportedInterfaces;


    constructor(string memory _uriBase, string memory _uriSuffix, address _trapContract, address _whitelist){

        supportedInterfaces[0x80ac58cd] = true; //ERC721
        supportedInterfaces[0x5b5e139f] = true; //ERC721Metadata
        supportedInterfaces[0x01ffc9a7] = true; //ERC165

        mobTokenIds[0] = 1;
        mobTokenIds[1] = 2;
        mobTokenIds[2] = 3;
        mobTokenIds[3] = 3;

        trapContract = _trapContract;
        whitelist = _whitelist;

        __uriBase = _uriBase;
        __uriSuffix = _uriSuffix;

        //Init mobHash segments
        mobHash =
            shiftBytes(bytes32(uint(0)),0) ^ // Random data that changes every tx to even out gas costs
            shiftBytes(bytes32(uint(1)),1) ^ // Number of owners to base ownership calcs on for mob 0
            shiftBytes(bytes32(uint(1)),2) ^ // Number of owners to base ownership calcs on for mob 1
            shiftBytes(bytes32(uint(1)),3) ^ // Number of owners to base ownership calcs on for mob 2
            shiftBytes(bytes32(uint(0)),4);  // Location data for calculating ownership of all mobs
    }

    /// Mint-Reserve State
    /// @notice Get struct properties of reservation mapping for given address, as well as preReserve count.
    /// @dev Combined these to lower compiled contract size (Spurious Dragon).
    /// @param _tokenOwner Address of reservation data to check
    /// @return _whitelistReserveCount Number of times address has pre-reserved
    /// @return blockNumber Block number of last reservation
    /// @return tokenIds Array of reserved, unclaimed tokens
    function mintReserveState(address _tokenOwner)  public view returns(uint8 _whitelistReserveCount, uint24 blockNumber, uint16[] memory tokenIds){
        return (whitelistReserveCount[_tokenOwner],reservations[_tokenOwner].block,reservations[_tokenOwner].tokens);
    }

    /// Contract State
    /// @notice View function for various contract state properties
    /// @dev Combined these to lower compiled contract size (Spurious Dragon).
    /// @return _tokenCount Number of tokens reserved or minted (not including mobs)
    /// @return _phase Current launch phase
    /// @return mobMax Uint used to calculate IDs and number if mobs in circulation.
    function contractState() public view returns(uint _tokenCount, Phase _phase, uint mobMax){
        return (tokenCount,phase(),mobTokenIds[3]);
    }



    /// Pre-Reserve
    /// @notice Pre-reserve tokens during Pre-Reserve phase if whitelisted. Max 2 per address. Must pay mint fee
    /// @param merkleProof Merkle proof for your address in the whitelist
    /// @param _count Number of tokens to reserve
    function preReserve(bytes32[] memory merkleProof, uint8 _count) external payable{
        require(!paused,"paused");
        require(phase() == Phase.PreReserve,"phase");
        require(msg.value >= PRICE_MINT * _count,"PRICE_MINT");
        require(whitelistReserveCount[msg.sender] + _count <= WHITELIST_RESERVE_LIMIT,"whitelistReserveCount");
        require(presaleCount + _count < PRESALE_LIMIT,"PRESALE_LIMIT");
        require(GBAWhitelist(whitelist).isWhitelisted(merkleProof,msg.sender),"whitelist");

        whitelistReserveCount[msg.sender] += _count;
        presaleCount += _count;
        _reserve(_count,msg.sender,true);
    }


    /// Mint Giveaway
    /// @notice Mint tokens for giveaway
    /// @param numTokens Number of tokens to mint
    function mintGiveaway(uint16 numTokens) public onlyOwner {
        require(tokensGiven + numTokens <= TOKENS_GIVEAWAY,"tokensGiven");
        require(tokenCount + numTokens <= SALE_MAX,"SALE_MAX");
        for(uint i = 0; i < numTokens; i++){
            tokensGiven++;
            _mint(msg.sender,++tokenCount);
        }
    }

    /// Withdraw All
    /// @notice Withdraw all Eth from mint fees
    function withdrawAll() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /// Reserve
    /// @notice Reserve tokens. Max 10 per tx, one tx per 10 blocks. Can't be called by contracts. Must be in Reserve phase. Must pay mint fee.
    /// @param _count Number of tokens to reserve
    /// @dev requires tx.origin == msg.sender
    function reserve(uint16 _count) public payable{
        require(msg.sender == tx.origin,"origin");
        require(!paused,"paused");
        require(phase() == Phase.Reserve,"phase");
        require(_count <= TRANSACTION_LIMIT,"TRANSACTION_LIMIT");
        require(msg.value >= uint(_count) * PRICE_MINT,"PRICE MINT");

        _reserve(_count,msg.sender,false);
    }


    /// Internal Reserve
    /// @notice Does the work in both Reserve and PreReserve
    /// @param _count Number of tokens being reserved
    /// @param _to Address that is reserving
    /// @param ignoreCooldown Don't revert for cooldown.Used in pre-reserve
    function _reserve(uint16 _count, address _to, bool ignoreCooldown) internal{
        require(tokenCount + _count <= SALE_MAX, "SALE_MAX");
        require(ignoreCooldown ||
            reservations[_to].block == 0 || block.number >= uint(reservations[_to].block) + COOLDOWN
        ,"COOLDOWN");

        for(uint16 i = 0; i < _count; i++){
            reservations[address(_to)].tokens.push(++tokenCount);

            emit Reserve(_to,tokenCount);
        }
        reservations[_to].block = uint24(block.number);

    }


    /// Claim
    /// @notice Mint reserved tokens
    /// @param reservist Address with reserved tokens.
    /// @param _count Number of reserved tokens mint.
    /// @dev Allows anyone to call claim for anyone else. Will mint to the address that made the reservations.
    function claim(address reservist, uint _count) public{
        require(!paused,"paused");
        require(
            phase() == Phase.Final
        ,"phase");

        require( reservations[reservist].tokens.length >= _count, "_count");
        for(uint i = 0; i < _count; i++){
            uint tokenId = uint(reservations[reservist].tokens[reservations[reservist].tokens.length - 1]);
            reservations[reservist].tokens.pop();
            _mint(reservist,tokenId);
            emit Claim(reservist,tokenId);
        }

        updateMobStart();
        updateMobFinish();
    }


    /// Mint
    /// @notice Mint unreserved tokens. Must pay mint fee.
    /// @param _count Number of reserved tokens mint.
    function mint(uint _count) public payable{
        require(!paused,"paused");
        require(
            phase() == Phase.Final
        ,"phase");
        require(msg.value >= _count * PRICE_MINT,"PRICE");

        require(tokenCount + uint16(_count) <= SALE_MAX,"SALE_MAX");

        for(uint i = 0; i < _count; i++){
            _mint(msg.sender,uint(++tokenCount));
        }

        updateMobStart();
        updateMobFinish();
    }


    /// Update URI
    /// @notice Update URI base and suffix
    /// @param _uriBase URI base
    /// @param _uriSuffix URI suffix
    /// @dev Pushing size limits (Spurious Dragon), so rather than having an explicit lock function, it can be implicit by renouncing ownership.
    function updateURI(string memory _uriBase, string memory _uriSuffix) public onlyOwner{
        __uriBase   = _uriBase;
        __uriSuffix = _uriSuffix;
    }


    /// Phase
    /// @notice Internal function to calculate current Phase
    /// @return Phase (enum value)
    function phase() internal view returns(Phase){
        uint _startTime = startTime;
        if(_startTime == 0){
            return Phase.Init;
        }else if(block.timestamp <= _startTime + 2 hours){
            return Phase.PreReserve;
        }else if(block.timestamp <= _startTime + 2 hours + 1 days && tokenCount < SALE_MAX){
            return Phase.Reserve;
        }else{
            return Phase.Final;
        }
    }

    /// Pause State
    /// @notice Get current pause state
    /// @return _paused Contract is paused
    /// @return _startTime Start timestamp of Cat phase (adjusted for pauses)
    /// @return _pauseTime Timestamp of pause
    function pauseState() view public returns(bool _paused,uint _startTime,uint _pauseTime){
        return (paused,startTime,pauseTime);
    }


    /// Disable pause
    /// @notice Disable mint pausability
    function disablePause() public onlyOwner{
        if(paused) togglePause();
        unpausable = true;
    }

    /// Toggle pause
    /// @notice Toggle pause on/off
    function togglePause() public onlyOwner{
        if(startTime == 0){
            startTime = block.timestamp;
            paused = false;
            emit Pause(false,startTime,pauseTime);
            return;
        }
        require(!unpausable,"unpausable");

        bool _pause = !paused;
        if(_pause){
            pauseTime = block.timestamp;
        }else if(pauseTime != 0){
            startTime += block.timestamp - pauseTime;
            delete pauseTime;
        }
        paused = _pause;
        emit Pause(_pause,startTime,pauseTime);
    }


    /// Get Mob Owner
    /// @notice Internal func to calculate the owner of a given mob for a given mob hash
    /// @param _mobIndex Index of mob to check (0-2)
    /// @param _mobHash Mob hash to base calcs off
    /// @return Address of the calculated owner
    function getMobOwner(uint _mobIndex, bytes32 _mobHash) internal view returns(address){
        bytes32 mobModulo = extractBytes(_mobHash, _mobIndex + 1);
        bytes32 locationHash = extractBytes(_mobHash,4);

        uint hash = uint(keccak256(abi.encodePacked(locationHash,_mobIndex,mobModulo)));
        uint index = hash % uint(mobModulo);

        address _owner = owners[tokens[index]];

        if(mobReleased){
            return _owner;
        }else{
            return address(0);
        }
    }

    /// Get Mob Token ID (internal)
    /// @notice Internal func to calculate mob token ID given an index
    /// @dev Doesn't check invalid vals, inferred by places where its used and saves gas
    /// @param _mobIndex Index of mob to calculate
    /// @return tokenId of mob
    function _getMobTokenId(uint _mobIndex) internal view returns(uint){
        return MOB_OFFSET+uint(mobTokenIds[_mobIndex]);
    }

    /// Get Mob Token ID
    /// @notice Calculate mob token ID given an index
    /// @dev Doesn't fail for _mobIndex = 3, because of Spurious Dragon and because it doesnt matter
    /// @param _mobIndex Index of mob to calculate
    /// @return tokenId of mob
    function getMobTokenId(uint _mobIndex) public view returns(uint){
        uint tokenId = _getMobTokenId(_mobIndex);
        require(tokenId != MOB_OFFSET,"no token");
        return tokenId;
    }

    /// Extract Bytes
    /// @notice Get the nth 4-byte chunk from a bytes32
    /// @param data Data to extract bytes from
    /// @param index Index of chunk
    function extractBytes(bytes32 data, uint index) internal pure returns(bytes32){
        uint inset = 32 * ( 7 -  index );
        uint outset = 32 * index;
        return ((data  << outset) >> outset) >> inset;
    }

    /// Extract Bytes
    /// @notice Bit shift a bytes32 for XOR packing
    /// @param data Data to bit shift
    /// @param index How many 4-byte segments to shift it by
    function shiftBytes(bytes32 data, uint index) internal pure returns(bytes32){
        uint inset = 32 * ( 7 -  index );
        return data << inset;
    }

    /// Release Mob
    /// @notice Start Mob
    function releaseMob() public onlyOwner{
        require(!mobReleased,"released");
        require(tokens.length > 0, "no mint");

        mobReleased = true;

        bytes32 _mobHash = mobHash;                                         //READ
        uint eliminationBlock = block.number - (block.number % 245) - 10;    //READ

        bytes32 updateHash  = extractBytes(keccak256(abi.encodePacked(_mobHash)),0);

        bytes32 mobModulo = bytes32(tokens.length);
        bytes32 destinationHash = extractBytes( blockhash(eliminationBlock),4) ;

        bytes32 newMobHash =    shiftBytes(updateHash,0) ^                                                //WRITE
                                shiftBytes(mobModulo,1) ^
                                shiftBytes(mobModulo,2) ^
                                shiftBytes(mobModulo,3) ^
                                shiftBytes(destinationHash,4);

        for(uint i = 0; i < 3; i++){
            uint _tokenId = _getMobTokenId(i);                                       //READ x 3
            emit Transfer(address(0),getMobOwner(i,newMobHash),_tokenId);           //EMIT x 3 max
        }

        mobHash = newMobHash;
    }

    /// Update Mobs Start
    /// @notice Internal - Emits all the events sending mobs to 0. First part of mobs moving
    function updateMobStart() internal{
        if(!mobReleased || mobTokenIds[3] == 0) return;

        //BURN THEM
        bytes32 _mobHash = mobHash;                                         //READ
        for(uint i = 0; i < 3; i++){
            uint _tokenId = _getMobTokenId(i);                                       //READ x 3
            if(_tokenId != MOB_OFFSET){
                emit Transfer(getMobOwner(i,_mobHash),address(0),_tokenId);           //READx3, EMIT x 3 max
            }
        }
    }

    /// Update Mobs Finish
    /// @notice Internal - Calculates mob owners and emits events sending to them. Second part of mobs moving
    function updateMobFinish() internal {
        if(!mobReleased) {
            require(gasleft() > 100000,"gas failsafe");
            return;
        }
        if(mobTokenIds[3] == 0) return;

        require(gasleft() > 64500,"gas failsafe");

        bytes32 _mobHash = mobHash;                                         //READ
        uint eliminationBlock = block.number - (block.number % 245) - 10;    //READ

        bytes32 updateHash  = extractBytes(keccak256(abi.encodePacked(_mobHash)),0);

        bytes32 mobModulo0 = extractBytes(_mobHash,1);
        bytes32 mobModulo1 = extractBytes(_mobHash,2);
        bytes32 mobModulo2 = extractBytes(_mobHash,3);

        bytes32 destinationHash = extractBytes( blockhash(eliminationBlock),4);

        bytes32 newMobHash = shiftBytes(updateHash,0) ^
                                shiftBytes(mobModulo0,1) ^
                                shiftBytes(mobModulo1,2) ^
                                shiftBytes(mobModulo2,3) ^
                                shiftBytes(destinationHash,4);

        mobHash = newMobHash; //WRITE

        for(uint i = 0; i < 3; i++){
            uint _tokenId = _getMobTokenId(i);                                       //READ x 3
            if(_tokenId != MOB_OFFSET){
                emit Transfer(address(0),getMobOwner(i,newMobHash),_tokenId);         //READx3, EMIT x 3 max
            }
        }
    }


    /// Update Catch Mob
    /// @notice Catch a mob that's in your wallet
    /// @param _mobIndex Index of mob to catch
    /// @dev Mints real token and updates mobs
    function catchMob(uint _mobIndex) public {
        IGBATrapsPartial(trapContract).useTrap(msg.sender);

        require(_mobIndex < 3,"mobIndex");
        bytes32 _mobHash = mobHash;
        address mobOwner = getMobOwner(_mobIndex,_mobHash);
        require(msg.sender == mobOwner,"owner");

        updateMobStart();   //Kill all mobs

        bytes32 updateHash  = extractBytes(_mobHash,0);

        bytes32[3] memory mobModulo;

        for(uint i = 0; i < 3; i++){
            mobModulo[i] = extractBytes(_mobHash,i + 1);
        }

        uint mobTokenId = _getMobTokenId(_mobIndex);                //READ

        //Mint real one
        _mint(msg.sender,mobTokenId+MOB_OFFSET);

        bool mintNewMob = true;
        if(mobTokenIds[3] < TOTAL_MOB_COUNT){
            mobTokenIds[_mobIndex] =  ++mobTokenIds[3];
        }else{
            mintNewMob = false;

            //if final 3
            mobTokenIds[3]++;
            mobTokenIds[_mobIndex] = 0;

            if(mobTokenIds[3] == TOTAL_MOB_COUNT + 3){
                //if final mob, clear last slot to identify end condition
                delete mobTokenIds[3];
            }
        }

        mobModulo[_mobIndex] = bytes32(tokens.length);

        uint eliminationBlock = block.number - (block.number % 245) - 10;    //READ
        bytes32 destinationHash = extractBytes( blockhash(eliminationBlock),4);

        mobHash = shiftBytes(updateHash,0) ^                       //WRITE
                    shiftBytes(mobModulo[0],1) ^
                    shiftBytes(mobModulo[1],2) ^
                    shiftBytes(mobModulo[2],3) ^
                    shiftBytes(destinationHash,4);

        updateMobFinish(); //release mobs
    }

    /// Mint (internal)
    /// @notice Mints real tokens as per ERC721
    /// @param _to Address to mint it for
    /// @param _tokenId Token to mint
    function _mint(address _to,uint _tokenId) internal{
        emit Transfer(address(0), _to, _tokenId);

        owners[_tokenId] =_to;
        balances[_to]++;
        tokens.push(_tokenId);
    }

    /// Is Valid Token (internal)
    /// @notice Checks if given tokenId exists (Doesn't apply to mobs)
    /// @param _tokenId TokenId to check
    function isValidToken(uint256 _tokenId) internal view returns(bool){
        return owners[_tokenId] != address(0);
    }

    /// Require Valid (internal)
    /// @notice Reverts if given token doesn't exist
    function requireValid(uint _tokenId) internal view{
        require(isValidToken(_tokenId),"valid");
    }

    /// Balance Of
    /// @notice ERC721 balanceOf func, includes active mobs
    function balanceOf(address _owner) external override view returns (uint256){
        uint _balance = balances[_owner];
        bytes32 _mobHash = mobHash;
        for(uint i = 0; i < 3; i++){
            if(getMobOwner(i, _mobHash) == _owner){
                _balance++;
            }
        }
        return _balance;
    }

    /// Owner Of
    /// @notice ERC721 ownerOf func, includes active mobs
    function ownerOf(uint256 _tokenId) public override view returns(address){
        bytes32 _mobHash = mobHash;
        for(uint i = 0; i < 3; i++){
            if(_getMobTokenId(i) == _tokenId){
                address owner = getMobOwner(i,_mobHash);
                require(owner != address(0),"invalid");
                return owner;
            }
        }
        requireValid(_tokenId);
        return owners[_tokenId];
    }

    /// Approve
    /// @notice ERC721 function
    function approve(address _approved, uint256 _tokenId)  external override{
        address _owner = owners[_tokenId];
        require( _owner == msg.sender                    //Require Sender Owns Token
            || authorised[_owner][msg.sender]                //  or is approved for all.
            ,"permission");
        emit Approval(_owner, _approved, _tokenId);
        allowance[_tokenId] = _approved;
    }

    /// Get Approved
    /// @notice ERC721 function
    function getApproved(uint256 _tokenId) external view override returns (address) {
//        require(isValidToken(_tokenId),"invalid");
        requireValid(_tokenId);
        return allowance[_tokenId];
    }

    /// Is Approved For All
    /// @notice ERC721 function
    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return authorised[_owner][_operator];
    }

    /// Set Approval For All
    /// @notice ERC721 function
    function setApprovalForAll(address _operator, bool _approved) external override {
        emit ApprovalForAll(msg.sender,_operator, _approved);
        authorised[msg.sender][_operator] = _approved;
    }

    /// Transfer From
    /// @notice ERC721 function
    /// @dev Fails for mobs
    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        requireValid(_tokenId);

        //Check Transferable
        //There is a token validity check in ownerOf
        address _owner = owners[_tokenId];

        require ( _owner == msg.sender             //Require sender owns token
            //Doing the two below manually instead of referring to the external methods saves gas
            || allowance[_tokenId] == msg.sender      //or is approved for this token
            || authorised[_owner][msg.sender]          //or is approved for all
        ,"permission");
        require(_owner == _from,"owner");
        require(_to != address(0),"zero");

        updateMobStart();

        emit Transfer(_from, _to, _tokenId);

        owners[_tokenId] =_to;

        balances[_from]--;
        balances[_to]++;

        //Reset approved if there is one
        if(allowance[_tokenId] != address(0)){
            delete allowance[_tokenId];
        }

        updateMobFinish();
    }

    /// Safe Transfer From
    /// @notice ERC721 function
    /// @dev Fails for mobs
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override {
        transferFrom(_from, _to, _tokenId);

        //Get size of "_to" address, if 0 it's a wallet
        uint32 size;
        assembly {
            size := extcodesize(_to)
        }
        if(size > 0){
            IERC721TokenReceiver receiver = IERC721TokenReceiver(_to);
            require(receiver.onERC721Received(msg.sender,_from,_tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),"receiver");
        }

    }

    /// Safe Transfer From
    /// @notice ERC721 function
    /// @dev Fails for mobs
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override {
        safeTransferFrom(_from,_to,_tokenId,"");
    }


    /// Name
    /// @notice ERC721 Metadata function
    /// @return _name Name of token
    function name() external pure override returns (string memory _name){
        return "Ghostbusters: Afterlife Collectibles";
    }

    /// Symbol
    /// @notice ERC721 Metadata function
    /// @return _symbol Symbol of token
    function symbol() external pure override returns (string memory _symbol){
        return "GBAC";
    }

    /// Token URI
    /// @notice ERC721 Metadata function (includes active mobs)
    /// @param _tokenId ID of token to check
    /// @return URI (string)
    function tokenURI(uint256 _tokenId) public view  override returns (string memory) {
        ownerOf(_tokenId); //includes validity check

        return string(abi.encodePacked(__uriBase,toString(_tokenId),__uriSuffix));
    }

    /// To String
    /// @notice Converts uint to string
    /// @param value uint to convert
    /// @return String
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }



    // ENUMERABLE FUNCTIONS (not actually needed for compliance but everyone likes totalSupply)
    function totalSupply() public view returns (uint256){
        uint highestMob = mobTokenIds[3];
        if(!mobReleased || highestMob == 0){
            return tokens.length;
        }else if(highestMob < TOTAL_MOB_COUNT){
            return tokens.length + 3;
        }else{
            return tokens.length + 3 - (TOTAL_MOB_COUNT - highestMob);
        }

    }

    function supportsInterface(bytes4 interfaceID) external override view returns (bool){
        return supportedInterfaces[interfaceID];
    }


}