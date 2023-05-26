pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GoldenGrannyPresaleToken is Ownable {
    function isOwner(address add) public view virtual returns (bool) {}
}

contract GoldenGranny is ERC721Enumerable, ERC721Pausable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _lastTokenIds;

    uint16 maxSupply = 9500;
    string private baseTokenURI = "";
    bool private mustCheckAuthorizationToMint = false;
    address private earlySupporterContractAddress = address(0x0);
    uint256 private tokenPrice = 0.04 ether;
    uint8 private discountInPercent = 0;
    uint8 private maxMintPerWallet = 0;
    uint8 private maxMintPerTransaction = 20; // can't be greater than 256
    mapping(address => uint8) private earlySupporterBalances;
    mapping(address => uint8) private notEarlySupporterBalances;

    constructor() ERC721("GoldenGranny", "GOLDENGRANNY") {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function mintNewGranny() public payable {
        // compute count
        uint256 count = 0;

        // check if wallet is allowed to mint
        if (mustCheckAuthorizationToMint && earlySupporterContractAddress != address(0x0)) {
            GoldenGrannyPresaleToken presaleContract = GoldenGrannyPresaleToken(earlySupporterContractAddress);
                 require(presaleContract.isOwner(msg.sender),
             "Must be early supporter token owner");
        }

        if (earlySupporterBalances[msg.sender] == 0) {
            count = (msg.value + discountInPercent * tokenPrice / 100) / tokenPrice;
            require(
                (msg.value + discountInPercent * tokenPrice / 100) % tokenPrice == 0,
                "Must pay a multiple of 0.04 eth + 0.02 eth"
            );
        } else {
            count = msg.value / tokenPrice;
            require(
                msg.value % tokenPrice == 0,
                "Must pay a multiple of 0.04 eth -- no discount"
            );
        }

        if (mustCheckAuthorizationToMint) {
            require(
                (maxMintPerTransaction == 0 || maxMintPerTransaction >= count) &&
                    (maxMintPerWallet == 0 ||
                        (maxMintPerWallet > 0 &&
                            earlySupporterBalances[msg.sender] + count <=
                            maxMintPerWallet)),
                "Unauthorized to mint so many"
            );
        } else {
            require(
                (maxMintPerTransaction == 0 || maxMintPerTransaction >= count) &&
                    (maxMintPerWallet == 0 ||
                        (maxMintPerWallet > 0 &&
                            notEarlySupporterBalances[msg.sender] + count <=
                            maxMintPerWallet)),
                "Unauthorized to mint so many"
            );
        }

        require(
            totalSupply() + count <= maxSupply,
            "No more grannies available"
        );
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _safeMint(msg.sender, newTokenId);
        }
        if (maxMintPerWallet > 0) {
            if (mustCheckAuthorizationToMint) {
                earlySupporterBalances[msg.sender] += uint8(count);
            }else{
                notEarlySupporterBalances[msg.sender] += uint8(count);
            }
        }
    }

    function mintSomeOfLastGranny(address[] memory addresses) public onlyOwner {
        uint16 lastTotalCount = 500;
        uint256 count = addresses.length;
        require(
            count <= lastTotalCount &&
            totalSupply() + count <= maxSupply + lastTotalCount, 
            "No more grannies available"
        );
        for (uint16 i=0; i<count; i++) {
            _lastTokenIds.increment();
            uint256 newTokenId = maxSupply + _lastTokenIds.current();
            _safeMint(addresses[i], newTokenId);
        }
    }

    function withdraw() public onlyOwner {
        uint256 withdrawableFunds = address(this).balance;
        payable(msg.sender).transfer(withdrawableFunds);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setTokenPrice(uint256 price) public onlyOwner {
        tokenPrice = price;
    }

    function getTokenPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function configureSale(bool mustCheck, uint8 discount, uint8 maxMint) public onlyOwner {
        mustCheckAuthorizationToMint = mustCheck;
        discountInPercent = discount;
        maxMintPerWallet = maxMint;
    }

    function setMintPerTransaction(uint8 quantity) public onlyOwner {
        maxMintPerTransaction = quantity;
    }

    function getMintPerTransaction() public view returns (uint8) {
        return maxMintPerTransaction;
    }

    function setAddressEarlySupporterContract(address newAddress)
        public
        onlyOwner
    {
        earlySupporterContractAddress = newAddress;
    }

    function getTotalPrice(uint8 count) public view returns (uint256) {
        require(count >= 1, "Count must be positive");
        // compute price
        if (earlySupporterBalances[msg.sender] >= 1) {
            return count * tokenPrice;
        } else {
            return
                ((100 - discountInPercent) * tokenPrice) / 100 + (count - 1) * tokenPrice;
        }
    }
}