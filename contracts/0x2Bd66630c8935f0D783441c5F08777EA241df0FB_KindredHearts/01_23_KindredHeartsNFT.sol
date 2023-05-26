// SPDX-License-Identifier: MIT
// Ts/22
pragma solidity ^0.8.9;
import "./BasicNFT.sol";
import "./RevealVRF.sol";
import "./RoyaltyNFT.sol";
import "./VerifyNFT.sol";
import "./MintableNFT.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface Token {
    function approve(address _spender, uint256 _value)
        external
        returns (bool success);
}


//       _____           _____
//   ,ad8PPPP88b,     ,d88PPPP8ba,
//  d8P"      "Y8b, ,d8P"      "Y8b
// dP'           "8a8"           `Yd
// 8(              "              )8
// I8                             8I
//  Yb,                         ,dP
//   "8a,                     ,a8"
//     "8a,                 ,a8"
//       "Yba             adP"
//         `Y8a         a8P'
//           `88,     ,88'
//             "8b   d8"
//              "8b d8"
//               `888'
//                 "
// (On-chain random VRF Revealable)
//
contract KindredHearts is
    BasicNFT,
    RevealVRF,
    RoyaltyNFT,
    VerifiableNFT,
    MintableNFT
{
    constructor(
        address _vrfCoordinator,
        address _link,
        uint256 _vrfFee,
        bytes32 _keyHash
    )
        BasicNFT("Kindred Hearts NFT", "KHEARTSNFT", "")
        RevealVRF(_vrfCoordinator, _link, _vrfFee, _keyHash)
        VerifiableNFT()
        MintableNFT(block.timestamp) // phase 1 start
    {
        currentId += 1; // start at Token ID 1
        for (uint256 i = 0; i < 17; i++) {
          _safeMint(msg.sender, currentId);
          currentId += 1;
        }
    }

    /**
     * @dev update metadata link if not locked
     */
    function setBaseURI(string memory uri) public onlyOwner {
        require(!metadataLocked, "metadata is locked");
        _baseTokenURI = uri;
    }

    /**
     * @dev hash of input traits for generation
     */
    bytes32 public provenance = 0;

    /**
     * @dev set provenance hash (before traitseed is set)
     * For proving that the inputs don't change during reveal
     */
    function setProvenance(bytes32 provenanceHash) public onlyOwner {
        require(traitseed == 0, "already revealed");
        provenance = provenanceHash;
    }

    /**
     * @dev VRF generated trait seed, keccak256(seed,tokenId) for card trait seed
     */
    function getTraitSeed() public view override returns (bytes32) {
        return traitseed;
    }

    /**
     * @dev internal overrides
     */
    function _safeMint(address to, uint256 tokenId)
        internal
        override(ERC721, MintableNFT)
    {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev max supply limit
     */
    function supplyLimit() public pure returns (uint256) {
        return 7777;
    }

    function _supplyLimit()
        internal
        pure
        override(VerifiableNFT, MintableNFT)
        returns (uint256)
    {
        return supplyLimit();
    }

    /**
     * @dev internal overrides
     */
    function _msgSender()
        internal
        view
        override(Context)
        returns (address sender)
    {
        return msgSender();
    }

    /**
     * @dev lock metadata immutable
     */
    bool public metadataLocked;

    function lockMetadata() public onlyOwner {
        metadataLocked = true;
    }

    /**
     * @dev lock weights immutable
     */
    function lockWeights() public onlyOwner {
        _weightSet();
    }

    // Example collection metadata (not individual token metadata)
    // {
    //   "name": "OpenSea Creatures",
    //   "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
    //   "image": "https://openseacreatures.io/image.png",
    //   "external_link": "https://openseacreatures.io",
    //   "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
    //   "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
    // }

    string private contractURI_ = "";

    /**
     * @dev collection metadata
     */
    function contractURI() public view returns (string memory) {
        return contractURI_;
    }

    /**
     * @dev set collection metadata
     */
    function setcontractURI(string memory uri) public onlyOwner {
        contractURI_ = uri;
    }

    /**
     * @dev request randomness from VRF.
     * should be done only after sale is complete.
     */
    function doReveal() public onlyOwner {
        require(traitseed == 0, "trait seed already set");
        require(currentId == supplyLimit() + 1, "cant reveal until supply limit");
        _doReveal();
    }

    /**
    * @dev update vrf config if necessary
    */
    function updateVrfConfig(uint256 _linkFee, bytes32 _keyHash) public onlyOwner {
        _updateVrfConfig(_linkFee, _keyHash);
    }

    /**
     * @dev retrieve erc20
     */
    function ownerApprove(Token address_) public onlyOwner {
        address_.approve(owner(), type(uint256).max);
    }

    /**
     * @dev set royalties receiver
     */
    function setRoyaltiesReceiver(address addr) public onlyOwner {
        _setRoyaltiesReceiver(addr);
    }

    /**
     * @dev give user(s) additional mintpass(es)
     */
    function newmintpass(address[] memory to, uint256[] memory amount)
        public
        onlyOwner
    {
        _newmintpass(to, amount);
    }

    /**
     * @dev whitelist user (allow purchasing in phase 1 and 2)
     */
    function newwhitelist(address[] memory addresses) public onlyOwner {
        _newwhitelist(addresses);
    }

    /**
     * @dev (Veriable traits) final number of layers
     */
    function newWeights(uint256 numLayers_) public onlyOwner {
        _newWeights(numLayers_);
    }

    /**
     * @dev (Veriable traits) edit layer 'numLayer' weight, ex: layer 1 = [1,1,1,10]
     */
    function editWeight(uint256 numLayer_, uint256[] memory choices_)
        public
        onlyOwner
    {
        _editWeight(numLayer_, choices_);
    }

    /**
     * @dev set phase1 timestamp
     */
    function setPhase1(uint256 unixTimestamp) public onlyOwner {
        require(phase() < 2, "cant set phase 1 after phase 1");
        _setPhase1(unixTimestamp);
    }
    /**
     * @dev set phase2 timestamp
     */
    function setPhase2(uint256 unixTimestamp) public onlyOwner {
        require(phase() < 2, "cant set phase 2 after phase 2");
        _setPhase2(unixTimestamp);
    }

    /**
     * @dev set phase3 timestamp
     */
    function setPhase3(uint256 unixTimestamp) public onlyOwner {
        require(phase() < 3, "cant set phase 3 after phase 3");
        _setPhase3(unixTimestamp);
    }
    /**
     * @dev set phase4 timestamp
     */
    function setPhase4(uint256 unixTimestamp) public onlyOwner {
        require(phase() < 4, "cant set phase 4 after phase 4");
        _setPhase4(unixTimestamp);
    }

    /**
     * @dev withdraw sent ether
     */
    function withdrawEther(uint256 amount, address recv) public onlyOwner {
        (bool sent,) = payable(recv).call{value: amount}("");
        require(sent, "transfer failed");
    }

    /**
     * @dev what do
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BasicNFT, RoyaltyNFT)
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ierc165 interface
            interfaceId == type(IERC165).interfaceId || 
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}