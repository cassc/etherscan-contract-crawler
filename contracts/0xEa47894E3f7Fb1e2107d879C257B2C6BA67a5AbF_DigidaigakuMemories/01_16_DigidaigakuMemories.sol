// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract DigidaigakuMemories is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable, DefaultOperatorFiltererUpgradeable {
    struct Snapshot {
        address minter;
        uint256[] ids;
    }

    event LogMemoryMinted(uint256 mintedId);

    string private METADATA_BASE_URL;
    mapping(address => uint256[]) private callerToApprovedMints;

    modifier onlyApprovedMints(uint256 id) {
        require(arrayContains(callerToApprovedMints[msg.sender], id), "Mint has not been approved");
        _;
    }

    function arrayContains(uint256[] memory a, uint256 v) internal pure returns(bool) {
        for (uint i = 0; i < a.length; i++) {
            if (a[i] == v) {
                return true;
            }
        }
        return false;
    }

    function initialize(string memory metadata_folder) public initializer {
        __ERC721_init("Digidaigaku Memories", "DIGIMEM");
        __ERC721URIStorage_init();
        __Ownable_init();
        __DefaultOperatorFilterer_init();
        METADATA_BASE_URL = metadata_folder;
    }

    function mintApprovedMemories() public {
        uint256[] storage approvedIds = callerToApprovedMints[msg.sender];
        for (uint i = 0; i < approvedIds.length; i++) {
            uint256 id = approvedIds[i];
            if (!_exists(id)) {
                _mintMemory(id);
                emit LogMemoryMinted(id);
            }
        }
    }

    function mintMemory(uint256 id) public onlyApprovedMints(id) {
        _mintMemory(id);
        emit LogMemoryMinted(id);
    }

    function _mintMemory(uint256 id) internal {
        _mint(msg.sender, id);
    }

    function memoryMinted(uint256 id) public view returns(bool) {
        return _exists(id);
    }

    function getApprovedMints(address addressToCheck) public view returns(uint256[] memory) {
        return callerToApprovedMints[addressToCheck];
    }

    function uploadSnapshot(Snapshot[] memory snapshot) public onlyOwner {
        for (uint256 i = 0; i < snapshot.length; i++) {
            callerToApprovedMints[snapshot[i].minter] = snapshot[i].ids;
        }
    }

    function _baseURI() internal view override returns(string memory) {
        return METADATA_BASE_URL;
    }

    function setBaseURI(string memory url) public onlyOwner() {
        METADATA_BASE_URL = url;
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        return string(abi.encodePacked(_baseURI(), StringsUpgradeable.toString(tokenId), ".json"));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override onlyAllowedOperator(from) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}