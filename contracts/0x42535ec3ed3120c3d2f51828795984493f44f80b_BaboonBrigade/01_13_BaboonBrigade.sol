// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721.sol";
contract BaboonBrigade is Ownable, ERC721 {
    using Strings for uint256;
    using ECDSA for bytes32;
    using SafeMath for uint256;
    uint256 public constant BBG_MAX = 7777; // total amount
    uint256 public constant BBG_PRESALE_LIMIT = 5; // presale stage
    uint256 public constant BBG_PUBLIC_LIMIT = 10; // public stage
    /// @notice price of each NFT for each stage
    uint256 public constant BBG_PRESALE_PRICE = 0.05 ether; // presale first stage
    uint256 public constant BBG_PUBLIC_PRICE = 0.07 ether; // public stage
    uint256 public BBG_PER_PRICE = BBG_PRESALE_PRICE; // per price
    uint256 public BBG_PER_MINT = BBG_PRESALE_LIMIT; // limit per mint
    uint256 public lastTokenId; // last token id
    /// @notice company wallet address which accept all payments
    address payable public companyAddress =
        payable(0x2d2DA12fFb23e1025d2490657e96289C37FC28B3); // company address
    /// @notice royalty address
    address public creatorAddress = 0xD387098B3CA4C6D592Be0cE0B69E83BE86011c50;
    /// @notice base token uri for metadata uri
    string public publicBaseURI = "";
    string public hiddenBaseURI = "";
    uint256 revealPointer = 0;
    /// @notice status enum for nft
    enum State {
        PRESALE,
        PUBLIC
    }
    /// @dev current stage of sale
    State public _state;
    event Presale(uint256 tokenId, address sender, uint256 payAmount);
    event PublicSale(uint256 tokenId, address sender, uint256 payAmount);
    constructor(string memory _publicBaseURI, string memory _hiddenBaseURI)
        ERC721("BaboonBrigade", "BBG")
    {
        publicBaseURI = _publicBaseURI;
        hiddenBaseURI = _hiddenBaseURI;
    }
    /**
     * @notice buy nfts
     * @param tokenQuantity total amount of nft to be minted
     */
    function buy(uint256 tokenQuantity) external payable {
        require(tokenQuantity <= BBG_PER_MINT, "EXCEED_PER_MINT");
        require(
            lastTokenId.add(tokenQuantity) <= BBG_MAX,
            "Sorry, there's not that many BBG left."
        );
        require(
            BBG_PER_PRICE * tokenQuantity <= msg.value,
            "Not Enough payments"
        );
        for (uint256 i = 0; i < tokenQuantity; i++) {
            uint256 tokenId = lastTokenId + 1;
            _safeMint(msg.sender, tokenId);
            lastTokenId++;
            emit PublicSale(tokenId, msg.sender, BBG_PER_PRICE);
        }
		companyAddress.transfer(msg.value);
    }
    /**
     * @notice Results a Remaining amount
     * @dev Total amount - minted amount
     */
    function getAmount() internal view returns (uint256) {
        return BBG_MAX - lastTokenId;
    }
    /**
     * @notice Results a price per NFT
     * @dev Only admin
     * @dev Set price per NFT
     */
    function setPrice(uint256 _price) external onlyOwner {
        BBG_PER_PRICE = _price;
    }
    /**
     * @notice return current NFT price
     * @return current NFT price per stage
     */
    function getCurrentPrice() external view returns (uint256) {
        return BBG_PER_PRICE;
    }
    /**
     * @notice Results a metadata URI
     * @param tokenId token URI per token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Cannot query non-existent token");
        if( revealPointer > tokenId ){
            return
                string( abi.encodePacked(
                                         publicBaseURI,
                                         tokenId.toString()
                                         ) );
        }
        return hiddenBaseURI;
    }
    /**
     * @notice Results a metadata uri
     * @param _tokenHiddenBaseURI token ID which need to be finished
     */
    function setTokenHiddenBaseUri(string memory _tokenHiddenBaseURI)
        public
        onlyOwner
    {
        hiddenBaseURI = _tokenHiddenBaseURI;
    }
    /**
     * @notice Results a metadata uri
     * @param _tokenPublicBaseURI token ID which need to be finished
     */
    function setTokenPublicBaseUri(string memory _tokenPublicBaseURI)
        public
        onlyOwner
    {
        publicBaseURI = _tokenPublicBaseURI;
    }
    function setRevealPointer(uint256 _revealPointer) public onlyOwner {
        revealPointer = _revealPointer;
    }
    /**
     * @notice Results a company wallet address
     * @param addr change another wallet address from wallet address
     */
    function setCompanyAddress(address payable addr) public onlyOwner {
        companyAddress = addr;
    }
    /**
     * @notice set creator wallet address
     * @param addr change another wallet address from wallet address
     */
    function setCreatorAddress(address payable addr) public onlyOwner {
        creatorAddress = addr;
    }
    /**
     * @notice Results a max value can buy
     */
    function getMaxValue() external view returns (uint256) {
        return BBG_PER_MINT;
    }
    /**
     * @notice getter method of current contract status
     * @return current contract status
     */
    function state() public view virtual returns (State) {
        return _state;
    }
    /**
     * @notice set current sale state
     * @param newState new state of sales
     */
    function setState(State newState) external onlyOwner {
        _state = newState;
        if (newState == State.PRESALE) {
            BBG_PER_PRICE = BBG_PRESALE_PRICE;
        } else if (newState == State.PUBLIC) {
            BBG_PER_PRICE = BBG_PUBLIC_PRICE;
        }
    }
}