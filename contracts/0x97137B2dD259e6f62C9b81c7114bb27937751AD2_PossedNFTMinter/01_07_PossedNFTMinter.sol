//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IPossedNFT.sol";

contract PossedNFTMinter is Ownable, Pausable, ReentrancyGuard {
    /// @dev Possed NFT contract address
    address public POSSED_NFT;

    bool public isPublicSale;
    bool public isWhitelistSale;
    bool public isAirdropSale;

    /// @dev Whitelist MerkleRoot
    bytes32 public WHITELIST_ROOT =
        0xe9be709fe4619cbef249d46d8321f37b0654ca528fe8e65d8fd9d2a743ff675d;

    /// @dev Airdrop MerkleRoot
    bytes32 public AIRDROP_ROOT =
        0x54fdc66561552fc7a4f8bede2acecebdc4db2686bf0dc3c2638d3f4415bd7d81;

    /// @dev Minting Fee
    uint256 public mintingFee;

    mapping(address => bool) public airdropParticipants;
    mapping(address => uint256) public whitelistParticipants;
    mapping(address => uint256) public publicParticipants;

    constructor() {
        _pause();
    }

    /// @dev Set Whitelist MerkleRoot
    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        WHITELIST_ROOT = _root;
    }

    /// @dev Set Airdrop MerkleRoot
    function setAirdropRoot(bytes32 _root) external onlyOwner {
        AIRDROP_ROOT = _root;
    }

    /// @dev Pause minting
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Unpause minting
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Set Possed NFT contract address
    function setPossedNFT(address _possedNFT) external onlyOwner {
        POSSED_NFT = _possedNFT;
    }

    /// @dev Update participant data
    function _updateParticipant(uint256 _amount) private {
        if (isPublicSale) {
            publicParticipants[_msgSender()] += _amount;
        } else {
            if (isAirdropSale) {
                airdropParticipants[_msgSender()] = true;
            } else {
                whitelistParticipants[_msgSender()] += _amount;
            }
        }
    }

    /// @dev Set Minting Round configuration
    function setMintingRound(
        uint256 _fee,
        bool _isPublicSale,
        bool _isWhitelistSale,
        bool _isAirdropSale
    ) external onlyOwner {
        mintingFee = _fee;
        isPublicSale = _isPublicSale;
        isWhitelistSale = _isWhitelistSale;
        isAirdropSale = _isAirdropSale;
    }

    /// @dev Mint PSDD NFT
    function mint(bytes32[] calldata _proofs, uint256 _amount)
        external
        payable
        canParticipate(_amount)
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "Amount should be greater than 0");
        require(mintingFee * _amount == msg.value, "Invalid Minting Fee");

        bytes32 root = isWhitelistSale ? WHITELIST_ROOT : AIRDROP_ROOT;
        if (!isPublicSale) {
            require(
                MerkleProof.verify(
                    _proofs,
                    root,
                    keccak256(abi.encodePacked(_msgSender()))
                ),
                "Not whitelisted"
            );
        }

        _updateParticipant(_amount);
        getPossedNFT().mint(_msgSender(), _amount);
    }

    /// @dev Withdraw ETH from contract
    function withdrawETH(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    /// @dev Get Possed NFT
    function getPossedNFT() public view returns (IPossedNFT) {
        return IPossedNFT(POSSED_NFT);
    }

    modifier canParticipate(uint256 _amount) {
        bool isParticipated;
        if (isPublicSale) {
            isParticipated = publicParticipants[_msgSender()] + _amount > 2
                ? true
                : false;
        } else {
            if (isAirdropSale) {
                require(_amount == 1, "Only 1 mint is available for airdrop");
                isParticipated = airdropParticipants[_msgSender()];
            } else {
                isParticipated = whitelistParticipants[_msgSender()] + _amount >
                    2
                    ? true
                    : false;
            }
        }

        require(!isParticipated, "Already participated");
        _;
    }
}