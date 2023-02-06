// Deployed 5th Feb 2023 11:52
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract OHAYOCHIBI is ERC721A, Ownable {
    uint256 public immutable maxNumberMint; // 1
    uint16 public immutable chibiSupply; // 370 (token starts at 1. Actually 369)
    uint16 public immutable teamReserve; // 30
    uint256 public mintPrice = 0.001 ether;
    address private _teamAddress;
    string private _baseTokenURI;

    constructor(
        uint256 maxNumberMint_,
        uint16 chibiSupply_,
        uint16 teamReserve_
    ) ERC721A("OHAYOCHIBI", "OC", maxNumberMint_, chibiSupply_) {
        maxNumberMint = maxNumberMint_;
        chibiSupply = chibiSupply_;
        teamReserve = teamReserve_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // Reserve for team
    function reserveForTeam(uint256 quantity) public onlyOwner {
        require(
            totalSupply() + quantity <= chibiSupply,
            "No More Chibis left!"
        );
        require(
            balanceOf(_teamAddress) <= teamReserve,
            "No chibis left for the team."
        );
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(_teamAddress, maxNumberMint);
        }
    }

    function mintChibi() external payable callerIsUser {
        require(totalSupply() + 1 <= chibiSupply, "No More Chibis left!");
        require(msg.value >= mintPrice, "No negative numbers");
        require(numberMinted(msg.sender) < 1, "Can only mint once");
        require(
            balanceOf(msg.sender) == 0,
            "Only 1 chibi per account please :>"
        );
        _safeMint(_msgSender(), 1);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setTeamAddress(address teamAddress) external onlyOwner {
        _teamAddress = teamAddress;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // Won't be needed, but kept in case.
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }
}