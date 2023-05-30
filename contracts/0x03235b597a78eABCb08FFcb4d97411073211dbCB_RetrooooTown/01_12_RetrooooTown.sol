// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721AQueryable.sol";

/*

     RETROOOOTOWN                                                               
   RETROOOOOOOOTOWN                         OOO                                 
    OOOOOO     OOOOO                       OOOO                                 
    OOOOOO     OOOOO     OOOTWONOOO    ORETROOOTOWNO  OOO    OOO      ORETRO    
   OOOOOOO   OOOOOO    RETROOOOOOTOWN OOOOOBEARDOOOO  OOOO  OOOOO  RETROOOOTOWN 
   OBUZZKILLEROO      OOOOOO   OOOOOO    OOOO        OOFREAKOO   ORETROO  OCARO 
  OOOOO  OOOOO        OOTOTHEMOONOO     OOOO         OOOOOOO    OOOOOO    OOOOO 
  OOOO   OOOOOOO     OOOOO              OOOO        OOOOO       OOOOO    OOOOO  
 OOOOO    OOOLANDOO   OOOO    OOOO      OOOO   OO   OOOOO       OOOOO  OOOOO    
 OOOOO      OOOEVILOO  OOOCHICKOO         OOOOOO    OOOOO        OOZOMBIEOOO     
 OOOOO         OOOOOOO  OOOOO                      OOO            OOOOOO         

*/
contract RetrooooTown is ERC721AQueryable, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 7777;
    uint256 public constant MAX_FREE_MINT_NUM = 1500;
    uint256 public constant MAX_PUBLIC_MINT_PER_WALLET = 5;
    uint256 public constant TEAM_RESERVE_NUM = 500;
    uint256 public constant PRICE = 0.005 ether;

    bool public publicMintActive;
    bool public freeMintActive;
    uint256 public freeMintNum;
    uint256 public teamMintNum;

    mapping(address => uint256) public freeMinted;

    string private _matadataURI;
    
    constructor() ERC721A("RetrooooTown", "RT") {
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier maxSupplyCompliance(uint256 num) {
        require(
            _totalMinted() + num <= MAX_SUPPLY,
            "Mint would exceed max supply"
        );
        _;
    }

    modifier publicMintCompliance(uint256 num) {
        require(publicMintActive, "Public mint is not active");
        require(msg.value >= PRICE * num, "Insufficient ethers");
        require(
            _numberMinted(msg.sender) + num - freeMinted[msg.sender] <=
                MAX_PUBLIC_MINT_PER_WALLET,
            "Mint would exceed max public mint for this wallet"
        );
        _;
    }

    modifier freeMintCompliance() {
        require(freeMintActive, "Free mint is not active");
        require(
            freeMintNum < MAX_FREE_MINT_NUM,
            "Mint would exceed max supply of free mints"
        );
        require(freeMinted[msg.sender] == 0, "Only 1 free per wallet");
        _;
    }

    modifier teamMintCompliance(uint256 num) {
        require(
            teamMintNum + num <= TEAM_RESERVE_NUM,
            "Mint would exceed team reserve"
        );
        _;
    }

    function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _matadataURI;
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function contractURI() public pure returns (string memory) {
		return "ipfs://QmdZ5N6ESvVo1cxSfEmnB722TZgWinAA9SAjGpkw5U1LzA";
	}

    function mint(uint256 num)
        external
        payable
        maxSupplyCompliance(num)
        publicMintCompliance(num)
        callerIsUser
    {
        // Caller is not a contract, skip safe check, save gas
        _mint(msg.sender, num, "", false);
    }

    function freeMint()
        external
        maxSupplyCompliance(1)
        freeMintCompliance
        callerIsUser
    {
        freeMinted[msg.sender] = 1;
        freeMintNum++;

        _mint(msg.sender, 1, "", false);
    }

    function teamMint(uint256 num, address to)
        external
        maxSupplyCompliance(num)
        teamMintCompliance(num)
        onlyOwner
    {
        teamMintNum += num;

        _mint(to, num, "", false);
    }

    function flipPublicMintActive() external onlyOwner {
        publicMintActive = !publicMintActive;
    }

    function flipFreeMintActive() external onlyOwner {
        freeMintActive = !freeMintActive;
    }

    function setMetadataURI(string calldata metadataURI) external onlyOwner {
        _matadataURI = metadataURI;
    }

    function withdraw(address to) external onlyOwner {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
}