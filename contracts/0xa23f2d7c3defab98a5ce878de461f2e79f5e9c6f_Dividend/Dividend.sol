/**
 *Submitted for verification at Etherscan.io on 2023-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external;
}

contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renouncedOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0x000000000000000000000000000000000000dEaD));
        _owner = address(0x000000000000000000000000000000000000dEaD);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IERC165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IDividend {

    function deposit() external payable;
}

// nft dividend

error NftNotFound();

contract Dividend is Ownable, ERC721Holder {

    using SafeMath for uint256;

    address public _distributor;

    IERC721 public nftAddress = IERC721(0x4De4410d84abd717eE25Bf0a345Ee9f7B13E54f7);

    struct Share {
        // uint256 amount;
        uint256 totalStaked;
        uint256 totalExcluded;
        uint256 totalRealised;
        uint256 reserved;
    }
    mapping (address => Share) public shares;

    mapping (address => uint[]) public nftIds;
    
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public totalReserved;

    uint256 public dividendsPerShareAccuracyFactor = 10 ** 18;

    modifier onlyDistributor() {
        require(msg.sender == _distributor); 
        _;
    }

    event nftStaked(address _user,uint _tokenId,uint _stamp);
    event nftUnstaked(address _user,uint _tokenId,uint _stamp);

    constructor() {
        _distributor = msg.sender;
    }

    function stake(uint _nftId) external {
        address shareholder = msg.sender;
        
        nftAddress.safeTransferFrom(shareholder, address(this), _nftId);
        nftIds[shareholder].push(_nftId);

        if(shares[shareholder].totalStaked > 0){
            distributeDividend(shareholder);
        }
        
        totalShares = totalShares.add(1);
        shares[shareholder].totalStaked += 1;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].totalStaked);

        emit nftStaked(shareholder,_nftId,block.timestamp);
    }

    function unstake(uint _nftId) external {

        address shareholder = msg.sender;
        uint length = nftIds[shareholder].length;
        uint index = findId(shareholder,_nftId,length);
        nftIds[shareholder][index] = nftIds[shareholder][length - 1];
        nftIds[shareholder].pop();

        if(shares[shareholder].totalStaked > 0){
            distributeDividend(shareholder);
        }

        totalShares = totalShares.sub(1);
        shares[shareholder].totalStaked -= 1;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].totalStaked);

        nftAddress.safeTransferFrom(address(this),shareholder, _nftId);

        emit nftUnstaked(shareholder,_nftId,block.timestamp);
    }

    function findId(address _user,uint _id,uint length) internal view returns (uint){
        bool found;
        uint index;
        for(uint i = 0; i < length; i++){
            if(nftIds[_user][i] == _id){
                found = true;
                index = i;
            }
        }
        if(!found) {
            revert NftNotFound();
        }
        return index;
    }

    function getUserStakedIds(address _user) external view returns (uint _subtotal,uint256[] memory _ids) {
        return (shares[_user].totalStaked,nftIds[_user]);
    } 

    function claim() external {
        address user = msg.sender;
        distributeDividend(user);
        uint subtotal = shares[user].reserved;
        if(subtotal > 0) {
            shares[user].reserved = 0;
            totalReserved = totalReserved.sub(subtotal);
            payable(user).transfer(subtotal);
        }
    }

    function deposit() external payable onlyDistributor() {
        uint256 amount = msg.value;
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].totalStaked == 0){ return; }
        uint256 amount = calEarning(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            shares[shareholder].reserved += amount;
            totalReserved += amount;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].totalStaked);
        }
    }

    function getUnpaidEarning(address shareholder) public view returns (uint256) {
        uint calReward = calEarning(shareholder);
        uint reservedReward = shares[shareholder].reserved;
        return calReward.add(reservedReward);
    }

    function calEarning(address shareholder) internal view returns (uint256) {
        if(shares[shareholder].totalStaked == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].totalStaked);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function setDistributor(address _newDistributor) external onlyOwner {
        _distributor = address(_newDistributor);
    }

    function setNft(address _newNft) external onlyOwner {
        nftAddress = IERC721(_newNft);
    }   

    function withdrawToken(address _token,uint _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function withdrawFunds() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawNfts(uint[] memory _ids) external onlyOwner {
        for(uint i = 0; i < _ids.length; i++) {
            nftAddress.safeTransferFrom(address(this),msg.sender,_ids[i]);
        }
    }

    receive() external payable {}

}