// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CyberBunny is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    string public baseTokenURI = "";
    uint256 public PUBLIC_SALE_PRICE = 0.004 ether;
    uint256 public MAX_PER_WALLET_FREE = 2;
    uint256 public MAX_PER_WALLET_PAID = 10;
    uint256 public MAX_SUPPLY = 5000;
    uint256 public LIMIT_PER_TX = 5;
    bool Mintenable = false;

    mapping(address => uint256) public Freemintlimit;
    mapping(address => uint256) public paidMintLimit;

    constructor() ERC721A("CyberBunny", "CBUNNY") {}

    modifier Validmint(uint256 _amount) {
        require(Mintenable, "Mint stoped");
        require(totalSupply() + _amount <= MAX_SUPPLY, "max supply reached");
        _;
    }

      function Mint(uint256 amount) public payable Validmint(amount) {
        require(LIMIT_PER_TX >= amount, "Limit over");
        //total free token minted by user
        uint256 Freelimitbyuser = Freemintlimit[msg.sender];
        //total paid token mint by user
        uint256 PaidMint = paidMintLimit[msg.sender];
        //Free Mint left for user
        uint256 Freemintleft = MAX_PER_WALLET_FREE - Freelimitbyuser;
        // total paid mint
        uint256 paidAmount = amount - Freemintleft;

        if (Freelimitbyuser < MAX_PER_WALLET_FREE) {
            if (amount <= Freemintleft) {
                Freemintlimit[msg.sender] += amount;
                _safeMint(msg.sender, amount);
            } else {
                require(
                    PaidMint + paidAmount < MAX_PER_WALLET_PAID,
                    "Limit end"
                );
                require(
                    PUBLIC_SALE_PRICE * paidAmount <= msg.value,
                    "Incorrect ETH value sent."
                );
                Freemintlimit[msg.sender] += Freemintleft;
                paidMintLimit[msg.sender] += paidAmount;
                _safeMint(msg.sender, amount);
            }
        } else {
            require(
                PUBLIC_SALE_PRICE * amount <= msg.value,
                "Incorrect ETH value sent"
            );
            require(PaidMint + amount < MAX_PER_WALLET_PAID, "Limit end");
            paidMintLimit[msg.sender] += amount;
            _safeMint(msg.sender, amount);
        }
    }




    function AdminMint(uint256 _amount) external Validmint(_amount) onlyOwner {
        _safeMint(msg.sender, _amount);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner nonReentrant {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(baseTokenURI, _tokenId.toString(), ".json")
            );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PUBLIC_SALE_PRICE = _price;
    }

    function setFreeLimitPerWallet(uint256 _limit) external onlyOwner {
        MAX_PER_WALLET_FREE = _limit;
    }

    function setPaidLimitPerWallet(uint256 _limit) external onlyOwner {
        MAX_PER_WALLET_PAID = _limit;
    }

    function setMaxSupply(uint256 _new) external onlyOwner {
        MAX_SUPPLY = _new;
    }

    function setLimitTx(uint256 _new) external onlyOwner {
        LIMIT_PER_TX = _new;
    }

    function setMintEnable(bool _mint) external onlyOwner {
        Mintenable = _mint;
    }

    function Freeleftbyuser(address _user)
        public
        view
        returns (uint)
    {
    
      uint freeleft = MAX_PER_WALLET_FREE - Freemintlimit[_user];
      return (freeleft);

    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}