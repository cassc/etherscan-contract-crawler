// SPDX-License-Identifier: MIT
/**
                                                                                                    
                                            ethkun <3 u                                                  
                                                                                                    
                                                                                                    
                                               ,,,***.                                              
                                               ,,,***.                                              
                                               ,,,***.                                              
                                            ,,,,,,*******                                           
                                            ,,,,,,*******                                           
                                         ,,,,,,,,,**********                                        
                                         ,,,,,,,,,**********                                        
                                         ,,,,,,,,,**********                                        
                                      ,,,,,,,,,,,,*************                                     
                                      ,,,,,,,,,,,,*************                                     
                                   ,,,,,,,,,,,,,,,****************                                  
                                   ,,,,,,,,,,,,,,,****************                                  
                                   ,,,,,,,,,,,,,,,****************                                  
                                ,,,,,,,,,,,,,,,,,,*******************                               
                                ,,,,,,,,,,,,,,,,,,*******************                               
                            .,,,,,,,,,,,,&&&,,,,,,******&&&*************                            
                            .,,,,,,,,,||||||,,,,,,******|||||||*********                            
                            .,,,,,,,,,||||||,,,,,,******|||||||*********                            
                         ,,,,,,,,,,,,,||||||,,,,,,******|||||||************                         
                         ,,,,,,,,,,,,,,,,,,,,,,,,,***#&&%******************                         
                      ,,,,,,,,,,,,,,,,,,,,,,&&&&&&&&&&&&%*********************.                     
                            .,,,,,,,,,,,,,,,,,,,,,***#&&%***************                            
                            .,,,,,,,,,,,,,,,,,,,,,***#&&%***************                            
                      ,,,,,,.      ,,,,,,,,,,,,,,,****************      ******.                     
                         ,,,,,,,,,,      ,,,,,,,,,**********      *********                         
                            .,,,,,,,,,,,,      ,,,***.      ************                            
                                ,,,,,,,,,,,,,,,      ,***************                               
                                ,,,,,,,,,,,,,,,      ,***************                               
                                   ,,,,,,,,,,,,,,,****************                                  
                                      ,,,,,,,,,,,,*************                                     
                                         ,,,,,,,,,**********                                        
                                            ,,,,,,*******                                           
                                            ,,,,,,*******                                           
                                               ,,,***.                                              
                                                                                                    
                                                                                                    


**/

// ethkun
// a celebration of The Merge
// by @eddietree and @SecondBestDad

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import 'base64-sol/base64.sol';

import "./IEthKunRenderer.sol";
import "./EthKunRenderer.sol";

