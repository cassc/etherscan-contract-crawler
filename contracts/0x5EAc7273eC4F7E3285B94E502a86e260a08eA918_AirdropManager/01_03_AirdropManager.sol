// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error AlreadyClaimed();
error InvalidAmountPerUser();
error InvalidProof();
error InvalidAirdrop();
error InvalidInput();
error InvalidStartDate();
error AirdropFullyClaimed();
error AirdropStillActive();
error AirdropNotStarted();

contract AirdropManager {
    mapping(address token => Airdrop[]) airdropList;
    mapping(uint256 airdropIndex => Airdrop) airdropInfo;
    mapping(uint256 airdropIndex => mapping(uint256 => uint256)) claimedBitMap;
    mapping(address user => bool ) public isAdmin;

    struct Airdrop {
        uint256 startDate;
        uint256 total;
        uint256 amountPerUser;
        uint256 claimed;
        bytes32 root;
        string whitelistUri;
        string imageUri;
        address token;
    }

    uint256 public airdropCount;

    address public immutable DEPLOYER;

    event Claimed(address indexed token, address indexed user, uint256 amount);
    event AirdropAdded(address indexed token, uint256 indexed index, uint256 total, uint256 amountPerUser, bytes32 root);

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] || DEPLOYER == msg.sender, "Only admin can call this function");
        _;
    }

    constructor() {
        isAdmin[msg.sender] = true;
        DEPLOYER = msg.sender;
    }

    function fetchCurrentAirdrop() external view returns(Airdrop memory){
        if(airdropCount == 0) return Airdrop(0,0,0,0,0,"","",address(0));
        return airdropInfo[airdropCount-1];
    }

    function fetchAirdropListLengthByToken(address token) external view returns(uint256) {
        return airdropList[token].length;
    }
    
    function fetchAirdropByTokenAndIndex(address token, uint256 index) external view returns(Airdrop memory) {
        return airdropList[token][index];
    }

    function fetchAirdropByAirdropIndex(uint256 airdropIndex) external view returns(Airdrop memory) {
        return airdropInfo[airdropIndex];
    }

    function isClaimed(uint256 airdropIndex, uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[airdropIndex][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 airdropIndex, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[airdropIndex][claimedWordIndex] = claimedBitMap[airdropIndex][claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claimAirdrop(uint256 userIndex, address user, bytes32[] calldata proof) external {
        if(airdropCount == 0) revert InvalidAirdrop();
        uint256 airdropIndex = airdropCount - 1;
        Airdrop memory airdrop = airdropInfo[airdropIndex];
        if(airdrop.startDate > block.timestamp) revert AirdropNotStarted();
        if(airdrop.total == 0) revert InvalidAirdrop();
        if(airdrop.total == airdrop.claimed) revert AirdropFullyClaimed();
        if(isClaimed(airdropIndex, userIndex)) revert AlreadyClaimed();
        uint256 amount = airdrop.amountPerUser;
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(userIndex, user))));
        if(!MerkleProof.verifyCalldata(proof, airdrop.root, leaf)) revert InvalidProof();
        _setClaimed(airdropIndex, userIndex);
        airdropInfo[airdropIndex].claimed += amount;
        IERC20(airdrop.token).transfer(user, amount);

        emit Claimed(airdrop.token, user, amount);
    }

    function addAirdrop(address token, uint256 startDate, uint256 total, uint256 amountPerUser, bytes32 root, string calldata whitelistUri, string calldata imageUri) external onlyAdmin {
        if(total == 0 || amountPerUser == 0 || root == 0 || token == address(0)) revert InvalidInput();
        if(startDate < block.timestamp) revert InvalidStartDate();
        if(total % amountPerUser != 0) revert InvalidAmountPerUser();
        if(airdropCount != 0){
            Airdrop memory airdrop = airdropInfo[airdropCount-1];
            if(airdrop.total != airdrop.claimed) revert AirdropStillActive();
        }
        IERC20(token).transferFrom(msg.sender, address(this), total);
        Airdrop memory newAirdrop = Airdrop(startDate, total, amountPerUser, 0, root, whitelistUri, imageUri, token);
        airdropInfo[airdropCount] = newAirdrop;
        airdropList[token].push(newAirdrop);
        uint256 index = airdropList[token].length - 1;
        airdropCount++;

        emit AirdropAdded(token, index, total, amountPerUser, root);
    }

    function forceStopAirdrop() external onlyAdmin {
        if(airdropCount == 0) revert InvalidAirdrop();
        Airdrop memory airdrop = airdropInfo[airdropCount-1];
        if(airdrop.total == airdrop.claimed) revert AirdropFullyClaimed();
        airdropInfo[airdropCount-1].total = airdrop.claimed;
    }

    function emergencyRescue(address token) external onlyAdmin{
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, amount);
    }

    function setAdmin(address _admin, bool _isAdmin) external onlyAdmin {
        isAdmin[_admin] = _isAdmin;
    }

    function setAdminList(address[] calldata _adminList, bool status) external onlyAdmin {
        uint256 size = _adminList.length;
        for(uint256 i = 0; i < size; ) {
            isAdmin[_adminList[i]] = status;
            unchecked {
                ++i;
            }
        }
    }

}