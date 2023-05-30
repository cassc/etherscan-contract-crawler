// contracts/Buccaneers.sol
// SPDX-License-Identifier: MIT
// Inspired from Chubbies

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Buccaneers is ERC721, Ownable {
    using SafeMath for uint256;
    uint public constant MAX_BUCCANEERS = 10000;
    uint public constant MAX_SHIPS = 500;
    uint public constant MAX_GIVEAWAY = 30;
    address proxyRegistryAddress;

    mapping(uint256 => uint256) roles;
    mapping(uint256 => bool) crewsTokens;
    uint256 public TOTAL_BUCCANEERS = 0;
    uint256 public TOTAL_SHIPS = 0;
    uint256 public TOTAL_GIVEAWAY = 0;

    event Minted(address _from, uint256 _id, string _tokenUrl, uint256 _role);

    constructor(string memory baseURI, address _proxyRegistryAddress) ERC721("Buccaneers","BUCCANEERS") {
        setBaseURI(baseURI);
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function tokensOfOwner(address _owner) public view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function isUsedForShip(uint256 tokenId) public view returns (bool) {
         return crewsTokens[tokenId];
    }

    function tokenRole(uint256 tokenId) public view returns (uint256) {
        return roles[tokenId];
    }

    function calculatePrice() public view returns (uint256) {
        require(totalBuccaneers() < MAX_BUCCANEERS, "Sale has already ended");

        uint currentSupply = totalBuccaneers();
        if (currentSupply >= 9900) {
            return 1000000000000000000;        // 9900-10000: 1.00 ETH
        } else if (currentSupply >= 9500) {
            return 640000000000000000;         // 9500-9900:  0.64 ETH
        } else if (currentSupply >= 7500) {
            return 320000000000000000;         // 7500-9500:  0.32 ETH
        } else if (currentSupply >= 3500) {
            return 160000000000000000;         // 3500-7500:  0.16 ETH
        } else if (currentSupply >= 1500) {
            return 80000000000000000;          // 1500-3500:  0.08 ETH
        } else if (currentSupply >= 500) {
            return 40000000000000000;          // 500-1500:   0.04 ETH
        } else {
            return 20000000000000000;          // 0 - 500     0.02 ETH
        }
    }

    function rand(uint seed) internal pure returns (uint) {
        bytes32 data;
        data = keccak256(abi.encodePacked(bytes32(seed)));
        uint sum;
        for(uint i;i < 32;i++){
            sum += uint(uint8(data[i]));
        }
        return uint(uint8(data[sum % data.length]))*uint(uint8(data[(sum + 2) % data.length]));
    }

    function randint(uint256 id) internal view returns(uint) {
        return rand(block.timestamp + id);
    }

    function randrange(uint a, uint b, uint256 id) internal view returns(uint) {
        return a + (randint(id) % b);
    }

    function getRand(uint256 id) internal view returns (uint) {
        return randrange(0, 27, id);
    }

    function calculatePriceForToken(uint _id) public pure returns (uint256) {
        require(_id < MAX_BUCCANEERS, "Sale has already ended");

        if (_id >= 9900) {
            return 1000000000000000000;        // 9900-10000: 1.00 ETH
        } else if (_id >= 9500) {
            return 640000000000000000;         // 9500-9900:  0.64 ETH
        } else if (_id >= 7500) {
            return 320000000000000000;         // 7500-9500:  0.32 ETH
        } else if (_id >= 3500) {
            return 160000000000000000;         // 3500-7500:  0.16 ETH
        } else if (_id >= 1500) {
            return 80000000000000000;          // 1500-3500:  0.08 ETH
        } else if (_id >= 500) {
            return 40000000000000000;          // 500-1500:   0.04 ETH
        } else {
            return 20000000000000000;          // 0 - 500     0.02 ETH
        }
    }

    function mint(uint256 numBuccaneers) public payable {
        require(totalBuccaneers() < MAX_BUCCANEERS, "Sale has already ended");
        require(numBuccaneers > 0 && numBuccaneers <= 20, "You can mint minimum 1, maximum 20 Buccaneers");
        require(totalBuccaneers().add(numBuccaneers) <= MAX_BUCCANEERS, "Exceeds MAX_BUCCANEERS");
        require(msg.value >= calculatePrice().mul(numBuccaneers), "Ether value sent is below the price");

        for (uint i = 0; i < numBuccaneers; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            roles[mintIndex] = uint256(getRand(mintIndex) / 3);
            TOTAL_BUCCANEERS = TOTAL_BUCCANEERS + 1;
            crewsTokens[mintIndex] = false;
            emit Minted(msg.sender, mintIndex, tokenURI(mintIndex), roles[mintIndex]);
        }
    }

    function mintCrewShip() public {
        require(totalShips() < MAX_SHIPS, "Ships are over");

        uint256[] memory crew = hasFullCrew(msg.sender);

        require(crew.length == 9, "You haven't full crew");

        for (uint i = 0; i < crew.length; i++) {
            uint256 token = crew[i];
            crewsTokens[token] = true;
        }

        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
        roles[mintIndex] = 9;
        crewsTokens[mintIndex] = true;
        TOTAL_SHIPS = TOTAL_SHIPS + 1;
        emit Minted(msg.sender, mintIndex, tokenURI(mintIndex), roles[mintIndex]);
    }

    function hasFullCrew(address _owner) public view returns (uint256[] memory) {
        uint256[] memory resultTokens = new uint256[](9);
        uint256[] memory tokens = tokensOfOwner(_owner);

        bool has0 = false;
        bool has1 = false;
        bool has2 = false;
        bool has3 = false;
        bool has4 = false;
        bool has5 = false;
        bool has6 = false;
        bool has7 = false;
        bool has8 = false;

        uint256 j = 0;
        uint256 i;

        for (i = 0; i < tokens.length; i++) {
            uint256 token = tokens[i];

            if (roles[token] == 0 && !crewsTokens[token] && !has0) {
                has0 = true;
                resultTokens[j++] = token;
            }
            if (roles[token] == 1 && !crewsTokens[token] && !has1) {
                has1 = true;
                resultTokens[j++] = token;
            }
            if (roles[token] == 2 && !crewsTokens[token] && !has2) {
                has2 = true;
                resultTokens[j++] = token;
            }
            if (roles[token] == 3 && !crewsTokens[token] && !has3) {
                has3 = true;
                resultTokens[j++] = token;
            }
            if (roles[token] == 4 && !crewsTokens[token] && !has4) {
                has4 = true;
                resultTokens[j++] = token;
            }
            if (roles[token] == 5 && !crewsTokens[token] && !has5) {
                has5 = true;
                resultTokens[j++] = token;
            }
            if (roles[token] == 6 && !crewsTokens[token] && !has6) {
                has6 = true;
                resultTokens[j++] = token;
            }
            if (roles[token] == 7 && !crewsTokens[token] && !has7) {
                has7 = true;
                resultTokens[j++] = token;
            }
            if (roles[token] == 8 && !crewsTokens[token] && !has8) {
                has8 = true;
                resultTokens[j++] = token;
            }
        }

        if (has0 && has1 && has2 && has3 && has4 && has5 && has6 && has7 && has8) {
            return resultTokens;
        }

        return new uint[](0);
    }

    function role(uint256 tokenId) public view returns (uint256) {
        return roles[tokenId];
    }

    function totalBuccaneers() public view returns (uint256) {
        return TOTAL_BUCCANEERS;
    }

    function totalShips() public view returns (uint256) {
        return TOTAL_SHIPS;
    }

    function totalGiveaway() public view returns (uint256) {
        return TOTAL_GIVEAWAY;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
    override
    public
    view
    returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    // God Mode

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function reserveGiveaway(uint256 numBuccaneers) public onlyOwner {
        require(totalGiveaway().add(numBuccaneers) <= MAX_GIVEAWAY, "Exceeded giveaway supply");
        uint256 index;
        for (index = 0; index < numBuccaneers; index++) {
            TOTAL_BUCCANEERS = TOTAL_BUCCANEERS + 1;
            TOTAL_GIVEAWAY = TOTAL_GIVEAWAY + 1;
            uint mintIndex = totalSupply();
            _safeMint(owner(), mintIndex);
            roles[mintIndex] = uint256(getRand(mintIndex) / 3);
            crewsTokens[mintIndex] = false;
        }
    }
}