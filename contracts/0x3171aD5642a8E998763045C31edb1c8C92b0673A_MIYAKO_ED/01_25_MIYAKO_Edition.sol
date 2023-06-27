// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "hardhat/console.sol";
import { BitOpe } from "./BitOpe.sol";

contract MIYAKO_ED is ERC721AQueryable ,ERC2981 ,AccessControl , Ownable, DefaultOperatorFilterer {
    using Address for address;
    using Strings for uint256;
    using BitOpe for uint256;
    using BitOpe for uint64;

    uint256 public maxSupply    = 650;
    uint96  constant private DEFAULT_ROYALTYFEE = 1000; // 10%

    uint256 private price     = 0.1 ether;//presale price.
    uint256 constant private _max_mint_PER_TX   = 2;

    enum SaleState { NON, NOT/*1*/, FREE/*2*/ , PRE/*3*/ , FCFS/*4*/ , PUB /*5*/ , FIN /*6*/} // Enum
    uint256 constant private startMintState = uint256(SaleState.FREE);
    SaleState public saleState = SaleState.NOT;

    uint256 private MintedOwner;

    string private baseTokenURI;
    string constant private uriExt = ".json";

    bytes32 private merkleRoot;

    address internal constant TEAM_ADDRESS1 = address(0x1d1b1e30a9d15dBA662f85119122e1D651090434);
    bytes32 private constant TEAM_ROLE = keccak256("TEAM_ROLE");

    mapping(uint256 => uint256) private tokenHoldInfo;
    event Locked(uint256 tokenId);
    event Unlocked(uint256 tokenId);

    constructor() ERC721A("MIYAKO_EDITION", "MYKED") {
        _setDefaultRoyalty(msg.sender, DEFAULT_ROYALTYFEE);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TEAM_ROLE, TEAM_ADDRESS1);
        _setupRole(TEAM_ROLE, msg.sender);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(TEAM_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function getCurrentPrice() public view returns(uint256) {
        return _getCurrentPrice();
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
        require(saleState >= SaleState.FREE && saleState <= SaleState.FCFS , "Presale is not active.");

        uint256 supply = totalSupply();
        uint256 cost = _getCurrentPrice() * _amount;

        require(_amount > 0 && supply + _amount <= maxSupply, "Invalid mint amount!");
        require(msg.value >= cost, "ETH value is not correct");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _allowedMaxMint));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof"
        );

        require((uint256(_getAuxMinted(msg.sender)) + _amount) <= _getMaxMint(_allowedMaxMint), "Over max minted");

        _setMintTime(_nextTokenId());   
        _safeMint(msg.sender, _amount);
        
        _setMintedCount(msg.sender,_amount);
    }

    function publicMint(uint256 _amount) external 
    payable {
        require(saleState == SaleState.PUB , "Publicsale is not active.");

        uint256 supply = totalSupply();
        uint256 cost = price * _amount;

        require(_amount > 0 && supply + _amount <= maxSupply && _amount <= _max_mint_PER_TX, "Invalid mint amount!");
        require(msg.value >= cost, "ETH value is not correct");
        _setMintTime(_nextTokenId());
        _safeMint(msg.sender, _amount);
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
        return _isLock(tokenId) == 0 ? 
        string(abi.encodePacked(_baseURI(), tokenId.toString() ,uriExt)) :
        string(abi.encodePacked(_baseURI(), tokenId.toString(), "_Lock" ,uriExt));
    }

    function setLock(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender);
        require(_isLock(tokenId) == 0, "Already locked");
        _setLock(tokenId);
    }

    function setOptionlock(uint256 tokenId, bool lock) external onlyRole(TEAM_ROLE){
        if(lock){
            _setLockOp(tokenId);
        }else{
            _setUnlockOp(tokenId);
        }
    }

    function getTime(uint256 tokenId)external view returns(uint256){
        return _getLockTime(tokenId);
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function approve(address operator, uint256 tokenId) 
    public override(ERC721A,IERC721A) payable onlyAllowedOperatorApproval(operator) {
        require(_isLock(tokenId) == 0,"Token is Locked.");
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

    function _beforeTokenTransfers(
        address from,
        address /*to*/,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal virtual override {
        if (from != address(0)) { 
            require(_isLock(startTokenId) == 0,"Token is Locked.");
        }
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override (IERC721A,ERC721A,ERC2981,AccessControl) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function _getCurrentPrice() view internal returns(uint256){
        if(saleState == SaleState.FREE){
            return 0 ether;
        }else{
            return price;
        }
    }

    //255-192 minttime , 191-128 locktime ,127-32 free, 31-16 LockFree, 15-0 Lock 
    function _setLock(uint256 tokenId) internal{
        unchecked {
            tokenHoldInfo[tokenId] = tokenHoldInfo[tokenId].set16(0,1).set64(3,block.timestamp);
        }
        emit Locked(tokenId);
    }
    // function _setLockFree(uint256 tokenId) internal{
    //     unchecked {
    //         tokenHoldInfo[tokenId] = tokenHoldInfo[tokenId].set16(1,1).set64(4,block.timestamp);
    //     }
    //     emit Locked(uint256 tokenId);
    // }
    function _setLockOp(uint256 tokenId) internal{
        unchecked {
            tokenHoldInfo[tokenId] = tokenHoldInfo[tokenId].set16(2,1).set16(0,0).set64(2,block.timestamp);
        }
        emit Locked(tokenId);
    }
    function _setUnlock(uint256 tokenId) internal{
        unchecked {
            tokenHoldInfo[tokenId] = tokenHoldInfo[tokenId].set16(0,0);
        }
        emit Unlocked( tokenId);
    }
    // function _setUnlockFree(uint256 tokenId) internal{
    //     unchecked {
    //         tokenHoldInfo[tokenId] = tokenHoldInfo[tokenId].set16(1,0);
    //     }
    //     emit Unlocked(uint256 tokenId);
    // }
    function _setUnlockOp(uint256 tokenId) internal{
        unchecked {
            tokenHoldInfo[tokenId] = tokenHoldInfo[tokenId].set64(0,0);
        }
        emit Unlocked( tokenId);
    }
    function _isLock(uint256 tokenId) internal view returns (uint256){
        return uint256(tokenHoldInfo[tokenId].get16(0)) | uint256(tokenHoldInfo[tokenId].get16(2));
    }
    // function _isFreeLock(uint256 tokenId) internal view returns (uint256){
    //     return tokenHoldInfo[tokenId].get16(1);
    // }
    function _isOptionalLock(uint256 tokenId) internal view returns (uint256){
        return tokenHoldInfo[tokenId].get16(2);
    }
    function _setMintTime(uint256 tokenId)internal {
        tokenHoldInfo[tokenId] = tokenHoldInfo[tokenId].set64(3,block.timestamp);
    }
    function _getLockTime(uint256 tokenId)internal view returns(uint256){
        return tokenHoldInfo[tokenId].get64(2);
    }
    function _getMintTime(uint256 tokenId)internal view returns(uint256){
        return tokenHoldInfo[tokenId].get64(3);
    }

    function _getFreeMaxMint(uint256 _maxMint) internal pure returns (uint64){
        return uint64(_maxMint.get16(0));
    }
    function _getALMaxMint(uint256 _maxMint) internal pure returns (uint64){
        return uint64(_maxMint.get16(1));
    }
    function _getFcfsMaxMint(uint256 _maxMint) internal pure returns (uint64){
        return uint64(_maxMint.get16(2));
    }
    //MaxMint state
    function _getMaxMint(uint256 _maxMint) internal view returns (uint64){
        return uint64(_maxMint.get16(uint256(saleState) - startMintState));
    }
    //Aux state
    function _setMintedCount(address _owner,uint256 _mintAmount) internal{
        unchecked {
            _setAuxMinted(_owner,_getAuxMinted(_owner) + uint64(_mintAmount));
        }
    }
    function _getAuxMinted(address _owner) internal view returns (uint64) {
        return uint64(_getAux(_owner).get16_forAux(uint256(saleState) - startMintState));
    }
    function _setAuxMinted(address _owner, uint64 _aux) internal {
        _setAux(_owner,_getAux(_owner).set16_forAux(uint256(saleState) - startMintState,_aux));
    }

}