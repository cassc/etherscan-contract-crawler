//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import { ZukuverseBase } from "./ZukuverseBase.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// all the events for specific errors that occur 
error Zukuverse__LOWFUNDS();
error Zukuverse__OVERMAXMINT();
error Zukuverse__MAXSUPPLYREACHED();
error Zukuverse__WRONGTYPE();
error Zukuverse__NOTPUBLIC();
error Zukuverse__NOTOGGEMSALE();
error Zukuverse__NOTGEMLISTED();
error Zukuverse__NOTOGLISTED();

/**
 * @title Zukuverse NFT Smart Contract. Mint a gemstone and harness the hado
 * @author NazaWeb team
 * @notice this is the main NFT smart contract for the Zukuverse collection 
 * @dev inherits abstract base for full implementation 
 */
contract Zukuverse is ZukuverseBase {
  /**
   * @notice publicSale is a bool that determines when public mint is active
   */
  bool public publicSale = false;
  /**
   * @notice ogGemSale is a bool that determines when OG/Gem list mint is active 
   */
  bool public ogGemSale = false;
  bytes32 internal merkleRoot;
  using MerkleProof for bytes32[];

/**
 * @notice this is the object based configuration for main mint info 
 */
  struct MintConfig {
    uint24 gemOgListMaxPerAddress;
    uint24 publicMaxPerAddress;
    uint256 gemListPrice;
    uint256 OGPrice;
    uint256 publicPrice;
    uint256 maxSupply;
  }
  MintConfig public zukuMintconfig;

  /**
   * @notice event is emitted after successful mint
   * @param sender refers to who minted
   * @param quantity refers to how many the sender minted
   */
  event Zukuverse__Minted(address indexed sender, uint256 indexed quantity);

  /**
   * @notice modifier ensures that whomever is calling the contract comes 
   * from an actual wallet, not smart contract
   */
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "Not a Sender");
    _;
  }

  /**
   * @notice this is the main constructor with all of the initial values 
   * @dev initializing the abstract base contract for full implementation 
   * @param _payees is an array of strings those getting rewarded with creator fees 
   * @param _shares is an array of shares that represent how the funds get split between payees 
   * @param _name is the name of the Collection 
   * @param _symbol is the symbol of the Collection 
   * @param _uri is the the baseURI for the nft metadata 
   * @param _mintDetails contains the detailed configuration for the mint 
   * @param _quantity refers to the quntity the team initially wants to reserve 
   * @param _merkleRoot is implemented to verify if wallet is gem listed or OG listed 
   * @param  _owner is whomever is going to be the main owner of the contract 
   * @param _devWallet is the wallet for the development team 
   */
  constructor(
    address[] memory _payees,
    uint256[] memory _shares,
    string memory _name,
    string memory _symbol,
    string memory _uri,
    MintConfig memory _mintDetails,
    uint256 _quantity,
    bytes32 _merkleRoot,
    address _owner,
    address _devWallet
  ) ZukuverseBase(_payees,_shares,_name,_symbol,_uri) {
    zukuMintconfig.gemOgListMaxPerAddress = _mintDetails.gemOgListMaxPerAddress;
    zukuMintconfig.publicMaxPerAddress = _mintDetails.publicMaxPerAddress;
    zukuMintconfig.gemListPrice = _mintDetails.gemListPrice;
    zukuMintconfig.OGPrice = _mintDetails.OGPrice;
    zukuMintconfig.publicPrice = _mintDetails.publicPrice;
    zukuMintconfig.maxSupply = _mintDetails.maxSupply;
    merkleRoot = _merkleRoot;
    setAdmin(_devWallet);
    adminMint(_owner, _quantity);
    transferOwnership(_owner);
  }

  /**
   * @notice editMintConfig is function executed to update mint details 
   * @dev onlyAdmin can execute the function 
   * @param _gemListMaxPerAddress is the max of NFTs per wallet for Gem or OG Listed
   * @param _publicMaxPerAddress is the max of NFts per wallet for public mint 
   * @param _gemListPrice is the cost for NFT mint for Gem Listed mints
   * @param _OGPrice is the cost for NFT mint for OG Listed mints 
   * @param _publicPrice is the cost for NFT for public mint
   * @param _maxSupply is the max Supply for total collection 
   */
  function editMintConfig(
    uint24 _gemListMaxPerAddress,
    uint24 _publicMaxPerAddress,
    uint256 _gemListPrice,
    uint256 _OGPrice,
    uint256 _publicPrice,
    uint256 _maxSupply
  ) external onlyAdmin {
    zukuMintconfig.gemOgListMaxPerAddress = _gemListMaxPerAddress;
    zukuMintconfig.publicMaxPerAddress = _publicMaxPerAddress;
    zukuMintconfig.gemListPrice = _gemListPrice;
    zukuMintconfig.OGPrice = _OGPrice;
    zukuMintconfig.publicPrice = _publicPrice;
    zukuMintconfig.maxSupply = _maxSupply;
  }

  /**
   * @notice changeRoot allows for update of allowlist for gem list and OG mint if needed
   * @dev only admin can update the merkleRoot 
   * @param _newRoot is the new merkle root to be implemented in contract
   */
   function changeRoot(bytes32 _newRoot) external onlyAdmin {
    merkleRoot = _newRoot;
  }

  /**
   * @notice editActiveSale allows for update of sale phase for og, gem and public mints 
   * @dev only admin can update the active sale 
   * @param _publicSale is the bool for update of public sale status 
   * @param _ogGemSale is the bool for update of OG And Gem Listed sale status 
   */
  function editActiveSale(bool _publicSale, bool _ogGemSale) external onlyAdmin {
    publicSale = _publicSale;
    ogGemSale = _ogGemSale;
  }


  /**
   * @notice gemListMint is the core mint function for those only in Gem List
   * @param _quantity refers to the total number of minted NFTs in single transaction
   * @param _proof is an array of hashes proving the user is on the list 
   */
  function gemListMint( uint256 _quantity, bytes32[] calldata _proof)
    external
    payable
    callerIsUser
  {
    if (msg.value < zukuMintconfig.gemListPrice * _quantity) revert Zukuverse__LOWFUNDS();
    if (!ogGemSale) revert Zukuverse__NOTOGGEMSALE();
    if (numberMinted(msg.sender) + _quantity > zukuMintconfig.gemOgListMaxPerAddress) revert Zukuverse__OVERMAXMINT();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, "gem-list"));
    if(!MerkleProof.verify(_proof, merkleRoot, leaf)) revert Zukuverse__NOTGEMLISTED();
    mint(_quantity);
  }

  /**
   * @notice ogMint is the core mint function for those only in OG List 
   * @param _quantity refers to the total number of minted NFTs in single transaction
   * @param _proof is an array of hashes proving the user is on the list 
   */
  function ogMint(
    uint256 _quantity,
    bytes32[] calldata _proof
  )
    external
    payable
    callerIsUser
  {
    if (msg.value < zukuMintconfig.OGPrice * _quantity) revert Zukuverse__LOWFUNDS();
    if (!ogGemSale) revert Zukuverse__NOTOGGEMSALE();
    if (numberMinted(msg.sender) + _quantity > zukuMintconfig.gemOgListMaxPerAddress) revert Zukuverse__OVERMAXMINT();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, "og-list"));
    if(!MerkleProof.verify( _proof, merkleRoot, leaf)) revert Zukuverse__NOTOGLISTED();
    mint(_quantity);
  }

