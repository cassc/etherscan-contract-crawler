// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./operator-filter-registry/DefaultOperatorFilterer.sol";
import "./StringUtils.sol";

// @@@@@@@@@@@(@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@
// @@@@@@@@@@////%@@@@@@@@@@@@@@@@@@@@@%////@@@@@@@@@
// @@@@@@@@@////////@@@@@@@@@@@@@@@@@////////@@@@@@@@
// @@@@@@@@#//////////@@@@@@@@@@@@@//////////@@@@@@@@
// @@@@@@@@/////////////@@@@@@@@@/////////////@@@@@@@
// @@@@@@@////////////////////////////////////#@@@@@@
// @@@@@@@/////////////////////////////////////@@@@@@
// @@@@@@@/////////////////////////////////////@@@@@@
// @@@@@@/////// //////////////////////* ///////@@@@@
// @@@@@////////.    ///////////////    *////////@@@@
// @@@@//////////      ,/////////.     .//////////@@@
// @@#/////////////////////////////////////////////@@
// @/////////////////////////////////////////////////
// @&///////////////////////////////////////////////@
// @@@@@@@#///////////////////////////////////#@@@@@@
// @@@@@@@@@@@&////////////, *////////////@@@@@@@@@@@
// @@@@@@@@@@@@@@@@///////////////////&@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@////////////%@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@%/////&@@@@@@@@@@@@@@@@@@@@@

error PublicSaleNotLive();
error WhitelistNotLive();
error ExceededLimit();
error NotEnoughTokensLeft();
error WrongEther();
error InvalidMerkle();

contract KitsudenFoxfone is
    ERC721A,
    Ownable,
    StringUtils,
    ERC2981,
    DefaultOperatorFilterer
{
    using Address for address;
    using MerkleProof for bytes32[];
    using Strings for uint256;

    bytes32 public merkleRoot;
    uint256 public maxMints = 5;
    uint256 public whiteListMaxMints = 1;
    uint256 public maxSupply = 6666;
    uint256 public mintRate = 0.03 ether;
    string public baseExtension = ".json";
    string public baseURI = "";
    string public baseHiddenUri =
        "https://kitsuden.infura-ipfs.io/ipfs/QmT7tsvigAix4AQvsfvHtJJV7U8JFYUu9MM3j4cESkVSPJ/";
    uint256 public mintPhase;
    bool public paused = false;
    bool public revealed = false;

    mapping(address => uint256) public whiteListUsedAddresses;
    mapping(address => uint256) public usedAddresses;

    //  ==========================================
    //  ========== FAIL SAFE STRATEGY ============
    //  ==========================================
    modifier unpaused() {
        require(!paused, "Paused");
        _;
    }

    constructor() ERC721A("KitsudenFoxFone", "KSDFF") {
        _setDefaultRoyalty(0x1C0C70453C5eD96c7C4EC2EA98c3A99Fc1Dd27EF, 700); // 7% * 10000
    }

    /**
     * @dev overrides contract supportInterface
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(_interfaceId) ||
            ERC2981.supportsInterface(_interfaceId);
    }

    function mint(uint256 quantity) external payable unpaused {
        // check if public sale is live
        if (mintPhase != 2) revert PublicSaleNotLive();

        // check if enough token balance
        if (totalSupply() + quantity > maxSupply) {
            revert NotEnoughTokensLeft();
        }

        // check for the value user pass is equal to the quantity and the mintRate
        if (mintRate * quantity != msg.value) {
            revert WrongEther();
        }

        // check for user mint limit
        if (quantity + usedAddresses[msg.sender] > maxMints) {
            revert ExceededLimit();
        }

        usedAddresses[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    /**
     * @dev a function that only allow whitelisted addresses to mint
     */
    function whiteListMint(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        unpaused
    {
        // check if white list sale is live
        if (mintPhase != 1) revert WhitelistNotLive();

        // check if the user is white listed.
        if (!isWhiteListed(msg.sender, proof)) revert InvalidMerkle();

        // check if enough token balance
        if (totalSupply() + quantity > maxSupply) {
            revert NotEnoughTokensLeft();
        }

        // check for the value user pass is equal to the quantity and the mintRate
        if (mintRate * quantity != msg.value) {
            revert WrongEther();
        }

        // cehck if user exceeded mint limit
        if (whiteListUsedAddresses[msg.sender] + quantity > whiteListMaxMints) {
            revert ExceededLimit();
        }

        whiteListUsedAddresses[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    /**
     * @dev a function that only allow owner to reserve nft for marketing/giveaway purpose
     */
    function reserveMint(uint256 quantity) public onlyOwner {
        if (totalSupply() + quantity > maxSupply) {
            revert NotEnoughTokensLeft();
        }

        _mint(msg.sender, quantity);
    }

    /**
     * @dev a function that check for user address and verify its proof
     */
    function isWhiteListed(address _account, bytes32[] calldata _proof)
        internal
        view
        returns (bool)
    {
        return _verify(leaf(_account), _proof);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "token does not exist!");
        if (revealed)
            return
                string(
                    abi.encodePacked(
                        baseURI,
                        _tokenId.toString(),
                        baseExtension
                    )
                );
        else {
            return
                string(
                    abi.encodePacked(
                        baseHiddenUri,
                        _tokenId.toString(),
                        baseExtension
                    )
                );
        }
    }

    function leaf(address _account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof)
        internal
        view
        returns (bool)
    {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //  ==========================================
    //  ======== OPERATOR FILTER OVERRIDES =======
    //  ==========================================

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //  ==========================================
    //  ============= MODIFY STATES ==============
    //  ==========================================

    /**
     * @dev a function to set white list merkle root
     */
    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    /**
     * @dev a function to set mint phase
     */
    function setMintPhase(uint256 _phase) external onlyOwner {
        mintPhase = _phase;
    }

    /**
     * @dev a function to toggle fail safe paused
     */
    function setTogglePaused() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev a function to setBaseURI only once, this to ensure that the tokenURI can't be meddle with!
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(bytes(_newBaseURI).length > 1, "_newBaseURI cannot be empty!");
        uint256 len = strLen(_newBaseURI);
        string memory char = substring(_newBaseURI, len - 1, len);

        require(
            compareStrings(char, "/"),
            "_newBaseURI should have a suffix of '/'"
        );
        require(!revealed, "You can only set baseURI once!");
        revealed = true;
        baseURI = _newBaseURI;
    }
}