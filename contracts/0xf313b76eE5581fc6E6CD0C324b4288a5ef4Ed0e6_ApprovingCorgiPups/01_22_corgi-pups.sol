// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC721AV4.sol";

contract ApprovingCorgiPups is ERC721A, Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    mapping(address => uint256[]) public _ownedTokens;

    string public baseURI;
    uint256 public maxPups = 9999;
    uint256 public giveaway = 300;
    bool public isBreedingActive = true;

    uint256 public numberOfAllowedBreeding = 1;

    uint256 public incubationPeriod = 3 days;

    struct Genes {
        uint256 p1;
        uint256 p2;
    }

    mapping(uint256 => uint256) public numberOfBreedTimes;
    mapping(address => uint256) addressBlockBought;
    mapping(uint256 => Genes) public parents;
    mapping(uint256 => uint256) public hatchDate;

    IERC721Enumerable public corgiContract;
    ERC20Burnable public thorgiContract;

    address signer;
    mapping(address => bool) allowedMinters;

    constructor(
        address _signer,
        address _corgi,
        address _thorgi
        ) ERC721A("Approving Corgi Pups", "APUPPIES")  {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        signer = _signer;
        corgiContract = IERC721Enumerable(_corgi);
        thorgiContract = ERC20Burnable(_thorgi);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_MINT_ON_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(isBreedingActive, "PHASE_1_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    /**
     * Breed Corgis
     */
    function breedCorgis(uint256 _parent1, uint256 _parent2, uint64 expireTime, bytes memory sig) external isSecured(1) {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender,expireTime));
        require(isAuthorized(sig,digest),"CONTRACT_MINT_NOT_ALLOWED");
        require(numberOfBreedTimes[_parent1] < numberOfAllowedBreeding, "REACHED_MAXIMUM_BREED_ALLOWED_P1");
        require(numberOfBreedTimes[_parent2] < numberOfAllowedBreeding, "REACHED_MAXIMUM_BREED_ALLOWED_P1");

        addressBlockBought[msg.sender] = block.timestamp;
        
        hatchDate[totalSupply()] = block.timestamp + incubationPeriod;
        parents[totalSupply()] = Genes(_parent1, _parent2);
        numberOfBreedTimes[_parent1] += 1;
        numberOfBreedTimes[_parent2] += 1;
        _ownedTokens[msg.sender].push(totalSupply());
        _safeMint( msg.sender, 1 );
    }

    function breedForMinter(address minter, uint256 numToMint) public onlyRole(MINTER_ROLE) {
        _safeMint(minter, numToMint);
    }

    function mintForExisting(address _owner, uint256 numToMint, uint256 _parent1, uint256 _parent2) external onlyOwner {
        hatchDate[totalSupply()] = block.timestamp;
        parents[totalSupply()] = Genes(_parent1, _parent2);
        numberOfBreedTimes[_parent1] += 1;
        numberOfBreedTimes[_parent2] += 1;
        _ownedTokens[msg.sender].push(totalSupply());
        _safeMint( _owner, numToMint );
    }

    function speedUp(uint256 _tokenId, uint256 _hours) external isSecured(1) { 
        require(ownerOf(_tokenId) == msg.sender, "NOT_THE_OWNER");
        require(hatchDate[_tokenId] > 0, "NO_HATCHDATE");

        if (_hours == 24) {
            hatchDate[_tokenId] -= 1 days;
            thorgiContract.transferFrom(msg.sender, address(this), 100 * 1e18);
        } else if (_hours == 48) {
            hatchDate[_tokenId] -= 2 days;
            thorgiContract.transferFrom(msg.sender, address(this), 200 * 1e18);
        }
    }

    /**
     * reserve Corgis for giveaways
     */
    function mintPupsForGiveaway(uint256 numberOfTokens) external onlyOwner {
        require(numberOfTokens < giveaway, "CANNOT_MINT_MORE_GIVEAWAYS");

        _safeMint(msg.sender, numberOfTokens);

        giveaway -= numberOfTokens;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function toggleBreedingActive() external onlyOwner {
        isBreedingActive = !isBreedingActive;
    }

    function setGiveawayNumber(uint256 _giveaway) external onlyOwner {
        giveaway = _giveaway;
    }

    function setThorgiContract(address _thorgiAddress) external onlyOwner {
        thorgiContract = ERC20Burnable(_thorgiAddress);
    }

    function setNumberOfBreedingTimes(uint256 _numberOfAllowedBreeding) external onlyOwner {
        numberOfAllowedBreeding = _numberOfAllowedBreeding;
    }

    function isAuthorized(bytes memory sig,bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMinterRole(address minter) external onlyOwner {
        _setupRole(MINTER_ROLE, minter);
    }

    function setMinterRoleToAddress(address minter) external onlyOwner {
        allowedMinters[minter] = true;
    }
    
    /**
     * Withdraw Ether
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw payment");
    }
}