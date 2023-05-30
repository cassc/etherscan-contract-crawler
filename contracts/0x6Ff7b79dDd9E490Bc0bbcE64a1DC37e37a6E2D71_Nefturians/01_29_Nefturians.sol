// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/ECDSALibrary.sol";
import "../libraries/MerkleProofLibrary.sol";
import "../interfaces/INefturians.sol";
import "../interfaces/INefturiansArtifact.sol";
import "../interfaces/INefturiansData.sol";
import "./AccessControl.sol";
import "./ERC721A.sol";
import "./NefturiansArtifact.sol";
import "./NefturiansData.sol";

/**********************************************************************************************************************/
/*                                                                                                                    */
/*                                                     Nefturians                                                     */
/*                                                                                                                    */
/*                     NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                  NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                  */
/*                NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                */
/*              NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN              */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNN...............NNNNNNNNNNNN............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN.................NNNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN...................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN.....................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN.......................NNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..........................NNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............................NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNN............NNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN............NNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNN...............NNNNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNNNN............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN..............NNNNNNNN.............NNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN...............NNNNN.............NNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN...............NNN.............NNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNN.............NNNNNNNNNN............................NNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN..........................NNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNN........................NNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNN.....................NNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN..................NNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNN..............NNNNNNNNNNN................NNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNN...........NNNNNNNNNNNNN..............NNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.........NNNNNNNNNNNNNNNN...........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.......NNNNNNNNNNNNNNNNNNN........NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNN.NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*          NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN          */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*           NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN           */
/*            NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN            */
/*             NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN             */
/*               NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN               */
/*                 NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                 */
/*                    NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN                     */
/*                                                                                                                    */
/*                                                                                                                    */
/*                                                                                                                    */
/**********************************************************************************************************************/

