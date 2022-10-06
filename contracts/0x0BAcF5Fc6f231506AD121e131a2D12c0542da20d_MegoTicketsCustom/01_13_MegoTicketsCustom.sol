// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";

/**
 * @title MegoTickets
 * Ticketing contract with on-chain metadata
 * https://mego.cx
 * Created by: YOMI <https://yomi.digital>
 */
 
contract MegoTicketsCustom is ERC721, Ownable, Pausable {
    struct Ticket {
        bool exists;
        bool active;
        string name;
        string description;
        string image;
        uint16 numMinted;
        uint16 maxSupply;
    }

    uint256 private _tokenIdCounter;

    mapping(string => Ticket) public _tickets;
    mapping(uint256 => string) public _idToTier;
    mapping(uint256 => string) public _idToSerial;
    mapping(address => bool) public _proxies;

    bool isPaused = false;

    event Minted(uint256 indexed tokenId);
    event Claimed(uint256 indexed tokenId);

    constructor(string memory _name, string memory _ticker)
        ERC721(_name, _ticker)
    {}

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function setProxyAddress(address proxy, bool state) external onlyOwner {
        _proxies[proxy] = state;
    }

    function manageTickets(
        string memory tier,
        string memory name,
        string memory description,
        string memory image,
        uint16 maxSupply,
        bool active
    ) external onlyOwner {
        require(
            !_tickets[tier].exists,
            "Can't manage this tier."
        );
        _tickets[tier].exists = true;
        _tickets[tier].name = name;
        _tickets[tier].description = description;
        _tickets[tier].image = image;
        _tickets[tier].maxSupply = maxSupply;
        _tickets[tier].active = active;
    }

    function returnMinted(string memory tier) external view returns (uint16) {
        Ticket memory ticket = _tickets[tier];
        return ticket.numMinted;
    }

    function returnActive(string memory tier) external view returns (bool) {
        Ticket memory ticket = _tickets[tier];
        return ticket.active;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        string memory tier = _idToTier[id];
        Ticket memory ticket = _tickets[tier];
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        ticket.name,
                        " #",
                        _idToSerial[id],
                        '", "description": "',
                        ticket.description,
                        '", "image": "',
                        ticket.image,
                        '", "attributes": [',
                        '{"trait_type": "TIER", "value": "',
                        tier,
                        '"}',
                        "]}"
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    function mint(
        address receiver,
        string memory tier,
        uint256 amount
    ) external {
        require(_proxies[msg.sender], "MegoTickets: Only proxy can mint");
        require(
            _tickets[tier].exists,
            "MegoTickets: Minting a non-existent tier"
        );
        require(_tickets[tier].active, "MegoTickets: Tier is not active");
        require(
            _tickets[tier].numMinted + amount <= _tickets[tier].maxSupply,
            "MegoTickets: Max supply reached"
        );

        Ticket storage ticket = _tickets[tier];

        for (uint256 k = 0; k < amount; k++) {
            _tokenIdCounter += 1;
            uint256 tokenId = _tokenIdCounter;
            ticket.numMinted++;
            _idToSerial[tokenId] = Strings.toString(ticket.numMinted);
            _idToTier[tokenId] = tier;
            _safeMint(receiver, tokenId);
            emit Minted(tokenId);
        }
    }

    function pause() public onlyOwner {
        _pause();
        isPaused = true;
    }

    function unpause() public onlyOwner {
        _unpause();
        isPaused = false;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}