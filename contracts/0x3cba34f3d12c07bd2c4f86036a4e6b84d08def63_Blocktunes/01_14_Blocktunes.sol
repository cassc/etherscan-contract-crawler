//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Blocktunes is ERC721Enumerable, Ownable, ReentrancyGuard {
    string public ipRightsHash;

    bool public saleIsActive;
    bool public mintlistIsActive;
    bool public teamMinted;

    uint256 public constant PRICE = 0.18 ether;
    uint256 public constant MAX_SUPPLY = 501;
    uint256 public constant TEAM_ALLOCATION = 100;

    mapping(address => uint256) public mintlist;
    string private uri;

    constructor() ERC721("blocktunes", "TUNE") {}

    function mint() external payable nonReentrant {
        require(saleIsActive, "sale not active");
        require(totalSupply() <= MAX_SUPPLY, "sold out");
        if (mintlistIsActive) {
            require(
                mintlist[msg.sender] > 0,
                "not mintlisted or already minted"
            );
            mintlist[msg.sender]--;
        }
        require(msg.value == PRICE, "wrong msg.value");
        _safeMint(msg.sender, totalSupply());
    }

    function mintTeam() external onlyOwner {
        require(!teamMinted, "team already minted");
        teamMinted = true;
        for (uint256 i; i < TEAM_ALLOCATION; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    function setSaleIsActive(bool _saleIsActive) external onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function setMintlistIsActive(bool _mintlistIsActive) external onlyOwner {
        mintlistIsActive = _mintlistIsActive;
    }

    function setMintlist(
        address[] calldata _addresses,
        uint256[] calldata _approved
    ) external onlyOwner {
        require(
            _addresses.length == _approved.length,
            "array length doesn't match"
        );
        for (uint256 i; i < _addresses.length; i++) {
            mintlist[_addresses[i]] = _approved[i];
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function setIpRightsHash(string memory _ipRightsHash) public onlyOwner {
        ipRightsHash = _ipRightsHash;
    }
}