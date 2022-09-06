//SPDX-License-Identifier: MIT

/*
 *
  /$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$  /$$   /$$  /$$$$$$ 
 /$$__  $$ /$$__  $$|__  $$__//$$__  $$| $$  | $$ /$$__  $$
| $$  \__/| $$  \ $$   | $$  | $$  \__/| $$  | $$| $$  \ $$
| $$ /$$$$| $$  | $$   | $$  | $$      | $$$$$$$$| $$$$$$$$
| $$|_  $$| $$  | $$   | $$  | $$      | $$__  $$| $$__  $$
| $$  \ $$| $$  | $$   | $$  | $$    $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/   | $$  |  $$$$$$/| $$  | $$| $$  | $$
 \______/  \______/    |__/   \______/ |__/  |__/|__/  |__/
                                                           
  /$$$$$$   /$$$$$$  /$$$$$$$$ /$$$$$$  /$$   /$$  /$$$$$$ 
 /$$__  $$ /$$__  $$|__  $$__//$$__  $$| $$  | $$ /$$__  $$
| $$  \__/| $$  \ $$   | $$  | $$  \__/| $$  | $$| $$  \ $$
| $$ /$$$$| $$$$$$$$   | $$  | $$      | $$$$$$$$| $$$$$$$$
| $$|_  $$| $$__  $$   | $$  | $$      | $$__  $$| $$__  $$
| $$  \ $$| $$  | $$   | $$  | $$    $$| $$  | $$| $$  | $$
|  $$$$$$/| $$  | $$   | $$  |  $$$$$$/| $$  | $$| $$  | $$
 \______/ |__/  |__/   |__/   \______/ |__/  |__/|__/  |__/                                                    
 *                             
*/

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error SaleInactive(string message);
error SoldOut(string message);
error Paused(string message);
error LimitMinted(string message);
error InvalidPrice(string message);
error InvalidQuantity(string message);
error InvalidProof(string message);
error WithdrawFailed(string message);

contract GotchaGatcha is Ownable, ERC721A("Gotcha Gatcha", "GG") {
    bytes32 public merkleRoot;
    
    uint256 public constant SUPPLY = 6868;
    uint256 public constant DEV_SUPPLY = 120;
    uint256 public WHITELIST_SUPPLY = 3120;
    uint256 public PUBLIC_SUPPLY = 3120;
    uint256 public price = 0.0468 ether;
    uint256 public maxMintedPerAddress = 1;
    
    string public BASE_URI;
    string public CONTRACT_URI;
    string private UNREVEALED_URI = "ipfs://QmQdVaSydf1DTM1ND3o7g7RpLrCzPAAnttYAUFDcKyeWRc/hidden.json";
    
    bool public REVEALED;
    bool public paused = true;
    bool public salePublicActive = false;
    bool public saleWLActive = false;
    
    function whitelistMint(uint256 quantity, bytes32[] memory proof) external payable mintCompliance(quantity) {
        if (!saleWLActive) revert SaleInactive("wl. sale inactive");
        if (totalSupply() + quantity > WHITELIST_SUPPLY) revert SoldOut("whitelist soldout");
        if (msg.value != price * quantity) revert InvalidPrice("wrong price");
        if (numberMinted(msg.sender) + quantity > maxMintedPerAddress) revert SoldOut("whitelist mint reached");
        if (!isProof(proof, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof("address not whitelisted");

        _safeMint(msg.sender, quantity);
    }

    function publicMint(uint256 quantity) external payable mintCompliance(quantity) {
        if (!salePublicActive) revert SaleInactive("public sale inactive");
        if (totalSupply() + quantity > PUBLIC_SUPPLY) revert SoldOut("public sale soldout");
        if (numberMinted(msg.sender) + quantity > maxMintedPerAddress) revert SoldOut("public mint reached");
        if (msg.value != price * quantity) revert InvalidPrice("Wrong price");

        _safeMint(msg.sender, quantity);
    }

    function devMint(uint256 quantity) external onlyOwner {
        if (numberMinted(msg.sender) + quantity > DEV_SUPPLY) revert SoldOut("dev mint reached");

        _safeMint(msg.sender, quantity);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        CONTRACT_URI = _contractURI;
    }
  
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function setWhitelistSupply(uint256 _newSupply) external onlyOwner {
        WHITELIST_SUPPLY = _newSupply;
    }

    function setPublicSupply(uint256 _newSupply) external onlyOwner {
        PUBLIC_SUPPLY = _newSupply;
    }
    
    function setMaxMinted(uint256 _quantity) external onlyOwner {
        maxMintedPerAddress = _quantity;
    }

    function setRevealed(bool _state) public onlyOwner {
        REVEALED = _state;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setWLSaleState(bool _active) external onlyOwner {
        saleWLActive = _active;
        salePublicActive = !_active;
    }

    function setPublicSaleState(bool _active) external onlyOwner {
        salePublicActive = _active;
        saleWLActive = !_active;
    }
    
    function contractURI() public view returns (string memory) {
        return CONTRACT_URI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        BASE_URI = baseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (REVEALED) {
            string memory baseURI = _baseURI();
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
        } else {
            return UNREVEALED_URI;
        }
    }

    function verifyPublicWL(address _address, bytes32[] memory _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, keccak256(abi.encodePacked(_address)), merkleRoot);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function tokensOf(address wallet) public view returns (uint256[] memory) {
        uint256 supply = totalSupply();
        uint256[] memory tokenIds = new uint256[](balanceOf(wallet));

        uint256 currIndex = 0;
        for (uint256 i = 1; i < supply; i++) {
            if (wallet == ownerOf(i)) tokenIds[currIndex++] = i;
        }

        return tokenIds;
    }

    function isProof(bytes32[] memory _proof, bytes32 leaf) internal view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, leaf);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    //MODIFIERS
    modifier mintCompliance(uint256 quantity) {
        if (paused) 
            revert Paused("contract paused");
        
        if(totalSupply() + quantity > SUPPLY)
            revert SoldOut("All Soldout");

        require(tx.origin == msg.sender, "No contract minting");
        _;
    }
}