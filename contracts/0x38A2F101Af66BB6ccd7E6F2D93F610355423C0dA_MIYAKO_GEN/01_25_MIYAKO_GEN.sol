// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *          __    __  __  __      ____    ____    __  __       *
 *  /'\_/`\ /\ \  /\ \/\ \/\ \    /\  _`\ /\  _`\ /\ \/\ \     *
 * /\      \\ `\`\\/'/\ \ \/'/'   \ \ \L\_\ \ \L\_\ \ `\\ \    *
 * \ \ \__\ \`\ `\ /'  \ \ , <     \ \ \L_L\ \  _\L\ \ , ` \   *
 *  \ \ \_/\ \ `\ \ \   \ \ \\`\    \ \ \/, \ \ \L\ \ \ \`\ \  *
 *   \ \_\\ \_\  \ \_\   \ \_\ \_\   \ \____/\ \____/\ \_\ \_\ *
 *    \/_/ \/_/   \/_/    \/_/\/_/    \/___/  \/___/  \/_/\/_/ *
 *                                                             *      
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//import "./TeamAccess.sol";
import "./ITokenInfo.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "hardhat/console.sol";

contract MIYAKO_GEN is ERC721AQueryable ,ERC2981 ,AccessControl , Ownable2Step, DefaultOperatorFilterer {
    using Address for address;
    using Strings for uint256;

    uint256 public maxSupply    = 2000;
    uint96  constant private DEFAULT_ROYALTYFEE = 1000; // 10%

    uint256 private price     = 0.03 ether;//presale price.

    enum SaleState { NON, NOT/*1*/, PRE/*2*/ , PRE2/*3*/ , FIN /*4*/} // Enum
    SaleState public saleState = SaleState.NOT;

    mapping(address => uint256) private _MintedAL;
    uint256 private MintedOwner;

    string private baseTokenURI;
    string constant private uriExt = ".json";

    uint256 private add_pre2mint = 1;
    bytes32 public merkleRoot;

    address internal constant TEAM_ADDRESS1 = address(0x1d1b1e30a9d15dBA662f85119122e1D651090434);

    bytes32 private constant TEAM_ROLE = keccak256("TEAM_ROLE");

    ITokenInfoInterface public tokenInfo;


    constructor() ERC721A("MIYAKO_GENESIS", "MYKGEN") {
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTYFEE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TEAM_ROLE, TEAM_ADDRESS1);
        _setupRole(TEAM_ROLE, msg.sender);
        
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(TEAM_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function getCurrentPrice() public view returns(uint256) {
        return price;
    }

    function setMaxSupply(uint256 _maxSupply ,uint256 _add_pre2mint) external virtual onlyOwner {
        require(totalSupply() <= _maxSupply);
        maxSupply = _maxSupply;
        add_pre2mint = _add_pre2mint;
    }

    function setBaseURI(string memory uri) external virtual onlyRole(TEAM_ROLE) {
        baseTokenURI = uri;
    }

    function _baseURI() internal view override
    returns (string memory) {
        return baseTokenURI;
    }

    //start from 1.djust for bueno.
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function preMint(uint256 _amount ,uint256 _allowedMaxMint ,bytes32[] calldata _merkleProof) external 
    payable {
        require(saleState == SaleState.PRE || saleState == SaleState.PRE2, "Presale is not active.");

        uint256 supply = totalSupply();
        uint256 cost = price * _amount;

        require(_amount > 0 && supply + _amount <= maxSupply, "Invalid mint amount!");
        require(msg.value >= cost, "ETH value is not correct");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _allowedMaxMint));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        if(saleState == SaleState.PRE2){
            require(_MintedAL[msg.sender] + _amount <= (_allowedMaxMint + add_pre2mint), "Over max minted");
        }else{
            require(_MintedAL[msg.sender] + _amount <= _allowedMaxMint, "Over max minted");
        }

        _safeMint(msg.sender, _amount);
        _MintedAL[msg.sender]+=_amount;
    }

    function ownerMint(address _transferAddress, uint256 _amount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _amount <= maxSupply);
        _safeMint(_transferAddress, _amount);
        MintedOwner+=_amount;
    }

    function setNextSale() external virtual onlyRole(TEAM_ROLE) {
        require(saleState < SaleState.FIN);
        saleState = SaleState(uint256(saleState) + 1);
    }

    function setSaleState(uint256 _state) external virtual onlyRole(TEAM_ROLE) {
        require(_state <= uint256(SaleState.FIN));
        saleState = SaleState(uint256(_state));
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A,IERC721A) returns (string memory){
        require( _exists(tokenId), "token does not exist" );
        return address(tokenInfo) == address(0) ? 
        string(abi.encodePacked(_baseURI(), tokenId.toString() ,uriExt)) : tokenInfo.createTokenURI(tokenId);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function setRoyaltyFee(uint96 _fee ,address _royaltyAddress) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _fee);
    }

    function setTokenInfoContract(address _addr) external onlyRole(TEAM_ROLE){
        tokenInfo = ITokenInfoInterface(_addr);
    }
    
    function setApprovalForAll(address operator, bool approved) 
    public override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator) {
        if (address(tokenInfo) != address(0)){
                tokenInfo.isPermitted(operator);
        }
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
    public override(ERC721A,IERC721A) payable onlyAllowedOperatorApproval(operator) {
        if (operator != address(0)  && address(tokenInfo) != address(0)) {
            tokenInfo.isLock(operator, tokenId);
        }
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) 
    public override(ERC721A,IERC721A) payable onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) 
    public override(ERC721A,IERC721A) payable onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A,IERC721A)
        payable 
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override (IERC721A,ERC721A,ERC2981,AccessControl) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal virtual override {
        if (from != address(0) && address(tokenInfo) != address(0)) {
            tokenInfo.isLock(to, startTokenId,  msg.sender);
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal virtual override {
        if (from != address(0) && address(tokenInfo) != address(0)) {
            tokenInfo.init(to, startTokenId);
        }
    }
}