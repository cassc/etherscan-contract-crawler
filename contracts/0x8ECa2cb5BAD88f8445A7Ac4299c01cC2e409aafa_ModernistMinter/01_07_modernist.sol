// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IGenesis {
    function mint(uint256) external;
    function ownerOf(uint256) external returns (address);
    function checkToken(uint256) external view returns (bool);
}
interface IMintable {
    function mintTo(address, uint256) external;
    function ownerOf(uint256) external returns (address);
    function checkToken(uint256) external view returns (bool);
}
interface ISplitMintable {
    function mintQuadrantsTo(address, uint256[] memory) external;
    function ownerOf(uint256) external returns (address);
    function checkQuadrant(uint256) external view returns (bool);
    function burnToken(uint256) external;
}

contract ModernistMinter is AccessControl {
    IGenesis Genesis;
    ISplitMintable Split;
    IMintable Modernist;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public constant TOTAL_SUPPLY = 9_724;
    uint256 public constant TOKEN_OFFSET = 10_000;
    uint256 constant EDITIONS = 22;
    uint256 constant TOTAL_MS = 442;

    bool public whitelistOnly = true;
    bool public mintStarted;

    struct ModernistStruct {
        uint8 count;
    }
    mapping (uint256 => ModernistStruct) stitchedMints;

    mapping (uint256 => uint256) _splitTokens;
 
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setGenesisContract(address newAddress) public onlyRole(MINTER_ROLE) {
        Genesis = IGenesis(newAddress);
    }

    function setSplitContract(address newAddress) public onlyRole(MINTER_ROLE) {
        Split = ISplitMintable(newAddress);
    }

    function setMintableContract(address newAddress) public onlyRole(MINTER_ROLE) {
        Modernist = IMintable(newAddress);
    }

    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function toggleWhitelistOnly() public onlyRole(MINTER_ROLE) {
        whitelistOnly = !whitelistOnly;
    }

    function toggleMintStatus() public onlyRole(MINTER_ROLE) {
        mintStarted = !mintStarted;
    }

    // Mints the corresponding 4 quadrants and marks the original token as split
    // tokenId: The ID to split, its owner will receive the split quadrants
    // quadrants: must pass exactly 4 values
    function split(uint256 tokenId, uint256[] memory quadrants) public onlyRole(MINTER_ROLE) {
        require(!isSplit(tokenId), "Token cant be split");
        require(quadrants.length == 4, "Invalid quadrants");

        address tokenOwner = Genesis.ownerOf(tokenId);
        for (uint64 i = 0; i < quadrants.length; i++) {
            require(!Split.checkQuadrant(quadrants[i]), "Quadrant already exists");
            require(isValidSplitQuadrant(quadrants[i], i), "Quadrant doesnt belong to correct position");
        }
        _splitTokens[tokenId] = tokenId;
        Split.mintQuadrantsTo(tokenOwner, quadrants);
    }

    // Receives 4 ids which must match the target MS Code
    // Up to 22 versions of each MS Code may be minted
    // modernistId: The MS Code can be 1-442
    // quadrants: all 4 ids need to be within the range for the input MS, and they must not have been used before
    function stitch(uint256 modernistId, uint256[] memory quadrants) public {
        // `quadrants` must be [TopR, TopL, BottomL, BottomR]
        require(quadrants.length == 4, "Requires 4 quadrants");
        // `modernistId` is the desired MS-Code ID, valid values: 1-442
        require(modernistId <= TOTAL_MS, "Invalid MS Code");
        require(stitchedMints[modernistId].count < EDITIONS, "All editions have been minted for MS Code");

        // Converts the desired ID to the start of the range, so the stitchedMints IDs don't overlap
        // 1 -> 1
        // 2 -> 23
        // 3 -> 45
        // Mint ranges are 1->22, 23->44, 45->66, etc...
        uint256 normalized = ((modernistId - 1) * EDITIONS) + 1;

        // Adds mint counter so we obtain the next edition for the current MS-Code
        uint256 targetId = normalized + stitchedMints[modernistId].count;

        require(!Modernist.checkToken(targetId), "Token has already been stitched");

        for (uint256 i = 0; i < quadrants.length; i++) {
            // Validate if sender owns all quadrants
            require(Split.ownerOf(quadrants[i]) == msg.sender, "You cant stitch this token");
            // Validate if quadrants belong to correct Modernist
            require(isValidQuadrant(modernistId, quadrants[i], i), "Quadrant doesnt belong to final modernist");
        }

        for (uint256 i = 0; i < quadrants.length; i++) {
            Split.burnToken(quadrants[i]);
        }
        stitchedMints[modernistId].count += 1;
        Modernist.mintTo(msg.sender, targetId);
    }

    // Checks if a quadrant NFT belongs to the correct corner
    function isValidQuadrant(uint256 modernistId, uint256 quadrantToken, uint256 quadrant) private pure returns (bool) {
        uint256 offset = TOKEN_OFFSET * quadrant;
        // Start of valid range, e.g. 10001 for modernistId=1 and quadrant=2
        uint256 start = offset + (EDITIONS * (modernistId - 1)) + 1;
        // End of valid range, e.g. 10022 for modernistId=1 and quadrant=2
        uint256 end = offset + (EDITIONS * modernistId);

        return quadrantToken >= start && quadrantToken <= end;
    }

    function isValidSplitQuadrant(uint256 quadrantToken, uint256 quadrant) private pure returns (bool) {
        uint256 offset = TOKEN_OFFSET * quadrant;
        // Start of valid range for quadrant, e.g. 10001 quadrant=2
        uint256 start = offset;
        // End of valid range, e.g. 19724 for quadrant=2
        uint256 end = offset + TOTAL_SUPPLY;

        return quadrantToken >= start && quadrantToken <= end;
    }

    function isSplit(uint256 index) public view returns (bool) {
        return _splitTokens[index] > 0;
    }
}