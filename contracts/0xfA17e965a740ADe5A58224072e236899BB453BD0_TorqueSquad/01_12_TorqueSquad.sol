// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P^         
//  [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P~       
//    ^5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G!     
//      ^YB###################BB#@@@@@@@@@@@@@##BBBBBBBBBBBBBB###############5^   
//                            [email protected]@@@@@@@@@@P~ .!?77777777777^               ..   
//                          [email protected]@@@@@@@@@&5^    :J&@@@@@@@@@@&Y^                  
//                        .J#@@@@@@@@@@&Y^        [email protected]@@@@@@@@@@P~                
//                      :Y&@@@@@@@@@@&J:             [email protected]@@@@@@@@@@G~              
//                    ^Y&@@@@@@@@@@#?.                 [email protected]@@@@@@@@@@G!            
//                  ^[email protected]@@@@@@@@@@B?.                     [email protected]@@@@@@@@@@B7.         
//                [email protected]@@@@@@@@@@B7                          ^[email protected]@@@@@@@@@@#?.       
//              [email protected]@@@@@@@@@@G~                              :Y&@@@@@@@@@@#J:     
//            [email protected]@@@@@@@@@@P~^J55555555555555555555555555555Y?~^J#@@@@@@@@@@&Y:   
//         [email protected]@@@@@@@@@&5^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#J~?#@@@@@@@@@@&5^ 
//       .J#@@@@@@@@@@&Y^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@Y
//     :Y&@@@@@@@@@@#J^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B
//   :Y&@@@@@@@@@@&J:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&5:

contract TorqueSquad is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_TOKENS = 8888;
    uint256 public constant MAX_PER_MINT = 4;
    uint256 public constant PRESALE_MAX_MINT = 4;
    uint256 public constant MAX_TOKENS_PER_WALLET = 50;
    uint256 public constant RESERVED_TOKENS = 500;

    uint256 public reservedClaimed;

    uint256 public numTokensMinted;

    string public baseTokenURI;

    uint256 public price = 0.08 ether;
    
    //0 default, 1 presale active, 2 public sale active
    uint256 public state;

    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _totalClaimed;

    event BaseURIChanged(string baseURI);
    event PresaleMint(address minter, uint256 count);
    event PublicSaleMint(address minter, uint256 count);

    modifier whenPresaleStarted() {
        require(state >= 1, "presale has not started");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(state >= 2, "public sale has not started");
        _;
    }

    function addToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = true;
        }
    }

    function checkWhitelist(address addr) external view returns (bool) {
        return _whitelist[addr];
    }

    function amountClaimedBy(address owner) external view returns (uint256) {
        require(owner != address(0), "address cannot be null");

        return _totalClaimed[owner];
    }

    function claimReserved(address recipient, uint256 count) external onlyOwner {
        require(reservedClaimed != RESERVED_TOKENS, "already claimed all reserved tokens");
        require(reservedClaimed + count <= RESERVED_TOKENS, "minting will exceed max reserved tokens");
        require(recipient != address(0), "address cannot be null");
        require(totalSupply() < MAX_TOKENS, "all tokens minted");
        require(totalSupply() + count <= MAX_TOKENS, "minting will exceed max supply");

        _safeMint(recipient, count);

        numTokensMinted += count;
        reservedClaimed += count;
    }

    function getFinalPrice(uint256 count, uint256 unitPrice, uint256 max) pure internal returns (uint256){
        if(count == max)
            return unitPrice * (count-1) + (unitPrice/2);
        else
            return unitPrice * count;
    }
    
    function mintPresale(uint256 count) external payable whenPresaleStarted {
        require(_whitelist[msg.sender], "not on whitelist");

        require(totalSupply() < MAX_TOKENS, "all tokens minted");
        require(count <= PRESALE_MAX_MINT, "max per mint exceeded");
        require(totalSupply() + count <= MAX_TOKENS, "minting will exceed max supply");
        require(_totalClaimed[msg.sender] + count <= PRESALE_MAX_MINT, "minting will exceed max per wallet");
        require(count > 0, "mint at least one");
        
        require(getFinalPrice(count,price,PRESALE_MAX_MINT) == msg.value, "eth amount is incorrect");

        _totalClaimed[msg.sender] += count;
        _safeMint(msg.sender, count);

        emit PresaleMint(msg.sender, count);
    }

    function mint(uint256 count) external payable whenPublicSaleStarted {
        require(totalSupply() < MAX_TOKENS, "all tokens minted");
        require(count <= MAX_PER_MINT, "max per mint exceeded");
        require(totalSupply() + count <= MAX_TOKENS, "minting will exceed max supply");
        require(_totalClaimed[msg.sender] + count <= MAX_TOKENS_PER_WALLET, "minting will exceed max per wallet");
        require(count > 0, "mint at least one");
        
        require(getFinalPrice(count,price,MAX_PER_MINT) == msg.value, "eth amount is incorrect");

        _totalClaimed[msg.sender] += count;
        _safeMint(msg.sender, count);

        emit PublicSaleMint(msg.sender, count);
    }

    function setState(uint256 s) external onlyOwner {
        require(s >= 0 && s <= 2 , "invalid state");
        state = s;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
        emit BaseURIChanged(baseURI);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
		price = newPrice;
	}

    function withdraw() public onlyOwner {
		uint balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
    
    constructor(string memory baseURI) ERC721A("TorqueSquad", "TSQ") Ownable() {
        baseTokenURI = baseURI;
    }

}