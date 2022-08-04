// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./ETHWalkersMiami.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract FreeAndFriendsMint is Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;
    ETHWalkersMiami private ewalk;
    mapping(address => uint8) public numberMinted;
    bool public friendsMintLive = false;
    address public whitelistSigner = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

    constructor() {
        address EwalksMiamiAddress = 0xD56814B97396c658373A8032C5572957D123a49e;
        ewalk = ETHWalkersMiami(EwalksMiamiAddress);
    }

    //Constants for signing whitelist
    bytes32 constant DOMAIN_SEPERATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("Signer NFT Distributor"),
            keccak256("1"),
            uint256(1),
            address(0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC)
        ));

    bytes32 constant ENTRY_TYPEHASH = keccak256("Entry(uint256 index,address wallet)");

    function friendsAndFreeETHWalkersMiamiMint(uint8 numberOfTokens, uint maxMints, bytes memory signature) external whenNotPaused {
        require(friendsMintLive, "Free mint must be started");
        require(numberMinted[_msgSender()] + numberOfTokens <= maxMints, "Exceeds maximum per wallet");
        require(!isContract(_msgSender()), "I fight for the user! No contracts");
        require(ewalk.totalSupply().add(numberOfTokens) <= ewalk.totalSupplyMiami(), "Purchase exceeds max supply of ETH Walkers");

        // verify signature
        bytes32 digest = getDigest(maxMints);
        address claimSigner = ECDSA.recover(digest, signature);
        require(claimSigner == whitelistSigner, "Invalid Message Signer.");

        ewalk.controllerMint(_msgSender(), numberOfTokens);
        numberMinted[_msgSender()] += numberOfTokens;
    }

    function flipContractSaleState() public onlyOwner {
        friendsMintLive = !friendsMintLive;
    }

    function setWLSignerAddress(address signer) public onlyOwner {
        whitelistSigner = signer;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function getDigest(uint index) internal view returns(bytes32){
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPERATOR,
                keccak256(abi.encode(
                    ENTRY_TYPEHASH,
                    index,
                    _msgSender()
                ))
            ));
        return digest;
    }

    function isContract(address _addr) private view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}