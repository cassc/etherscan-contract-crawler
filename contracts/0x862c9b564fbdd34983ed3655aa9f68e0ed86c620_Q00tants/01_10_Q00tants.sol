// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./ERC721AGuardable.sol";
import "openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Q00tants is ERC721AGuardable, Ownable {
    error NotEnoughTokens();
    error CallerMustBeQ00t(address q00t, address sender);

    uint256 public MAX_SUPPLY = 5000;

    string private baseTokenURI;
    bool private isRevealed;
    address private q00tsContract;

    constructor(string memory _baseTokenURI) ERC721AGuardable("q00tants", "q00tants") {
        baseTokenURI = _baseTokenURI;
    }

    function mint(address recipient, uint256 amount) external payable {
        if (msg.sender != q00tsContract) revert CallerMustBeQ00t(q00tsContract, msg.sender);
        if (totalSupply() + amount > MAX_SUPPLY) revert NotEnoughTokens();

        _mint(recipient, amount);
    }

    function airdrop(address[] calldata owners, uint[] calldata amounts) external onlyOwner {
        if (owners.length != amounts.length) revert();

        for (uint256 i = 0; i < owners.length; i++) {
            uint256 amount = amounts[i];
            if (totalSupply() + amount > MAX_SUPPLY) revert NotEnoughTokens();

            _mint(owners[i], amount);
        }
    }

    function numberMinted(address owner) external view returns(uint256) {
        return _numberMinted(owner);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!isRevealed) return _baseURI();

        return super.tokenURI(tokenId);
    }

    function setRevealed(string calldata _baseTokenURI) external onlyOwner {
        setBaseTokenURI(_baseTokenURI);
        isRevealed = true;
    }

    function burnExcess() external onlyOwner {
        MAX_SUPPLY = totalSupply();
    }

    function setBaseTokenURI(string calldata _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setQ00tsContract(address _q00tsContract) external onlyOwner {
        q00tsContract = _q00tsContract;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}