// __/\\\\\\\\\\\\______/\\\\\\\\\\\\\\\_____________/\\\\\__/\\\________/\\\_
//  _\/\\\////////\\\___\/\\\///////////__________/\\\\////__\/\\\_____/\\\//__
//   _\/\\\______\//\\\__\/\\\__________________/\\\///_______\/\\\__/\\\//_____
//    _\/\\\_______\/\\\__\/\\\\\\\\\\\\_______/\\\\\\\\\\\____\/\\\\\\//\\\_____
//     _\/\\\_______\/\\\__\////////////\\\____/\\\\///////\\\__\/\\\//_\//\\\____
//      _\/\\\_______\/\\\_____________\//\\\__\/\\\______\//\\\_\/\\\____\//\\\___
//       _\/\\\_______/\\\___/\\\________\/\\\__\//\\\______/\\\__\/\\\_____\//\\\__
//        _\/\\\\\\\\\\\\/___\//\\\\\\\\\\\\\/____\///\\\\\\\\\/___\/\\\______\//\\\_
//         _\////////////______\/////////////________\/////////_____\///________\///__

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "ERC721A/ERC721A.sol";
import "./DialUpState.sol";
import { Ownable } from "openzeppelin-contracts/access/Ownable.sol";

interface IDisk {
    function burn(address _from, uint256[] memory _tokenIds, uint256[] memory _amounts) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract DialUp56k is ERC721A, DialUpState, Ownable {
    // solhint-disable-next-line no-empty-blocks
    constructor() ERC721A("d56k Operating Systems", "D56K") {}

    event Overwrite(uint16 osId, uint16 diskId, address owner);

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getDisk(uint16 _diskId) public view returns (Disk memory) {
        return disks[_diskId];
    }

    function getOSWrites(uint16 _odId) public view returns (uint8, uint16[] memory) {
        require(operatingSystms[_odId].writes > 0, "OS not written");
        uint16[] memory written = new uint16[](operatingSystms[_odId].writes);

        for (uint8 i = 0; i < operatingSystms[_odId].writes; i++) {
            written[i] = operatingSystms[_odId].disks[i];
        }

        return (operatingSystms[_odId].writes, written);
    }

    function upload(uint16 _diskId) external payable {
        require(disks[_diskId].loaded, "Disk not loaded");
        require(disks[_diskId].active, "Disk not active");
        require(disks[_diskId].burn > 0, "Disk not burnable");
        require(disks[_diskId].uploads > 0, "Disk not uploadable");
        require(totalSupply() < TOTAL_SUPPLY, "All OS uploaded");

        uint16 _burn = disks[_diskId].burn;
        uint256 _uploads = disks[_diskId].uploads;

        uint256[] memory _tokenIds = new uint256[](1);
        _tokenIds[0] = _diskId;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = _burn;

        if (_uploads + totalSupply() > TOTAL_SUPPLY) {
            _uploads = TOTAL_SUPPLY - totalSupply();
        }

        if (msg.value < MINT_PRICE * _uploads) revert EthValueTooLow();

        if (IDisk(diskAddress).balanceOf(msg.sender, _diskId) < _burn) revert NotEnoughTokens();

        IDisk(diskAddress).burn(msg.sender, _tokenIds, _amounts);

        _mint(msg.sender, _uploads);
    }

    function loadDisk(uint16 _diskId, uint16 _burn, uint16 _uploads, uint16 _writes) external onlyOwner {
        require(_uploads < TOTAL_SUPPLY, "TOO MANY UPLOADS");
        Disk memory newDisk;
        newDisk.burn = _burn;
        newDisk.uploads = _uploads;
        newDisk.writes = _writes;
        newDisk.active = false;
        newDisk.loaded = true;

        disks[_diskId] = newDisk;
    }

    function toggleDisk(uint16 _diskId) external onlyOwner {
        require(disks[_diskId].loaded, "Disk not loaded");
        disks[_diskId].active = !disks[_diskId].active;
    }

    function overwrite(uint16 _osId, uint16 _diskId) external {
        require(disks[_diskId].loaded, "Disk not loaded");
        require(disks[_diskId].active, "Disk not active");
        require(disks[_diskId].burn > 0, "Disk not burnable");
        require(disks[_diskId].writes > 0, "Disk not writeable");
        require(_exists(_osId), "OS not loaded");
        require(ownerOf(_osId) == msg.sender, "Access Denied");

        uint256 _writes = disks[_diskId].writes;

        uint256[] memory _tokenIds = new uint256[](1);
        _tokenIds[0] = _diskId;

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = _writes;

        IDisk(diskAddress).burn(msg.sender, _tokenIds, _amounts);

        operatingSystms[_osId].disks[operatingSystms[_osId].writes] = _diskId;
        operatingSystms[_osId].writes = operatingSystms[_osId].writes + 1;

        emit Overwrite(_osId, _diskId, msg.sender);
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!baseURIFrozen, "Base URI is frozen");
        baseURI = _newBaseURI;
    }

    function freezeBaseURI() external onlyOwner {
        require(!baseURIFrozen, "Base URI is already frozen");
        baseURIFrozen = true;
    }

    function setAdminWallet(address _adminWallet) external onlyOwner {
        adminWallet = _adminWallet;
    }

    function setDiskAddress(address _diskAddress) external onlyOwner {
        diskAddress = _diskAddress;
    }

    function withdrawFunds() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool teamSuccess, ) = adminWallet.call{ value: address(this).balance }("");
        require(teamSuccess, "Transfer failed.");
    }
}