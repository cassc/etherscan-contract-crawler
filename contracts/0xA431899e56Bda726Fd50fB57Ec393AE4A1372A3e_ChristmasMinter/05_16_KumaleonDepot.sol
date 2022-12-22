// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract KumaleonDepot is ERC721, IERC2981, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    constructor(string memory customBaseURI_) ERC721("Kumaleon Depot", "KD") {
        customBaseURI = customBaseURI_;
    }

    /** MINTING **/

    uint256 public constant MAX_MULTIMINT = 100;

    Counters.Counter private supplyCounter;

    function mint(uint256[] calldata ids) public nonReentrant onlyOwner {
        uint256 count = ids.length;

        require(saleIsActive, "Sale not active");

        require(count <= MAX_MULTIMINT, "Mint at most 100 at a time");

        for (uint256 i = 0; i < count; i++) {
            uint256 id = ids[i];

            _mint(msg.sender, id);

            supplyCounter.increment();
        }
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    /** ACTIVATION **/

    bool public saleIsActive = false;

    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    /** URI HANDLING **/

    string private customBaseURI;

    mapping(uint256 => string) private tokenURIMap;

    function setTokenURI(uint256 tokenId, string memory tokenURI_)
    external
    onlyOwner
    {
        tokenURIMap[tokenId] = tokenURI_;
    }

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override
    returns (string memory)
    {
        string memory tokenURI_ = tokenURIMap[tokenId];

        if (bytes(tokenURI_).length > 0) {
            return tokenURI_;
        }

        return string(abi.encodePacked(super.tokenURI(tokenId)));
    }

    /** PAYOUT **/

    address private constant payoutAddress1 =
    0xD24aD79964244d0d382aECf4AF042b20C8C86F0B;

    function withdraw() public nonReentrant {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(payoutAddress1), balance);
    }

    /** ROYALTIES **/

    function royaltyInfo(uint256, uint256 salePrice) external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 1000) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, IERC165)
    returns (bool)
    {
        return (
        interfaceId == type(IERC2981).interfaceId ||
        super.supportsInterface(interfaceId)
        );
    }
}

// Contract created with Studio 721 v1.5.0
// https://721.so