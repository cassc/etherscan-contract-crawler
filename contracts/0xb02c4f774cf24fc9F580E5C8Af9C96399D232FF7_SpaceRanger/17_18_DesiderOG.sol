// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/presets/ERC1155PresetMinterPauser.sol)
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract DesiderOG is ERC721, Ownable {
    using Strings for uint256;

    string public baseURI;

    uint public constant MAX_SUPPLY = 300;

    uint private mintedNum = 0;

    uint private autoNum = 10;

    error SoulboundTokenNoSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes data
    );

    error SoulboundTokenNoSetApprovalForAll(address operator, bool approved);
    error SoulboundTokenNoIsApprovedForAll(address account, address operator);
    error SoulboundTokenNotApproved(address to, uint256 tokenId);
    error SoulboundTokenTransfer(address from, address to, uint256 tokenId);

    constructor(address _owner) ERC721("DESIDER OG", "DOG")
    {
         transferOwnership(_owner);
    }

    function totalSupply() public view returns (uint256) {
        return mintedNum;
    }

    function mulMint(address[] memory addrs) external onlyOwner {
        uint256 addrCount = addrs.length;
        require(
            totalSupply() + addrCount <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );

        uint i = 0;
        while (i < addrCount) {
            require(balanceOf(addrs[i]) < 1, "everyone can only have one");
            uint256 mintIndex = autoNum;
            if (_exists(mintIndex)) {
                autoNum ++;
                continue;
            }
            if (totalSupply() < MAX_SUPPLY) {
                mintedNum ++;
                autoNum ++;

                _safeMint(addrs[i], mintIndex);
            }
            i ++;
        }
    }

    function specifyMint(address[] memory to, uint256[] memory tokenIds) external onlyOwner {
        uint256 addrCount = to.length;
        require(
            totalSupply() + addrCount <= MAX_SUPPLY,
            "Sale would exceed max supply"
        );
        for(uint i = 0; i < addrCount; i ++) {
            require(balanceOf(to[i]) < 1, "everyone can only have one");
            mintedNum ++;
            _safeMint(to[i], tokenIds[i]);
        }

    } 

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        revert SoulboundTokenNoSafeTransferFrom(from, to, tokenId, data);
    }

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert SoulboundTokenNoSetApprovalForAll(operator, approved);
    }

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        revert SoulboundTokenNoIsApprovedForAll(owner, operator);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        revert SoulboundTokenNotApproved(to, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert SoulboundTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(_baseURI(), tokenId.toString(), ".json"));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

}