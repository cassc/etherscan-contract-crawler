// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "../util/Ownablearama.sol";
import "../treats/ForgottenRunesTreats.sol";
import "../treats/ForgottenRunesTricks.sol";
import "./NightmareImpTreasureBox.sol";

interface IPunks {
    function punkIndexToAddress(uint256 index) external view returns (address);
}

interface IDelegationRegistry {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

interface IShapeshifter {
    function mint(address receiver, uint256 tokenId) external;
}

contract NightmareImpDoor is EIP712, Ownablearama {
    uint256 public startTimestamp = type(uint256).max;

    ForgottenRunesTricks public tricks;
    ForgottenRunesTreats public treats;
    NightmareImpTreasureBox public treasureBox;

    IDelegationRegistry public delegationRegistry;

    IPunks public punks;

    address public signer;

    address public beasts;
    address public souls;

    mapping(uint256 => bool) public boxClaimedStatus;

    mapping(address => mapping(uint256 => uint256))
        public partnerTokenToClaimsCount;

    mapping(address => uint256) public partnerCollectionToBoxesClaimedCount;

    mapping(address => address) public partnerCollectionToShapeshiftContract;

    mapping(address => bool) public earlyMinters;

    event TrickMinted(
        address indexed to,
        address indexed partnerContract,
        uint256 indexed partnerToken,
        uint256 trickTokenId
    );

    constructor(
        ForgottenRunesTricks _tricks,
        ForgottenRunesTreats _treats,
        NightmareImpTreasureBox _treasureBox,
        IPunks _punks,
        IDelegationRegistry _delegationRegistry,
        address _souls,
        address _beasts
    ) EIP712("NightmareImpDoor", "1") {
        tricks = _tricks;
        treats = _treats;
        treasureBox = _treasureBox;
        punks = _punks;
        delegationRegistry = _delegationRegistry;
        souls = _souls;
        beasts = _beasts;
    }

    function requireSenderIsTokenOwnerAndAllocationNotClaimed(
        address partnerContract,
        uint256 partnerTokenId
    ) public view {
        if (partnerContract == address(punks)) {
            address punkOwner = punks.punkIndexToAddress(partnerTokenId);

            require(
                punkOwner == msg.sender ||
                    delegationRegistry.checkDelegateForToken(
                        msg.sender,
                        punkOwner,
                        address(punks),
                        partnerTokenId
                    ),
                "You do not own this punk"
            );
        } else {
            address nftOwner = IERC721(partnerContract).ownerOf(partnerTokenId);

            require(
                nftOwner == msg.sender ||
                    delegationRegistry.checkDelegateForToken(
                        msg.sender,
                        nftOwner,
                        partnerContract,
                        partnerTokenId
                    ),
                "You do not own this partner token"
            );
        }

        uint256 trickOrTreatAllocation = 1;

        if (partnerContract == souls) {
            trickOrTreatAllocation = 3;
        } else if (partnerContract == beasts) {
            trickOrTreatAllocation = 10;
        }

        require(
            partnerTokenToClaimsCount[partnerContract][partnerTokenId] <
                trickOrTreatAllocation,
            "Max trick or treat allocation already claimed by this token"
        );
    }

    function mintTricksAndBoxes(
        address[] calldata partnerContracts,
        uint256[] calldata partnerTokenIds,
        bool[] calldata isBox,
        uint256[] calldata trickTokenIds,
        bytes calldata signature
    ) public {
        require(
            block.timestamp >= startTimestamp || earlyMinters[msg.sender],
            "Not yet started"
        );

        require(
            partnerContracts.length == partnerTokenIds.length &&
                partnerContracts.length == isBox.length &&
                partnerContracts.length == trickTokenIds.length,
            "Arrays must be same length"
        );

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "TricksAndBoxes(address to,address[] partnerContracts,uint256[] partnerTokenIds,bool[] isBox,uint256[] trickTokenIds)"
                    ),
                    msg.sender,
                    keccak256(abi.encodePacked(partnerContracts)),
                    keccak256(abi.encodePacked(partnerTokenIds)),
                    keccak256(abi.encodePacked(isBox)),
                    keccak256(abi.encodePacked(trickTokenIds))
                )
            )
        );

        require(
            ECDSA.recover(digest, signature) == signer,
            "Signature not by signer"
        );

        for (uint256 i = 0; i < partnerContracts.length; i++) {
            address partnerContract = partnerContracts[i];
            uint256 partnerTokenId = partnerTokenIds[i];

            requireSenderIsTokenOwnerAndAllocationNotClaimed(
                partnerContract,
                partnerTokenId
            );

            partnerTokenToClaimsCount[partnerContract][partnerTokenId]++;

            if (isBox[i]) {
                treasureBox.mint(msg.sender, partnerContract);
            } else {
                tricks.mint(msg.sender, trickTokenIds[i], 1, "");

                IShapeshifter(
                    partnerCollectionToShapeshiftContract[partnerContract]
                ).mint(msg.sender, partnerTokenId);

                emit TrickMinted(
                    msg.sender,
                    partnerContract,
                    partnerTokenId,
                    trickTokenIds[i]
                );
            }
        }
    }

    function mintTreats(
        uint256[] calldata tokenIds,
        uint256[] calldata boxIds,
        bytes calldata signature
    ) public {
        require(
            block.timestamp >= startTimestamp || earlyMinters[msg.sender],
            "Not yet started"
        );

        require(
            tokenIds.length == boxIds.length,
            "Token ids and box ids must be same length"
        );

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256(
                        "Treats(address to,uint256[] tokenIds,uint256[] boxIds)"
                    ),
                    msg.sender,
                    keccak256(abi.encodePacked(tokenIds)),
                    keccak256(abi.encodePacked(boxIds))
                )
            )
        );

        require(
            ECDSA.recover(digest, signature) == signer,
            "Signature not by signer"
        );

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 boxId = boxIds[i];

            require(
                treasureBox.burnedTokenIdToBurner(boxId) == msg.sender,
                "Box must have been burnt by sender"
            );

            require(
                !boxClaimedStatus[boxId],
                "Treat already claimed for this box"
            );

            boxClaimedStatus[boxId] = true;

            treats.mint(msg.sender, tokenIds[i], 1, "");
        }
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setTreats(ForgottenRunesTreats _treats) external onlyOwner {
        treats = _treats;
    }

    function setTricks(ForgottenRunesTricks _tricks) external onlyOwner {
        tricks = _tricks;
    }

    function setPunks(IPunks _punks) external onlyOwner {
        punks = _punks;
    }

    function setDelegationRegistry(IDelegationRegistry _delegationRegistry)
        external
        onlyOwner
    {
        delegationRegistry = _delegationRegistry;
    }

    function setTreasureBox(NightmareImpTreasureBox _treasureBox)
        external
        onlyOwner
    {
        treasureBox = _treasureBox;
    }

    function setSoulsAndBeasts(address _souls, address _beasts)
        external
        onlyOwner
    {
        souls = _souls;
        beasts = _beasts;
    }

    function setPartnerCollectionToShapeshiftContract(
        address partnerContract,
        address shapeshiftContract
    ) external onlyOwner {
        partnerCollectionToShapeshiftContract[
            partnerContract
        ] = shapeshiftContract;
    }

    function setStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        startTimestamp = _startTimestamp;
    }

    function setIsEarlyMinter(address minterAddress, bool isMinter)
        external
        onlyOwner
    {
        earlyMinters[minterAddress] = isMinter;
    }
}