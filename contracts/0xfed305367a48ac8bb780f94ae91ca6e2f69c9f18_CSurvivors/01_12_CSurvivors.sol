// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

//@author Gaetan Dumont
//@title Covid Survivors collection

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract CSurvivors is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    // IPFS URI for the NFTs
    string public baseURI;
    string public hiddenURI;

    enum Step {
        Before,
        PreSale,
        PublicSale,
        Reveal
    }

    uint private constant MAX_SUPPLY = 9998;
    uint private constant MAX_PRESALE = 10;
    uint public price = 0.24 ether;

    // Timestamp for the presale
    uint public presaleStartTime = 1670281200;

    uint private teamLength;

    // While deploying the smartcontract while ask for the uniq ids of the vip list and whitelist + the URI of the reveal and unrevealed NFT
    constructor(address[] memory _team, uint[] memory _teamShares, string memory _baseURI, string memory _hiddenURI)
            ERC721A("C Survivors", "CS") PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        hiddenURI = _hiddenURI;
        teamLength = _team.length;
    }

    // For internal use only
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Here we ask on which step we are for the website to know what to do
    function getStep() public view returns (Step) {
        uint currentTimestamp = currentTime();
        if (currentTimestamp < presaleStartTime) {
            return Step.Before;
        }
        else if (currentTimestamp >= presaleStartTime && currentTimestamp < presaleStartTime + 3 days) {
            return Step.PreSale;
        }
        else if (currentTimestamp >= presaleStartTime + 3 days && currentTimestamp < presaleStartTime + 34 days) {
            return Step.PublicSale;
        }
        else {
            return Step.Reveal;
        }
    }

    // Minting function
    function mint(uint _quantity) external payable {
        uint quantity = _quantity;
        require(price != 0, "Price is 0");
        Step currentStep = getStep();
        require(currentStep != Step.Before, "The sales has not started yet");
        if (currentStep == Step.PreSale) {
            require(totalSupply() + quantity <= MAX_PRESALE, "Max presale supply exceeded");
        }
        else if (currentStep == Step.PublicSale || currentStep == Step.Reveal) {
            require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded");
        }
        require(msg.value >= price * quantity, "Not enought funds");
        _safeMint(msg.sender, quantity);
    }

    // Update the URI of the NFTs on IPFS
    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    function setHiddenUri(string memory _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    // Internal function to get the time
    function currentTime() public view returns(uint) {
        return block.timestamp;
    }

    // Here we ask the token path in order to get it metadatas and we check of it's revealed or not
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if ( getStep() == Step.Reveal ) {
            return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
        }
        else {
            return string(abi.encodePacked(hiddenURI, "unreveal.json"));
        }
    }

    //ReleaseALL
    function releaseAll() external {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }

}