//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./IDresNFT.sol";

contract DresNFTMinter is Ownable, Pausable, ReentrancyGuard {
    enum MintRound {
        OG_MINT, // 0
        EARLY_MINT, // 1
        WHITELIST_MINT, // 2
        WAITLIST_MINT, // 3
        VIP_MINT, // 4
        TEAM_MINT // 5
    }

    bytes32 public OG_ROOT =
        0xf0d8c4c2f915b9e61defe5cf09a3c823541b2aa234f657e225a29367990bf394;
    bytes32 public TEAM_ROOT =
        0x52fefa64e25d35e3510a4a8b835b55a40bc86fc1f9f054be42ed57ece48c2b9d;
    bytes32 public VIP_ROOT =
        0x7537f59b160272888e1378a8a96cf3ab6a662fc69f901e267a511a9458c40f00;
    bytes32 public EARLY_ROOT =
        0x16ce9e7af5245460e1ff74590bc495b3b09a39442ebd09486410f4fb5112fe06;
    bytes32 public WAITLIST_ROOT =
        0x8d89f048346ccb9a64ecda2bf90be87d8e4b7203c66884141608e1682fa67c64;
    bytes32 public WHITELIST_ROOT =
        0x66a722b929b90b65deae92f7c9e75b1fd979a9a8d002b933e3997fc03eab8200;

    address public DRES_NFT;

    MintRound public mintRound;

    bool public isReservedMint;

    bool public isOGAndEarlyMint;

    bool public isPublicMint;

    uint256 public mintingFee;

    mapping(address => bool) public ogParticipants;

    mapping(address => bool) public earlyParticipants;

    mapping(address => bool) public whitelistParticipants;

    mapping(address => bool) public waitlistParticipants;

    mapping(address => bool) public vipParticipants;

    mapping(address => bool) public participants;

    constructor(address _nft) {
        DRES_NFT = _nft;
        _pause();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Set OG Root
     */
    function setOGRoot(bytes32 _root) external onlyOwner {
        OG_ROOT = _root;
    }

    /**
     * @dev Set Team Root
     */
    function setTeamRoot(bytes32 _root) external onlyOwner {
        TEAM_ROOT = _root;
    }

    /**
     * @dev Set VIP Root
     */
    function setVIPRoot(bytes32 _root) external onlyOwner {
        VIP_ROOT = _root;
    }

    /**
     * @dev Set Waitlist Root
     */
    function setWaitlistRoot(bytes32 _root) external onlyOwner {
        WAITLIST_ROOT = _root;
    }

    /**
     * @dev Set Whitelist Root
     */
    function setWhitelistRoot(bytes32 _root) external onlyOwner {
        WHITELIST_ROOT = _root;
    }

    function toggleRound(
        MintRound _round,
        bool _isReservedMint,
        bool _isOGAndEarlyMint,
        bool _isPublicMint,
        uint256 _mintingFee
    ) external onlyOwner {
        mintRound = _round;
        isReservedMint = _isReservedMint;
        isOGAndEarlyMint = _isOGAndEarlyMint;
        isPublicMint = _isPublicMint;
        mintingFee = _mintingFee;
    }

    function _updateParticipants() private {
        if (mintRound == MintRound.OG_MINT) {
            require(!ogParticipants[_msgSender()], "Already participated");
            ogParticipants[_msgSender()] = true;
        }

        if (mintRound == MintRound.EARLY_MINT) {
            require(!earlyParticipants[_msgSender()], "Already participated");
            earlyParticipants[_msgSender()] = true;
        }

        if (mintRound == MintRound.WHITELIST_MINT) {
            require(
                !whitelistParticipants[_msgSender()],
                "Already participated"
            );
            whitelistParticipants[_msgSender()] = true;
        }

        if (mintRound == MintRound.WAITLIST_MINT) {
            require(
                !waitlistParticipants[_msgSender()],
                "Already participated"
            );
            waitlistParticipants[_msgSender()] = true;
        }

        if (mintRound == MintRound.VIP_MINT) {
            require(!vipParticipants[_msgSender()], "Already participated");
            vipParticipants[_msgSender()] = true;
        }
    }

    function mint(bytes32[] calldata _proofs) external payable whenNotPaused {
        require(msg.value == mintingFee, "Invalid fee");

        if (isOGAndEarlyMint) {
            if (
                MerkleProof.verify(
                    _proofs,
                    OG_ROOT,
                    keccak256(abi.encodePacked(_msgSender()))
                )
            ) {
                require(!ogParticipants[_msgSender()], "Already pariticpated");
                ogParticipants[_msgSender()] = true;
            } else if (
                MerkleProof.verify(
                    _proofs,
                    EARLY_ROOT,
                    keccak256(abi.encodePacked(_msgSender()))
                )
            ) {
                require(
                    !earlyParticipants[_msgSender()],
                    "Already pariticpated"
                );
                earlyParticipants[_msgSender()] = true;
            } else {
                revert("Not Whitelisted");
            }
        } else {
            if (isPublicMint) {
                require(!participants[_msgSender()], "Already participated");
            } else {
                require(
                    MerkleProof.verify(
                        _proofs,
                        getMerkleRoot(),
                        keccak256(abi.encodePacked(_msgSender()))
                    ),
                    "Caller is not whitelisted"
                );
                _updateParticipants();
            }
        }

        if (isReservedMint) {
            getDresNFT().mintReservedNFT(_msgSender(), 1);
        } else {
            getDresNFT().mint(_msgSender(), 1);
        }
    }

    function withdrawETH(address _to) external onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    function setDresNFT(address _nft) external onlyOwner {
        DRES_NFT = _nft;
    }

    function getDresNFT() public view returns (IDresNFT) {
        return IDresNFT(DRES_NFT);
    }

    function getMerkleRoot() public view returns (bytes32) {
        if (mintRound == MintRound.OG_MINT) {
            return OG_ROOT;
        }

        if (mintRound == MintRound.EARLY_MINT) {
            return EARLY_ROOT;
        }

        if (mintRound == MintRound.WHITELIST_MINT) {
            return WHITELIST_ROOT;
        }

        if (mintRound == MintRound.WAITLIST_MINT) {
            return WAITLIST_ROOT;
        }

        if (mintRound == MintRound.VIP_MINT) {
            return VIP_ROOT;
        }

        return bytes32(0);
    }
}