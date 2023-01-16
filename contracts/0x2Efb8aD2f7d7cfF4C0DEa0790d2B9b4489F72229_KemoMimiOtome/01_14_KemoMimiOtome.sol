// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract KemoMimiOtome is AccessControl, ERC721AntiScam {
    bytes32 public ADMIN = "ADMIN";

    // Metadata
    string public baseURI;
    string public baseExtension;

    // Change
    struct KemomimiChange {
        uint8 id;
        uint8 fromHour;
        uint8 fromMin;
        uint8 toHour;
        uint8 toMin;
        string suffix;
    }
    mapping(uint256 => KemomimiChange[]) kemomimiChangesByToken;
    mapping(uint256 => uint8) lockedIdByTokenId;

    // TimeDiff
    uint8 public diffHours = 9;

    // Constructor
    constructor() ERC721A("KemoMimiOtome", "KMO") {
        grantRole(ADMIN, msg.sender);
    }

    // Modifier
    modifier isTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You Are Not Token Owner");
        _;
    }

    // Main
    function mint(address to, KemomimiChange[] memory kemomimiChanges) external onlyRole(ADMIN) {
        _safeMint(to, 1);
        setKemomimiChanges(totalSupply(), kemomimiChanges);
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        KemomimiChange memory kemomimiChange = getCurrentChange(tokenId);
        return string(abi.encodePacked(ERC721A.tokenURI(tokenId), kemomimiChange.suffix, baseExtension));
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // Setter
    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyRole(ADMIN) {
        baseExtension = "";
    }
    function setDiffHours(uint8 _value) external onlyOwner {
        diffHours = _value;
    }

    // For ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function exists(uint256 tokenId) public view virtual returns (bool) {
        return _exists(tokenId);
    }

    // Lock
    function lock(uint256 tokenId, uint8 changeId) public
        isTokenOwner(tokenId)
    {
        lockedIdByTokenId[tokenId] = changeId;
    }
    function unlock(uint256 tokenId) public
        isTokenOwner(tokenId)
    {
        lockedIdByTokenId[tokenId] = 0;
    }
    function locked(uint256 tokenId) public view returns (bool) {
        return lockedIdByTokenId[tokenId] > 0;
    }

    // KemomimiChange
    function setKemomimiChanges(uint256 tokenId, KemomimiChange[] memory kemomimiChanges) public
        isTokenOwner(tokenId)
    {
        kemomimiChangesByToken[tokenId] = kemomimiChanges;
    }
    function getKemomimiChanges(uint256 tokenId) public view returns (KemomimiChange[] memory) {
        return kemomimiChangesByToken[tokenId];
    }
    function getCurrentChange(uint256 tokenId) public view returns (KemomimiChange memory) {
        if (locked(tokenId)) {
            return getLockedChange(tokenId);
        } else {
            uint256 hour = getHour();
            uint256 min = getMin();
            return getChange(tokenId, hour, min);
        }
    }
    function getLockedChange(uint256 tokenId) public view returns (KemomimiChange memory) {
        KemomimiChange[] memory kemomimiChanges = kemomimiChangesByToken[tokenId];
        uint256 lockedId = lockedIdByTokenId[tokenId];
        for (uint8 i = 0; i < kemomimiChanges.length; i++) {
            KemomimiChange memory kemomimiChange = kemomimiChanges[i];
            if (kemomimiChange.id == lockedId) {
                return kemomimiChange;
            }
        }
        return KemomimiChange(0, 0, 0, 0, 0, "");
    }
    function getChange(uint256 tokenId, uint256 hour, uint256 min) public view returns (KemomimiChange memory) {
        KemomimiChange[] memory kemomimiChanges = kemomimiChangesByToken[tokenId];
        for (uint8 i = 0; i < kemomimiChanges.length; i++) {
            KemomimiChange memory kemomimiChange = kemomimiChanges[i];
            if (kemomimiChange.fromHour > hour) continue;
            if (kemomimiChange.fromHour == hour && kemomimiChange.fromMin > min) continue;
            if (kemomimiChange.toHour < hour) continue;
            if (kemomimiChange.toHour == hour && kemomimiChange.toMin < min) continue;
            return kemomimiChange;
        }
        return KemomimiChange(0, 0, 0, 0, 0, "");
    }

    // Date
    function getHour() public view returns (uint256) {
        uint256 sec = block.timestamp % 60;
        uint256 min = ((block.timestamp - sec) / 60) % 60;
        uint256 hour = ((block.timestamp - sec - min * 60) / 3600 + diffHours) % 24;
        return hour;
    }
    function getMin() public view returns (uint256) {
        uint256 sec = block.timestamp % 60;
        uint256 min = ((block.timestamp - sec) / 60) % 60;
        return min;
    }
    function getSec() public view returns (uint256) {
        uint256 sec = block.timestamp % 60;
        return sec;
    }

    // Interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721AntiScam) returns (bool) {
        return
            interfaceId == type(IERC721AntiScam).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}