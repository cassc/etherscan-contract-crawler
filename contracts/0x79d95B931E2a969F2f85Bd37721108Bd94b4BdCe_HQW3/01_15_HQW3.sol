// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";

contract HQW3 is ERC1155, DefaultOperatorFilterer, Ownable, ReentrancyGuard {
    string public name = "Owner";
    string public symbol = "HQW";
    string public base_uri =
        "https://www.headquarterweb3.at/assets/media/";

    uint256 public PUBLIC_PRICE = 2 ether;

    uint256 public constant Owner = 1;
    uint256 public OWNER_MAX_SUPPLY = 999;
    uint256 public OWNER_TOTAL_SUPPLY = 0;

    enum Stage {
        NONE,
        PUBLIC,
        FINAL
    }

    Stage stage = Stage.NONE;


    mapping(address => uint256) private numberMinted;

    constructor() ERC1155("") {
    }

    function getNumberMinted(address owner) public view returns (uint256) {
        return numberMinted[owner];
    }

    function setPublicStage() external onlyOwner nonReentrant {
        stage = Stage.PUBLIC;
    }

    function setNoneStage() external onlyOwner nonReentrant {
        stage = Stage.NONE;
    }

    function setFinialStage() external onlyOwner nonReentrant {
        stage = Stage.FINAL;
    }


    function isPublicMint() external view returns (bool) {
        return stage == Stage.PUBLIC;
    }

    function isFinalMint() external view returns (bool) {
        return stage == Stage.FINAL;
    }

    function publicMintOwner(uint256 amount) external
        payable
        nonReentrant {
        require(stage == Stage.PUBLIC, "Public mint hasn't started yet");
        require(
            OWNER_TOTAL_SUPPLY + amount <= OWNER_MAX_SUPPLY,
            "Supply Limit exceeded"
        );

        require(msg.value == (PUBLIC_PRICE * amount), "Invalid ether amount");

        _mintOwner(msg.sender, amount);
    }

    function finalMint(uint256 amount) external onlyOwner nonReentrant {
        require(
            stage == Stage.FINAL,
            "Final mint hasn't started yet"
        );

        require(
            OWNER_TOTAL_SUPPLY + amount <= OWNER_MAX_SUPPLY,
            "Supply Limit exceeded"
        );

        _mintOwner(msg.sender, amount);
    }

    function _mintOwner(address minter, uint256 amount) internal {
        OWNER_TOTAL_SUPPLY += amount;
        _mint(minter, Owner, amount, "");
    }

    // Config contract
    function uri(uint256 id) public view override returns (string memory) {
        return
            string(abi.encodePacked(base_uri, Strings.toString(id), ".json"));
    }

    function setBaseUri(string memory _base_uri) external onlyOwner nonReentrant {
        base_uri = _base_uri;
    }

    function setPublicPrice(uint256 price) external onlyOwner nonReentrant {
        PUBLIC_PRICE = price;
    }


    function withdraw() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool successful, ) = payable(owner()).call{value: amount}("");
        require(successful, "Failed to transfer");
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}