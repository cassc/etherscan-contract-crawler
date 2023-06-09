// SPDX-License-Identifier: MIT
// Archetype ERC20 PoC
//
//        d8888                 888               888
//       d88888                 888               888
//      d88P888                 888               888
//     d88P 888 888d888 .d8888b 88888b.   .d88b.  888888 888  888 88888b.   .d88b.
//    d88P  888 888P"  d88P"    888 "88b d8P  Y8b 888    888  888 888 "88b d8P  Y8b
//   d88P   888 888    888      888  888 88888888 888    888  888 888  888 88888888
//  d8888888888 888    Y88b.    888  888 Y8b.     Y88b.  Y88b 888 888 d88P Y8b.
// d88P     888 888     "Y8888P 888  888  "Y8888   "Y888  "Y88888 88888P"   "Y8888
//                                                            888 888
//                                                       Y8b d88P 888
//                                                        "Y88P"  888

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRewardToken.sol";


error MintLocked();
error OwnerMintLocked();
error NotAMinter(address triedToMint);
error MaxRewardsExceded();

struct Config {
	bool mintLocked;
	bool ownerMintLocked;
    bool rewardsMintersLocked;
    // Wont overflow as long as its below `(2**96)/(10**18)`.
	uint96 maxSupply;
}

contract MPARTY is Ownable, ERC20, IRewardToken {
    
    Config config;
    mapping (address => bool) private _isRewardsMinter;

	/*****************************************************\
	|* Contract Initialization And Configuration Methods *|
	\*****************************************************/
	constructor() ERC20("MiladyMakerParty", "MPARTY") {}

	function setMaxSupply(uint96 maxSupply) public onlyOwner {
        require(maxSupply >= totalSupply(), "Max supply can't be below current supply");
		config.maxSupply = maxSupply;
	}
	
	/********************\
	|* Minting  Methods *|
	\********************/
	function _mint(address account, uint256 amount) internal virtual override {
		if (config.mintLocked) revert MintLocked();
		super._mint(account, amount);
	}

	function ownerMint(address account, uint256 amount) public onlyOwner {
		if (config.ownerMintLocked) revert OwnerMintLocked();
        _mint(account, amount);
	}

	/*******************************\
	|* IRewardToken implementation *|
	\*******************************/
    function mintRewards(address account, uint256 amount) external {
        if (!_isRewardsMinter[msg.sender]) revert NotAMinter(msg.sender);
        if (amount > supplyLeft()) revert MaxRewardsExceded();
        _mint(account, amount);
    }

    function isRewardsMinter(address minter) public view returns (bool) {
        return _isRewardsMinter[minter];
    }

    function addRewardsMinter(address minter) external onlyOwner {
        require(!config.rewardsMintersLocked);
        _isRewardsMinter[minter] = true;
    }

    function removeRewardsMinter(address minter) external onlyOwner {
        require(!config.rewardsMintersLocked);
        _isRewardsMinter[minter] = false;
    }

    function supplyLeft() public view returns (uint256) {
        return totalSupply() > config.maxSupply ?
            0 : config.maxSupply - totalSupply();
    }

    /**************************\
    |* Contract configuration *|
    \**************************/
    function lockMintsForever() external onlyOwner {
        config.mintLocked = true; 
    }

    function lockOwnerMintsForever() external onlyOwner {
        config.ownerMintLocked = true; 
    }

    function lockRewardsMintersForever() external onlyOwner {
        config.rewardsMintersLocked = true; 
    }

}