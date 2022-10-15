// SPDX-License-Identifier: UNLICENSED

/**
__      ___   _  __  __    ___     ___             _  __    ___   __   __ 
\ \    / / | | ||  \/  |  | _ )   / _ \     o O O | |/ /   | __|  \ \ / / 
 \ \/\/ /| |_| || |\/| |  | _ \  | (_) |   o      | ' <    | _|    \ V /  
  \_/\_/  \___/ |_|__|_|  |___/   \___/   TS__[O] |_|\_\   |___|   _|_|_  
_|"""""|_|"""""|_|"""""|_|"""""|_|"""""| {======|_|"""""|_|"""""|_| """ | 
"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'./o--000'"`-0-0-'"`-0-0-'"`-0-0-' 
by @wumbolabs
**/

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract WumboKey is ERC721, ERC721Enumerable, Pausable, Ownable {
    string public baseURI = "ipfs://bafkreicxzynqxhjtjq4j5uv6torabdyabl6ktywenkwlkbjxj4ecarymqa/";
    bool public saleIsActive = false;
    uint256 public MAX_SUPPLY = 277;
    uint256 public price = 1.2 ether;

    mapping(address => bool) public whitelist;

    constructor() ERC721("Wumbo Key", "WBKEY") {
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        require(!saleIsActive);
        MAX_SUPPLY = _supply;
    }

    function maxSupply() external view returns (uint256 _supply) {
        return MAX_SUPPLY;
    }

    /* -- ALLOWLIST THE PEOPLE -- */

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function resetAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }
    
    function addWhitelist(address _newEntry) external onlyOwner {
        require(!whitelist[_newEntry], "Already in whitelist");
        whitelist[_newEntry] = true;
    }
  
    function removeWhitelist(address _newEntry) external onlyOwner {
        require(whitelist[_newEntry], "Previous not in whitelist");
        whitelist[_newEntry] = false;
    }

    function isAllowlist(address _address) external view returns (bool _allowlisted) {
        return whitelist[_address];
    }

    /* ONLY OUR FAVORITE PEOPLE */

    function mint(uint256 nTokens) external payable {
        require(nTokens == 1, "Wumbo Key: Only one per mint");
        require(saleIsActive, "Wumbo Key: Sale not active");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Wumbo Key: Oversupplied");
        require(price == msg.value, "Wumbo Key: Need more monies");
        require(whitelist[msg.sender], "Wumbo Key: Not in whitelist");
        whitelist[msg.sender] = false;
        _safeMint(msg.sender, totalSupply() + 1);
    }

    function ownerMint(address _address) external onlyOwner {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Wumbo Key: Oversupplied");
        _safeMint(_address, totalSupply() + 1);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function toggleSale() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setCurrentPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /* NO TRANSFER FOR YOU */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /* OVERRIDE SOME FUNCTIONS PLZ */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI)) : "";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed.");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override(ERC721, IERC721) whenNotPaused {
        //revert("Token is non-transferable");
        super.safeTransferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) whenNotPaused {
        //revert("Token is non-transferable");
        super.safeTransferFrom(from, to, id, _data);
    }

    function approve(address to, uint256 id) public virtual override(ERC721, IERC721) whenNotPaused {
        // revert("Token is non-transferable");
        super.approve(to, id);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override(ERC721, IERC721) whenNotPaused {
        // revert("Token is non-transferable");
        super.transferFrom(from, to, id);
    }
}