// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A_royalty.sol";

contract IYKYK1px is Ownable, ERC721A, PaymentSplitter {

    using Strings for uint;

    string public baseURI;

    bool public saleOn = false;
    uint public publicSalePrice = 0 ether;
    uint public  MAX_SUPPLY = 36;
    uint256 public saleStartTime = 1682913600; // May 1, 2023, 00:00 ET - 1682913600
    uint256 public saleStopTime = 1685592000; // June 1, 2023, 00:00 ET - 1685592000

    uint private teamLength;

    uint96 royaltyFeesInBips;
    address royaltyReceiver;

    constructor(uint96 _royaltyFeesInBips, address[] memory _team, uint[] memory _teamShares, string memory _baseURI) ERC721A("IYKYK1px", "IYKYK1px")
    PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        teamLength = _team.length;
        royaltyFeesInBips = _royaltyFeesInBips;
        royaltyReceiver = msg.sender;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function currentTime() internal view returns(uint256) {
        return block.timestamp;
    }
    //MINTING
    function publicSaleMint(uint _quantity) external payable callerIsUser {
        require(saleOn == true, "Public sale is not activated");
        require(currentTime() > saleStartTime, "Sale is not started.");
        require(currentTime() < saleStopTime, "Sale has ended.");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(msg.value >= publicSalePrice * _quantity, "Not enought funds");
        _safeMint(msg.sender, _quantity);
    }

    function airdrop(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        _safeMint(_to, _quantity);
    }

    //ADMIN
    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }
    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
    function setSaleOn(bool _saleOn) external onlyOwner {
        saleOn = _saleOn;
    }
    function setSaleStartTime(uint256 _saleStartTime) external onlyOwner {
        saleStartTime = _saleStartTime;
    }
    function setSaleStopTime(uint256 _saleStopTime) external onlyOwner {
        saleStopTime = _saleStopTime;
    }
    

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    // ROYALTY
    function royaltyInfo (
    uint256 _tokenId,
    uint256 _salePrice
     ) external view returns (
        address receiver,
        uint256 royaltyAmount
     ){
         return (royaltyReceiver, calculateRoyalty(_salePrice));
     }

    function calculateRoyalty(uint256 _salePrice) view public returns (uint256){
        return(_salePrice / 10000) * royaltyFeesInBips;
    }

    function setRoyaltyInfo (address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        royaltyReceiver = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
    }

    //WITHDRAW
    function releaseAll() external onlyOwner {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }

}