contract Nefturians is ERC721A, Ownable, AccessControl, Pausable, INefturians {

  /**
   * Base URI for offchain metadata
   */
  string private _baseTokenURI;

  /**
   * Roles used for access control
   */
  bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 internal constant DAO_ROLE = keccak256("DAO_ROLE");
  bytes32 internal constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
  bytes32 internal constant METADATA_ROLE = keccak256("METADATA_ROLE");
  bytes32 internal constant DATA_CONTRACT_ROLE = keccak256("DATA_CONTRACT_ROLE");
  bytes32 internal constant ARTIFACT_CONTRACT_ROLE = keccak256("ARTIFACT_CONTRACT_ROLE");
  bytes32 internal constant URI_ROLE = keccak256("URI_ROLE");

  /**
   * Minting rules and supplies
   */
  uint256 internal constant MAX_SUPPLY = 8001;
  uint256 internal constant TOKENS_RESERVED = 250;
  uint256 internal constant MINTING_PRICE = 0.15 ether;
  uint256 internal constant MAX_PUBLIC_MINT = 5;
  uint256 internal constant MAX_WHITELIST_MINT = 2;

  /**
   * Sale calendar
   */
  uint256 internal preSaleStartTimestamp = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
  uint256 internal publicSaleStartTimestamp = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  /**
   * Minting state used to enforce aforementioned rules
   */
  uint256 internal reservedTokensMinted = 0;
  mapping(address => uint256) private nonces;
  mapping(address => uint256) public whitelistClaimed;
  mapping(address => uint256) public publicClaimed;

  /**
   * Root hash for the whitelist merkle tree
   */
  bytes32 public merkleRoot;

  /**
   * Payment distribution and addresses
   */
  uint256 internal totalShares = 1000;
  uint256 internal totalReleased;
  mapping(address => uint256) internal released;
  mapping(address => uint256) internal shares;
  address internal gnosisSafe = 0x9Ba52109EdA0B6aFB60f0c98265a7457d1b47763;
  address internal CEO = 0x741572cee2Cc991DBC142F0910e9f47A3871c110;
  address internal CTO = 0x5712dABA01D33b323D5130cA6c48E11427d675B2;
  address internal COO = 0x657C9FDe093e08fe976686f4b68FaAC57fBF8bbE;
  address internal CMO = 0xA944E23Fc61D57502bfBf8dFa358Aadeb5ADB64C;
  address internal Dev = 0x9Eb3a30117810d5a36568714EB5350480942f644;
  address internal Advisor = 0x1DbBEc72Fc72406851aB9d42c18dc52aBEbBB287;

  /**
   * Side contracts
   */
  INefturianArtifact internal nefturiansArtifacts;
  INefturiansData internal nefturiansData;

  /**
   * Provably fair metadata will respect this hash
   *
   * To ensure fair disitrubution of attributes among the tokens, the 8001 attributes objects will be published
   * in their original order and hashed into the provableFairnessHash public variable.
   *
   * Before revealing the metadata, random numbers provided by the community will be hashed together to ensure
   * a fair random shuffling of that order before the reveal.
   */
  string public provableFairnessHash;

  constructor() ERC721A("Nefturians", "NFTR") {
    nefturiansArtifacts = new NefturiansArtifact();
    nefturiansData = new NefturiansData();

    _grantRole(DEFAULT_ADMIN_ROLE, gnosisSafe);
    _grantRole(MINTER_ROLE, gnosisSafe);
    _grantRole(PAUSER_ROLE, gnosisSafe);
    _grantRole(DAO_ROLE, gnosisSafe);
    _grantRole(SIGNER_ROLE, gnosisSafe);
    _grantRole(URI_ROLE, gnosisSafe);
    _grantRole(URI_ROLE, msg.sender);
    _grantRole(METADATA_ROLE, gnosisSafe);
    _grantRole(METADATA_ROLE, address(nefturiansData));
    _grantRole(METADATA_ROLE, address(nefturiansArtifacts));
    _grantRole(DATA_CONTRACT_ROLE, address(nefturiansData));
    _grantRole(ARTIFACT_CONTRACT_ROLE, address(nefturiansArtifacts));
    _grantRole(MINTER_ROLE, address(this));
    nefturiansArtifacts.transferOwnership(gnosisSafe);

    shares[gnosisSafe] = 872;
    shares[CEO] = 27;
    shares[CTO] = 27;
    shares[COO] = 27;
    shares[CMO] = 27;
    shares[Dev] = 10;
    shares[Advisor] = 10;

    require(
      shares[gnosisSafe] +
      shares[CEO] +
      shares[CTO] +
      shares[COO] +
      shares[CMO] +
      shares[Dev] +
      shares[Advisor] ==
      totalShares, "Wrong shares distribution");
  }

  /**
   * Update NefturiansArtifact contract
   * @param newNefturiansArtifact: address of new NefturiansArtifact contract
   */
  function setNefturiansArtifact(address newNefturiansArtifact) public onlyRole(DEFAULT_ADMIN_ROLE) {
    _revokeRole(METADATA_ROLE, address(nefturiansArtifacts));
    _revokeRole(ARTIFACT_CONTRACT_ROLE, address(nefturiansArtifacts));
    nefturiansArtifacts = INefturianArtifact(newNefturiansArtifact);
    _grantRole(METADATA_ROLE, address(nefturiansArtifacts));
    _grantRole(ARTIFACT_CONTRACT_ROLE, address(nefturiansArtifacts));
  }

  /**
   * Get the pinting price
   */
  function getMintingPrice() public pure returns (uint256) {
    return MINTING_PRICE;
  }

  /**
   * Get the address of the internally deployed NefturiansArtifact contract
   */
  function getArtifactContract() public view returns (address) {
    return address(nefturiansArtifacts);
  }

  /**
   * Get the timestamp of the presale start
   */
  function getPreSaleTimestamp() public view returns(uint256) {
    return preSaleStartTimestamp;
  }

  /**
   * Get the timestamp of the presale start
   */
  function getPublicSaleTimestamp() public view returns(uint256) {
    return publicSaleStartTimestamp;
  }

  /**
   * Get the address of the internally deployed NefturiansData contract
   */
  function getDataContract() public view returns (address) {
    return address(nefturiansData);
  }

  /**
   * Admin can move the presale start to avoid conflicting with NFT partners
   */
  function setPresaleStart(uint256 ts) public onlyRole(DEFAULT_ADMIN_ROLE) {
    preSaleStartTimestamp = ts;
  }

  /**
   * Admin can move the public sale start to avoid conflicting with NFT partners
   */
  function setPublicSaleStart(uint256 ts) public onlyRole(DEFAULT_ADMIN_ROLE) {
    publicSaleStartTimestamp = ts;
  }

  /**
   * Set the hash of all the attributes in their original order
   *
   * This function can only be called once
   */
  function setProvableFairnessHash(string calldata hash) public onlyRole(DEFAULT_ADMIN_ROLE) {
    provableFairnessHash = hash;
  }

  /**
   * Globally pauses minting
   */
  function pause() public onlyRole(PAUSER_ROLE) {
    _pause();
  }

  /**
   * Globally unpauses minting
   */
  function unpause() public onlyRole(PAUSER_ROLE) {
    _unpause();
  }

  /**
   * Mint function for devs
   * @param to: address of receiver
   * @param quantity: number of tokens to mint
   *
   * Error messages:
   *  - N0 : "Maximum supply would be exceeded with this mint" (should never happen but better safe than sorry)
   *  - N15: "Reserve supply would be exceeded with this mint"
   */
  function safeMint(address to, uint256 quantity) public onlyRole(MINTER_ROLE) {
    require(quantity + totalSupply() <= MAX_SUPPLY, "N0");
    require(reservedTokensMinted + quantity <= TOKENS_RESERVED, "N15");
    reservedTokensMinted += quantity;
    _safeMint(to, quantity);
  }

  /**
   * Mint function for presale
   * @param quantity: uint256 - number of tokens to mint
   * @param merkleProof: serie of merkle hashes to prove whitelist
   *
   * Error messages:
   *  - N7 : "Presale has not started"
   *  - N18: "Presale is over"
   *  - N8 : "Whitelist supply would be exceeded with this mint"
   *  - N9 : "The whitelist has not been initialized"
   *  - N5 : "You have to send the right amount"
   *  - N10: "Your max allocation would be exceeded with this mint"
   *  - N11: "Invalid proof of whitelist"
   */
  function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) public payable whenNotPaused {
    require(block.timestamp >= preSaleStartTimestamp, "N7");
    require(block.timestamp < publicSaleStartTimestamp, "N18");
    require(totalSupply() + quantity <= MAX_SUPPLY - TOKENS_RESERVED + reservedTokensMinted, "N8");
    require(merkleRoot != 0, "N9");
    require(msg.value == MINTING_PRICE * quantity, "N5");
    require(whitelistClaimed[msg.sender] + quantity <= MAX_WHITELIST_MINT, "N10");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProofLibrary.verify(merkleProof, merkleRoot, leaf), "N11");
    whitelistClaimed[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  /**
   * Public mint function that requires a signature from a SIGNER_ROLE
   * @param quantity: number of tokens to mint
   * @param signature: signature from a wallet with SIGNER_ROLE to authorize the mint
   *
   * Error messages:
   *  - N2 : "Public sale has not started yet"
   *  - N3 : "Public supply would be exceeded with this mint"
   *  - N4: "Mint quantity too high"
   *  - N5: "You have to send the right amount"
   *  - N6: "This operation has not been signed"
  */
  function publicMint(uint256 quantity, bytes calldata signature) public payable whenNotPaused {
    require(block.timestamp >= publicSaleStartTimestamp, "N2");
    require(quantity + totalSupply() <= MAX_SUPPLY - TOKENS_RESERVED + reservedTokensMinted, "N3");
    require(publicClaimed[msg.sender] + quantity <= MAX_PUBLIC_MINT, "N4");
    publicClaimed[msg.sender] += quantity;
    require(msg.value == MINTING_PRICE * quantity, "N5");
    uint256 nonce = nonces[msg.sender] + 1;
    require(hasRole(SIGNER_ROLE, ECDSALibrary.recover(abi.encodePacked(msg.sender, nonce), signature)), "N6");
    nonces[msg.sender] += 1;
    _safeMint(msg.sender, quantity);
  }

  /**
   * Define merkle root
   * @param newMerkleRoot: newly defined merkle root
   */
  function setMerkleRoot(bytes32 newMerkleRoot) public onlyRole(MINTER_ROLE) {
    merkleRoot = newMerkleRoot;
  }

  /**
   * Get the nonce of a particular address
   * @param minter: selected address from which to get the nonce
   */
  function getNonce(address minter) public view returns (uint256) {
    return nonces[minter] + 1;
  }

  /**
   * Increment the nonce
   * @param holder: address of the address for which to increnebnt the nonce
   */
  function incrementNonce(address holder) public onlyRole(METADATA_ROLE) {
    nonces[holder] += 1;
  }

  /**
   * Get the on chain metadata of a token
   * @param tokenId: id of the token from which to get the on chain metadata
   *
   * Error messages:
   *  - N12: "Token ID doesn't correspond to a minted token"
   */
  function getMetadata(uint256 tokenId) public view returns (string memory) {
    require(_exists(tokenId), "N12");
    return nefturiansData.getMetadata(tokenId);
  }

  /**
   * Add a new Metadata key
   * @param keyName: the name of the Metadata key
   */
  function addKey(string calldata keyName) public onlyRole(METADATA_ROLE) {
    nefturiansData.addKey(keyName);
  }

  /**
   * Get the base URI
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * Set the base URI
   * @param baseURI: new base URI
   */
  function setBaseURI(string calldata baseURI) external onlyRole(URI_ROLE) {
    _baseTokenURI = baseURI;
  }

  /**
   * Contract level Metadata URI
   */
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseTokenURI, "collection"));
  }

  /**
   * Get the URI of a selected token
   * @param tokenId: token id from which to get token URI
   *
   * Error messages:
   *  - N12: "Token ID doesn't correspond to a minted token"
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "N12");
      return string(abi.encodePacked(_baseTokenURI, StringsLibrary.toString(tokenId)));
  }

  /**
   * Withdraw contract balance to a shareholder proportionnaly to their share amount
   *
   * @param account: address of the shareholder
   *
   * Error messages:
   *  - N16: "You have no shares in the project"
   *  - N17: "All funds have already been sent"
   */
  function withdraw(address account) public {
    require(shares[account] > 0, "N16");
    uint256 totalReceived = address(this).balance + totalReleased;
    uint256 payment = (totalReceived * shares[account]) / totalShares - released[account];
    require(payment > 0, "N17");
    released[account] = released[account] + payment;
    totalReleased = totalReleased + payment;
    payable(account).transfer(payment);
  }

  /**
   * Mints an egg artifact for the buyer
   *
   * @param from: transferer's address
   * @param to: reveiver's address
   */
  function _beforeTokenTransfers(
    address from,
    address to
  ) internal override {
    if (from != address(0) && to != address(0)) {
      nefturiansArtifacts.giveEgg(to);
    }
  }
}