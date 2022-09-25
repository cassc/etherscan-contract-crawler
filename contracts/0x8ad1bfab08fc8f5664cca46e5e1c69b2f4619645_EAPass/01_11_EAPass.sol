// SPDX-License-Identifier: MIT

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//  $$\      $$\ $$\   $$\  $$$$$$\   $$$$$$\  $$$$$$$\  $$$$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\        $$\        $$$$$$\  $$$$$$$\   $$$$$$\    //
//  $$ | $\  $$ |$$ |  $$ |$$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$\       $$ |      $$  __$$\ $$  __$$\ $$  __$$\   //
//  $$ |$$$\ $$ |$$ |  $$ |$$ /  $$ |$$ /  $$ |$$ |  $$ |$$ |  $$ |$$ /  $$ |$$ /  $$ |$$ |  $$ |      $$ |      $$ /  $$ |$$ |  $$ |$$ /  \__|  //
//  $$ $$ $$\$$ |$$$$$$$$ |$$ |  $$ |$$ |  $$ |$$$$$$$  |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$$$$$$  |      $$ |      $$$$$$$$ |$$$$$$$\ |\$$$$$$\    //
//  $$$$  _$$$$ |$$  __$$ |$$ |  $$ |$$ |  $$ |$$  ____/ $$ |  $$ |$$ |  $$ |$$ |  $$ |$$  ____/       $$ |      $$  __$$ |$$  __$$\  \____$$\   //
//  $$$  / \$$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |            $$ |      $$ |  $$ |$$ |  $$ |$$\   $$ |  //
//  $$  /   \$$ |$$ |  $$ | $$$$$$  | $$$$$$  |$$ |      $$$$$$$  | $$$$$$  | $$$$$$  |$$ |            $$$$$$$$\ $$ |  $$ |$$$$$$$  |\$$$$$$  |  //
//  \__/     \__|\__|  \__| \______/  \______/ \__|      \_______/  \______/  \______/ \__|            \________|\__|  \__|\_______/  \______/   //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//    WhoopDoop Labs (https://whoopdoop.com)
//    Author: @GrizzlyDesign

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC721ABurnable.sol";
import "./MerkleProof.sol";
import "./Address.sol";

contract EAPass is ERC721AQueryable, ERC721ABurnable, Ownable {
    uint256 public constant MAX_SUPPLY = 300;
    uint256 public mintableSupply = MAX_SUPPLY;

    uint256 private maxMint = 1;

    bool public ogSaleActive = false;
    bool public regSaleActive = false;
    bool public revealed = false;

    bytes32 private ogMerkleRoot;
    bytes32 private regMerkleRoot;

    mapping(uint256 => mapping(address => uint256)) private mintCount;

    string private baseURI;
    string private unrevealedUri;
    string private baseExtension = ".json";

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initUnrevealedUri
    ) ERC721A(_name, _symbol) {
        baseURI = _initBaseURI;
        unrevealedUri = _initUnrevealedUri;
    }

    /**
     * @notice Toggle The OG Claim Period.
     */
    function toggleOgSale() external onlyOwner {
        ogSaleActive = !ogSaleActive;
    }

    modifier isOgSaleActive() {
        require(ogSaleActive, "OG Claim Not Active");
        _;
    }

    /**
     * @notice Toggle The Regular Claim Period.
     */
    function toggleRegSale() external onlyOwner {
        regSaleActive = !regSaleActive;
    }

    modifier isRegSaleActive() {
        require(regSaleActive, "Regular Claim Not Active");
        _;
    }

    modifier hasCorrectAmount(uint256 price, uint256 quantity) {
        require(msg.value >= price * quantity, "Insufficent Funds");
        _;
    }

    modifier withinMintableSupply(uint256 quantity) {
        require(
            _totalMinted() + quantity <= mintableSupply,
            "Surpasses Supply"
        );
        _;
    }

    /**
     * @notice Reveals The True Token URI
     */
    function reveal() public onlyOwner {
        revealed = true;
    }

    /**
     * @notice Set the merkle root for the OG list verification
     * @param _ogMerkleRoot - OG Merkle Root
     */
    function setOgMerkleRoot(bytes32 _ogMerkleRoot) external onlyOwner {
        ogMerkleRoot = _ogMerkleRoot;
    }

    /**
     * @notice Set the merkle root for the OG list verification
     * @param _regMerkleRoot - Regular Claim Merkle Root
     */
    function setRegMerkleRoot(bytes32 _regMerkleRoot) external onlyOwner {
        regMerkleRoot = _regMerkleRoot;
    }

    /**
     * @notice OG List Claim.
     * @param merkleProof - Proof To Verify OG List.
     */
    function claimOG(bytes32[] calldata merkleProof)
        public
        isOgSaleActive
        hasValidMerkleProof(merkleProof, ogMerkleRoot)
        withinMintableSupply(1)
    {
        uint256 netMinted = (mintCount[0][msg.sender] += 1);
        require((netMinted <= maxMint), "You have already claimed.");
        _mint(msg.sender, 1);
    }

    /**
     * @notice Regular List Claim.
     * @param merkleProof - Proof To Verify Regular List.
     */
    function claimReg(bytes32[] calldata merkleProof)
        public
        isRegSaleActive
        hasValidMerkleProof(merkleProof, regMerkleRoot)
        withinMintableSupply(1)
    {
        uint256 netMinted = (mintCount[0][msg.sender] += 1);
        require((netMinted <= maxMint), "You have already claimed.");
        _mint(msg.sender, 1);
    }

    modifier hasValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Merkle Proof Incorrect."
        );
        _;
    }

    /**
     * @notice Admin mint
     * @param recipient - The receiver of the NFT
     * @param quantity - The quantity to mint
     */
    function mintAdmin(address recipient, uint256 quantity)
        external
        onlyOwner
        withinMintableSupply(quantity)
    {
        _mint(recipient, quantity);
    }

    /**
     * @notice Allow adjustment of max mint
     * @param limit - Number of allowed mints per wallet.
     */
    function setMaxMint(uint256 limit) external onlyOwner {
        maxMint = limit;
    }

    /**
     * @notice Allow adjustment of mintable supply
     * @param supply - Mintable supply, limited to the maximum supply
     */
    function setMintableSupply(uint256 supply) external onlyOwner {
        require(
            supply >= _totalMinted() && supply <= MAX_SUPPLY,
            "Invalid Supply"
        );
        mintableSupply = supply;
    }

    /**
     * @notice Sets the base URI of the NFT
     * @param baseURI_ - The Base URI of the NFT
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Sets the Unrevealed URI of the NFT
     * @param _unrevealedURI - The Unrevealed URI of the NFT
     */
    function setUnrevealedURI(string memory _unrevealedURI) public onlyOwner {
        unrevealedUri = _unrevealedURI;
    }

    /**
     * @dev Returns the Base URI of the NFT
     */
    function _baseURI() internal view virtual override returns (string memory) {
        if (revealed == false) {
            return unrevealedUri;
        }
        return baseURI;
    }

    /**
     * @notice Returns The URI Of the Specified Token ID
     * @param tokenId - The ID Of The Token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (revealed == false) {
            return
                bytes(unrevealedUri).length != 0
                    ? string(
                        abi.encodePacked(
                            unrevealedUri,
                            _toString(tokenId),
                            baseExtension
                        )
                    )
                    : "";
        }

        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(baseURI, _toString(tokenId), baseExtension)
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    /**
     * @dev Returns the starting token ID.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Withdrawal of funds
     */

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}