// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISpaceEggz.sol";

//
//            _ _              __  __      _
//      /\   | (_)            |  \/  |    | |
//     /  \  | |_  ___ _ __   | \  / | ___| |_ __ _
//    / /\ \ | | |/ _ \ '_ \  | |\/| |/ _ \ __/ _` |
//   / ____ \| | |  __/ | | | | |  | |  __/ || (_| |
//  /_/    \_\_|_|\___|_| |_| |_|  |_|\___|\__\__,_|

// AlienMeta.wtf - Mowgli + Dev Lrrr

contract SpaceEggz is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdCounter;
 
    uint256 public hatchPrice = 100 * 10**18;
    ISpaceEggz public hatcheryContract;

    bool public isRevealed = false;
    bool public isStarted = false;
    string public baseURI;
    address public breeding;
    address public upg;

    IERC20 public seggzCoin;
    address seggzCoinAddress;

    mapping(address => uint256) public promoCode;
    address public hatcheryAddress;
    event Minted(uint256 indexed idMinted, address indexed minter);

    constructor(address _hatcheryAddress, address _seggzCoinAddress)
        ERC721("SpaceEggz", "SpaceEggz")
    {
        hatcheryContract = ISpaceEggz(_hatcheryAddress);
        hatcheryAddress = _hatcheryAddress;

        seggzCoin = IERC20(_seggzCoinAddress);
        seggzCoinAddress = _seggzCoinAddress;
    }

    function updateHatcheryContractAddress(address _hatcheryContract)
        external
        onlyOwner
    {
        hatcheryContract = ISpaceEggz(_hatcheryContract);
        hatcheryAddress = _hatcheryContract;
    }

    function isUserAHatcheryHolder(address _user) public view returns (bool) {
        if (hatcheryContract.balanceOf(_user) > 0) {
            return true;
        } else {
            return false;
        }
    }

    function doesUserHoldThisEggID(address _user, uint256 _tokenID)
        public
        view
        returns (bool)
    {
        if (hatcheryContract.ownerOf(_tokenID) == _user) {
            return true;
        } else {
            return false;
        }
    }

    function getCurrentPrice(address _userAddress)
        public
        view
        returns (uint256)
    {
        uint256 currentPrice = 0;
        uint256 promo = promoCode[_userAddress];
        if (promo > 0) {
            if (promo == 100) {
                currentPrice = 0;
            } else {
                currentPrice = (hatchPrice * promo) / 100;
            }
        } else {
            currentPrice = hatchPrice;
        }

        return currentPrice;
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

    function modifyHatchPrice(uint256 _newPrice) external onlyOwner {
        hatchPrice = _newPrice;
    }

    function gethatchPrice() public view returns (uint256) {
        return hatchPrice;
    }

    // approve

    function hatchEgg(uint256 _eggID) external {
        require(isStarted == true, "not started");
        require(
            isUserAHatcheryHolder(msg.sender) == true,
            "You must hold atleast 1 GASA Egg!"
        );
        require(
            doesUserHoldThisEggID(msg.sender, _eggID) == true,
            "You don't own this tokenID!!"
        );

        require(
            seggzCoin.balanceOf(msg.sender) >= gethatchPrice(),
            "not enough"
        );

        seggzCoin.transferFrom(msg.sender, address(this), gethatchPrice());

        hatcheryContract.breedingBurn(_eggID);

        promoCode[msg.sender] = 0;
        _tokenIdCounter.increment();
        uint256 the_current_id = _tokenIdCounter.current();
        _safeMint(msg.sender, the_current_id);
        emit Minted(the_current_id, msg.sender);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
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

    function withdrawSeggz() external onlyOwner {
        seggzCoin.transfer(
            seggzCoinAddress,
            seggzCoin.balanceOf(address(this))
        );
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