// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//            _ _              __  __      _
//      /\   | (_)            |  \/  |    | |
//     /  \  | |_  ___ _ __   | \  / | ___| |_ __ _
//    / /\ \ | | |/ _ \ '_ \  | |\/| |/ _ \ __/ _` |
//   / ____ \| | |  __/ | | | | |  | |  __/ || (_| |
//  /_/    \_\_|_|\___|_| |_| |_|  |_|\___|\__\__,_|

// AlienMeta.wtf - Mowgli + Dev Lrrr

contract SpaceEggzNFT is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable,
    ERC721Burnable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;

    uint256 private price = 0.1 ether;

    uint256 private totalFreeMints = 1;

    bool private isRevealed = false;
    bool private isStarted = false;
    uint256 private maxFreeMintQuantity = 222;
    string public baseURI;
    address public breeding;
    address public upg;

    mapping(address => uint256) public promoCode;

    constructor() ERC721("SpaceEggzNFT", "SpaceEggzNFT") {}

    event Minted(uint256 indexed idMinted, address indexed minter);

    function getMaxFreeMintQuantity() external view returns (uint256) {
        return maxFreeMintQuantity;
    }

    function setMaxFreeMintQuantity(uint256 _newQuantity) external onlyOwner {
        maxFreeMintQuantity = _newQuantity;
    }

    function getTotalFreeMints() external view returns (uint256) {
        return totalFreeMints;
    }

    function getABTotalFreeMints() external view returns (uint256) {
        return (totalFreeMints - 1);
    }

    function setTheTotalFreeMints(uint256 _newTotalFreeMints)
        external
        onlyOwner
    {
        totalFreeMints = _newTotalFreeMints;
    }

    function getCurrentPrice(address _userAddress)
        external
        view
        returns (uint256)
    {
        uint256 currentPrice = 0;
        uint256 currentId = getCurrentId();
        if (currentId > (totalFreeMints - 1)) {
            currentPrice = price;
            uint256 promo = promoCode[_userAddress];
            if (promo > 0) {
                if (promo == 100) {
                    currentPrice = 0;
                } else {
                    currentPrice = (price * promo) / 100;
                }
            }
        }

        return currentPrice;
    }

    function getMultipleNFTsPrice(address _user, uint256 _qte)
        public
        view
        returns (uint256)
    {
        uint256 currentPrice = 0;
        uint256 currentId = getCurrentId();
        if (currentId + _qte > (totalFreeMints - 1)) {
            currentPrice = price * _qte;
            uint256 promo = promoCode[_user];
            if (promo > 0) {
                if (promo == 100) {
                    currentPrice = (price * _qte) - price;
                } else {
                    currentPrice = (price * _qte) - ((price * promo) / 100);
                }
            }
        }
        return currentPrice;
    }

    function setTheNewPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function isRevealedFunction() external view returns (bool) {
        return isRevealed;
    }

    function changeRevealed() external onlyOwner {
        isRevealed = true;
    }

    function getStartStatus() external view returns (bool) {
        return isStarted;
    }

    function changeStatus() external onlyOwner {
        isStarted = !isStarted;
    }

    function setPromoCode(uint256 _promoCode, address user) external onlyOwner {
        promoCode[user] = _promoCode;
    }

    function getCurrentId() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addBreeding(address _address) external onlyOwner {
        require(_address != address(0), "not allowed");
        breeding = _address;
    }

    function addUpg(address _address) external onlyOwner {
        require(_address != address(0), "not allowed");
        upg = _address;
    }

    modifier onlyContract() {
        require(msg.sender == breeding || msg.sender == upg, "not contract");
        _;
    }

    function breedingMint(address _user, uint256 id) external onlyContract {
        _safeMint(_user, id);
    }

    function breedingBurn(uint256 id) external onlyContract {
        _burn(id);
    }

    function getNft(uint256 _quantity) external payable {
        require(isStarted == true, "not started");
        require(
            IERC721(address(this)).balanceOf(msg.sender) + _quantity <=
                maxFreeMintQuantity,
            "not allowed"
        );
        uint256 currentId = _tokenIdCounter.current();

        require(
            msg.value >= getMultipleNFTsPrice(msg.sender, _quantity),
            "not enough"
        );
        promoCode[msg.sender] = 0;
        for (uint256 i = 0; i <= _quantity; i++) {
            _tokenIdCounter.increment();
            uint256 the_current_id = _tokenIdCounter.current();
            _safeMint(msg.sender, the_current_id);
        }

        emit Minted(currentId, msg.sender);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if (isRevealed == false) {
            return
                string(
                    string(
                        abi.encodePacked(
                            "https://nft.nftpeel.com/spaceeggz/gen1/meta/",
                            tokenId.toString(),
                            ".json"
                        )
                    )
                );
        } else {
            return
                string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "failed to send ether");
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}