// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721AQueryable.sol";

contract TKWolves is ERC721AQueryable, Ownable {
 
    string private _baseTokenURI;
    
    uint256 public constant maxPurchaseAmt = 10;
    uint256 public publicSupply = 5000;
		uint256 public reserveSupply = 353;
		uint256 public mintPrice = 0.01666 ether;

		address public claimContract;
		bool public active;

		mapping(uint256 => bool) public claims;

    constructor(address _claimContract
    ) ERC721A("TKWolves", "WOLVES") {
				claimContract = _claimContract;
    }

		function claim(address _recipient, uint256[] memory _claimIds) external {
				require(msg.sender == claimContract, "Not allowed");
				uint256 amount = _claimIds.length;
				uint i;
				for (i; i < amount; ){
					claims[_claimIds[i]] = true;
					unchecked { ++i; }
				}
				_safeMint(_recipient, amount);
		}
    
    function mint(uint256 _amount) external payable {
				require(active, "Not active yet");
				require(msg.value == mintPrice * _amount, "Wrong eth amount sent");
				require(_amount <= publicSupply, "Mint would exceed max supply");
        require(_amount <= maxPurchaseAmt, "Exceeds max per tx");
        
				unchecked { publicSupply -= _amount; }
        _safeMint(msg.sender, _amount);
    }

		function ownerMint(uint256 _amount, address receiver) external payable {
				require(reserveSupply >= _amount, "Mint would exceed max supply");
				unchecked { reserveSupply -= _amount; }
        _safeMint(receiver, _amount);
		}

		function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        
        uint pay1 = balance * 20 / 100;
        uint pay2 = balance * 25 / 100;
        uint pay3 = balance - pay1 - pay2;
        
        payable(address(0x6B2083a5C04bcbbC5DA2b57c9906657162F09fcC)).transfer(pay1);
        payable(address(0x624d44ddd2357FCffC2E461d9e690c37bF1baF60)).transfer(pay3);
        payable(address(0xAf1765c5Fa17CB6E4aedAFF3F8Df6c36874C65AF)).transfer(pay3);
    }
    
		function setActive() external onlyOwner {
				active = !active;
		}
    
		function setPrice(uint256 newPrice) external onlyOwner {
				mintPrice = newPrice;
		}
    
    function setBaseURI(string calldata newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

}