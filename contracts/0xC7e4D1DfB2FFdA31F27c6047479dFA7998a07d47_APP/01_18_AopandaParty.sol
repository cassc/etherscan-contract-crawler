// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import { BitOpe } from "./libs/BitOpe.sol";
import "./interface/ITokenURI.sol";
import "./interface/IContractAllowListProxy.sol";

abstract contract APPcore is  Ownable{
    enum Phase {
        BeforeMint,
        WLMint,
        BurnMint
    }

    // Upgradable FullOnChain
    ITokenURI public tokenuri;
    IContractAllowListProxy public cal;

    address public stakeManage; //for only stake control

    address public constant WITHDRAW_ADDRESS = 0x62314D5A0F7CBed83Df49C53B9f2C687d2c18289;
    address public constant OWNER_ADDRESS = 0x5298D64d870b8B5a809a3f5eDF3395a13851f852;
    address public constant CONTRIBUTOR_ADDRESS_1 = 0x12D1BE4943B291623603f73367492D606c397996;
    address public constant CONTRIBUTOR_ADDRESS_2 = 0xF93d060E832F945E1e06a018d5AD0E0A1670fe8F;
    address public constant CONTRIBUTOR_ADDRESS_3 = 0x16C23163f10f9e8AA1497E017d2174129092653B;
    address public constant CONTRIBUTOR_ADDRESS_4 = 0x193Cc7EBe8B095f4517527D5B1852C0DDB3c1437;
    address public constant CONTRIBUTOR_ADDRESS_5 = 0x4C5396c9F28e75B8D5E6B711aee6048C78cDdF39;
    address public constant CONTRIBUTOR_ADDRESS_6 = 0x93186D61Bf098A1875069C3a6674c967C061275F;

    uint256 public constant MAX_SUPPLY = 10000;
    bytes32 internal constant ADMIN = keccak256("ADMIN");
    
    uint256 public maxBurnMint = 2000;
    uint256 public limitGroup;          //0 start
    uint256 public limitRelease = 1;    //LimitReleaseON>2
    uint256 public limitReleaseMaxAmount = 1;
    uint256 public cost = 0.001 ether;
    string public baseURI = "https://nft.aopanda.ainy-llc.com/site/app/metadata/";
    string public baseURI_lock = "https://nft.aopanda.ainy-llc.com/site/app_lock/metadata/";
    string public baseExtension = ".json";
    bytes32 public merkleRoot;
    uint256 public wlcount;         // max:65535 Always raiseOrder
    uint256 public bmcount;         // max:65535 Always raiseOrder
    Phase public phase = Phase.BeforeMint;
    address public royaltyAddress = WITHDRAW_ADDRESS;
    uint96 public royaltyFee = 1000;    // default:10%
    uint256 public calLevel = 1;
    bool public isLocked;           //initial:false
    bool public isLockDisplay;      //initial:false
    mapping(uint256 => uint256) public stakeInfo; //individual lock&stake
    
    event StartStake(uint256 indexed tokenId, address indexed holder,uint256 startTime);
    event EndStake(uint256 indexed tokenId, address indexed holder,uint256 startTime,uint256 endTime);
}

