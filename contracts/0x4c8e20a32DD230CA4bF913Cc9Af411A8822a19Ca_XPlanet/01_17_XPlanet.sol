//SPDX-License-Identifier: MIT
//solhint-disable no-empty-blocks

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";  

contract XPlanet is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeERC20 for IERC20;
 

    IERC20 usdc;

    mapping(address => uint256) private maxMintsPerAddress;

    mapping(address => mapping(uint256 => uint256)) private holdingStart; 

    address[] public teamPayments = [
        0x509F082695496a07e577965D0F5C48A8bD288d4f, // Founder 
        0x9444E845311c0d247eaE0FE0122E53Ffec357848  // Dev2,
    ]; 
    uint256[] public teamPaymentShares = [ 
        980,    // Founder: 98% 
         20     // Dev: 2% 
    ];  

    uint256 public MINT_PRICE = 1000;

    uint256 public constant MAX_SUPPLY = 888;
    
    uint256 public constant MAX_WHITELIST_MINT = 3;
    
    uint256 public MAX_PUBLIC_MINT = 3; 
    
    uint256 public MAX_MINT_PHASE = 444;

    bool public whitelistSale = false;
     
    bool public publicSale = false; 

    bool public phase2Active = false;

    bool public isBaseURILocked = false; 
    
    string private baseURI; 
    
    bytes32 public whitelistMerkleRoot;
    
    bytes32 public whitelist2MerkleRoot;

    bytes32 public reservedlistMerkleRoot;

    constructor(address _usdc, string memory _name, string memory _symbol) ERC721( _name, _symbol) {
        usdc = IERC20(_usdc);
    }

    function setPrice(uint256  _price ) external onlyOwner{
        MINT_PRICE = _price;
    }

    function setMaxMintPhase(uint256  _qty ) external onlyOwner{
        MAX_MINT_PHASE = _qty;
    }

    function updateWhitelistMerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyOwner{
        whitelistMerkleRoot = _newMerkleRoot;
    }

    function updateWhitelist2MerkleRoot(bytes32 _newMerkleRoot)
        external
        onlyOwner{
        whitelist2MerkleRoot = _newMerkleRoot;
    }

    function updateReservedlistMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner{
        reservedlistMerkleRoot = _newMerkleRoot;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        require(!isBaseURILocked, "locked-base-uri");
        baseURI = newURI;
    } 

    function flipSaleState() external onlyOwner {
        publicSale = !publicSale;
    }

    function flipWhitelistState() external onlyOwner {
        whitelistSale = !whitelistSale;
    }  
 
    function flipPhase2State() external onlyOwner {
        phase2Active = !phase2Active;
    }  
 
    function balanceOfUsdc(address  _address) public view returns (uint256){
        return usdc.balanceOf(_address);
    }

    function allowed() external view returns (uint256){
        return usdc.allowance(address(this), msg.sender);
    }

    function allow(uint256  _price ) external returns (address){
        usdc.approve(address(this),  _price );
        return msg.sender;
    }


    function withdraw() external onlyOwner{
        uint _balance = usdc.balanceOf(address(this)); 
        for (uint256 i = 0; i < teamPayments.length; i++) {
            uint256 _shares = (_balance / 1000) * teamPaymentShares[i];
            uint256 _currentBalance = usdc.balanceOf(address(this));
            _shares = (_shares < _currentBalance) ? _shares : _currentBalance; 
            usdc.transfer( teamPayments[i], _shares); 
        } 
    }

    function getSmartContractBalance() external view returns(uint) {
        return usdc.balanceOf(address(this));
    }

    function isContract(address  account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256  tokenId)
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
 
    // Allow minting to everyone. Phase 1. Max 444

    function publicMint(uint256  _numberOfTokens) external {
        address _user = _msgSender();
        uint256 _amount = MINT_PRICE * _numberOfTokens  * 1000000;
        require(publicSale, "sale-not-active");
        require( totalSupply() + _numberOfTokens <= MAX_SUPPLY, "max-supply-reached" );
        require( totalSupply() + _numberOfTokens <= MAX_MINT_PHASE, "max-supply-reached" );

        require( balanceOfUsdc(_user) >= _amount, "not-enough-usdc" );
        require( !isContract(_user), "mint-via-contract");
        require( _numberOfTokens > 0 && _numberOfTokens <= MAX_PUBLIC_MINT, "mint-number-out-of-range" );
        require( maxMintsPerAddress[_user] + _numberOfTokens <= MAX_PUBLIC_MINT, "max-mint-limit" ); 
         
        usdc.transferFrom(_user, address(this), _amount );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_MINT_PHASE) {
                _safeMint(_user, totalSupply());
                maxMintsPerAddress[_user]++;
            } else {
                usdc.transfer( _user,  (_numberOfTokens - i) * MINT_PRICE  * 1000000 ); 
                break;
            }
        }
    }
    
    // Allow minting to whitelisted addresses only. Phase 1. Max 444

    function whitelistMint(uint256 _numberOfTokens, bytes32[] calldata merkleProof ) external  {
        address _user = _msgSender(); 
        uint256 _amount = MINT_PRICE * _numberOfTokens * 1000000;

        require(whitelistSale, "sale-not-active");
        require( totalSupply() + _numberOfTokens <= MAX_SUPPLY, "max-supply-reached" );
        require( balanceOfUsdc(_user) >= _amount, "not-enough-usdc" );
        require( !isContract(_user), "mint-via-contract" );
        require( totalSupply() + _numberOfTokens <= MAX_MINT_PHASE, "max-supply-reached" );
        require( maxMintsPerAddress[_user] + _numberOfTokens <= MAX_WHITELIST_MINT, "max-mint-limit" ); 

        bool isWhitelisted = MerkleProof.verify(
            merkleProof,
            whitelistMerkleRoot,
            keccak256(abi.encodePacked(_user))
        );

        require( isWhitelisted, "invalid-proof");
        
        usdc.transferFrom(_user, address(this), _amount );

        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_MINT_PHASE) {
                _safeMint(_user, totalSupply());
                maxMintsPerAddress[_user]++;
            } else {
                usdc.transfer( _user,  (_numberOfTokens - i) * MINT_PRICE * 1000000 ); 
                break;
            }
        }
    }
    
    // Allow minting to reserved people only (crew)

    function reservedMint(uint256 _numberOfTokens, bytes32[] calldata merkleProof ) external  {
        address _user = _msgSender(); 
 
        require( !isContract(_user), "mint-via-contract" );
        require( totalSupply() + _numberOfTokens <= MAX_SUPPLY, "max-supply-reached" );
 
        bool isWhitelisted = MerkleProof.verify( merkleProof, reservedlistMerkleRoot, keccak256(abi.encodePacked(_user)) );

        require( isWhitelisted, "invalid-proof" );
        
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_user, totalSupply());
                maxMintsPerAddress[_user]++;
            } else { 
                break;
            }
        }
    }
    
    // Allow minting to whitelisted only. Phase 2

    function mint( bytes32[] calldata merkleProof ) external  {
        address _user = _msgSender();  
        uint256 _amount = MINT_PRICE * 1000000;

        require( phase2Active, "sale-not-active");
        require( balanceOfUsdc(_user) >= _amount, "not-enough-usdc" );
        require( !isContract(_user), "mint-via-contract" );
        require( totalSupply() + 1 <= MAX_SUPPLY, "max-supply-reached" );
        require( maxMintsPerAddress[_user] == 0, "max-mint-limit" ); 

        bool isWhitelisted = MerkleProof.verify( merkleProof, whitelist2MerkleRoot, keccak256(abi.encodePacked(_user)) );
        require( isWhitelisted, "invalid-proof");
        
        usdc.transferFrom(_user, address(this), _amount);
        _safeMint(_user, totalSupply());
        maxMintsPerAddress[_user]++;
    }

    function airDrop( uint256 _numberOfTokens, address _user ) public onlyOwner{ 
        require( totalSupply() + _numberOfTokens <= MAX_SUPPLY, "max-supply-reached" );
        require( !isContract(_user), "mint-via-contract" );
        for (uint256 i = 0; i < _numberOfTokens; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_user, totalSupply()); 
            } else {
                break;
            }
        }
    }

    // STACKING

    function _beforeTokenTransfer( address from, address to, uint256 tokenId ) internal virtual override {
        holdingStart[from][tokenId] = 0;
        holdingStart[to][tokenId] = block.timestamp;
        super._beforeTokenTransfer(from, to, tokenId);
    }
       
    function holdingTime(address _owner, uint256 _tokenId) external  view returns (uint256 _time) {
        if (holdingStart[_owner][_tokenId] == 0) return 0;
        _time = block.timestamp - holdingStart[_owner][_tokenId];
    }
}