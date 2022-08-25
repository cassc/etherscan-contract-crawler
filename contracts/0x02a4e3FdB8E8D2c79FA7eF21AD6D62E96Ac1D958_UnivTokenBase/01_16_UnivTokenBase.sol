//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./IUnivToken.sol";

contract UnivTokenBase is ERC777Upgradeable, AccessControlUpgradeable, IUnivToken {

    uint constant ONE_TOKEN = 1e18;
    /**
     * @dev MINTER_ROLE role is assigned to our NFT contract so that it can
     * mint a single Token for each NFT that is minted.
     * The minter must pay an eth fee that it stores in escrow in case the
     * owner of the Token would like to redeem it (burn).
     *
     **/
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint escrowFee;

    function getEscrowFee() public virtual override view returns (uint) {
        return escrowFee;
    }

    function getEscrow() public virtual override view returns (uint256) {
        return address(this).balance;
    }
//    We should not change this value after contract deployed as the owners
//    of tokens can redeem them for the escrow price paid (and not a different price).
//
//    function setEscrowFee(uint fee) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
//        escrowFee = fee;
//    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize()
    initializer public {
        __Context_init_unchained();
        __ERC777_init_unchained("Kozmosi Token", "KOZMO", new address[](0));
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        escrowFee = 0.001 ether;
        _mint(msg.sender, 1000000e18, "", "");
    }

    /**
     * @dev mintTokenForNft
     * The minter must pay an eth fee that it stores in escrow in case the
     * owner of the Token would like to redeem it (burn).
     * Each time an NFT is generated we also give the minter a free token!
     **/
    function mintTokenForNft(address account) public virtual override payable onlyRole(MINTER_ROLE) {
        require(msg.value == escrowFee, "In order to mint a token you must pay the escrow fee");
        _mint(account, ONE_TOKEN, "", "" );
    }

    /**
     * @dev mintTokenForMiner
     * The minter must pay an eth fee that it stores in escrow in case the
     * owner of the Token would like to redeem it (burn).
     * Each time 100 NFT(s) are generated we also give the miner a free token!
     **/
    function mintTokenForMiner(address miner) public virtual override payable onlyRole(MINTER_ROLE) {
        require(msg.value == escrowFee, "In order to mint a token you must pay the escrow fee");
        _mint(miner, ONE_TOKEN, "", "");
    }

    /**
     * @dev owners of tokens can redeem them at any time for the escrow amount they paid.
     * @param tokenOwner address to redeem to
     * @param tokenAmount in wei 1 full token is 1e18 wei (minimum redemption is 1 full token).
     */
    function redeemTokens(address payable tokenOwner, uint256 tokenAmount) public virtual override {
        require(tokenAmount >= ONE_TOKEN, "Must redeem at least one token" );
        _burn(tokenOwner, tokenAmount, "Token Redeemed", "");
        uint refundAmount = (tokenAmount / ONE_TOKEN) * escrowFee;
        tokenOwner.transfer(refundAmount);
    }

    /**
     * @dev fallback function to receive ether.
     **/
    receive() external payable {  }
}