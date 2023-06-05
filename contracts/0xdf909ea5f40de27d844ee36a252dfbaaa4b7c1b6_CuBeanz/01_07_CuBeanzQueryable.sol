//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

error NotOwner();
error MaxTeamMints();
error RoundSoldOut();
error SaleNotStarted();
error InvalidValue();
error MaxMints();
error ContractMint();
error BurnNotActive();
error BattleNotStarted();
/*

░█████╗░██╗░░░██╗██████╗░███████╗░█████╗░███╗░░██╗███████╗
██╔══██╗██║░░░██║██╔══██╗██╔════╝██╔══██╗████╗░██║╚════██║
██║░░╚═╝██║░░░██║██████╦╝█████╗░░███████║██╔██╗██║░░███╔═╝
██║░░██╗██║░░░██║██╔══██╗██╔══╝░░██╔══██║██║╚████║██╔══╝░░
╚█████╔╝╚██████╔╝██████╦╝███████╗██║░░██║██║░╚███║███████╗
░╚════╝░░╚═════╝░╚═════╝░╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚══════╝

@0xShimazu
*/


import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract CuBeanz is  ERC721AQueryable , Ownable {

    //@dev mint constraints
    uint  constant roundOneSupply = 2222;
    uint  constant roundTwoSupply = 1778;
    uint  constant maxRoundOneMints = 2;
    uint  constant maxRoundTwoMints = 1;

    uint80  constant public burnRate = 10000 ether;
    uint80  constant public cubePrice = 22000 ether; 
    
    //@dev number of mints reserved for the cubeanz team
    uint maxTeamMints = 444;
    //@dev counter for teamMints
    uint public teamMints;

    //@dev this is maximum number of times that a cube can attack a bean
    //each time a bean attacks a cube, it's attack counter is incremented
    //50% chance to lose traits, 50% chance to upgrade a single trait.abi
    uint public maxAttacks  = 5;
    

    //@dev roundNum==1? round one is live. roundNum == 2? round two is live :)
    uint public roundNum;
    bool public burnMintActive;
    bool public revealed;   

    //@dev get ready....
    bool public battleStarted;
    

    MintTracker public mintTracker = MintTracker(0,0);

    //@dev tracks amount of tokens burned in round one and two.
    //@notice, we could have used built in totalSupply() function for round one
    //but for clean syntax we introduce a new counter
    struct MintTracker {
            uint16 roundOneMints;
            uint16 roundTwoMints;
        }

    //@dev ryoToken obtained by burning cubes
    IERC20 public ryoToken; 

    //@dev tokenUri factory
    string public baseURI;
    string public notRevealedUri;
    string public uriSuffix = ".json";
    
   //@dev maps tokenIds to number of times they've attacked
    mapping(uint => uint) public numAttacks;

    
    // @dev tracks mints per round: Rounds are 1 and 2
    mapping(address => mapping(uint => uint)) public mintsPerRound;




    constructor()
        ERC721A("CuBeanz", "CBZ")

    {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmYLBMRzuHewKXghmbgxfrQvzVDRDXxZVmJVDYp5kF5RgH");
    }

    event ATTACK(uint indexed numAttack,uint indexed tokenId);


     /*//////////////////////////////////////////////////////////
                               TEAM MINT
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/

    function teamMint(address to ,uint amount) external onlyOwner  {
        if(teamMints + amount > maxTeamMints) revert MaxTeamMints();
        teamMints+= amount;
        _mint(to,amount);
    }

    /*//////////////////////////////////////////////////////////
                       ROUND ONE AND TWO MINTS
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/

    function roundOneMint(uint amount) external  {
        if(roundNum!=1) revert SaleNotStarted();
        if(msg.sender != tx.origin) revert ContractMint();
        if(mintTracker.roundOneMints + amount > roundOneSupply) revert RoundSoldOut();
        if(mintsPerRound[msg.sender][1]  + amount > maxRoundOneMints) revert MaxMints();
         mintsPerRound[msg.sender][1] +=amount;
         mintTracker.roundOneMints += uint16(amount);
         _mint(msg.sender,amount);
    }

    function roundTwoMint(uint amount) external  {
        if(roundNum !=2) revert SaleNotStarted();
        if(msg.sender != tx.origin) revert ContractMint();
        if(mintTracker.roundTwoMints + amount > roundTwoSupply) revert RoundSoldOut();
        if(mintsPerRound[msg.sender][2] + amount > maxRoundTwoMints) revert MaxMints();
        mintsPerRound[msg.sender][2]  += amount;
        mintTracker.roundTwoMints += uint16(amount);
        _mint(msg.sender,amount);
    }

    /*//////////////////////////////////////////////////////////
                             RYO MINT
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/


     function ryoMint(uint amount) external{
         if(!burnMintActive) revert BurnNotActive();
         ryoToken.transferFrom(msg.sender,address(this), cubePrice * amount);
         _mint(msg.sender,amount);
     }

    /*//////////////////////////////////////////////////////////
                              ATTACK
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
     function attackBean(uint tokenId) public {
        if(msg.sender != ownerOf(tokenId)) revert NotOwner();
        if(!battleStarted) revert BattleNotStarted();
         require(numAttacks[tokenId] < maxAttacks);
         numAttacks[tokenId]++;
         emit ATTACK(numAttacks[tokenId],tokenId);
     }

     function gangUpOnBean(uint[] calldata tokenIds) external {
        for(uint i; i<tokenIds.length;i++){
            attackBean(tokenIds[i]);
        }

     }

    /*//////////////////////////////////////////////////////////
                             BURN MINTS
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function burnCube(uint tokenId) external {
        if(msg.sender != ownerOf(tokenId)) revert NotOwner();
        ryoToken.mint(msg.sender, burnRate);
        _burn(tokenId);
    }

    function burnBatchCubes(uint[] calldata tokenIds) external{
        for(uint i; i<tokenIds.length;i++){
            if(msg.sender != ownerOf(tokenIds[i])) revert NotOwner();
            _burn(tokenIds[i]);
        }
        ryoToken.mint(msg.sender, burnRate * tokenIds.length);
    }


    /*//////////////////////////////////////////////////////////
                                SETTERS
    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*/
    function setMaxAttacks(uint amountAttacks) external onlyOwner {
        require(amountAttacks > maxAttacks);
        maxAttacks = amountAttacks;
    }

    function setRyoToken(address _address) external onlyOwner{
        ryoToken =  IERC20(_address);
    }


    function setRevealed(bool status) external onlyOwner {
        revealed = status;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

   
    function setUriSuffix(string memory _newSuffix) external onlyOwner{
        uriSuffix = _newSuffix;
    }

      function setRoundNum(uint _roundNum) external onlyOwner{
            roundNum = _roundNum;
    }

    function setBattleStarted(bool status) external onlyOwner{
        battleStarted = status;
    }
    function setBurnMintActive(bool status) external onlyOwner{
        burnMintActive = status;
     }

 

    


 
 


    // FACTORY

    function tokenURI(uint256 _tokenId)
        public
        view

        //ignore
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId),uriSuffix))
                : "";
    }


  
    function withdrawRyoToken() external onlyOwner{
        uint balance = ryoToken.balanceOf(address(this));
        ryoToken.transfer(owner(), balance);
    }

   
    


}

interface IERC20{

    function mint(address holder, uint tokenId) external;
    function balanceOf(address account) external view returns(uint);
    function transferFrom(address from, address to, uint amount) external;
    function transfer(address to, uint amount) external;
}