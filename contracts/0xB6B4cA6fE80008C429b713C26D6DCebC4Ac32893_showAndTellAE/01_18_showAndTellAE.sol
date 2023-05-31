// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ERC721Psi.sol";

import "IERC2981.sol";
import "ReentrancyGuard.sol";
import "Ownable.sol";
import "Counters.sol";

interface SchoolYard {
    function contractURI() external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract showAndTellAE is ERC721Psi, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    bool public contractRoyalties = true;
    bool public bComFun = false;

    uint256 public constant MAX_DROP = 3750;
    uint256 public constant SCHOOL_ACTIVITIES = 2000;
    SchoolYard schoolAddress;
    address private _creators;

    string private _contractURI;
    string private _metadataBaseURI;

    // ** MODIFIERS ** //
    // *************** //

    modifier allocTokens(uint256[] memory numToMint) {
        uint256 count;
        for(uint256 i = 0; i < numToMint.length; i++) {
            count += numToMint[i];
        }
        require(
            totalSupply() + count-1 <= MAX_DROP,
            "Sorry, there are not enough artworks remaining."
        );
        _;
    }

    mapping(address => bool) private whitelistedContract; 
    mapping(address => uint256) private contractAllowance; 
    mapping(address => uint256) private contractClaimCount; 

    constructor(
        string memory _cURI,
        string memory _mURI,
        address _creatorAdd,
        address _schAdd
    ) ERC721Psi("Show And Tell Alpha Elementary", "SAT") {
        _contractURI = _cURI;
        _metadataBaseURI = _mURI;
        _creators = _creatorAdd;
        schoolAddress = SchoolYard(_schAdd);
    }

    // ** AIRDROP NFT FUNC ** //
    // ********************** //

    function showAndTell(address[] memory _claimList, uint256[] memory _ids)
        external
        nonReentrant
        allocTokens(_ids)
        onlyOwner
    {
        require(_claimList.length == _ids.length, "Ensure you provide the number of tokens for every address");
        for (uint256 i = 0; i < _claimList.length; i++) {
            _safeMint(_claimList[i], _ids[i]);
        }
    }


    function communityFun(address _award, uint256 num)
        external
        nonReentrant
        returns (uint256)
    {
        require(whitelistedContract[msg.sender] == true, "This address is not whitelisted");
        require(contractClaimCount[msg.sender] + num < contractAllowance[msg.sender], "Requesting too many tokens");
        require(totalSupply() + num <= SCHOOL_ACTIVITIES + MAX_DROP, "No tokens left");
        require(bComFun == true, "This function is currently disabled");

        contractClaimCount[msg.sender] + num;
        _safeMint(_award, num);

        return totalSupply()-1;
    }

    function getOwnersTokens(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        require(balanceOf(_owner) > 0, "You don't currently hold any tokens");
        uint256 tokenCount = balanceOf(_owner);
        uint256 foundTokens = 0;
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                tokenIds[foundTokens] = i;
                foundTokens++;
            }
        }
        return tokenIds;
    }
    

    function returnAddressesOfAEHolder(uint256[] calldata tokenIds) external view onlyOwner returns (address[] memory) {
        
        address[] memory fetchedAdd = new address[](tokenIds.length);

        for(uint256 i = 0; i < tokenIds.length; i++) {
            fetchedAdd[i] = schoolAddress.ownerOf(tokenIds[i]);
        }
        return fetchedAdd;
    }

    function checkWhitelistedContract(address _addr) external view returns (bool) {
        return whitelistedContract[_addr];
    }

    function checkContractClaimed(address _addr) external view returns (uint256) {
        return contractClaimCount[_addr];
    }

    // ** SETTINGS ** //
    // ************** //

    function _baseURI() internal view override returns (string memory) {
        return _metadataBaseURI;
    }

    function metaURI(string calldata _URI) external onlyOwner {
        _metadataBaseURI = _URI;
    }

    function cntURI(string calldata _URI) external onlyOwner {
        _contractURI = _URI;
    }

    function updateSchoolyard(address _addr) external onlyOwner {
        schoolAddress = SchoolYard(_addr);
    }

    function whitelistContract(address[] memory _addr, uint256[] memory _alloc) external onlyOwner {
        for(uint256 i = 0; i < _addr.length; i++) {
            whitelistedContract[_addr[i]] = true;
            contractAllowance[_addr[i]] = _alloc[i];
        }
    }

    function removeContract(address _addr) external onlyOwner {
        whitelistedContract[_addr] = false;
    }

    function flipCommunityFun() external onlyOwner {
        bComFun = !bComFun;
    }


    /**
     * @dev Reserve ability to make use of {IERC165-royaltyInfo} standard to implement royalties.
     */
    function toggleRoyalties() external onlyOwner {
        contractRoyalties = !contractRoyalties;
    }

    // ** READ ONLY DATA ** //
    // ******************** //

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function setCreator(address to) external onlyOwner returns (address) {
        _creators = to;
        return _creators;
    }

    /**
     * @dev See {IERC165-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Nonexistent token");
        require(contractRoyalties == true, "Royalties dissabled");

        return (address(_creators), (salePrice * 7) / 100);
    }
}