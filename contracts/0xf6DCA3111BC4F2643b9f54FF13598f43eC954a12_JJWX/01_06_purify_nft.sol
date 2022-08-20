// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

contract JJWX is ERC721A, Ownable {
    enum Status {
        Waiting,
        Started,
        Finished,
        AllowListOnly
    }

    Status public status;
    string public baseURI;
    uint256 public constant MAX_MINT_PER_ADDR = 4;
    uint256 public MAX_SUPPLY = 440;

    mapping(address => uint256) public allowlist;

    constructor(string memory initBaseURI) ERC721A("JIEJINGWENXUE", "JJWX") {
        baseURI = initBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 quantity) external payable {
        require(status == Status.Started, "JJWX: Not started yet.");
        require(tx.origin == msg.sender, "JJWX: Not callable.");
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINT_PER_ADDR,
            "JJWX: max 4 per address."
        );
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "JJWX: Not enough NFTs."
        );

        _safeMint(msg.sender, quantity);
    }

    function allowlistMint(uint256 quantity) external payable {
        require(allowlist[msg.sender] > 0, "JJWX: Not in the white list.");
        require(
            status == Status.Started || status == Status.AllowListOnly,
            "JJWX: Not started yet for public."
        );
        require(tx.origin == msg.sender, "JJWX: Not callable.");
        require(quantity <= allowlist[msg.sender], "JJWX: Too much.");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "JJWX: Not enough NFT."
        );
        allowlist[msg.sender] = allowlist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);

    }

    function seedAllowlist(
        address[] memory addresses,
        uint256[] memory numSlots
    ) external onlyOwner {
        require(addresses.length == numSlots.length, "JJWX: Wrong address.");
        for (uint256 i = 0; i < addresses.length; i++) {
            allowlist[addresses[i]] = numSlots[i];
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setStatus(Status _status) external onlyOwner {
        status = _status;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId)))
            : "";
    }

    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = recipient.call{value: balance}("");
        require(success, "JJWX: hmmmm");
    }
}