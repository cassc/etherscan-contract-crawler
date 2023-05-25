//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RoninWhitelist.sol";

/// @author Andrew Parker
/// @title OniRonin NFT Contract
contract Ronin is ERC721, Ownable, /*ERC2981,*/ ERC721Enumerable{

    enum Phase{Init,Cat,Reserve,Claim,Ceremony} //Current launch phase

    struct Reservation{
        uint24 block;       // Using uint24 to store block number is fine for the next 2.3 years
        uint16[] tokens;    // TokenIDs reserved by person
    }

    bool paused = true;                 // Sale pause state
    bool unpausable;                    // Unpausible
    uint startTime;                     // Timestamp of when cat phase started (adjusts when paused/unpaused)
    uint pauseTime;                     // Timestamp of pause
    address whitelist;                  // Cat Phase Whitlelist contract
    bool forceCeremony;                 // Ceremony enabled before all tokens minted
    uint16 public tokenCount;           // Total tokens minted and reserved.
    uint16 constant TOKEN_MAX = 8888;   // Max Ronins that can exist

    uint16 tokensGiven;                     // Total number of giveaway token's minted
    uint16 constant TOKENS_GIVEAWAY = 300;  // Max number of giveaway tokens

    uint constant PRICE_MINT = 0.0888 ether;    // Mint cost

    string __uriBase;       // Metadata URI base
    string __uriSuffix;     // Metadata URI suffix

    uint constant COOLDOWN = 10;            // Min interval in blocks to reserve
    uint16 constant TRANSACTION_LIMIT = 10; // Max tokens reservable in one transaction

    mapping(address => Reservation) reservations;   // Mapping of buyer to reservations
    mapping(address => bool) public catMinted;      // Mapping of cat owners who have minted

    event Pause(bool _pause,bool _unpausable,uint _startTime,uint _pauseTime);
    event Reserve(address indexed reservist, uint indexed tokenId);
    event Claim(address indexed reservist, uint indexed tokenId);
    event Ceremony(uint indexed tokenId);


    /// Constructor
    /// @param _uriBase the metadata URI base
    /// @param _uriSuffix the metadata URI suffix
    /// @param _whitelist address of the Merkle tree whitelist contract
    constructor(
        string memory _uriBase,
        string memory _uriSuffix,
        address _whitelist
    ) ERC721("OniRonin","ONI"){
        __uriBase   = _uriBase;
        __uriSuffix = _uriSuffix;
        whitelist = _whitelist;
    }

    /// Mint a Ronin (Cat Owner)
    /// @notice Mint a Ronin if you're in the Stoner Cats snapshot. Must pay mint fee. Must be after Cat phase has started.
    /// @param merkleProof merkle proof for your address in the snapshot
    function catMint(bytes32[] memory merkleProof) external payable{
        require(!paused,"paused");
        require(phase() != Phase.Init,"phase");
        require(tokenCount < TOKEN_MAX,"TOKEN_MAX");

        require(msg.value >= PRICE_MINT,"PRICE_MINT");
        require(!catMinted[msg.sender],"catMinted");
        require(RoninWhitelist(whitelist).isWhitelisted(merkleProof,msg.sender),"whitelist");
        catMinted[msg.sender] = true;

        _mint(msg.sender,uint(++tokenCount));
    }

    /// Pause/Unpause
    /// @notice Pause/unpause sale, or disable pausing.
    /// @param _pause Pause sale
    /// @param disable Disable pausing
    /// @dev Had to bundle disable into the same func because contract is pushing size limit. Adjusts startTime when contract is unpaused
    function pause(bool _pause, bool disable) public onlyOwner{
        if(startTime == 0){
            startTime = block.timestamp;
            paused = false;
            emit Pause(false,false,startTime,pauseTime);
            return;
        }
        require(!unpausable,"unpausable");

        if(disable){
            _pause = false;
            unpausable = true;
        }
        if(paused != _pause){
            if(_pause){
                pauseTime = block.timestamp;
            }else if(pauseTime != 0){
                startTime += block.timestamp - pauseTime;
                delete pauseTime;
            }
            paused = _pause;
            emit Pause(_pause, unpausable,startTime,pauseTime);
        }
    }

    /// Start Ceremony phase
    /// @notice Enable Ceremony of Ascension even if not all Ronins minted.
    function startCeremonyPhase() public onlyOwner{
        forceCeremony = true;
    }

    /// Update URI
    /// @notice Update URI base and suffix
    /// @param _uriBase URI base
    /// @param _uriSuffix URI suffix
    /// @dev Pushing size limits, so rather than having an explicit lock function, it can be implicit by renouncing ownership.
    function updateURI(string memory _uriBase, string memory _uriSuffix) public onlyOwner{
        __uriBase   = _uriBase;
        __uriSuffix = _uriSuffix;
    }

    /// Mint Giveaway
    /// @notice Mint Ronins for giveaway
    /// @param numTokens Number of tokens to mint
    function mintGiveaway(uint16 numTokens) public onlyOwner {
        require(tokensGiven + numTokens <= TOKENS_GIVEAWAY,"tokensGiven");
        require(tokenCount + numTokens <= TOKEN_MAX,"TOKEN_MAX");
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
    /// @notice Reserve Ronins. Max 10 per tx, one tx per 10 blocks. Can't be called by contracts. Must pay mint fee.
    /// @param _count Number of Ronins to reserve
    /// @dev requires tx.origin == msg.sender
    function reserve(uint16 _count) public payable{
        require(msg.sender == tx.origin,"origin");
        require(!paused,"paused");
        require(phase() == Phase.Reserve,"phase");
        require(_count <= TRANSACTION_LIMIT,"TRANSACTION_LIMIT");
        require(tokenCount + _count <= TOKEN_MAX, "TOKEN_MAX");
        require(msg.value >= uint(_count) * PRICE_MINT);
        require(
            reservations[msg.sender].block == 0 || block.number >= uint(reservations[msg.sender].block) + COOLDOWN
        ,"COOLDOWN");

        for(uint16 i = 0; i < _count; i++){
            reservations[address(msg.sender)].tokens.push(++tokenCount);

            emit Reserve(msg.sender,tokenCount);
        }
        reservations[msg.sender].block = uint24(block.number);
    }

    /// Claim
    /// @notice Mint reserved Ronins
    /// @param reservist Address of person with reserved Ronins.
    /// @param _count Number of reserved Ronins mint.
    /// @dev Allows anyone to call claim for anyone else. Will mint to the address that made the reservations.
    function claim(address reservist, uint _count) public{
        require(!paused,"paused");
        require(
            phase() == Phase.Claim
            ||
            phase() == Phase.Ceremony
        ,"phase");

        require( reservations[reservist].tokens.length >= _count, "_count");
        for(uint i = 0; i < _count; i++){
            uint tokenId = uint(reservations[reservist].tokens[reservations[reservist].tokens.length - 1]);
            reservations[reservist].tokens.pop();
            _mint(reservist,tokenId);
            emit Claim(reservist,tokenId);
        }
    }

    /// Mint
    /// @notice Mint unreserved Ronins. Must pay mint fee.
    /// @param _count Number of reserved Ronins mint.
    function mint(uint _count) public payable{
        require(!paused,"paused");
        require(
            phase() == Phase.Claim
            ||
            phase() == Phase.Ceremony
        ,"phase");
        require(msg.value >= _count * PRICE_MINT);

        require(tokenCount + uint16(_count) <= TOKEN_MAX,"TOKEN_MAX");

        for(uint i = 0; i < _count; i++){
            _mint(msg.sender,uint(++tokenCount));
        }
    }

    /// Ceremony
    /// @notice Commit Ronin to the Ceremony of Ascension
    /// @param tokenId ID of Ronin to commit
    function ceremony(uint tokenId) public{
        require(!paused,"paused");
        require(phase() == Phase.Ceremony,"phase");

        require(ownerOf(tokenId) == msg.sender,"ownerOf");
        require(tokenId < 10000, "ceremonyd");

        emit Ceremony(tokenId);

        _burn(tokenId);
        _mint(msg.sender,tokenId + uint(10000));
    }

    /// Phase
    /// @notice Get current Phase
    /// @return Phase (enum value)
    function phase() public view returns(Phase){
        uint _startTime = startTime;
        if(forceCeremony){
            return Phase.Ceremony;
        }else if(_startTime == 0){
            return Phase.Init;
        }else if(block.timestamp <= _startTime + 1 days){
            return Phase.Cat;
        }else if(block.timestamp <= _startTime + 2 days && tokenCount < TOKEN_MAX){
            return Phase.Reserve;
        }else if(totalSupply() < uint(TOKEN_MAX)){
            return Phase.Claim;
        }else{
            return Phase.Ceremony;
        }
    }

    /// Pause State
    /// @notice Get current pause state
    /// @return _paused Contract is paused
    /// @return _unpausable Contract is unpausable
    /// @return _startTime Start timestamp of Cat phase (adjusted for pauses)
    /// @return _pauseTime Timestamp of pause
    function pauseState() view public returns(bool _paused,bool _unpausable,uint _startTime,uint _pauseTime){
        return (paused,unpausable,startTime,pauseTime);
    }

    /// Reservation
    /// @notice Get struct properties of reservation mapping
    /// @param _reservist Address of reservation to check
    /// @return blockNumber block number of last reservation
    /// @return tokens Array of reserved, unclaimed tokens
    function reservation(address _reservist) public view returns(uint24 blockNumber, uint16[] memory tokens){
        return (reservations[_reservist].block,reservations[_reservist].tokens);
    }

    /// Token URI
    /// @notice ERC721 Metadata function
    /// @param _tokenId ID of token to check
    /// @return URI (string)
    function tokenURI(uint256 _tokenId) public view override  returns (string memory){
        require(_exists(_tokenId),"exists");

        if(_tokenId == 0){
            return string(abi.encodePacked(__uriBase,bytes("0"),__uriSuffix));
        }

        uint _i = _tokenId;
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(abi.encodePacked(__uriBase,bstr,__uriSuffix));
    }

    /// Supports Interface
    /// @notice Override ERC-165 function for conflict
    /// @param interfaceId Interface ID to check
    /// @return bool Contract supports this interface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721,  ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    /// Before Token Transfer
    /// @notice Override OpenZeppelin function conflict
    /// @param from from
    /// @param to to
    /// @param tokenId tokenId
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable){
        ERC721Enumerable._beforeTokenTransfer(from,to,tokenId);
    }
}