// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import '@openzeppelin/contracts/access/Ownable.sol';
import './MetadataGenerator.sol';
import 'hardhat/console.sol';
import './IDeathClockDescriptor.sol';

contract DeathClockDesciptor is
    IDeathClockDescriptor,
    Ownable,
    MetadataGenerator
{
    string public viewerCID = '';
    string public previewCID = '';
    uint256 private constant MAX_CLOCKS = 500;

    mapping(uint256 => TokenParams) public tokenParamsById;
    bytes32[] public colorNames = [
        bytes32('A$hes'),
        bytes32('Y2Kgreen'),
        bytes32('Ev3ryth1ng'),
        bytes32(unicode'R3s†[email protected]'),
        bytes32(unicode'†rus†'),
        bytes32('Du$T'),
        bytes32('[email protected]'),
        bytes32('F0r3v3rY0ung'),
        bytes32(unicode'P1NKCrYp†'),
        bytes32('L1FE&[email protected]')
    ];

    bytes32[] public imageNames = [
        bytes32('All-Dogs-Go-To-Heaven-1989'),
        bytes32('Amazon-Fulfillment'),
        bytes32('Bambi-1942'),
        bytes32('Betty-Boop-Snow-White-1933'),
        bytes32('Burial-iPhone-Like-Accessory'),
        bytes32('Burried-Alive'),
        bytes32('Couple-Burial-01'),
        bytes32('Couple-Burial-02'),
        bytes32('Couple-Burial-Harappa'),
        bytes32(unicode'Couple-Burial-Téviec'),
        bytes32('Couple-Coffin'),
        bytes32('Cuevas-de-las-Manos-01'),
        bytes32('Cuevas-de-las-Manos-02'),
        bytes32('Cuevas-de-las-Manos-03'),
        bytes32('Denisovan-Prehistoric-Graffiti'),
        bytes32('Dickinsonia-Oldest-Fossil-01'),
        bytes32('Dickinsonia-Oldest-Fossil-02'),
        bytes32(unicode'Diquís-Giant-Sphere'),
        bytes32('Egyptian-Mummy-CT-Scan-01'),
        bytes32('Egyptian-Mummy-CT-Scan-02'),
        bytes32('Egyptian-Mummy-CT-Scan-03'),
        bytes32('Egyptian-Mummy-CT-Scan-04'),
        bytes32('Egyptian-Mummy-CT-Scan-Tamut'),
        bytes32(unicode'Étienne-Louis-Boullée'),
        bytes32('Footprints-Engare-Sero'),
        bytes32('Footprints-North-America'),
        bytes32('Footprints-Pliocene-Laetoli'),
        bytes32('Fossil-Nokia'),
        bytes32('Haunted-House-1929-01'),
        bytes32('Haunted-House-1929-02'),
        bytes32('Haunted-House-1929-03'),
        bytes32('Human-Fossil-Teeth'),
        bytes32('Ice-Age-Burial-03'),
        bytes32('Kings-Hunt-Assurbanipal'),
        bytes32('Loyalty-Rihanna-Kendrick'),
        bytes32('Menkaure-Khamerernebty-01'),
        bytes32('Menkaure-Khamerernebty-02'),
        bytes32(unicode'Ötzi-The-Iceman'),
        bytes32('Peter-and-the-Wolf-1946'),
        bytes32('Piranesi-01'),
        bytes32('Piranesi-02'),
        bytes32('Piranesi-03'),
        bytes32('Piranesi-04'),
        bytes32('Pompeii-Fallen-Stone'),
        bytes32('Pompeii-Garden-Fugitives-01'),
        bytes32('Pompeii-Garden-Fugitives-02'),
        bytes32('Quest-for-Fire-1981'),
        bytes32('Shovel'),
        bytes32('Skull-Close-Up'),
        bytes32('Snake-Bird-Death'),
        bytes32('Swing-You-Sinners-1930-01'),
        bytes32('Swing-You-Sinners-1930-02'),
        bytes32('The-Crystal-Maiden'),
        bytes32('The-Skeleton-Dance-1929-01'),
        bytes32('The-Skeleton-Dance-1929-02'),
        bytes32('The-Skeleton-Dance-1929-03'),
        bytes32('Venus-de-Willendorf'),
        bytes32('Viking-Burial-01'),
        bytes32('Viking-Burial-02'),
        bytes32('Warner-Brothers-Bugs-Bunny'),
        bytes32('Work-Bitch-Britney-Spears'),
        bytes32('Zoroastrian-Towers-of-Silence')
    ];

    constructor(string memory _viewerCID, string memory _previewCID) {
        viewerCID = _viewerCID;
        previewCID = _previewCID;
    }

    function setViewerCID(string calldata _viewerCID) external onlyOwner {
        viewerCID = _viewerCID;
    }

    function setPreviewCID(string calldata _previewCID) external onlyOwner {
        previewCID = _previewCID;
    }

    function setTokenParams(
        TokenParams[] memory _tokenParams,
        uint256 startWith
    ) external onlyOwner {
        for (uint256 i = 0; i < _tokenParams.length; i++) {
            tokenParamsById[startWith + i] = _tokenParams[i];
        }
    }

    function getMetadataJSON(MetadataPayload calldata metadataPayload)
        external
        view
        returns (string memory)
    {
        uint256 tokenId = metadataPayload.id;
        address acct = metadataPayload.acct;
        TokenParams memory _tp = tokenParamsById[tokenId];
        uint256 previewId = tokenId;
        bool isRemnant = tokenId >= MAX_CLOCKS;
        if (isRemnant) {
            previewId = 9999; //renmant
        }
        console.log('!!', tokenId, MAX_CLOCKS, isRemnant);
        return
            generateMetadataJSON(
                MetadataGenerator.metadataPayload(
                    tokenId,
                    isRemnant,
                    metadataPayload.minted,
                    metadataPayload.expDate,
                    _tp.cid,
                    _tp.tid,
                    _tp.bid,
                    colorNames[_tp.cid],
                    imageNames[_tp.tid],
                    imageNames[_tp.bid],
                    metadataPayload.remnants,
                    metadataPayload.resets,
                    string.concat(
                        previewCID,
                        '/',
                        Strings.toString(previewId),
                        '.gif'
                    ),
                    string.concat('ipfs://', viewerCID),
                    acct
                )
            );
    }
}