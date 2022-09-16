/* solhint-disable quotes */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IAnonymice.sol";
import "./IAnonymiceBreeding.sol";
import "./IDNAChip.sol";
import "./AnonymiceLibrary.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract BadgesVerifier is Ownable {
    struct CollabBadge {
        address tokenAddress;
        uint256 badgeId;
    }

    struct WalletCollection {
        bool glitched;
        bool irradiated;
        bool jimDangles;
        bool astronaut;
        bool vr;
        bool eye3d;
        bool hoodie;
        bool bane;
        bool halo;
        bool skele;
        bool alien;
        bool robot;
        bool druid;
        bool freak;
    }

    uint256 public constant CHARACTER_INDEX = 8;
    uint256 public constant EARRINGS_INDEX = 4;
    uint256 public constant HAT_INDEX = 1;
    uint256 public constant EYES_INDEX = 5;

    address public cheethAddress;
    address public genesisAddress;
    address public babiesAddress;
    address public badgesAddress;
    address public dnaChipAddress;
    CollabBadge[] public collabBadges;

    function claimableWalletBadges(address wallet) external view returns (uint256[] memory) {
        uint256[] memory genesisMice = getGenesisRelevantTokens(wallet);
        uint256[] memory babyMice = getBabiesRelevantTokens(wallet);

        return _claimableBadges(genesisMice, babyMice, wallet);
    }

    function claimableBadges(
        uint256[] memory genesisMice,
        uint256[] memory babyMice,
        address wallet
    ) external view returns (uint256[] memory) {
        return _claimableBadges(genesisMice, babyMice, wallet);
    }

    function getRelevantMice(address wallet) external view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory relevantGenesis = getGenesisRelevantTokens(wallet);
        uint256[] memory relevantBabies = getBabiesRelevantTokens(wallet);
        return (relevantGenesis, relevantBabies);
    }

    function getCollabBadges() external view returns (CollabBadge[] memory) {
        return collabBadges;
    }

    function _getGenesisCollectorData(uint256[] memory tokens, address wallet)
        internal
        view
        returns (WalletCollection memory walletCollection)
    {
        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokenId = tokens[index];
            require(IAnonymice(genesisAddress).ownerOf(tokenId) == wallet, "not mouse owner");
            string memory tokenHash = IAnonymice(genesisAddress)._tokenIdToHash(tokenId);
            uint256[9] memory traits = _parseTraits(tokenHash);

            if (traits[CHARACTER_INDEX] == 0) {
                walletCollection.glitched = true;
            } else if (traits[CHARACTER_INDEX] == 1) {
                walletCollection.irradiated = true;
            }

            if (traits[EARRINGS_INDEX] == 0) {
                walletCollection.jimDangles = true;
            }

            if (traits[HAT_INDEX] == 0) {
                walletCollection.astronaut = true;
            } else if (traits[HAT_INDEX] == 1) {
                walletCollection.bane = true;
            } else if (traits[HAT_INDEX] == 5) {
                walletCollection.halo = true;
            }

            if (traits[EYES_INDEX] == 0) {
                walletCollection.vr = true;
            }
        }

        return walletCollection;
    }

    function _claimableBadges(
        uint256[] memory genesisMice,
        uint256[] memory babyMice,
        address wallet
    ) internal view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](15 + collabBadges.length);
        uint256 resultIndex;
        uint256 cheethBalance = IERC20(cheethAddress).balanceOf(wallet);
        WalletCollection memory genesisCollection = _getGenesisCollectorData(genesisMice, wallet);
        WalletCollection memory babiesCollection = _getBabiesCollectorData(babyMice, wallet);
        for (uint256 collabIndex = 0; collabIndex < collabBadges.length; collabIndex++) {
            CollabBadge memory collabBadge = collabBadges[collabIndex];
            if (
                IERC721Enumerable(genesisAddress).balanceOf(wallet) > 0 &&
                IERC721Enumerable(collabBadge.tokenAddress).balanceOf(wallet) > 0
            ) {
                result[resultIndex++] = collabBadge.badgeId;
            }
        }

        if (cheethBalance >= 10000 ether) {
            // 2 => 10k cheeth
            result[resultIndex++] = 2;
        }
        if (cheethBalance >= 25000 ether) {
            // 7 => 25k cheeth
            result[resultIndex++] = 7;
        }
        if (cheethBalance >= 50000 ether) {
            // 17 => 50k cheeth
            result[resultIndex++] = 17;
        }
        if (
            genesisCollection.jimDangles &&
            genesisCollection.glitched &&
            genesisCollection.astronaut &&
            genesisCollection.irradiated &&
            genesisCollection.vr
        ) {
            // 24 => Own genesis mice with Jd, glitched, astro, irradiated, VR traits
            result[resultIndex++] = 24;
        }
        if (
            babiesCollection.glitched &&
            babiesCollection.irradiated &&
            babiesCollection.vr &&
            babiesCollection.eye3d &&
            babiesCollection.hoodie
        ) {
            // 14 => Own baby mice with glitched, irradiated, vr, 3d, hoodie traits
            result[resultIndex++] = 14;
        }
        if (
            babiesCollection.freak &&
            babiesCollection.robot &&
            babiesCollection.skele &&
            babiesCollection.druid &&
            babiesCollection.alien
        ) {
            // 8 => Hold 1 of all 5 evolved baby mice types
            result[resultIndex++] = 8;
        }

        if (genesisCollection.glitched) {
            // 25 => Hold a Gl1tch3d gen mouse
            result[resultIndex++] = 25;
        }
        if (genesisCollection.astronaut) {
            // 21 => Hold an astro gen mouse
            result[resultIndex++] = 21;
        }
        if (genesisCollection.bane) {
            // 15 => Hold a bane gen mouse
            result[resultIndex++] = 15;
        }
        if (babiesCollection.hoodie) {
            // 9 => Hold a hoodie baby mouse
            result[resultIndex++] = 9;
        }
        if (babiesCollection.halo && genesisCollection.halo) {
            // 11 => Hold Halo Gen + Baby
            result[resultIndex++] = 11;
        }
        if (babiesCollection.skele) {
            // 5 => Hold a skele baby mouse
            result[resultIndex++] = 5;
        }

        return result;
    }

    function getGenesisRelevantTokens(address wallet) public view returns (uint256[] memory) {
        uint256[] memory tokens = _getWalletTokens(genesisAddress, wallet);
        uint256[] memory rawRelevantTokens = new uint256[](tokens.length);
        uint256 relevantIndex;

        for (uint256 index = 0; index < tokens.length; index++) {
            string memory tokenHash = IAnonymice(genesisAddress)._tokenIdToHash(tokens[index]);
            uint256[9] memory traits = _parseTraits(tokenHash);
            bool isRelevant;

            if (traits[CHARACTER_INDEX] == 0) {
                isRelevant = true;
            } else if (traits[CHARACTER_INDEX] == 1) {
                isRelevant = true;
            }

            if (traits[EARRINGS_INDEX] == 0) {
                isRelevant = true;
            }

            if (traits[HAT_INDEX] == 0) {
                isRelevant = true;
            } else if (traits[HAT_INDEX] == 1) {
                isRelevant = true;
            } else if (traits[HAT_INDEX] == 5) {
                isRelevant = true;
            }

            if (traits[EYES_INDEX] == 0) {
                isRelevant = true;
            }

            if (isRelevant) {
                rawRelevantTokens[relevantIndex++] = tokens[index];
            }
        }
        uint256[] memory relevantTokens = new uint256[](relevantIndex);
        for (uint256 index = 0; index < relevantTokens.length; index++) {
            relevantTokens[index] = rawRelevantTokens[index];
        }

        return relevantTokens;
    }

    function _getBabiesCollectorData(uint256[] memory tokens, address wallet)
        internal
        view
        returns (WalletCollection memory walletCollection)
    {
        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokenId = tokens[index];
            require(IAnonymiceBreeding(babiesAddress).ownerOf(tokenId) == wallet, "not mouse owner");
            bool isRevelaed = IAnonymiceBreeding(babiesAddress)._tokenToRevealed(tokenId);
            if (!isRevelaed) continue;
            uint256 chipId = IDNAChip(dnaChipAddress).breedingIdToEvolutionPod(tokenId);
            if (chipId == 0) {
                string memory tokenHash = IAnonymiceBreeding(babiesAddress)._tokenIdToHash(tokenId);
                uint256[9] memory traits = _parseTraits(tokenHash);

                if (traits[CHARACTER_INDEX] == 0) {
                    walletCollection.glitched = true;
                } else if (traits[CHARACTER_INDEX] == 1) {
                    walletCollection.irradiated = true;
                }

                if (traits[EYES_INDEX] == 0) {
                    walletCollection.vr = true;
                } else if (traits[EYES_INDEX] == 1) {
                    walletCollection.eye3d = true;
                }

                if (traits[HAT_INDEX] == 8) {
                    walletCollection.hoodie = true;
                } else if (traits[HAT_INDEX] == 5) {
                    walletCollection.halo = true;
                }
            } else {
                uint8[8] memory traits = IDNAChip(dnaChipAddress).getTraitsArray(chipId);
                uint8 character = traits[0];

                if (character == 0) {
                    walletCollection.freak = true;
                } else if (character == 1) {
                    walletCollection.robot = true;
                } else if (character == 2) {
                    walletCollection.druid = true;
                } else if (character == 3) {
                    walletCollection.skele = true;
                } else if (character == 4) {
                    walletCollection.alien = true;
                }
            }
        }

        return walletCollection;
    }

    function getBabiesRelevantTokens(address wallet) public view returns (uint256[] memory) {
        uint256[] memory tokens = _getWalletTokens(babiesAddress, wallet);
        uint256[] memory rawRelevantTokens = new uint256[](tokens.length);
        uint256 relevantIndex;

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 tokenId = tokens[index];
            bool isRevelaed = IAnonymiceBreeding(babiesAddress)._tokenToRevealed(tokenId);
            if (!isRevelaed) continue;
            uint256 chipId = IDNAChip(dnaChipAddress).breedingIdToEvolutionPod(tokenId);
            bool isRelevant;
            if (chipId == 0) {
                string memory tokenHash = IAnonymiceBreeding(babiesAddress)._tokenIdToHash(tokenId);
                uint256[9] memory traits = _parseTraits(tokenHash);

                if (traits[CHARACTER_INDEX] == 0) {
                    isRelevant = true;
                } else if (traits[CHARACTER_INDEX] == 1) {
                    isRelevant = true;
                }

                if (traits[EYES_INDEX] == 0) {
                    isRelevant = true;
                } else if (traits[EYES_INDEX] == 1) {
                    isRelevant = true;
                }

                if (traits[HAT_INDEX] == 8) {
                    isRelevant = true;
                } else if (traits[HAT_INDEX] == 5) {
                    isRelevant = true;
                }
            } else {
                isRelevant = true;
            }

            if (isRelevant) {
                rawRelevantTokens[relevantIndex++] = tokenId;
            }
        }
        uint256[] memory relevantTokens = new uint256[](relevantIndex);
        for (uint256 index = 0; index < relevantTokens.length; index++) {
            relevantTokens[index] = rawRelevantTokens[index];
        }

        return relevantTokens;
    }

    function _getWalletTokens(address tokenWallet, address wallet) internal view returns (uint256[] memory) {
        uint256 balance = IERC721Enumerable(tokenWallet).balanceOf(wallet);
        uint256[] memory tokens = new uint256[](balance);
        for (uint256 index = 0; index < tokens.length; index++) {
            tokens[index] = IERC721Enumerable(tokenWallet).tokenOfOwnerByIndex(wallet, index);
        }
        return tokens;
    }

    function _parseTraits(string memory tokenHash) internal pure returns (uint256[9] memory traits) {
        for (uint8 i = 0; i < traits.length; i++) {
            uint8 trait = AnonymiceLibrary.parseInt(AnonymiceLibrary.substring(tokenHash, i, i + 1));
            traits[i] = trait;
        }
    }

    function addCollab(address _collabAddress, uint256 _badgeId) external onlyOwner {
        collabBadges.push(CollabBadge(_collabAddress, _badgeId));
    }

    function removeCollab(address _collabAddress) external onlyOwner {
        uint256 indexToRemove = 0;
        bool itemFound;
        for (uint256 index = 0; index < collabBadges.length; index++) {
            if (collabBadges[index].tokenAddress == _collabAddress) {
                itemFound = true;
                indexToRemove = index;
                break;
            }
        }
        if (itemFound) {
            CollabBadge memory collabBadge = collabBadges[collabBadges.length - 1];
            collabBadges[indexToRemove] = collabBadge;
            collabBadges.pop();
        }
    }

    function setAddresses(
        address _cheethAddress,
        address _genesisAddress,
        address _babiesAddress,
        address _badgesAddress,
        address _dnaChipAddress
    ) external onlyOwner {
        cheethAddress = _cheethAddress;
        genesisAddress = _genesisAddress;
        babiesAddress = _babiesAddress;
        badgesAddress = _badgesAddress;
        dnaChipAddress = _dnaChipAddress;
    }
}
/* solhint-enable quotes */