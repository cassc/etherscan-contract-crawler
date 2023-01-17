//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ERC721HolderUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {IStakingPass} from "./IStakingPass.sol";
contract BitiocracyStakingContract is OwnableUpgradeable, ERC721HolderUpgradeable {

    mapping (address => address) public nftToStakingPass;

    mapping (address => mapping ( uint256 => uint256 ) ) private stakingStarted;
    mapping (address => mapping ( uint256 => uint256 ) ) private stakingTotal;
    mapping (address => mapping ( uint256 => address ) ) private lastStakedWallet;

    // Variables to mint into staking. Impossible to lock user staked tokens
    mapping (address => mapping ( uint256 => bool ) ) private lockedToken;    
    mapping (address => uint256) public totalLockedTokens;
    mapping (address => uint256) public availableToUnlock;
    mapping (address => uint256) public maxUnlockPerTransaction;

    // Variables for external contract managers
    mapping (address => bool ) private managerStatus;   
    event AddManager(address manager); 
    event RemoveManager(address manager);
    event StakeTokens(address collectionAddress, uint256 numberStaked);
    event StakeManual(address collectionAddress, uint256 numberStaked);
    event StakeManualLocked(address collectionAddress, uint256 numberStaked);
    event UnstakeTokens(address collectionAddress, uint256 numberUnstaked);
    event UnlockTokensAdmin(address collectionAddress, uint256 numberUnlocked);
    event UnlockTokens(address collectionAddress, uint256 numberUnlocked);

    function initialize() public initializer {
        __Ownable_init();
        __ERC721Holder_init();
    }


    // Managers allow external mint contracts to stake tokens directly
    modifier onlyOwnerOrManager() {
        require(
            managerStatus[msg.sender] == true || owner() == msg.sender,
            "caller is neither owner nor manager"
        );
        _;
    }

    function addManager(address _newManager) external onlyOwner {
        managerStatus[_newManager] = true;
        emit AddManager(_newManager);
    }

    function removeManager(address _newManager) external onlyOwner {
        managerStatus[_newManager] = false;
        emit RemoveManager(_newManager);
    }

    function isManager(address _checkAddress)
        external
        view
        returns (
            bool manager
        )
    {
        if (managerStatus[_checkAddress] == true) {
            manager = true;
        } else {
            manager = false;
        }
        
    }


    function stakeTokens(address _collectionAddress, uint256[] memory Tokens) external {
        uint256[] memory localTokens = Tokens;
        uint256 arrayLength = localTokens.length;

        for (uint256 i =0; i<arrayLength;) {
            require(IStakingPass(_collectionAddress).ownerOf(localTokens[i]) == msg.sender, "You do not own this Token");
            IStakingPass(_collectionAddress).safeTransferFrom(msg.sender, address(this), localTokens[i]);
            if(IStakingPass(nftToStakingPass[_collectionAddress]).checkExistence(localTokens[i])) {
                IStakingPass(nftToStakingPass[_collectionAddress]).transferFrom( address(this), msg.sender, localTokens[i]);
            } else {
                IStakingPass(nftToStakingPass[_collectionAddress]).mint(msg.sender, localTokens[i]);
            }

            // Add time track
            if (stakingTotal[_collectionAddress][localTokens[i]] > 0){
                if (lastStakedWallet[_collectionAddress][localTokens[i]] != msg.sender) {
                    stakingTotal[_collectionAddress][localTokens[i]] = 0;    
                }
            }
            stakingStarted[_collectionAddress][localTokens[i]] = block.timestamp;
        unchecked {
            i++;
        }

        emit StakeTokens(_collectionAddress, arrayLength);
        }
    }


    /**
        Function to mint into staking from mint contracts. Tokens staked by users can not be locked.
     */
    function stakeManual(address _collectionAddress, uint256[] memory Tokens, address targetWallet, bool lockTokens) external onlyOwnerOrManager {
        uint256[] memory localTokens = Tokens;
        uint256 arrayLength = localTokens.length;

        for (uint256 i =0; i<arrayLength;) {
            // Send tokens to stake first
            require(IStakingPass(_collectionAddress).ownerOf(localTokens[i]) == address(this), "Send Token First");
            
            if(IStakingPass(nftToStakingPass[_collectionAddress]).checkExistence(localTokens[i])) {
                IStakingPass(nftToStakingPass[_collectionAddress]).transferFrom( address(this), targetWallet, localTokens[i]);
            } else {
                IStakingPass(nftToStakingPass[_collectionAddress]).mint(targetWallet, localTokens[i]);
            }

            if (stakingTotal[_collectionAddress][localTokens[i]] > 0){
                if (lastStakedWallet[_collectionAddress][localTokens[i]] != targetWallet) {
                    stakingTotal[_collectionAddress][localTokens[i]] = 0;    
                }
            }

            if (lockTokens == true){
                lockedToken[_collectionAddress][localTokens[i]] = true;
            }
            stakingStarted[_collectionAddress][localTokens[i]] = block.timestamp;
        unchecked {
            i++;
        }
        }

        if (lockTokens == true){
            totalLockedTokens[_collectionAddress] += arrayLength;
            emit StakeManualLocked(_collectionAddress, arrayLength);
        } else {
            emit StakeTokens(_collectionAddress, arrayLength);
        }
    }    


    /**
        Transfer without losing staking totals.
     */
    function transferStaked(address _collectionAddress, uint256[] memory Tokens, address _toAddress) external {
        uint256[] memory localTokens = Tokens;
        uint256 arrayLength = localTokens.length;

        for (uint256 i =0; i<arrayLength;) {
            require(IStakingPass(_collectionAddress).ownerOf(localTokens[i]) == msg.sender, "You do not own this Token");

            IStakingPass(_collectionAddress).safeTransferFrom(msg.sender, _toAddress, localTokens[i]);

            lastStakedWallet[_collectionAddress][localTokens[i]] = _toAddress;

        unchecked {
            i++;
        }
        }

    }


    function unstakeTokens(address _collectionAddress, uint256[] memory Tokens) external{
        uint256[] memory localTokens = Tokens;
        uint256 arrayLength = localTokens.length;

        for (uint256 j = 0; j <arrayLength;) {
            require (IStakingPass(nftToStakingPass[_collectionAddress]).ownerOf(localTokens[j]) == msg.sender, "You do not own this staking pass");
            require (lockedToken[_collectionAddress][localTokens[j]] != true, "Locked Token");

            IStakingPass(nftToStakingPass[_collectionAddress]).safeTransferFrom( msg.sender, address(this), localTokens[j]);
            IStakingPass(_collectionAddress).transferFrom(address(this), msg.sender, localTokens[j]);
            // time tracker
            stakingTotal[_collectionAddress][localTokens[j]] += block.timestamp - stakingStarted[_collectionAddress][localTokens[j]];
            stakingStarted[_collectionAddress][localTokens[j]] = 0;
            lastStakedWallet[_collectionAddress][localTokens[j]] = msg.sender;
            unchecked {
                j++;
            }
        }
        emit UnstakeTokens(_collectionAddress, arrayLength);
    }


    /**
        User unlockable tokens. Sets the rate tokens can be released to trading supply.
     */    
    function setAmountToUnlock(address _collectionAddress, uint256 _newAmount) external onlyOwner {
        availableToUnlock[_collectionAddress] = _newAmount;
    }

    function setMaxUnlockPerTransaction(address _collectionAddress, uint256 _newMax) external onlyOwner {
        maxUnlockPerTransaction[_collectionAddress] = _newMax;
    }


    /**
        Unlock for Admins.
     */
    function unlockTokensAdmin(address _collectionAddress, uint256[] memory Tokens) external onlyOwnerOrManager {
        uint256[] memory localTokens = Tokens;
        uint256 arrayLength = localTokens.length;
        uint256 totalUnlocked = 0;

        for (uint256 j = 0; j <arrayLength;) {
            if ( lockedToken[_collectionAddress][localTokens[j]] == true ) {
                totalUnlocked += 1;
                lockedToken[_collectionAddress][localTokens[j]] = false;
            }

            unchecked {
                j++;
            }
        }
        availableToUnlock[_collectionAddress] -= totalUnlocked;
        totalLockedTokens[_collectionAddress] -= totalUnlocked;

        emit UnlockTokensAdmin(_collectionAddress, arrayLength);
    }


    /**
        Unlock for tokens minted into staking. Can unlock when allocations are made available.
     */
    function unlockTokens(address _collectionAddress, uint256[] memory Tokens) external {
        uint256[] memory localTokens = Tokens;
        uint256 totalUnlocked = 0;
        uint256 arrayLength = localTokens.length;

        require(availableToUnlock[_collectionAddress] >= arrayLength, "Less available than requested");
        require(maxUnlockPerTransaction[_collectionAddress] >= arrayLength, "Too many unlocks in 1 transaction");

        for (uint256 j = 0; j <arrayLength;) {            
            require (IStakingPass(nftToStakingPass[_collectionAddress]).ownerOf(localTokens[j]) == msg.sender, "You do not own this staking pass");

            if ( lockedToken[_collectionAddress][localTokens[j]] == true ) {
                totalUnlocked += 1;
                lockedToken[_collectionAddress][localTokens[j]] = false;
            }

            unchecked {
                j++;
            }
        }
        availableToUnlock[_collectionAddress] -= totalUnlocked;
        totalLockedTokens[_collectionAddress] -= totalUnlocked;

        emit UnlockTokens(_collectionAddress, arrayLength);
    }


    function stakeTotalTime(address _collectionAddress, uint256 tokenId)
        external
        view
        returns (
            uint256 current,
            uint256 total
        )
    {
        uint256 start = stakingStarted[_collectionAddress][tokenId];
        if (start != 0) {
            current = block.timestamp - start;
        }
        total = current + stakingTotal[_collectionAddress][tokenId];
    }

    function lastWalletUsed(address _collectionAddress, uint256 tokenId)
        external
        view
        returns (
            address lastWallet
        )
    {
        lastWallet = lastStakedWallet[_collectionAddress][tokenId];
    }


    function isTokenLocked(address _collectionAddress, uint256 tokenId)
        external
        view
        returns (
            bool tokenLocked
        )
    {
        if (lockedToken[_collectionAddress][tokenId] == true) {
            tokenLocked = true;
        } else {
            tokenLocked = false;
        }
        
    }

    function lockCounts(address _collectionAddress)
        external
        view
        returns (
            uint256 totalLocked,
            uint256 totalAvailable,
            uint256 maxPerTransaction
        )
    {
        totalLocked = totalLockedTokens[_collectionAddress];
        totalAvailable = availableToUnlock[_collectionAddress];
        maxPerTransaction = maxUnlockPerTransaction[_collectionAddress];
        
    }    


    function addPassToCollection (address[] memory _nftAddress, address[] memory _stakingPassAddress) external onlyOwnerOrManager {
        for (uint256 i = 0; i < _nftAddress.length;i++) {
            nftToStakingPass[_nftAddress[i]] = _stakingPassAddress[i];
            availableToUnlock[_nftAddress[i]] = 0;
            maxUnlockPerTransaction[_nftAddress[i]] = 1;
        }
    }

    function removePassFromCollection (address[] memory _nftAddress) external onlyOwner {
        for (uint256 i = 0; i < _nftAddress.length;i++) {
            delete nftToStakingPass[_nftAddress[i]];
            availableToUnlock[_nftAddress[i]] = 0;
            maxUnlockPerTransaction[_nftAddress[i]] = 1;
        }
    }
}