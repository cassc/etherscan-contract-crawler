// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Uppercut is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // TODO: provenance hashes - these will be set before contract deployment and will not change. empty strins for now
    string public OQO_PROVENANCE = "";
    string public TNGO_PROVENANCE = "";
    string public GNASIS_PROVENANCE = "";

    // constants
    uint256 public constant NUMBER_OF_DOMOS = 3;

    // immutable
    uint256 public immutable numberOfHeroes;
    uint256 public immutable numberOfHeroesPerDomos;

    // global vars public
    uint256 public startingIndex = 0;
    uint256 public startingIndexBlock = 0;

    // [domosOqoBalance, domosTngoBalance, domosGnasisBalance]
    uint256[3] public balances = [0, 0, 0];

    string private baseTokenURI;
    address public season2ContractAddress;

    mapping(uint256 => uint256) public mintIndexToDomosIndex; // between 0 and 2
    mapping(uint256 => uint256) public mintIndexToHeroInDomosIndex; // between 0 and numberOfHeroesPerDomos

    constructor(uint32 _numberOfHeroes) ERC721A("Uppercut", "HERO") {
        require(_numberOfHeroes % NUMBER_OF_DOMOS == 0, "heroes % 3 == 0");
        numberOfHeroes = _numberOfHeroes;
        numberOfHeroesPerDomos = _numberOfHeroes / NUMBER_OF_DOMOS;
    }

    function teamMint() external onlyOwner {
        require(_currentIndex == 0, "Sold out");

        uint256 _domosId = 0;

        for (uint256 i = _currentIndex; i < numberOfHeroes; i++) {
            _domosId = i % NUMBER_OF_DOMOS;
            mintIndexToHeroInDomosIndex[i] = uint256(i / 3);
            mintIndexToDomosIndex[i] = _domosId;
        }

        uint256 perDomos = numberOfHeroes / NUMBER_OF_DOMOS;

        balances = [perDomos, perDomos, perDomos];

        _safeMint(msg.sender, numberOfHeroes);
    }

    function airdrop(address[] calldata _addresses, uint256[] calldata ids)
        external
        onlyOwner
    {
        require(
            _addresses.length == ids.length,
            "addresses and ids do not match"
        );
        for (uint256 i = 0; i < _addresses.length; i++) {
            transferFrom(msg.sender, _addresses[i], ids[i]);
        }
    }

    function calculateTokenURIId(uint256 _heroId)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 domosOffset = mintIndexToDomosIndex[_heroId] *
            numberOfHeroesPerDomos;
        uint256 randomizedIndexOfHeroInDomos = (mintIndexToHeroInDomosIndex[
            _heroId
        ] + startingIndex) % numberOfHeroesPerDomos;

        return randomizedIndexOfHeroInDomos + domosOffset;
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function tokenURI(uint256 _heroId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(_heroId), "Nonexistent token");

        if (startingIndex == 0) {
            return
                string(
                    abi.encodePacked(
                        baseTokenURI,
                        "/",
                        mintIndexToDomosIndex[_heroId].toString()
                    )
                );
        }

        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    "/",
                    calculateTokenURIId(_heroId).toString()
                )
            );
    }

    function withdrawEthereum() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function setStartingIndexBlock() external onlyOwner {
        require(startingIndexBlock == 0, "Already set");
        startingIndexBlock = block.number;
    }

    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "Already set");
        require(startingIndexBlock != 0, "Call setStartingIndexBlock");

        startingIndex =
            (block.number - startingIndexBlock) %
            numberOfHeroesPerDomos;

        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = 1;
        }
    }

    function setSeason2ContractAddress(address _addr) public onlyOwner {
        season2ContractAddress = _addr;
    }

    modifier onlySeason2Contract() {
        require(season2ContractAddress != address(0), "Invalid addr");
        require(
            msg.sender == season2ContractAddress,
            "Only Season 2 Contract can call function"
        );
        _;
    }

    function burnHero(uint256 _heroId) external onlySeason2Contract {
        _burn(_heroId);
    }

    function burn(uint256 _heroId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), _heroId),
            "Caller is not owner/approved"
        );
        _burn(_heroId);
    }

    function _isApprovedOrOwner(address messageSender, uint256 _heroId)
        private
        view
        returns (bool)
    {
        TokenOwnership memory prevOwnership = ownershipOf(_heroId);

        return (messageSender == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, messageSender) ||
            getApproved(_heroId) == messageSender);
    }
}