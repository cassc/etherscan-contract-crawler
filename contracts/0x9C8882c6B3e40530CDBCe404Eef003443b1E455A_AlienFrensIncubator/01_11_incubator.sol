// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AlienFrensIncubator is ERC1155, Ownable {
    using Strings for uint256;

    address private v2contract;
    string private baseURI;
    uint256 public constant IncubatorId = 0;

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
    }

    function setV2Contract(address _v2contract) external onlyOwner {
        v2contract = _v2contract;
    }

    function getIncubatorId() external pure returns (uint256) {
        return IncubatorId;
    }

    function airdrop(address[] calldata addrs) external onlyOwner {
        for (uint256 i = 0; i < addrs.length; i++) {
            _mint(addrs[i], IncubatorId, 1, "");
        }
    }

    // @param burnTokenAddress address of Incubator holder
    function burnIncubatorForAddress(address burnTokenAddress) external {
        // burn request will come from v2 contract
        require(msg.sender == v2contract, "Invalid burner address");
        // burn baby burn
        _burn(burnTokenAddress, IncubatorId, 1);
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 typeId) public view override returns (string memory) {
        require(typeId == IncubatorId, "Only typeId 0 is supported");
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}