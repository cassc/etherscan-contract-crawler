//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./PublicCryptopunksData.sol";
import "./IOtherPunksConfiguration.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./OtherPunks.sol";

contract MineablePunks is ERC721, Ownable {
    event BurnOriginalPunk (
        uint16 originalPunkId
    );

    PublicCryptopunksData public punksData;
    OtherPunks public otherPunks;
    IOtherPunksConfiguration public otherPunksConfiguration;

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

    constructor(
        PublicCryptopunksData _punksData,
        IOtherPunksConfiguration _otherPunksConfiguration,
        OtherPunks _otherPunks
    ) ERC721("MineablePunks", "MPUNKS") Ownable() {
        punksData = _punksData;
        otherPunksConfiguration = _otherPunksConfiguration;
        otherPunks = _otherPunks;

        difficultyTarget = otherPunksConfiguration.getDifficultyTargetAtIndex(
            0
        );

        // 10002
        punkAssetsToId[350588487688295238464456448] = 10000;
        punkIdToAssets[10000] = 350588487688295238464456448;
        ERC721._safeMint(0x08D816526BdC9d077DD685Bd9FA49F58A5Ab8e48, 10000);

        // 10003
        punkAssetsToId[1237940039285405564639657472] = 10001;
        punkIdToAssets[10001] = 1237940039285405564639657472;
        ERC721._safeMint(0x08D816526BdC9d077DD685Bd9FA49F58A5Ab8e48, 10001);

        // 10005
        punkAssetsToId[647984239313459929809944576] = 10002;
        punkIdToAssets[10002] = 647984239313459929809944576;
        ERC721._safeMint(0x08D816526BdC9d077DD685Bd9FA49F58A5Ab8e48, 10002);

        // 10006
        punkAssetsToId[2475882076944016005046206464] = 10003;
        punkIdToAssets[10003] = 2475882076944016005046206464;
        ERC721._safeMint(0x08D816526BdC9d077DD685Bd9FA49F58A5Ab8e48, 10003);

        // 10008
        punkAssetsToId[2785365088392134206999774976] = 10004;
        punkIdToAssets[10004] = 2785365088392134206999774976;
        ERC721._safeMint(0xe76091F84dDf27f9e773cA8bD2090830943f615C, 10004);

        // 10009
        punkAssetsToId[928455029464081386486049792] = 10005;
        punkIdToAssets[10005] = 928455029464081386486049792;
        ERC721._safeMint(0xe76091F84dDf27f9e773cA8bD2090830943f615C, 10005);

        // 10010
        punkAssetsToId[2166395068749416019387244032] = 10006;
        punkIdToAssets[10006] = 2166395068749416019387244032;
        ERC721._safeMint(0x92e9b91AA2171694d740E7066F787739CA1Af9De, 10006);

        // 10011
        punkAssetsToId[618970019642704432224805632] = 10007;
        punkIdToAssets[10007] = 618970019642704432224805632;
        ERC721._safeMint(0x26EE5302D8cc0422EE5DCdF19668c663e2fAfb8E, 10007);

        // After the second redeploy...
        punkAssetsToId[2785365088392105881019360000] = 10008;
        punkIdToAssets[10008] = 2785365088392105881019360000;
        ERC721._safeMint(0xD0bA4295Acf286a173cbaB2A1312c2B83FCa0723, 10008);

        punkAssetsToId[1237940039294694239022106624] = 10009;
        punkIdToAssets[10009] = 1237940039294694239022106624;
        ERC721._safeMint(0xC39043082AdF6D2Ec27F79075C77Fb80A9C03eB0, 10009);

        punkAssetsToId[1237940039285424256001769472] = 10010;
        punkIdToAssets[10010] = 1237940039285424256001769472;
        ERC721._safeMint(0xC39043082AdF6D2Ec27F79075C77Fb80A9C03eB0, 10010);

        punkAssetsToId[2166397070221148016712764928] = 10011;
        punkIdToAssets[10011] = 2166397070221148016712764928;
        ERC721._safeMint(0xA45e535d79c82C31eA1F172ccd5b54D930C56c14, 10011);

        numMined = 12;
        nextPunkId = 10012;
        lastMinedPunkAssets = 2166397070221148016712764928; 
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.mpunks.org/metadata/";
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

    function mint(uint256 _nonce, uint256 blockNumber) external {
        require((blockNumber < otherPunksConfiguration.getBlockNumber() && 
            blockNumber >= otherPunksConfiguration.getBlockNumber() - 15) || 
            difficultyTarget <= otherPunksConfiguration.getHardDifficultyTarget(), "blockNumber out of range");

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
                            otherPunksConfiguration.getBlockHash(
                                blockNumber
                            )
                );
        }

        uint96 punkAssets = otherPunks.seedToPunkAssets(seed);

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
            uint96 founderPunkAssets = otherPunks.seedToPunkAssets(uint256(keccak256(abi.encodePacked(seed))));

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