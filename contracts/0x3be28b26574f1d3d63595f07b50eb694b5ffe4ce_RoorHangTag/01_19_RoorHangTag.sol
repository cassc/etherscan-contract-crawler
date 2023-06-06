// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721AOperatorFilter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";



contract RoorHangTag is ERC721A, ERC2981, Ownable, ERC721AOperatorFilter, ReentrancyGuard, Pausable{
    using SignatureChecker for address;
    using Strings for uint256;

    enum HangTagTokenType {Common, SpecialEdition, Custom}
         
    address public signer;
    uint256 public tokenId;    
    uint256 public walletBFee;
    uint256 public totalAmountSentToWalletB;    
    uint256 public capWalletB;    
    address public trustedWallet_A;
    address public trustedWallet_B;   
    string  public baseURI;    
    uint256 public commonPrice;
    uint256 public supplyLeftCommon;        
    uint256 public preMintPrice;    
    uint256 public preMintPerWalletAllowed;    
    uint256 public preMintQtyRemaining;    
    bool    public preMintPaused;
    uint256 public supplyLeftSpecialEdition;    

    struct HangTagToken {
        HangTagTokenType tokenType;        
    }    

    mapping(uint256 => HangTagToken) private hangTagTokens;    
        
    modifier isNotPaused() {
        require(!paused(),"ROOR MINT: Contract is paused");
        _;
    }

    modifier preMintNotPaused() {
        require(!preMintPaused,"ROOR MINT: Contract premint is paused");
        _;
    }
    
    constructor (
        uint256 _commonPrice, 
        uint256 _preMintPrice, 
        uint256 _preMintPerWalletAllowed,  
        uint256 _preMintQtyRemaining, 
        address _trustedWallet_A, 
        address _trustedWallet_B, 
        uint256 _capWalletB, 
        uint256 _supplyCommon, 
        uint256 _supplySpecialEdition, 
        address _allowListSigner, 
        uint256 _walletBFee
    ) ERC721A("Roor Hang Tag", "ROORHANGTAG") {
        tokenId = 1;
        preMintPrice = _preMintPrice;
        commonPrice = _commonPrice;
        preMintPerWalletAllowed = _preMintPerWalletAllowed;
        preMintQtyRemaining = _preMintQtyRemaining;
        trustedWallet_A = _trustedWallet_A;
        trustedWallet_B = _trustedWallet_B;
        walletBFee = _walletBFee;
        capWalletB = _capWalletB;
        supplyLeftSpecialEdition = _supplySpecialEdition;
        supplyLeftCommon = _supplyCommon;
        preMintPaused = true;
        signer = _allowListSigner;
        _pause();
    }  

    /// @dev Set starting token id to 1
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev public mint
    function mint(uint256 _amount, address _recipient) payable external nonReentrant isNotPaused {
        require(msg.value >= commonPrice * _amount, "RT: Not sufficent balance to buy");
        require(supplyLeftCommon >= _amount, "RT: Not enough supply for Common");
        supplyLeftCommon -= _amount;
        for (uint256 i=0; i < _amount; i++) {
            hangTagTokens[tokenId].tokenType = HangTagTokenType.Common;                        
            tokenId++;            
        }        
        super._safeMint(_recipient, _amount);
        payment(_amount);        
    }

    /// @dev pre mint
    function preMint(uint256 _amount, bytes memory _signature) payable external nonReentrant preMintNotPaused {
        require(msg.value >= preMintPrice * _amount, "RT: Not sufficent balance to buy");                
        require(supplyLeftCommon >= _amount, "RT: Not enough supply for Common");
        require(preMintQtyRemaining >= _amount, "RT: Not enough supply pre mint");        
        require(isAllowListed(_signature), "RT: signature invalid");
        uint256 cumulativeMint = _numberMinted(msg.sender) + _amount;
        require(cumulativeMint <= preMintPerWalletAllowed, "RT: greater than qty allowed");

        supplyLeftCommon -= _amount;
        preMintQtyRemaining -= _amount;
        for (uint256 i=0; i < _amount; i++) {
            hangTagTokens[tokenId].tokenType = HangTagTokenType.Common;                        
            tokenId++;            
        }        
        super._safeMint(msg.sender, _amount);
        payment(_amount);        
    }

    /// @dev Returns if user is on the premint allowList
    function isAllowListed(bytes memory signature) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(msg.sender));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, signature);
    }
    
    /// @dev Private mint function for only Special Edition Tag
    function privateMintSpecialEdition(uint256 quantity, address destinationAddress) onlyOwner external {
        require(quantity > 0, "RT: quantity is 0");
        require(supplyLeftSpecialEdition >= quantity, "RT: Not enough supply for Special Edition");
        supplyLeftSpecialEdition-=quantity;
        for (uint256 i=0; i < quantity; i++) {
            hangTagTokens[tokenId].tokenType = HangTagTokenType.SpecialEdition;                        
            tokenId++;
        }
        super._safeMint(destinationAddress, quantity);
    }

    /// @dev Private mint function for only Common Tag
    function privateMintCommon(uint256 quantity, address destinationAddress) onlyOwner external {
        require(quantity > 0, "RT: quantity is 0"); 
        require(supplyLeftCommon >= quantity, "RT: Not enough supply for Common");
        supplyLeftCommon -= quantity;
        for (uint256 i=0; i < quantity; i++) {
            hangTagTokens[tokenId].tokenType = HangTagTokenType.Common;                        
            tokenId++;
        }
        super._safeMint(destinationAddress, quantity);
    }

    /// @dev Private mint function for only Custom Tag
    function privateMintCustom(uint256 quantity, address destinationAddress) onlyOwner external {
        require(quantity > 0, "RT: quantity is 0"); 
        for (uint256 i=0; i < quantity; i++) {
            hangTagTokens[tokenId].tokenType = HangTagTokenType.Custom;                        
            tokenId++;
        }
        super._safeMint(destinationAddress, quantity);
    }

    /// @dev process payment    
    function payment(uint256 _quantity) internal {
        if((totalAmountSentToWalletB < capWalletB)){
            uint256 amount = (msg.value - (walletBFee * _quantity));
            (bool success,) = trustedWallet_A.call{value: amount}("");
            require(success, "RT: Transfer A failed");            
            
            amount = msg.value - amount;
            (success, ) = trustedWallet_B.call{value: amount}("");
            require(success, "RT: Transfer B failed");            
            totalAmountSentToWalletB += amount;
        }else {
            uint256 amount = msg.value; 
            (bool success,) = trustedWallet_A.call{value: amount}("");
            require(success, "RT: Transfer A failed");
        }
    }

    /// @dev updates the commonPrice global variable. 
    function updateCurrentPrice(uint256 _commonPrice) external onlyOwner {
        commonPrice = _commonPrice;
    }

    /// @dev updates the preMintPrice global variable. 
    function updatePreMintPrice(uint256 _preMintPrice) external onlyOwner {
        preMintPrice = _preMintPrice;
    }

    /// @dev updates the preMintPerWalletAllowed global variable. 
    function updatePreMintPerWalletAllowed(uint256 _preMintPerWalletAllowed) external onlyOwner {
        preMintPerWalletAllowed = _preMintPerWalletAllowed;
    }

    /// @dev updates the preMintPerWalletAllowed global variable. 
    function updatePreMintQtyRemaining(uint256 _preMintQtyRemaining) external onlyOwner {
        preMintQtyRemaining = _preMintQtyRemaining;
    }
    
    /// @dev Updates address of 'trustedWallet_A'          
    function setTrustedWallet_A(address _trustedWallet) external onlyOwner {
        trustedWallet_A = _trustedWallet;
    }
    
    /// @dev Updates address of 'trustedWallet_B'         
    function setTrustedWallet_B(address _trustedWallet) external onlyOwner {
        trustedWallet_B = _trustedWallet;
    }

    /// @dev Updates values of 'walletBFee'          
    function setWalletBFee(uint256 _walletBFee) external onlyOwner {
        walletBFee = _walletBFee;
    }
    
    ///@dev Sets URIs for a tokenID.    
    function setBaseURI(string memory _uri) external onlyOwner {
        require(bytes(_uri).length > 0, "ROOR TAG: Empty URI value");
        baseURI = _uri;
    }

    /// @dev updates the preMintPaused status 
    function updatePreMintPaused(bool _paused) external onlyOwner {
        preMintPaused = _paused;
    }
    
    /// @dev Pause mint
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause mint
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Returns URI for the token. 
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "RT: invalid token");        
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI,_tokenId.toString()))
                : "";
    }

    /// @dev Returns token type
    function getToken(uint256 _tokenId) public view returns (HangTagToken memory _token) {
        return hangTagTokens[_tokenId];
    }

    /// @dev See {IERC165-supportsInterface}.    
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            _interfaceId == 0x7f5828d0 ||
            super.supportsInterface(_interfaceId);
    }

    /// ERC2981 functions
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function resetTokenRoyalty(uint256 _tokenId) external onlyOwner {
        _resetTokenRoyalty(_tokenId);
    }

    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _quantity
    )
        internal
        virtual
        override(ERC721A, ERC721AOperatorFilter)
    {
        super._beforeTokenTransfers(_from, _to, _tokenId, _quantity);
    }
}