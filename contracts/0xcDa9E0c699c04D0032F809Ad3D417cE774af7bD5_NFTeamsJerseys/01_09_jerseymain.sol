// jerseys.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "https://github.com/chiru-labs/ERC721A/contracts/ERC721A.sol";
import "https://github.com/chiru-labs/ERC721A/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface iNFTeamsMinter {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}

contract NFTeamsJerseys is ERC721A, Ownable, ERC721AQueryable {
    // Sale state control variables
    bool public burningEnabled = false;
    bool public mintingEnabled = false;
    mapping(uint256 => bool) public claimedByTeamId;

    // Metadata variables
    string public _baseURI_;
    
    // External contracts
    address public nfteamsContractAddress;
    iNFTeamsMinter nfteamsContract;

    constructor() ERC721A("NFTeamsJerseys", "NFTeamsJerseys") {
        // placeholder for testing
        _baseURI_ = "https://s3.ap-southeast-2.amazonaws.com/jersey-meta.nfteams.club/";
        // PROD: 0x03f5CeE0d698c24A42A396EC6BDAEe014057d4c8;
        // Goerli: 0x182c8F3cAD0795C3863E62a8C5Aa1a554f2C6f34
        nfteamsContractAddress = 0x03f5CeE0d698c24A42A396EC6BDAEe014057d4c8;
        nfteamsContract = iNFTeamsMinter(nfteamsContractAddress);
    }

    /** *********************************** **/
    /** ********* State Functions ********* **/
    /** *********************************** **/
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _baseURI_ = _newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURI_;
    }

    function toggleBurningEnabled() external onlyOwner {
        burningEnabled = !burningEnabled;
    }

    function toggleMintingEnabled() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function setNFTeamsContractAddress(address _address) external onlyOwner {
        nfteamsContractAddress = _address;
        nfteamsContract = iNFTeamsMinter(_address);
    }

    /** *********************************** **/
    /** ********* First Token = 1 ********* **/
    /** *********************************** **/
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /** *********************************** **/
    /** ********* Minting Functions ******* **/
    /** *********************************** **/
    function mint(uint256[] memory teamIds) external payable {
        require(mintingEnabled, "Minting is not enabled");

        // Check balance of nfteams
        uint256 balance = nfteamsContract.balanceOf(msg.sender);
        require(balance > 0, "Must be an NFTeams holder to mint");

        // Iterate through each team id specified
        for (uint256 k = 0; k < teamIds.length; k++) {
            // Check if jersey has already been claimed for this team
            uint256 teamId = teamIds[k];
            if (claimedByTeamId[teamId] == true) {
                revert(string(abi.encodePacked("Jersey for Team #", Strings.toString(teamId), " has already been claimed")));
            }

            // Confirm team is owned by the user
            address teamOwner = nfteamsContract.ownerOf(teamId);
            if (msg.sender != teamOwner) {
                revert(string(abi.encodePacked("You do not own Team #", Strings.toString(teamId))));
            }
        }

        // ERC721A Mint Function
        _mint(msg.sender, teamIds.length);

        // Update claimed array
        for (uint256 k = 0; k < teamIds.length; k++) {
            uint256 teamId = teamIds[k];
            claimedByTeamId[teamId] = true;
        }
    }

    /** *********************************** **/
    /** ********* Burning Function ******** **/
    /** *********************************** **/
    function burn(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(burningEnabled, "burning is not enabled");
        require(
            isApprovedForAll(owner, _msgSender()),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }
}