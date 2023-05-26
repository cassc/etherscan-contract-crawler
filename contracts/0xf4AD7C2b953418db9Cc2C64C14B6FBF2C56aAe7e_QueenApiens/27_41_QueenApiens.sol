// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
/**
                    .......................................................                         
                   .............................................................                    
                .......................''''''..'''''''...''.........................                
              ...................''''''''''''''',,,''''''''''''''.....................              
           ................'''''''''''',,,,;;,,,,,,,,,,,,,,,,,,'''''.......................         
          .............'''''''',,,,,,,,,;;;;;;;;;;;;;;;;;;;;;,,,,,,,'''''''''''............         
    ...............'''''''',,,,,,;;;;;;;;:::::::::::::::::::;;;;;,,,,;,,,,,''''''............       
 ...................''''',,,,,;;;;::::::::c::cccc::cccccccc:::::::;;;;;;;,,,,,''''.............     
...................''',,,,;;;;;;::cccccccc;'........,clllccccccccc:::::;;;,,,,,,''................  
................'''',,,;;;;;::c::ccllllll:..         .cllllllllllccc:::;;;;,,,,,,''.................
...............''',,,;;;;;:::cccclllool:'..           .;looloolllllccc:::::;;;,,,'''................
.............''',,,,;;:::::ccccllooool:'.....           .:odoooooolllccccc:::;;;,,,,'''.............
...........''',,;;;;;::cccccclllooodl:,'.......          .;odddddooolllllcccc::;;;,,,,'''...........
........'''',,,;;;::::cccllllooooddo:;,'......    .....   .:xxxddddoooloollccc::;;;;,,,,'''.........
.....''''''',,;;:::::cllloooooddddxl;,,,'.',,,,,,;::::;'.  ,dkxxxddddooooolllcc:::::;;;,,,''........
....'',,,,,,,;;::ccccclooooodddxxxxo:,;;',;:cccccccccc::;..;dkxxxxxddddoooollccccc::::;;;,,'''......
..''',,,;;;;;;::ccccclloodddddxxkxxd:,::,,;;:ccc::::;;;;;'.,cldkkxxxxxdddoolllllcccccc::;;;,,'''....
'',,;;;;;;:::::ccclllooodddxxxxkkdoo:,cl:,,,;col:;;,,',,,..'::lkkkkxxxxdddoooooollllccc:::;;,,,,,'''
cc::::::::cccccclllloodddxxxxkkkkdll:,cdolccccooc:;;:::;'..,;:okOOkkkxxxddddddoooolllccccc:::;;;;;::
XXK0OkxdoollllllloooodddxxxkkkkkOxooc,';oxdollooc;;;;cc,. .';cxOOOOOkkxxxxxxddddddooolllllloodxkO0KX
WWWWWWWNXXK0OkkxdddddoodxxxkkkOkOkddl,'cxkOOOkddolccccc:'..,lkOO0OOOOkkkxxkxdoodddxxxkkO0KXNNWWWWWWW
NNWWWWWWWWWWWWWNXXKK0OdoddxkkOOOOxc;:;;okkOOOkxdolccclcc:..,x00000OOOOkkkxxdodO0KKXNNWWWWWWWWWWWWWNN
lodxkOO00KXXNNNWWWWWWWNX0xdxxxkOOxl:;;;dkkkkkxdlccccclll:...oO0000OOOkxxxdx0XNWWWWWWWNNXXKK00Okkxdol
,;::ccllloddxk0KXNNNWNNWNOlloodxkdoc;,,:oxkkxxolcccclll:'...:k0000kxxdolllkNNNNNNNNXK0kxdoollcc:::;;
,;::ccllooddxkO0KXXNNNNNNXklc:cloodl,,:,,:ldxxdollcc:,..;,..,dOkkxollccclkXNNNNNNXXK0Oxddoollcc:::;,
OO0000KKKKKXXXXXXXNNNNWNWWNXK0kdccoc,:c,.',,,;,,''.....;l:..'ldolc::ok0KXNWWWWNNNNNXXXXXXKKKK0000OOO
oxkOO00KKKXXXXNNNNNNNWWWWWWWWWWNKko;,:c,..,,''.........:c,..':c::cxKNWWWWWWWWWWWWNNNNXXXXKKK000OOkdo
',,;::ccllooddxxkkOOKXNNNNNXXXXNXOdodo;'.':c;'.... ...,,........;ok0KXXXXNNNNNXKOkkkxxddoolcc::;;,,'
.'',;;:::clloooddxOKXNNNNNNNNWWWXkxkkx:........    ... ...........';cxKNNNNNNNNXKOkdddollcc::;;,,''.
.'',,;;;:clodxkO0KXNNWWWWWWWWNKkl;,'..........         ... ........;lkXWWWWWWWNNNXK00Oxdolc:;;,,''..
..'',:ldxO0XXNNWWNNNNXXXXKKXXKkc,.............         ..........,ldxOXXKKXXXXXXNNNNWWNXK0Okdc;,''..
..'',;:clodxxkkkkxxxxxxxkOKXXKK0x:....'''......          .;c;. .,oddxkKXX0Okkkxxxxkkkkkkxxdol:;''...
...''',,,;::ccllloooooddkO0Okk0KXKd,..,'.......           ,c:' .cdddxxkOO0Okxddoooolllccc::;;,'.....
.....'''',;;;:ccclllllodddxk0XXKXXKO:......               .;lc..cdddxk00kxxddoolllccc:::;;,,''......
........'',,,;;::cccllodxOKNWWXXKKKKk,.....              . .cl,.:ddddkKWNKOxdollcc:::;;,,,'''.......
..........'',,,;;:cccox0XNNXK0KXKKKXk,..,c:.               .,c,.:ooddxOKNNNX0xocc::;;,,'''..........
..........'''',,,;::coxkkxxdokKKKKK0x;..cOo.               .,:,.;looddxxdxkkkxl:;;;,,''''...........
...........''''',,;;:ccccclco0XKKKOxo:..,oo,               .;c'':loooddddlc:::;;;,,'''''............
  ...........'''',,;;;:::::cxKXKOxdol;..'okl.              .:c'':loooooddl:;;;;,,,,'''..............
   .............''',,,,;;;:d00Okxddoc,..'d0d.        .     .lo,':loooooodo:;;;,,,''''...............
   ................''',,,;dO0OOOOOko:'...lkd, ...,,,,,;'.  .''.':looooooooc,,''''''................ 
   ..................'',,cOKKKKK0Oxl,....:dx:.'oxdooool;.    ..';loollllool,''''''................  
    ..................'''l0KKKK00kd:'....:ddl;okc,,,,,,,,,,,,''.;lllllloooo:..................      
     ...................,dKKKK0Okdo;.....:ddkOkxdollllllccc:;,'.;clllllllodc'..............         
           .............;kK0OOkxxdl,...:xOOkOxldkdl:,,,';lllcc,',:llcccllool,............           
            ............c0KOkkkkkd:.':d0KKKK0c'dKxl'    .';cllc,',cllloooodl,.........              
              .........'dK0OOkOkxc',oOKKKKK0kllO0o;.       :ollc,.;llllloodo;......                 
                .......,kK0OOOkxo;;d0KKKKKK0dlx0Ol,.       ;oollc;';loooddddc....                   
                   ....:OK0OOxdoc;oOKKKKK0KOooxOOkxdll:;;,':ooollc,'cxxxdxddl'..                    
                     ..cKK0kddol:cx00KKKK0KOxdddxxxddxOOkxddooollc:.,dkxxxxdl.                      
 */
