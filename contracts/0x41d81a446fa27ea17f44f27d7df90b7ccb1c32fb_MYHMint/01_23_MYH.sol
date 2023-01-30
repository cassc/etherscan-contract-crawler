// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * *
 *  _           _   _           _   _           _              (_)            *
 * (_) _     _ (_) (_)_       _(_) (_)         (_)        _  (_) (_)  _       *
 * (_)(_)   (_)(_)   (_)_   _(_)   (_)         (_)      _(_)(_)   (_)(_)_     *
 * (_) (_)_(_) (_)     (_)_(_)     (_) _  _  _ (_)     (_)             (_)    *
 * (_)   (_)   (_)       (_)       (_)(_)(_)(_)(_)    (_)               (_)   *
 * (_)         (_)       (_)       (_)         (_)    (_)               (_)   *
 * (_)         (_)       (_)       (_)         (_)     (_)             (_)    *
 * (_)         (_)       (_)       (_)         (_)       (_)(_)(_)(_)(_)      *
 *                                                                            * 
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *  * */

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";

//import "./TeamAccess.sol";
import "./ITokenURIInterface.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "hardhat/console.sol";

contract MYHMint is ERC721AQueryable ,ERC2981 ,AccessControl , Ownable2Step, DefaultOperatorFilterer  {
    using Address for address;
    using Strings for uint256;

    uint256 public maxSupply    = 550;
    uint96  constant private DEFAULT_ROYALTYFEE = 1000; // 10%

    uint256 private price     = 0.01 ether;//presale price.

    enum SaleState { NON, NOT/*1*/, PRE/*2*/ , PRE2/*3*/ , WAIT /*4*/ , FIN /*5*/} // Enum
    SaleState public saleState = SaleState.NOT;

    uint256 private _maxMintOwner = 50;

    mapping(address => uint256) private _MintedAL;
    mapping(address => uint256) private _MintedWait;
    uint256 private MintedOwner;

    string private baseTokenURI;
    string constant private uriExt = ".json";

    bool private externalContractEn = false;
    ITokenURIInterface private tokenURIContract;

    uint256 private constant ADD_PRE2MINT = 1;
    bytes32 public merkleRoot;
    bytes32 public wait_merkleRoot;

    struct HoldStatus {
        uint256 startTime;
    }

    mapping(uint256 => HoldStatus) private holdStatus;
    uint256 private constant ONE_DAY = 1 days; // for production

    address internal constant TEAM_ADDRESS1 = address(0x1d1b1e30a9d15dBA662f85119122e1D651090434);

    bytes32 public constant TEAM_ROLE = keccak256("TEAM_ROLE");

    constructor() ERC721A("MocomocoYetiHomies", "MYH") {
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTYFEE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TEAM_ROLE, TEAM_ADDRESS1);
        _setupRole(TEAM_ROLE, msg.sender);
    }

    function setMerkleRoot(bytes32 _merkleRoot, bytes32 _waitMerkleRoot) external onlyRole(TEAM_ROLE) {
        merkleRoot = _merkleRoot;
        wait_merkleRoot = _waitMerkleRoot;
    }

    function getCurrentPrice() public view returns(uint256) {
        return price;
    }

    function setMaxSupply(uint256 _maxSupply) external virtual onlyOwner {
        require(totalSupply() <= _maxSupply);
        maxSupply = _maxSupply;
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
            require(_MintedAL[msg.sender] + _amount <= (_allowedMaxMint + ADD_PRE2MINT), "Over max minted");
        }else{
            require(_MintedAL[msg.sender] + _amount <= _allowedMaxMint, "Over max minted");
        }

        _safeMint(msg.sender, _amount);
        _MintedAL[msg.sender]+=_amount;
    }

    function waitMint(uint256 _amount ,uint256 _allowedMaxMint ,bytes32[] calldata _merkleProof) external 
    payable {
        require(saleState == SaleState.WAIT, "Waitlist Sale is not active.");

        uint256 supply = totalSupply();
        uint256 cost = price * _amount;

        require(_amount > 0 && supply + _amount <= maxSupply, "Invalid mint amount!");
        require(msg.value >= cost, "ETH value is not correct");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _allowedMaxMint));
        require(
            MerkleProof.verify(_merkleProof, wait_merkleRoot, leaf),
            "Invalid Merkle Proof"
        );
        
        require(_MintedWait[msg.sender] + _amount <= _allowedMaxMint, "Over max minted");

        _safeMint(msg.sender, _amount);
        _MintedWait[msg.sender]+=_amount;
    }

    function ownerMint(address _transferAddress, uint256 _amount) external onlyOwner {
        require(_maxMintOwner >= MintedOwner + _amount);
        _safeMint(_transferAddress, _amount);
        MintedOwner+=_amount;
    }

    function setOwnerMax(uint256 _max) external virtual onlyOwner {
        _maxMintOwner = _max;
    }

    function setNextSale() external virtual onlyRole(TEAM_ROLE) {
        require(saleState < SaleState.FIN);
        saleState = SaleState(uint256(saleState) + 1);
    }

    function setSaleState(uint256 _state) external virtual onlyRole(TEAM_ROLE) {
        //1:Not Sale, 2:Sale1, 3:Fin
        require(_state <= uint256(SaleState.FIN));
        saleState = SaleState(uint256(_state));
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A,IERC721A) returns (string memory){
        require( _exists(tokenId), "token does not exist" );
        return !externalContractEn ? 
        string(abi.encodePacked(_baseURI(), tokenId.toString() ,uriExt))
        : tokenURIContract.createTokenURI(tokenId);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function setRoyaltyFee(uint96 _fee ,address _royaltyAddress) external onlyOwner {
        _setDefaultRoyalty(_royaltyAddress, _fee);
    }

    function getHoldStatus(uint256 _tokenId) public view virtual returns (uint256){
        require( _exists(_tokenId));
        uint256 _holdDay = (block.timestamp - holdStatus[_tokenId].startTime) / ONE_DAY;
        return _holdDay;
    }

    function setExtContract(address _addr, bool _enable) external onlyOwner{
        tokenURIContract = ITokenURIInterface(_addr);
        externalContractEn = _enable;
    }

    function _beforeTokenTransfers(address from,address to,uint256 startTokenId,uint256 quantity) internal virtual override(ERC721A) {
        for(uint256 i = 0;i<quantity;i++)
        {
            HoldStatus storage HS = holdStatus[startTokenId + i];
            HS.startTime = block.timestamp;
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
    
    function setApprovalForAll(address operator, bool approved) 
    public override(ERC721A,IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) 
    public override(ERC721A,IERC721A) payable onlyAllowedOperatorApproval(operator) {
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
}