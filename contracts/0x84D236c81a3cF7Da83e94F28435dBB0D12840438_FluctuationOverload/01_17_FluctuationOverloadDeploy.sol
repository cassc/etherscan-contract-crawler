// SPDX-License-Identifier: MIT

// ██████╗░██╗░░░██╗███╗░░██╗██╗░░██╗░██████╗
// ██╔══██╗██║░░░██║████╗░██║██║░██╔╝██╔════╝
// ██████╔╝╚██╗░██╔╝██╔██╗██║█████═╝░╚█████╗░
// ██╔═══╝░░╚████╔╝░██║╚████║██╔═██╗░░╚═══██╗
// ██║░░░░░░░╚██╔╝░░██║░╚███║██║░╚██╗██████╔╝
// ╚═╝░░░░░░░░╚═╝░░░╚═╝░░╚══╝╚═╝░░╚═╝╚═════╝░

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

pragma solidity 0.8.9;
pragma abicoder v2;

contract FluctuationOverload is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    
    string public name;
    string public symbol;
    
    bool public saleIsActive = false;
    bool public claimIsActive = false;
    bytes32 public claimRoot; // Merkle Root for Claim
    mapping(address => bool) public hasClaimed;

    // Reserve up to 100 comics for founders (marketing, giveaways, team holdings etc.)
    uint public foundersReserve = 100;

    uint256 public availableComics = 1000; // for public mint
    uint256 public availableClaims = 4000; // for holders claims
  
    bool public allowBurn = false;
    uint256 public burnedTokens = 0;

    uint256 public thePrice = 30000000000000000; // 0.03 ETH

    string public _baseURI = "";

    // Withdraw address
    address t1 = 0x8323cc95c6fc88C832086e38869cFe1d834A4980; // PVNKS-TEAM

    constructor() ERC1155(_baseURI) {
        name = "Fluctuation Overload";
        symbol = "FLUXCOMIC";
     }

    modifier notBotted() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    
   function reserveComics(address _to, uint256 _reserveAmount) public onlyOwner {        
        require(_reserveAmount > 0 && _reserveAmount <= foundersReserve, "unable to mint any further for founders");
        _mint(_to, 1, _reserveAmount, "0x0000");
        foundersReserve = foundersReserve - _reserveAmount;
    }
   
   function setBaseURI(string memory newuri) public onlyOwner {
		_baseURI = newuri;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

	function tokenURI(uint256 tokenId) public view returns (string memory) {
		return string(abi.encodePacked(_baseURI, uint2str(tokenId)));
	}

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() public onlyOwner {
        uint256 _total = address(this).balance;
        require(payable(t1).send(_total));
    }

    function setThePrice(uint256 newPrice) public onlyOwner {
        thePrice = newPrice;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipClaimState() public onlyOwner {
        claimIsActive = !claimIsActive;
    }

     function flipBurnState() public onlyOwner {
        allowBurn = !allowBurn;
    }

    function setClaimRoot(bytes32 root) external onlyOwner {
        claimRoot = root;
    }

    function tokenBalance1(address owner) public view returns (uint256) {
        return balanceOf(owner,1);
    }

    function tokenBalance2(address owner) public view returns (uint256) {
        return balanceOf(owner,2);
    }

    // Claiming

    function claimMint(bytes32[] calldata proof) external {
        require(claimIsActive, "Claim window is not active");
        require(!hasClaimed[msg.sender], "User has already claimed");
        require(totalSupply(1) + 2 <= availableClaims, "Supply would be exceeded");
        require(MerkleProof.verify(proof, claimRoot, keccak256(abi.encodePacked(_msgSender()))), "Not Eligible");

            _mint(msg.sender, 1, 2, "0x0000");
            hasClaimed[msg.sender] = true;
    } 

    // Minting

    function publicMint(uint COMICS) public payable notBotted {
        require(saleIsActive, "Public Sale is not active");
        require(totalSupply(2) + COMICS <= availableComics, "Supply would be exceeded");
        require(COMICS > 0 && COMICS <= 5, "Max 5 per transaction");
        require(msg.value >= thePrice * COMICS, "Ether value sent is incorrect");

            _mint(msg.sender, 2, COMICS, "0x0000");
    } 

    // Burning #1

    function burnYourComic1(uint256 howMany) public {
        require(allowBurn, "Burn mechanism not yet active");

        burn(msg.sender,1,howMany);
        burnedTokens += howMany;
    }

    // Burning #2

    function burnYourComic2(uint256 howMany) public {
        require(allowBurn, "Burn mechanism not yet active");

        burn(msg.sender,2,howMany);
        burnedTokens += howMany;
    }

}