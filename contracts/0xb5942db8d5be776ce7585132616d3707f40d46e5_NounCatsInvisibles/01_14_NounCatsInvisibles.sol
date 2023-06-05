//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ Noun Cats – The Invisibles $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!$$$$jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!$$$$jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$!!!!!!lllllllll>---------~!!!!!$$$$jjjjjt|||||||||ruuuuuuuuurjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$!!!!!;         )$$$$$$$$$C!!!!!$$$$jjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$!!!!!;         )$$$$$$$$$C!!!!!$$$$jjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$jjjjjjjjjjjjjjj{!!!!;         )$$$$$$$$$C!!!!]jjjjjjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$jjjjjjjjjjjjjjj)!!!!;         )$$$$$$$$$C!!!![jjjjjjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$jjjjjjjjjjjjjjj)!!!!;         )$$$$$$$$$C!!!![jjjjjjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$jjjjjj$$$$$$$$$!!!!!;         )$$$$$$$$$C!!!!!$$$$jjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$jjjjjj$$$$$$$$$!!!!!;         )$$$$$$$$$C!!!!!$$$$jjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$jjjjjj$$$$$$$$$!!!!!;         )$$$$$$$$$C!!!!!$$$$jjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$jjjjjj$$$$$$$$$!!!!!;         )$$$$$$$$$C!!!!!$$$$jjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$jjjjjj$$$$$$$$$!!!!!;         )$$$$$$$$$C!!!!!$$$$jjjjj>         J$$$$$$$$$Jjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$xjjjjj$$$$$$$$$!!!!!l;;;;;;;;;~)))))))))?!!!!!$$$$jjjjj|{{{{{{{{{nYYYYYYYYYnjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!$$$$jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!$$$$jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

// Contract by: @backseats_eth


