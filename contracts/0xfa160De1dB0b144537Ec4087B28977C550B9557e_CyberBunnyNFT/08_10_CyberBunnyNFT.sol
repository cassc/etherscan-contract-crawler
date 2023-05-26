// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CyberBunnyNFT is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    using ECDSA for bytes32;
    string public baseTokenURI = "";
    uint256 public PUBLIC_SALE_PRICE = 0.004 ether;
    uint256 public MAX_PER_WALLET_FREE = 1;
    uint256 public MAX_PER_WALLET_PAID = 3;
    uint256 public MAX_SUPPLY = 3000;
    uint256 private freestops = 3000;
    bool Mintenable = false;

    mapping(address => uint256) public Freemintlimit;
    mapping(address => uint256) public paidMintLimit;
    mapping(address => mapping(string => bool)) public processedNonces;

    constructor() ERC721A("CyberBunnyNFT", "CB") {}

    modifier Validmint() {
        require(Mintenable, "Mint stoped");
        require(totalSupply() < MAX_SUPPLY, "max supply reached");
        _;
    }



    function Mint(bytes memory _signature,string memory _msg) external payable Validmint {
        require(isMessageValid(_signature, _msg), "signature invalid");
        require(processedNonces[msg.sender][_msg] == false,"invalid nonce");
        processedNonces[msg.sender][_msg] = true;
        if (totalSupply() < freestops) {
            if (Freemintlimit[msg.sender] < MAX_PER_WALLET_FREE) {
                Freemintlimit[msg.sender] += 1;
            } else {
                require(
                    PUBLIC_SALE_PRICE <= msg.value,
                    "Incorrect ETH value sent"
                );
                require(
                    paidMintLimit[msg.sender] < MAX_PER_WALLET_PAID,
                    "limit end"
                );
                paidMintLimit[msg.sender] += 1;
            }
        } else {
            require(PUBLIC_SALE_PRICE <= msg.value, "Incorrect ETH value sent");
            require(
                paidMintLimit[msg.sender] < MAX_PER_WALLET_PAID,
                "limit end"
            );
            paidMintLimit[msg.sender] += 1;
        }
        _safeMint(msg.sender, 1);
    }

   

    function AdminMint(uint256 _amount) external Validmint onlyOwner {
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

    function setAfreestops(uint256 _new) external onlyOwner {
        freestops = _new;
    }

    function setMintEnable(bool _mint) external onlyOwner {
        Mintenable = _mint;
    }

    function isMessageValid(bytes memory _signature, string memory _msg)
        public
        view
        returns (bool)
    {
        bytes32 messagehash = keccak256(abi.encodePacked(_msg));
        address signer = messagehash.toEthSignedMessageHash().recover(
            _signature
        );

        if (msg.sender == signer) {
            return true;
        } else {
            return false;
        }
    }

    function FreeOrPaid(address _user)
        public
        view
        returns (string memory, bool)
    {
        if (totalSupply() < freestops) {
            if (Freemintlimit[_user] < MAX_PER_WALLET_FREE) {
                return ("free", true);
            } else {
                return ("paid", (paidMintLimit[_user] < MAX_PER_WALLET_PAID));
            }
        } else {
            if (paidMintLimit[_user] < MAX_PER_WALLET_PAID) {
                return ("paid", (paidMintLimit[_user] < MAX_PER_WALLET_PAID));
            } else {
                return ("paid", false);
            }
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}