/**
   * @notice ogMint is the core mint function for those only in OG List 
   * @param _quantity refers to the total number of minted NFTs in single transaction
   */
  function publicMint(uint256 _quantity)
    external
    payable
    callerIsUser
  {
    if (!publicSale) revert Zukuverse__NOTPUBLIC();
    if (msg.value < zukuMintconfig.publicPrice * _quantity) revert Zukuverse__LOWFUNDS();
    if (numberMinted(msg.sender) + _quantity > zukuMintconfig.publicMaxPerAddress) revert Zukuverse__OVERMAXMINT();
    mint(_quantity);
  }

/**
   * @notice the main mint function for all the phases 
   * @dev set internally since it is called within each of the individual mint functions for the
   * phases. Also implement Reentrancy guard and callerIsUser for security purposes 
   * @param _quantity refers to the total number of minted NFTs in single transaction
   */
  function mint(uint256 _quantity) internal {
    if (totalSupply() + _quantity > zukuMintconfig.maxSupply) revert Zukuverse__MAXSUPPLYREACHED();
    _safeMint(msg.sender, _quantity);
    emit Zukuverse__Minted(msg.sender, _quantity);
  }

/**
   * @notice the admin mint function for team NFT reserve  
   * @dev implement nonReentrant and callerIsUser for security purposes and only
   * admin can execute function 
   * @param _owner is whomever on the receiving the minted NFTs
   * @param _quantity refers to the total number of minted NFTs in single transaction
   */
  function adminMint(address _owner, uint256 _quantity)
    public
    onlyAdmin
    nonReentrant
    callerIsUser
  {
   _safeMint(_owner,_quantity);
  }
}