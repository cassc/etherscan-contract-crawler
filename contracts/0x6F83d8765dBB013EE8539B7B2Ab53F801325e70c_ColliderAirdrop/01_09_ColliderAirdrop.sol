// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ColliderAirdrop is ERC721ABurnable, ERC721AQueryable, Ownable {
    constructor(string memory name_, string memory symbol_) ERC721A(name_, symbol_) {}
    
    mapping(address => bool) private _admins;
    bool public finished;

    event AirdropMinted(uint256 startingId, uint256 total, uint256 airdropId);

    function isAdmin(address to_) public view returns (bool) {
        return _admins[to_];
    }
    modifier onlyAdmins() {
        require(isAdmin(msg.sender), "unauthorised");
        _;
    }
    function setAdmin(address to_, bool adminStatus_) external onlyOwner {
        _admins[to_] = adminStatus_;
    }

    string public baseURI = "https://collidercraftworks.mypinata.cloud/ipfs/QmUHBzeo3dJDcMrmdSBWB15BXyRBdmM7wHoJNTVTsQuywp/";
    function _baseURI() internal view override(ERC721A) returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function airdrop(address[] calldata to_, uint256[] calldata no_, uint256 airdropIndex_) external onlyOwner {
        uint256 toLength = to_.length;
        require(toLength == no_.length, "Arrays need to have the same length");
        for(uint256 i; i < toLength; i++){
            _mint(to_[i], no_[i], airdropIndex_);
        }
    }

    function mint(address to_, uint256 no_, uint256 airdropId) external onlyAdmins {
        _mint(to_, no_, airdropId);
    }

    function _mint(address to_, uint256 no_, uint256 airdropId) internal {
        require(!finished, "Sale is now finished");
        uint256 start = _nextTokenId();
        _safeMint(to_, no_); 
        emit AirdropMinted(
            start,
            no_,
            airdropId
        );
    }

    function turnFinishedOn() external onlyOwner {
        finished = true;
    }
}