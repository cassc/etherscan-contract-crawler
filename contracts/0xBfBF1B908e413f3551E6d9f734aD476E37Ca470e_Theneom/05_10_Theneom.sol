// SPDX-License-Identifier: MIT
/***********************************************************
 * (o)__(o)\\  //      \\\  ///          .-.   \\\    ///  *
 * (__  __)(o)(o)  wWw ((O)(O)) wWw    c(O_O)c ((O)  (O))  *
 *   (  )  ||  ||  (O)_ | \ ||  (O)_  ,'.---.`, | \  / |   *
 *    )(   |(__)| .' __)||\\|| .' __)/ /|_|_|\ \||\\//||   *
 *   (  )  /.--.\(  _)  || \ |(  _)  | \_____/ ||| \/ ||   *
 *    )/  -'    `-`.__) ||  || `.__) '. `---' .`||    ||   *
 *   (                 (_/  \_)        `-...-' (_/    \_)  *
************************************************************/
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Theneom is ERC721A, DefaultOperatorFilterer, Ownable {
    using Strings for uint256;

    string public baseURI;
    address public withdrawAddress;
    uint256 public totalQuantity;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public mintPrice;
    uint256 public perUserMint;
    bool public openMint;

    mapping(address => uint256) public mintedCount;


    constructor() ERC721A("Theneom", "Theneom"){
        withdrawAddress = owner();
        totalQuantity = 20000;

        startTime = 1681095600;
        endTime = startTime + 45 * 24 * 60 * 60;
        mintPrice = 0 ether;
        perUserMint = 3;
        openMint = true;
        baseURI = "https://www.theneom.io/api/metadata/";
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable  override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)  public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }


    function setTotalQuantity(uint256 _totalQuantity) external onlyOwner {
        totalQuantity = _totalQuantity;
    }

    function setWithdrawAddress(address newWithdrawAddress) external onlyOwner {
        withdrawAddress = newWithdrawAddress;
    }

    function setMint(uint256 _startTime, uint256 _endTime, uint256 _mintPrice, uint256 _perUserMint, bool _openMint) external onlyOwner {
        startTime = _startTime;
        endTime = _endTime;
        mintPrice = _mintPrice;
        perUserMint = _perUserMint;
        openMint = _openMint;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier isWithdrawAddress() {
        require(
            withdrawAddress == msg.sender,"The caller is incorrect address."
        );
        _;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory)  {
        if (!_exists(tokenId))
        {
            revert URIQueryForNonexistentToken();
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")): "";
    }

    function withdrawTo(address beneficiary, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "amount is illegal");
        payable(beneficiary).transfer(amount);
    }

    function withdraw() external isWithdrawAddress callerIsUser() {
        payable(withdrawAddress).transfer(address(this).balance);
    }

    function airdrop(address[] calldata recipients, uint256[] calldata values) external onlyOwner {
        require(recipients.length == values.length, "len wrong");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(_totalMinted() + values[i] <= totalQuantity,"Max supply reached");
            _safeMint(recipients[i], values[i]);
        }
    }

    function mint(uint256 quantity) external payable callerIsUser {
        require(openMint == true,"Sale phase mismatch");
        require(startTime < block.timestamp,"Sale no start");
        require(endTime > block.timestamp,"Sale end");
        require(_totalMinted() + quantity <= totalQuantity,"Max supply reached");
        uint256 walletMinted = mintedCount[msg.sender];
        require(perUserMint - walletMinted >= quantity,"Exceeds personal limit");
        require(msg.value >= mintPrice * quantity, "Incorrect price");
        mintedCount[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function totalMinted() public view returns(uint256) {
        return _totalMinted();
    }

    function getMintSettings() external view
    returns (
        uint256 _startTime,
        uint256 _endTime,
        uint256 _mintPrice,
        uint256 _perUserMint,
        uint256 _totalMintedCount,
        uint256 _totalQuantity
    ){
        return (
            startTime,
            endTime,
            mintPrice,
            perUserMint,
            _totalMinted(),
            totalQuantity
        );
    }

    function getMintedInfo(address _address) external view returns (uint256 _mintedCount) {
        return mintedCount[_address];
    }
}