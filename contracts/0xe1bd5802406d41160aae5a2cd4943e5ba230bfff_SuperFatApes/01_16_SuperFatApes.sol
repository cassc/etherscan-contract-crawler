//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SuperFatApes is ERC721A, Ownable, PaymentSplitter {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public maxSupply = 8400;
    uint256 public maxMintPerTx = 3;
    uint256 public price = 0.29 ether;
    uint256 public presaleSupply = 8400;

    uint256 public presaleStart = 1646240340;
    uint256 public presaleEnd = 1646326740;
    uint256 public raffleStart = 1646413140;
    uint256 public raffleEnd = 1646499540;
    uint256 public publicStart = 1646672340;

    address private presaleAddress = 0x8522c1499248464A13B256Edc0229bab335f912E;
    address private raffleAddress = 0xCCac7bB63E4FFcBE7B7473263a49565CB5019055;

    string public baseURI;
    string public notRevealedUri;

    bool public revealed = false;
    bool public metadatasFrozen = false;
    bool public paused = false;

    uint256 public presaleCount = 0;
    uint256 public raffleCount = 0;

    mapping(address => uint256) presaleTokensMinted;
    mapping(address => uint256) raffleTokensMinted;
    mapping(address => bool) canReserveToken;
    mapping(address => bool) public premintClaimed;

    address[] private team_ = [0x348f8639AF6dC74eA4FA4E0aE30cA248ADed08Ba];
    uint256[] private teamShares_ = [100];

    constructor()
        ERC721A("SuperFatApes", "SFA")
        PaymentSplitter(team_, teamShares_)
    {
        setBaseURI("");
        setNotRevealedURI("ipfs://QmcJpfdfFfU2KX4vzzR6sMHj4fK8TJGZbHCfvcNvWanG1Z");
        canReserveToken[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    //GETTERS

    function getSalePrice() public view returns (uint256) {
        return price;
    }

    //END GETTERS

    //SIGNATURE VERIFICATION

    function verifyAddressSigner(
        address referenceAddress,
        bytes32 messageHash,
        bytes memory signature
    ) internal pure returns (bool) {
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

    //END SIGNATURE VERIFICATION

    //MINT FUNCTIONS

    function presaleMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable {
        require(paused == false, "SuperFatApes: Contract Paused");
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                presaleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            presaleStart > 0 && block.timestamp >= presaleStart,
            "SuperFatApes: presale not started"
        );
        require(presaleEnd > 0 && block.timestamp <= presaleEnd, "SuperFatApes: presale ended");
        require(presaleTokensMinted[msg.sender] + amount <= max, "SuperFatApes: You can't mint more tokens at presale!");
        require(presaleCount + amount <= presaleSupply, "SuperFatApes: PRESALE SOLD OUT!");
        require(supply + amount <= maxSupply, "SuperFatApes: Sold out!");
        require(msg.value >= price * amount, "SuperFatApes: INVALID PRICE");

        presaleTokensMinted[msg.sender]+=amount;
        presaleCount+=amount;

        _safeMint(msg.sender, amount);
    }

    function raffleMint(
        uint256 amount,
        uint256 max,
        bytes calldata signature
    ) external payable {
        require(paused == false, "SuperFatApes: Contract Paused");
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one token");
        require(
            verifyAddressSigner(
                raffleAddress,
                hashMessage(max, msg.sender),
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );
        require(
            raffleStart > 0 && block.timestamp >= raffleStart,
            "SuperFatApes: raffle not started"
        );
        require(raffleEnd > 0 && block.timestamp <= raffleEnd,
            "SuperFatApes: raffle ended"
            );
        require(raffleTokensMinted[msg.sender] + amount <= max, "SuperFatApes: You can't mint more tokens at raffle!");
        require(supply + amount <= maxSupply, "SuperFatApes: Sold out!");
        require(msg.value >= price * amount, "SuperFatApes: INVALID PRICE");

        raffleTokensMinted[msg.sender]+=amount;

        _safeMint(msg.sender, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require(paused == false, "SuperFatApes: Contract Paused");
        uint256 supply = totalSupply();
        require(amount > 0, "You must mint at least one NFT.");
        require(amount <= maxMintPerTx, "SuperFatApes: Mint too large!");
        require(supply + amount <= maxSupply, "SuperFatApes: Sold out!");
        require(
            publicStart > 0 && block.timestamp >= publicStart,
            "SuperFatApes: sale not started"
        );
        require(msg.value >= price * amount, "SuperFatApes: Insuficient funds");

        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        require(
            totalSupply() + addresses.length <= maxSupply,
            "SuperFatApes: You can't mint more than max supply"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    function reserveTokens(uint256 amount) external {
        require(canReserveToken[msg.sender] == true, "SuperFatApes: You are not allowed to reserve tokens");
        require(totalSupply() + amount <= maxSupply, "SuperFatApes: You can't mint mint than max supply");

        _safeMint(msg.sender, amount);
    }

    // END MINT FUNCTIONS

    function setPresaleStart(uint256 _start) external onlyOwner {
        presaleStart = _start;
    }

    function setPresaleEnd(uint256 _end) external onlyOwner {
        presaleEnd = _end;
    }

    function setRaffleStart(uint256 _start) external onlyOwner {
        raffleStart = _start;
    }

    function setRaffleEnd(uint256 _end) external onlyOwner {
        raffleEnd = _end;
    }

    function setSaleStart(uint256 _start) external onlyOwner {
        publicStart = _start;
    }

    function pauseSale() external onlyOwner {
        paused = true;
    }

    function unpauseSale() external onlyOwner {
        paused = false;
    }

    function setPresaleSupply(uint256 supply) external onlyOwner{
        presaleSupply = supply;
    }

    function setMaxSupply(uint256 supply) external onlyOwner {
        maxSupply = supply;
    }

    function setCanReserveToken(address _address, bool _can) public onlyOwner{
        canReserveToken[_address] = _can;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(metadatasFrozen == false, "SuperFatApes: Metadatas are frozen.");
        baseURI = _newBaseURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setMaxMintPerTx(uint256 _newMax) public onlyOwner { 
        maxMintPerTx = _newMax;
    }

    function freezeMetadatas() public onlyOwner {
        metadatasFrozen = true;
    }

    // FACTORY

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
                : "";
    }
}