/// Noun Cats is two 5,000 piece collections. This is part one: The Invisibles. The goal is to acquire your Nounterpart, in this case, The Cat, from the forthcoming collection
/// and either work solo or with the Nounterpart owner to interact with a contract to mint something completely new!
contract NounCatsInvisibles is ERC721, Ownable {
    using ECDSA for bytes32;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    uint256 public price = 0.075 ether;

    // We're giving away 500 free Invisibles!
    uint256 public constant MAX_EARLY_SALE_SUPPLY = 500;

    // We go one over the actual max supply because < is cheaper than <= gas-wise.
    uint256 public constant MAX_SUPPLY = 5001;

    // Tracking which nonces have been used from the server
    mapping(string  => bool) public usedNonces;

    // Tracking which addresses have minted their 1 free Invisible Noun Cat
    mapping(address => bool) public didMintEarly;

    // Tracking how many mints an address has done in pre-sale. Can mint up to 3
    mapping(address => uint) public allowListMintCount;

    // The Merkle tree root for minting a free Invisible Noun Cat to certain addresses
    bytes32 public freeSaleMerkleRoot;

    // The Merkle tree root of our allow list addresses. Cheaper than storing an array of addresses or encrypted addresses on-chain
    bytes32 public allowListMerkleRoot;

    // The address of the private key that creates nonces and signs signatures for mint
    address public systemAddress;

    // The IPFS URI where our data can be found
    string public _baseTokenURI;

    // Tracking whether we've minted our 25 Invisibles yet
    bool public teamMintFinished;

    // An enum and associated variable tracking the state of the mint
    enum MintState {
      CLOSED,
      EARLY,
      ALLOWLIST,
      OPEN
    }

    MintState public _mintState;

    // Constructor

    constructor() ERC721("Noun Cats Invisibles", "INVISINOUNS") {}

    // Mint Functions

    /// @notice The first 500 Noun Cats are free! Each wallet can only mint 1.
    function mintEarly(bytes32[] calldata _merkleProof) external {
      require(_mintState == MintState.EARLY, "Early mint closed");
      require(totalSupply() < MAX_EARLY_SALE_SUPPLY, "Early mint full");
      require(!didMintEarly[msg.sender], 'Already minted');

      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkleProof, freeSaleMerkleRoot, leaf), 'Not on the list');

      didMintEarly[msg.sender] = true;

      _tokenSupply.increment();
      _mint(msg.sender, totalSupply());
    }

    /// @notice Function requires a Merkle proof and will only work if called from the minting site.
    /// Allows the allowList minter to come back and mint again if they mint under 3 max mints in the first transaction(s).
    function allowListMint(bytes32[] calldata _merkleProof, uint _amount) external payable {
      require(_mintState == MintState.ALLOWLIST, "Allow list mint closed");
      require(allowListMintCount[msg.sender] + _amount < 4, "Can only mint 3");
      require(totalSupply() + _amount < MAX_SUPPLY, "Exceeds max supply");
      require(price * _amount == msg.value, "Wrong ETH amount");

      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkleProof, allowListMerkleRoot, leaf), 'Not on the list');

      allowListMintCount[msg.sender] = allowListMintCount[msg.sender] + _amount;

      mint(msg.sender, _amount);
    }

    /// @notice Mint up to 10 Invisible Noun Cats in a transaction
    function publicMint(string calldata _nonce, uint _amount, bytes calldata _signature) external payable {
      require(_mintState == MintState.OPEN, "Mint closed");
      require(msg.sender == tx.origin, "Real users only");
      require(_amount < 11, "Wrong amount");
      require(totalSupply() + _amount < MAX_SUPPLY, 'Exceeds max supply');
      require(price * _amount == msg.value, "Wrong ETH amount");
      require(!usedNonces[_nonce], "Nonce already used");

      require(isValidSignature(keccak256(abi.encodePacked(msg.sender, _amount, _nonce)), _signature), "Invalid signature");

      usedNonces[_nonce] = true;

      mint(msg.sender, _amount);
    }

    /// @notice Allows the team to mint Invisibles to a destination address
    function promoMint(address _to, uint _amount) external onlyOwner {
      require(totalSupply() + _amount < MAX_SUPPLY, 'Exceeds max supply');

      mint(_to, _amount);
    }

    /// @notice Allows the team to do a one-time mint of 25 Invisibles for events, giveaways, collabs, fun future things, etc.
    /// We like surprises.
    function teamMint() external onlyOwner {
      require(!teamMintFinished, "Already minted our Cats");
      require(totalSupply() + 25 < MAX_SUPPLY, 'Exceeds max supply');

      teamMintFinished = true;
      mint(msg.sender, 25);
    }

    function mint(address _to, uint _amount) private {
      for(uint i = 0; i < _amount; i++) {
        _tokenSupply.increment();
        _mint(_to, totalSupply());
      }
    }

    function totalSupply() public view returns (uint) {
      return _tokenSupply.current();
    }

    /// @notice Checks if the private key that singed the nonce matches the system address of the contract
    function isValidSignature(bytes32 hash, bytes calldata signature) internal view returns (bool) {
      require(systemAddress != address(0), "Missing system address");
      bytes32 signedHash = hash.toEthSignedMessageHash();
      return signedHash.recover(signature) == systemAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    // Ownable Functions

    function setSystemAddress(address _systemAddress) external onlyOwner {
      systemAddress = _systemAddress;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
      _baseTokenURI = _baseURI;
    }

    function setFreeSaleMerkleRoot(bytes32 _root) external onlyOwner {
      freeSaleMerkleRoot = _root;
    }

    function setAllowListMerkleRoot(bytes32 _root) external onlyOwner {
      allowListMerkleRoot = _root;
    }

    function setMintState(uint256 status) external onlyOwner {
      require(status <= uint256(MintState.OPEN), "Bad status");

      _mintState = MintState(status);
    }

    // Important: Set new price in wei (i.e. 50000000000000000 for 0.05 ETH)
    function setPrice(uint _newPrice) external onlyOwner {
      price = _newPrice;
    }

    function withdraw() external onlyOwner {
      address w1 = 0x702457481718bEF08C5bb0124083A1369fAB4542;
      address w2 = 0x5390B04839C6EBaA765886E1EDe2BCE7116e462F;
      address w3 = 0x02fBd51319bee0c0b135E99E0bABED20dF8414d2;
      address w4 = 0x3733f44e9FF13d398512449E4d96E78Bc5594708;
      address w5 = 0x3230086971D2D50D30642e3e344233f56BECB5C5;

      uint balance = address(this).balance;
      uint256 smallBal = balance * 50/1000;
      uint256 largeBal = balance * 425/1000;

      (bool sent, ) = w1.call{value: smallBal}("");
      require(sent, "w1 Send failed");
      (bool sent2, ) = w2.call{value: smallBal}("");
      require(sent2, "w2 Send failed");
      (bool sent3, ) = w3.call{value: smallBal}("");
      require(sent3, "w3 Send failed");
      (bool sent4, ) = w4.call{value: largeBal}("");
      require(sent4, "w4 Send failed");
      (bool sent5, ) =  w5.call{value: largeBal}("");
      require(sent5, "w5 Send failed");
    }

}