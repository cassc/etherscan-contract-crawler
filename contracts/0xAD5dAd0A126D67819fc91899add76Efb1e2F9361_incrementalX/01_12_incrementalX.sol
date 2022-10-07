pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract incrementalX is ERC721, Ownable {
    using Strings for uint256;
    uint256 public totalSupply;

    constructor() ERC721("incrementalX", "++") {
    }

    function imageData(uint256 tokenId) 
        internal
        pure
        returns (string memory)
    {

        bytes memory data = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg"><text x="50%" y="50%" text-anchor="middle" dominant-baseline="central">',
            tokenId.toString(),
            '</text></svg>'
        );

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(data)
            )
        );
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId));
        bytes memory data = abi.encodePacked(
            '{',
                '"name": "#', tokenId.toString(), '",',
                '"image": "', imageData(tokenId), '"',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(data)
            )
        );
    }

    function mint()
        public
    {
        _mint(msg.sender, totalSupply);
        totalSupply++;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}