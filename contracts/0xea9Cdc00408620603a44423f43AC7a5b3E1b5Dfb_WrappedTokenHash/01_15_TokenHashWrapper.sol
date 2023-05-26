//Wrapped Token Hash contract, Jonathan Chomko, 2023
//Project initated by one of the many matts and Matt Stephenson
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */

contract WrappedTokenHash is ERC721, ERC721Enumerable, Ownable {
    
    address payable public withdrawalAddress;
    address tokenHashAddress;
    IERC721 public tokenHash;

    bool public mintingActive;
    string public baseAnimationURL;
    string public baseImageURL;
    
    mapping (uint256 => uint256) public renderStyleMap;
    mapping (uint256 => string) public renderStyleNameMap;
    
    event Wrap(address sender, uint256 tokenId, uint256 styleId);
    event Unwrap(address sender, uint256 tokenId);

    constructor(
        address givenTokenHashAddress,
        string memory givenBaseAnimationURL,
        string memory givenBaseImageURL
    ) ERC721("Wrapped Token Hash", "WTH") {
        tokenHashAddress = givenTokenHashAddress;
        tokenHash = IERC721(givenTokenHashAddress);  
        baseAnimationURL = givenBaseAnimationURL;
        baseImageURL = givenBaseImageURL; 
    }

    function generateRawHash(uint256 tokenId) public pure returns (bytes32){
        return keccak256(abi.encodePacked("RANDOM", toString(tokenId)));    
    }

    function generateHashMod(uint256 tokenId) public pure returns (uint256){
        return uint256(keccak256(abi.encodePacked("RANDOM", toString(tokenId)))) % 999;
    }

    function setRenderStyleStringMap(string [] memory givenRenderNames) public onlyOwner{
        for(uint256 i = 0; i < givenRenderNames.length; i ++){
            renderStyleNameMap[i] = givenRenderNames[i];
        }
    }
    
    function tokenURI(uint256 tokenId) override public view returns (string memory){
            require(_exists(tokenId) || msg.sender == owner(), "token does not exist");
            string[6] memory parts;
            
            uint256 hashMod = generateHashMod(tokenId);
            bytes32 rawHash = generateRawHash(tokenId);
            string memory rawHashString = bytes32ToString(rawHash);
            
            parts[0] = baseAnimationURL;
            parts[1] = toString(renderStyleMap[tokenId]);
            parts[2] = ".html?tokenId=";
            parts[3] = toString(tokenId); 
            parts[4] = "&hash=";
            parts[5] = rawHashString;

            string memory anim_url = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5] ));
            string memory image_url = string(abi.encodePacked( baseImageURL, toString(tokenId), '-', toString(renderStyleMap[tokenId]) , '.png'));
            string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "WTH ', renderStyleNameMap[renderStyleMap[tokenId]], ' ', toString(tokenId), ', ' , toString(hashMod), '", "description": "Token Hash, Art Blocks", "image": "',image_url,'", "animation_url": "',anim_url,'" }' ))));
            json = string(abi.encodePacked('data:application/json;base64,', json));
            return json;
    }

    function setMintActive(bool isActive) external onlyOwner {
        mintingActive = isActive;
    }

    function setBaseAnimationURL(string memory givenData )external onlyOwner {
        baseAnimationURL = givenData;
    }

    function setBaseImageURL(string memory givenData )external onlyOwner {
        baseImageURL = givenData;
    }

    //Withdrawal
    function setWithdrawalAddress(address payable givenWithdrawalAddress) external onlyOwner {
        withdrawalAddress = givenWithdrawalAddress;
    }

    function withdrawEth() external onlyOwner {
        Address.sendValue(withdrawalAddress, address(this).balance);
    }
    
    function mintWrapper(uint256 tokenId, uint256 givenRenderStyle) public {
       require(mintingActive, "minting must be active");
       require(tokenHash.isApprovedForAll(msg.sender, address(this)), "sender has not approved contract to transfer tokens");
       tokenHash.transferFrom(msg.sender,address(this), tokenId);
       renderStyleMap[tokenId] = givenRenderStyle;
        _safeMint(msg.sender, tokenId);
        emit Wrap(msg.sender, tokenId, givenRenderStyle);
    }
    
    function unWrap(uint256 tokenId) public {
        require(_exists(tokenId), "token does not exist");
        require(ownerOf(tokenId) == msg.sender, "token not owned by sender");
        tokenHash.transferFrom(address(this), msg.sender, tokenId);
        _burn(tokenId);
        emit Unwrap(msg.sender, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    //Helpers
    function bytes32ToString(bytes32 x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(64);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            uint8 byteValue = uint8(bytes1(x << (j * 8)));
            uint8 hi = byteValue / 16;
            uint8 lo = byteValue % 16;
            bytesString[charCount++] = bytes1(hi + (hi < 10 ? 48 : 87));
            bytesString[charCount++] = bytes1(lo + (lo < 10 ? 48 : 87));
        }
        return string(bytesString);
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}