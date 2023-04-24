// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OBABabes is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 10000;
    uint256 public PUBLIC_SALE_PRICE = 0.25 ether;

    string private  baseTokenUri;
    string public   notRevealedUri;
    string public   uriMetadataSuffix = "";

    bool public isRevealed;
    bool public publicSale;

    constructor() ERC721A("OBA BABES", "OBABABES"){}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "OBABABES :: Cannot be called by a contract");
        _;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function mint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "OBABABES :: Sale Not Active Yet.");
        require(_quantity > 0, "OBABABES :: Mint at least 1 OBABABES NFT");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "OBABABES :: Beyond Max Supply");
        require(msg.value >= PUBLIC_SALE_PRICE * _quantity, "OBABABES :: Less Amount Sent for transaction");

        _safeMint(msg.sender, _quantity);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");

        if (isRevealed == false) {
            string memory baseURI = _baseURI();
            return string(abi.encodePacked(baseURI));
        } else {
            string memory baseURI_revealed = _baseURI();
            // "ipfs://__CID__/"
            return string(abi.encodePacked(baseURI_revealed, toString(tokenId),uriMetadataSuffix));
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        if (isRevealed == false) {
            return notRevealedUri;
        } else {
            return baseTokenUri;
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory){
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);

        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                tokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return tokenIds;
    }

    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        notRevealedUri = _placeholderTokenUri;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        PUBLIC_SALE_PRICE = _price; 
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function get_balance() public onlyOwner view returns (uint balance) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner{
        uint total_balance = get_balance();
        require(total_balance>0, "Balance is 0");

        (bool owv, ) = payable(msg.sender).call{value: total_balance}("");
        require(owv);
    }

    function changeUriMetadataSuffix(string memory _suffix) external onlyOwner {
        uriMetadataSuffix = _suffix;
    }

    function getUriMetadataSuffix() internal view virtual returns (string memory) {
        return uriMetadataSuffix;
    }

    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    function airdropTokens(address[] memory recipients, uint256[] memory _quantities) public onlyOwner {
        
        require(recipients.length > 0, "Recipients array must not be empty");
        require(recipients.length == _quantities.length, "Data length mismatch");

        uint256 total = 0;
        for (uint256 i = 0; i < _quantities.length; i++) {
            total+=_quantities[i];
        }
        require((totalSupply() + total) <= MAX_SUPPLY, "OBABABES :: Beyond Max Supply");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(_quantities[i] > 0, "Quantity must be greater than zero");

            // Mint NFTs to the specified recipient
            _safeMint(recipients[i], _quantities[i]);
        }
    }

}