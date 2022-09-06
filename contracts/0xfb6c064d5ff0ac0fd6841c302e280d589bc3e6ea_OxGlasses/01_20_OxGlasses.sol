// SPDX-License-Identifier: MIT

/*
             
                  <>><<>><<>><<>><   <>><<>><<>><<>><     <>><<>><<>><<>><                                    <>><<>><<>><<>><
                <>><<>><<>><<>><       <>><<>><<>><<>><     <>><<>><<>><<>><                                <>><<>><<>><<>><  
              <>><<>><<>><<>><           <>><<>><<>><<>><     <>><<>><<>><<>><                            <>><<>><<>><<>><
            <>><<>><<>><<>><               <>><<>><<>><<>><     <>><<>><<>><<>><                        <>><<>><<>><<>><   
          <>><<>><<>><<>><                   <>><<>><<>><<>><     <>><<>><<>><<>><                    <>><<>><<>><<>><    
        <>><<>><<>><<>><                       <>><<>><<>><<>><     <>><<>><<>><<>><                <>><<>><<>><<>><  
      <>><<>><<>><<>><                           <>><<>><<>><<>><     <>><<>><<>><<>><            <>><<>><<>><<>><  
    <>><<>><<>><<>><                               <>><<>><<>><<>><     <>><<>><<>><<>><        <>><<>><<>><<>><      
  <>><<>><<>><<>><                                   <>><<>><<>><<>><     <>><<>><<>><<>><    <>><<>><<>><<>><  
<>><<>><<>><<>><                                       <>><<>><<>><<>><    <>><<>><<>><<>><  <>><<>><<>><<>><
  <>><<>><<>><<>><                                   <>><<>><<>><<>><     <>><<>><<>><<>><    <>><<>><<>><<>><
    <>><<>><<>><<>><                               <>><<>><<>><<>><     <>><<>><<>><<>><        <>><<>><<>><<>><
      <>><<>><<>><<>><                           <>><<>><<>><<>><     <>><<>><<>><<>><            <>><<>><<>><<>><
        <>><<>><<>><<>><                       <>><<>><<>><<>><     <>><<>><<>><<>><                <>><<>><<>><<>><
          <>><<>><<>><<>><                   <>><<>><<>><<>><     <>><<>><<>><<>><                    <>><<>><<>><<>><       
            <>><<>><<>><<>><               <>><<>><<>><<>><     <>><<>><<>><<>><                        <>><<>><<>><<>><
              <>><<>><<>><<>><           <>><<>><<>><<>><     <>><<>><<>><<>><                            <>><<>><<>><<>><
                <>><<>><<>><<>><       <>><<>><<>><<>><     <>><<>><<>><<>><                                <>><<>><<>><<>><
                  <>><<>><<>><<>><   <>><<>><<>><<>><     <>><<>><<>><<>><                                    <>><<>><<>><<>><       




// 0xGlasses by 0xDrip NFTs are governed by the following Terms and Conditions: https://www.0xdrip.io/terms


*/

pragma solidity ^0.8.0;

import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./lib/MerkleDistributorTokensPrice.sol";

