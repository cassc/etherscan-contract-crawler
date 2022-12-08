// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface X721 {
    function safeTransferFrom(address,address,uint256) external ;
}

contract NftEscrow is
IERC721Receiver,
Initializable,
OwnableUpgradeable,
AccessControlUpgradeable,
UUPSUpgradeable
{
    struct EscrowToken{
        uint256 TokenId;
        uint256 StartTime;
    }

    mapping(address=>mapping(address =>EscrowToken[])) private tokens;//contract addr - user - tokenid
    mapping(address=>mapping(uint256 =>address)) private tokenOwner;//contract addr - tokenid - user
    mapping(address=>uint256) private tokenAmount;//contract addr - count
    mapping(address=>bool) private tokenAddr;
    address[] private tokenList;
    bool public checkFlag;
    bool public stakingPaused;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    event Stake( address tokenAddr, address from, uint256 tokenId);
    event UnStake( address tokenAddr, address from, uint256 tokenId);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        checkFlag = true;
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    function setCheckFlag(bool _flag) external onlyRole(UPGRADER_ROLE){
        checkFlag=_flag;
    }

    function setPaused(bool _paused) external onlyRole(UPGRADER_ROLE){
        stakingPaused=_paused;
    }

    function getTokenList() external view returns (address[] memory) {
        return tokenList;
    }

    function setToken(address addr) external onlyRole(UPGRADER_ROLE){
        require(!tokenAddr[addr],"token already in list");
        tokenList.push(addr);
        tokenAddr[addr] = true;
    }

    function removeToken(address addr)  external onlyRole(UPGRADER_ROLE){
        uint _len = tokenList.length;
        require(tokenAddr[addr],"token not found");
        for (uint i=0;i<_len;i++){
            if(addr == tokenList[i]){
                tokenList[i] = tokenList[_len-1];
                tokenList.pop();
                delete tokenAddr[addr];
                break;
            }
        }
    }

    function checkContractAddr(address _addr) internal view {
        if (checkFlag) require(tokenAddr[_addr] == true,"NftEscrow:contract not found");
    }

    function stake(address[] calldata _addr, uint256[] calldata _tokenId)
    external {
        require(!stakingPaused, "Staking is currently paused.");
        require(
            _addr.length == _tokenId.length  && _addr.length > 0,
            "NftEscrow: The two arrays are not equal in length"
        );
        uint256  _len = _addr.length;
        for (uint i=0;i<_len;i++){
            checkContractAddr(_addr[i]);
            X721(_addr[i]).safeTransferFrom( msg.sender,address(this),_tokenId[i]);
            tokens[_addr[i]][msg.sender].push(EscrowToken({StartTime:block.timestamp,TokenId:_tokenId[i]}));
            tokenOwner[_addr[i]][_tokenId[i]] = msg.sender;
            tokenAmount[_addr[i]]++;
            emit Stake(_addr[i],msg.sender,_tokenId[i]);
        }
    }

    function unStake(address[] calldata  _addr, uint256[] calldata  _tokenId) external{
        require(!stakingPaused, "Staking is currently paused.");
        require(
            _addr.length == _tokenId.length && _addr.length > 0,
            "NftEscrow: The two arrays are not equal in length"
        );

        uint256  addr_len = _addr.length;
        EscrowToken[] storage _ts ;
        for (uint i=0;i<addr_len;i++){
            _ts = tokens[_addr[i]][msg.sender];
            for (uint j=0;j<_ts.length;j++){
                if(_ts[j].TokenId == _tokenId[i]){
                    require(
                        tokenOwner[_addr[i]][_tokenId[i]] == msg.sender,
                        "NftEscrow: only owner can operate"
                    );
                    checkContractAddr(_addr[i]);
                    X721(_addr[i]).safeTransferFrom( address(this),msg.sender,_tokenId[i]);
                    _ts[j] = _ts[_ts.length-1];
                    _ts.pop();
                    delete tokenOwner[_addr[i]][_tokenId[i]];
                    tokenAmount[_addr[i]]--;
                    emit UnStake(_addr[i],msg.sender,_tokenId[i]);
                    break;
                }
            }
        }
    }

    function getUserTokens(address contractAddr, address userAddr) external view returns(EscrowToken[] memory){
        return  tokens[contractAddr][userAddr];
    }

    function getTokensArray(address contractAddr, address userAddr)
    external view returns(uint256[] memory tokenIds,uint256[]  memory times){
        uint256 len=tokens[contractAddr][userAddr].length;
        tokenIds = new uint256[](len);
        times = new uint256[](len);
        for(uint i = 0;i<len;i++){
            tokenIds[i] = tokens[contractAddr][userAddr][i].TokenId;
            times[i] = tokens[contractAddr][userAddr][i].StartTime;
        }
    }

    function getTokenAmount(address contractAddr) public view returns(uint256){
        return  tokenAmount[contractAddr];
    }

    function getStakeUser(address  _addr,uint256  _start,uint256  _count)
    external view returns(uint256[] memory tokenIds,address[] memory owners){
        require(
            _count > 0,
            "NftEscrow: count must gt 0"
        );
        uint256 len = getLen(_addr,_start,_count);
        tokenIds = new uint256[](len);
        owners = new address[](len);
        uint256 j=0;

        for (uint256 i=0;i<_count;i++){
            if(tokenOwner[_addr][_start+i] != address(0)){
                tokenIds[j]=_start+i;
                owners[j]=tokenOwner[_addr][_start+i];
                j++;
            }
        }
    }

    function getStakeUserAndTime(address  _addr,uint256  _start,uint256  _count)
    external view returns(uint256[] memory tokenIds,address[] memory owners,uint256[] memory times){
        require(
            _count > 0,
            "NftEscrow: count must gt 0"
        );
        uint256 len = getLen(_addr,_start,_count);
        tokenIds = new uint256[](len);
        owners = new address[](len);
        times = new uint256[](len);
        uint256 j=0;

        for (uint256 i=0;i<_count;i++){
            if(tokenOwner[_addr][_start+i] != address(0)){
                tokenIds[j]=_start+i;
                owners[j]=tokenOwner[_addr][_start+i];
                times[j] = getTime(_addr,_start+i,owners[j]);
                j++;
            }
        }
    }

    function getTime(address  contractAddr,uint256  _tokenId,address  userAddr) internal view returns (uint256 sTime) {
        uint256 len =tokens[contractAddr][userAddr].length;
        for (uint256 i=0;i<len;i++){
            if(tokens[contractAddr][userAddr][i].TokenId == _tokenId){
                sTime = tokens[contractAddr][userAddr][i].StartTime;
                break;
            }
        }
    }

    function getLen(address  _addr,uint256  _start,uint256  _count) internal view returns (uint256) {
        uint256 j=0;
        for (uint256 i=0;i<_count;i++){
            if(tokenOwner[_addr][_start+i] != address(0)){
                j++;
            }
        }
        return j;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function onERC721Received(
        address , address , uint256 , bytes calldata
    )
    public pure override returns(bytes4)
    {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(AccessControlUpgradeable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}