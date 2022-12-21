// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../ERC721/NorthPass.sol";
import "../../lib/payment/Withdrawable.sol";

error MintNotActive();
error NotOnTheAllowlist();
error NotPrepaid();
error NotEnoughPaid();
error ExceedsMaxTotalSupply();
error AddressAlreadyMinted();

/**
 * @title Founders by North Minter
 * @dev Contract for minting the Founders by North NFT for https://northapp.com
 * @author North Technologies
 * @custom:version v1.0
 * @custom:date 20 December 2022
 */
contract NorthPassMinter is AccessControl, Withdrawable {
    using Counters for Counters.Counter;

    bytes32 public constant STAFF_ROLE = keccak256("STAFF_ROLE");

    NorthPass private immutable _passContract = NorthPass(address(0x44A9e7CB929CCed8F7Ea3D79C216C0Cd8120506D)); // Main

    bool public mintActive = false; 

    uint256 public mintingFee = 590000000000000000; // 0.59 ETH

    uint256 public maxTotalSupply = 360;
    uint256 public prepaidReserved = 80;

    Counters.Counter private _prepaidRedeemedCounter;

    mapping(address => bool) public addressMinted;
    
    bytes32 public whitelistMerkleRoot = 0xe62ae175d2eb022f059b107f18c8949119eb17dd3b9f508ea8601ec01c7255ad;
    bytes32 public prepaidMerkleRoot = 0xff0d8f3b162b0703d5a4f429723d56329b423a5e4c59db3a9ead2f37eb5f8690;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(STAFF_ROLE, msg.sender);
    }

    function getTotalPrepaidRedeemed() public view returns (uint256) {
        return _prepaidRedeemedCounter.current();
    }

    function flipMintActive() external onlyRole(STAFF_ROLE) {
        mintActive = !mintActive;
    }

    function setMaxtTotalSupply(uint256 _maxTotalSupply) external onlyRole(STAFF_ROLE) {
        maxTotalSupply = _maxTotalSupply;
    }

    function setPreparedReserved(uint256 _prepaidReserved) external onlyRole(STAFF_ROLE) {
        prepaidReserved = _prepaidReserved;
    }

    function setMintingFee(uint256 _mintingFee) external onlyRole(STAFF_ROLE) {
        mintingFee = _mintingFee;
    }

    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot) external onlyRole(STAFF_ROLE) {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    function setPrepaidMerkleRoot(bytes32 _prepaidMerkleRoot) external onlyRole(STAFF_ROLE) {
        prepaidMerkleRoot = _prepaidMerkleRoot;
    }

    function flipAddressMinted(address minter) external onlyRole(STAFF_ROLE) {
        addressMinted[minter] = !addressMinted[minter];
    }

    function verifyMerkleProof(bytes32 merkleRoot, address _address, bytes32[] memory _merkleProof) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function prepaidSafeMint(bytes32[] memory _merkleProof) external returns (uint256 tokenId) {
        if(!verifyMerkleProof(prepaidMerkleRoot, msg.sender, _merkleProof)) revert NotPrepaid();

        _prepaidRedeemedCounter.increment();

        return _safeMint(msg.sender);
    }

    function safeMint(bytes32[] memory _merkleProof) external payable returns (uint256 tokenId) {
        if(!verifyMerkleProof(whitelistMerkleRoot, msg.sender, _merkleProof)) revert NotOnTheAllowlist();

        // Collect payment
        if(msg.value < mintingFee) revert NotEnoughPaid();

        return _safeMint(msg.sender);
    }

    function _safeMint(address to) internal returns (uint256 tokenId) {
        // Check that mint is activated
        if(!mintActive) revert MintNotActive();

        // Check if mint would not be exceeding supply
        if(_passContract.totalSupply() + prepaidReserved - _prepaidRedeemedCounter.current() >= maxTotalSupply) revert ExceedsMaxTotalSupply();

        // Check if adddress minted before
        if(addressMinted[msg.sender]) revert AddressAlreadyMinted();

        // Set address minted to true to deny the next time
        addressMinted[msg.sender] = true;

        // Mint
        return _passContract.safeMint(to);
    }
}