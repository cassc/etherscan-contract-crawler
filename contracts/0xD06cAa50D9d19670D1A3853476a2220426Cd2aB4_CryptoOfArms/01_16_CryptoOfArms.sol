// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Payment.sol";

contract CryptoOfArms is ERC1155, ERC2981, Payment, Ownable {
    enum SaleStatus{ PAUSED, PUBLIC }

    mapping(uint256 => bool) private _mintedIds;

    uint private constant MAX_SUPPLY = 10000;
    uint private constant TOKENS_PER_TRAN_LIMIT = 20;
    uint private MINT_PRICE = 1 ether;
    uint private MIN_MINT_PRICE = 0.03 ether;
    SaleStatus private saleStatus = SaleStatus.PAUSED;
    string private preRevealURL = "";
    mapping(address => uint) private _mintedCount;

    event Withdraw();

    constructor(
        address[] memory shareAddressList, 
        uint[] memory shareList, 
        uint96 _royaltyFeesInBips, 
        string memory _initBaseURI) ERC1155("") Payment(shareAddressList, shareList){
        setRoyaltyInfo(owner(), _royaltyFeesInBips);
        setURI(_initBaseURI);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /// @notice Reveal metadata for all the tokens
    function reveal(string calldata url) external onlyOwner {
         _setURI(url);
    }
    
    /// @notice Set Pre Reveal URL
    function setPreRevealUrl(string calldata url) external onlyOwner {
        preRevealURL = url;
    }

    /// @notice Get token URI. In case of delayed reveal we give user the json of the placeholer metadata.
    /// @param tokenId token ID
    function tokenURI(uint tokenId) public view returns (string memory) {
        string memory baseURI = uri(tokenId);

        return bytes(baseURI).length > 0 
            ? string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId), ".json"))
            : string(abi.encodePacked(preRevealURL, "/", Strings.toString(tokenId), ".json"));
    }

    function totalSupply() public pure returns (uint) {
        return MAX_SUPPLY;
    }

    function isMinted(uint256 id) public view returns (bool) {
        return _mintedIds[id] == true;
    }

    /// @notice Update current sale stage
    function setSaleStatus(SaleStatus status) external onlyOwner {
        saleStatus = status;
    }

    /// @notice Update public mint price
    function setPublicMintPrice(uint price) external onlyOwner {
        MINT_PRICE = price;
    }

    function setPublicMinMintPrice(uint price) external onlyOwner {
        MIN_MINT_PRICE = price;
    }

    function calcFamilynamePrice (uint id) public view returns (uint)
    {
        require(id > 0, "Token doesn't exists");
        require(id <= MAX_SUPPLY, "Token doesn't exists");

        if(id <= 970){
            return MINT_PRICE - (id -1) * 10 ** 18 / 1000;
        }

        return MIN_MINT_PRICE;
    }

    function calcBatchFamilynamePrice (uint[] memory ids) public view returns (uint)
    {
        uint256 price = 0;
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            price += calcFamilynamePrice(id);
        }

        return price;
    }

    function airdrop(address to, uint256 id) external onlyOwner {
        require(saleStatus != SaleStatus.PAUSED, "Cryptoarms: Sales are off");
        require(id > 0, "Token doesn't exists");
        require(id <= MAX_SUPPLY, "Token doesn't exists");

        require(_mintedIds[id] != true, "Token already minted" );

        _mint(to, id, 1, "");


        _mintedIds[id] = true;
    }

    function mint(uint256 id) public payable {
        require(saleStatus != SaleStatus.PAUSED, "Cryptoarms: Sales are off");
        require(id > 0, "Token doesn't exists");
        require(id <= MAX_SUPPLY, "Token doesn't exists");

        require(_mintedIds[id] != true, "Token already minted" );

        uint price = calcFamilynamePrice(id);
        require(msg.value >= price, "ETH input is wrong");
       
        require(msg.value >= calcFamilynamePrice(id), "Cryptoarms: Ether value sent is not sufficient");  

        _mint(msg.sender, id, 1, "");

        _mintedIds[id] = true;
	}


    function mintBatch(uint256[] memory ids) public payable
    {
        require(saleStatus != SaleStatus.PAUSED, "Cryptoarms: Sales are off");
        require(ids.length <= TOKENS_PER_TRAN_LIMIT, "Cryptoarms: Number of requested tokens exceeds allowance (20)");
        
        uint totalPrice = calcBatchFamilynamePrice(ids);
        require(msg.value >= totalPrice, "ETH input is wrong");

        uint[] memory amounts = new uint[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            require(id > 0, "Token doesn't exists");
            require(id <= MAX_SUPPLY, "Token doesn't exists");
            require(_mintedIds[id] != true, "Some tokens already minted" );
            amounts[i] = 1;
        }

        _mintBatch(msg.sender, ids, amounts, "");

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            _mintedIds[id] = true;
        }       
    }

    function withdraw() external  {
        _withdraw(payable(msg.sender));
        emit Withdraw();
	}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}