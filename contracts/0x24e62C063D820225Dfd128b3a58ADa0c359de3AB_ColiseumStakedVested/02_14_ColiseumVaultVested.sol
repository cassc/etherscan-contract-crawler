//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./ColiseumStakedVested.sol";
import "./IColiseum.sol";

contract ColiseumVaultVested is Ownable, IERC721Receiver {
    // Custom errors
    error TokenIdNotStaked();
    error NotYourToken();
    error NeedToInputAllPastStakedIds();
    error NotAllowedToClaimTwiceInSameBlock();
    error NotAuthorized();
    error LockActive();
    error InvalidLock();
    error InvalidStakeCount();
    error LockDisabled();

    // State variables

    uint256 public totalStaked;

    uint256 public deployTime;

    bool public emergencyActive;

    struct Stake {
        address owner;
        uint24 tokenId;
        bool isStaked;
        uint256 lastClaimed;
        uint8 lockType;
    }

    event ColiseumIsStaked(
        address owner,
        address stakedFor,
        uint256 tokenId,
        uint8 lock
    );
    event ColiseumUnstaked(address owner, uint256 tokenId);
    event Claimed(address owner, uint256 amount);

    // Contract instances and mappings

    IColiseum public coliseum =
        IColiseum(0x575D99d27ffF5974d608b7089404daDc9e291aca);

    ColiseumStakedVested public stakedColiseumVested =
        ColiseumStakedVested(0x575D99d27ffF5974d608b7089404daDc9e291aca);

    mapping(uint256 => Stake) public vault;

    mapping(uint8 => bool) public lockTypeActive;
    mapping(uint8 => bool) public lockTypeDisabled;
    mapping(uint8 => uint256) public lockTypeTime;

    mapping(address => uint256) private balanceOfTokens;

    mapping(address => bool) controllers;

    // Constructor

    constructor() {
        deployTime = block.timestamp;
        controllers[msg.sender] = true;
        lockTypeTime[0] = 604800;
        lockTypeTime[1] = 1209600;
        lockTypeTime[2] = 2419200;
        lockTypeTime[3] = 7257600;
    }

    modifier callerIsController() {
        if (!controllers[msg.sender]) revert NotAuthorized();
        _;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function setStakedContract(
        ColiseumStakedVested _newContract
    ) external onlyOwner {
        stakedColiseumVested = _newContract;
    }

    function setContract(IColiseum _newContract) external onlyOwner {
        coliseum = _newContract;
    }

    function stake(uint256[] calldata tokenIds, uint8 lock) external {
        uint256 tokenId;
        if (lockTypeTime[lock] == 0) revert InvalidLock();
        if (lockTypeDisabled[lock]) revert LockDisabled();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (coliseum.ownerOf(tokenId) != msg.sender) revert NotYourToken();

            coliseum.transferFrom(msg.sender, address(this), tokenId);
            emit ColiseumIsStaked(msg.sender, msg.sender, tokenId, lock);

            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                isStaked: true,
                lastClaimed: block.timestamp,
                lockType: lock
            });
        }
        stakedColiseumVested.batchMint(msg.sender, tokenIds);
        totalStaked += tokenIds.length;
        balanceOfTokens[msg.sender] += tokenIds.length;
    }

    function setLockDisabled(
        uint8 lock,
        bool active
    ) external callerIsController {
        lockTypeDisabled[lock] = active;
    }

    function isLockDisabled(uint8 lock) external view returns (bool) {
        return lockTypeDisabled[lock];
    }

    function setLockTypeTime(
        uint8 _lockType,
        uint256 _timeInBlocks
    ) external callerIsController {
        lockTypeTime[_lockType] = _timeInBlocks;
    }

    function setOwnerOfTokenId(
        uint256 tokenId,
        address newOwner
    ) external callerIsController {
        vault[tokenId].owner = newOwner;
    }

    function setLockTypeActive(
        uint8 lockTypeNumber,
        bool active
    ) external callerIsController {
        lockTypeActive[lockTypeNumber] = active;
    }

    function deleteVaultOfTokenId(uint256 tokenId) external callerIsController {
        delete vault[tokenId];
    }

    function setLockTypeForTokenId(
        uint256 tokenId,
        uint8 lockTypeNumber
    ) external callerIsController {
        vault[tokenId].lockType = lockTypeNumber;
    }

    function setLastClaimedOfTokenId(
        uint256 tokenId
    ) external callerIsController {
        vault[tokenId].lastClaimed = block.timestamp;
    }

    function setTotalStaked(
        uint256 newTotalStaked
    ) external callerIsController {
        totalStaked = newTotalStaked;
    }

    function setBalanceOfTokensOfUser(
        address user,
        uint256 newBalance
    ) external callerIsController {
        balanceOfTokens[user] = newBalance;
    }

    function unstake(uint256[] calldata tokenIds) external {
        _unstakeMany(msg.sender, tokenIds);
    }

    function toggleEmergencyActive() external onlyOwner {
        emergencyActive = !emergencyActive;
    }

    function emergencyUnstake(uint256[] calldata tokenIds) external {
        require(emergencyActive, "Only in emergencies");
        _unstakeManyEmergency(msg.sender, tokenIds);
    }

    function _unstakeManyEmergency(
        address account,
        uint256[] calldata tokenIds
    ) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            Stake memory currentVault = vault[tokenIds[i]];
            if (currentVault.owner != account) revert NotYourToken();
            delete vault[tokenIds[i]];
            emit ColiseumUnstaked(account, tokenIds[i]);
            coliseum.transferFrom(address(this), account, tokenIds[i]);
        }
        stakedColiseumVested.batchBurn(tokenIds);
        balanceOfTokens[account] -= tokenIds.length;
        totalStaked -= tokenIds.length;
    }

    function _unstakeMany(
        address account,
        uint256[] calldata tokenIds
    ) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            Stake memory currentVault = vault[tokenIds[i]];
            if (currentVault.owner != account) revert NotYourToken();
            require(
                ((currentVault.lastClaimed +
                    lockTypeTime[currentVault.lockType]) < block.timestamp) ||
                    (lockTypeActive[currentVault.lockType]),
                "Lock not active"
            );
            delete vault[tokenIds[i]];
            emit ColiseumUnstaked(account, tokenIds[i]);
            coliseum.transferFrom(address(this), account, tokenIds[i]);
        }
        stakedColiseumVested.batchBurn(tokenIds);
        balanceOfTokens[account] -= tokenIds.length;
        totalStaked -= tokenIds.length;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOfTokens[account];
    }

    function tokensOfOwner(
        address account
    ) public view returns (uint256[] memory ownerTokens) {
        uint256 supply = coliseum.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tokenId;
                index += 1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function tokensOfOwnerUnStaked(
        address account
    ) public view returns (uint256[] memory ownerTokens) {
        uint256 supply = coliseum.totalSupply();
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            // Check if the token exists using a try-catch statement
            try coliseum.ownerOf(tokenId) returns (address tokenOwner) {
                // If the token exists and the owner is the specified account, add it to the array
                if (tokenOwner == account) {
                    tmp[index] = tokenId;
                    index += 1;
                }
            } catch {
                // If the token doesn't exist, continue with the next token
                continue;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function getLastClaimedOfToken(
        uint256 tokenId
    ) external view returns (uint256) {
        if (!vault[tokenId].isStaked) revert TokenIdNotStaked();
        return vault[tokenId].lastClaimed;
    }

    function getOwnerOfToken(uint256 tokenId) external view returns (address) {
        if (vault[tokenId].owner == address(0)) revert TokenIdNotStaked();
        return vault[tokenId].owner;
    }

    function isUserStaking(address account) external view returns (bool) {
        return balanceOfTokens[account] > 0;
    }

    function isLockActive(uint8 lock) external view returns (bool) {
        return lockTypeActive[lock];
    }

    function getLockOfToken(uint256 tokenId) external view returns (uint8) {
        if (!vault[tokenId].isStaked) revert TokenIdNotStaked();
        return vault[tokenId].lockType;
    }

    function isTokenIdStaked(uint256 tokenId) external view returns (bool) {
        return vault[tokenId].isStaked;
    }

    function getOwnerOfStakedToken(
        uint256 tokenId
    ) external view returns (address) {
        if (!vault[tokenId].isStaked) revert TokenIdNotStaked();
        return vault[tokenId].owner;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}