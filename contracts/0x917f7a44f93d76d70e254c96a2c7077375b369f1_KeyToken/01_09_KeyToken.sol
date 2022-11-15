// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

/**
 * @dev {ERC777} token
 * Learn more about the $KEYS on https://thewhitelist.io/
 *
 */
contract KeyToken is ERC777 {
    uint256 public BASE_SUPPLY = 500000000000000000000000000;
    address public NFT_STAKING_CONTRACT;
    address public LEGACY_NFT_STAKING_CONTRACT;
    address public RESERVES_MANAGER;
    bool public PERMANENTLY_DISABLE_RESERVE_MANAGEMENT = false;

    /**
     *
     */
    constructor(
        string memory name,
        string memory symbol,
        address[] memory defaultOperators
    ) ERC777(name, symbol, defaultOperators) {
        RESERVES_MANAGER = msg.sender;
    }

    /**
     * @dev This function setup the Token. Our entire supply is only rewarded through NFT Staking.
     *
     * @param _NFT_STAKING_CONTRACT The Staking contract
     *
     */
    function setupToken(address _NFT_STAKING_CONTRACT)
        public
        onlyTokenReserveManager
    {
        require(
            _NFT_STAKING_CONTRACT != address(0),
            "KEYS: Staking Contract can't be empty"
        );
        require(
            _NFT_STAKING_CONTRACT != address(0) &&
                NFT_STAKING_CONTRACT != _NFT_STAKING_CONTRACT,
            "KEYS: Staking Contract identical"
        );
        require(
            balanceOf(LEGACY_NFT_STAKING_CONTRACT) == 0,
            "KEYS: Old Staking Contract needs to be empty"
        );

        LEGACY_NFT_STAKING_CONTRACT = NFT_STAKING_CONTRACT;
        NFT_STAKING_CONTRACT = _NFT_STAKING_CONTRACT;

        // Mint First batch to Staking contract
        _mint(NFT_STAKING_CONTRACT, BASE_SUPPLY, "", "");
    }

    /**
     * @dev Fund Staking Pool on NFT_STAKING_CONTRACT. Anyone can call this once
     * the staking contract is below one 5th of BASE_SUPPLY.
     *
     */
    function fundStakingPool() external {
        require(
            balanceOf(NFT_STAKING_CONTRACT) < BASE_SUPPLY / 5,
            "KEYS: Staking Reward Pool has enough funds."
        );
        _mint(NFT_STAKING_CONTRACT, BASE_SUPPLY, "", "");
    }

    function burnLegacySupply() external onlyTokenReserveManager {
        require(
            LEGACY_NFT_STAKING_CONTRACT != address(0),
            "KEYS: No Legacy Staking Contract"
        );

        _burn(
            LEGACY_NFT_STAKING_CONTRACT,
            balanceOf(LEGACY_NFT_STAKING_CONTRACT),
            "",
            ""
        );
    }

    /**
     * @dev Once this function is called, no new Staking Contract can be added!
     */
    function disableReserveManagementPermanently()
        external
        onlyTokenReserveManager
    {
        PERMANENTLY_DISABLE_RESERVE_MANAGEMENT = true;
    }

    modifier onlyTokenReserveManager() {
        require(
            !PERMANENTLY_DISABLE_RESERVE_MANAGEMENT,
            "KEYS: Token Reserve Management Disabled"
        );

        require(
            msg.sender == RESERVES_MANAGER,
            "KEYS: Only Reserves Manager can withdrawal."
        );
        _;
    }
}