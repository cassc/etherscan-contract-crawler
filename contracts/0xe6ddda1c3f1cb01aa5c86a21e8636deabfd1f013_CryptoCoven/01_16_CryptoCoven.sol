//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.0;

/*
.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。

                                                       s                                            _                                 
                         ..                           :8                                           u                                  
             .u    .    @L           .d``            .88           u.                       u.    88Nu.   u.                u.    u.  
      .    .d88B :@8c  9888i   .dL   @8Ne.   .u     :888ooo  ...ue888b           .    ...ue888b  '88888.o888c      .u     [email protected] [email protected]
 .udR88N  ="8888f8888r `Y888k:*888.  %8888:[email protected]  -*8888888  888R Y888r     .udR88N   888R Y888r  ^8888  8888   ud8888.  ^"8888""8888"
<888'888k   4888>'88"    888E  888I   `888I  888.   8888     888R I888>    <888'888k  888R I888>   8888  8888 :888'8888.   8888  888R 
9888 'Y"    4888> '      888E  888I    888I  888I   8888     888R I888>    9888 'Y"   888R I888>   8888  8888 d888 '88%"   8888  888R 
9888        4888>        888E  888I    888I  888I   8888     888R I888>    9888       888R I888>   8888  8888 8888.+"      8888  888R 
9888       .d888L .+     888E  888I  uW888L  888'  .8888Lu= u8888cJ888     9888      u8888cJ888   .8888b.888P 8888L        8888  888R 
?8888u../  ^"8888*"     x888N><888' '*88888Nu88P   ^%888*    "*888*P"      ?8888u../  "*888*P"     ^Y8888*""  '8888c. .+  "*88*" 8888"
 "8888P'      "Y"        "88"  888  ~ '88888F`       'Y"       'Y"          "8888P'     'Y"          `Y"       "88888%      ""   'Y"  
   "P'                         88F     888 ^                                  "P'                                "YP'                 
                              98"      *8E                                                                                            
                            ./"        '8>                                                                                            
                           ~`           "                                                                                             


.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CryptoCoven is ERC721Enumerable, IERC2981, Ownable {
    using Strings for uint256;

    string public verificationHash;

    string private baseURI;
    address private openSeaProxyRegistryAddress;

    uint256 public constant MAX_WITCHES_PER_WALLET = 3;
    uint256 public maxWitches;

    uint256 public constant PUBLIC_SALE_PRICE = 0.07 ether;
    bool public isPublicSaleActive;

    uint256 public COMMUNITY_SALE_PRICE = 0.05 ether;
    uint256 public maxCommunitySaleWitches;
    bytes32 private communitySaleMerkleRoot;
    bool public isCommunitySaleActive;

    uint256 public maxGiftedWitches;
    bytes32 private claimListMerkleRoot;
    uint256 private numGiftedWitches;

    mapping(address => bool) public claimed;

    constructor(
        address _openSeaProxyRegistryAddress,
        uint256 _maxWitches,
        uint256 _maxCommunitySaleWitches,
        uint256 _maxGiftedWitches
    ) ERC721("Crypto Coven", "WITCH") {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
        maxWitches = _maxWitches;
        maxCommunitySaleWitches = _maxCommunitySaleWitches;
        maxGiftedWitches = _maxGiftedWitches;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    function mint(uint256 numberOfTokens) external payable {
        uint256 ts = totalSupply();
        require(isPublicSaleActive, "Public sale is not open");
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_WITCHES_PER_WALLET,
            "Max witches already minted to this wallet"
        );
        require(
            ts + numberOfTokens <= maxWitches - maxGiftedWitches,
            "Not enough witches remaining to mint"
        );
        require(
            PUBLIC_SALE_PRICE * numberOfTokens <= msg.value,
            "Incorrect ETH value sent"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i + 1);
        }
    }

    function mintCommunitySale(
        uint8 numberOfTokens,
        bytes32[] calldata merkleProof
    ) external payable {
        uint256 ts = totalSupply();

        require(isCommunitySaleActive, "Community sale is not open");
        require(
            balanceOf(msg.sender) + numberOfTokens <= MAX_WITCHES_PER_WALLET,
            "Max witches already minted to this wallet"
        );
        require(
            ts + numberOfTokens <= maxCommunitySaleWitches,
            "Not enough witches remaining to mint"
        );
        require(
            COMMUNITY_SALE_PRICE * numberOfTokens <= msg.value,
            "Incorrect ETH value sent"
        );
        require(
            verify(
                communitySaleMerkleRoot,
                keccak256(abi.encodePacked(msg.sender)),
                merkleProof
            ),
            "Address does not exist in list"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i + 1);
        }
    }

    function claim(bytes32[] calldata merkleProof) external {
        uint256 ts = totalSupply();

        require(
            balanceOf(msg.sender) + 1 <= MAX_WITCHES_PER_WALLET,
            "Max witches already minted to this wallet"
        );
        require(
            numGiftedWitches + 1 <= maxGiftedWitches,
            "Not enough witches remaining to gift"
        );
        require(ts + 1 <= maxWitches, "Not enough witches remaining to mint");
        require(!claimed[msg.sender], "Witch already claimed by this wallet");
        require(
            verify(
                claimListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender)),
                merkleProof
            ),
            "Address does not exist in list"
        );

        _safeMint(msg.sender, ts + 1);

        claimed[msg.sender] = true;
        numGiftedWitches += 1;
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setVerificationHash(string memory _verificationHash)
        external
        onlyOwner
    {
        verificationHash = _verificationHash;
    }

    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    function setIsCommunitySaleActive(bool _isCommunitySaleActive)
        external
        onlyOwner
    {
        isCommunitySaleActive = _isCommunitySaleActive;
    }

    function setCommunityListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        communitySaleMerkleRoot = merkleRoot;
    }

    function setClaimListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        claimListMerkleRoot = merkleRoot;
    }

    function reserveForGifting(uint256 numToReserve) external onlyOwner {
        uint256 ts = totalSupply();
        require(
            numGiftedWitches + numToReserve <= maxGiftedWitches,
            "Not enough witches remaining to gift"
        );
        require(
            ts + numToReserve <= maxWitches,
            "Not enough witches remaining to mint"
        );

        for (uint256 i = 0; i < numToReserve; i++) {
            _safeMint(msg.sender, ts + i + 1);
        }

        numGiftedWitches += numToReserve;
    }

    function giftWitches(address[] calldata addresses) external onlyOwner {
        uint256 ts = totalSupply();
        uint256 numToGift = addresses.length;
        require(
            numGiftedWitches + numToGift <= maxGiftedWitches,
            "Not enough witches remaining to gift"
        );
        require(
            ts + numToGift <= maxWitches,
            "Not enough witches remaining to mint"
        );

        for (uint256 i = 0; i < numToGift; i++) {
            if (balanceOf(addresses[i]) < MAX_WITCHES_PER_WALLET) {
                _safeMint(addresses[i], ts + i + 1);
            }
        }

        numGiftedWitches += numToGift;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // ============ SUPPORTING FUNCTIONS ============

    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) private pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    // ============ FUNCTION OVERRIDES ============

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Override isApprovedForAll to allowlist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Get a reference to OpenSea's proxy registry contract by instantiating
        // the contract using the already existing address.
        ProxyRegistry proxyRegistry = ProxyRegistry(
            openSeaProxyRegistryAddress
        );
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");

        return (address(this), SafeMath.div(SafeMath.mul(salePrice, 5), 100));
    }
}

// These contract definitions are used to create a reference to the OpenSea
// ProxyRegistry contract by using the registry's address (see isApprovedForAll).
contract OwnableDelegateProxy {

}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}