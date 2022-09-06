// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "./ERC721A.sol";


/*
                                                                                                                                         
*/
contract BeyondConcept is ERC721A, Ownable {
    using Strings for uint256;

    address private constant TEAM_ADDRESS = 0x5e959D443b55463D116083416Bf9f36F84241e4f;

    uint256 public constant maxSupply = 499;
    uint256 public constant TEAM_CLAIM_AMOUNT = 19;


    uint256 public  MAX_PUBLIC_PER_TX = 3;
    uint256 public  MAX_PUBLIC_MINT_PER_WALLET = 6;

    bool claimed = false;

    uint256 public token_price = 0.01 ether;
    bool public publicSaleActive;


    string private _baseTokenURI;


    constructor() ERC721A("BeyondConcept", "BeyondConcept") {
        _safeMint(msg.sender, 6);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier underMaxSupply(uint256 _quantity) {
        require(
            _totalMinted() + _quantity <= maxSupply,
            "Mint would exceed max supply"
        );

        _;
    }

    modifier validatePublicStatus(uint256 _quantity) {
        require(publicSaleActive, "Sale hasn't started");
        require(msg.value >= token_price * _quantity, "Need to send more ETH.");
        require(_quantity > 0 && _quantity <= MAX_PUBLIC_PER_TX, "Invalid mint amount.");
        require(
            _numberMinted(msg.sender) + _quantity <= MAX_PUBLIC_MINT_PER_WALLET,
            "This purchase would exceed maximum allocation for public mints for this wallet"
        );

        _;
    }

    /**
     * @dev override ERC721A _startTokenId()
     */
    function _startTokenId() 
        internal 
        view 
        virtual
        override 
        returns (uint256) {
        return 1;
    }

    function mint(uint256 _quantity)
        external
        payable
        callerIsUser
        validatePublicStatus(_quantity)
        underMaxSupply(_quantity)
    {
        _mint(msg.sender, _quantity, "", false);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : '';
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

      function teamClaim() external onlyOwner {
        require(!claimed, "Team already claimed");
        // claim
        _safeMint(TEAM_ADDRESS, TEAM_CLAIM_AMOUNT);
        claimed = true;
  }

    
    function setMaxPerTxn(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        MAX_PUBLIC_PER_TX = _num;
    } 

    function setMaxPerWallet(uint256 _num) external onlyOwner {
        require(_num >= 0, "Num must be greater than zero");
        MAX_PUBLIC_MINT_PER_WALLET = _num;
    } 

    function setTokenPrice(uint256 newPrice) external onlyOwner {
        require(newPrice >= 0, "Token price must be greater than zero");
        token_price = newPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawFundsToAddress(address _address, uint256 amount) external onlyOwner {
        (bool success, ) =_address.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function flipPublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

}