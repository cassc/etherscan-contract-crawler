/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                             ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ░░ ██ ░░ ░░ ░░ ░░ ░░   ░░
░░   ░░ ██ ██ ██ ██ ██ ██ ░░   ░░
░░   ░░ ██ ░░ ░░ ░░ ░░ ██ ░░   ░░
░░   ░░ ██ ░░ ░░ ██ ░░ ██ ░░   ░░
░░   ░░ ██ ░░ ░░ ░░ ░░ ██ ░░   ░░
░░   ░░ ██ ██ ██ ██ ██ ██ ░░   ░░
░░   ░░ ░░ ░░ ░░ ░░ ░░ ░░ ░░   ░░
░░                             ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Utilities.sol";

interface IEdition {
    function getCurrentColors() external view returns (uint32[64] memory);
    function changeCounter() external pure returns (uint);
}

contract UintsEditionSnapshots is ERC721A, Ownable {
    constructor() ERC721A("UINTS Edition Snapshots", "UES") {}

    address _editionContract = 0xb1d74122ea8a7F9bAbCf489cF5133837B31878a7;

    function setEditionContract(address contractAddress) public onlyOwner {
        _editionContract = contractAddress;
        iEditionContract = IEdition(contractAddress);
    }

    IEdition iEditionContract = IEdition(_editionContract);

    struct Snapshot {
        address capturedBy;
        uint artVersion;
        uint timestamp;
        uint32[64] colors;
    }

    mapping(uint => Snapshot) public snapshots;
    uint public snapshotCounter;

    function takeSnapshot() public {
        snapshots[snapshotCounter + 1] = Snapshot({
            capturedBy: msg.sender,
            artVersion: iEditionContract.changeCounter(),
            timestamp: block.timestamp,
            colors: iEditionContract.getCurrentColors()
        });
        _mint(msg.sender, 1);
        snapshotCounter++;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory result) {
        string memory svg = utils.renderSvg(snapshots[tokenId].colors);
        string memory json = string(
            abi.encodePacked(
                '{"name": "UINTS Edition Snapshot ',
                _toString(tokenId),
                '", "description": "UINTS Edition Snapshots are on-chain records of artwork from the UINTS Edition collection.", ',
                '"attributes": [{"trait_type": "Captured by", "value": "0x',
                utils.toAsciiString(snapshots[tokenId].capturedBy),
                '"},{"display_type": "number", "trait_type": "Art version", "value": ',
                _toString(snapshots[tokenId].artVersion),
                '},{"display_type": "date", "trait_type": "Date", "value": ',
                _toString(snapshots[tokenId].timestamp),
                '}], "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(svg)),
                '"}'
            )
        );

        result = string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(json))
            )
        );
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}