import "./Allowable.sol";
import "./PackableOwnership.sol";
import { SetContractMetadataRenderable, RenderableData } from "./SetContractMetadataRenderable.sol";
import { DEFAULT, FLAG, PRE } from "./SetFlexibleMetadata.sol";
error ApienAlreadyClaimed(uint256 id);
error BagAlreadyClaimed(uint256 id);
error InvalidPayment(uint256 cost, uint256 amount);
error Unphased();
error NotInTreasury(uint256 tokenId);
/// @title Apiens Generation 2: Female Apiens
/// @author @OsmOnomous https://osm.tools
contract QueenApiens is Allowable {    
    using SetContractMetadataRenderable for RenderableData;
    RenderableData renderings;
    // minting phases
    uint256 ALLOW_PHASE = 0;
    uint256 ALLOW_BAG_PHASE = 1;
    uint256 CLAIM_PHASE = 2;
    uint256 PUBLIC_PHASE = 3;
    
    // claim tracking addresses
    address GENESIS_BAG = 0xD2C83498882AfF028E18aF5FB46120342c5129bD;
    address APIENS = 0xcf8896D28B905cEfd5fFbDDD5Dbfa0eEfF8d938B;
    address GENESIS_BAG_ALLOW = address(0x0);

    // supply and allowances
    uint256 MAX_SUPPLY = 8888;

    // allowed phase
    uint256 ALLOW_PER = 5;
    uint256 ALLOW_SUPPLY = 8600;
    uint256 ALLOW_PRICE = .03 ether;
    
    // free claim phase
    uint256 FREE_PER = 3000;
    uint256 FREE_SUPPLY = 3000;
    uint256 FREE_PRICE = 0 ether;   
    
    // public phase
    uint256 PUBLIC_PER = 5;
    uint256 PUBLIC_PRICE = 0.049 ether;    

    // contract metadata
    bytes prerevealUri = "ipfs://QmTkQej4rqQrKEQd7fQrHQwYH2fRDHAo8xJPinUuJv4Lx1";
    bytes contractProfileURI = "ipfs://bafybeifrzbmi4icjrwdsypqqxlxkb27oyzlqf2372eq55t3kn7nidnmagq";
    uint256 royaltyBasis = 500;
    address feeRecipient = 0xb9d8a142F6fC69dD1B38a33eD123C895870A42e8;

    mapping(address=>bool) freeClaimed;

    /**
     * Initialization
     */
        
    /// @notice contract is initialized as soul bound, no transfers or approvals allowed
    /// @dev sales can be enabled by contract owner calling enableSecondarySales()
    /// @param name string name of contract
    /// @param symbol string symbol for contract 
    constructor(string memory name, string memory symbol) Allowable(name,symbol) {
        soulBind();
        initializePhases();        
    }    

    /// @notice initialization of minting phases
    function initializePhases() internal virtual override {
        Phase[] storage phases = getPhases();

        // Phase struct
        // name, maxPerWallet (0 indicates no limit), maxMint, price
        phases.push(Phase("allowed", ALLOW_PER, ALLOW_SUPPLY, ALLOW_PRICE));
        phases.push(Phase("allowedBags", FREE_PER, ALLOW_SUPPLY, ALLOW_PRICE));
        phases.push(Phase("claim", FREE_PER, FREE_SUPPLY, FREE_PRICE));
        phases.push(Phase("public", PUBLIC_PER, MAX_SUPPLY, PUBLIC_PRICE));
        
        initialize(phases,MAX_SUPPLY);        
    }
    
    /**
     * Metadata
     */
    function contractURI() external view virtual override returns (string memory) {   
        return renderings.encodedContractURI(contractProfileURI, royaltyBasis, feeRecipient);
    }   

    /**
     * Minting & Burning
     */    

    /// @notice minting CLAIM_PHASE, requires trusted signature, staked Apien and Genesis Bag
    /// @param stakedApiens uint256[] ids of staked Apien
    /// @param genesisBags uint256[] ids of Genesis Bag
    /// @param signature bytes trusted signature 
    function freeClaimMint(uint256[] memory stakedApiens, uint256[] memory genesisBags, bytes calldata signature) 
    external requiresClaimSig(signature,msg.sender,genesisBags,stakedApiens) {    
        if (freeClaimed[msg.sender]) revert ApienAlreadyClaimed(0);
        for (uint i = 0; i < genesisBags.length; i++) {
            if (hasBeenClaimed(genesisBags[i], GENESIS_BAG)) {
                revert BagAlreadyClaimed(genesisBags[i]);
            }
            
            claim(genesisBags[i], GENESIS_BAG);
        }
        for (uint i; i < stakedApiens.length; i++) {
            if (hasBeenClaimed(stakedApiens[i], APIENS)) {
                revert ApienAlreadyClaimed(stakedApiens[i]);
            }
            
            claim(stakedApiens[i], APIENS);
        }
        phasedMint(CLAIM_PHASE, stakedApiens.length, false);        
    } 

    /// @notice minting ALLOW_PHASE, requires trusted signature and GenesisBag
    /// @param genesisBags uint256[] ids of Genesis Bags
    /// @param signature bytes trusted signature 
    function bagAllowMint(uint256[] memory genesisBags, bytes calldata signature) 
    external payable requiresBagSig(signature,msg.sender,genesisBags) { 
        for (uint i = 0; i < genesisBags.length; i++) {
            if (hasBeenClaimed(genesisBags[i], GENESIS_BAG)) {
                revert BagAlreadyClaimed(genesisBags[i]);
            }
            
            claim(genesisBags[i], GENESIS_BAG);
        }
        Phase memory phased = findPhase(ALLOW_BAG_PHASE);     
        isValidPayment(phased.cost, genesisBags.length);

        phasedMint(ALLOW_BAG_PHASE, genesisBags.length, false);        
        
        // we do not want to track bag claims as consuming an allowlist spot
        // setAux(msg.sender, getAux(msg.sender)+uint64(genesisBags.length));
    }     

    /// @notice minting ALLOW_PHASE, requires trusted signature, maximum quantity 5 per wallet
    /// @param quantity uint64 number to mint
    /// @param signature bytes trusted signature 
    function allowlistMint(uint64 quantity, bytes calldata signature) 
    external payable requiresAllowSig(signature,msg.sender) {  
        
        Phase memory phased = findPhase(ALLOW_PHASE); 

        isValidPayment(phased.cost, quantity);

        phasedMint(ALLOW_PHASE, quantity, false);       
    }

    /// @notice minting PUBLIC_PHASE, maximum quantity 5 per wallet
    /// @param quantity uint64 number to mint
    function publicMint(uint64 quantity) 
    external payable {  
        
        Phase memory phased = findPhase(PUBLIC_PHASE); 

        isValidPayment(phased.cost, quantity);

        phasedMint(PUBLIC_PHASE, quantity, false);       
    }

    /// @notice empower function
    /// @param tokenId uint256 token id to empower
    function empower(uint256 tokenId) external {
        validateApprovedOrOwner(msg.sender, tokenId);

        if (!enumerationExists(tokenId)) {
            enumerateToken(msg.sender, tokenId);
        }
    }    

    /// @notice burn function
    /// @param tokenId uint256 token id to burn
    function burn(uint256 tokenId) external {

        validateApprovedOrOwner(msg.sender, tokenId);
        
        validateLock(tokenId);   

        if (enumerationExists(tokenId)) {
            enumerateBurn(msg.sender,tokenId);
            selfDestruct(tokenId);
        }

        packedBurn(tokenId);
    }    

    /**
     * Owner Utility and Managment of TREASURY 
     */     

    /**
     * setRoyaltyBasis
     * @notice sets the royalty rate 
     * @param royalty_basis uint256 0 - 1000 (1000 = 10%)
     */
    function setRoyaltyBasis(uint256 royalty_basis) external onlyOwner {
        royaltyBasis = royalty_basis;
    }    

    /**
     * setContractRoyaltyRecipient
     * @notice sets the royalty payment recipient
     * @param recipient address to recieve royalties
     */
    function setContractRoyaltyRecipient(address recipient) external onlyOwner {
        feeRecipient = recipient;
    }   

    /**
     * setContractProfileImage
     * @notice sets the contract profile image
     * @param imageUri uri to use for profile image
     */
    function setContractProfileImage(bytes calldata imageUri) external onlyOwner {
        contractProfileURI = imageUri;
    }                

    /// @notice withdraw funds to treasury
    function withdrawFunds() external onlyOwner {
        TREASURY.transfer(address(this).balance);
    } 

    /// @notice set treasury wallet address
    function assignFundRecipient(address treasury) external onlyOwner {
        TREASURY = payable(treasury);
    }      

    /// @notice disables soul bound state allowing transfers and approvals
    function enableSecondarySales() external onlyOwner {
        releaseSoul();
    }    

    /// @notice establishes the cost of a mint for the specified phase
    /// @param phase uint256 the phase to set the mint price for
    /// @param price uint256 price of mint during phase
    function setMintPrice(uint256 phase, uint256 price) external onlyOwner {
        Phase memory existing = findPhase(phase);
        existing.cost = price;
        updatePhase(phase, existing);
    }

    /// @notice determines the price for a minting phase
    /// @param phase uint256 the phase to get the mint price for
    function getMintPrice(uint256 phase) external view returns (uint256) {
        Phase memory existing = findPhase(phase);
        return existing.cost;
    }    

    /// @notice mints quantity of tokens to TREASURY without enumeration
    /// @param quantity uint256 quantity to mint to TREASURY
    function airdropToTreasury(uint256 quantity) public onlyOwner {        
        if (minted()+quantity > getMaxSupply()) {
            revert ExceedsMaxSupply();
        }
        _mint(TREASURY, quantity, false);
    }  

    /// @notice airdrops tokenId from TREASURY to recipient
    /// @param tokenId uint256 tokenId to airdrop
    /// @param recipient address address to airdrop token to
    function airdropFromTreasury(uint256 tokenId, address recipient) public onlyOwner {        
        if (ownerOf(tokenId) != TREASURY) {
            revert NotInTreasury(tokenId);
        }
        if (!enumerationExists(tokenId)) {
            enumerateToken(TREASURY, tokenId);
        }
        transferFrom(TREASURY, recipient, tokenId);

    }        

    /**
     * @notice 
     * @param recipient address recipient of airdrop
     * @param quantity quantity to airdrop
     */
    function bulkAirdrop(address recipient, uint256 quantity) public virtual onlyOwner {        
        super.airdrop(recipient,quantity,false);
        freeClaimed[msg.sender] = true;
    }    

    /// @notice max supply of tokens allowed
    function maxSupply() external view returns (uint256) {
        return getMaxSupply();
    }       

    /// @notice validate payment for minting phase
    /// @param cost uint256 cost required by requested phase
    /// @param quantity uint256 number of tokens requested
    function isValidPayment(uint256 cost, uint256 quantity) internal view {        
        if (msg.value != (cost*quantity)) {
            revert InvalidPayment(cost*quantity, msg.value);
        }
    } 
}

/**
 * Ordo Signum Machina - 2023
 */