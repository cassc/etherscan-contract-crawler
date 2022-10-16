// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @author: x0r - Michael Blau

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';

contract ASCIIGenerator is Ownable {
    using Base64 for string;
    using Strings for uint256;

    uint256[] public partOne;
    uint256[] public partTwo;

    string internal description = 'Ledger is a fully on-chain dynamic NFT that leverages smart contract composability. The ASCII image portrays a subtle x0r logo where the vertical line contains the addresses of all current owners of the NFT. Whenever this NFT transfers, the ASCII art will update and always reflect both the current owners and the last block number where an update occurred.';
    string internal SVGHeader =
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 900 1090'><defs><style>.cls-1{font-size: 10px; fill: white; font-family:monospace;}</style></defs><g><rect width='900' height='1090' fill='black' />";
    string internal firstTextTagPart =
        "<text lengthAdjust='spacing' textLength='900' class='cls-1' x='0' y='";
    string internal SVGFooter = '</g></svg>';
    uint256 internal tspanLineHeight = 12;

    // =================== ASCII GENERATOR FUNCTIONS =================== //

    /**
     * @notice Generates full metadata
     */
    function generateMetadata(address _nftContract, uint256 _tokenId, uint256 _lastUpdatedBlock)
        public
        view
        returns (string memory)
    {
        string[55] memory owners = getOwners(_nftContract);

        string memory SVG = generateSVG(owners, _lastUpdatedBlock);

        string memory metadata = Base64.encode(
            bytes(
                string.concat(
                    '{"name": "Ledger #',
                    _tokenId.toString(),
                    '/55",',
                    '"description":"',
                    description,
                    '","image":"',
                    SVG,
                    '"}'
                )
            )
        );

        return string.concat('data:application/json;base64,', metadata);
    }

    /**
     * @notice Get all ERC721 owner addresses and convert them to strings
     * @param _nftContract to query NFT owners from
     */
    function getOwners(address _nftContract) internal view returns (string[55] memory) {
        IERC721 nftContract = IERC721(_nftContract);

        string[55] memory owners;

        for (uint256 i; i < owners.length; i++) {
            try nftContract.ownerOf(i + 1) returns (address nftOwner) {
                owners[i] = Strings.toHexString(uint256(uint160(nftOwner)), 20);
            } catch {
                owners[i] = Strings.toHexString(uint256(uint160(address(0))), 20);
            }
        }

        return owners;
    }

    /**
     * @notice Generates the SVG image
     */
    function generateSVG(string[55] memory _owners, uint256 _lastUpdatedBlock) public view returns (string memory) {
        string[89] memory rows = genCoreAscii(_owners);

        string memory _firstTextTagPart = firstTextTagPart;
        string memory span;
        string memory center;
        uint256 y = tspanLineHeight;

        for (uint256 i; i < rows.length; i++) {
            span = string.concat(_firstTextTagPart, y.toString(), "'>", rows[i], '</text>');
            center = string.concat(center, span);
            y += tspanLineHeight;
        }

        // add last row of ASCII that contains the last updated block number
        center = string.concat(
            center,
            _firstTextTagPart,
            y.toString(),
            "'>",
            getLastUpdatedBlockString(_lastUpdatedBlock),
            '</text>'
        );

        // base64 encode the SVG text
        string memory SVGImage = Base64.encode(bytes(string.concat(SVGHeader, center, SVGFooter)));

        return string.concat('data:image/svg+xml;base64,', SVGImage);
    }

    /**
     * @notice Generates all ASCII rows of the image
     */
    function genCoreAscii(string[55] memory _owners) public view returns (string[89] memory) {
        string[89] memory asciiRows;

        uint256 partOneEndIndex = partOne.length;
        uint256 partTwoEndIndex = partOneEndIndex + partTwo.length;

        for (uint256 i; i < asciiRows.length; i++) {
            if (i < partOneEndIndex) {
                asciiRows[i] = rowToString(partOne[i], 150);
            } else if (i >= partOneEndIndex && i < partTwoEndIndex) {
                uint256 centerIndex = i - partOneEndIndex;
                string memory rowHalf = rowToString(partTwo[centerIndex], 54);
                asciiRows[i] = string.concat(rowHalf, _owners[centerIndex], reverseValue(rowHalf));
            } else if (i >= partTwoEndIndex) {
                asciiRows[i] = asciiRows[asciiRows.length - i - 1];
            }
        }

        return asciiRows;
    }

    /**
     * @notice Generates one ASCII row as a string
     */
    function rowToString(uint256 _row, uint256 _bitsToUnpack)
        internal
        pure
        returns (string memory)
    {
        string memory rowString;
        for (uint256 i; i < _bitsToUnpack; i++) {
            if (((_row >> (1 * i)) & 1) == 0) {
                rowString = string.concat(rowString, '.');
            } else {
                rowString = string.concat(rowString, '-');
            }
        }

        return rowString;
    }

    /**
     * @notice Generates one row of ASCII that shows the last block number when the ledger was updated (i.e., the NFT was transferred)
     * @param _blockNumber when the NFT was last transferred
     */
    function getLastUpdatedBlockString(uint256 _blockNumber) public pure returns (string memory) {
        string memory blockNumberString = _blockNumber.toString();
        uint256 asciiOffset = 150 - bytes(blockNumberString).length;

        string memory asciiRow;
        for (uint256 i; i < asciiOffset; i++) {
            asciiRow = string.concat(asciiRow, '.');
        }

        return string.concat(asciiRow, blockNumberString);
    }

    /**
     * @notice reverse a string
     */
    function reverseValue(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        assert(_baseBytes.length > 0);

        string memory _tempValue = new string(_baseBytes.length);
        bytes memory _newValue = bytes(_tempValue);

        for (uint256 i; i < _baseBytes.length; i++) {
            _newValue[_baseBytes.length - i - 1] = _baseBytes[i];
        }

        return string(_newValue);
    }

    // =================== STORE IMAGE DATA =================== //

    function storeImageParts(uint256[] memory _partOne, uint256[] memory _partTwo)
        external
        onlyOwner
    {
        partOne = _partOne;
        partTwo = _partTwo;
    }

    function setSVGParts(
        string calldata _SVGHeader,
        string calldata _SVGFooter,
        string calldata _firstTextTagPart,
        uint256 _tspanLineHeight
    ) external onlyOwner {
        SVGHeader = _SVGHeader;
        SVGFooter = _SVGFooter;
        firstTextTagPart = _firstTextTagPart;
        tspanLineHeight = _tspanLineHeight;
    }

    function getSVGParts()
        external
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256
        )
    {
        return (SVGHeader, SVGFooter, firstTextTagPart, tspanLineHeight);
    }

    function setDescription(string calldata _description) external onlyOwner {
        description = _description;
    }
}