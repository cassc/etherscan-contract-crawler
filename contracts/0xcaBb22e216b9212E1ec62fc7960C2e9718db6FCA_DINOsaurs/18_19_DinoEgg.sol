// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./Dino.sol";

contract DinoEgg is ERC721, ERC721Burnable, Ownable, ERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Hatch public hatchPhase;
    States public currentState;

    IERC20 public dinoToken;
    DinoNFT public dinoHatchery;

    //6 counters, 1 for egg, 5 for dino
    Counters.Counter public _tokenIDcounter;
    Counters.Counter[5] private _base;

    //lets enumerate tokenIDs by owner - [owner][index => tokenID]
    mapping(address => mapping(uint256 => uint256)) public _ownedTokens;

    //WL
    mapping(address => bool) public isVIP;
    mapping(address => bool) public isBigStaker;
    mapping(address => bool) public isSmallStaker;
    mapping(address => uint) public vipMintCount;
    mapping(address => uint) public stakersMintCount;
    mapping(address => uint) public publicMintCount;
    
    mapping(uint => bool) public burnedIDs;
    uint public vipMintLimit = 10;
    uint public stakerLimits = 3;
    uint public pubMintLimit = 2;
    uint public pubMintThrottle = 2;
    uint public totalMinted;
    uint maxSupply = 10000;
    string public baseURI;
    uint256 cost = .0333 ether;
    uint private nonce;
    address dinoWallet;

    enum States {
        bigStakeMint,
        littleStakeMint,
        publicMint
    }

    enum Hatch {
        cannotHatch,
        canHatch
    }

    constructor(
        address dino,
        address _dinoToken,
        address _royaltyWallet,
        address _dinoWallet
    )
    ERC721("Dino Mystery Egg", "Degg")
    {
        _setDefaultRoyalty(_royaltyWallet, 1000);
        dinoWallet = _dinoWallet;
        dinoToken = IERC20(_dinoToken);
        dinoHatchery = DinoNFT(dino);
        currentState = States.bigStakeMint;
        hatchPhase = Hatch.cannotHatch;
    }
    /*phase management */
    function canHatch() public onlyOwner
    {
        if(hatchPhase == Hatch.cannotHatch){
            hatchPhase = Hatch.canHatch;
        }
    }
    function cannotHatch() public onlyOwner
    {
        if(hatchPhase == Hatch.canHatch){
            hatchPhase = Hatch.cannotHatch;
        }
    }
    function forwardState() public onlyOwner
    {
        if(currentState == States.bigStakeMint) {
            currentState = States.littleStakeMint;
        } else if(currentState == States.littleStakeMint) {
            currentState = States.publicMint;
        }
    }
    function backState() public onlyOwner
    {
        if(currentState == States.publicMint){
            currentState = States.littleStakeMint;
        } else if(currentState == States.littleStakeMint){
            currentState = States.bigStakeMint;
        }
    }
    /* end */
    
    /*WL section */
    function addVIPs(address[] calldata _vip) public onlyOwner
    {
        for(uint i = 0; i < _vip.length; i++){
            isVIP[_vip[i]] = true;
        }
    }
    function addBigStakers(address[] calldata _bigStaker) public onlyOwner
    {
        for(uint i = 0; i < _bigStaker.length; i++){
            isBigStaker[_bigStaker[i]] = true;
        }
    }
    function addSmallStakers(address[] calldata _smallStakers) public onlyOwner
    {
        for(uint i = 0; i < _smallStakers.length; i++){
            isSmallStaker[_smallStakers[i]] = true;
        }
    }
    /* end */

    //requires token approval
    function vipAndTeamMint(uint quantity) public
    {
        require(isVIP[msg.sender] == true,"you're up to no good if you're seeing this.");
        require(vipMintCount[msg.sender] + quantity <= vipMintLimit, "that's all you get from this mint function");
        require(dinoToken.transferFrom(msg.sender, address(this), (1000 * 10 ** 18) * quantity),"either no approval or not enough dino");

        for(uint i = 0; i < quantity; i++){
            //increase tokenID counter to start at one
            _tokenIDcounter.increment();
            //current tokenID
            uint tokenID = _tokenIDcounter.current();
            //vip mint count
            vipMintCount[msg.sender] ++;
            //mint the egg to msg sender
            _safeMint(msg.sender, tokenID);
            //increase total minted counter
            totalMinted++;
            //emit egg mint event
            emit eggMinted(msg.sender, tokenID);
            _ownedTokens[msg.sender][i] = tokenID;
            
        }
    }


    //must have token approval prior to calling
    function stakersMint(uint quantity) public {
        require(currentState != States.publicMint,"private sales closed");
        require(stakersMintCount[msg.sender] + quantity <= stakerLimits, "you've minted the max amount for this phase");
        require(dinoToken.transferFrom(msg.sender, address(this), (1000 * 10 ** 18) * quantity),"either no approval or not enough dino");

        if(currentState == States.bigStakeMint){
            require(isBigStaker[msg.sender] == true, "youre not a big staker. check back later");
        } else if(currentState == States.littleStakeMint) {
            require(dinoToken.balanceOf(msg.sender) >= 10000 * 10 **18 || isSmallStaker[msg.sender] == true, "not staking or have enough dino");
        }

        //loop through quantity amount and begin egg minting process
        for(uint i = 0; i < quantity; i++){
            stakersMintCount[msg.sender] ++;
            //increase tokenID counter
            _tokenIDcounter.increment();
            //current tokenID
            uint tokenID = _tokenIDcounter.current();
            //mint the egg to msg sender
            _safeMint(msg.sender, tokenID);
            //increase total minted counter
            totalMinted++;
            //emit egg mint event
            _ownedTokens[msg.sender][i] = tokenID;
            emit eggMinted(msg.sender, tokenID);
            
        }
    }
    //requires token approval
    function publicMint(uint quantity) public
    {   
        require(currentState != States.bigStakeMint && currentState != States.littleStakeMint, "public sale has not opened yet.");
        //cap max supply at 10_000
        require(_tokenIDcounter.current() <= maxSupply, "max supply met.");
        //move dino tokens from caller to contract for batch burning
        require(dinoToken.transferFrom(msg.sender, address(this), (1000 * 10 ** 18) * quantity),"either no approval or not enough dino");
        //max 2 per wallet on public sale
        require(publicMintCount[msg.sender] + quantity <= pubMintLimit,"you've minted max for public");

        for(uint i = 0; i < quantity; i++){
            publicMintCount[msg.sender] ++;
            //increase tokenID counter
            _tokenIDcounter.increment();
            //current tokenID
            uint tokenID = _tokenIDcounter.current();
            //mint the egg to msg sender
            _safeMint(msg.sender, tokenID);
            //increase total minted counter
            totalMinted++;
            //emit egg mint event
            _ownedTokens[msg.sender][i] = tokenID;
            emit eggMinted(msg.sender, tokenID);
        }

    }

    //charges ether 
    function hatchEgg(uint _eggID) public payable
    {    
        //gotta own the egg if you wanna hatch it        
        require(ownerOf(_eggID) == msg.sender, "what are u doing?");
        require(hatchPhase == Hatch.canHatch,"its not time to hatch your egg yet");
        require(msg.value >= cost,"not enough ether sent");
        
        _burn(_eggID);
        burnedIDs[_eggID] = true;
        emit eggBurn(msg.sender, _eggID);
        randomHatch(msg.sender);
        emit numberRequested(_eggID, msg.sender);
        
    }

    function setBaseURI(string memory _newURI) public onlyOwner
    {
        baseURI = _newURI;
    }

    function _baseURI() internal view virtual override returns (string memory)
    {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI))
        : "";
    }
    //transfers dino from contract to dead wallet. no other options.
    function burnDinoTokens() public onlyOwner
    {
        uint256 burnBalance = dinoToken.balanceOf(address(this));
        dinoToken.transfer(address(0x000000000000000000000000000000000000dEaD), burnBalance);
    }
    //withdraws ether to contract owner
    function withdrawEther() public onlyOwner
    {
        uint256 contractEthBal = address(this).balance;
		payable(dinoWallet).transfer(contractEthBal); 
    }
    function setCost(uint _newCost) public onlyOwner
    {
        cost = _newCost;
    }
    function setPubLimit(uint _amount) public onlyOwner
    {
        pubMintLimit = _amount;
    }
    function setPubThrottle(uint _amount) public onlyOwner
    {
        pubMintThrottle = _amount;
    }
    function setStakerLimits(uint _amount) public onlyOwner
    {
        stakerLimits = _amount;
    }

    function randomHatch(address _hatchee) internal
    {  
        uint word = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), block.coinbase, msg.sender, nonce++)));
        uint range = (word % 5) + 1;
        emit numberResolved(range, msg.sender);

        while(true) {
            if(_base[range - 1].current() < 2000) {  
                uint startingIndex = (range - 1) * 2000 + 1; // 1, 2001, 4001 etc.    
                uint tokenid = _base[range - 1].current() + startingIndex;
                _base[range - 1].increment();
                dinoHatchery.indexHatcher(_hatchee, tokenid);
                emit hatchSent(_hatchee, tokenid);
                break;
            }
            else {
                word = uint256(keccak256(abi.encodePacked(word)));
                range = (word % 5) + 1;
            }
        }
    }
    //override to make royalties and 721 get along
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /* events */
    event eggMinted
    (
        address receiver,
        uint eggID
    );
    event eggBurn
    (
        address burner,
        uint eggID
    );
    event hatchSent
    (
        address receiver,
        uint dinoID
    );
    event numberRequested(
        uint indexed eggID,
        address indexed caller
    );
    event numberResolved(
        uint indexed number,
        address indexed caller
    ); 

//neo was here
}