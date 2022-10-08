// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract POORPEOPLECLUB is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;

    uint256 public TOTAL_POORPEOPLE = 3069;
    uint256 public richRoyalty = 10;


    uint256 public constant MINT_LIMIT = 2;

    address public team_royaltyWallet;

    constructor(address _team_royaltyWallet)
        ERC721A("POOR PEOPLE CLUB", "PPC")
    {
        team_royaltyWallet = _team_royaltyWallet;
    }

    function getTotalNFTsMintedSoFar() public view returns (uint256) {
        return _totalMinted();
    }

    function setRoyaltyWallet(address _teamRoyaltyWallet) public onlyOwner {
        team_royaltyWallet = _teamRoyaltyWallet;
    }

    function POORPEOPLEMINT(uint256 quantity) public payable nonReentrant {
        require(
            _totalMinted() + quantity <= TOTAL_POORPEOPLE,
            "can not mint this many"
        );
        require(
            quantity <= MINT_LIMIT - _numberMinted(msg.sender),
            "You got to poor. You can't mint anymore"
        );
        _safeMint(msg.sender, quantity);
    }

    function setRoyalty(uint256 _royaltyAmount) public onlyOwner {
        require(_royaltyAmount <= 10, "Royalty cannot be more than 10%");
        richRoyalty = _royaltyAmount;
    }

    function withdraw() public onlyOwner nonReentrant {
        payable(team_royaltyWallet).transfer(address(this).balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256)
    {
        _tokenId;
        uint256 royaltyAmount = (_salePrice / 100) * richRoyalty;
        return (team_royaltyWallet, royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}