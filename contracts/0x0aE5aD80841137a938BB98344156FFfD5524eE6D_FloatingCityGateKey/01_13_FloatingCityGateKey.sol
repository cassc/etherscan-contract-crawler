// SPDX-License-Identifier: MIT
// base64.tech
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Errors.sol";

/*

   ▄████████  ▄█        ▄██████▄     ▄████████     ███      ▄█  ███▄▄▄▄      ▄██████▄        ▄████████  ▄█      ███     ▄██   ▄   
  ███    ███ ███       ███    ███   ███    ███ ▀█████████▄ ███  ███▀▀▀██▄   ███    ███      ███    ███ ███  ▀█████████▄ ███   ██▄ 
  ███    █▀  ███       ███    ███   ███    ███    ▀███▀▀██ ███▌ ███   ███   ███    █▀       ███    █▀  ███▌    ▀███▀▀██ ███▄▄▄███ 
 ▄███▄▄▄     ███       ███    ███   ███    ███     ███   ▀ ███▌ ███   ███  ▄███             ███        ███▌     ███   ▀ ▀▀▀▀▀▀███ 
▀▀███▀▀▀     ███       ███    ███ ▀███████████     ███     ███▌ ███   ███ ▀▀███ ████▄       ███        ███▌     ███     ▄██   ███ 
  ███        ███       ███    ███   ███    ███     ███     ███  ███   ███   ███    ███      ███    █▄  ███      ███     ███   ███ 
  ███        ███▌    ▄ ███    ███   ███    ███     ███     ███  ███   ███   ███    ███      ███    ███ ███      ███     ███   ███ 
  ███        █████▄▄██  ▀██████▀    ███    █▀     ▄████▀   █▀    ▀█   █▀    ████████▀       ████████▀  █▀      ▄████▀    ▀█████▀  
             ▀                                                                                                                    
                                                                                                                                  
   ▄██████▄     ▄████████     ███        ▄████████         ▄█   ▄█▄    ▄████████ ▄██   ▄                                          
  ███    ███   ███    ███ ▀█████████▄   ███    ███        ███ ▄███▀   ███    ███ ███   ██▄                                        
  ███    █▀    ███    ███    ▀███▀▀██   ███    █▀         ███▐██▀     ███    █▀  ███▄▄▄███                                        
 ▄███          ███    ███     ███   ▀  ▄███▄▄▄           ▄█████▀     ▄███▄▄▄     ▀▀▀▀▀▀███                                        
▀▀███ ████▄  ▀███████████     ███     ▀▀███▀▀▀          ▀▀█████▄    ▀▀███▀▀▀     ▄██   ███                                        
  ███    ███   ███    ███     ███       ███    █▄         ███▐██▄     ███    █▄  ███   ███                                        
  ███    ███   ███    ███     ███       ███    ███        ███ ▀███▄   ███    ███ ███   ███                                        
  ████████▀    ███    █▀     ▄████▀     ██████████        ███   ▀█▀   ██████████  ▀█████▀                                         
                                                          ▀                                                                       

*/
contract FloatingCityGateKey is ERC721, Ownable
{
    using ECDSA for bytes32;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant TOKEN_PRICE = .3 ether;
    
    address public signatureVerifier;
    address public fcTokenContract;
    string public _tokenBaseURI;
    uint256 public totalSupply;
    
    mapping (address => bool) public publicAddressesMinted;
    mapping (address => bool) public allowListAddressesMinted;

    enum MintState{ PAUSED, ALLOWLIST, PUBLIC }
    MintState public mintState;

    string private _baseTokenURI;

    constructor() ERC721("FloatingCityGateKey", "FCGATEKEY") 
    {}

    modifier underMaxSupply(uint256 _quantity) {
        if(totalSupply + _quantity > MAX_SUPPLY) revert ExceedsMaxSupply();
        _;
    }

    modifier hasValidSignature(bytes memory _signature, bytes memory message) {
        bytes32 messageHash = ECDSA.toEthSignedMessageHash(keccak256(message));
        if(messageHash.recover(_signature) != signatureVerifier) revert UnrecognizableHash();

        _;
    }

    modifier validateClaimPeriodActive(MintState _mintState) {
        if(mintState != _mintState) revert IncorrectMintState();
        _;
    }

    function mint() 
        internal 
        underMaxSupply(1)
    {
        if (tx.origin != msg.sender) revert CallerIsAnotherContract();
        if(msg.value < TOKEN_PRICE) revert NotEnoughEthSent(); 

        _mint(msg.sender, totalSupply);
        totalSupply++;
    }

    function allowListMint(bytes memory _signature)
        external
        payable
        validateClaimPeriodActive(MintState.ALLOWLIST)
        hasValidSignature(_signature, abi.encodePacked(msg.sender))
    {
        if(allowListAddressesMinted[msg.sender] == true) revert WalletHasAlreadyAllowListMinted();
       
        allowListAddressesMinted[msg.sender] = true;
        mint();
    }

    function publicMint(bytes memory _signature)
        external
        payable
        validateClaimPeriodActive(MintState.PUBLIC)
        hasValidSignature(_signature, abi.encodePacked(msg.sender))
    {
        if(publicAddressesMinted[msg.sender] == true) revert WalletHasAlreadyPublicMinted();
       
        publicAddressesMinted[msg.sender] = true;
        totalSupply++;
        mint();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert ("URIQueryForNonexistentToken");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function burn(uint256 _tokenId) external {
       if(msg.sender != fcTokenContract) revert IsNotCalledFromFCTokenContract();
       _burn(_tokenId);
    }

    function getTokenOwners() external view returns (address[MAX_SUPPLY] memory) {
        address[MAX_SUPPLY] memory tokenOwners;

        for(uint256 i = 0; i < totalSupply; i++) {
            tokenOwners[i] = ownerOf(i);
        }

        return tokenOwners;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }


    /* Owner Functions */
    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        signatureVerifier = _signatureVerifier;
    }

    function ownerMintToAddress(address _recipient, uint256 _numberToMint) 
        external 
        onlyOwner 
        underMaxSupply(_numberToMint)
    {
        for(uint256 i = 0; i < _numberToMint; i++) {
            _mint(_recipient, totalSupply);
            totalSupply++;
        }
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        _baseTokenURI = _URI;
    }

    function setFCTokenContract(address _address) external onlyOwner {
        fcTokenContract = _address;
    }

    function setMintStatePause() external onlyOwner {
        mintState = MintState.PAUSED;
    }
    
    function setMintStateAllowList() external onlyOwner {
        mintState = MintState.ALLOWLIST;
    }
    
    function setMintStatePublic() external onlyOwner {
        mintState = MintState.PUBLIC;
    }
}