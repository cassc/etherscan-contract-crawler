// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBabyBirdez.sol";
import "./interfaces/IGenesisBirdez.sol";

contract BirdezKingdom is ERC721Enumerable, Ownable {
    using Strings for uint256;
     

    IGenesisBirdez public immutable genesis;
    IBabyBirdez public immutable baby;

    mapping(address => uint256) private maxMintsPerAddress; 
    mapping(uint256 => uint256) public maxFreeMintsPerToken;
 
    uint256 public constant MAX_RESERVED_MINT = 3;
    uint256 public constant MAX_PUBLIC_MINT = 5;
 
    
    uint256 public constant PHASE1_MAX_SUPPLY = 2500;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant FREE_GENESIS_SUPPLY = 1333;
 
    uint256 public constant MINT_PRICE = 0.088 ether;

    address[] public teamPayments = [
        0x14FA48721559bb00Cc4C90D3C5f9dC7bB16e34a5, // Founder
        0x52E9c9d83E954B034ff6EA10ea96A8f1de6A514E, // Advisor1
        0x5865D2fe60E242Ce16b9E31A3575cEA4d68F7002, // Advisor2
        0x9aB0f8ED479df9a7E06FCDBd349FBcE71868fa60, // Dev1
        0x39c0797E5f8c5cBfd23404a7EC48Af9a49998b2c, // Artist1
        0x2aEe6953177cB5B4Dba1B350ecaCC378b8ed0BB5, // Artist2
        0x9444E845311c0d247eaE0FE0122E53Ffec357848  // Dev2,
    ];

    uint256[] public teamPaymentShares = [ 
        755,    // Founder: 75.5%
        100,    // Advisor1: 10%
         70,    // Advisor2: 7%
         35,    // Dev1: 3.5%
         20,    // Artist1: 2%
         10,    // Artist2: 1%
         10     // Dev2: 1% 
    ]; 

    uint256 public constant PHASE1_START = 1650970800;
    uint256 public constant PHASE2_START = 1650981600;
    uint256 public constant PHASE3_START = 1651003200; 

    bool public startSale;
    bool public whitelistSale;
    bool public publicSale;
    bool public genesisSale;
    bool public isBaseURILocked;

    string private baseURI; 
 
    bytes32 public whitelistMerkleRoot;

    constructor(
        string memory _name, 
        string memory _symbol,
        IGenesisBirdez _genesis,
        IBabyBirdez _baby
     ) ERC721(_name, _symbol) {
        require(address(_genesis) != address(0), "invalid-genesis");
        require(address(_baby) != address(0), "invalid-baby");
        genesis = _genesis;
        baby = _baby;

        startSale = false;
        whitelistSale = false;
        publicSale = false;
        genesisSale = false;
        isBaseURILocked = false; 
     }

    function updateWhitelistMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner{
        whitelistMerkleRoot = _newMerkleRoot;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        require(!isBaseURILocked, "locked-base-uri");       
        baseURI = _uri;
    } 

    function lockBaseURI() external onlyOwner {
        isBaseURILocked = true; 
    } 
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "non-existent-token");
        string memory _base = _baseURI();
        return string(abi.encodePacked(_base, tokenId.toString()));
    }

    // Phase 1
    function isPhase1()  public view returns (bool ){
        return block.timestamp >= PHASE1_START || startSale;
    }
    function flipPrivateSaleState() public onlyOwner {
        startSale = !startSale;
    } 


    // Phase 2
    function flipWhitelistState() public onlyOwner {
        whitelistSale = !whitelistSale;
    } 
    function isPhase2() public view returns (bool ){
        return block.timestamp >= PHASE2_START || whitelistSale;
    }


    // Phase 3
    function flipSaleState() public onlyOwner {
        publicSale = !publicSale;
    }
    function isPhase3() public view returns (bool ){
        return block.timestamp >= PHASE3_START || publicSale;
    }
 
    // Phase 4
    function flipGenesisState() public onlyOwner {
        genesisSale = !genesisSale;
    }  
    function isPhase4() public view returns (bool ){
        return genesisSale;
    }

    function getGenesisCount(address _owner) public view returns (uint256){
        return genesis.balanceOf(_owner);
    }

    function getGenesisByAddressAndIndex(address _owner, uint256 _tokenId) internal view returns (uint256){
        return genesis.tokenOfOwnerByIndex(_owner, _tokenId);
    }

    function getBabyCount(address _owner) public view returns (uint256){
        return baby.balanceOf(_owner);
    } 
      

    // PHASE 1
    function genesisPaidMint(uint256 _numberOfTokens) external payable{
        address _user = msg.sender;   
        require(isPhase1() || startSale, "sale-not-opened");
        require(msg.value >= _numberOfTokens * MINT_PRICE);
        require(getGenesisCount(_user) +  getBabyCount(_user) > 0, "no-birdez-in-wallet"); 
        require(totalSupply() + _numberOfTokens <= PHASE1_MAX_SUPPLY, "max-supply-reached");
        require(maxMintsPerAddress[_user] + _numberOfTokens <= MAX_RESERVED_MINT, "max-mint-limit" ); 
        for (uint i = 0; i < _numberOfTokens; i++) {  
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_user, totalSupply());
                maxMintsPerAddress[_user]++; 
            } else {
                payable(_user).transfer( (_numberOfTokens - i) * MINT_PRICE  );
                break;
            }
        } 
    }

    // PHASE 2
    function whitelistMint(uint256 _numberOfTokens,  bytes32[] calldata merkleProof) external payable{
        address _user = msg.sender; 
        require(isPhase2(), "whitelist-sale-not-opened"); 
        require(msg.value >= _numberOfTokens * MINT_PRICE);
        bool isWhitelisted = MerkleProof.verify( merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(_user)) );
        require(isWhitelisted, "invalid-proof"); 
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "max-supply-reached");
        require(maxMintsPerAddress[_user] + _numberOfTokens <= MAX_RESERVED_MINT, "max-mint-limit" ); 
        for (uint i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_user, totalSupply());
                maxMintsPerAddress[_user]++;
            } else { 
                payable(_user).transfer( (_numberOfTokens - i) * MINT_PRICE  );
                break;
            }
        } 
    } 

    // PHASE 3
    function publicMint(uint256 _numberOfTokens) external payable{
        address _user = msg.sender; 
        require(isPhase3(), "public-sale-not-opened"); 
        require(msg.value >= _numberOfTokens * MINT_PRICE);
        require(totalSupply() + _numberOfTokens <= MAX_SUPPLY, "max-supply-reached");
        require(maxMintsPerAddress[_user] + _numberOfTokens <= MAX_PUBLIC_MINT, "max-mint-limit" ); 
        for (uint i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_user, totalSupply());
                maxMintsPerAddress[_user]++;
            } else {
                payable(_user).transfer( (_numberOfTokens - i) * MINT_PRICE  );
                break;
            }
        } 
    }

    // PHASE 4
    function genesisFreeMint() external payable{
        address _user = msg.sender; 
        require(genesisSale, "sale-not-open"); 
        require(getGenesisCount(_user) > 0, "no-birdez-in-wallet"); 
        uint256 _numberOfTokens = getGenesisCount(_user);
        require(totalSupply() + _numberOfTokens <= FREE_GENESIS_SUPPLY + MAX_SUPPLY, "max-supply-reached");
 
        for (uint i = 0; i < _numberOfTokens; i++) {
            uint256 tid = getGenesisByAddressAndIndex(_user, i);
            if(maxFreeMintsPerToken[tid] > 0) continue;
            if (totalSupply() < FREE_GENESIS_SUPPLY) {
                _safeMint(_user, totalSupply()); 
                maxFreeMintsPerToken[tid]++;
            } else {
                break;
            }
        } 
    }
 
 
    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        for (uint i = 0; i < teamPayments.length; i++) {
            uint256 _shares = (_balance / 1000) * teamPaymentShares[i];
            uint256 _currentBalance = address(this).balance;
            _shares = (_shares < _currentBalance) ? _shares : _currentBalance;
            payable(teamPayments[i]).transfer(_shares);
        }
    }
     
}