// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/ISignatureVerifier.sol";

contract ShinikiAirdrop is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    // Info interface address signature
    ISignatureVerifier public SIGNATURE_VERIFIER;

    // Info interface address token
    IERC721Upgradeable public tokenShiniki;

    // Info address owner token
    address public ownerToken;

    // type NFT
    bytes32 public constant TYPE_1 = keccak256("TYPE_1");
    bytes32 public constant TYPE_2 = keccak256("TYPE_2");

    // curent index by round,type
    mapping(bytes32 => uint256) public currentIndex;

    mapping(bytes32 => uint256) public total;

    // Info address claimed
    mapping(address => bool) public claimed;

    function initialize(
        IERC721Upgradeable _tokenShiniki,
        address _ownerToken,
        address signatureVerifier
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        tokenShiniki = _tokenShiniki;
        ownerToken = _ownerToken;

        currentIndex[TYPE_1] = 1750;
        currentIndex[TYPE_2] = 5545;

        SIGNATURE_VERIFIER = ISignatureVerifier(signatureVerifier);
    }

    /**
    @notice User claim airdrop
     * @param receiver 'address' receiver for nft
     * @param amount 'uint256' amount
     * @param nonce 'uint256' a number random
     * @param signature 'bytes' a signature to verify data when claim nft
     */
    function claimAirdrop(
        address receiver,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public nonReentrant whenNotPaused {
        require(!claimed[receiver], "ShinikiAirdrop: receiver is claimed");
        require(
            SIGNATURE_VERIFIER.verifyClaimAirdrop(
                receiver,
                amount,
                nonce,
                signature
            ),
            "ShinikiAirdrop: signature claim airdrop is invalid"
        );
        for (uint64 i = 0; i < amount; i++) {
            if (currentIndex[TYPE_1] < 2907) {
                if (currentIndex[TYPE_1] == 2002) {
                    currentIndex[TYPE_1] = 2003;
                }
                IERC721Upgradeable(tokenShiniki).safeTransferFrom(
                    ownerToken,
                    receiver,
                    currentIndex[TYPE_1]
                );
                currentIndex[TYPE_1] = currentIndex[TYPE_1] + 1;
            } else if (currentIndex[TYPE_2] < 6795){
                if (currentIndex[TYPE_2] == 5661) {
                    currentIndex[TYPE_2] = 5662;
                }
                IERC721Upgradeable(tokenShiniki).safeTransferFrom(
                    ownerToken,
                    receiver,
                    currentIndex[TYPE_2]
                );
                currentIndex[TYPE_2] = currentIndex[TYPE_2] + 1;
            } else {
                revert("ShinikiAirdrop: Amount input exceed");
            }
        }
        claimed[receiver] = true;
    }

    /**
    @notice Setting token ERC721
     * @param _tokenShiniki 'address' token
     */
    function setTokenShiniki(IERC721Upgradeable _tokenShiniki)
        external
        onlyOwner
    {
        tokenShiniki = _tokenShiniki;
    }

    /**
    @notice Setting owner token
     * @param _ownerToken 'address' owner token 
     */
    function setTokenOwner(address _ownerToken) external onlyOwner {
        ownerToken = _ownerToken;
    }

    /**
    @notice Setting new address signature
     * @param _signatureVerifier 'address' signature 
     */
    function setSignatureVerifier(address _signatureVerifier)
        external
        onlyOwner
    {
        SIGNATURE_VERIFIER = ISignatureVerifier(_signatureVerifier);
    }

    /**
    @dev Pause the contract
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
    @dev Unpause the contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }
}