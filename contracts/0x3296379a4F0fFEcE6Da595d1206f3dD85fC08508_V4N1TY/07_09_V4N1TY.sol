// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract V4N1TY is ERC721A, ERC2981, Ownable {

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    constructor() ERC721A("V4N1TY", "V4N1TY") {}

    // ------------------------------------------------------------------------------------------\\
    // Constants
    // ------------------------------------------------------------------------------------------\\

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_MINT = 10;
    uint256 public constant DEV_MAX = 20;

    // ------------------------------------------------------------------------------------------\\
    // Variables
    // ------------------------------------------------------------------------------------------\\

    address public adminWallet = 0x691C04861F0156C0E3fE00a9ED3F117FFaE43ba6;
    uint256 public mintPrice = 0.005 ether;
    string public baseURI;
    bool public mintLive;
    bool public devMinted;

    // ------------------------------------------------------------------------------------------\\
    // Public Functions
    // ------------------------------------------------------------------------------------------\\
    
    function mint(uint256 quantity) external payable {
        require(quantity <= MAX_MINT, "T00 GR33DY");
        require(mintLive, "P4T13NC3");
        require(msg.value == mintPrice * quantity, "N33D M0R3 ETH");
        require(totalSupply() + quantity <= MAX_SUPPLY, "50LD 0UT");
        _mint(msg.sender, quantity);
    }
    

    // ------------------------------------------------------------------------------------------\\
    // Admin Functions
    // ------------------------------------------------------------------------------------------\\

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

        function toggleMintLive() external onlyOwner {
        mintLive = !mintLive;
    }

    function devMint() external onlyOwner  {
        require(!devMinted);
        devMinted = true;
        _mint(msg.sender, DEV_MAX);
    }

    function updatePrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setDefaultRoyalty(address receiver, uint96 fee) external onlyOwner {
        require(fee <= 1000);
        _setDefaultRoyalty(receiver, fee);
    }

    function setAdminWallet(address _adminWallet) external onlyOwner {
        adminWallet = _adminWallet;
    }

    function withdrawFunds() external onlyOwner {
        require(adminWallet != address(0));
        (bool teamSuccess,) = adminWallet.call{ value: address(this).balance }("");
        require(teamSuccess);
    }


    // ------------------------------------------------------------------------------------------\\
    // Function Overrides
    // ------------------------------------------------------------------------------------------\\

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}