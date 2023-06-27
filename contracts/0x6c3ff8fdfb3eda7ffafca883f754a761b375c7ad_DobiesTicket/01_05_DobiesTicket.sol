// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDobies.sol";

contract DobiesTicket is ERC1155, Ownable {
    address private dobies;
    string private ticketURI;
    uint256 public MAX_SUPPLY = 350;
    uint256 public minted = 0;
    uint256 public startTime;
    string public name = "Dobies Tickets";
    string public symbol = "TICKET";

    mapping(uint256 => bool) claimed;

    constructor(
        address _dobies,
        string memory _ticketURI,
        uint256 _startTime
    ) ERC1155() {
        dobies = _dobies;
        ticketURI = _ticketURI;
        startTime = _startTime;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return ticketURI;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
    }

    function setURI(string memory _ticketURI) external onlyOwner {
        ticketURI = _ticketURI;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        MAX_SUPPLY = _maxSupply;
    }

    function mint(uint256[] calldata dobieIds) external {
        require(block.timestamp > startTime, "Minting not yet started");
        require(dobieIds.length > 0, "Should claim at least 1 Dobie");
        require(
            IDobies(dobies).isOwnerOf(msg.sender, dobieIds),
            "Must own all dobies provided"
        );
        uint256 amount = dobieIds.length;
        require(minted + amount <= MAX_SUPPLY);

        for (uint256 i = 0; i < amount; i++) {
            uint256 id = dobieIds[i];
            require(!claimed[id], "Dobie ticket already claimed");
            claimTicket(id);
        }

        minted += amount;
        _mint(msg.sender, 0, amount, "");
    }

    function claimTicket(uint256 id) internal {
        claimed[id] = true;
    }
}