abstract contract APPadmin is APPcore,AccessControl,ERC721AQueryable,ERC2981{
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
        require(hasRole(ADMIN, msg.sender), "You are not authorized.");
        _;
    }

    // onlyOwner
    function setAdminRole(address[] memory admins) external onlyOwner{
        for (uint256 i = 0; i < admins.length; i++) {
            _grantRole(ADMIN, admins[i]);
        }
    }

    function revokeAdminRole(address[] memory admins) external onlyOwner{
        for (uint256 i = 0; i < admins.length; i++) {
            _revokeRole(ADMIN, admins[i]);
        }
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

    function setPhase(Phase _newPhase) external onlyAdmin {
        //0:BeroreMint > Always Stop Sale (1 -> 0 , 2 -> 0)
        //1:WLMint > Mint Start (0 -> 1)
        //2:BurnMint  > BurnMint Start (1 -> 2)
        phase = _newPhase;
    }

    function setLimitReleaseMaxAmount(uint256 _value) external onlyAdmin{
        limitReleaseMaxAmount = _value;
    }

    function setLimitRelease(uint256 _value) external onlyAdmin{
        limitRelease = _value;
    }

    function setLimitGroup(uint256 _value) external onlyAdmin{
        limitGroup = _value;
    }

    function setWlcount() external onlyAdmin {
        require( phase == Phase.BeforeMint,"out-of-scope phase that can be set");
        require( wlcount < 65535,"no Valid");
        unchecked {
            wlcount += 1;
        }
    }

    function setBMcount() external onlyAdmin {
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

    // Stake Function 
    function _setStartStake(uint256 _tokenId) internal{
        require(stakeInfo[_tokenId].get128(0) == 0,"Already staked");
        stakeInfo[_tokenId] = stakeInfo[_tokenId].set128(0,1).set128(1,block.timestamp);
        emit StartStake(_tokenId,ownerOf(_tokenId),block.timestamp);
    }
    
    function _setEndStake(uint256 _tokenId) internal {
        require(stakeInfo[_tokenId].get128(0) == 1,"Not staked");
        stakeInfo[_tokenId] = stakeInfo[_tokenId].set128(0,0);
        emit EndStake(_tokenId,ownerOf(_tokenId),stakeInfo[_tokenId].get128(1),block.timestamp);
    }

    function setStartStake_admin(uint256[] calldata _tokenId) external onlyAdmin{
        for(uint256 i = 0; i < _tokenId.length;i++){
            _setStartStake(_tokenId[i]);
        }
    }

    function setEndStake_admin(uint256[] calldata _tokenId)  external onlyAdmin {
        for(uint256 i = 0; i < _tokenId.length;i++){
            _setEndStake(_tokenId[i]);
        }
    }
}

contract APP is APPadmin {
    using BitOpe for uint256;
    using BitOpe for uint64;

    constructor() ERC721A('Aopanda Party', 'APP') {
        _safeMint(OWNER_ADDRESS, 2000);
        _safeMint(CONTRIBUTOR_ADDRESS_1, 100);
        _safeMint(CONTRIBUTOR_ADDRESS_2, 100);
        _safeMint(CONTRIBUTOR_ADDRESS_3, 100);
        _safeMint(CONTRIBUTOR_ADDRESS_4, 100);
        _safeMint(CONTRIBUTOR_ADDRESS_5, 80);
        _safeMint(CONTRIBUTOR_ADDRESS_6, 80);
 
        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender);  // set owner as admin
    }

    // overrides
    function setApprovalForAll(address operator, bool approved) public virtual override(IERC721A,ERC721A) {
        if(address(cal) != address(0)){
            require(cal.isAllowed(operator,calLevel) == true,"address no list");
        }

        super.setApprovalForAll(operator,approved);
    }

    function approve(address to, uint256 tokenId) public virtual override(IERC721A,ERC721A){
        if(address(cal) != address(0)){
            require(cal.isAllowed(to,calLevel) == true,"address no list");
        }

        if(isLocked == true){
            require(stakeInfo[tokenId].get128(0) == 0,"this tokenId is locked");
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
            require(stakeInfo[startTokenId].get128(0) == 0,"this tokenId is locked");
        }

        // Reward Lock-up
        if(block.timestamp > 1682899200){   // UNIXTIME 2023.5.1 00:00
            return; // Lock-up completed
        }
        address[6] memory rewardaddress = [CONTRIBUTOR_ADDRESS_1,
                                           CONTRIBUTOR_ADDRESS_2,
                                           CONTRIBUTOR_ADDRESS_3,
                                           CONTRIBUTOR_ADDRESS_4,
                                           CONTRIBUTOR_ADDRESS_5,
                                           CONTRIBUTOR_ADDRESS_6];
        for(uint256 i = 0; i < rewardaddress.length; i++){
            require(from != rewardaddress[i],"Transfer is not possible during lockup.");
        }
    }

    function _afterTokenTransfers(
        address from,
        address /*to*/,
        uint256 startTokenId,
        uint256 /*quantity*/
    ) internal virtual override {
        if (from != address(0) && stakeInfo[startTokenId].get128(0) == 1) {
            // after transfer always unlock
            stakeInfo[startTokenId].set128(0,0);
        }
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
        if(address(tokenuri) == address(0))
        {
            if(isLockDisplay == true && isLocked == true && stakeInfo[tokenId].get128(0) == 1){
                return string(abi.encodePacked(_tokenURI_lock(tokenId), baseExtension));
            }else{
                return string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
            }
        }else{
            // Full-on chain support
            return tokenuri.tokenURI_future(tokenId,stakeInfo[tokenId].get128(0));
        }
    }

    function getWLRemain(address _address,uint256 _wlAmountMax,uint256 _wlGroup,bytes32[] calldata _merkleProof)
    public view returns (uint256) {
        uint256 _Amount = 0;
        if(phase == Phase.WLMint){
            if(getWLExit(_address,_wlAmountMax,_wlGroup,_merkleProof) == true){
                if(limitRelease == 1){
                    if(_getAux(_address).get16_forAux(0) < wlcount){
                        _Amount = _wlAmountMax;
                    }else{
                        _Amount = _wlAmountMax - _getAux(_address).get16_forAux(1);
                    }
                }else{
                    if(_getAux(_address).get16_forAux(0) < wlcount){
                        _Amount = limitReleaseMaxAmount;
                    }else{
                        _Amount = limitReleaseMaxAmount - _getAux(_address).get16_forAux(1);    // After limit release
                    }
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
    function setStartStake(uint256 _tokenId) external{
        require(msg.sender == stakeManage,"only specific control contract");
        _setStartStake(_tokenId);
    }
    
    function setEndStake(uint256 _tokenId) external {
        require(msg.sender ==stakeManage,"only specific control contract");
        _setEndStake(_tokenId);
    }

    // get stake info (only view)
    function getStakeState(uint256 _tokenId,uint256 _info)external view returns (uint256){
        require(_exists(_tokenId) == true,"not exists");
        require(_info <= 1,"no Valid");
        return stakeInfo[_tokenId].get128(_info);
    }

    function getStakeStateOfOwner(address owner)external view returns (bool[] memory){
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
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
                if (currOwnershipAddr == owner) {
                    bool setval = false;
                    if(stakeInfo[i].get128(0) == 1){
                        setval = true;
                    }
                    tokenIdLocked[tokenIdsIdx++] =  setval;
                }
            }
            return tokenIdLocked;
        }
    }

    function getStakeStartTimestamp(uint256 _tokenId) public view returns(uint256 stakedTimestamp){
        require(stakeInfo[_tokenId].get128(0) == 1,"Not staked");
        return stakeInfo[_tokenId].get128(1);
    }

    function getStakeStartTimestamp_array(uint256[] calldata _tokenId) external view returns(uint256[] memory stakedTimestamp){
        uint256[] memory tokenIdTimestamp = new uint256[](_tokenId.length);
        for(uint256 i = 0; i < _tokenId.length;i++){
            tokenIdTimestamp[i] = getStakeStartTimestamp(_tokenId[i]);
        }
        return tokenIdTimestamp;
    } 

    function getStakeTimestampTerm(uint256 _tokenId) public view returns(uint256 stakedTimestamp){
        require(stakeInfo[_tokenId].get128(0) == 1,"Not staked");
        require(block.timestamp > stakeInfo[_tokenId].get128(1),"timestamp is wrong");
        return block.timestamp - stakeInfo[_tokenId].get128(1);
    }

    function getStakeTimestampTerm_array(uint256[] calldata _tokenId) external view returns(uint256[] memory  stakedTimestamp){
        uint256[] memory tokenIdTimestamp = new uint256[](_tokenId.length);
        for(uint256 i = 0; i < _tokenId.length;i++){
            tokenIdTimestamp[i] = getStakeTimestampTerm(_tokenId[i]);
        }
        return tokenIdTimestamp;
    }
}