/// @title ethkun
/// @author @eddietree
/// @notice ethkun is an 100% on-chain experimental NFT project
contract EthKun is ERC721A, Ownable {
    
    // TTD: 58750000000000000000000 
    uint256 public constant MAX_TOKEN_SUPPLY_GENESIS = 5875;

    // contracts
    IEthKunRenderer public contractRenderer;

    enum MintStatus {
        CLOSED, // 0
        PUBLIC // 1
    }

    MintStatus public mintStatus = MintStatus.CLOSED;
    bool public revealEnabled = false;
    bool public mergeEnabled = false;
    bool public demoteRerollEnabled = false;
    bool public burnSacrificeEnabled = false;

    mapping(uint256 => uint256) public seeds; // seeds for image + stats
    mapping(uint256 => uint) public level;
    uint256 public maxLevel = 64;
    uint256 public mergeBlockNumber = 0; // estimated block# to be injected

    // tier 0 (free mint)
    uint256 public tier0_supply = 2000;
    uint256 public tier0_price = 0.0 ether;
    uint256 public tier0_maxTokensOwnedInWallet = 2;
    uint256 public tier0_maxMintsPerTransaction = 1;

    // tier 1 (paid)
    uint256 public tier1_price = 0.01 ether;
    uint256 public tier1_maxTokensOwnedInWallet = 64;
    uint256 public tier1_maxMintsPerTransaction = 64;

    uint256 public constant SECS_PER_DAY = 86400;

    // events
    event EthKunLevelUp(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel); // emitted when an EthKun levels up
    event EthKunDied(uint256 indexed tokenIdDied, uint256 level, uint256 indexed tokenMergedInto); // emitted when an EthKun dies
    event EthKunSacrificed(uint256 indexed tokenId); // emitted when an EthKun gets sacrificed upon the alter of Vitty B
    event EthRerolled(uint256 indexed tokenId, uint256 newLevel); // emitted when an EthKun gets rerolled

    constructor() ERC721A("ethkun", "ETHKUN") {
        //contractRenderer = IEthKunRenderer(this);
    }

    modifier verifyTokenId(uint256 tokenId) {
        require(tokenId >= _startTokenId() && tokenId <= _totalMinted(), "Invalid");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(
            _ownershipOf(tokenId).addr == _msgSender() ||
                getApproved(tokenId) == _msgSender(),
            "Not approved nor owner"
        );
        
        _;
    }

    modifier verifySupplyGenesis(uint256 numToMint) {
        require(numToMint > 0, "Mint at least 1");
        require(_totalMinted() + numToMint <= MAX_TOKEN_SUPPLY_GENESIS, "Invalid");

        _;
    }

    // randomize seed
    function _saveSeed(uint256 tokenId) private {
        seeds[tokenId] = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId, msg.sender)));
    }

    /// @notice Burn sacrifice an ethkun at the altar of Lord Vitalik
    /// @param tokenId The tokenID for the EthKun
    function burnSacrifice(uint256 tokenId) external onlyApprovedOrOwner(tokenId) {
        //require(msg.sender == ownerOf(tokenId), "Not yours");
        require(burnSacrificeEnabled == true);

        _burn(tokenId);
        emit EthKunSacrificed(tokenId);
    }

    function _startTokenId() override internal pure virtual returns (uint256) {
        return 1;
    }

    function _mintEthKuns(address to, uint256 numToMint) private {
        uint256 startTokenId = _startTokenId() + _totalMinted();
         for(uint256 tokenId = startTokenId; tokenId < startTokenId+numToMint; tokenId++) {
            _saveSeed(tokenId);
            level[tokenId] = 1;
         }

         _safeMint(to, numToMint);
    }

    function reserveEthKuns(address to, uint256 numToMint) external onlyOwner {
        _mintEthKuns(to, numToMint);
    }

    function reserveEthKunsMany(address[] calldata recipients, uint256 numToMint) external onlyOwner {
        uint256 num = recipients.length;
        require(num > 0);

        for (uint256 i = 0; i < num; ++i) {
            _mintEthKuns(recipients[i], numToMint);    
        }
    }

    /// @notice Mint genesis ethkuns into your wallet!
    /// @param numToMint The number of genesis ethkuns to mint 
    function mintEthKunsGenesis(uint256 numToMint) external payable verifySupplyGenesis(numToMint) {
        require(mintStatus == MintStatus.PUBLIC, "Public mint closed");
        require(msg.value >= _getPrice(numToMint), "Incorrect ether sent" );

        // check max mint
        (uint256 maxTokensOwnedInWallet, uint256 maxMintsPerTransaction) = _getMaxMintsData();
        require(_numberMinted(msg.sender) + numToMint <= maxTokensOwnedInWallet, "Exceeds max mints");
        require(numToMint <= maxMintsPerTransaction, "Exceeds transaction max");

        _mintEthKuns(msg.sender, numToMint);
    }

    function _merge(uint256[] calldata tokenIds) private {
        uint256 num = tokenIds.length;
        require(num > 0);

        // all the levels accumulate to the first token
        uint256 tokenIdChad = tokenIds[0];
        uint256 accumulatedTotalLevel = 0;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 tokenLevel = level[tokenId];

            require( _ownershipOf(tokenId).addr == _msgSender() || getApproved(tokenId) == _msgSender(), "Denied");
            require(tokenLevel != 0, "Dead");

            accumulatedTotalLevel += tokenLevel;

            // burn if not main one
            if (i > 0) {
                _burn(tokenId);
                emit EthKunDied(tokenId, tokenLevel, tokenIdChad);

                // reset
                level[tokenId] = 0;
            }
        }

        require(accumulatedTotalLevel <= maxLevel, "Exceeded max level");

        uint256 prevLevel = level[tokenIdChad];
        level[tokenIdChad] = accumulatedTotalLevel;

        //_saveSeed(tokenIdChad);
        emit EthKunLevelUp(tokenIdChad, prevLevel, accumulatedTotalLevel);
    }

    /// @notice Merge several ethkuns into one buff gigachad ethkun, all the levels accumulate into the gigachad ethkun, but the remaining ethkuns are burned, gg
    /// @param tokenIds Array of owned tokenIds. Note that the first tokenId will be the one that remains and accumulates levels of other ethkuns, the other tokens will be BURNT!!
    function merge(uint256[] calldata tokenIds) external {
        require(_isRevealed() && mergeEnabled, "Not mergeable");
        _merge(tokenIds);
    }

    /// @notice Reroll the visuals/stats of ethkun, but unfortunately demotes them by -1 level :(
    /// @param tokenIds Array of owned tokenIds of ethkuns to demote
    function rerollMany(uint256[] calldata tokenIds) external {
        require(_isRevealed() && demoteRerollEnabled);

        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            uint256 tokenLevel = level[tokenId];

            require(_ownershipOf(tokenId).addr == _msgSender(), "Must own");
            require(tokenLevel > 1, "At least Lvl 1"); // need to be at least level 1 to reroll
            
            // reroll visuals/stats
            _saveSeed(tokenId); 

            // demote -1 evel
            uint256 tokenLevelDemoted = tokenLevel-1;
            level[tokenId] = tokenLevelDemoted; 

            emit EthRerolled(tokenId, tokenLevelDemoted);
        }
    }

    // taken from 'ERC721AQueryable.sol'
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    ///////////////////////////
    // -- GETTERS/SETTERS --
    ///////////////////////////
    function getNumMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function _getNumBabiesMinted() private view returns (uint256) {
        uint256 numTotalMinted = _totalMinted();

        if (numTotalMinted <= MAX_TOKEN_SUPPLY_GENESIS)
            return 0;

        return numTotalMinted - MAX_TOKEN_SUPPLY_GENESIS;
    }

    function getNumBabiesMinted() external view returns (uint256) {
        return _getNumBabiesMinted();
    }

    function setPricing(uint256[] calldata pricingData) external onlyOwner {
        // tier 0
        tier0_supply = pricingData[0];
        tier0_price = pricingData[1];
        tier0_maxTokensOwnedInWallet = pricingData[2];
        tier0_maxMintsPerTransaction = pricingData[3];

        // tier 1
        tier1_price = pricingData[4];
        tier1_maxTokensOwnedInWallet = pricingData[5];
        tier1_maxMintsPerTransaction = pricingData[6];

        require(tier0_supply <= MAX_TOKEN_SUPPLY_GENESIS);
    }

    function _getPrice(uint256 numToMint) private view returns (uint256) {
        uint256 numMintedAlready = _totalMinted();
        return numToMint * (numMintedAlready < tier0_supply ? tier0_price : tier1_price);
    }

    function getPrice(uint256 numToMint) external view returns (uint256) {
        return _getPrice(numToMint);
    }

    function _getMaxMintsData() private view returns (uint256 maxTokensOwnedInWallet, uint256 maxMintsPerTransaction) {
        uint256 numMintedAlready = _totalMinted();

        return (numMintedAlready < tier0_supply) ? 
            (tier0_maxTokensOwnedInWallet, tier0_maxMintsPerTransaction) 
            : (tier1_maxTokensOwnedInWallet, tier1_maxMintsPerTransaction);
    }

    function getMaxMintsData() external view returns (uint256 maxTokensOwnedInWallet, uint256 maxMintsPerTransaction) {
        return _getMaxMintsData() ;
    }

    function setMaxLevel(uint256 _maxLevel) external onlyOwner {
        maxLevel = _maxLevel;
    }

    function setMintStatus(uint256 _status) external onlyOwner {
        mintStatus = MintStatus(_status);
    }

    function setContractRenderer(address newAddress) external onlyOwner {
        contractRenderer = IEthKunRenderer(newAddress);
    }

    function setRevealed(bool _revealEnabled) external onlyOwner {
        revealEnabled = _revealEnabled;
    }

    function setMergeEnabled(bool _enabled) external onlyOwner {
        mergeEnabled = _enabled;
    }

    function setMergeBlockNumber(uint256 newMergeBlockNumber) external onlyOwner {
        mergeBlockNumber = newMergeBlockNumber;
    }

    function setBurnSacrificeEnabled(bool _enabled) external onlyOwner {
        burnSacrificeEnabled = _enabled;
    }

    function setDemoteRerollEnabled(bool _enabled) external onlyOwner {
        demoteRerollEnabled = _enabled;
    }

    function numberMinted(address addr) external view returns(uint256){
        return _numberMinted(addr);
    }

    function isGenesis(uint256 tokenId) external pure returns(bool){
        return tokenId <= MAX_TOKEN_SUPPLY_GENESIS;
    }

    ///////////////////////////
    // -- MERKLE NERD STUFF --
    ///////////////////////////
    bytes32 public merkleRoot = 0x0;
    bool public merkleMintEnabled = false;
    uint256 public constant merkleMintMax = 1;

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMerkleMintEnabled(bool _enabled) external onlyOwner {
        merkleMintEnabled = _enabled;
    }

    function _verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) private view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function verifyMerkle(bytes32[] calldata _proof, bytes32 _leaf) external view returns (bool) {
        return _verifyMerkle(_proof, _leaf);
    }

    function verifyMerkleAddress(bytes32[] calldata _proof, address from) external view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(from));
        return _verifyMerkle(_proof, leaf);
    }

    function mintMerkle(bytes32[] calldata _merkleProof, uint256 numToMint) external verifySupplyGenesis(numToMint) {
        require(merkleMintEnabled == true, "Merkle closed");
        require(_numberMinted(msg.sender) + numToMint <= merkleMintMax, "Can claim only 1");

        // verify merkle        
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(_verifyMerkle(_merkleProof, leaf), "Invalid proof");

        _mintEthKuns(msg.sender, numToMint);
    }

    ///////////////////////////
    // -- TOKEN URI --
    ///////////////////////////
    function _tokenURI(uint256 tokenId) private view returns (string memory) {
        //string[13] memory lookup = [  '0', '1', '2', '3', '4', '5', '6', '7', '8','9', '10','11', '12'];

        uint256 seed = seeds[tokenId];
        unchecked{ // unchecked so it can run over
            seed += mergeBlockNumber;
        }

        uint256 currentLevel = level[tokenId];

        string memory image = contractRenderer.getSVG(seed, currentLevel);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"ethkun #', Strings.toString(tokenId),'",',
                    '"description": "ethkun is an 100% on-chain dynamic NFT project with unique functionality and fun merge mechanics, made to celebrate The Merge! Gambatte ethkun!",',
                    '"attributes":[',
                        contractRenderer.getTraitsMetadata(seed),
                        _getStatsMetadata(seed, currentLevel),
                        '{"trait_type":"Genesis", "value":', (tokenId <= MAX_TOKEN_SUPPLY_GENESIS) ? '"Yes"' : '"No"', '},',
                        '{"trait_type":"Steaking", "value":', (steakingStartTimestamp[tokenId] != NULL_STEAKING) ? '"Yes"' : '"No"', '},',
                        '{"trait_type":"Level", "value":',Strings.toString(currentLevel),'}'
                    '],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _tokenUnrevealedURI(uint256 tokenId) private view returns (string memory) {
        uint256 seed = seeds[tokenId];
        string memory image = contractRenderer.getUnrevealedSVG(seed);

        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": ', '"ethkun #', Strings.toString(tokenId),'",',
                    '"description": "ethkun is an 100% on-chain dynamic NFT project with unique functionality and fun merge mechanics, made to celebrate The Merge! Gambatte ethkun!",',
                    '"attributes":[{"trait_type":"Waiting for The Merge", "value":"True"}],',
                    '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(image)), '"}' 
                )
            ))
        );

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    function _isRevealed() private view returns (bool) {
        return revealEnabled && block.number > mergeBlockNumber;   
    }

    function tokenURI(uint256 tokenId) override(ERC721A) public view verifyTokenId(tokenId) returns (string memory) {
        if (_isRevealed()) 
            return _tokenURI(tokenId);
        else
            return _tokenUnrevealedURI(tokenId);
    }

    function _randStat(uint256 seed, uint256 div, uint256 min, uint256 max) private pure returns (uint256) {
        return min + (seed/div) % (max-min);
    }

    function _getStatsMetadata(uint256 seed, uint256 currLevel) private pure returns (string memory) {
        //string[11] memory lookup = [ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10' ];

        string memory metadata = string(abi.encodePacked(
          '{"trait_type":"Kimochii", "display_type": "number", "value":', Strings.toString(_randStat(seed, 2, 1, 5+currLevel)), '},',
          '{"trait_type":"UWU", "display_type": "number", "value":', Strings.toString(_randStat(seed, 3, 2, 10+currLevel)), '},',
          '{"trait_type":"Ultrasoundness", "display_type": "number", "value":', Strings.toString(_randStat(seed, 4, 2, 10+currLevel)), '},',
          '{"trait_type":"Fungibility", "display_type": "number", "value":', Strings.toString(_randStat(seed, 5, 2, 10+currLevel)), '},',
          '{"trait_type":"Sugoiness", "display_type": "number", "value":', Strings.toString(_randStat(seed, 6, 2, 10+currLevel)), '},',
          '{"trait_type":"Kakkoii", "display_type": "number", "value":', Strings.toString(_randStat(seed, 7, 2, 10+currLevel)), '},',
          '{"trait_type":"Kawaii", "display_type": "number", "value":', Strings.toString(_randStat(seed, 8, 2, 10+currLevel)), '},',
          '{"trait_type":"Moisturized", "display_type": "number", "value":', Strings.toString(_randStat(seed, 9, 2, 10+currLevel)), '},'
        ));

        return metadata;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    ///////////////////////////
    // -- STEAKING --
    ///////////////////////////

    bool public steakingEnabled = false;
    bool public mintingBabiesEnabled = false;
    uint256 public minSteakingLevel = 8; // ethkun's min level to allow for steaking
    uint256 private constant NULL_STEAKING = 0;

    // steaking curve parameters
    uint256 public steakingMinDays = 2;
    uint256 public steakingCurveDivisor = 8;
    uint256 public steakingLevelBoostDivisor = 16;

    // steaking
    mapping(uint256 => uint256) private steakingStartTimestamp; // tokenId -> steaking start time (0 = not steaking).
    mapping(uint256 => uint256) private steakingTotalTime; // tokenId -> cumulative steaking time, does not include current time if steaking
    
    // events
    event EventStartSteaking(uint256 indexed tokenId);
    event EventEndSteaking(uint256 indexed tokenId);
    event EventForceEndSteaking(uint256 indexed tokenId);
    event EventBirthBaby(uint256 indexed tokenIdParent, uint256 indexed tokenIdBaby);

    // currentSteakingTime: current steaking time in secs (0 = not steaking)
    // totalSteakingTime: total time of steaking (in secs)
    function getSteakingInfoForToken(uint256 tokenId) external view returns (uint256 currentSteakingTime, uint256 totalSteakingTime, bool steaking)
    {
        currentSteakingTime = 0;
        uint256 startTimestamp = steakingStartTimestamp[tokenId];

        // is steaking?
        if (startTimestamp != NULL_STEAKING) { 
            currentSteakingTime = block.timestamp - startTimestamp;
        }

        totalSteakingTime = currentSteakingTime + steakingTotalTime[tokenId];
        steaking = startTimestamp != NULL_STEAKING;
    }

    function setSteakingEnabled(bool allowed) external onlyOwner {
        steakingEnabled = allowed;
    }

    function setMintingBabiesEnabled(bool allowed) external onlyOwner {
        mintingBabiesEnabled = allowed;
    }

    function setSteakingMinLevel(uint256 _minLvl) external onlyOwner {
        minSteakingLevel = _minLvl;
    }

    function _toggleSteaking(uint256 tokenId) private onlyApprovedOrOwner(tokenId)
    {
        uint256 startTimestamp = steakingStartTimestamp[tokenId];

        if (startTimestamp == NULL_STEAKING) { 
            // start steaking
            require(steakingEnabled, "Disabled");
            require(level[tokenId] >= minSteakingLevel, "Not level");
            steakingStartTimestamp[tokenId] = block.timestamp;

            emit EventStartSteaking(tokenId);
        } else { 
            // start unsteaking
            steakingTotalTime[tokenId] += block.timestamp - startTimestamp;
            steakingStartTimestamp[tokenId] = NULL_STEAKING;

            emit EventEndSteaking(tokenId);
        }
    }

    /// @notice Token steaking on multiple ethkun tokens!
    /// @param tokenIds Array of ethkun tokenIds to toggle steaking 
    function toggleSteaking(uint256[] calldata tokenIds) external {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _toggleSteaking(tokenId);
        }
    }

    function _resetAndClearSteaking(uint256 tokenId) private {
        // end staking
        if (steakingStartTimestamp[tokenId] != NULL_STEAKING) {
            steakingStartTimestamp[tokenId] = NULL_STEAKING;
            emit EventEndSteaking(tokenId);
        }

        // clear total staking time
        if (steakingTotalTime[tokenId] != NULL_STEAKING)    
            steakingTotalTime[tokenId] = NULL_STEAKING;
    }

    function _adminForceStopSteaking(uint256 tokenId) private {
        require(steakingStartTimestamp[tokenId] != NULL_STEAKING, "Character not steaking");
        
        // accum current time
        uint256 deltaTime = block.timestamp - steakingStartTimestamp[tokenId];
        steakingTotalTime[tokenId] += deltaTime;

        // no longer steaking
        steakingStartTimestamp[tokenId] = NULL_STEAKING;

        emit EventEndSteaking(tokenId);
        emit EventForceEndSteaking(tokenId);
    }

    function adminForceStopSteaking(uint256[] calldata tokenIds) external onlyOwner {
        uint256 num = tokenIds.length;

        for (uint256 i = 0; i < num; ++i) {
            uint256 tokenId = tokenIds[i];
            _adminForceStopSteaking(tokenId);
        }
    }

    function _canSpawnEthKunBaby(uint256 tokenId) private view returns (bool) {
        uint256 currentSteakingTime = 0;
        uint256 startTimestamp = steakingStartTimestamp[tokenId];

        // is steaking?
        if (startTimestamp != NULL_STEAKING) { 
            currentSteakingTime = block.timestamp - startTimestamp;
        }

        uint256 totalSteakingTime = currentSteakingTime + steakingTotalTime[tokenId];
        
        return 
            totalSteakingTime >= _getSecsSteakingRequiredToMintBaby(tokenId)  // check staking time
            && level[tokenId] >= minSteakingLevel // check level
            && steakingStartTimestamp[tokenId] != NULL_STEAKING; // is staking
    }

    function canSpawnEthKunBaby(uint256 tokenId) external view returns (bool) {
        return _canSpawnEthKunBaby(tokenId);
    }

    /// @notice Set parameters for steaking
    /// @param _steakingMinDays Minimum days for steaking
    /// @param _steakingCurveDivisor Per baby coefficient divisor
    function setSteakingParams(uint256 _steakingMinDays, uint256 _steakingCurveDivisor, uint256 _steakingLevelBoostDivisor) external onlyOwner {
        steakingMinDays = _steakingMinDays;
        steakingCurveDivisor = _steakingCurveDivisor;
        steakingLevelBoostDivisor = _steakingLevelBoostDivisor;
    }

    function _getSecsSteakingRequiredToMintBaby(uint256 tokenId) private view returns (uint256) {

        // formula goes as such
        // secs requires to mint =
        //      min days
        //      + secsCurveFromBabies
        //      - levelBoost

        // curve for babies minted
        uint256 numBabiesMinted = _getNumBabiesMinted();
        uint256 secsFromBabiesMinted = (SECS_PER_DAY*numBabiesMinted)/steakingCurveDivisor;

        // reduction for higher level
        uint256 secsLevelSubtractor = 0;
        uint256 currLevel = level[tokenId];
        if (currLevel > minSteakingLevel) {
            secsLevelSubtractor = (SECS_PER_DAY*(currLevel - minSteakingLevel)) / steakingLevelBoostDivisor;
        }

        // cannot go below steakingMinDays
        if (secsLevelSubtractor > secsFromBabiesMinted) {
            secsLevelSubtractor = secsFromBabiesMinted;
        }

        uint256 secMinSteaked = steakingMinDays * SECS_PER_DAY + secsFromBabiesMinted - secsLevelSubtractor;
        
        // convert days to seconds
        return secMinSteaked;
    }

    /// @notice Mint a baby ethkun from steaked parent ethkun!
    /// @param parentTokenIds Steaked ethkun tokenIds to spawn from
    function mintEthKunBaby(uint256[] calldata parentTokenIds) external {
        _mintEthKunBabies(parentTokenIds);
    }

    function _mintEthKunBabies(uint256[] calldata parentTokenIds) private {
        require(mintingBabiesEnabled == true, "Babies disabled");
        //require(steakingEnabled == true, "Steaking disabled");

        uint256 num = parentTokenIds.length;
        for (uint256 i = 0; i < num; ++i) {

            uint256 parentTokenId = parentTokenIds[i];

            require(_ownershipOf(parentTokenId).addr == _msgSender() || getApproved(parentTokenId) == _msgSender(), "Denied");
            require(_canSpawnEthKunBaby(parentTokenId), "Not ready");

            // mint a new baby to owner's address!
            _mintEthKuns(_ownershipOf(parentTokenId).addr, 1);

            // reset staking to now
            steakingTotalTime[parentTokenId] = 0;
            steakingStartTimestamp[parentTokenId] = block.timestamp;

            uint256 childTokenId = _totalMinted();
            emit EventBirthBaby(parentTokenId, childTokenId);
        }
    }

     function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
        // bypass for minting and burning
        if (from == address(0) || to == address(0))
            return;

        // transfers will cancel+clear steaking
        if (from != address(0)) {
            for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; ++tokenId) {
                _resetAndClearSteaking(tokenId);
            }
        }
    }

    function getSecsSteakingRequiredToMintBaby(uint256 tokenId) external view returns (uint256) {
        return _getSecsSteakingRequiredToMintBaby(tokenId);
    }
}