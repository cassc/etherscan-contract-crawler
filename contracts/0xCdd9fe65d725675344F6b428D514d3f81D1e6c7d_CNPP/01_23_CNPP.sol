// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import { BitOpe } from 'bitope/contracts/libs/BitOpe.sol';
import "./libs/OperatorFilterer/UpdatableOperatorFilterer.sol";
import "./libs/OperatorFilterer/RevokableDefaultOperatorFilterer.sol";
import "./interface/ITokenURI.sol";
import "./interface/IContractAllowListProxy.sol";
import "./interface/ISBTwithMint.sol";

abstract contract CNPPcore is  Ownable{
    enum Phase {
        BeforeMint,
        WLMint,
        BurnMint
    }

    // Upgradable FullOnChain
    ITokenURI public tokenuri;
    IContractAllowListProxy public cal;

    address public stakeManage; //for only stake control

    address public constant WITHDRAW_ADDRESS = 0x664d4e1e7E0DEb51932985f0A727d4dFB09fB621;
    uint256 public constant MAX_SUPPLY = 7641;
    
    uint256 public maxBurnMint = 2000;
    uint256 public limitGroup;          //0 start
    uint256 public cost = 0.001 ether;
    string public baseURI;
    string public baseURI_lock;
    string public baseExtension = ".json";
    bool public revealed;   //initial:false
    string public notRevealedUri;
    bytes32 public merkleRoot;
    uint256 public wlcount;         // max:65535 Always raiseOrder
    uint256 public bmcount;         // max:65535 Always raiseOrder
    Phase public phase = Phase.BeforeMint;
    address public royaltyAddress = WITHDRAW_ADDRESS;
    uint96 public royaltyFee = 1000;    // default:10%
    uint256 public calLevel = 1;
    bool public isLocked;           //initial:false
    bool public isLockDisplay;      //initial:false

    // Bit management with uint256 for 30 groups of 256 divisions of 7641
    mapping(uint256 => uint256) public stakeInfo; //individual lock&stake

    bool public SBTwithMint;    //initial:false
    ISBTwithMint public sbtCollection;
    
    event StartStake(address indexed holder,uint256 indexed tokenId,uint256 startTime);
    event EndStake(address indexed holder,uint256 indexed tokenId,uint256 endTime);
}

