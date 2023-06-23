// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol"; 
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract THECLUB is Ownable, ERC721  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 public mintFees;
    address public admin;
    mapping (address => bool) public _whitelist;
    mapping (address => uint256) public buyBalance;

    uint256 public start;
    uint256 public preSaleEnd;
    uint256 public pubSaleEnd;

    uint256 public sold;
    constructor () ERC721("THE CLUB F11", "$F11CLUB") {
        mintFees = 76 *10**15;
        admin = msg.sender;
        sold = 0;
        _safeMint(msg.sender, 1);
        _safeMint(msg.sender, 26);
        _safeMint(msg.sender, 51);
        _safeMint(msg.sender, 76);
        _safeMint(msg.sender, 101);
        _safeMint(msg.sender, 126);
        start = 1645437600;
        preSaleEnd = 1645524000;
        pubSaleEnd = 1645696800;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/bafybeiatu2dqn32xprwi4z26kuxr5ezkwr33xpicqxpy3ga2jftven2swe/";
    }

    function setAdmin (address newAdmin) public {
        require(msg.sender == admin, "unauthorized");
        admin = newAdmin;
    }

    function setDates (uint256 start_, uint256 preSaleEnd_, uint256 pubSaleEnd_) public {
        require(msg.sender == admin, "unauthorized");
        start = start_;
        preSaleEnd = preSaleEnd_;
        pubSaleEnd = pubSaleEnd_;
    }

    function whiteList (address[] calldata accounts, bool isWhiteList ) public {
        require(msg.sender == admin, "unauthorized");
        for (uint256 i = 0; i < accounts.length; ++i ) {
            _whitelist[accounts[i]] = isWhiteList;
        }
    }

    function mint(uint256 n) public payable returns(uint256) {
        require(buyBalance[msg.sender] < 2 && n <= 2, "you can only buy 2 NFTs");
        require(n <= 2 - buyBalance[msg.sender], "invalid n");
        
        require(msg.value == mintFees*n, "invalid fees");
        require(block.timestamp >= start, "minting no start yet");
        require(block.timestamp <= pubSaleEnd, "minting finished");
        uint256 newItemId = 0;
        for(uint256 i =0; i < n; ++i) {
            sold++;
            if(block.timestamp < preSaleEnd) {
                require(_whitelist[msg.sender], "you are not whitelisted");
                require(sold < 95, "pre sale sold out");
            }
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            if(newItemId == 1 || newItemId == 26 || newItemId == 51 || newItemId == 76 || newItemId == 101 || newItemId == 126){
                _tokenIds.increment();
                newItemId = _tokenIds.current();
            }
            // 1,26,51,76,101,126
            require(newItemId <= 150, "all minted");   
            _safeMint(msg.sender, newItemId);
            buyBalance[msg.sender] += n;
        
        }
        (bool succ, ) = address(0xcf60E7aAB58c7fdB68fe720182b5e450BAf85441).call{value: msg.value}("");
        require(succ, "ETH not sent");

        return newItemId;
    }

    function tokenURI(uint256 tokenId) override public view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return string(
            abi.encodePacked(
                baseURI,
                Strings.toString(tokenId),
                ".json"
            )
        );
    }

    function withdrawEth() public {
        require(msg.sender == admin, "only admin");
        uint256 Balance = address(this).balance;

        (bool succ, ) = address(admin).call{value: Balance}("");
        require(succ, "ETH not sent");
    }
}