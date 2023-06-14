pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Peacefall is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 8192;
    uint256 public constant MAX_PER_MINT = 10;
    uint256 public constant PRICE_PER_MINT = 0.1 ether;
    bool public isAllowListActive = false;
    bool public isPublicActive = false;
    bool public reserved = false;

    string private _baseTokenURI;

    //allow list mapping: address -> amount eligible to int
    mapping(address => uint256) public allowList;

    constructor() ERC721A("Peacefall", "PF") {}

    function mintChallenger(uint256 quantity) external payable {
        require(isPublicActive, "Sale must be active to mint NFTs");
        require(msg.value >= quantity * PRICE_PER_MINT, "Not enough ETH");
        require(quantity <= MAX_PER_MINT, "Exceed limit per mint");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough Challengers remaining"
        );
        _safeMint(msg.sender, quantity);
    }

    function allowlistmintChallenger(uint256 quantity) external payable {
        require(isAllowListActive, "Allow list must be active to mint NFTs");
        // prevents wallets not in allowlist AND if allow list wallet exceeded mint limit
        require(allowList[msg.sender] >= quantity, "Not eligible for allowlist mint");
        require(msg.value >= quantity * PRICE_PER_MINT, "Not enough ETH");
        require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough Challengers remaining"
        );
        allowList[msg.sender] -= quantity;
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "NFT does not exist"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    // only run once per address to avoid overide quanitity
    function seedAllowList(address[] calldata addresses, uint256 quanitity) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            allowList[addresses[i]] = quanitity;
        }
    }

    function setPublicSaleActive(bool _isPublicSaleActive) external onlyOwner {
        isPublicActive = _isPublicSaleActive;
    }
    
    function setAllowListActive(bool _isAllowListActive) external onlyOwner {
        isAllowListActive = _isAllowListActive;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function reserveMint(uint256 quantity) external onlyOwner {
      require(
            totalSupply() + quantity <= MAX_SUPPLY,
            "Not enough Challengers remaining"
      );
      require(
            quantity % 8 == 0,
            "can only mint a multiple of 8"
      );
      require(reserved == false, "Already reserved");
      uint256 numChunks = quantity / 8;
      // needed to mint in batches to keep gas low
      for (uint256 i = 0; i < numChunks; i++) {
          _safeMint(msg.sender, 8);
      }
      reserved = true;
    }

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}