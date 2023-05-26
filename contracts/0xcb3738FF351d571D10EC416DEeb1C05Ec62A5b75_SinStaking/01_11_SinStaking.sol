// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/*

  _________                           __  .__              _____                __  .__             ________              .__.__          
 /   _____/__.__. _____ ___________ _/  |_|  |__ ___.__. _/ ____\___________  _/  |_|  |__   ____   \______ \   _______  _|__|  |   ______
 \_____  <   |  |/     \\____ \__  \\   __\  |  <   |  | \   __\/  _ \_  __ \ \   __\  |  \_/ __ \   |    |  \_/ __ \  \/ /  |  |  /  ___/
 /        \___  |  Y Y  \  |_> > __ \|  | |   Y  \___  |  |  | (  <_> )  | \/  |  | |   Y  \  ___/   |    `   \  ___/\   /|  |  |__\___ \ 
/_______  / ____|__|_|  /   __(____  /__| |___|  / ____|  |__|  \____/|__|     |__| |___|  /\___  > /_______  /\___  >\_/ |__|____/____  >
        \/\/          \/|__|       \/          \/\/                                      \/     \/          \/     \/                  \/ 

I see you nerd! ⌐⊙_⊙
*/

contract SinStaking is Ownable, ERC721Holder, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC721 public sftdContractInstance;

    IERC20 public sinsTokenContractInstance;

    // Number of tokens per block. There are approx 6k blocks per day and 10 tokens are represented by 10^19 (after considering decimals).
    uint256 public rate;

    // Expiration block number.
    uint256 public expirationBlockNumber;

    // Mapping of address to token numbers deposited
    mapping(address => EnumerableSet.UintSet) private _deposits;

    // Mapping of address -> token -> block number
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    uint256 private _ogSupply;

    constructor(address sympathyForTheDevilsContractAddress, uint256 initialRate, uint256 numberOfExpirationBlocks, address sinsTokenAddress, uint256 ogSupply) {
        sftdContractInstance = IERC721(sympathyForTheDevilsContractAddress);
        rate = initialRate;
        expirationBlockNumber = block.number + numberOfExpirationBlocks;
        sinsTokenContractInstance = IERC20(sinsTokenAddress);
        _ogSupply = ogSupply;
        _pause();
    }

    function setAddresses(address sympathyForTheDevilsContractAddress, address sinsTokenAddress) public onlyOwner {
        sftdContractInstance = IERC721(sympathyForTheDevilsContractAddress);
        sinsTokenContractInstance = IERC20(sinsTokenAddress);
    }

    function setRate(uint256 newRate) public onlyOwner {
        rate = newRate;
    }

    function setExpiration(uint256 numberOfExpirationBlocks) public onlyOwner {
        expirationBlockNumber = block.number + numberOfExpirationBlocks;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function depositsOf(address owner) external view returns (uint256[] memory) {
        EnumerableSet.UintSet storage depositSet = _deposits[owner];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function hasDeposits(address owner, uint256[] memory tokenIds) external view returns (bool) {
        EnumerableSet.UintSet storage depositSet = _deposits[owner];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (! depositSet.contains(tokenIds[i])) {
                return false;
            }
        }

        return true;
    }

    function hasDepositsOrOwns(address owner, uint256[] memory tokenIds) external view returns (bool) {
        EnumerableSet.UintSet storage depositSet = _deposits[owner];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (! depositSet.contains(tokenIds[i]) && sftdContractInstance.ownerOf(tokenIds[i]) != owner) {
                return false;
            }
        }

        return true;
    }

    function calculateRewards(address owner, uint256[] memory tokenIds) external view returns (uint256) {
        uint256 reward = 0;

        for (uint256 i; i < tokenIds.length; i++) {
            reward += calculateReward(owner, tokenIds[i]);
        }

        return reward;
    }

    function calculateReward(address owner, uint256 tokenId) public view returns (uint256) {
        require(Math.min(block.number, expirationBlockNumber) >= _depositBlocks[owner][tokenId], "Invalid block numbers");

        return rate * 
            (_deposits[owner].contains(tokenId) ? 1 : 0) * 
            (tokenId > _ogSupply ? 2 : 1) * 
            (Math.min(block.number, expirationBlockNumber) - _depositBlocks[owner][tokenId]);
    }

    function claimRewards(uint256[] calldata tokenIds) public whenNotPaused {
        uint256 reward = 0;
        uint256 currentBlock = Math.min(block.number, expirationBlockNumber);

        for (uint256 i; i < tokenIds.length; i++) {
            reward += calculateReward(msg.sender, tokenIds[i]);
            _depositBlocks[msg.sender][tokenIds[i]] = currentBlock;
        }

        if (reward > 0) {
            sinsTokenContractInstance.transfer(msg.sender, reward);
        }
    }

    function deposit(uint256[] calldata tokenIds) external whenNotPaused {
        require(msg.sender != address(sftdContractInstance), "Invalid address");
        uint256 currentBlock = Math.min(block.number, expirationBlockNumber);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            sftdContractInstance.safeTransferFrom(msg.sender, address(this), tokenIds[i], "");

            _deposits[msg.sender].add(tokenIds[i]);
            _depositBlocks[msg.sender][tokenIds[i]] = currentBlock;
        }
    }

    function withdraw(uint256[] calldata tokenIds) external whenNotPaused {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(_deposits[msg.sender].contains(tokenIds[i]), "This token has not been deposited");

            _deposits[msg.sender].remove(tokenIds[i]);

            sftdContractInstance.safeTransferFrom(address(this), msg.sender, tokenIds[i], "");
        }
    }

    function withdrawTokens(uint256 tokenAmount) external onlyOwner {
        sinsTokenContractInstance.transfer(msg.sender, tokenAmount);
    }
}