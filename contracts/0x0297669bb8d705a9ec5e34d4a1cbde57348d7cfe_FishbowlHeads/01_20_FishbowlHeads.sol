//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRNG.sol";

contract FishbowlHeads is ERC721Enumerable, Ownable, ReentrancyGuard, IERC777Recipient {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    using Strings for uint256;

    uint256   public constant _maxSupply        = 9999;
    uint256   public constant _maxMintCount     = 12;
    uint256   public constant _maxPresaleCount  = 3;
    uint256   public constant _maxECCount       = 2;
    uint256   public _mintPrice                 = 0.0369 ether;           //36900000000000000 wei
    uint256   public _discMintPrice             = 0.0300 ether;           //30000000000000000 wei
    uint256   public _dustPrice                 = 420 ether;
    uint256   public _ecMaxSupply               = 2000;
    uint256   public _ecSupplyCount             = 0;
    bool      public _publicSaleIsActive        = false;
    bool      public _presaleIsActive           = false;
    bool      public _dustMintActive            = false;
    bytes32   public _reqID                     = bytes32(0);
    IERC721   public _etherCards                = IERC721(0x97CA7FE0b0288f5EB85F386FeD876618FB9b8Ab8); //EC contract address
    IRNG      public _iRnd                      = IRNG(0x72170F577F3B221b3478E09ccD5323445a8460d7); //EC Randomiser contract address
    address   public _dustToken;

    bool    private _randomReceived       = false;
    uint256 private _teamTokenCount       = 24;
    uint256 private _randomCL             = 0;
    address private _signer               = address(0);
    address private _multiSig             = address(0);
    string  private _tokenPreRevealURI    = '';
    string  private _tokenRevealedBaseURI = '';

    mapping(address => uint) public _presaleMintCount;

    bytes32 constant private TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");
    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    event Receive(uint256);
    event Fallback(bytes,uint256);
    event PresaleEvent(uint256 quantity, uint256 value, bool ambassador);
    event ECEvent(uint256 quantity, uint256 value);
    event PublicEvent(uint256 quantity, uint256 value);
    event WithdrawEvent(uint256 value);
    event DustEvent(uint256 quantity, uint256 value);

    constructor(address signer, address multiSig, address dust) ERC721("Fishbowl Heads", "FBH") {
      _signer = signer;
      _multiSig = multiSig;
      _dustToken = dust;
      _ERC1820_REGISTRY.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    function setRng(IRNG rnd) external onlyOwner {
      _iRnd = rnd;
    }

    function setEC(IERC721 ec) external onlyOwner {
      _etherCards = ec;
    }

    function startPresale(bool state) external onlyOwner {
      _presaleIsActive = state;
    }


    function MintFBH (uint256 mintCount) internal {
        require(mintCount > 0, "No. of tokens <= zero");
        require(_tokenIds.current() + mintCount <= _maxSupply, "Only 9999 can be minted");

        for (uint256 i = 0; i < mintCount; i++) {
          _tokenIds.increment();
          uint256 newItemId = _tokenIds.current();
          _safeMint(msg.sender, newItemId);
      }
    }

    function presaleMint(uint256 tokenCount, bytes memory signature, bool ambassador) public payable {
      require(!(_publicSaleIsActive), "Public Sale is active");
      require(_presaleIsActive, "Pre-Sale not active yet");
      require(verify(msg.sender, signature, ambassador), "You are not on the Presale List");
      if(!(ambassador)) {
        require(_mintPrice * tokenCount <= msg.value, "Incorrect Ether value sent");
      }
      else{
        require(_discMintPrice * tokenCount <= msg.value, "Incorrect discount Ether value sent");
      }

      _presaleMintCount[msg.sender] += tokenCount;
      require(_presaleMintCount[msg.sender] <= _maxPresaleCount, "Exceeds max allowed limit");

      MintFBH(tokenCount);
      (bool sent, bytes memory data) = payable(_multiSig).call{value: msg.value}("");
      require(sent, "Failed to send Ether");
      emit PresaleEvent(tokenCount, msg.value, ambassador);
    }

    function ecMint(uint tokenCount) public payable {
      require(!(_publicSaleIsActive), "Public Sale is active");
      require(_presaleIsActive, "Pre-Sale not active yett");
      require(_etherCards.balanceOf(msg.sender) > 0, "You are not an Ether Card holder.");
      require(_mintPrice * tokenCount <= msg.value, "Incorrect Ether value sent.");

      _presaleMintCount[msg.sender] += tokenCount;
      _ecSupplyCount += tokenCount;
      require(_presaleMintCount[msg.sender] <= _maxECCount, "Exceeds max allowed limit");
      require(_ecSupplyCount < _ecMaxSupply, "EC max supply reached");

      MintFBH(tokenCount);
      (bool sent, bytes memory data) = payable(_multiSig).call{value: msg.value}("");
      require(sent, "Failed to send Ether");
      emit ECEvent(tokenCount, msg.value);
    }

    function startPublicSale(bool state) external onlyOwner {
      _publicSaleIsActive = state;
    }

    function publicMint(uint256 tokenCount) public payable {
      require(_publicSaleIsActive, "Public minting not active yet");
      require(!(_presaleIsActive), "Pre-Sale is active");
      require(tokenCount <= _maxMintCount, "Only 12 tokens can be minted per transaction");
      require(_mintPrice * tokenCount == msg.value, "Incorrect Ether value sent");

      MintFBH(tokenCount);
      (bool sent, bytes memory data) = payable(_multiSig).call{value: msg.value}("");
      require(sent, "Failed to send Ether");
      emit PublicEvent(tokenCount, msg.value);
    }

    function reserveMint(uint256 tokenCount) external onlyOwner {
        MintFBH(tokenCount);
    }

    function verify(address signedAddr, bytes memory signature, bool role) internal  view returns (bool) {
        require(signedAddr != address(0), "INVALID_SIGNER");
        bytes32 hash = keccak256(abi.encode(signedAddr, role));
        require (signature.length == 65,"Invalid signature length");
        bytes32 sigR;
        bytes32 sigS;
        uint8   sigV;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        assembly {
            sigR := mload(add(signature, 0x20))
            sigS := mload(add(signature, 0x40))
            sigV := byte(0, mload(add(signature, 0x60)))
        }

        bytes32 data =  keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );
        address recovered = ecrecover(
                data,
                sigV,
                sigR,
                sigS
            );

        return
            _signer == recovered;
    }

    function startDustMint(bool state) external onlyOwner {
        _dustMintActive = state;
    }

    function mintFBH_DUST(address dustMinter) internal {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(dustMinter, newItemId);
    }

    function tokensReceived(
        address ,
        address from,
        address ,
        uint256 amount,
        bytes calldata userData,
        bytes calldata
      ) external override nonReentrant {

        require(_dustMintActive, "Dust minting not active yet");
        require(msg.sender == _dustToken, "Unauthorised");
        require(_etherCards.balanceOf(from) > 0, "You are not an Ether Card holder.");

        uint256 tokenCount = amount/_dustPrice;
        _presaleMintCount[from] += tokenCount;
        _ecSupplyCount += tokenCount;
        require(_presaleMintCount[from] <= _maxECCount, "Exceeds max allowed limit");
        require(_ecSupplyCount < _ecMaxSupply, "EC max supply reached");
        require(tokenCount > 0, "No. of tokens <= zero");
        require(_tokenIds.current() + tokenCount <= _maxSupply, "Only 9999 can be minted");

        mintFBH_DUST(from);
        if(tokenCount == _maxECCount) {
            mintFBH_DUST(from);
        }
        IERC777(_dustToken).send(owner(), amount, bytes("Dust Minting"));
        emit DustEvent(tokenCount, amount);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        _mintPrice = newPrice;
    }

    function setDiscPrice(uint256 newPrice) external onlyOwner {
        _discMintPrice = newPrice;
    }

    function setDustPrice(uint256 newDustPrice) external onlyOwner {
        _dustPrice = newDustPrice;
    }

    function withdraw() external onlyOwner {
        uint256 amt = address(this).balance;
        (bool sent, bytes memory data) = payable(_multiSig).call{value: amt}("");
        require(sent, "Failed to send Ether");
        emit WithdrawEvent(amt);
    }

    function setPreRevealURI(string calldata URI) external onlyOwner {
        _tokenPreRevealURI = URI;
     }

    function setRevealBaseURI(string calldata revealedBaseURI) external onlyOwner {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function offsetTokenURI(uint256 tokenId) internal view returns(uint256) {
      if (tokenId <= _teamTokenCount) {
          return tokenId;
      }
      uint normal_tokenId = tokenId - (_teamTokenCount+1);
      uint normal_supply = totalSupply() - _teamTokenCount;
      uint new_normal = (normal_tokenId + _randomCL) % normal_supply;

      return new_normal + (_teamTokenCount+1);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token does not exist');
        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return bytes(revealedBaseURI).length > 0 ?
        string(abi.encodePacked(revealedBaseURI, offsetTokenURI(tokenId).toString())) :
        _tokenPreRevealURI;
    }

    function setMultisig(address safe) external onlyOwner {
        _multiSig = safe;
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function setRandomiser() external onlyOwner {
       _reqID = _iRnd.requestRandomNumberWithCallback();
    }

    function process(uint256 random, bytes32 reqID) external {
        require(msg.sender == address(_iRnd),"Unauthorised RNG");
        require(_reqID == reqID, "Incorrect request ID sent");
        require(!(_randomReceived), "Random No. already received");
        _randomCL = random/2;
        _randomReceived = true;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        emit Receive(msg.value);
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        emit Fallback(msg.data, msg.value);
    }

    // --- recovery of tokens sent to this address

    function retrieveERC20(address _tracker, uint256 amount) external onlyOwner {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}