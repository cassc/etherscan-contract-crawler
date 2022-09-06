// SPDX-License-Identifier: UNLICENSED
/// @title AngryDickbutts
/// @notice Angry Dickbutts
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.13;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@cyberpnk/solidity-library/contracts/FeeLockable.sol";
import "@cyberpnk/solidity-library/contracts/PausableLockable.sol";
// import "hardhat/console.sol";

contract AngryDickbutts is Ownable, ERC721A, PausableLockable, FeeLockable {
    uint public maxMintQuantity = 50;
    uint public maxTotal = 10000;
    string public baseURI = '';
    string public suffixURI = '.json';
    string public unrevealedURI = '';
    bool public revealed = false;

    mapping (address => bool) public mintedWithCDBs;
    IERC721 cdbs;

    function _myMint(uint256 quantity) internal {
        require(quantity <= maxMintQuantity, "Too many");
        require(quantity + totalSupply() <= maxTotal, "Not enough left");
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        require(msg.value >= quantity * feeAmount(), "Wrong value");
        _myMint(quantity);
    }

    function mintOneWithCdbs() external whenNotPaused {
        require(!mintedWithCDBs[msg.sender], "Already minted");
        require(cdbs.balanceOf(msg.sender) > 1, "No CDBs");
        mintedWithCDBs[msg.sender] = true;
        _myMint(1);
    }

    function ownerMint(uint256 quantity) external onlyOwner {
        _myMint(quantity);
    }

    constructor(address cdbsContract) ERC721A("AngryDickbutts", "ANGRYDICKBUTT") {
        pause();
        setFeePayee(msg.sender);
        cdbs = IERC721(cdbsContract);
    }

    function setMaxMintQuantity(uint _maxMintQuantity) external onlyOwner {
        maxMintQuantity = _maxMintQuantity;
    }

    function setMaxTotal(uint _maxTotal) external onlyOwner {
        maxTotal = _maxTotal;
    }

    function withdraw() external {
        payable(feePayee).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address,
        address,
        uint256
    ) internal view {
        require(!paused(), "Paused");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    function setSuffixURI(string memory _suffixURI) external onlyOwner {
        suffixURI = _suffixURI;
    }

    function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    function reveal() external onlyOwner {
        revealed = true;
    }

    function tokenURI(uint tokenId) public view override returns(string memory) {
        if (!revealed) {
            return unrevealedURI;
        }
        return string(abi.encodePacked(super.tokenURI(tokenId), suffixURI));
    }
}