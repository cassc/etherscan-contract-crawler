// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title StudioUno smart-contract
contract StudioUno is ERC721, Pausable, Ownable, ReentrancyGuard {
    using SignatureChecker for address;
    using Strings for uint256;

    bool public isArtScriptLocked;
    bool public publicMintingPaused;         
    string public baseURI;
                         
    // Current token prices per tier
    uint256 public publicPrice;
    uint256 public earlyCollectorPrice;
    uint256 public holderPrice;
    uint256 public primeHolderPrice;
    uint256 public updateMintPrice;

    uint256 public tokenId; // Last token ID minted
    uint256 public supplyLeft; // Supply amount available for public token minting
        
    address public trustedWallet_A;
    address public trustedWallet_B;
    address public signerCryptoarteEarlyCollector;
    address public signerCryptoarteHolder;
    address public signerCryptoartePrimeHolder;
        
    struct Token {
        address creatorAddress;
        string mode;
        string style;
        uint8 var1;
        uint8 var2;
        bool blackBackground;
        bool displayAddress; 
        uint256 iteration;       
    }

    struct ArtScript {
        string jsonProperties;
        string script1;
        string script2;
        string script3;
        string script4;
        string script5;
    }

    ArtScript public script;

    mapping(address => mapping( string => bool )) private mintedCombinations;
    mapping(address => bool) private hasMinted;
    mapping(address => bool) private blacklisted;
    mapping(uint256 => Token) private tokens; // @dev tokenId -> Token
           
    event Minted(address _buyer, uint256 _tokenId, uint256 _paid);            
    event Transfered(address _wallet, uint256 _amount);
    event Updated(address _owner, uint256 _tokenId, uint256 _paid);

    constructor(         
        address _trustedWallet_A,
        address _trustedWallet_B,        
        address _signerCryptoarteEarlyCollector,
        address _signerCryptoarteHolder,
        address _signerCryptoartePrimeHolder,        
        uint256 _totalSupply,         
                
        uint256 _publicPrice,
        uint256 _earlyCollectorPrice,
        uint256 _holderPrice,
        uint256 _primeHolderPrice,
        uint256 _updateMintPrice       

        ) ERC721("StudioUno Norte", "S1NORTE") {
                               
        supplyLeft = _totalSupply;
        publicMintingPaused = true;
        trustedWallet_A = _trustedWallet_A;
        trustedWallet_B = _trustedWallet_B;        
        publicPrice = _publicPrice;
        earlyCollectorPrice = _earlyCollectorPrice;
        holderPrice = _holderPrice;
        primeHolderPrice = _primeHolderPrice;
        updateMintPrice = _updateMintPrice;        
        signerCryptoarteEarlyCollector = _signerCryptoarteEarlyCollector;
        signerCryptoarteHolder = _signerCryptoarteHolder;
        signerCryptoartePrimeHolder = _signerCryptoartePrimeHolder;
        
        _pause();
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    modifier whenPublicMintingNotPaused {
        require(publicMintingPaused == false, "S1: publicMint paused");
        _;
    }

    modifier whenArtScriptNotLocked {
        require( !isArtScriptLocked, "S1: ArtScript locked");
        _;
    }

    // Getters of mappings
    function getIsMintedCombination(address _walletAddress, string memory combination) public view returns(bool value) {
        return mintedCombinations[_walletAddress][combination];
    }

    function getHasMinted(address _walletAddress) public view returns(bool value) {
        return hasMinted[_walletAddress];
    }

    function isBlacklisted(address _walletAddress) public view returns(bool value) {
        return blacklisted[_walletAddress];
    }

    // Start: Minting operations

    /// @dev Mint token
    function publicMint(string memory mode, string memory style, uint8 var1, uint8 var2, bool blackBackground, bool displayAddress) external payable nonReentrant() whenNotPaused whenPublicMintingNotPaused {
        require(msg.value >= publicPrice, "S1: wrong price");
        require(supplyLeft > 0, "S1: sold out");
        require(( keccak256(abi.encode(mode)) == keccak256(abi.encode("1")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("2")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("3")) ) , "S1: wrong mode");
        require(( keccak256(abi.encode(style)) == keccak256(abi.encode("1")) || keccak256(abi.encode(style)) == keccak256(abi.encode("2")) || keccak256(abi.encode(style)) == keccak256(abi.encode("3")) ) , "S1: wrong style");
        
        supplyLeft--;
        _mintTo(msg.sender, msg.sender, mode, style, var1, var2, blackBackground, displayAddress);                        
    }

    /// @dev Mint token CryptoArte early collectors
    function cryptoArteEarlyCollectorMint(bytes memory signature, string memory mode, string memory style, uint8 var1, uint8 var2, bool blackBackground, bool displayAddress) external payable nonReentrant() whenNotPaused {
        require(isWhitelistedAsCryptoArteEarlyCollector(signature), "S1: not whitelisted");
               
        if (hasMinted[msg.sender] == false) {
            require(msg.value >= 0, "S1: not free");
        }
        else {
            require(msg.value >= earlyCollectorPrice, "S1: wrong price");
        }
                        
        require(( keccak256(abi.encode(mode)) == keccak256(abi.encode("1")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("2")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("3")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("4")) ) , "S1: wrong mode");
        require(( keccak256(abi.encode(style)) == keccak256(abi.encode("1")) || keccak256(abi.encode(style)) == keccak256(abi.encode("2")) || keccak256(abi.encode(style)) == keccak256(abi.encode("3")) || keccak256(abi.encode(style)) == keccak256(abi.encode("4")) || keccak256(abi.encode(style)) == keccak256(abi.encode("5")) ) , "S1: wrong style");
        _mintTo(msg.sender, msg.sender, mode, style, var1, var2, blackBackground, displayAddress);                                    
    }
  
    /// @dev Mint token CryptoArte holders
    function cryptoArteHolderMint(bytes memory signature, string memory mode, string memory style, uint8 var1, uint8 var2, bool blackBackground, bool displayAddress) external payable nonReentrant() whenNotPaused {
        require(isWhitelistedAsCryptoArteHolder(signature), "S1: not whitelisted");
        require(msg.value >= holderPrice, "S1: wrong price");

        require(( keccak256(abi.encode(mode)) == keccak256(abi.encode("1")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("2")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("3")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("4")) ) , "S1: wrong mode");
        require(( keccak256(abi.encode(style)) == keccak256(abi.encode("1")) || keccak256(abi.encode(style)) == keccak256(abi.encode("2")) || keccak256(abi.encode(style)) == keccak256(abi.encode("3")) || keccak256(abi.encode(style)) == keccak256(abi.encode("4")) ) , "S1: wrong style");
        _mintTo(msg.sender, msg.sender, mode, style, var1, var2, blackBackground, displayAddress);                                         
    }

    /// @dev Mint token CryptoArte prime holders
    function cryptoArtePrimeHolderMint(bytes memory signature, string memory mode, string memory style, uint8 var1, uint8 var2, bool blackBackground, bool displayAddress) external payable nonReentrant() whenNotPaused {
        require(isWhitelistedAsCryptoArtePrimeHolder(signature), "S1: not whitelisted");
        
        if (hasMinted[msg.sender] == false) {
            require(msg.value >= 0, "S1: not free");
        }
        else {
            require(msg.value >= primeHolderPrice, "S1: wrong price");
        }
        
        require(( keccak256(abi.encode(mode)) == keccak256(abi.encode("1")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("2")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("3")) || keccak256(abi.encode(mode)) == keccak256(abi.encode("4")) ) , "S1: wrong mode");
        require(( keccak256(abi.encode(style)) == keccak256(abi.encode("1")) || keccak256(abi.encode(style)) == keccak256(abi.encode("2")) || keccak256(abi.encode(style)) == keccak256(abi.encode("3")) || keccak256(abi.encode(style)) == keccak256(abi.encode("4")) || keccak256(abi.encode(style)) == keccak256(abi.encode("6")) ) , "S1: wrong style");
        _mintTo(msg.sender, msg.sender, mode, style, var1, var2, blackBackground, displayAddress);        
    }
    
    /// @dev Mint token internal
    function freeMintTo(address _receiver, address creatorAddress, string memory mode, string memory style, uint8 var1, uint8 var2, bool blackBackground, bool displayAddress) external nonReentrant() onlyOwner {
        _mintTo(_receiver, creatorAddress, mode, style, var1, var2, blackBackground, displayAddress);
    }

    /// @dev Increment tokenId, mint token, emit event
    function _mintTo(address _receiver, address creatorAddress, string memory mode, string memory style, uint8 var1, uint8 var2, bool blackBackground, bool displayAddress) internal {
        require(!blacklisted[msg.sender], "S1: blacklisted");
        string memory combination = string(abi.encodePacked(mode, style));        
        require(mintedCombinations[creatorAddress][combination] == false, "S1: combination already minted");

        mintedCombinations[creatorAddress][combination] = true;        
        hasMinted[creatorAddress] = true;
        tokenId++;
        setTokenTraits(tokenId, creatorAddress, mode, style, var1, var2, blackBackground, displayAddress);        
                        
        if (msg.value > 0) {
            payment();
        }        

        super._safeMint(_receiver, tokenId);                
        emit Minted(_receiver, tokenId, msg.value);        
    }

    /// @dev Update token
    function updateMint(uint256 _tokenId, uint8 var1, uint8 var2, bool blackBackground, bool displayAddress) external payable nonReentrant() whenNotPaused {
        require(!blacklisted[msg.sender], "S1: blacklisted");           
        require(msg.sender == ownerOf(_tokenId), "S1: not owner");
        require(msg.value >= updateMintPrice, "S1: wrong price");

        Token storage token = tokens[_tokenId];                
        token.var1 = var1;
        token.var2 = var2;
        token.blackBackground = blackBackground;
        token.displayAddress = displayAddress;        
        token.iteration = token.iteration + 1;
                        
        if (msg.value > 0) {
            payment();
        }

        emit Updated(msg.sender, _tokenId, msg.value);
    }

    // End: Minting operations
    
    
    // Start: Whitelisting operations

    function isWhitelistedAsCryptoArteEarlyCollector(bytes memory signature) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(msg.sender));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signerCryptoarteEarlyCollector.isValidSignatureNow(hash, signature);
    }

    function isWhitelistedAsCryptoArteHolder(bytes memory signature) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(msg.sender));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signerCryptoarteHolder.isValidSignatureNow(hash, signature);
    }

    function isWhitelistedAsCryptoArtePrimeHolder(bytes memory signature) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(msg.sender));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signerCryptoartePrimeHolder.isValidSignatureNow(hash, signature);
    }
    
    function setSignerCryptoarteEarlyCollector(address _signer) external onlyOwner {
        signerCryptoarteEarlyCollector = _signer;
    }

    function setSignerCryptoarteHolder(address _signer) external onlyOwner {
        signerCryptoarteHolder = _signer;
    }

    function setSignerCryptoartePrimeHolder(address _signer) external onlyOwner {
        signerCryptoartePrimeHolder = _signer;
    }

    // End: Whitelisting operations


    // Start: Blacklisting operations

    function setBlacklisted(address _addr, bool _value) external onlyOwner {
        blacklisted[_addr] = _value;
    }

    // End: Blacklisting operations


    // Start: Price operations
    
    /// @param _price New price
    function setPublicPrice(uint256 _price) external onlyOwner {        
        publicPrice = _price;        
    }

    /// @param _price New price
    function setEarlyCollectorPrice(uint256 _price) external onlyOwner {        
        earlyCollectorPrice = _price;        
    }

    /// @param _price New price
    function setHolderPrice(uint256 _price) external onlyOwner {        
        holderPrice = _price;    
    }

    /// @param _price New price
    function setPrimeHolderPrice(uint256 _price) external onlyOwner {        
        primeHolderPrice = _price;        
    }

    /// @param _price New price
    function setUpdateMintPrice(uint256 _price) external onlyOwner {        
        updateMintPrice = _price;        
    }

    // End: Price operations


    // Start: Token operations

    function getToken(uint256 _tokenId) external view returns (Token memory _token) {
        return tokens[_tokenId];
    }
    
    function setTokenTraits(uint256 _tokenId, address creatorAddress, string memory mode, string memory style, uint8 var1, uint8 var2, bool blackBackground, bool displayAddress) internal {
        Token storage token = tokens[_tokenId];
        token.creatorAddress = creatorAddress;
        token.mode = mode;
        token.style = style;
        token.var1 = var1;
        token.var2 = var2;
        token.blackBackground = blackBackground;
        token.displayAddress = displayAddress;
        token.iteration = 1;
    }    
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "S1: invalid token");       
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tokenId.toString()))
                : "";
    }
    
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    // End: Token operations


    //Start:  Script operations

    function setArtScriptJSONProperties(string memory _jsonProperties) external onlyOwner whenArtScriptNotLocked {
        script.jsonProperties = _jsonProperties;        
    }

    function setArtScript1(string memory _script1) external onlyOwner whenArtScriptNotLocked {            
        script.script1 = _script1;
    }
    
    function setArtScript2(string memory _script2) external onlyOwner whenArtScriptNotLocked {              
        script.script2 = _script2;
    }

    function setArtScript3(string memory _script3) external onlyOwner whenArtScriptNotLocked {        
        script.script3 = _script3;
    }

    function setArtScript4(string memory _script4) external onlyOwner whenArtScriptNotLocked {        
        script.script4 = _script4;
    }

    function setArtScript5(string memory _script5) external onlyOwner whenArtScriptNotLocked {        
        script.script5 = _script5;
    }
    
    function setArtScriptLock() external onlyOwner whenArtScriptNotLocked {        
        isArtScriptLocked = true;
    }

    //End:  Script operations


    // Start: Trusted wallets operations

    function payment() internal {
        require(msg.value > 0, "S1: invalid value");        
        uint256 amount = (msg.value * 95) / 100;
        (bool success, ) = trustedWallet_A.call{value: amount}("");
        require(success, "S1: Transfer A failed");
        emit Transfered(trustedWallet_A, amount);

        amount = msg.value - amount;
        (success, ) = trustedWallet_B.call{value: amount}("");
        require(success, "S1: Transfer B failed");
        emit Transfered(trustedWallet_B, amount);
    }

    function setTrustedWallet_A(address _trustedWallet) external onlyOwner {
        trustedWallet_A = _trustedWallet;
    }

    function setTrustedWallet_B(address _trustedWallet) external onlyOwner {
        trustedWallet_B = _trustedWallet;
    }

    // End: Trusted wallets operations


    // Start Pauseable requirement
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _tokenId);

        require(!paused(), "S1: paused");
    }

    /// @dev Pause contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Pause publicMint()
    function pausePublicMinting() external onlyOwner {
     publicMintingPaused = true;
    }

    /// @dev Unpause publicMint()
    function unpausePublicMinting() external onlyOwner {
     publicMintingPaused = false;
    }

    // End Pausable requirement

}