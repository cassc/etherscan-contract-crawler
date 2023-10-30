// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract NerdyNuggets is ERC721, ERC721Enumerable, Ownable {

    using SafeMath for uint256;
    string public NerdyNugget_PROVENANCE = ""; // IPFS added once sold out
    string public LICENSE_TEXT = "";
    bool licenseLocked = false;
    uint public constant maxNerdyNuggetPurchase = 20;
    uint256 public constant MAX_NUGGETS = 10000;
    bool public saleIsActive = false;
    
    uint256 private _nerdyNuggetPrice = 3000000000000000; // 0.03 ETH
    string private baseURI;
    uint private _nerdyNuggetReserve = 200;

    mapping(uint => string) public nerdyNuggetNames;

    event licenseisLocked(string _licenseText);

    constructor() ERC721("Nerdy Nuggets", "NN") { }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        uint remainingBalance = balance;
        uint balanceToMultiply = balance / uint(1000); // 100% in thousandths
        uint twentyPercent = uint(200); // 20% in thousandths
        uint onePointFivePercent = uint(15); //1.5% in thousandths
        uint twoPointFivePercent = uint(25); // 2.5% in thousandths

        uint twentyPercentBalanceDropt = balanceToMultiply * twentyPercent;
        remainingBalance = remainingBalance - twentyPercentBalanceDropt;
        uint twentyPercentBalanceParley = balanceToMultiply * twentyPercent;
        remainingBalance = remainingBalance - twentyPercentBalanceParley;
        uint onePointFiveBalanceIcon = balanceToMultiply * onePointFivePercent;
        remainingBalance = remainingBalance - onePointFiveBalanceIcon;
        uint twoPointFiveBalanceRico = balanceToMultiply * twoPointFivePercent;
        remainingBalance = remainingBalance - twoPointFiveBalanceRico;

        payable(address(0x066D71a1F7e1A96Da69D6113e7e3C546bb7e44FC)).transfer(twentyPercentBalanceDropt); //20% to dropt
        payable(address(0xc64AaA34Cf9DcE746A4C5dA2A0732CAf86BBDA5d)).transfer(twentyPercentBalanceParley); // 20% to Parley
        payable(address(0x3097617CbA85A26AdC214A1F87B680bE4b275cD0)).transfer(onePointFiveBalanceIcon); // 1.5% to icon
        payable(address(0xa45C7CCbBFaAD6668DDF2B59A6593293B9922A11)).transfer(twoPointFiveBalanceRico); // 2.5% to Rico
        payable(msg.sender).transfer(remainingBalance);
    }
    
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _nerdyNuggetPrice = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return _nerdyNuggetPrice;
    }
    
    function reserveNuggets(address _to, uint256 _reserveAmount) public onlyOwner {
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= _nerdyNuggetReserve, "Reserve limit has been reached");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        _nerdyNuggetReserve = _nerdyNuggetReserve.sub(_reserveAmount);
    }


    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        NerdyNugget_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }


    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Returns the license for tokens
    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Choose a NerdyNugget in supply range");
        return LICENSE_TEXT;
    }

    // Locks the license to prevent further changes
    function lockLicense() public onlyOwner {
        licenseLocked =  true;
        emit licenseisLocked(LICENSE_TEXT);
    }

    // Change the license
    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License already locked");
        LICENSE_TEXT = _license;
    }


    function mintNerdyNuggets(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint NerdyNuggets");
        require(numberOfTokens > 0 && numberOfTokens <= maxNerdyNuggetPurchase, "Oops - you can only mint 20 NerdyNuggets at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_NUGGETS, "Purchase exceeds max supply of NerdyNuggets");
        require(msg.value >= _nerdyNuggetPrice.mul(numberOfTokens), "Ether value is incorrect. Check and try again");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_NUGGETS) {
                _safeMint(msg.sender, mintIndex);
            }
        }

    }


    // All Nuggets in wallet
    function nerdyNuggetNamesOfOwner(address _owner) external view returns(string[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new string[](0);
        } else {
            string[] memory result = new string[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = nerdyNuggetNames[ tokenOfOwnerByIndex(_owner, index) ] ;
            }
            return result;
        }
    }

}