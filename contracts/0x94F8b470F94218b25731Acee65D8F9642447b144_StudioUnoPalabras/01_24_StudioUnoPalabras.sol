// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "./ERC721A.sol";
import "./interfaces/IOwnershipable.sol";
import "./ERC721ATokenUriDelegate.sol";
import "./ERC721AOperatorFilter.sol";

contract StudioUnoPalabras is ERC721A, ERC2981, Pausable, Ownable, ERC721AOperatorFilter, ERC721ATokenUriDelegate {
    using SignatureChecker for address;
    using Strings for uint256;

    bool public allowListMinting;
    bool public publicMinting;

    uint256 public publicPrice;
    uint256 public maxPublicMints;
    string public apiBaseURI;
    string public ipfsBaseURI;
    uint256 public currentRoundNumber;

    uint256 public lastIpfsTokenId;

    address public signer;

    address public trustedWallet_A;
    address public trustedWallet_B;

    uint256 public tokenId;

    mapping(bytes32 => bool) public claimedTokenIds;
    mapping(string => mapping(uint256 => uint256)) public mintedCounts;
    mapping(string => mapping(uint256 => mapping(address => uint256))) public claimWithSignatureMintedCounts;
    mapping(string => bool) public mintedWords;
    mapping(uint256 => string) public tokenWords;

    event FundsTransferred(address _wallet, uint256 _amount);
    event Minted(address _buyer, uint256 _paid, uint256 _quantity, uint256 _tokenId, string _word, uint256 _round);
    event ClaimMinted(address _buyer, uint256 _paid, uint256 _tokenId, string _word, uint256 _round);
    event PrivateMinted(address _buyer, uint256 _quantity, uint256 _tokenId, string _word, uint256 _round);
    event ArtistMinted(address _buyer, uint256 _quantity, uint256 _tokenId, string _word, uint256 _round);
    event PremiumMinted(address _buyer, uint256 _paid, uint256 _tokenId, string _word, uint256 _round);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token.
     */
    constructor(
      address _trustedWallet_A,
      address _trustedWallet_B,        
      address _signer,
      uint256 _publicPrice,
      uint256 _maxPublicMints
    ) ERC721A("StudioUno Palabras", "S1PALABRAS") {
        trustedWallet_A = _trustedWallet_A;
        trustedWallet_B = _trustedWallet_B;

        signer = _signer;
        publicPrice = _publicPrice;
        maxPublicMints = _maxPublicMints;
        currentRoundNumber = 1;
        lastIpfsTokenId = 0;

        allowListMinting = false;
        publicMinting = false;

        _pause();
    }

    function mint(address _receiver, uint256 _quantity) internal {
      if(msg.value > 0) {
          payment();
      }

      _safeMint(_receiver, _quantity);
    }

    function allowListMint(
        string memory _word,
        uint256 _roundNumber,
        uint256 _quantityToMint,
        uint256 _quantityAllowed,
        bytes memory _signature
    ) external payable whenNotPaused whenAllowListMinting {
        require(_quantityToMint > 0, "S1: mint quantity must be greater than 0");
        require(maxPublicMints >= _quantityToMint, "S1: minted quantity is higher than max public mints");
        require(_quantityAllowed >= mintedCounts[_word][_roundNumber] + _quantityToMint, "S1: wrong quantity to mint");
        require(verifyAllowListMintSignature(_word, _roundNumber, _quantityAllowed, msg.sender, _signature), "S1: signature not valid");
        require(_roundNumber == currentRoundNumber, "S1: wrong round number");
        require(msg.value >= publicPrice * _quantityToMint, "S1: value sent is lower");
        
        mintedCounts[_word][_roundNumber] += _quantityToMint;
        for (uint256 i = 0; i < _quantityToMint; i++) {
          tokenId ++;
          tokenWords[tokenId] = _word;
        }
        mintedWords[_word] = true;
        mint(msg.sender, _quantityToMint);
        emit Minted(msg.sender, msg.value, _quantityToMint, tokenId, _word, _roundNumber);
    }

    function publicMint(
        string memory _word,
        uint256 _roundNumber,
        uint256 _quantityToMint,
        uint256 _quantityAllowed,
        bytes memory _signature
    ) external payable whenNotPaused whenPublicMinting {
        require(_quantityToMint > 0, "S1: mint quantity must be greater than 0");
        require(_quantityAllowed >= mintedCounts[_word][_roundNumber] + _quantityToMint, "S1: wrong quantity to mint");
        require(verifyPublicMintSignature(_word, _roundNumber, _quantityAllowed, _signature), "S1: signature not valid");
        require(_roundNumber == currentRoundNumber, "S1: wrong round number");
        require(msg.value >= publicPrice * _quantityToMint, "S1: value sent is lower");
        
        mintedCounts[_word][_roundNumber] += _quantityToMint;
        for (uint256 i = 0; i < _quantityToMint; i++) {
          tokenId ++;
          tokenWords[tokenId] = _word;
        }
        mintedWords[_word] = true;
        mint(msg.sender, _quantityToMint);
        emit Minted(msg.sender, msg.value, _quantityToMint, tokenId, _word, _roundNumber);
    }

    function premiumMint(
        string memory _word,
        uint256 _premiumPublicPrice,
        bytes memory _signature
    ) external payable whenNotPaused {
        require(msg.value >= _premiumPublicPrice, "S1: value sent is lower");
        require(verifyPremiumMintSignature(_word, _premiumPublicPrice, _signature), "S1: signature not valid");
        require(mintedWords[_word] == false, "S1: Premium word already minted");
        tokenId++;
        mintedWords[_word] = true;
        tokenWords[tokenId] = _word;
        mint(msg.sender, 1);
        emit PremiumMinted(msg.sender, msg.value, tokenId, _word, currentRoundNumber);
    }

    function premiumRequestedMint(
        string memory _word,
        uint256 _premiumPublicPrice,
        bytes memory _signature
    ) external payable whenNotPaused {
        require(msg.value >= _premiumPublicPrice, "S1: value sent is lower");
        require(verifyPremiumRequestedMintSignature(_word, msg.sender, _premiumPublicPrice, _signature), "S1: signature not valid");
        require(mintedWords[_word] == false, "S1: Premium word already minted");
        tokenId++;
        mintedWords[_word] = true;
        tokenWords[tokenId] = _word;
        mint(msg.sender, 1);
        emit PremiumMinted(msg.sender, msg.value, tokenId, _word, currentRoundNumber);
    }

    function claim(
        uint256 _tokenId,
        address _collectionAddress,
        string memory _word,
        uint256 _roundNumber,
        bytes memory _signature
    ) external whenNotPaused {
        require(IOwnershipable(_collectionAddress).ownerOf(_tokenId) == msg.sender, "S1: sender is not owner");
        require(verifyClaimSignature(_word, _roundNumber, _collectionAddress, _signature), "S1: signature not valid");
        require(_roundNumber == currentRoundNumber, "S1: wrong round number");
        
        bytes32 hashed_key = keccak256(abi.encodePacked(_tokenId, _word, _collectionAddress, _roundNumber));
        
        require(claimedTokenIds[hashed_key] == false, "S1: Token has been claimed");
        claimedTokenIds[hashed_key] = true;

        tokenId++;
        mintedWords[_word] = true;
        tokenWords[tokenId] = _word;
        mint(msg.sender, 1);
        emit ClaimMinted(msg.sender, 0, tokenId, _word, _roundNumber);
    }

    function claimWithSignature(
        string memory _word,
        uint256 _roundNumber,
        uint256 _quantityToMint,
        uint256 _quantityAllowed,
        bytes memory _signature
    ) external whenNotPaused {
        require(_quantityToMint > 0, "S1: mint quantity must be greater than 0");
        require(_quantityAllowed >= claimWithSignatureMintedCounts[_word][_roundNumber][msg.sender] + _quantityToMint, "S1: wrong quantity to mint");
        require(verifyClaimWithSignature(_word, _roundNumber, _quantityAllowed, msg.sender, _signature), "S1: signature not valid");
        require(_roundNumber == currentRoundNumber, "S1: wrong round number");
        
        claimWithSignatureMintedCounts[_word][_roundNumber][msg.sender] += _quantityToMint;
        for (uint256 i = 0; i < _quantityToMint; i++) {
          tokenId ++;
          tokenWords[tokenId] = _word;
        }
        mintedWords[_word] = true;
        mint(msg.sender, _quantityToMint);
        emit ClaimMinted(msg.sender, 0, tokenId, _word, _roundNumber);
    }

    function privateMint(
        address _receiver,
        string memory _word,
        uint256 _quantity,
        uint256 _roundNumber,
        bool _artistMint
    ) external onlyOwner {
        mintedCounts[_word][_roundNumber] += _quantity;
        for (uint256 i = 0; i < _quantity; i++) {
          tokenId ++;
          tokenWords[tokenId] = _word;
        }
        mintedWords[_word] = true;
        mint(_receiver, _quantity);
        if (_artistMint) {
          emit ArtistMinted(_receiver, _quantity, tokenId, _word, _roundNumber);
        } else {
          emit PrivateMinted(_receiver, _quantity, tokenId, _word, _roundNumber);
        }
    }

    /// @dev Returns if signature is whitelisted to mint tokens.
    function verifyPublicMintSignature(
        string memory _word,
        uint256 _roundNumber,
        uint256 _quantityAllowed,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(_word, _roundNumber, _quantityAllowed));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    function verifyAllowListMintSignature(
        string memory _word,
        uint256 _roundNumber,
        uint256 _quantityAllowed,
        address _senderAddress,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(_word, _roundNumber, _quantityAllowed, _senderAddress));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    function verifyPremiumMintSignature(
        string memory _word,
        uint256 _premiumPublicPrice,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(_word, _premiumPublicPrice));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    function verifyPremiumRequestedMintSignature(
        string memory _word,
        address _authorizedAddress,
        uint256 _premiumPublicPrice,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(_word, _authorizedAddress, _premiumPublicPrice));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    function verifyClaimSignature(
        string memory _word,
        uint256 _roundNumber,
        address _collectionAddress,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(_word, _roundNumber, _collectionAddress));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    function verifyClaimWithSignature(
        string memory _word,
        uint256 _roundNumber,
        uint256 _quantityAllowed,
        address _senderAddress,
        bytes memory _signature
    ) internal view returns (bool) {
        bytes32 result = keccak256(abi.encodePacked(_word, _roundNumber, _quantityAllowed, _senderAddress, "S1Claim"));
        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", result));
        return signer.isValidSignatureNow(hash, _signature);
    }

    /// @dev Split value paid for a token
    /// Emits two {FundsTransfered} events.
    function payment() internal {
        uint256 amount = (msg.value * 95) / 100;
        (bool success, ) = trustedWallet_A.call{value: amount}("");
        require(success, "S1: Transfer A failed");
        emit FundsTransferred(trustedWallet_A, amount);

        amount = msg.value - amount;
        (success, ) = trustedWallet_B.call{value: amount}("");
        require(success, "S1: Transfer B failed");
        emit FundsTransferred(trustedWallet_B, amount);
    }

    /// @dev Pause getGenesisToken(). Only DEFAULT_ADMIN_ROLE can call it.
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause getGenesisToken(). Only DEFAULT_ADMIN_ROLE can call it.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates address of 'signer'
     * @param _signer  New address for 'signer'
     */
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * @dev Updates address of 'trustedWallet_A'
     * @param _trustedWallet  New address for 'trustedWallet_A'
     */
    function setTrustedWallet_A(address _trustedWallet) external onlyOwner {
        trustedWallet_A = _trustedWallet;
    }

    /**
     * @dev Updates address of 'trustedWallet_B'
     * @param _trustedWallet  New address for 'trustedWallet_B'
     */
    function setTrustedWallet_B(address _trustedWallet) external onlyOwner {
        trustedWallet_B = _trustedWallet;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setMaxPublicMints(uint256 _maxPublicMints) external onlyOwner {
        maxPublicMints = _maxPublicMints;
    }

    function setLastIpfsTokenId(uint256 _newLastIpfsTokenId) external onlyOwner {
        lastIpfsTokenId = _newLastIpfsTokenId;
    }

    function setApiBaseURI(string memory _newApiBaseURI) external onlyOwner {
        apiBaseURI = _newApiBaseURI;
    }

    function setIpfsBaseURI(string memory _newIpfsBaseURI) external onlyOwner {
        ipfsBaseURI = _newIpfsBaseURI;
    }

    function setAllowListMinting(bool _allowListMinting) external onlyOwner {
        allowListMinting = _allowListMinting;
    }

    function setPublicMinting(bool _publicMinting) external onlyOwner {
        publicMinting = _publicMinting;
    }

    function startNextRound() external onlyOwner {
        currentRoundNumber += 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override(ERC721ATokenUriDelegate, ERC721A) returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = "";
        if(_tokenId <= lastIpfsTokenId) {
            baseURI = ipfsBaseURI;
        } else {
            baseURI = apiBaseURI;
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : '';
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC2981, ERC721A) returns (bool) {
        return
            _interfaceId == 0x7f5828d0 ||
            super.supportsInterface(_interfaceId);
    }

    modifier whenPublicMinting {
        require(publicMinting == true, "S1: PublicMinting is not enabled");
        _;
    }

    modifier whenAllowListMinting {
        require(allowListMinting == true, "S1: AllowListMinting is not enabled");
        _;
    }

    // ERC2981 functions
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