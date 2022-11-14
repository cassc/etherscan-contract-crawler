// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract LivesOfSBF is ERC721A, Ownable {

    string public baseURI = "ipfs://QmVvpotUdMDKaJZVnjfEFMaMZQqqV2vzCa4dWw9HUFVVSi/";
    string public contractURI = "ipfs://QmeXZ11J5CmuKzwcfrkS3kcerVoKJVs5b6T4qqBei7FFoH";

    uint256 constant public MAX_SUPPLY = 1000;
    bool public paused = false;

    constructor() ERC721A("LivesOfSBF", "SBF") {}

    function _startTokenId() internal override view virtual returns (uint256) {
        return 1;
    }

    function bankrupt(bytes4 _check) external payable {
        address _caller = _msgSender();
        require(!paused, "Public paused");
        require(tx.origin == _caller, "No contracts");
        require(checkWebMint(_caller, _check), "Not from web");
        require(MAX_SUPPLY >= totalSupply() + 1, "Exceeds max supply");
        require(_numberMinted(_caller) == 0, "Mint limit");

        _safeMint(_caller, 1);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to send");
    }

    function fuckCaroline(address _to, uint256 _amount) external onlyOwner {
        _safeMint(_to, _amount);
    }

    function toggleOrgy() external onlyOwner {
        paused = !paused;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setContractURI(string memory _contractURI) external onlyOwner {
        contractURI = _contractURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(
            abi.encodePacked(
              baseURI,
              Strings.toString(_tokenId),
              ".json"
            )
        ) : "";
    }

    function checkWebMint(address _sender, bytes4 _check) internal pure returns(bool){
        return bytes4(keccak256(abi.encodePacked(_sender))) == _check;
    }
}