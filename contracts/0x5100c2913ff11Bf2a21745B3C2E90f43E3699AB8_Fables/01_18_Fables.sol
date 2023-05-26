// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./modules/Permission.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 
interface IFables2 {
    function mintBatch(address recipients,uint256  _amount) external;
    function balanceOf(address owner)external view returns(uint256);
    function addLevel(uint256 tokenId) external;
    function tokenOfOwnerByIndex(address recipients,uint256  _amount) external view returns(uint256);
    function whitelist(uint8 table, address add)external view returns(bool);
    function investor(address add)external view returns(uint256);
    function alreadymint(address add)external view returns(bool);
    function ownerOf(uint256 tokenId)external view returns(address);
}

contract Fables is
    Context,
    Permission,
    ERC721URIStorage,
    Ownable
{
    using Strings for uint256;
    uint private _tokenIdTracker;
    IFables2 private fables2Address = IFables2(0xFD7F90b4746d70281AAb4A4bBd64A6Dd29E5537D);
    mapping(uint8 => string) private _baseTokenURI;
    mapping(address => bool) public alreadymint;
    mapping(uint256 => uint8) public fablesLevel;
    mapping(uint8 => uint) public startTime;
    mapping(uint8 => uint) public endTime;
    mapping(uint8 => mapping(address => bool)) public whitelist;
    mapping(address => uint256) public investor;
    mapping(uint256 => bool) public isAirdrop;

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxBatchSize,
        uint256 collectionSize,
        string memory baseTokenURI
    ) ERC721A(name, symbol,  maxBatchSize, collectionSize) {
        _baseTokenURI[0] = baseTokenURI;
    }

    function getWhitelist(uint8 _table, address add)public view returns(bool) {
        return fables2Address.whitelist(_table, add);
    }

    function getInvestor(address add)public view returns(uint256) {
        return fables2Address.investor(add);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI(fablesLevel[tokenId]);
        return
        bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : "";
    }

    function setSellTime(uint8 _item, uint _start, uint _end) external onlyRole(MANAGER_ROLE){
        startTime[_item] = _start;
        endTime[_item] = _end;
    }


    function setWhitelist(uint8 _table, address[] memory setAmount )external onlyRole(MANAGER_ROLE){
        for(uint16 i = 0; i < setAmount.length; i ++){
            whitelist[_table][setAmount[i]] = true;
        }
    }

    function mintBatch(
        address recipients,
        uint256  _amount
    ) public onlyRole(MINTER_ROLE){
        require(_tokenIdTracker + _amount <= 3000,"NFT is already limited");
        _tokenIdTracker = _tokenIdTracker + _amount;
        _safeMint(recipients, _amount);
    }

    function mint(address _send) public virtual  onlyRole(MINTER_ROLE){
        require(_tokenIdTracker + 1 <= 3000,"NFT is already limited");
        _tokenIdTracker = _tokenIdTracker + 1;
        _safeMint(_send, 1);
    }

    function airdrop(uint _start, uint _end)external onlyRole(MANAGER_ROLE){
        for(uint256 i = _start; i <= _end; i++){
            require(!isAirdrop[i],"You already airdrop!");
        }
        for(uint256 i = _start; i <= _end; i++){
            isAirdrop[i] = true;
            address ownerAmount = fables2Address.ownerOf(i);
            mint(ownerAmount);
        }
    }

    function isAlreadymint(address add)public view returns(bool){
        return fables2Address.alreadymint(add);
    }

    function mintBatchInvestor() external{
        uint256 _amount = getInvestor(msg.sender);
        require(_amount > 0,"You can not mint!");
        require(_tokenIdTracker + _amount <= 3000,"NFT is already limited");
        require(block.timestamp >= startTime[1] && block.timestamp < endTime[1], "It is not sellTime");
        require(!alreadymint[msg.sender] && !isAlreadymint(msg.sender),"You are already minted");
        _tokenIdTracker = _tokenIdTracker + _amount;
        // investor[msg.sender] = 0;
        alreadymint[msg.sender] = true;
        _safeMint(msg.sender, _amount);
    }

    function mintVIP() public virtual{
        require(!alreadymint[msg.sender] && !isAlreadymint(msg.sender),"You are already minted");
        require(block.timestamp >= startTime[1] && block.timestamp < endTime[1], "It is not sellTime");
        require(getWhitelist(1,msg.sender),"You are not VIP");
        require(_tokenIdTracker + 1 <= 3000,"NFT is already limited");
        alreadymint[msg.sender] = true;
        _tokenIdTracker = _tokenIdTracker + 1;
        _safeMint(msg.sender, 1);
    }

    function mintWhitelist() public virtual{
        require(!alreadymint[msg.sender] && !isAlreadymint(msg.sender),"You are already minted");
        require(block.timestamp >= startTime[2] && block.timestamp < endTime[2], "It is not sellTime");
        require(getWhitelist(2,msg.sender) || getWhitelist(1,msg.sender),"You are not whitelist or VIP");
        require(_tokenIdTracker + 1 <= 3000,"NFT is already limited");
        alreadymint[msg.sender] = true;
        _tokenIdTracker = _tokenIdTracker + 1;
        _safeMint(msg.sender, 1);
    }
    
    function mintPublic() public virtual{
        require(!alreadymint[msg.sender] && !isAlreadymint(msg.sender),"You are already minted");
        require(block.timestamp >= startTime[3] && block.timestamp < endTime[3], "It is not sellTime");
        require(_tokenIdTracker + 1 <= 3000,"NFT is already limited");
        alreadymint[msg.sender] = true;
        _tokenIdTracker = _tokenIdTracker + 1;
        _safeMint(msg.sender, 1);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function addLevel(uint256 tokenId) external onlyRole(MINTER_ROLE){
        fablesLevel[tokenId] = fablesLevel[tokenId] + 1;
    }

    function redLevel(uint256 tokenId) external onlyRole(MINTER_ROLE){
        require(fablesLevel[tokenId] >= 1,"Level is lowest!");
        fablesLevel[tokenId] = fablesLevel[tokenId] - 1;
    }

//only manager
    function setInvestor(address _investor, uint256 _amount) external onlyRole(MANAGER_ROLE){
        investor[_investor] = _amount;
    }

    function setBaseURI(string memory baseURI, uint8 _base) external onlyRole(MANAGER_ROLE){
        _baseTokenURI[_base] = baseURI;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyRole(MANAGER_ROLE){
        _setTokenURI(tokenId, _tokenURI);
    }

//overwrite
    function _baseURI(uint8 _base) internal view virtual returns (string memory) {
        return _baseTokenURI[_base];
    }

//other

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}