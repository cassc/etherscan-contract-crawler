// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract TAOSTClubSBT is
    Initializable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenId;

    uint256 public constant totalSupply = type(uint256).max;

    struct TiersPrice {
        uint256 tier1;
        uint256 tier2;
        uint256 tier3;
    }

    TiersPrice public tiersPrice;

    function initialize(
        string memory name_,
        string memory symbol_
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init();
        tiersPrice.tier1 = 0.1 ether;
        tiersPrice.tier2 = 1 ether;
        tiersPrice.tier3 = 10 ether;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId;
    }

    function mint(string memory _tokenURI, uint256 tier) external payable {
        require(tier == 1 || tier == 2 || tier == 3, "The tier is not exist");
        require(
            (tier == 1 && msg.value >= tiersPrice.tier1) ||
                (tier == 2 && msg.value >= tiersPrice.tier2) ||
                (tier == 3 && msg.value >= tiersPrice.tier3),
            "Ether is insufficient"
        );

        require(balanceOf(_msgSender()) == 0, "The address already has token");
        _tokenId.increment();
        uint256 tokenId = _tokenId.current();

        _mint(_msgSender(), tokenId);
        _setTokenURI(tokenId, _tokenURI);
        _setApprovalForAll(_msgSender(), owner(), true);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override onlyOwner {
        require(balanceOf(to) == 0, "The address already has token");
        super._transfer(from, to, tokenId);
    }

    function setTiersPrice(uint256 tier, uint256 newPrice) external onlyOwner {
        require(tier == 1 || tier == 2 || tier == 3, "The tier is not exist");
        if (tier == 1) {
            tiersPrice.tier1 = newPrice;
        } else if (tier == 2) {
            tiersPrice.tier2 = newPrice;
        } else {
            tiersPrice.tier3 = newPrice;
        }
    }

    function setBatchTiersPrice(
        uint256[3] memory newPrices
    ) external onlyOwner {
        tiersPrice.tier1 = newPrices[0];
        tiersPrice.tier2 = newPrices[1];
        tiersPrice.tier3 = newPrices[2];
    }

    function burn(uint256 tokenId) external virtual onlyOwner {
        require(_exists(tokenId), "The token is not exist");
        super._burn(tokenId);
    }

    function withdraw() external onlyOwner {
        address payable _owner = payable(owner());
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success, "Transfer failed!");
    }
}