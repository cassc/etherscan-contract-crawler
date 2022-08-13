// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract RareDoodPepes is ERC721AQueryable, Ownable, ReentrancyGuard {
  error NoContracts();

    string private _baseTokenURI =
        "https://ipfs.io/ipfs/QmW54gDDNaripvUUg7VGV2iSChq4zSAj4tExt1AMfQuqXi/";

    uint256 public maxSupply = 10000;
    uint256 public MAX_FREE_SUPPLY = 10000;
    uint256 public MAX_PER_TX = 10;
    uint256 public PRICE = 0.001 ether;
    uint256 public MAX_FREE_PER_WALLET = 1;

    bool private publicSale;
    
    mapping(address => uint256) public qtyFreeMinted;

    constructor() ERC721A("RareDoodPepes", "Dpepes") {
        _mint(msg.sender,10);
        _mint(0xdf0AC86561939D7f15C2a507a2C1d0F75a47b915, 50);
        }

    modifier callerIsUser() {
        if (msg.sender != tx.origin) revert NoContracts();
        _;
    }

    function viewPerWalletLimit() external pure returns (uint8) {
        return 1;
    }

    function mint(uint256 amount) external payable callerIsUser
    {
        require(publicSale, "Minting is not live yet.");
		require(amount <= MAX_PER_TX,"Exceeds NFT per transaction limit");
		require(_totalMinted() + amount <= maxSupply,"Exceeds max supply");

        uint payForCount = amount;
        uint mintedSoFar = qtyFreeMinted[msg.sender];
        if(mintedSoFar < MAX_FREE_PER_WALLET) {
            uint remainingFreeMints = MAX_FREE_PER_WALLET - mintedSoFar;
            if(amount > remainingFreeMints) {
                payForCount = amount - remainingFreeMints;
            }
            else {
                payForCount = 0;
            }
        }

		require(
			msg.value >= payForCount * PRICE,
			'Ether value sent is not sufficient'
		);
    	qtyFreeMinted[msg.sender] += amount;

        _safeMint(msg.sender, amount);
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function isPublicSaleActive() external view returns (bool) {
        return publicSale;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSale = !publicSale;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        PRICE = _newPrice;
    }

    function setMaxFreePerAddress(uint256 _MaxFreePerAddress) external onlyOwner {
        MAX_FREE_PER_WALLET = _MaxFreePerAddress;
    }

    function setMaxPerTX(uint256 _newMaxPerTX) external onlyOwner {
        MAX_PER_TX = _newMaxPerTX;
    }

    function lowerSupply(uint16 _newSupply) external onlyOwner {
        if (_newSupply > maxSupply) revert("You can't increase the supply");
        maxSupply = _newSupply;
    }

    function lowerFreeSupply(uint16 _newFreeSupply) external onlyOwner {
        if (_newFreeSupply > maxSupply) revert("You can't increase the supply");
        MAX_FREE_SUPPLY = _newFreeSupply;
    }

    function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }
 
  function withdraw() public onlyOwner nonReentrant {
    (bool hs, ) = payable(0x21974a0ce53eAe45FA7e4291B2CE448DaF51F74c).call{value: address(this).balance * 15 / 100}('');
    require(hs);
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}