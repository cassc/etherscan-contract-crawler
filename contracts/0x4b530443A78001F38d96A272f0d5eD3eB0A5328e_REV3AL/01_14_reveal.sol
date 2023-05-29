// SPDX-License-Identifier: MIT

/*
██████╗░███████╗██╗░░░██╗██████╗░░█████╗░██╗░░░░░
██╔══██╗██╔════╝██║░░░██║╚════██╗██╔══██╗██║░░░░░
██████╔╝█████╗░░╚██╗░██╔╝░█████╔╝███████║██║░░░░░
██╔══██╗██╔══╝░░░╚████╔╝░░╚═══██╗██╔══██║██║░░░░░
██║░░██║███████╗░░╚██╔╝░░██████╔╝██║░░██║███████╗
╚═╝░░╚═╝╚══════╝░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝╚══════╝
*/


pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Address.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract REV3AL is ERC721A, Ownable, ReentrancyGuard {

uint256 public immutable maxSupply = 5500;
uint64  private immutable maxBatchSize = 50;

struct MintInfo {
    bytes32 Root;
    uint256 Price;
    uint64 Max;
    uint256 Supply;
    bool Paused;
}

mapping(uint64 => MintInfo) public MintList;
mapping(address => uint256) public MintHistory;
mapping(address => uint256) public OwnersHistory;

address[] public TeamList;
uint256[] public ShareList;
bool private teamListDone = false;
bool private isRevealed = false;

string public _baseTokenURI = "ipfs://QmP41vRaid59VccXgQ41WVGe753dZjRCdzWwNHY4pbgy5A/hidden.json";

constructor() ERC721A("REV3AL", "REV3AL") {
    MintList[1]  = MintInfo(0,0.02 ether,10,5500,false); // public
    MintList[2]  = MintInfo(0x37d29d8231c89e720507e567f12abaabf9bc8d262740e10b5c09d94230613a5e,0,3,600,false); // owners
}

function _onlySender() private view {
    require(msg.sender == tx.origin);
}

modifier onlySender {
    _onlySender();
    _;
}

function _revMint(address to, uint256 amount) internal {
    require((totalSupply() + amount) <= maxSupply, "Sold out!");
    _safeMint(to, amount);
}

function lowBulkMint(address to,uint256 amount) external onlyOwner {
    _revMint(to,amount);
}

function bulkMint(uint256 amount) external onlyOwner {
    require((totalSupply() + amount) <= maxSupply, "Sold out!");
    require(amount % maxBatchSize == 0,"Can only mint a multiple of the maxBatchSize");
    uint256 numChunks = amount / maxBatchSize;
    numChunks = numChunks == 0 ? amount : numChunks;
    for (uint256 i = 0; i < numChunks; i++) {
        _safeMint(msg.sender, maxBatchSize);
    }
}

function isAddressMinter(bytes32[] memory proof, bytes32 _leaf) public view returns (bool)
{
    return checkMerkleRoot(MintList[2].Root, proof, _leaf);
}

function checkMerkleRoot(bytes32 merkleRoot,bytes32[] memory proof,bytes32 _leaf) internal pure returns (bool) {
    return MerkleProof.verify(proof,merkleRoot, _leaf);
}

function setPrices(uint256 _publicPrice,uint256 _ownerPrice) external onlyOwner{
    MintList[1].Price = _publicPrice;
    MintList[2].Price = _ownerPrice;
}

function setRevealed(bool _revealed) external onlyOwner {
    isRevealed = _revealed;
}

function setOptions(bool _publicSaleStatus,bytes32 _ownerRoot) external onlyOwner {
    MintList[1].Paused = _publicSaleStatus;
    MintList[2].Root = _ownerRoot;
}

function setTeamData(address[] calldata _teamAddressList, uint256[] calldata _shareList) external onlyOwner {
    require(!teamListDone);
    require(_teamAddressList.length == _shareList.length, "Address & Share list not equal length..");
    delete TeamList;
    delete ShareList;

    for(uint256 i = 0;i < _teamAddressList.length;i++)
    {
        TeamList.push(_teamAddressList[i]);
        ShareList.push(_shareList[i]);
    }

    teamListDone = true;
}

function OwnerMint(bytes32[] memory proof, uint256 amount) external payable onlySender nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(isAddressMinter(proof,leaf),"You are not eligible for an owner mint");
    require(OwnersHistory[msg.sender] + amount <= MintList[2].Max,"Minting amount exceeds allowance per wallet");
    MintList[2].Supply = MintList[2].Supply - amount;
    OwnersHistory[msg.sender] += amount;
    _revMint(msg.sender, amount);
}

function publicMint(uint256 amount) external payable onlySender nonReentrant {
    require(msg.value >= MintList[1].Price * amount , "Value is not correct");
    require(!MintList[1].Paused, "Public mint is paused");
    require(MintHistory[msg.sender] + amount <= MintList[1].Max,"Minting amount exceeds allowance per wallet");
    MintList[1].Supply = MintList[1].Supply - amount;
    MintHistory[msg.sender] += amount;
    _revMint(msg.sender, amount);
}

function withdraw() public onlyOwner nonReentrant
{
    uint256 total = address(this).balance;
    for(uint256 i = 0;i<TeamList.length;i++)
    {
        uint256 share = (total * ShareList[i])  / 1000;
        (bool success, ) = payable(TeamList[i]).call{value: share}("");
        require(success, "Transfer failed..");
    }
}

// as a protecting against network computing problems
function withdrawForVault() public onlyOwner nonReentrant
{
     uint256 total = address(this).balance;
     (bool success, ) =  payable(msg.sender).call{value: total}("");
     require(success, "Transfer failed..");
}

function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
}

function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
}

function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory)
{
    if(isRevealed)
    {
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId),".json"));
    }
    else
    {
    return  string(_baseTokenURI);
    }
}

function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
    uint256 _balance = balanceOf(address_);
    uint256[] memory _tokens = new uint256[] (_balance);
    uint256 _index;
    uint256 _loopThrough = totalSupply();
    for (uint256 i = 0; i < _loopThrough; i++) {
    bool _exists = _exists(i);
    if (_exists) {
    if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
    }
    else if (!_exists && _tokens[_balance - 1] == 0) { _loopThrough++; }
    }
    return _tokens;
}  

}