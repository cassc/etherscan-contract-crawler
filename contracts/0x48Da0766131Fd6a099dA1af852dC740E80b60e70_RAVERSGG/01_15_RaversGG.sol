// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RAVERSGG is Context, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public MAX_PURCHASE = 10;

    uint256 public constant MAX_TOKENS = 5000;

    mapping(address => uint256) public minted;

    address public WHITELIST_SIGNER;

    bool public saleIsActive = false;

    string private _baseTokenURI;

    uint256 private _nftPrice;

    uint256 private _pendingWithdrawals;
    
    constructor() ERC721("RandomRaversGG", "RAVERSGG") {
        _nftPrice = 20000 * 10 ** 12;
    }

    /* function to change the max quantity to mint in one transaction */
    function changeMaxPurchase(uint256 max) public onlyOwner {
        MAX_PURCHASE = max;
    }

    function setWhiteListSigner(address signer) public onlyOwner {
        WHITELIST_SIGNER = signer;
    }

    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function reserve(uint256 numberOfTokens) public onlyOwner {
        uint256 mintable = MAX_TOKENS.sub(totalSupply());
        require(
            saleIsActive == false,
            "Impossible reserve when sale is active"
        );

        if (numberOfTokens > mintable) {
            numberOfTokens = mintable;
        }

        uint256 supply = totalSupply();
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), supply + i);
        }
    }

    function preMint(
        uint256 numberOfTokens,
        uint256 max,
        bytes memory signature
    ) public payable nonReentrant {
        require(
            saleIsActive == false,
            "Impossible Pre-Mint when sale is active"
        );
        require(msg.value >= _nftPrice * numberOfTokens , "The value is incorrect");

        uint256 mintable = MAX_TOKENS.sub(totalSupply());
        require(mintable != 0, "Sold out");

        if (numberOfTokens > mintable) {
            numberOfTokens = mintable;
        }

        bytes32 hash;
        require(
            WHITELIST_SIGNER != address(0),
            "Pre-Mint is not available yet"
        );
        require(
            numberOfTokens <= MAX_PURCHASE,
            "Exceed the number of tokens able to mint"
        );

        hash = keccak256(abi.encodePacked(_msgSender(), max));

        require(
            recover(hash, signature) == WHITELIST_SIGNER,
            "Invalid Signature"
        );

        require(
            minted[_msgSender()].add(numberOfTokens) <= max,
            "Max mint reached"
        );

        minted[_msgSender()] = minted[_msgSender()].add(numberOfTokens);

        uint256 supply = totalSupply();
        _pendingWithdrawals += msg.value;

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), supply + i);
        }
    }
    
    // PLEASE SEND THIS IN SZABOS
    function setPrice(uint256 price) public onlyOwner {
        _nftPrice = price * 10**12;
    }

    function getPrice() public view returns (uint256 price) {
        return _nftPrice;
    }

    function mint(uint256 numberOfTokens) public payable nonReentrant {
        require(numberOfTokens > 0, "Number of tokens must be greater than 0");
        require(saleIsActive, "Sale must be active to mint");
        uint256 mintable = MAX_TOKENS.sub(totalSupply());
        require(mintable != 0, "Sold out");

        if (numberOfTokens > mintable) {
            numberOfTokens = mintable;
        }

        if (minted[_msgSender()].add(numberOfTokens) > MAX_PURCHASE) {
            numberOfTokens = MAX_PURCHASE.sub(minted[_msgSender()]);
        }
        require(numberOfTokens != 0, "Max Purchase Reached");

        require(msg.value >= _nftPrice * numberOfTokens , "The value is incorrect");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(_msgSender(), totalSupply());
        }
        minted[_msgSender()] = minted[_msgSender()].add(numberOfTokens);
        _pendingWithdrawals += msg.value;
    }

    function setBaseURI(string memory baseUri)
        public
        onlyOwner
        returns (string memory)
    {
        _baseTokenURI = baseUri;

        return baseUri;
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId)
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function recover(bytes32 _hash, bytes memory _signed)
        internal
        pure
        returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signed, 32))
            s := mload(add(_signed, 64))
            v := and(mload(add(_signed, 65)), 255)
        }
        return ecrecover(_hash, v, r, s);
    }

    function availableToWithdraw() public view returns (uint256) {
        return _pendingWithdrawals;
    }

    function withdraw() public onlyOwner nonReentrant {

        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable receiver = payable(msg.sender);

        uint256 amount = _pendingWithdrawals;
        // zero account before transfer to prevent re-entrancy attack
        _pendingWithdrawals = 0;
        receiver.transfer(amount);
    }
}