contract OxGlasses is
    ERC721ABurnable,
    ERC2981,
    MerkleDistributorTokensPrice,
    ReentrancyGuard,
    AccessControl,
    Ownable
{
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT");
    uint256 public constant MAX_SUPPLY = 1111;
    uint256 public constant MAX_PUBLIC_MINT = 3;
    uint256 public constant MAX_RESERVE_SUPPLY = 111;
    uint256 public constant PRICE_PER_TOKEN = 0.25 ether;

    uint256 public reserveSupply = MAX_RESERVE_SUPPLY;
    string public provenance;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;
    bool public saleActive;

    constructor(address payable shareholderAddress_) ERC721A("0xGlasses by 0xDrip", "DRIP") {
        require(shareholderAddress_ != address(0));

        // set immutable variables
        shareholderAddress = shareholderAddress_;

        // setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SUPPORT_ROLE, msg.sender);
    }

    /**
     * @notice checks to see if amount of tokens to be minted would exceed the maximum supply allowed
     * @param numberOfTokens the number of tokens to be minted
     */
    modifier supplyAvailable(uint256 numberOfTokens) {
        require(_totalMinted() + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max tokens");
        _;
    }

    /**
     * @notice checks to see whether saleActive is true
     */
    modifier isPublicSaleActive() {
        require(saleActive, "Public sale is not active");
        _;
    }

    ////////////////
    // admin
    ////////////////
    /**
     * @notice reserves a number of tokens
     * @param numberOfTokens the number of tokens to be minted
     */
    function devMint(uint256 numberOfTokens)
        external
        onlyRole(SUPPORT_ROLE)
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        uint256 reserveSupplyRemaining = reserveSupply;
        require(reserveSupplyRemaining >= numberOfTokens, "Number would exceed max reserve supply");

        reserveSupply = reserveSupplyRemaining - numberOfTokens;
        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * @notice allows public sale minting
     * @param state the state of the public sale
     */
    function setSaleActive(bool state) external onlyRole(SUPPORT_ROLE) {
        saleActive = state;
    }

    ////////////////
    // allow list
    ////////////////
    /**
     * @notice allows minting from a list of clients
     * @param allowListActive the state of the allow list
     */
    function setAllowListActive(bool allowListActive) external onlyRole(SUPPORT_ROLE) {
        _setAllowListActive(allowListActive);
    }

    /**
     * @notice sets the merkle root for the allow list
     * @param merkleRoot the merkle root
     */
    function setAllowList(bytes32 merkleRoot) external onlyRole(SUPPORT_ROLE) {
        _setAllowList(merkleRoot);
    }

    ////////////////
    // tokens
    ////////////////
    /**
     * @notice sets the base uri for {_baseURI}
     * @param baseURI_ the base uri
     */
    function setBaseURI(string memory baseURI_) external onlyRole(SUPPORT_ROLE) {
        _baseURIextended = baseURI_;
    }

    /**
     * @notice See {ERC721-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @notice sets the provenance hash
     * @param provenance_ the provenance hash
     */
    function setProvenance(string memory provenance_) external onlyRole(SUPPORT_ROLE) {
        provenance = provenance_;
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     * @param interfaceId the interface id
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     * @param tokenId the token id to burn
     * @param approvalCheck check to see whether msg.sender is approved to burn the token
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual override {
        super._burn(tokenId, approvalCheck);
        _resetTokenRoyalty(tokenId);
    }

    ////////////////
    // public
    ////////////////
    /**
     * @notice returns the total minted tokens
     */
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @notice allow minting if the msg.sender is on the allow list
     * @param numberOfTokens the number of tokens to be minted
     * @param merkleProof the merkle proof for the msg.sender
     */
    function mintAllowList(
        uint256 numberOfTokens,
        uint256 totalTokenAmount,
        uint256 price,
        bytes32[] memory merkleProof
    )
        external
        payable
        isAllowListActive
        ableToClaim(msg.sender, totalTokenAmount, price, merkleProof)
        tokensAvailable(msg.sender, numberOfTokens, totalTokenAmount)
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        require((numberOfTokens * price) == msg.value, "Ether value sent is not correct");

        _setAllowListMinted(msg.sender, numberOfTokens);
        _safeMint(msg.sender, numberOfTokens);
    }

    /**
     * @notice allow public minting
     * @param numberOfTokens the number of tokens to be minted
     */
    function mint(uint256 numberOfTokens)
        external
        payable
        isPublicSaleActive
        supplyAvailable(numberOfTokens)
        nonReentrant
    {
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(numberOfTokens * PRICE_PER_TOKEN == msg.value, "Ether value sent is not correct");

        _safeMint(msg.sender, numberOfTokens);
    }

    ////////////////
    // royalty
    ////////////////
    /**
     * @notice See {ERC2981-_setDefaultRoyalty}.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(SUPPORT_ROLE) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @notice See {ERC2981-_deleteDefaultRoyalty}.
     */
    function deleteDefaultRoyalty() external onlyRole(SUPPORT_ROLE) {
        _deleteDefaultRoyalty();
    }

    /**
     * @notice See {ERC2981-_setTokenRoyalty}.
     */
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(SUPPORT_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice See {ERC2981-_resetTokenRoyalty}.
     */
    function resetTokenRoyalty(uint256 tokenId) external onlyRole(SUPPORT_ROLE) {
        _resetTokenRoyalty(tokenId);
    }

    ////////////////
    // withdraw
    ////////////////
    /**
     * @notice withdraws ether from the contract to the shareholder address
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = shareholderAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}