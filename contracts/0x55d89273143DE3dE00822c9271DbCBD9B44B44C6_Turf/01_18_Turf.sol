// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*********************************
    
       ▄▄▄▄▀ ▄   █▄▄▄▄ ▄████  
    ▀▀▀ █     █  █  ▄▀ █▀   ▀ 
        █  █   █ █▀▀▌  █▀▀    
       █   █   █ █  █  █      
      ▀    █▄ ▄█   █    █     
            ▀▀▀   ▀      ▀    
    
            Turf.NFT
              2022

*********************************/

contract Turf is ERC721A, Ownable, ReentrancyGuard {

    enum ReleaseMode{ CLOSED, FOUNDERS, PRE_SALE, OPEN, ENDED }
    ReleaseMode public currentMode;

    // How we track how many items were minted per address.
    mapping(address => uint256) private _mintedPerAddress;
    // Track if the given address has made a purchase while holding a Founders Pass.
    // That entitles them to a free mint, but can only be used once.
    mapping(address => uint256) private _founderPassRedeemed;

    mapping (uint256 => bool) public mysteryZones;

     // Used for the OpenSea free listing feature.
    address public openSeaProxyRegistryAddress;

    // All set via setWalletAddresses.
    address private _mAddress;
    address private _kAddress;
    address private _dAddress;
    address private _ogAddress;
    address private _turfAddress;

    // Our Merkle Roots: Needed for various list checking.
    // Set with corrosponding setter methods.
    bytes32 private _presaleMerkleRoot;
    bytes32 private _founderPassMerkleRoot;
    bytes32 private _staffPassMerkleRoot;

    bool private _hqMinted;
    bool private _isOpenSeaProxyActive = true;

    // Generally only allow this many NFTs per wallet address.
    uint256 private constant MAX_PER_ADDRESS = 3;

    // How many are we able to mint in total? Set in the constructor.
    uint256 public maxSupply;

    bool public mysteryZoneBaseURILocked;
    bool public baseTokenURILocked;
    uint256 public price;

    // Failsafe to make sure we don't give away to many. Set in the constructor.
    uint256 private maxFriendSupply;
    uint256 private friendMintCount; // How many have we given away so far?

    string public baseTokenURI;
    string public baseMysteryZoneTokenURI;

    // Simple Eth check, assuming no freebies.
    modifier requireCorrectEth(uint256 buildCount) {
      require(msg.value == price * buildCount, "Sent incorrect Ether");
      _;
    }

    /// @param buildCount The amount of items intended to be minted.
    /// @dev All of our validations that we check before a mint.
    modifier validateBuild(uint256 buildCount) {
      require(
          _mintedPerAddress[msg.sender] + buildCount <= MAX_PER_ADDRESS,
          "Exceeds wallet limit"
      );
      require(totalSupply() + buildCount <= maxSupply, "Would exceed max supply");
      _;
   }

    /// @dev Only allow pre-sale eligible actions to be taken at the right time (presale or general sale).
    modifier validatePreSaleAction() {
      require(currentMode == ReleaseMode.PRE_SALE || currentMode == ReleaseMode.OPEN, "Not presale time yet");
      _;
    }

    /// @dev Founders time?
    modifier validateFoundersAction() {
      require(currentMode == ReleaseMode.FOUNDERS, "Not founders time yet");
      _;
    }    

    /// @param baseTokenURI_ The starting baseTokenURI, we'll change this later to lock in the data on Arweave.
    /// @param maxSupply_ How many items are mintable?
    /// @param price_ Price per token
    /// @param maxFriendSupply_ A limit on how many we can give away
    /// @param openSeaProxyRegistryAddress_ The OpenSea proxy address, set at run time so we can easily swap between testnet and mainnet.
    /// @dev The constructor!
    constructor(
        string memory baseTokenURI_,
        uint256 maxSupply_,
        uint256 price_,
        uint256 maxFriendSupply_,
        address openSeaProxyRegistryAddress_)
        ERC721A("Turf", "TURF", 3)
    {
        maxSupply = maxSupply_;
        baseTokenURI = baseTokenURI_;
        price = price_;
        maxFriendSupply = maxFriendSupply_;
        openSeaProxyRegistryAddress = openSeaProxyRegistryAddress_;
    }

    /// @notice Returns whether or not you, the person calling this method, have minted with a Founders Pass.
    function founderPassClaimed(address a) external view returns (bool){
      return _founderPassRedeemed[a] == 1;
    }

    /**
    @param buildCount How many do you want to mint?
    @notice This is the public method people should use to mint X items, if you _do not_ care about Founders Passes.
    It doesn't check any lists, it's just a plain mint.
    */
    function generalBuild(uint buildCount) validateBuild(buildCount) requireCorrectEth(buildCount) nonReentrant external payable {
        require(currentMode == ReleaseMode.OPEN, "It's not go time yet.");
        mint(msg.sender, buildCount, true);
    }

    /// @param _merkleProof The proof generated by the front end, to see if you have a Founders Pass.
    /// @param buildCount How many are we minting?
    /// @notice The public minting method with support for checking a Merkle proof for your Founders Pass holding status, which may entitle you to a free item.
    function generalBuildWithPass(bytes32[] memory _merkleProof, uint buildCount) validateBuild(buildCount) nonReentrant external payable {
        require(currentMode == ReleaseMode.OPEN, "It's not go time yet.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        // The amount we're charging (e.g, the amount we're validating) will depend on
        // if we detected a Founder Pass match. If so we check for a lesser amount of eth.
        uint buildCountToCharge = buildCount;
        if(MerkleProof.verify(_merkleProof, _founderPassMerkleRoot, leaf)){
          if(_founderPassRedeemed[msg.sender] != 1){ // if the pass is NOT already used, mark it as used and let us use the free one.
            buildCountToCharge = buildCountToCharge - 1;
            _founderPassRedeemed[msg.sender] = 1;
          }
        }

        require(msg.value == price * buildCountToCharge, "Sent incorrect Ether");
        mint(msg.sender, buildCount, true);
    }

    /**
    @param merkleProof Your Merkle proof to check that you're on the presale list.
    @param foundersMerkleProof Proof for your presence on the Founders Pass list.
    @param buildCount Amount to mint.
    @notice This is the mint function called by folks before the general sale, assuming they're allow-listed.
    @dev We don't need to enforce any specific limits on number of presale units minted, since the allow list itself
    will limit participants, plus the limit of mints per address checked in `validateBuild`.
    */
    function preSaleBuild(bytes32[] memory merkleProof, bytes32[] memory foundersMerkleProof, uint buildCount) validateBuild(buildCount) validatePreSaleAction nonReentrant external payable {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(merkleProof, _presaleMerkleRoot, leaf), "Not on allowlist");

      // You can get your Founders Pass freebie during the presale, which is in another Merkle Tree.
      // The amount we're charging (e.g, the amount we're validating) will depend on
      // if we detected a Founder Pass match. If so we check for a lesser amount of eth.
      uint buildCountToCharge = buildCount;
      if(MerkleProof.verify(foundersMerkleProof, _founderPassMerkleRoot, leaf)){
        if(_founderPassRedeemed[msg.sender] != 1){ // if the pass is NOT already used, mark it as used and let us use the free one.
          buildCountToCharge = buildCountToCharge - 1;
          _founderPassRedeemed[msg.sender] = 1;
        }
      }

      require(msg.value == price * buildCountToCharge, "Sent incorrect Ether");
      mint(msg.sender, buildCount, true);
    }

    function foundersBuild(bytes32[] memory foundersMerkleProof, uint buildCount) validateBuild(buildCount) validateFoundersAction nonReentrant external payable {
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(MerkleProof.verify(foundersMerkleProof, _founderPassMerkleRoot, leaf), "Not a Founder");

      // You can get your Founders Pass freebie during the presale, which is in another Merkle Tree.
      // The amount we're charging (e.g, the amount we're validating) will depend on
      // if we detected a Founder Pass match. If so we check for a lesser amount of eth.
      uint buildCountToCharge = buildCount;

      if(_founderPassRedeemed[msg.sender] != 1){ // if the pass is NOT already used, mark it as used and let us use the free one.
        buildCountToCharge = buildCountToCharge - 1;
        _founderPassRedeemed[msg.sender] = 1;
      }

      require(msg.value == price * buildCountToCharge, "Sent incorrect Ether");

      mint(msg.sender, buildCount, true);

    }

    /// @dev This is purely for internal testing. Let's us verify a proof for the given sender against the Founders Pass Merkle Root.
    function verifyPresale(bytes32[] memory _merkleProof, address sender) view external onlyOwner returns (bool) {
      bytes32 leaf = keccak256(abi.encodePacked(sender));
      return MerkleProof.verify(_merkleProof, _founderPassMerkleRoot, leaf);
    }

    function setMysteryZones(uint[] memory ids) external onlyOwner {
      for (uint i=0; i < ids.length; i++) {
        mysteryZones[ids[i]] = true;
      }
    }

    function hqBuild() external onlyOwner {
      require(!_hqMinted, "HQ already minted");
      mint(_mAddress, 1, true);
      _hqMinted = true;
    }

    function powerPlantBuild(address a, uint256 count) external onlyOwner {
      require(_hqMinted, "Only do this after HQ mint");
      mint(a, count, false);
    }

    /// @dev Sets the various wallets for withdrawl.
    function setWalletAddresses(address m, address k, address d, address og, address t) external onlyOwner {
      _mAddress = m;
      _kAddress = k;
      _dAddress = d;
      _ogAddress = og;
      _turfAddress = t;
    }

    function getWalletAddresses() view external onlyOwner returns(address m, address k, address d, address og, address t){
      return (_mAddress, _kAddress, _dAddress, _ogAddress, _turfAddress);
    }

    function setFounderPassMerkleRoot(bytes32 merkRoot) external onlyOwner {
      _founderPassMerkleRoot = merkRoot;
    }

    function setPresaleMerkleRoot(bytes32 merkRoot) external onlyOwner {
      _presaleMerkleRoot = merkRoot;
    }

    function setStaffPassMerkleRoot(bytes32 merkRoot) external onlyOwner {
      _staffPassMerkleRoot = merkRoot;
    }

    function setMysteryZoneUri(string memory uri) external onlyOwner {
      require(!mysteryZoneBaseURILocked, "setMysteryZoneUri is locked");
      baseMysteryZoneTokenURI = uri;
    }

    /// @dev After we cut over to the permaweb base URI, lock it up so we can't change it back. This is a one-time operation! Don't mess it up!
    function lockBaseTokenURI() external onlyOwner {
      baseTokenURILocked = true;
    }

    function lockMysteryZoneBaseTokenURI() external onlyOwner {
      mysteryZoneBaseURILocked = true;
    }

    /// @param baseTokenURI_ The new baseTokenURI
    /// @dev Need this so we can set the new base URI for the cut over to permaweb.
    function setBaseURI(string memory baseTokenURI_) external onlyOwner {
        require(!baseTokenURILocked, "setBaseURI is locked");
        baseTokenURI = baseTokenURI_;
    }

    // Copy + pasted in the ERC721A in order to override.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = mysteryZones[tokenId] ? baseMysteryZoneTokenURI : baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), '.json')) : "";
    }

    /// @param recipients A list of addresses to be sent tokens
    /// @param countPerPerson How many to send to each given address
    /// @dev Our air dropper.
    function friendBuild(address[] memory recipients, uint countPerPerson) external nonReentrant onlyOwner {
      require(totalSupply() + (recipients.length * countPerPerson) <= maxSupply, "would exceed max supply");
      require(friendMintCount + (recipients.length * countPerPerson) <= maxFriendSupply, "would exceed max friend supply");
      for (uint i = 0; i < recipients.length; i++) {
        mint(recipients[i], countPerPerson, false);
        friendMintCount = friendMintCount + countPerPerson;
      }
    }

    /// @dev Set our current mode to FOUNDERS.
    function startFoundersSale() external onlyOwner {
      setSaleStatus(ReleaseMode.FOUNDERS);
    }

    /// @dev Set our current mode to PRE_SALE.
    function startPreSale() external onlyOwner {
      setSaleStatus(ReleaseMode.PRE_SALE);
    }

    /// @dev Set our current mode to OPEN, for the general sale.
    function startGeneralSale() external onlyOwner {
      setSaleStatus(ReleaseMode.OPEN);
    }

    /// @dev End the sale (ENDED)
    function endSale() external onlyOwner {
      setSaleStatus(ReleaseMode.ENDED);
    }

    /// @dev Sets the current state to the given status.
    function setSaleStatus(ReleaseMode newStatus) private onlyOwner {
      currentMode = newStatus;
    }

    /// @dev You know.
    function withdraw() external nonReentrant onlyOwner {
      // Some percentage magic:
      uint256 balance = address(this).balance;
      uint256 fivePercent = balance / 100 * 5;
      payable(_kAddress).transfer(fivePercent);
      payable(_dAddress).transfer(fivePercent);
      payable(_mAddress).transfer(fivePercent);
      uint256 ogPercent = balance / 400 * 7; // 1.75, this is just weird contorted math
      payable(_ogAddress).transfer(ogPercent);
      uint256 remaining = address(this).balance;
      payable(_turfAddress).transfer(remaining);
    }

    /// @param to Who are we minting for?
    /// @param countTowardsWalletLimit Allows us to indicate if this should count towards the "X NFTs per Wallet" limit, or if we bypass that.
    /// @dev Our internal mint method, that handles some universal book-keeping.
    function mint(address to, uint256 count, bool countTowardsWalletLimit) private {
        if(countTowardsWalletLimit){
          _mintedPerAddress[to] += count;
        }
        _safeMint(to, count);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (_isOpenSeaProxyActive && address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function setIsOpenSeaProxyActive(bool isOpenSeaProxyActive_) external onlyOwner {
      _isOpenSeaProxyActive = isOpenSeaProxyActive_;
    }

    /// @notice In case any wayward tokens make their way over.
    function withdrawTokens(IERC20 token) external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    // @dev Overriding to add support for Royalties
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) 
    {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

    /// @notice Royalties
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        return (_turfAddress, (salePrice * 5) / 100);
    }

    /// @dev Allow us to receive arbitrary ETH if sent directly. Mostly want this for test purposes.
    receive() external payable {}

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}