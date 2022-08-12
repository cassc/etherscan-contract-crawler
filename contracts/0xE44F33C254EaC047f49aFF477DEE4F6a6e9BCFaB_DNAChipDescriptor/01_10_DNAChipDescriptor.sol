// SPDX-License-Identifier: MIT
/* solhint-disable quotes */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";
import "./AnonymiceLibrary.sol";
import "./RedactedLibrary.sol";
import "./IAnonymiceBreeding.sol";

contract DNAChipDescriptor is Ownable {
    address public dnaChipAddress;
    address public evolutionTraitsAddress;
    address public breedingAddress;

    uint8 public constant BASE_INDEX = 0;
    uint8 public constant EARRINGS_INDEX = 1;
    uint8 public constant EYES_INDEX = 2;
    uint8 public constant HATS_INDEX = 3;
    uint8 public constant MOUTHS_INDEX = 4;
    uint8 public constant NECKS_INDEX = 5;
    uint8 public constant NOSES_INDEX = 6;
    uint8 public constant WHISKERS_INDEX = 7;

    constructor() {}

    function setAddresses(
        address _dnaChipAddress,
        address _evolutionTraitsAddress,
        address _breedingAddress
    ) external onlyOwner {
        dnaChipAddress = _dnaChipAddress;
        evolutionTraitsAddress = _evolutionTraitsAddress;
        breedingAddress = _breedingAddress;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        uint8[8] memory traits = RedactedLibrary.representationToTraitsArray(
            IDNAChip(dnaChipAddress).tokenIdToTraits(_tokenId)
        );
        bool isEvolutionPod = IDNAChip(dnaChipAddress).isEvolutionPod(_tokenId);
        string memory name;
        string memory image;
        if (!isEvolutionPod) {
            name = string(abi.encodePacked('{"name": "DNA Chip #', AnonymiceLibrary.toString(_tokenId)));
            image = AnonymiceLibrary.encode(bytes(getChipSVG(traits)));
        } else {
            name = string(abi.encodePacked('{"name": "Evolution Pod #', AnonymiceLibrary.toString(_tokenId)));
            image = AnonymiceLibrary.encode(bytes(getEvolutionPodSVG(traits)));
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    image,
                                    '","attributes": [',
                                    IEvolutionTraits(evolutionTraitsAddress).getMetadata(traits),
                                    ', {"trait_type" :"Assembled", "value" : "',
                                    isEvolutionPod ? "Yes" : "No",
                                    '"}',
                                    "]",
                                    ', "description": "DNA Chips is a collection of 3,550 DNA Chips. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function tokenBreedingURI(uint256 _tokenId, uint256 _breedingId) public view returns (string memory) {
        uint256 traitsRepresentation = IDNAChip(dnaChipAddress).tokenIdToTraits(_tokenId);
        uint8[8] memory traits = RedactedLibrary.representationToTraitsArray(traitsRepresentation);
        string memory name = string(abi.encodePacked('{"name": "Baby Mouse #', AnonymiceLibrary.toString(_breedingId)));
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    AnonymiceLibrary.encode(bytes(getBreedingSVG(traits))),
                                    '","attributes": [',
                                    IEvolutionTraits(evolutionTraitsAddress).getMetadata(traits),
                                    "]",
                                    ', "description": "Anonymice Breeding is a collection of 3,550 baby mice. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function tokenIncubatorURI(uint256 _breedingId) public view returns (string memory) {
        string memory name = string(
            abi.encodePacked('{"name": "Evolved Incubator #', AnonymiceLibrary.toString(_breedingId))
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    AnonymiceLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    AnonymiceLibrary.encode(bytes(getEvolvedIncubatorSVG())),
                                    '","attributes":',
                                    evolvedIncubatorIdToAttributes(_breedingId),
                                    ', "description": "Anonymice Breeding is a collection of 3,550 baby mice. All the metadata and images are generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function evolvedIncubatorIdToAttributes(uint256 _breedingId) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type": "Parent #1 ID", "value": "',
                    AnonymiceLibrary.toString(
                        IAnonymiceBreeding(breedingAddress)._tokenToIncubator(_breedingId).parentId1
                    ),
                    '"},{"trait_type": "Parent #2 ID", "value": "',
                    AnonymiceLibrary.toString(
                        IAnonymiceBreeding(breedingAddress)._tokenToIncubator(_breedingId).parentId2
                    ),
                    '"}, {"trait_type" :"revealed","value" : "Not Revealed Evolution"}]'
                )
            );
    }

    function getChipSVG(uint8[8] memory traits) internal view returns (string memory) {
        string memory imageTag = IEvolutionTraits(evolutionTraitsAddress).getDNAChipSVG(traits[0]);
        return
            string(
                abi.encodePacked(
                    '<svg id="dna-chip" width="100%" height="100%" version="1.1" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    imageTag,
                    '<g transform="translate(43, 33) scale(1.5)">',
                    IEvolutionTraits(evolutionTraitsAddress).getTraitsImageTagsByOrder(
                        traits,
                        [
                            BASE_INDEX,
                            NECKS_INDEX,
                            MOUTHS_INDEX,
                            NOSES_INDEX,
                            WHISKERS_INDEX,
                            EYES_INDEX,
                            EARRINGS_INDEX,
                            HATS_INDEX
                        ]
                    ),
                    "</g>",
                    "</svg>"
                )
            );
    }

    function getEvolutionPodSVG(uint8[8] memory traits) public view returns (string memory) {
        uint8 base = traits[0];
        string memory preview;
        if (base == 0) {
            // FREAK
            preview = '<g transform="translate(75,69)">';
        } else if (base == 1) {
            // ROBOT
            preview = '<g transform="translate(85,74)">';
        } else if (base == 2) {
            // DRUID
            preview = '<g transform="translate(70,80)">';
        } else if (base == 3) {
            // SKELE
            preview = '<g transform="translate(19,56)">';
        } else if (base == 4) {
            // ALIEN
            preview = '<g transform="translate(75,58)">';
        }
        preview = string(
            abi.encodePacked(
                preview,
                IEvolutionTraits(evolutionTraitsAddress).getTraitsImageTagsByOrder(
                    traits,
                    [
                        BASE_INDEX,
                        NECKS_INDEX,
                        MOUTHS_INDEX,
                        NOSES_INDEX,
                        WHISKERS_INDEX,
                        EYES_INDEX,
                        EARRINGS_INDEX,
                        HATS_INDEX
                    ]
                ),
                "</g>"
            )
        );

        string
            memory result = '<svg id="evolution-pod" width="100%" height="100%" version="1.1" viewBox="0 0 125 125" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';

        result = string(
            abi.encodePacked(
                result,
                IEvolutionTraits(evolutionTraitsAddress).getEvolutionPodImageTag(base),
                preview,
                "</svg>"
            )
        );
        return result;
    }

    function getBreedingSVG(uint8[8] memory traits) public view returns (string memory) {
        string
            memory result = '<svg id="ebaby" width="100%" height="100%" version="1.1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';

        result = string(
            abi.encodePacked(
                result,
                _buildTraits(traits),
                "<style>#ebaby{image-rendering: pixelated; transform: translate3d(0,0,0);}</style>",
                "</svg>"
            )
        );
        return result;
    }

    function _buildTraits(uint8[8] memory traits) internal view returns (string memory) {
        uint8 base = traits[0];
        string memory traitImages;
        string
            memory prefix = '<foreignObject x="0" y="0" width="100%" height="100%"><img xmlns="http://www.w3.org/1999/xhtml" src=';
        string memory sufix = "</foreignObject>";
        uint8[8] memory traitsOrder = [
            BASE_INDEX,
            NECKS_INDEX,
            MOUTHS_INDEX,
            NOSES_INDEX,
            WHISKERS_INDEX,
            EYES_INDEX,
            EARRINGS_INDEX,
            HATS_INDEX
        ];

        for (uint256 index = 0; index < traitsOrder.length; index++) {
            uint8 currentTrait = traitsOrder[index];
            uint8 traitValue = traits[currentTrait];
            (string memory svgImageTag, ) = IEvolutionTraits(evolutionTraitsAddress).traitDataByCharacter(
                base,
                currentTrait,
                traitValue
            );
            if (bytes(svgImageTag).length > 0) {
                traitImages = string(abi.encodePacked(traitImages, prefix, substring(svgImageTag, 112), sufix));
            }
        }
        return traitImages;
    }

    function substring(string memory str, uint256 startIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint256 endIndex = strBytes.length;
        if (endIndex == 0) return "";
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function getEvolvedIncubatorSVG() public view returns (string memory) {
        string
            memory result = '<svg id="eincubator" width="100%" height="100%" version="1.1" viewBox="0 0 52 52" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';

        result = string(
            abi.encodePacked(result, IEvolutionTraits(evolutionTraitsAddress).evolvedIncubatorImage(), "</svg>")
        );
        return result;
    }
}

/* solhint-enable quotes */