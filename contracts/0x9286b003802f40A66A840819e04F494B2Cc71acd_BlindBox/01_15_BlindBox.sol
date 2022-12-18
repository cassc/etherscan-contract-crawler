// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract BlindBox is ERC721Upgradeable, OwnableUpgradeable, IERC721ReceiverUpgradeable {
    bytes32 public merkleRoot;
    string public cidURL;
    uint256 public nowPeriod; 

    struct EventInfo {
        uint256 period;
        uint256 startTokenId;
        uint256 nowTokenId;
        uint256 total;
        uint256 bought;
        uint256 price;
        uint256 purchase;
    }

    mapping (uint256 => EventInfo) public eventInfos;
    EventInfo[] public eventArray;

    function setEventInfo(uint256 _period, uint256 _startTokenId, uint256 _nowTokenId, uint256 _total, uint256 _bought, uint256 _price, uint256 _purchase) public checkAdmin
    {
        EventInfo memory o = EventInfo({
            period: _period,
            startTokenId: _startTokenId,
            nowTokenId: _nowTokenId,
            total: _total,
            bought: _bought,
            price: _price,
            purchase: _purchase
        });
        
        eventInfos[_period] = o;

        bool hasEvents = checkEvents(_period);
    
        if(hasEvents){
            for(uint256 i = 0; i < eventArray.length; i++){
                if(_period == eventArray[i].period){
                    eventArray[i] = o;
                }
            }
        }else{
            eventArray.push(o);
        }
    }

    function checkEvents(uint256 _period) public view returns (bool) 
    {
        bool result;

        for(uint256 i = 0; i < eventArray.length; i++){
            if(_period == eventArray[i].period){
                result = true;
                break;
            }
        }

        return result;
    }

    function setNowPeriod(uint256 _period) public checkAdmin 
    {
        nowPeriod = _period;
    }

    //
    struct Purchase
    {
        uint256 period;
        uint256 bought;
    }

    mapping(address => mapping(uint256 => uint256)) public purchases;

    mapping(address => bool) public admin;
    struct OwnerInfo
    {
        uint256 _tokenId;
        address _addr;
    }

    modifier checkAdmin()
    {
        require(admin[_msgSender()], "not admin");
        _;
    }

    event eventMultiDeposit(address indexed from_addr, uint256[] tokenIds);
    event eventMultiWithdraw(address indexed to, uint256[] tokenIds);

    function initialize() public initializer
    {
        __ERC721_init("BlindBox", "BlindBox");
        __Ownable_init();
    }

    function setAdmin(address _sender, bool _flag) public onlyOwner
    {
        admin[_sender] = _flag;
    }

    function approveForContract(address operator, bool _flag) public onlyOwner
    {
        _setApprovalForAll(address(this), operator, _flag);
    }

    function _baseURI() internal override view virtual returns (string memory)
    {
        return cidURL;
    }

    function setMerkleRoot(bytes32 _root) public checkAdmin
    {
        merkleRoot = _root;
    }

    function setCidURL(string memory _cidURL) public checkAdmin
    {
        cidURL = _cidURL;
    }

    function getAddressAllTokenId(address _address) public view returns (uint256[] memory)
    {
        uint256 count = balanceOf(_address);
        uint256[] memory result = new uint256[](count);
        uint256 index = 0;

        for(uint256 i = 0; i < eventArray.length; i++){
            for (uint256 j = eventArray[i].startTokenId; j <= eventArray[i].nowTokenId; j++) {
                if (_exists(j) && ownerOf(j) == _address) {
                    result[index] = j;
                    index ++;
                }
            }
        }

        return result;
    }

    function getMerkleLeaf(address _address) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(_address));
    }

    function checkMerkle(bytes32[] calldata _merkleProof, address _address) public view returns (bool)
    {
        return MerkleProof.verify(_merkleProof, merkleRoot, getMerkleLeaf(_address));
    }
    
    function singleMint(bytes32[] calldata _merkleProof) external payable
    {
        require(checkEvents(nowPeriod), "event no open");
        require(checkMerkle(_merkleProof, _msgSender()), "invalid merkle proof");
        require(eventInfos[nowPeriod].bought < eventInfos[nowPeriod].total, "Sold out");
        require(purchases[_msgSender()][nowPeriod] < eventInfos[nowPeriod].purchase, "purchase ceiling");
        require(msg.value >= eventInfos[nowPeriod].price, "value error");

        _safeMint(_msgSender(), eventInfos[nowPeriod].nowTokenId);
        
        eventInfos[nowPeriod].bought ++;
        eventInfos[nowPeriod].nowTokenId ++;
        
        for(uint256 i = 0; i < eventArray.length; i++){
            if(nowPeriod == eventArray[i].period){
                eventArray[i].bought ++;
                eventArray[i].nowTokenId ++;
            }
        }
        
        purchases[_msgSender()][nowPeriod] ++;
    }

    function extract(address payable _address) public checkAdmin
    {
        _address.transfer(address(this).balance);
    }

    function multiDeposit(uint256[] memory tokenIds) external
    {
        for (uint256 i = 0; i < tokenIds.length; i++)
        {
            safeTransferFrom(_msgSender(), address(this), tokenIds[i]);
        }

        emit eventMultiDeposit(_msgSender(), tokenIds);
    }

    function multiWithdraw(address to, uint256[] memory tokenIds) external checkAdmin
    {
        for (uint256 i = 0; i < tokenIds.length; i++)
        {
            safeTransferFrom(address(this), to, tokenIds[i]);
        }

        emit eventMultiWithdraw(to, tokenIds);
    }

    function mintFromMapping(OwnerInfo[] memory  _ownerInfo) external checkAdmin
    {
        for (uint256 i = 0; i < _ownerInfo.length; i++)
        {
            _safeMint(_ownerInfo[i]._addr, _ownerInfo[i]._tokenId);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }
}