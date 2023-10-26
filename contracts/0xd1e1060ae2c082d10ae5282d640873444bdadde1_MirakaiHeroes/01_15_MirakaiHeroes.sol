// ███╗░░░███╗██╗██████╗░░█████╗░██╗░░██╗░█████╗░██╗
// ████╗░████║██║██╔══██╗██╔══██╗██║░██╔╝██╔══██╗██║
// ██╔████╔██║██║██████╔╝███████║█████═╝░███████║██║
// ██║╚██╔╝██║██║██╔══██╗██╔══██║██╔═██╗░██╔══██║██║
// ██║░╚═╝░██║██║██║░░██║██║░░██║██║░╚██╗██║░░██║██║
// ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚═╝

///@author 0xBeans
///@dev This contract burns scrolls and $ORBs to summon a hero
/// with the same tokenID and traits as the scroll burned.

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IOrbsToken.sol";
import "./interfaces/IMirakaiScrolls.sol";
import "./interfaces/IMirakaiHeroesRenderer.sol";

// import {console} from "forge-std/console.sol";

contract MirakaiHeroes is Ownable, ERC721 {
    error SummonNotActive();
    error ERC721Metadata_URIQueryForNonExistentToken();
    error ERC721Burnable_CallerIsNotOwnerNorApproved();

    uint256 public constant MAX_SUPPLY = 10000;

    // cost to summon
    uint256 public summonCost;
    uint256 public totalSupply;

    // upgradeable renderer
    address public heroesRenderer;
    address public orbsToken;
    address public mirakaiScrolls;

    // safety switch
    bool public summonActive;

    // tokenId to dna
    mapping(uint256 => uint256) public dna;

    constructor() ERC721("Mirakai Heroes", "MIRAKAI_HEROES") {
        summonActive = true;
    }

    /*==============================================================
    ==                      Summoning Logic                       ==
    ==============================================================*/

    /**
     * @dev summon a single hero from scroll
     * @param scrollId self-explanatory
     */
    function summon(uint256 scrollId) external {
        if (!summonActive) revert SummonNotActive();

        // set dna on this contract, it will get deleted on the scrolls contracts
        dna[scrollId] = IMirakaiScrolls(mirakaiScrolls).dna(scrollId);

        //burn scroll
        IMirakaiScrolls(mirakaiScrolls).burn(scrollId);
        //burn orbs
        IOrbsToken(orbsToken).burn(msg.sender, summonCost);

        unchecked {
            ++totalSupply;
        }
        _mint(msg.sender, scrollId);
    }

    /**
     * @notice batch summon heroes
     * @param scrollIds array of scrollIds
     */
    function batchSummon(uint256[] calldata scrollIds) external {
        uint256 currSupply = totalSupply;

        if (!summonActive) revert SummonNotActive();

        uint256 scrollIdsLength = scrollIds.length;

        uint256 i;
        for (; i < scrollIdsLength; ) {
            uint256 scrollId = scrollIds[i];

            // set dna on this contract, it will get deleted on the scrolls contracts
            dna[scrollId] = IMirakaiScrolls(mirakaiScrolls).dna(scrollId);

            //burn scroll
            IMirakaiScrolls(mirakaiScrolls).burn(scrollId);
            //burn orbs
            IOrbsToken(orbsToken).burn(msg.sender, summonCost);

            unchecked {
                ++currSupply;
            }
            _mint(msg.sender, scrollId);

            ++i;
        }

        totalSupply = currSupply;
    }

    /**
     * @dev returns empty string if no renderer is set
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert ERC721Metadata_URIQueryForNonExistentToken();
        }

        if (heroesRenderer == address(0)) {
            return "";
        }

        return
            IMirakaiHeroesRenderer(heroesRenderer).tokenURI(
                tokenId,
                dna[tokenId]
            );
    }

    /**
     * @dev should ONLY be called off-chain. Used for displaying wallet's scrolls
     */
    function walletOfOwner(address addr)
        external
        view
        returns (uint256[] memory)
    {
        uint256 count;
        uint256 walletBalance = balanceOf(addr);
        uint256[] memory tokens = new uint256[](walletBalance);

        uint256 i;
        for (; i < MAX_SUPPLY; ) {
            // early break if all tokens found
            if (count == walletBalance) {
                return tokens;
            }

            // exists will prevent throw if burned token
            if (_exists(i) && ownerOf(i) == addr) {
                tokens[count] = i;
                count++;
            }

            unchecked {
                ++i;
            }
        }
        return tokens;
    }

    /**
     * @dev should ONLY be called off-chain. Used for displaying heroes.
     */
    function allSummonedHeroes() external view returns (uint256[] memory) {
        uint256 count;
        uint256[] memory tokens = new uint256[](totalSupply);

        uint256 i;
        for (; i < MAX_SUPPLY; ) {
            // early break if all tokens found
            if (count == totalSupply) {
                return tokens;
            }

            if (_exists(i)) {
                tokens[count] = i;
                count++;
            }

            unchecked {
                ++i;
            }
        }
        return tokens;
    }

    function burn(uint256 tokenId) external {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert ERC721Burnable_CallerIsNotOwnerNorApproved();
        }

        _burn(tokenId);
        delete dna[tokenId];

        unchecked {
            totalSupply--;
        }
    }

    /*==============================================================
    ==                    Only Owner Functions                    ==
    ==============================================================*/

    function initialize(
        address _heroesRenderer,
        address _orbsToken,
        address _scrolls,
        uint256 _summonCost
    ) external onlyOwner {
        heroesRenderer = _heroesRenderer;
        orbsToken = _orbsToken;
        mirakaiScrolls = _scrolls;
        summonCost = _summonCost;
    }

    function setHeroesRenderer(address _heroesRenderer) external onlyOwner {
        heroesRenderer = _heroesRenderer;
    }

    function setOrbsTokenAddress(address _orbsToken) external onlyOwner {
        orbsToken = _orbsToken;
    }

    function setScrollsAddress(address _mirakaiScrolls) external onlyOwner {
        mirakaiScrolls = _mirakaiScrolls;
    }

    function setSummonCost(uint256 _summonCost) external onlyOwner {
        summonCost = _summonCost;
    }

    function flipSummon() external onlyOwner {
        summonActive = !summonActive;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}