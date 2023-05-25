//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./PublicCryptopunksData.sol";
import "./IOtherPunksConfiguration.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract OtherPunks is ERC721, Ownable {
    event BurnOriginalPunk (
        uint16 originalPunkId
    );

    PublicCryptopunksData public punksData;
    IOtherPunksConfiguration public otherPunksConfiguration;
    bool public contractSealed = false;

    // Punks
    uint256 public constant firstPunkId = 10000;
    uint256 public nextPunkId = firstPunkId;
    mapping(uint256 => uint96) public punkIdToAssets;
    mapping(uint96 => uint256) public punkAssetsToId;
    mapping(uint96 => bool) public blockedAssets;

    // Mining
    uint88 public difficultyTarget = 0;
    uint32 public numMined = 0;
    uint96 public lastMinedPunkAssets = 0x0;

    // Base
    uint16 public constant baseRangeMax = 9997;
    uint16[][] public baseRanges;
    uint256 public constant baseMask = 0xffff << 240;
    uint8 public constant baseShift = 240;
    mapping(uint8 => uint8) public baseToGender;

    // Slots
    uint16[][] public genderToSlotMaxes;
    uint16[][][][] public genderToSlotToAttributeRanges;
    uint256[] public slotMasks;
    uint16[] public slotShifts;

    // Misc
    mapping(uint8 => bool) public disallowedOnAlienOrApe;

    modifier unsealed() {
        require(!contractSealed, "Contract sealed.");
        _;
    }

    modifier mustBeSealed() {
        require(contractSealed, "Contract unsealed.");
        _;
    }

    constructor(
        PublicCryptopunksData _punksData,
        IOtherPunksConfiguration _otherPunksConfiguration
    ) ERC721("OtherPunks", "OPUNKS") Ownable() {
        punksData = _punksData;
        otherPunksConfiguration = _otherPunksConfiguration;

        baseToGender[1] = 0;
        baseToGender[2] = 0;
        baseToGender[3] = 0;
        baseToGender[4] = 0;
        baseToGender[5] = 1;
        baseToGender[6] = 1;
        baseToGender[7] = 1;
        baseToGender[8] = 1;
        baseToGender[9] = 0;
        baseToGender[10] = 0;
        baseToGender[11] = 0;

        baseRanges.push([1509, 1]);
        baseRanges.push([3018, 2]);
        baseRanges.push([4527, 3]);
        baseRanges.push([6036, 4]);
        baseRanges.push([6996, 5]);
        baseRanges.push([7956, 6]);
        baseRanges.push([8916, 7]);
        baseRanges.push([9876, 8]);
        baseRanges.push([9964, 9]);
        baseRanges.push([9988, 10]);
        baseRanges.push([9997, 11]);

        uint8[] memory slotWidths = new uint8[](11);
        slotWidths[0] = 8;
        slotWidths[1] = 16;
        slotWidths[2] = 16;
        slotWidths[3] = 16;
        slotWidths[4] = 16;
        slotWidths[5] = 16;
        slotWidths[6] = 8;
        slotWidths[7] = 16;
        slotWidths[8] = 16;
        slotWidths[9] = 16;
        slotWidths[10] = 8;

        uint16 takenSpace = 16;
        for (uint8 i = 0; i < slotWidths.length; i++) {
            takenSpace += slotWidths[i];
            slotShifts.push(256 - takenSpace);
            slotMasks.push(((uint256(2)**slotWidths[i]) - 1) << slotShifts[i]);
        }

        difficultyTarget = otherPunksConfiguration.getDifficultyTargetAtIndex(
            0
        );

        disallowedOnAlienOrApe[27] = true;
        disallowedOnAlienOrApe[12] = true;
        disallowedOnAlienOrApe[55] = true;
        disallowedOnAlienOrApe[30] = true;
        disallowedOnAlienOrApe[23] = true;
        disallowedOnAlienOrApe[18] = true;
    }

    /*
    When I try to remove this function, only with the optimizer enabled, I get:
    CompilerError: Stack too deep when compiling inline assembly: Variable tail is 3 slot(s) too deep inside the stack.
    Error HH600: Compilation failed
    */
    function getSlotShifts() public view returns (uint16[] memory) {
        return slotShifts;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.otherpunks.org/metadata/";
    }

    function seedToPunkAssets(uint256 seed) external view returns (uint96) {
        uint96 punk = 0;
        uint16 baseRange = uint16((seed & baseMask) >> baseShift) %
            baseRangeMax;
        uint8 base;
        for (uint8 i = 0; i < baseRanges.length; i++) {
            if (i == 0 && baseRange < baseRanges[i][0]) {
                base = uint8(baseRanges[i][1]);
                break;
            }

            if (
                baseRange >= baseRanges[i][0] &&
                baseRange < baseRanges[i + 1][0]
            ) {
                base = uint8(baseRanges[i + 1][1]);
                break;
            }
        }

        punk = punk | (uint96(base) << 88);
        uint8 gender = baseToGender[base];

        for (uint8 slotIndex = 0; slotIndex < 11; slotIndex++) {
            uint16 attributeRange = uint16(
                ((seed & slotMasks[slotIndex]) >> slotShifts[slotIndex])
            ) % genderToSlotMaxes[gender][slotIndex];
            uint16[][] storage attributeRanges = genderToSlotToAttributeRanges[
                gender
            ][slotIndex];

            uint8 attribute;
            for (uint8 j = 0; j < attributeRanges.length; j++) {
                if (j == 0 && attributeRange < attributeRanges[j][0]) {
                    attribute = uint8(attributeRanges[j][1]);
                    break;
                }

                if (
                    attributeRange >= attributeRanges[j][0] &&
                    attributeRange < attributeRanges[j + 1][0]
                ) {
                    attribute = uint8(attributeRanges[j + 1][1]);
                    break;
                }
            }

            if ((base == 10 || base == 11) && disallowedOnAlienOrApe[attribute]) {
                attribute = 0;
            }

            punk = punk | (uint96(attribute) << (88 - (8 * (slotIndex + 1))));
        }

        return punk;
    }

    function render(uint256 punkId) public view returns (bytes memory) {
        require(ERC721._exists(punkId), "PunkId does not exist.");
        return punksData.render(punkIdToAssets[punkId]);
    }

    function renderSvg(uint256 punkId) public view returns (string memory) {
        require(ERC721._exists(punkId), "PunkId does not exist.");
        return punksData.renderSvg(punkIdToAssets[punkId]);
    }

    function isValidNonce(uint256 nonce) public view returns (bool) {
        uint256 combined = uint256(
            keccak256(
                abi.encodePacked(
                    lastMinedPunkAssets,
                    uint72(uint160(msg.sender)),
                    uint88(nonce)
                )
            )
        );

        return uint88(combined) < difficultyTarget;
    }

    // Non-view functions

    function addAttributeRanges(
        uint16[] memory slotMaxes,
        uint16[][][] memory slotRanges
    ) external onlyOwner unsealed {
        genderToSlotMaxes.push(slotMaxes);
        genderToSlotToAttributeRanges.push(slotRanges);

        if (genderToSlotMaxes.length == 2) {
            contractSealed = true;
        }
    }

    function mint(uint256 _nonce) external mustBeSealed {
        // [LAST PUNK ID (96 bits)][SENDER ADDR (72 bits)][NONCE (88 bits)]
        uint256 combined = uint256(
            keccak256(
                abi.encodePacked(
                    lastMinedPunkAssets,
                    uint72(uint160(msg.sender)),
                    uint88(_nonce)
                )
            )
        );

        if (uint88(combined) >= difficultyTarget) {
            revert("Bad nonce");
        }

        uint256 seed;
        if (
            difficultyTarget <=
            otherPunksConfiguration.getHardDifficultyTarget()
        ) {
            seed = combined;
        } else {
            seed = uint256(
                keccak256(
                    abi.encodePacked(
                            otherPunksConfiguration.getBlockHash(
                                otherPunksConfiguration.getBlockNumber() - 1
                            )
                        )
                    )
                );
        }

        uint96 punkAssets = this.seedToPunkAssets(seed);

        if (punkAssetsToId[punkAssets] != 0 || blockedAssets[punkAssets]) {
            revert("Punk already mined");
        }

        uint256 punkId = nextPunkId;
        ERC721._safeMint(msg.sender, punkId);
        punkIdToAssets[punkId] = punkAssets;
        punkAssetsToId[punkAssets] = punkId;
        nextPunkId += 1;
        numMined += 1;
        lastMinedPunkAssets = punkAssets;

        uint88 newTarget = otherPunksConfiguration.getDifficultyTargetAtIndex(
            numMined
        );
        if (newTarget > 0) {
            difficultyTarget = newTarget;
        }

        // Founders reward
        if (numMined % 33 == 0) {
            uint96 founderPunkAssets = this.seedToPunkAssets(uint256(keccak256(abi.encodePacked(seed))));

            if (punkAssetsToId[founderPunkAssets] == 0) {
                uint256 founderPunkId = nextPunkId;
                ERC721._safeMint(Ownable.owner(), founderPunkId);
                punkIdToAssets[founderPunkId] = founderPunkAssets;
                punkAssetsToId[founderPunkAssets] = founderPunkId;
                nextPunkId += 1;
                numMined += 1;
                lastMinedPunkAssets = founderPunkAssets;

                uint88 _newTarget = otherPunksConfiguration
                    .getDifficultyTargetAtIndex(numMined);
                if (_newTarget > 0) {
                    difficultyTarget = _newTarget;
                }
            }
        }
    }

    function removeTrainingWheels() public {
        require(
            otherPunksConfiguration.getBlockNumber() >=
                otherPunksConfiguration
                    .getHardDifficultyBlockNumberDeadline() &&
                difficultyTarget >
                otherPunksConfiguration.getHardDifficultyTarget()
        );

        difficultyTarget = otherPunksConfiguration.getHardDifficultyTarget();
    }

    function blockUnminedOriginalPunk(
        uint96 punkAssets,
        uint16 originalPunkIndex
    ) public {
        require(punkAssetsToId[punkAssets] == 0);
        require(
            punksData.isPackedEqualToOriginalPunkIndex(
                punkAssets,
                originalPunkIndex
            )
        );
        blockedAssets[punkAssets] = true;
        emit BurnOriginalPunk(originalPunkIndex);
    }

    function burnAlreadyMinedOriginalPunk(
        uint256 punkId,
        uint16 originalPunkIndex
    ) public {
        address owner = ERC721.ownerOf(punkId);
        require(
            owner != 0x0000000000000000000000000000000000000001,
            "Already burned"
        );
        uint96 punkAssets = punkIdToAssets[punkId];
        require(
            punksData.isPackedEqualToOriginalPunkIndex(
                punkAssets,
                originalPunkIndex
            )
        );
        ERC721._transfer(
            owner,
            0x0000000000000000000000000000000000000001,
            punkId
        );
        emit BurnOriginalPunk(originalPunkIndex);
    }
}