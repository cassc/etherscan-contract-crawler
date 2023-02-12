// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721A} from "@erc721a/ERC721A.sol";
import {Ownable} from "@openzeppelin-contracts/access/Ownable.sol";
import {IERC721A} from "@erc721a/IERC721A.sol";
import {Strings} from "@openzeppelin-contracts/utils/Strings.sol";

contract OrdinalDuckMintToken is ERC721A, Ownable {
    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    uint256 public mintableSupply;
    string public baseUri;
    IERC721A public immutable ordinalsContract;

    constructor(
        string memory baseUri_,
        uint256 mintableSupply_,
        address ordinalsContract_
    ) ERC721A("Ordinal Duck Mint Token", "ODMT") {
        mintableSupply = mintableSupply_;
        baseUri = baseUri_;
        ordinalsContract = IERC721A(ordinalsContract_);
    }

    function ordinalsOf(address address_)
        public
        view
        returns (uint256[] memory)
    {
        return _ordinalsOf(address_, 0);
    }

    function _ordinalsOf(address address_, uint256 max)
        private
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 idx;
            uint256 numTokens = ordinalsContract.balanceOf(address_);
            uint256 maxTokens = max != 0 && max > numTokens ? max : numTokens;
            uint256[] memory tokens = new uint256[](maxTokens);
            for (uint256 i; idx != maxTokens; ++i) {
                try ordinalsContract.ownerOf(i) returns (
                    address originalOwner
                ) {
                    if (originalOwner == address_) {
                        tokens[idx++] = i;
                    }
                } catch (bytes memory) {}
            }
            return tokens;
        }
    }

    function burnForMe() public {
        uint256[] memory tokenIds = _ordinalsOf(msg.sender, 10);
        burn(tokenIds);
    }

    function burn(uint256[] memory tokenIds) public {
        require(_totalMinted() + 1 <= mintableSupply, "Sold Out");
        require(_getAux(msg.sender) == 0, "Max 1 Per Wallet");
        require(tokenIds.length == 10, "Minimum 10 Ordinals");
        for (uint256 i; i < tokenIds.length; ++i) {
            ordinalsContract.safeTransferFrom(
                msg.sender,
                DEAD_ADDRESS,
                tokenIds[i]
            );
        }
        _setAux(msg.sender, 1);
        _mint(msg.sender, 1);
    }

    function userMinted(address address_) public view returns (bool) {
        return _getAux(address_) == 1;
    }

    function mintAsAdmin(address recipient, uint256 quantity) public onlyOwner {
        require(_totalMinted() + quantity <= mintableSupply, "Max Supply Hit");
        _mint(recipient, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(baseUri).length == 0) {
            return "";
        }
        return
            string(
                abi.encodePacked(baseUri, Strings.toString(tokenId), ".json")
            );
    }

    function setMintableSupply(uint256 mintableSupply_) public onlyOwner {
        mintableSupply = mintableSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("Not Allowed");
    }

    function approve(address, uint256) public payable override {
        revert("Not Allowed");
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (to != address(0) && from != address(0)) {
            revert("Not Allowed");
        }
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function changeBaseUri(string memory baseUri_) public onlyOwner {
        baseUri = baseUri_;
    }
}