//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TreatsNFT is ERC1155Burnable, Ownable {
    using Strings for uint256;

    string tokenUri = "https://awoo.finance/snctry/json/treats/";
    
    mapping(uint256 => uint256) public evoPoint;

    function setTokenURI(string calldata _uri) public onlyOwner {
        tokenUri = _uri;
    }

    function contractURI() public pure returns (string memory) {
        return "https://awoo.finance/snctry/json/contracttreats";
    }

    constructor() ERC1155("https://awoo.finance/snctry/json/treats/") {
        evoPoint[0] = 10;
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for all token types. It relies
     * on the token type ID substituion mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the \{id\} substring with the
     * actual token type ID.
     */
    function uri(uint256 _id) public view override returns (string memory) {
        return
            bytes(tokenUri).length > 0
                ? string(abi.encodePacked(tokenUri, _id.toString()))
                : "";
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        _mint(account, id, amount, data);
    }
}