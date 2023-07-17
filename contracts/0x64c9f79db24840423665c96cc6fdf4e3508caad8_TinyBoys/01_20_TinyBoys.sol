// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC2981.sol";
import "./OERC721R.sol";
import "./layerzero/contracts/token/onft/ONFT721Core.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TinyBoys is Ownable, IERC2981, OERC721R, ONFT721Core {

    using Address for address;
    using Strings for uint256;

    uint256 public saleStartTimestamp = 1652817600;
    uint256 public whitelistEndTimestamp = 1652904000;

    uint256 public royaltyAmount = 1000;
    address public royaltyAddress;
    
    uint256 public mintPrice;

    string public baseProofURI;
    string public baseTokenURI;

    string private wholeContractURI;

    mapping(address => uint256) public whitelist;

    uint256 private whitelistQuantity;

    constructor(
        uint256 _mintPrice,
        uint256 _traverseFee,
        address _lzEndpoint,
        uint256 _offset,
        uint256 _supply
    )
        OERC721R(
            "TinyBoys", 
            "TBOY",
            _offset,
            _supply
        )
        ONFT721Core(
            _lzEndpoint, 
            _traverseFee
        )
    {
        mintPrice = _mintPrice;

        royaltyAddress = owner();
    }

    function claim(address _to) external {
        require(isSaleLive());

        uint256 _amount = whitelist[_msgSender()];
        require(_amount > 0);
        
        _removeWhitelist(_msgSender());

        _mintRandom(_to, _amount);
    }

    function mint(address _to, uint256 _amount) external payable {
        require(isSaleLive());
        require(msg.value == mintPrice * _amount);
        require(_amount <= 10);
        require(_amount + totalMint() <= _availableMint());

        _mintRandom(_to, _amount);
    }

    function addWhitelist(address[] memory _address, uint256 _quantity) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i ++) {
            whitelist[_address[i]] = _quantity;
        }

        whitelistQuantity += (_address.length * _quantity);
    }

    function removeWhitelist(address _address) external onlyOwner {
        _removeWhitelist(_address);
    }

    function setContractURI(string memory _string) external onlyOwner {
        wholeContractURI = _string;
    }

    function setBaseProofURI(string memory _string) external onlyOwner {
        require(!isSaleLive());
        baseProofURI = _string;
    }

    function setBaseTokenURI(string memory _string) external onlyOwner {
        baseTokenURI = _string;
    }

    function setSaleStartTimestamp(uint256 _timestamp) external onlyOwner {
        require(!isSaleLive());
        saleStartTimestamp = _timestamp;
    }

    function setWhitelistEndTimestamp(uint256 _timestamp) external onlyOwner {
        whitelistEndTimestamp = _timestamp;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setRoyaltyAmount(uint256 _amount) external onlyOwner {
        royaltyAmount = _amount;
    }

    function setRoyaltyAddress(address _address) external onlyOwner {
        royaltyAddress = _address;
    }

    function withdraw(address _address) external onlyOwner {
        payable(_address).transfer(address(this).balance);
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view override returns (address, uint256) {
		return (royaltyAddress, (_salePrice * royaltyAmount) / 10000);
	}

    function contractURI() external view returns (string memory) {
        return wholeContractURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(OERC721R, ONFT721Core, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function isSaleLive() public view returns (bool) {
        return saleStartTimestamp <= block.timestamp;
    }

    function proofURI(uint256 tokenId) public view returns (string memory) {
        return bytes(baseProofURI).length > 0 ? string(abi.encodePacked(baseProofURI, tokenId.toString())) : "";
    }

    function _removeWhitelist(address _address) internal {
        whitelistQuantity -= whitelist[_address];
        whitelist[_address] = 0;
    }

    function _debitFrom(address _from, uint16, bytes memory, uint _tokenId) internal virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId));
        require(OERC721R.ownerOf(_tokenId) == _from);
        _burn(_tokenId);
    }

    function _creditTo(uint16, address _toAddress, uint _tokenId) internal virtual override {
        _mint(_toAddress, _tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _availableMint() internal view returns (uint256) {
        if (whitelistEndTimestamp > block.timestamp) {
            return maxMint() - whitelistQuantity;
        }

        return maxMint();
    }

}