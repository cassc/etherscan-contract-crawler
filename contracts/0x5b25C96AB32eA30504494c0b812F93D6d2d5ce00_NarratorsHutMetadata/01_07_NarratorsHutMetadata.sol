//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/*
.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。

                                                 ▄┐
                                   ▓▌        ▓▓╓██▌
                                   ████▓██████████`
                                  ▄████████████████µ
                                ▄█████████████╬█████▄Γ
                             ╓▓█████████████▓╬╬██████▓▄
                          ,▄████████████▓▓▓▒╬╠╬████████▓,.......
                      ,▄▄██████████████▓▓█▒╬▒╠╣╬▓▓╬╠▓▓▓██▓▄░░░░░.┌
                   ..'╙╙│▀▀██████▓████████▓▓▓▓▓▓▓▓▓╣▓▓▓█▀╙╙▀░░░░░│.
                  .¡░░░░╬╣▒███╬▓╫▓╫▓╫████▓██▓▓▓▓████████▒ε░░╓▓▓▓▓▀⌐
                 ┌.¡░░░░╟╫╣██████████████▓██████▓▓▓▓▓█████████▓████▌─
                '.│░░░Q▄▓█████████████████████▓▓█▓▓██████████▓▓████▓▄▄
                 ,▄▓▓████████████████████▓█▓█▓▓▓▓█▓▒╚╚█▓▓██▓▓▓▓██████▓▓═
               "╠╠▀████████████████████▓▓█▓█▓▓▓█▓▓▓░░▒╣╬▓╣██▓▓▓█████▌   φε
                └╠░████╣██╬██▓█████████▓▓▓▓▓▓███▓▓▓╬╬╬╣▓▓╣█▓████████▓████▒
              ▐▌╓╠▄╣████████▓▓██████████████████▓▓▓╬▓▓▓╬▓╣▓██████▓██▓▀▀▀▀░╛
              ║█████████████████████████████████▓▓╣██▓█╣▓╣▓▓▓╣╬╣╬╬╬╬▒╠│░'"
              ╚████████████████████████████████▓▓╣╬▓▀▓█▓▓╣▓▓▓▓▓▓▓▓╬╬╠▒░.
            ,Q ╓▄░░╬╚███████████████████████████▓╫▓▓▓███▓▓╬▓█▓▓╬▓▓╬╬▒░░
           ]██▌ └ⁿ"░╚╚░╚╚▀▀▀██▀█████████████████▓▓▓█▓█▓▓███▓▓▓▓╬╣▓╬╬▀Γ=
             ¬       '''"░""Γ"░Γ░░Γ╙╙▀▀▀▀█████████████╬███▓╬▓▓██╬╬▓░░░'
                                     ' `"""""░╚╙╟╚╚╚╠╣╬╬╬╬╬▓▓▀╬╩▒▓▓▓∩'
                                                    ` "└└╙"╙╙Γ""`

                                                       s                                            _                                 
                         ..                           :8                                           u                                  
             .u    .    @L           .d``            .88           u.                       u.    88Nu.   u.                u.    u.  
      .    .d88B :@8c  9888i   .dL   @8Ne.   .u     :888ooo  ...ue888b           .    ...ue888b  '88888.o888c      .u     [email protected] [email protected]
 .udR88N  ="8888f8888r `Y888k:*888.  %8888:[email protected]  -*8888888  888R Y888r     .udR88N   888R Y888r  ^8888  8888   ud8888.  ^"8888""8888"
<888'888k   4888>'88"    888E  888I   `888I  888.   8888     888R I888>    <888'888k  888R I888>   8888  8888 :888'8888.   8888  888R 
9888 'Y"    4888> '      888E  888I    888I  888I   8888     888R I888>    9888 'Y"   888R I888>   8888  8888 d888 '88%"   8888  888R 
9888        4888>        888E  888I    888I  888I   8888     888R I888>    9888       888R I888>   8888  8888 8888.+"      8888  888R 
9888       .d888L .+     888E  888I  uW888L  888'  .8888Lu= u8888cJ888     9888      u8888cJ888   .8888b.888P 8888L        8888  888R 
?8888u../  ^"8888*"     x888N><888' '*88888Nu88P   ^%888*    "*888*P"      ?8888u../  "*888*P"     ^Y8888*""  '8888c. .+  "*88*" 8888"
 "8888P'      "Y"        "88"  888  ~ '88888F`       'Y"       'Y"          "8888P'     'Y"          `Y"       "88888%      ""   'Y"  
   "P'                         88F     888 ^                                  "P'                                "YP'                 
                              98"      *8E                                                                                            
                            ./"        '8>                                                                                            
                           ~`           "                                                                                             

.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "base64-sol/base64.sol";

import "./interfaces/INarratorsHutMetadata.sol";
import "./utils/Random.sol";

contract NarratorsHutMetadata is INarratorsHutMetadata, Ownable {
    mapping(uint256 => Artifact) public artifacts;

    constructor() {}

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier artifactExists(uint256 artifactId) {
        if (artifactId == 0 || bytes(artifacts[artifactId].name).length == 0) {
            revert ArtifactDoesNotExist();
        }
        _;
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getArtifactForToken(
        uint256 artifactId,
        uint256 tokenId,
        uint256 witchId
    ) public view returns (ArtifactManifestation memory) {
        Artifact memory artifact = artifacts[artifactId];

        AttunementManifestation[] memory attunements = pickAttunementModifiers(
            artifact,
            tokenId,
            artifactId,
            witchId
        );

        return
            ArtifactManifestation({
                name: artifact.name,
                description: artifact.description,
                witchId: witchId,
                artifactId: artifactId,
                attunements: attunements
            });
    }

    function canMintArtifact(uint256 artifactId)
        external
        view
        artifactExists(artifactId)
        returns (bool)
    {
        return artifacts[artifactId].mintable == true;
    }

    // ============ INTERNAL HELPER FUNCTIONS ============

    function pickAttunementModifiers(
        Artifact memory artifact,
        uint256 tokenId,
        uint256 artifactId,
        uint256 witchId
    ) internal pure returns (AttunementManifestation[] memory) {
        AttunementManifestation[]
            memory attunementModifiers = new AttunementManifestation[](
                artifact.attunements.length
            );
        for (uint256 i = 0; i < artifact.attunements.length; i++) {
            attunementModifiers[i] = pickAttunementModifier(
                artifact.attunements[i],
                tokenId,
                artifactId,
                witchId
            );
        }
        return attunementModifiers;
    }

    function pickAttunementModifier(
        string memory attunement,
        uint256 tokenId,
        uint256 artifactId,
        uint256 witchId
    ) internal pure returns (AttunementManifestation memory) {
        if (
            (witchId == 1 &&
                keccak256(abi.encodePacked(attunement)) ==
                keccak256(abi.encodePacked("Woe"))) ||
            (witchId == 2 &&
                keccak256(abi.encodePacked(attunement)) ==
                keccak256(abi.encodePacked("Wisdom"))) ||
            (witchId == 3 &&
                keccak256(abi.encodePacked(attunement)) ==
                keccak256(abi.encodePacked("Will"))) ||
            (witchId == 4 &&
                keccak256(abi.encodePacked(attunement)) ==
                keccak256(abi.encodePacked("Wonder"))) ||
            (witchId == 5 &&
                keccak256(abi.encodePacked(attunement)) ==
                keccak256(abi.encodePacked("Wit")))
        ) {
            return AttunementManifestation({name: attunement, value: 5});
        }

        string memory seed = string.concat(
            attunement,
            Strings.toString(artifactId),
            witchId == 0 ? Strings.toString(tokenId) : Strings.toString(witchId)
        );

        uint256 rand = Random.randomFromSeed(seed);
        bool isNegative = Random.randomFromSeed(string.concat(seed, "sign")) %
            4 ==
            0;
        uint256 rarity = rand % 100;

        int256 attunementModifier;
        if (rarity <= 14) {
            attunementModifier = 0;
        } else if (rarity <= 81) {
            attunementModifier = 1;
        } else if (rarity <= 96) {
            attunementModifier = 2;
        } else {
            attunementModifier = 3;
        }

        attunementModifier = isNegative
            ? -attunementModifier
            : attunementModifier;

        return
            AttunementManifestation({
                name: attunement,
                value: attunementModifier
            });
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function craftArtifact(CraftArtifactData calldata data) external onlyOwner {
        if (bytes(artifacts[data.id].name).length > 0) {
            revert ArtifactHasAlreadyBeenCrafted();
        }
        Artifact storage artifact = artifacts[data.id];
        artifact.name = data.name;
        artifact.description = data.description;

        for (uint256 i; i < data.attunements.length; ) {
            artifact.attunements.push(data.attunements[i]);

            unchecked {
                ++i;
            }
        }

        artifact.mintable = true;
    }

    function getArtifact(uint256 artifactId)
        external
        view
        onlyOwner
        returns (Artifact memory)
    {
        return artifacts[artifactId];
    }

    function lockArtifacts(uint256[] calldata artifactIds) external onlyOwner {
        for (uint256 i = 0; i < artifactIds.length; i++) {
            artifacts[artifactIds[i]].mintable = false;
        }
    }

    // ============ ERRORS ============

    error ArtifactDoesNotExist();
    error ArtifactHasAlreadyBeenCrafted();
}