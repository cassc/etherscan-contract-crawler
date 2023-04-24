pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./HIVEMIND.sol"; // Import the HIVEMIND contract
import "./PFP.sol"; // Import the PFP contract

contract ZeroDay is ERC721Enumerable, Ownable, AccessControl {
    uint256 public constant MAX_SUPPLY = 1000;
    string public baseURI = "https://hvmd.s3.amazonaws.com/metadata/";
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    HIVEMIND private _hivemind;
    PFP private _pfp; // Add the PFP reference

    constructor() ERC721("LEGION ZERO", "ZERO") {
        _grantRole(ADMIN_ROLE, 0x0a3C1bA258c0E899CF3fdD2505875e6Cc65928a8);
        _grantRole(ADMIN_ROLE, 0xE42E4F21A750C1cC1ba839E5B1e4EfC3eD1fe454);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setHivemindAddress(address hivemindAddress) public onlyRole(ADMIN_ROLE) {
        require(hivemindAddress != address(0), "Invalid address");
        _hivemind = HIVEMIND(hivemindAddress);
    }

    function setPFPAddress(address pfpAddress) public onlyRole(ADMIN_ROLE) {
        require(pfpAddress != address(0), "Invalid address");
        _pfp = PFP(pfpAddress);
    }

    function setBaseURI(string memory newuri) public onlyRole(ADMIN_ROLE){
        baseURI = newuri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function bruteF0rce(uint256[] calldata tokenIds) public {
        require(address(_pfp) != address(0), "PFP contract not set");
        require(msg.sender == address(_pfp), "Only PFPContract can call this function");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            _burn(tokenId);
        }
    }

    function zeroDayAttack(uint256[] calldata tokenIds) public {
        require(address(_hivemind) != address(0), "HIVEMIND contract not set");
        require(tokenIds.length > 0, "No token IDs provided");

        uint256 mintStartTimestamp = _hivemind.getMintStartTimestamp(); // Access the mintStartTimestamp from the HIVEMIND contract

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_hivemind.ownerOf(tokenId) == msg.sender, "Caller is not the owner of the token");
            require(block.timestamp <= mintStartTimestamp + 9 days, "Can only run the attack during the mint");
            _hivemind.burn(tokenId);
            _safeMint(msg.sender, tokenId);
        }
    }
}