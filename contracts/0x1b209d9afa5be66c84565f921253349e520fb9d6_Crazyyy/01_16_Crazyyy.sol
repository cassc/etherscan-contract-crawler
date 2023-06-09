// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Crazyyy is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private tokenCounter;

    uint256 public startTime = 0;
    uint256 public closeTime = 0;
    uint256 public finishTime = 0;

    address public sys1 = 0x3bfd433DCf093D921EA3C24660e37D6989253254;
    address public sys2 = 0x3B1292F3E6CEb5B1B841a709CF1dCd4b7C3E7027;

    address public vat = 0x1a26CF8720458c128af2a3EE316C047e2D738795;
    address public organizer = 0x9ff20cAA55F0d94E40b2Ff2f8cE62cd52933aBD1;

	uint256 public vatBalance = 0;
    uint256 public organizerBalance = 0;
    uint256 public prizeBalance = 0;

	uint256[] public prize;
    uint256 public prizeUpdated = 0;
    bool public prizeLock = false;

    uint256[] public ranking;
    uint256 public rankingUpdated = 0;

    bytes32 public root;

    mapping(address => bool) public discounts;
    mapping(uint256 => bool) public claims;

    constructor() ERC721("Crazyyy", "CZY") { }

    modifier onlySys1() {
      require(msg.sender == sys1, "Address not allowed");
      _;
    }

    modifier onlySys2() {
      require(msg.sender == sys2, "Address not allowed");
      _;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nft.crazyyy.app/";
    }

    function getPrice() public view returns (uint256) {
    	uint256 mints = tokenCounter.current();

    	if(mints < 3072) {
    		return 0.0128 ether;
    	} else if(mints < 5120) {
    		return 0.0256 ether;
    	} else if(mints < 10240) {
    		return 0.0512 ether;
    	} else if(mints < 15360) {
    		return 0.1024 ether;
    	} else if(mints < 32768) {
    		return 0.2048 ether;
    	}

    	return 0.4096 ether;
    }

    function getMints() public view returns(uint256) {
    	return tokenCounter.current();
    }

    function checkout(bytes32[] calldata proof, uint256 tokens) public view returns (uint256 amount, bool discount) {
    	require(tokens > 0 && tokens <= 20, "Purchase min 1, max 20");
    	require((tokenCounter.current() + tokens) <= 65536, "Token limit exceeded");
    	require(closeTime == 0 || block.timestamp < closeTime, "Sales closed");

    	uint256 price = getPrice();

    	if(proof.length > 0) {
	    	require(!discounts[msg.sender], "Only one discount per wallet");
	    	require(MerkleProof.verify(proof, root, keccak256(bytes.concat(keccak256(abi.encode(msg.sender))))), "Invalid proof");

	    	tokens--;

	    	discount = true;

    		if(tokenCounter.current() >= 3072) {
    			amount += price / 2;
    		}
    	}

    	if(tokens > 0) {
    		amount += price * tokens;
    	}
    }

    function mint(bytes32[] calldata proof, uint256 tokens) public payable {
    	(uint256 amount, bool discount) = checkout(proof, tokens);

    	require(amount <= msg.value, "Invalid ETH amount");

    	if(discount) {
    		discounts[msg.sender] = true;
    	}

    	if(msg.value > 0.0001 ether) {
	    	uint256 amountVatFree = (msg.value * 100) / 121;

	    	prizeBalance += amountVatFree / 2;
	    	organizerBalance += amountVatFree / 2;
	    	vatBalance += msg.value - amountVatFree;
		}

    	while (tokens > 0) {
    		tokens--;

    		tokenCounter.increment();

			_safeMint(msg.sender, tokenCounter.current());
	    }

	    if((tokenCounter.current() - prizeUpdated) >= 1024 || tokenCounter.current() == 65536) {
			prizeUpdated = tokenCounter.current();
			prizeUpdate();
		}

	    if(startTime == 0 && tokenCounter.current() >= 32768) {
			startTime = block.timestamp + 14 days;
			closeTime = block.timestamp + 43 days;
    		finishTime = block.timestamp + 44 days;
		}
	}

	function setRoot(bytes32 value) public onlySys2 {
        root = value;
	}
	
	function token2team(uint256 tokenId) public pure returns (uint256) {
		require(tokenId > 0, "Out of bounds");
		require(tokenId < 65537, "Out of bounds");

		uint256 team = 0;

		uint256 start = 0;
		uint256 end = 0;

		for (uint256 i = 0; i < 64; i++) {
			if(tokenId > i * 1024 && tokenId <= (i + 1) * 1024) {
				start = (i * 1024) + 1;
				end = start + 1024;

				break;
			}
		}

		for (uint256 i = start; i < end; i++) {
			team++;

			if (i == tokenId) {
				break;
			}

			if (team == 1024) {
				team = 0;
			}
		}
		
		return team;
	}

	function players(uint256 team) public view returns (uint256) {
		require(team > 0, "Out of bounds");
		require(team < 1025, "Out of bounds");

		uint256 current = tokenCounter.current();
		uint256 count = 0;

		for (uint256 i = 0; i < 64; i++) {
			if (current >= (team + (i * 1024))) {
				count++;
			} else {
				break;
			}
		}

		return count;
	}
	
	function rankingSet(uint256[] calldata value) public onlySys1 {
		require(block.timestamp < finishTime, "Ranking updates only allowed in competition");

		ranking = value;
		rankingUpdated = block.timestamp;
	}

	function rankingToken(uint256 tokenId) public view returns(uint256) {
		uint256 team = token2team(tokenId);
		uint256 position = 1024;

		for (uint256 i = 0; i < ranking.length; i++) {
			if(ranking[i] == team) {
				position = i;
				break;
			}
		}

		return position;
	}

    function prizeUpdate() private {
		delete prize;

		uint256 amount = prizeBalance;

		for(uint256 i = 0; i < 1024; i++) {
			amount /= 2;

			if(amount < 100000000000000) {
				break;
			}

			prize.push(amount);
		}
    }

	function tokenPrize(uint256 tokenId) public view returns (uint256) {
		uint256 team = token2team(tokenId);
		uint256 position = rankingToken(tokenId);

		if(position < prize.length) {
			return prize[position] / players(team);
		}

		return 0;
	}
	
	function claim(uint256 tokenId) external nonReentrant {
		require(msg.sender == ownerOf(tokenId), "Only owner of token");
		require(!claims[tokenId], "Already claimed");
		require(finishTime > 0 && block.timestamp > finishTime, "Not finished");

		if (!prizeLock) {
			prizeLock = true;
			prizeUpdate();
        }

		uint256 amount = tokenPrize(tokenId);

		require(amount > 0, "No prize");

		claims[tokenId] = true;

		payable(ownerOf(tokenId)).transfer(amount);
	}

	function withdrawVat() public onlySys2 {
		if(vatBalance > 0) {
			payable(vat).transfer(vatBalance);
			vatBalance = 0;
		}
	}

	function withdrawOrganizer() public onlySys2 {
		if(organizerBalance > 0) {
			payable(organizer).transfer(organizerBalance);
			organizerBalance = 0;
		}
	}

	receive() external payable {
		if(msg.value > 0 ether) {
	    	prizeBalance += msg.value;
		}
	}
}