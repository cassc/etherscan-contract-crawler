pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

//        rare ghost club X nervous.eth
//
//  ██████   █████  ██████  ███████      ██████  ██   ██  ██████  ███████ ████████      ██████ ██      ██    ██ ██████
//  ██   ██ ██   ██ ██   ██ ██          ██       ██   ██ ██    ██ ██         ██        ██      ██      ██    ██ ██   ██
//  ██████  ███████ ██████  █████       ██   ███ ███████ ██    ██ ███████    ██        ██      ██      ██    ██ ██████
//  ██   ██ ██   ██ ██   ██ ██          ██    ██ ██   ██ ██    ██      ██    ██        ██      ██      ██    ██ ██   ██
//  ██   ██ ██   ██ ██   ██ ███████      ██████  ██   ██  ██████  ███████    ██         ██████ ███████  ██████  ██████
//
//
//  ██   ██
//   ██ ██
//    ███
//   ██ ██
//  ██   ██
//
//
//  ███    ██ ███████ ██████  ██    ██  ██████  ██    ██ ███████
//  ████   ██ ██      ██   ██ ██    ██ ██    ██ ██    ██ ██
//  ██ ██  ██ █████   ██████  ██    ██ ██    ██ ██    ██ ███████
//  ██  ██ ██ ██      ██   ██  ██  ██  ██    ██ ██    ██      ██
//  ██   ████ ███████ ██   ██   ████    ██████   ██████  ███████
//

//        work with us: nervous.net // [email protected]

contract NervousNFT is ERC721, ERC721Enumerable, PaymentSplitter, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public MAX_TOKENS = 100000;
    uint256 public tokenPrice = 80000000000000000;
    bool public hasSaleStarted = false;
    string public baseURI;

    uint256 public MAX_GIFTS = 30000;
    uint256 public numberOfGifts;

    uint256 public MAX_VIP_MINTS = 3;
    bool public hasVIPSaleStarted = true;
    address public bouncer;
    mapping(address => uint256) private VIPListMints;

    

    string public constant R =
        "We are Nervous. Are you? Let us help you with your next NFT Project -> [email protected]";

    constructor(
        string memory name,
        string memory symbol,
        string memory _initBaseURI,
        uint256 _maxTokens,
        uint256 _price,
        uint256 _maxGifts,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721(name, symbol) PaymentSplitter(payees, shares) {
        MAX_TOKENS = _maxTokens;
        MAX_GIFTS = _maxGifts;
        tokenPrice = _price;

        setBaseURI(_initBaseURI);
    }

    function calculatePrice() public view returns (uint256) {
        return tokenPrice; // 0.1 ETH
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function mint(uint256 numTokens) public payable {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(
            _tokenIds.current() + numTokens <= MAX_TOKENS,
            "Exceeds maximum token supply."
        );
        require(
            numTokens > 0 && numTokens <= 10,
            "Machine can dispense a minimum of 1, maximum of 10 tokens"
        );
        require(
            msg.value >= SafeMath.mul(calculatePrice(), numTokens),
            "Amount of Ether sent is not correct."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }

    /* VIP Handling */

    function startVIPSale() public onlyOwner {
        hasVIPSaleStarted = true;
    }

    function pauseVIPSale() public onlyOwner {
        hasVIPSaleStarted = false;
    }

    function setBouncer(address _bouncer) public onlyOwner {
        bouncer = _bouncer;
    }

    function mintVIP(uint8 numTokens, bytes memory signature) public payable {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender));
        bytes32 ethMessageHash = ECDSA.toEthSignedMessageHash(messageHash);
        require(hasVIPSaleStarted == true, "Sale hasn't started");
        require(
            SignatureChecker.isValidSignatureNow(
                bouncer,
                ethMessageHash,
                signature
            ),
            "Address not on VIP List."
        );
        require(
            numTokens > 0 && numTokens <= 10,
            "Machine can dispense a minimum of 1, maximum of 10 tokens"
        );
        require(
            VIPListMints[msg.sender] + numTokens  <= MAX_VIP_MINTS,
            "Exceeds maximum VIP Mints."
        );
        require(
            _tokenIds.current() + numTokens <= MAX_TOKENS,
            "Exceeds maximum token supply."
        );
        require(
            msg.value >= (calculatePrice() * numTokens),
            "Amount of Ether sent is not correct."
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _mint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
            VIPListMints[msg.sender] = VIPListMints[msg.sender] + 1;
        }
    }

    /* Magic */

    function magicGift(address[] calldata receivers) external onlyOwner {
        require(
            _tokenIds.current() + receivers.length <= MAX_TOKENS,
            "Exceeds maximum token supply"
        );
        require(
            numberOfGifts + receivers.length <= MAX_GIFTS,
            "Exceeds maximum allowed gifts"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            numberOfGifts++;

            _safeMint(receivers[i], _tokenIds.current());
            _tokenIds.increment();
        }
    }

    function magicMint(uint256 numTokens) external onlyOwner {
        require(
            _tokenIds.current() + numTokens <= MAX_TOKENS,
            "Exceeds maximum token supply."
        );
        require(
            numTokens > 0 && numTokens <= 100,
            "Machine can dispense a minimum of 1, maximum of 100 tokens"
        );

        for (uint256 i = 0; i < numTokens; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }

    /* URIs */

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}