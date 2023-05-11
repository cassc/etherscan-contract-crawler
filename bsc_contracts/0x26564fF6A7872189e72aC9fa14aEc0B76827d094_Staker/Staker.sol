/**
 *Submitted for verification at BscScan.com on 2023-05-11
*/

// File: @openzeppelin\contracts\utils\Context.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol



pragma solidity ^0.8.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts\SHREYA\Deposit.sol



pragma solidity ^0.8.0;
abstract contract NFTToken721 {
    function transferFrom(address from, address to, uint256 tokenId) virtual external;
    function ownerOf(uint256 tokenId) public view virtual  returns (address);
    function setApprovalForAll(address operator, bool approved) public virtual;
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool);

}
abstract contract Token20 {
    function approve(address spender, uint value) virtual external returns (bool);

    function transfer(address to, uint value) virtual external returns (bool);

    function transferFrom(address from, address to, uint value) virtual external returns (bool);

    function balanceOf(address owner) virtual external view returns (uint);
}

contract Staker is Ownable {

    address public nftToken721Addr;

    bool public pauseStake;
    bool public pauseUnStake;

    uint public stakeTotal;

    mapping(address => uint[] ) public stakeList;
    mapping(uint =>address) public ownership;

    mapping(address => bool) public assetRole;

    NFTToken721 private nftToken721;

    event Stake(address _addr, uint _num);
    event UnStake(address _addr, uint _num);

    function _addItem(address _addr,uint item) private {
        ownership[item] = msg.sender;
        stakeList[_addr].push(item);
    }
    function getList(address _addr)view public returns(uint[] memory){
        return stakeList[_addr];
    }
    function _deleteItem(address _addr, uint item) private {
        for(uint i = 0; i < stakeList[_addr].length; i++){
            if (stakeList[_addr][i] == item){
                _remove(_addr,i);
            } 
        }
        delete ownership[item];
    }
    function _remove(address _addr,uint _index) private  {
        require(_index < stakeList[_addr].length, "index out of bound");

        for (uint i = _index; i < stakeList[_addr].length - 1; i++) {
            stakeList[_addr][i] = stakeList[_addr][i + 1];
        }
        stakeList[_addr].pop();
    }

    function pauseDep() external onlyOwner {
        pauseStake = true;
    }

    function unpauseDep() external onlyOwner {
        pauseStake = false;
    }

    function pauseUnDep() external onlyOwner {
        pauseUnStake = true;
    }

    function unpauseUnDep() external onlyOwner {
        pauseUnStake = false;
    }

    function addAssetRole(address _addr) external onlyOwner {
        assetRole[_addr] = true;
    }

    function removeAssetRole(address _addr) external onlyOwner {
        assetRole[_addr] = false;
    }

    function setNFT721TokenAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        nftToken721Addr = _addr;
        nftToken721 = NFTToken721(_addr);
    }


    function stake(uint tokenId) external {
        require(nftToken721.isApprovedForAll(msg.sender, address(this)),"please approve first");
        require(nftToken721.ownerOf(tokenId) == msg.sender, "Error:sender not owner");
        require(ownership[tokenId]==address(0x0),"nft is already staked");
        require(!pauseStake, "Error: Stake paused!");
        nftToken721.transferFrom(msg.sender, address(this), tokenId);
        _addItem(msg.sender,tokenId);
        stakeTotal += 1;

        emit Stake(msg.sender, tokenId);
    }

    function _unStake(uint _tokenId) private {
        require(ownership[_tokenId]==msg.sender,"Error:sender not owner");
        require(nftToken721.ownerOf(_tokenId) == address(this), "Error:staker not owner");
        require(!pauseUnStake, "Error:UnStake paused!");
        nftToken721.transferFrom(address(this), msg.sender, _tokenId);
        _deleteItem(msg.sender, _tokenId);
        stakeTotal -= 1;
        emit UnStake(msg.sender, _tokenId);
    }
    function unStake(uint _tokenId) external{
        _unStake(_tokenId);
    }
    function unStakeList(uint[] memory _tokenIds) external {
        for(uint i = 0;i<_tokenIds.length;i++){
            _unStake(_tokenIds[i]);
        }
    }
    function withdrawToken20(address _addr) external onlyOwner {
        Token20 token20 = Token20(_addr);
        token20.transfer(_addr, token20.balanceOf(address(this)));
    }

    modifier onlyAssetRole() {
        require(assetRole[msg.sender] || msg.sender == owner(), "onlyAssetRole");
        _;
    }


}