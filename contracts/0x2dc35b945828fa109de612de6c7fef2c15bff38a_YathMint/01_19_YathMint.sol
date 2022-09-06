// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IYathGame {
    function getNFTState(uint256) external view returns(uint8);
}

import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract YathMint is ERC721A, Ownable, ReentrancyGuard {

    //safemath to be sure of what we do here
    using SafeMath for uint256;

    //To concatenate the URL of an NFT
    using Strings for uint256;

    //Maximum number of NFTs an address can mint
    uint256 public maxMintAllowed = 2;
    //Timestamp mint start
    uint256 public startMint;

    //Number of NFTs in the collection
    uint256 public constant MAX_SUPPLY = 5555;

    //Price of one NFT in sale
    uint256 public priceSale = 0.0389 ether;

    //WL Premint + Collab
    bytes32 public premintMerkleRoot;

    //URI of the NFTs when not revealed
    string public unrevealedURI;
    //URI of the NFTs when revealed
    string public aliveURI;
    //URI of the NFTs when caracter die
    string public deadURI;
    //The extension of the file containing the Metadatas of the NFTs
    string public baseExtension = ".json";
    //Are the NFT revealed ?
    bool public isRevealed = false;

    //count the number of mint per wallet
    mapping(address => uint) public mintNFTsperWallet;

    //list of the contract steps
    enum steps {presale, mint, over}
    steps currentStep;

    //list of the mint steps
    enum mintSteps {whitelist, publicMint, over}
    mintSteps currentMintStep;

    //The game contract address
    address public gameAddress;

    //Constructor of the collection
    constructor(bytes32 _premintMerkleRoot, uint256 _startMint, string memory _unrevealedURI, string memory _aliveURI, string memory _deadURI)
            ERC721A("Hero quest chapter 1", "HRQT") {
        transferOwnership(msg.sender);
        premintMerkleRoot = _premintMerkleRoot;
        unrevealedURI = _unrevealedURI;
        startMint = _startMint;
        aliveURI = _aliveURI;
        deadURI = _deadURI;
        currentStep = steps.presale;
    }

    //Internal function to get the time
    function currentTime() public view returns(uint256) {
        return block.timestamp;
    }

    // For internal use only
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // Change mint price
    function changePriceSale(uint256 _priceSale) external onlyOwner {
        priceSale = _priceSale;
    }

    // Change mint start time
    function changeStartMint(uint256 _startMint) external onlyOwner {
        startMint = _startMint;
    }

    // Change URI metadatas alive
    function setAliveUri(string memory _aliveURI) external onlyOwner {
        aliveURI = _aliveURI;
    }

    // Change URI metadatas not revealed
    function setUnrevealedURI(string memory _unrevealedURI) external onlyOwner {
        unrevealedURI = _unrevealedURI;
    }

    // Change URI metadatas dead
    function setDeadURI(string memory _deadURI) external onlyOwner {
        deadURI = _deadURI;
    }

    // Change URI metadatas dead
    function setRevealed() external onlyOwner {
        isRevealed = true;
    }

    // Set the game contract address to get the NFT state
    function setGameAddress(address _gameAddress) external onlyOwner {
        gameAddress = _gameAddress;
    }

    function forceOver() external onlyOwner {
        currentStep = steps.over;
        currentMintStep = mintSteps.over;
    }

    // internal function for opensea usage
    function _baseURI() internal view virtual override returns (string memory) {
        return aliveURI;
    }

    // Get current step of the contract
    function getCurrentStep() public view returns(string memory) {
        if (currentStep == steps.presale) {
            return "presale";
        }
        else if (currentStep == steps.mint) {
            return "mint";
        }
        else {
            return "over";
        }
    }

    // Get current mint step of the contract
    function getMintStep() public view returns(mintSteps) {
        //if not presale or mint then it's over
        if (currentStep != steps.presale && currentStep != steps.mint) {
            return mintSteps.over;
        }
        else {
            uint256 currentTimestamp = currentTime();
            // if it's less than 4h after mint start then it's whitelist time
            if (currentTimestamp < startMint + 3 hours) {
                return mintSteps.whitelist;
            }
            // else it's just public
            else {
                return mintSteps.publicMint;
            }
        }
    }

    // Can we mint now ?
    function isMintReadyToStart() public view returns(bool) {
        if (currentStep == steps.presale) {
            if (currentTime() >= startMint) {
                return true;
            }
        }
        return false;
    }

    // Mint function
    function mint(uint256 _quantity, address _wallet, bytes32[] calldata _proof) external payable nonReentrant {
        //can we start now if it's presale step ?
        if (currentStep == steps.presale && isMintReadyToStart()) {
            currentStep = steps.mint;
        }
        //if it's presale step it's too soon
        require(currentStep != steps.presale, "The mint has not started yet.");
        //if it's something else than mint it's too late
        require(currentStep == steps.mint, "The mint is over.");
        //Get the number of NFT sold
        uint256 numberNftSold = totalSupply();
        //Did the user then enought Ethers to buy ammount NFTs ?
        require(msg.value >= priceSale.mul(_quantity), "Not enought funds.");
        //If the user try to mint any non-existent token
        require(numberNftSold.add(_quantity) <= MAX_SUPPLY, "You can't mint that much NFT.");
        //If the user already mint
        require(mintNFTsperWallet[msg.sender].add(_quantity) <= maxMintAllowed, "You can't get more NFT.");
        //Check whitelist if needed
        if (getMintStep() == mintSteps.whitelist) {
            require(isPremintWhiteListed(msg.sender, _proof), "Not on the whitelist.");
        }
        //Add the playeer informations
        mintNFTsperWallet[msg.sender] = mintNFTsperWallet[msg.sender].add(_quantity);
        _safeMint(_wallet, _quantity);
        //if we reach the max supplu then it's soldout
        if (numberNftSold.add(_quantity) == MAX_SUPPLY) {
            currentStep = steps.over;
            currentMintStep = mintSteps.over;
        }
    }

    // Get the NFT URI
    function tokenURI(uint256 _nftId) public view override(ERC721A) returns (string memory) {
        //Check if the NFT exist
        require(_exists(_nftId), "This NFT doesn't exist.");
        //If the NFT are not revealed we send the unrevealed metadatas
        if (!isRevealed) {
            return string(abi.encodePacked(unrevealedURI, "unrevealed", baseExtension));
        }
        else {
            //If the NFT status id dead then we return the dead URI
            if (gameAddress != address(0)) {
                if(IYathGame(gameAddress).getNFTState(_nftId) == 2) {
                    return string(abi.encodePacked(deadURI, _nftId.toString(), baseExtension));
                }
            }
            //In all other case it's the alive metadatas
            return string(abi.encodePacked(aliveURI, _nftId.toString(), baseExtension));
        }
    }

    // Whitelist functions for collab and premint
    function setPremintMerkleRoot(bytes32 _premintMerkleRoot) external onlyOwner {
        premintMerkleRoot = _premintMerkleRoot;
    }
    function leafPremint(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }
    function isPremintWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verifyPremint(leafPremint(_account), _proof);
    }
    function _verifyPremint(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, premintMerkleRoot, _leaf);
    }

    //Send the cashprize to the game contract
    function sendCashPrize() external payable nonReentrant onlyOwner {
        require(gameAddress != address(0), "You must provide a valid contract");
        payable(gameAddress).transfer(address(this).balance);
    }

    //Withdraw all the ETH on the contract when the gam is over since a long time
    function forceWithdraw() external payable nonReentrant onlyOwner {
        //Owner can force the withdraw only if he wait enough ! (30 days)
        require(currentTime() >= startMint + 30 days, "You can't force the withdraw now.");
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}