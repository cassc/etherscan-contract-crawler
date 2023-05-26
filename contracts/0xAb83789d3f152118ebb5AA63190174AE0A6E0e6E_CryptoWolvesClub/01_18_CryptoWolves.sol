// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CryptoWolvesClub is ERC721Enumerable, PaymentSplitter, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using ECDSA for bytes32;

    Counters.Counter private _tokenIdCounter;

    uint256 private constant MAX_SALE_SUPPLY = 11111;
    uint256 private constant MAX_PRESALE = 1000;
    uint256 public constant MAX_SELF_MINT = 10;
    uint256 public constant PRESALE_PRICE = 0.07 ether;
    uint256 public constant TEAM_RESERVE = 25; //Might change

    uint256 private publicSalePrice= 0.15 ether;

    //Placeholder
    address private presaleAddress = 0xDFc148B90146dA2ee5BD0b5B341dAE46C1576a87;
    address private giftAddress = 0xdDBA858bA06bbcA4df4fcfD430d3813E36fE64A0;

    uint256 private presaleCount;

    string public baseURI;
    string public notRevealedUri;
    string public kingUri;

    bool public revealed = false;

    bool private teamReserved;

    uint256 private immutable kingTokenId;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        SoldOut,
        Reveal,
        Paused
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public tokensPerWallet;
    mapping(address => bool) public premintClaimed;


    //Placeholders, shall be changed to the real team addresses and shares
    address[] private team_ = [0x445bBe77B3c1bEd42711F716c7c5df4771956376, 0x48f17e0474ad8de76AE0573911e5d8782d7d622A, 0xbBC21ACD4b0ff961aa0f5f296e55Ba8B8691d1A0, 0x67E83e1FA8a03b9f4d2e5411B5A222A0f112506c];
    uint256[] private teamShares_ = [359375, 359375, 250000, 31520];

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri)
        ERC721("CryptoWolvesClub", "CWC")
        PaymentSplitter(team_, teamShares_)
    {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        kingTokenId = _tokenIdCounter.current();
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        
    }

    //GETTERS

    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function getSalePrice() public view returns(uint256){
        return publicSalePrice;
    }

    function verifyAddressSigner(address referenceAddress, bytes32 messageHash, bytes memory signature)
        internal
        pure
        returns (bool)
    {
        return
            referenceAddress ==
            messageHash.toEthSignedMessageHash().recover(signature);
    }

    function hashMessage(uint256 number, address sender)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(number, sender));
    }

    /**
        Claims tokens for free paying only gas fees
     */
    function preMint(
        uint256 number,
        bytes32 messageHash,
        bytes calldata signature
    ) external virtual {
        require(
            hashMessage(number, msg.sender) == messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifyAddressSigner(giftAddress, messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            premintClaimed[msg.sender] == false,
            "CryptoWolvesClub: You already claimed your premint tokens."
        );

        premintClaimed[msg.sender] = true;

        for (uint256 i = 0; i < number; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    /**
        Mints reserve for the team. Only callable once. Amount fixed.
     */
    function teamReserve() external onlyOwner {
        require(teamReserved == false, "CryptoWolvesClub: Team already reserved");
        teamReserved = true;
        for (uint256 i = 0; i < TEAM_RESERVE; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function presaleMint(
        uint256 number,
        bytes32 messageHash,
        bytes calldata signature
    ) external payable {
        require(
            hashMessage(number, msg.sender) == messageHash,
            "MESSAGE_INVALID"
        );
        require(
            verifyAddressSigner(presaleAddress, messageHash, signature),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            workflow == WorkflowStatus.Presale,
            "CryptoWolvesClub: Presale is not started yet!"
        );
        require(
            tokensPerWallet[msg.sender] < 1,
            "CryptoWolvesClub: You can only mint one token at presale."
        );
        require(presaleCount <= MAX_PRESALE, "CryptoWolvesClub: PRESALE SOLD OUT");
        require(msg.value >= PRESALE_PRICE, "CryptoWolvesClub: INVALID PRICE");

        tokensPerWallet[msg.sender] += 1;
        presaleCount += 1;

        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function publicSaleMint(uint256 amount) external payable {
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one token.");
        require(workflow != WorkflowStatus.SoldOut, "CryptoWolvesClub: SOLD OUT!");
        require(
            supply + amount <= MAX_SALE_SUPPLY,
            "CryptoWolvesClub: Mint too large!"
        );
        require(
            workflow == WorkflowStatus.Sale,
            "CryptoWolvesClub: public sale is not started yet"
        );
        require(
            msg.value >= publicSalePrice * amount,
            "CryptoWolvesClub: Insuficient funds"
        );
        require(
            amount <= MAX_SELF_MINT,
            "CryptoWolvesClub: You can only mint up to ten token at once!"
        );
        require(
            tokensPerWallet[msg.sender] + amount <= MAX_SELF_MINT,
            "CryptoWolvesClub: You already minted 10 tokens!"
        );

        tokensPerWallet[msg.sender] += amount;
        if (supply + amount == MAX_SALE_SUPPLY) {
            workflow = WorkflowStatus.SoldOut;
        }
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    // Before All.

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setKingURI(string memory _newKingURI) public onlyOwner {
        kingUri = _newKingURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setGiftAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        giftAddress = _newAddress;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        publicSalePrice = _newPrice;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (tokenId == kingTokenId) {
            return kingUri;
        }

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }


    //ERC721Burnable without the inheritance
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}