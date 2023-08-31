// SPDX-License-Identifier: Unlicensed

//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
//░░░░▓█▓▓▓███▒░░░░░▒░░▒▓▓▓▓▒░░░░░░░░░▒▓▒░░░░░░░▒░░░░░▒▓▓▒░░░░░░░░░░░░░░▒▒░░▒▓▓▓▓▒░░▒▒▓░░░░░
//░░░░▒▒▒██▓▒▒░██▒░▓█▓░██▒▒▓▒░░░░░░░░░▓██░██▒░░▓█▓░░███▓▓▒░░░░░▓█████░░░▓▓░▒██▓▓▓▒▒██▓▓▒░░░░
//░░░░░░░██▒░░░██▓░▓█▓░██░░░░░░░░░░░░░▓██░██▒░░▒██░██▓░░░░░░░░██▓░░░░░░░██▒▒██░░░░▓██░░░░░░░
//░░░░░░░██▒░░░██████▓░████▒░░░░░░░░░░▒██░▓█▒░░░██░██░▓█████▒▓██░░█████░██▒▒█████░░▓██░░░░░░
//░░░░░░░██▒░░░██▓░▓█▓░██▒░░░░░░░░██▒░▓██░▓█▓░░▓██░██▓▒▒▒▒██▒▒██░░░▒██▓░██▒░██░░░░░░▓██░░░░░
//░░░░░░░██▓░░░██▓░▓█▓░▓███▓░░░░░░▒█████▒░░██████▒░░███▓▓██▒░░▒██▓▓██▓░░▒█▒░▓████░░▓██▓░░░░░
//░░░░░░░▒▓▒░░░░░░░░░░░░░▒▒▒░░░░░░░░▓▓▒░░░░░░▒▒▒░░░░░░▒▓▒▒░░░░░░▒▒▒▒░░░░░░░░░░░░░░░▓▒░░░░░░░
//░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

pragma solidity >=0.8.17 <0.9.0;

contract TheJuggiesOG is
    ERC721A,
    Ownable,
    RevokableDefaultOperatorFilterer,
    ReentrancyGuard,
    ERC2981
{
    using Strings for uint256;

    //base url for metadata
    string _baseTokenURI;
    //mint price
    uint256 public cost = 0 ether;
    //maximum supply of the collection
    uint256 public maxSupply = 5000;
    //metadata is revealed or not
    bool public isRevealed = false;
    //merkle root
    bytes32 public merkleRoot;
    //white list active or not
    bool public whiteListActive = true;
    //pause minting
    bool public paused = false;
    //max mintable amount
    uint256 public maxMintableAmount = 10;

    constructor(string memory baseURI) ERC721A("The Juggies OG", "JUGGIES") {
        _baseTokenURI = baseURI;

        // Set royalty receiver to the contract creator,
        // at 10% (default denominator is 1000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    /**
     * @dev change cost
     * @param _cost cost of the token
     */
    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    /**
     * @dev toggle white list
     */
    function toggleWhiteList() external onlyOwner {
        whiteListActive = !whiteListActive;
    }

    /**
     * @dev set max supply
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    //dev wallet mint
    function devMint(uint256 _amount) external onlyOwner {
        uint256 supply = _totalMinted();
        require(supply + _amount <= maxSupply, "Exceed maximum supply");
        _mint(msg.sender, _amount);
    }

    /**
     * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
     * returned an empty string for the baseURI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev setBaseURI
     * @param _uri base url for metadata
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        _baseTokenURI = _uri;
    }

    /**
     * @dev reveal metadata
     * @param _uri base url for metadata
     */
    function revealMetadata(string memory _uri) external onlyOwner {
        isRevealed = true;
        _baseTokenURI = _uri;
    }

    //toggle minting
    function toggleMinting() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev setMerkleRoot
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    //set max mintable amount
    function setMaxMintableAmount(
        uint256 _maxMintableAmount
    ) external onlyOwner {
        maxMintableAmount = _maxMintableAmount;
    }

    /**
     * @dev mint allows an user to mint 1 NFT each.
     * @param _proof merkle proof
     */
    function mint(bytes32[] memory _proof, uint256 _amount) external payable {
        if (paused) {
            revert("Minting is paused");
        }

        if (whiteListActive) {
            require(
                MerkleProof.verify(
                    _proof,
                    merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                "Wallet not whitelisted."
            );
        }

        uint256 supply = _totalMinted();
        require(supply + _amount <= maxSupply, "Exceed maximum supply");
        require(_amount <= maxMintableAmount, "Exceed maximum mintable amount");
        require(msg.value == cost, "Incorrect value sent");
        _mint(msg.sender, _amount);
    }

    /**
     * @dev Get token URI
     * @param tokenId ID of the token to retrieve
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();

        if (isRevealed)
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            Strings.toString(tokenId),
                            ".json"
                        )
                    )
                    : "";
        else {
            return
                bytes(currentBaseURI).length > 0
                    ? string(abi.encodePacked(currentBaseURI))
                    : "";
        }
    }

    function setRoyaltyInfo(
        address _receiver,
        uint96 _royaltyFeesInBips
    ) external onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function withdraw() public onlyOwner nonReentrant {
        //owner withdraw
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    // function to recieve eth sent externally
    event ethReceived(address, uint256);

    receive() external payable {
        emit ethReceived(msg.sender, msg.value);
    }

    // ================== Withdraw Function End=======================

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
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

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}