abstract contract CNPPadmin is CNPPcore,AccessControl,ERC721AQueryable,ERC2981{
    using BitOpe for uint256;

    function supportsInterface(bytes4 interfaceId) public view virtual 
        override(AccessControl,IERC721A,ERC721A, ERC2981) returns (bool) {
        return
        interfaceId == type(IAccessControl).interfaceId ||
        interfaceId == type(IERC721A).interfaceId ||
        interfaceId == type(ERC2981).interfaceId ||
        super.supportsInterface(interfaceId);
    }
    
    // modifier
    modifier onlyAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    // onlyAdmin
    function setMaxBurnMint(uint256 _value) external onlyAdmin {
        maxBurnMint = _value;
    }

    function setCost(uint256 _value) external onlyAdmin {
        cost = _value;
    }

    function setBaseURI(string memory _newBaseURI) external onlyAdmin {
        baseURI = _newBaseURI;
    }

    function setBaseURI_lock(string memory _newBaseURI) external onlyAdmin {
        baseURI_lock = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyAdmin {
        baseExtension = _newBaseExtension;
    }

    function setRevealed(bool _value) external onlyAdmin{
        revealed = _value;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyAdmin {
        notRevealedUri = _notRevealedURI;
    }

    function setPhase(Phase _newPhase) external onlyAdmin {
        //0:BeroreMint > Always Stop Sale (1 -> 0 , 2 -> 0)
        //1:WLMint > Mint Start (0 -> 1)
        //2:BurnMint  > BurnMint Start (1 -> 2)
        phase = _newPhase;
    }

    function setLimitGroup(uint256 _value) external onlyAdmin{
        limitGroup = _value;
    }

    function incWlcount() external onlyAdmin {
        require( phase == Phase.BeforeMint,"out-of-scope phase that can be set");
        require( wlcount < 65535,"no Valid");
        unchecked {
            wlcount += 1;
        }
    }

    function incBMcount() external onlyAdmin {
        require( phase == Phase.BeforeMint,"out-of-scope phase that can be set");
        require( bmcount < 65535,"no Valid");
        unchecked {
            bmcount += 1;
        }
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyAdmin {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyAdmin {
        (bool os, ) = payable(WITHDRAW_ADDRESS).call{value: address(this).balance}("");
        require(os);
    }

    function setRoyaltyFee(uint96 _feeNumerator) external onlyAdmin {
        royaltyFee = _feeNumerator;         // set Default Royalty._feeNumerator 500 = 5% Royalty
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyAdmin {
        royaltyAddress = _royaltyAddress;   //Change the royalty address where royalty payouts are sent
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    function setTokenURI(ITokenURI _tokenuri) external onlyAdmin{
        tokenuri = _tokenuri;
    }

    function setStakeManage(address _stakemanage) external onlyAdmin{
        stakeManage = _stakemanage;
    }

    function setCalContract(IContractAllowListProxy _cal) external onlyAdmin{
        cal = _cal;
    }

    function setCalLevel(uint256 _value) external onlyAdmin{
        calLevel = _value;
    }

    function setIsLocked(bool _locked) external onlyAdmin{
        isLocked = _locked;
    }

    function setIsLockDisplay(bool _lockDisplay) external onlyAdmin{
        isLockDisplay = _lockDisplay;
    }

    function setSBTwithMint(bool _SBTwithMint) external onlyAdmin {
        SBTwithMint = _SBTwithMint;
    }

    function setSbtCollection(address _address) external onlyAdmin {
        sbtCollection = ISBTwithMint(_address);
    }

    function admin_mint(address[] calldata _airdropAddresses , uint256[] memory _UserMintAmount) external onlyAdmin{
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount + totalSupply() <= MAX_SUPPLY, "claim is over the max supply");
        require(_airdropAddresses.length ==  _UserMintAmount.length, "array length unmuch");

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i] );
        }
    }

    function _getStakeInfo(uint256 _tokenId) internal view returns(bool value){
        uint256 _group = _tokenId / 256;
        uint256 _index = (_tokenId % 256);
        return stakeInfo[_group].get256bit(_index);
    }

    function _setStakeInfo(uint256 _tokenId,bool _setValue) internal{
        uint256 _group = _tokenId / 256;
        uint256 _index = (_tokenId % 256);
        stakeInfo[_group] = stakeInfo[_group].set256bit(_index,_setValue);
    }

    // Stake Function 
    function _setStartStake(uint256 _tokenId) internal{
        require(_exists(_tokenId) == true,"not exists");
        require(_getStakeInfo(_tokenId) == false,"Already staked");
        _setStakeInfo(_tokenId,true);
        
        emit StartStake(ownerOf(_tokenId),_tokenId,block.timestamp);
    }
    
    function _setEndStake(uint256 _tokenId) internal {
        require(_exists(_tokenId) == true,"not exists");
        require(_getStakeInfo(_tokenId) == true,"Not staked");
        _setStakeInfo(_tokenId,false); 

        emit EndStake(ownerOf(_tokenId),_tokenId,block.timestamp);
    }

    function setStartStake_admin(uint256[] calldata _tokenIds) external onlyAdmin{
        for(uint256 i = 0; i < _tokenIds.length;i++){
            _setStartStake(_tokenIds[i]);
        }
    }

    function setEndStake_admin(uint256[] calldata _tokenIds)  external onlyAdmin {
        for(uint256 i = 0; i < _tokenIds.length;i++){
            _setEndStake(_tokenIds[i]);
        }
    }
}

contract CNPP is CNPPadmin,RevokableDefaultOperatorFilterer{
    using BitOpe for uint256;
    using BitOpe for uint64;

    constructor() ERC721A('CNP Philippines', 'CNPP') {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        _safeMint(0x664d4e1e7E0DEb51932985f0A727d4dFB09fB621, 1448);
        _safeMint(0xAb5060422c66dDA175a9931fCdF589E2A059D9FC, 500);

        _safeMint(0x083e6B4300A3e3c4e6d6e888E4cA158b3cb1812E, 50);
        _safeMint(0x6A1Ebf8f64aA793b4113E9D76864ea2264A5d482, 25);
        _safeMint(0xd63A3eD1B2a6776b031B56C6ba91c6fEEBaCfA1f, 15);
        _safeMint(0xe0aB5Bcf3E41De3598D9F41B95c708a16fDf6383, 15);
    }

    // overrides
    function setApprovalForAll(address operator, bool approved)
        public virtual override(IERC721A,ERC721A)
        onlyAllowedOperatorApproval(operator){
        if(address(cal) != address(0)){
            require(cal.isAllowed(operator,calLevel) == true,"address no list");
        }

        super.setApprovalForAll(operator,approved);
    }

    function approve(address to, uint256 tokenId)
        public virtual override(IERC721A,ERC721A)
        onlyAllowedOperatorApproval(to){
        if(address(cal) != address(0)){
            require(cal.isAllowed(to,calLevel) == true,"address no list");
        }

        if(isLocked == true){
            require(_getStakeInfo(tokenId) == false,"this tokenId is locked");
        }

        super.approve(to, tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address /*to*/,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal view override {
        // individual lock
        if(isLocked == true && from != address(0)){
            require(_getStakeInfo(startTokenId) == false,"this tokenId is locked");
        }
    }

    function _afterTokenTransfers(
        address from,
        address /*to*/,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal virtual override {
        if (from != address(0) && _getStakeInfo(startTokenId) == true) {
            // after transfer always unstake
            _setStakeInfo(startTokenId,false);
        }
    }

    // For OperatorFilter functions
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721A,ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(IERC721A,ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IERC721A,ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view virtual override (Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
   
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _tokenURI_lock(uint256 _tokenId) internal view returns (string memory) {
        if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI_lock).length != 0 ? string(abi.encodePacked(baseURI_lock, _toString(_tokenId))) : '';
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // aux->00..15:wl_count,16..31:wl_amount,32..47:burnmint_count,48..63:burnmint_amount
    function _resetWLCount(address _owner) internal{
        uint64 _auxval = _getAux(_owner);
        if(_auxval.get16_forAux(0) < wlcount){
            _setAux(_owner,_auxval.set16_forAux(0,uint64(wlcount)).set16_forAux(1,0));  // CountUp + Clear
        }
    }

    function _resetBMCount(address _owner) internal{
        uint64 _auxval = _getAux(_owner);
        if(_auxval.get16_forAux(2) < bmcount){
            _setAux(_owner,_auxval.set16_forAux(2,uint64(bmcount)).set16_forAux(3,0));  // CountUp + Clear
        }
    } 

    function _getAuxforWLAmount(address _owner) internal returns (uint64){
        _resetWLCount(_owner);
        return _getAux(_owner).get16_forAux(1);
    }

    function _getAuxforBMAmount(address _owner) internal returns (uint64){
        _resetBMCount(_owner);
        return _getAux(_owner).get16_forAux(3);
    }

    function _setAuxforWL(address _owner, uint64 _aux) internal {
        _resetWLCount(_owner);
        _setAux(_owner,_getAux(_owner).set16_forAux(1,_aux));
    }

    function _setWLmintedCount(address _owner,uint256 _mintAmount) internal{
        unchecked {
            _setAuxforWL(_owner,_getAuxforWLAmount(_owner) + uint64(_mintAmount));
        }
    }

    function _setAuxforBM(address _owner, uint64 _aux) internal{
        _resetBMCount(_owner);
        _setAux(_owner,_getAux(_owner).set16_forAux(3,_aux));
    }

    function _setBMmintedCount(address _owner,uint256 _mintAmount) internal{
        unchecked {
            _setAuxforBM(_owner,_getAuxforBMAmount(_owner) + uint64(_mintAmount));
        }
    }

    // public
    function tokenURI(uint256 tokenId) public view virtual override(IERC721A,ERC721A)  returns (string memory){
        if(revealed == false) {
            return notRevealedUri;
        }

        if(address(tokenuri) == address(0))
        {
            if(isLockDisplay == true && isLocked == true && _getStakeInfo(tokenId) == true){
                return string(abi.encodePacked(_tokenURI_lock(tokenId), baseExtension));
            }else{
                return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
            }
        }else{
            // Full-on chain support
            return tokenuri.tokenURI_future(tokenId,_getStakeInfo(tokenId));
        }
    }

    function getWLRemain(address _address,uint256 _wlAmountMax,uint256 _wlGroup,bytes32[] calldata _merkleProof)
    public view returns (uint256) {
        uint256 _Amount = 0;
        if(phase == Phase.WLMint){
            if(getWLExit(_address,_wlAmountMax,_wlGroup,_merkleProof) == true){
                if(_getAux(_address).get16_forAux(0) < wlcount){
                    _Amount = _wlAmountMax;
                }else{
                    _Amount = _wlAmountMax - _getAux(_address).get16_forAux(1);
                }
            } 
        }
        return _Amount;
    }

    function getBMRemain(address _address,uint256 _wlAmountMax,uint256 _wlGroup,bytes32[] calldata _merkleProof
    ) public view returns (uint256) {
        uint256 _Amount = 0;
        if(phase == Phase.BurnMint){
            if(getWLExit(_address,_wlAmountMax,_wlGroup,_merkleProof) == true){
                if(_getAux(_address).get16_forAux(2) < bmcount){
                    _Amount = _wlAmountMax;
                }else{
                    _Amount = _wlAmountMax - _getAux(_address).get16_forAux(3);
                }
            } 
        }
        return _Amount;
    }

    function getWLExit(address _address,uint256 _wlAmountMax,uint256 _wlGroup,bytes32[] calldata _merkleProof
    ) public view returns (bool) {
        bool _exit = false;
        bytes32 _leaf = keccak256(abi.encodePacked(_address,_wlAmountMax,_wlGroup));   

        if(MerkleProof.verifyCalldata(_merkleProof, merkleRoot, _leaf) == true){
            _exit = true;
        }

        return _exit;
    }

    // external
    function getTotalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function mint(uint256 _mintAmount,uint256 _wlAmountMax,uint256 _wlGroup,bytes32[] calldata _merkleProof)
        external payable {
        require(phase == Phase.WLMint,"sale is not active");
        require(_wlGroup <= limitGroup,"not target group");
        require(tx.origin == msg.sender,"the caller is another controler");
        require(getWLExit(msg.sender,_wlAmountMax,_wlGroup,_merkleProof) == true,"You don't have a whitelist!");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        _resetWLCount(msg.sender);  // Always check reset before getWLRemain
        require(_mintAmount <= getWLRemain(msg.sender,_wlAmountMax,_wlGroup,_merkleProof), "claim is over max amount");
        require(_mintAmount + totalSupply() <= MAX_SUPPLY, "claim is over the max supply");
        require(msg.value >= cost * _mintAmount, "not enough eth");

        if(SBTwithMint == true){
            if(sbtCollection.balanceOf(msg.sender) == 0){
                sbtCollection.externalMint(msg.sender,1);
            }
        }

        _setWLmintedCount(msg.sender, _mintAmount);
        _safeMint(msg.sender, _mintAmount);
    }

    function burnMint(uint256[] memory _burnTokenIds,uint256 _wlAmountMax,uint256 _wlGroup,bytes32[] calldata _merkleProof) 
        external payable{
        require(phase == Phase.BurnMint,"sale is not active");
        require(_wlGroup <= limitGroup,"not target group");
        require(tx.origin == msg.sender,"the caller is another controler");
        require(getWLExit(msg.sender,_wlAmountMax,_wlGroup,_merkleProof) == true,"You don't have a whitelist!");
        require(_burnTokenIds.length > 0, "need to mint at least 1 NFT");
        _resetBMCount(msg.sender);  // Always check reset before getBMRemain
        require(_burnTokenIds.length <= getBMRemain(msg.sender,_wlAmountMax,_wlGroup,_merkleProof), "claim is over max amount");
        require(_burnTokenIds.length + _totalBurned() <= maxBurnMint, "over total burn count");
        require(msg.value >= cost * _burnTokenIds.length, "not enough eth");
        
        _setBMmintedCount(msg.sender,_burnTokenIds.length);
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            uint256 tokenId = _burnTokenIds[i];
            require (msg.sender == ownerOf(tokenId));
            _burn(tokenId);
        }
        _safeMint(msg.sender, _burnTokenIds.length);
    }

    // Stake Function external
    function setStartStake(uint256[] calldata _tokenIds) external{
        require(msg.sender == stakeManage,"only specific control contract");
        for(uint256 i = 0; i < _tokenIds.length;i++){
            _setStartStake(_tokenIds[i]);
        }
    }
    
    function setEndStake(uint256[] calldata _tokenIds) external {
        require(msg.sender ==stakeManage,"only specific control contract");
        for(uint256 i = 0; i < _tokenIds.length;i++){
            _setEndStake(_tokenIds[i]);
        }
    }

    // get stake info (only view)
    function getStakeState(uint256 _tokenId)external view returns (bool){
        require(_exists(_tokenId) == true,"not exists");
        return _getStakeInfo(_tokenId);
    }

    function getStakeStateOfOwner(address _owner)external view returns (bool[] memory){
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(_owner);
            bool[] memory tokenIdLocked = new bool[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == _owner) {
                    bool setval = false;
                    if(_getStakeInfo(i) == true){
                        setval = true;
                    }
                    tokenIdLocked[tokenIdsIdx++] =  setval;
                }
            }
            return tokenIdLocked;
        }
    }
}