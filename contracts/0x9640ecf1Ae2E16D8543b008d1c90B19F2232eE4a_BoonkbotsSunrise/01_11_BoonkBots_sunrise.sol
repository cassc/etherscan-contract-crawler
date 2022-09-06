pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract BoonkbotsSunrise is ERC721A, ERC2981, Ownable {

  //  ........................................
  //  .....4LL UR B00NKS 4R3 B3L0NG TO U5.....
  //  ........................................
  //  .............';'..';;'..,;,.............
  //  ...........'lxkxllkOOkllkOko,...........
  //  ...........lkxxxxxxxxxxxxxxOl...........
  //  ...........lo'............'dl...........
  //  ...........ld;'''''''''''';do...........
  //  ...........lOOOOOOOOOOOOOOO0o...........
  //  ...........l00O0000000000000o...........
  //  ....,ll:...o0000000000000000o...:oo;....
  //  ..,ok00Od,.:xdxxxxxxxxxxxxxxc.,xOK0Od;..
  //  .lO00000O:.';;;;;;;;;;;;;;;;'.:0KKKKK0l.
  //  .,oO000kl..o0000000000000000o.'lOKKK0d;.
  //  ...,:::'..lkKKKKKKKKKKKKKKKKkl..,:::;...
  //  ....,co;..;d0KKKKKKKKKKKKKK0d;..:ol,....
  //  ...olckd....;dxxxxkkkkkkkkd;....dOloo'..
  //  ..,kxoOd.....,::::::::::::;.....dOdkO,..
  //  ..,kxcc;....'kKKKKKKKKKKKXk,....;llkO,..
  //  ...;:;......,OXXXOl::lOXXXO,......;:;...
  //  ............,OXXXd....dXXNO,............
  //  ............'dkkkl....lOOOd'............
  //  ........................................

  using Strings for uint256;

  string _baseTokenURI;


  uint256 public RESERVE = 37;
  uint256 public MAX_SUPPLY = 1337;
  uint256 public PRICE_PRESALE = 0.048 ether;
  uint256 public PRICE_PUBLICSALE = 0.064 ether;
  uint256 public MAX_PER_WALLET_PRESALE = 1;
  address public BB_ADDRESS = 0x2083aBBE7a3Cbf3cC19F3C76DC7fD48eB6C50763;
  string public contractURI = "https://meta.boonkbots.xyz/sunrise/contract";

  bool public claim_period = false;
  bool public preSale_period = false;
  bool public publicSale_period = false;

  bytes32 public merkleRootBoonklist = 0x9d9e2fb53ad88e838b8522790a5ca344d43924c4398e55fed6c4870fbd29cafd;
  bytes32 public merkleRootMintlist = 0xcad5b715bb161fce8642f93532303847f9d68b052e6172ccda96c173b4700725;

  mapping(address => uint256) public _boonklistClaimed;
  mapping(address => uint256) public _mintlistClaimed;

  constructor(string memory baseURI) ERC721A("Boonkbots Sunrise", "BOONKSUN") {
    setBaseURI(baseURI);
  }

  modifier callerIsUser() {
      require(tx.origin == msg.sender, "Cannot be called by a contract");
      _;
  }

  function claim(uint256 _quantity, uint256 _totalAllowed, bytes32[] calldata _merkleProof) external callerIsUser {

    // is claim period active
    require( claim_period, "Free claim not active" );

    // does not exceed total supply
    uint256 _supply = totalSupply();
    require(_supply + _quantity <= MAX_SUPPLY - RESERVE, "Exceeds maximum B00NKB0TS supply" );

    // is address on the claimlist?
    bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _totalAllowed.toString()));
    require(MerkleProof.verify(_merkleProof, merkleRootBoonklist, _leaf), "Address not allowed to claim");

    // has address any mints left?
    require(_quantity + _boonklistClaimed[msg.sender] <= _totalAllowed, "Not enough claims left for this address");

    // increment count
    _boonklistClaimed[msg.sender] += _quantity;

    // mint
    _safeMint(msg.sender, _quantity);

  }


  function mintPresale(uint256 _quantity, bytes32[] calldata _merkleProof) external payable callerIsUser {

      // is presale period active
      require( preSale_period, "Presale not active" );

      // does not exceed total supply
      uint256 _supply = totalSupply();
      require(_supply + _quantity <= MAX_SUPPLY - RESERVE, "Exceeds maximum B00NKB0TS supply" );

      // is address on the mintlist?
      bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(_merkleProof, merkleRootMintlist, _leaf), "Address not allowed to mint");

      // has address any mints left?
      require(_quantity + _mintlistClaimed[msg.sender] <= MAX_PER_WALLET_PRESALE, "Not enough mints left for this address");

      // payed?
      require( msg.value == PRICE_PRESALE * _quantity, "Ether sent is not correct" );

      // mint
      _safeMint(msg.sender, _quantity);

      // increment count
      _mintlistClaimed[msg.sender] += _quantity;

  }

  function mint(uint256 _quantity) external payable callerIsUser {

      // is public sale period active
      require( publicSale_period, "Public sale not active" );

      // does not exceed total supply
      uint256 _supply = totalSupply();
      require(_supply + _quantity <= MAX_SUPPLY - RESERVE, "Exceeds maximum B00NKB0TS supply" );

      // payed?
      require( msg.value == PRICE_PUBLICSALE * _quantity, "Ether sent is not correct" );

      // mint
      _safeMint(msg.sender, _quantity);

  }

  function giveAway(address _to, uint256 _amount) external onlyOwner() {

      // exceeds reserve
      require( _amount <= RESERVE, "Exceeds reserved B00NKB0TS supply" );
      uint256 supply = totalSupply();

      // exceeds total suply
      require( supply + _amount <= MAX_SUPPLY, "Exceeds maximum B00NKB0TS supply" );

      // mint
      _safeMint(_to, _amount);

      // increment reserve
      RESERVE -= _amount;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }


  function setPricePresale(uint256 _pricePreSale) public onlyOwner {
      PRICE_PRESALE = _pricePreSale;
  }
  function setPricePublicSale(uint256 _pricePublicSale) public onlyOwner {
      PRICE_PUBLICSALE = _pricePublicSale;
  }
  function setBaseURI(string memory _baseURI) public onlyOwner {
      _baseTokenURI = _baseURI;
  }
  function setContractURI(string memory _contractURI) public onlyOwner {
      contractURI = _contractURI;
  }
  function setMerkleRootBoonklist(bytes32 _root) external onlyOwner {
    merkleRootBoonklist = _root;
  }
  function setMerkleRootMintlist(bytes32 _root) external onlyOwner {
    merkleRootMintlist = _root;
  }
  function setClaim(bool _val) external onlyOwner {
      claim_period = _val;
  }
  function setPreSale(bool _val) external onlyOwner {
      preSale_period = _val;
  }
  function setPublicSale(bool _val) external onlyOwner {
      publicSale_period = _val;
  }
  function setRoyaltyInfo(address payable receiver, uint96 numerator) public onlyOwner {
      _setDefaultRoyalty(receiver, numerator);
  }
  function setMaxPerWalletPresale(uint256 _maxPerWalletPreSale) public onlyOwner {
      MAX_PER_WALLET_PRESALE = _maxPerWalletPreSale;
  }



  function withdrawAll() external onlyOwner {
      uint256 _amount = address(this).balance;
      require(payable(BB_ADDRESS).send(_amount));
  }



  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {

      return
          ERC721A.supportsInterface(interfaceId) ||
          ERC2981.supportsInterface(interfaceId);
  }


}