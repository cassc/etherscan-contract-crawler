// SPDX-License-Identifier: MIT
//  _______                __  __            __                       __
// |     __|.-----..--.--.|  |/  |.--.--..--|  |.---.-..-----..---.-.|__|
// |    |  ||  _  ||  |  ||     < |  |  ||  _  ||  _  ||__ --||  _  ||  |
// |_______||_____| \___/ |__|\__||_____||_____||___._||_____||___._||__|
pragma solidity ^0.8.17;

import "./IERC5192.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract GovKudasai is Ownable, ERC721Enumerable, IERC5192 {
    uint256 public immutable mintCost = 0.005 ether;
    string private _imageUri = "QmSP2sYM4zHJLJcheDAQxZtejp8KrYBkCfrZpEKK15zw2w";
    mapping(address => bool) public recipientAddress;
    constructor() ERC721("GovKudasai", "GK") {
        recipientAddress[address(0)] = true;
        recipientAddress[address(0x000000000000000000000000000000000000dEaD)] = true;
    }
    
    receive() external payable {
        require(balanceOf(msg.sender) == 0, "You already have");
        require(msg.value == mintCost, "Mint cost is insufficient");
        uint256 tokenId = totalSupply();
        _safeMint(msg.sender, tokenId);
        emit Locked(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    modifier checkSBTTransfer(address from_, address to_, uint256 tokenId_) {
        require(recipientAddress[to_] || from_ == address(0), "Soul Bound Token");
        _;
    }

    function locked(uint256 tokenId) external override(IERC5192) view returns (bool) {
        return true; // All tokens are locked.
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 /** batch **/) internal virtual override checkSBTTransfer(from, to, tokenId) {   
        super._beforeTokenTransfer(from, to, tokenId, 1);  
    }

    function mint() public payable {
        require(balanceOf(msg.sender) == 0, "You already have");
        require(msg.value == mintCost, "Mint cost is insufficient");
        uint256 tokenId = totalSupply();
        _safeMint(msg.sender, tokenId);
        emit Locked(tokenId);
    }
    
    function setRecipientAddress(address recipientAddress_, bool state_) external onlyOwner {
        recipientAddress[recipientAddress_] = state_;
    }

    function setImageUri(string memory newImage) external onlyOwner {
        _imageUri = newImage;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(
            abi.encodePacked(
                '{',
                    '"name":"GovKudasai #', Strings.toString(tokenId), '",',
                    '"description":"Just for discussion.",',
                    '"image":"', _imageUri, '",',
                    '"attributes":[{"trait_type":"id","display_type":"number","value":', Strings.toString(tokenId), '},'
                    '{"display_type": "date","trait_type": "birthday","value":', Strings.toString(block.timestamp), '},',
                    '{"trait_type":"owner","value":"', Strings.toHexString(ownerOf(tokenId)), '"}]',
                '}'
            )
        ) ) );
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}